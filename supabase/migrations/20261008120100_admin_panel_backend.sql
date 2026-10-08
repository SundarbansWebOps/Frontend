-- Admin panel, part 2: roster-gated Google sign-in, two-person rule, RCs manage all events
-- Decisions (owner, 2026-10-08):
--   * Students are added to a roster by their Regional Coordinator (own region) or a Super Admin.
--     A new account (first Google sign-in) is created only for an email on the roster; everyone
--     else is refused. Existing accounts (e.g. the Super Admins) are linked by Supabase Auth to the
--     Google identity with the same confirmed email, so this trigger does not run for them.
--   * Every change to student data goes through approval_requests and is applied only when a
--     DIFFERENT Super Admin approves it, including changes filed by a Super Admin. The direct
--     sa_* actions and assign/revoke_position are no longer callable by signed-in users; approval
--     runs them on the approver's behalf.
--   * Regional Coordinators manage all events (previously house-wide only).

-- ── 1. Roster ───────────────────────────────────────────────────────────────
-- Pending students only: a row is deleted when the student's account is created, so personal
-- data lives in one place (members) and hard delete needs no change.

create table public.member_roster (
  email      text primary key,
  full_name  text not null,
  phone      text not null,
  region_id  smallint not null references public.regions (id),
  gender     text,
  added_by   uuid not null references public.members (id),
  added_at   timestamptz not null default now(),

  constraint member_roster_email_format check (email = lower(email) and email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
  constraint member_roster_full_name_length check (full_name = btrim(full_name) and length(full_name) between 1 and 200),
  constraint member_roster_phone_e164 check (phone ~ '^\+[1-9][0-9]{7,14}$'),
  constraint member_roster_gender_length check (gender is null or length(gender) between 1 and 50),
  constraint member_roster_phone_key unique (phone)
);

create index member_roster_region_idx on public.member_roster (region_id);
create index member_roster_added_by_idx on public.member_roster (added_by);

comment on table public.member_roster is
  'Students added by an RC or Super Admin who have not signed in yet. First Google sign-in with the email creates the member and removes the row.';

alter table public.member_roster enable row level security;
revoke all on table public.member_roster from public, anon, authenticated, service_role;
grant select on table public.member_roster to authenticated;
grant all on table public.member_roster to service_role;

create policy member_roster_select on public.member_roster
  for select to authenticated
  using ((select private.is_super_admin()) or region_id = (select private.my_rc_region()));

-- Add one student. RC: own region only (p_region_id may be omitted). Super Admin: any region.
create or replace function public.roster_add(
  p_email     text,
  p_full_name text,
  p_phone     text,
  p_region_id smallint default null,
  p_gender    text default null
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sa     boolean  := (select private.is_super_admin());
  v_rc     smallint := (select private.my_rc_region());
  v_email  text     := lower(btrim(coalesce(p_email, '')));
  v_name   text     := btrim(coalesce(p_full_name, ''));
  v_gender text     := nullif(btrim(coalesce(p_gender, '')), '');
  v_region smallint;
  v_phone  text;
  v_row    public.member_roster%rowtype;
begin
  if not v_sa and v_rc is null then
    raise exception 'Only a Regional Coordinator or Super Admin can add students'
      using errcode = 'insufficient_privilege';
  end if;

  if v_sa then
    v_region := p_region_id;
  else
    if p_region_id is not null and p_region_id <> v_rc then
      raise exception 'You can only add students to your own region' using errcode = 'insufficient_privilege';
    end if;
    v_region := v_rc;
  end if;

  if v_region is null or not exists (select 1 from public.regions r where r.id = v_region) then
    raise exception 'Choose a valid region' using errcode = 'invalid_parameter_value';
  end if;

  if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'Enter a valid email address' using errcode = 'invalid_parameter_value';
  end if;

  if exists (select 1 from private.signup_email_domains)
     and not exists (select 1 from private.signup_email_domains d where d.domain = split_part(v_email, '@', 2)) then
    raise exception 'Only IITM student emails (@ds.study.iitm.ac.in) can be added' using errcode = 'invalid_parameter_value';
  end if;

  if length(v_name) not between 1 and 200 then
    raise exception 'Full name is required (up to 200 characters)' using errcode = 'invalid_parameter_value';
  end if;

  if v_gender is not null and length(v_gender) > 50 then
    raise exception 'Gender is too long (up to 50 characters)' using errcode = 'invalid_parameter_value';
  end if;

  v_phone := private.normalise_phone(p_phone);

  if exists (select 1 from public.members m where m.email = v_email) then
    raise exception 'This email already belongs to a member' using errcode = 'unique_violation';
  end if;

  if exists (select 1 from public.members m where m.phone = v_phone) then
    raise exception 'This phone number already belongs to a member' using errcode = 'unique_violation';
  end if;

  if exists (select 1 from public.blacklist_entries b
             where b.lifted_at is null
               and (b.email_hash = private.identity_hash('email', v_email)
                    or b.phone_hash = private.identity_hash('phone', v_phone))) then
    raise exception 'This person cannot be added' using errcode = 'insufficient_privilege';
  end if;

  begin
    insert into public.member_roster (email, full_name, phone, region_id, gender, added_by)
    values (v_email, v_name, v_phone, v_region, v_gender, (select auth.uid()))
    returning * into v_row;
  exception when unique_violation then
    raise exception 'This email or phone number is already on the roster' using errcode = 'unique_violation';
  end;

  perform private.write_audit('roster.add', 'member_roster', v_email, null, to_jsonb(v_row));
  return v_email;
end;
$$;

-- Add many students at once (e.g. pasted from the council Sheet). Each row is added on its own;
-- the result lists every row as {email, ok, error}. At most 500 rows per call.
create or replace function public.roster_add_many(p_rows jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row    jsonb;
  v_out    jsonb := '[]'::jsonb;
begin
  if not (select private.is_super_admin()) and (select private.my_rc_region()) is null then
    raise exception 'Only a Regional Coordinator or Super Admin can add students'
      using errcode = 'insufficient_privilege';
  end if;

  if jsonb_typeof(p_rows) is distinct from 'array' or jsonb_array_length(p_rows) not between 1 and 500 then
    raise exception 'Send between 1 and 500 rows' using errcode = 'invalid_parameter_value';
  end if;

  for v_row in select * from jsonb_array_elements(p_rows) loop
    begin
      if jsonb_typeof(v_row) <> 'object' then
        raise exception 'Row is not an object' using errcode = 'invalid_parameter_value';
      end if;
      perform public.roster_add(v_row ->> 'email', v_row ->> 'full_name', v_row ->> 'phone',
                                (v_row ->> 'region_id')::smallint, v_row ->> 'gender');
      v_out := v_out || jsonb_build_array(jsonb_build_object('email', v_row ->> 'email', 'ok', true));
    exception when others then
      v_out := v_out || jsonb_build_array(jsonb_build_object('email', v_row ->> 'email', 'ok', false, 'error', sqlerrm));
    end;
  end loop;

  return v_out;
end;
$$;

-- Remove a student who has not signed in yet. RC: own region. Super Admin: any.
create or replace function public.roster_remove(p_email text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sa  boolean  := (select private.is_super_admin());
  v_rc  smallint := (select private.my_rc_region());
  v_row public.member_roster%rowtype;
begin
  if not v_sa and v_rc is null then
    raise exception 'Only a Regional Coordinator or Super Admin can remove roster entries'
      using errcode = 'insufficient_privilege';
  end if;

  delete from public.member_roster r
   where r.email = lower(btrim(coalesce(p_email, '')))
     and (v_sa or r.region_id = v_rc)
  returning * into v_row;

  if not found then
    raise exception 'Not on the roster in your scope' using errcode = 'no_data_found';
  end if;

  perform private.write_audit('roster.remove', 'member_roster', v_row.email, to_jsonb(v_row), null);
end;
$$;

revoke execute on function public.roster_add(text, text, text, smallint, text), public.roster_add_many(jsonb),
  public.roster_remove(text) from public, anon;
grant execute on function public.roster_add(text, text, text, smallint, text), public.roster_add_many(jsonb),
  public.roster_remove(text) to authenticated;

-- ── 2. Sign-up: roster only ─────────────────────────────────────────────────
-- Replaces the metadata-based sign-up (full_name / phone / region_code). The profile comes from the
-- roster row; user metadata (e.g. Google's name) is ignored. Any refusal makes Supabase Auth return
-- "Database error saving new user", which the site shows as "not on the house roster".

create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text := lower(btrim(new.email));
  v_entry public.member_roster%rowtype;
begin
  if v_email is null or v_email = '' then
    raise exception 'An email address is required to sign up'
      using errcode = 'invalid_parameter_value';
  end if;

  if exists (select 1 from private.signup_email_domains)
     and not exists (select 1 from private.signup_email_domains d where d.domain = split_part(v_email, '@', 2)) then
    raise exception 'Sign-up is restricted to approved email domains'
      using errcode = 'insufficient_privilege';
  end if;

  select * into v_entry from public.member_roster r where r.email = v_email for update;

  if not found then
    raise exception 'This email is not on the house roster'
      using errcode = 'insufficient_privilege';
  end if;

  -- Blacklisted people may not register again under the same email or phone (§6, Q11).
  if exists (select 1 from public.blacklist_entries b
             where b.lifted_at is null
               and (b.email_hash = private.identity_hash('email', v_email)
                    or b.phone_hash = private.identity_hash('phone', v_entry.phone))) then
    raise exception 'Registration is not allowed for this account'
      using errcode = 'insufficient_privilege';
  end if;

  insert into public.members (id, member_code, full_name, email, phone, gender, region_id)
  values (new.id, private.member_code_for(v_email), v_entry.full_name, v_email, v_entry.phone,
          v_entry.gender, v_entry.region_id);

  delete from public.member_roster r where r.email = v_email;

  perform private.write_audit('roster.claim', 'members', new.id::text, to_jsonb(v_entry),
                              jsonb_build_object('member_id', new.id), null, 'success', new.id);
  return new;
end;
$$;

-- ── 3. Requests: shapes and filing ──────────────────────────────────────────

alter table public.approval_requests drop constraint approval_requests_target_shape;
alter table public.approval_requests add constraint approval_requests_target_shape check (
  (type in ('member_deletion', 'member_blacklist', 'member_hard_delete',
            'member_profile_update', 'member_status_change', 'position_change')
   and target_registration_id is null)
  or (type in ('community_record_update', 'community_record_deletion') and target_registration_id is not null)
);

-- Deletion and blacklist requests: RC (own region) as before, and now Super Admins (any region).
create or replace function private.file_member_request(p_type public.request_type, p_member_id uuid, p_reason text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sa      boolean  := (select private.is_super_admin());
  v_region  smallint := (select private.my_rc_region());
  v_member  public.members%rowtype;
  v_reason  text;
  v_request public.approval_requests%rowtype;
begin
  if not v_sa and v_region is null then
    raise exception 'Only a Regional Coordinator or Super Admin can file this request'
      using errcode = 'insufficient_privilege';
  end if;

  if p_member_id is null then
    raise exception 'member_id is required' using errcode = 'invalid_parameter_value';
  end if;

  v_reason := private.clean_reason(p_reason, true);

  select * into v_member from public.members where id = p_member_id for update;

  -- Same answer for "does not exist" and "not in your region".
  if not found or (not v_sa and v_member.region_id <> v_region) then
    raise exception 'Member not found in your region' using errcode = 'insufficient_privilege';
  end if;

  if v_member.account_status = 'deleted' then
    raise exception 'Member is already deleted' using errcode = 'PT409';
  end if;

  if p_type = 'member_blacklist' and v_member.account_status = 'blacklisted' then
    raise exception 'Member is already blacklisted' using errcode = 'PT409';
  end if;

  perform private.assert_requestable_target(p_member_id);

  begin
    insert into public.approval_requests (type, target_member_id, target_snapshot, reason, requested_by)
    values (p_type, p_member_id, private.member_snapshot(p_member_id), v_reason, (select auth.uid()))
    returning * into v_request;
  exception when unique_violation then
    raise exception 'A pending % request already exists for this member', p_type
      using errcode = 'unique_violation';
  end;

  perform private.write_audit(
    'request.create', 'approval_requests', v_request.id::text, null,
    jsonb_build_object('type', v_request.type, 'target_member_id', v_request.target_member_id,
                       'reason', v_request.reason),
    v_request.id);

  return v_request.id;
end;
$$;

-- Shared insert for the new request types.
create or replace function private.insert_request(
  p_type public.request_type, p_member_id uuid, p_change jsonb, p_reason text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_request public.approval_requests%rowtype;
begin
  begin
    insert into public.approval_requests (type, target_member_id, target_snapshot, requested_change, reason, requested_by)
    values (p_type, p_member_id, private.member_snapshot(p_member_id), p_change, p_reason, (select auth.uid()))
    returning * into v_request;
  exception when unique_violation then
    raise exception 'A pending request of this kind already exists for this member'
      using errcode = 'unique_violation';
  end;

  perform private.write_audit(
    'request.create', 'approval_requests', v_request.id::text, null,
    jsonb_build_object('type', v_request.type, 'target_member_id', p_member_id,
                       'requested_change', p_change, 'reason', p_reason),
    v_request.id);

  return v_request.id;
end;
$$;

revoke execute on function private.insert_request(public.request_type, uuid, jsonb, text) from public, anon, authenticated;

-- Common target checks for the new types. Returns the locked member.
create or replace function private.lock_request_target(p_member_id uuid, p_allow_admin_targets boolean)
returns public.members
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sa     boolean  := (select private.is_super_admin());
  v_region smallint := (select private.my_rc_region());
  v_member public.members%rowtype;
begin
  if p_member_id is null then
    raise exception 'member_id is required' using errcode = 'invalid_parameter_value';
  end if;

  select * into v_member from public.members where id = p_member_id for update;

  if not found or (not v_sa and v_member.region_id is distinct from v_region) then
    raise exception 'Member not found in your region' using errcode = 'insufficient_privilege';
  end if;

  if p_member_id = (select auth.uid()) then
    raise exception 'You cannot file a request about yourself' using errcode = 'PT409';
  end if;

  if exists (select 1 from public.super_admin_allowlist s where s.user_id = p_member_id) then
    raise exception 'Super Admin accounts are managed by migration' using errcode = 'PT409';
  end if;

  if not p_allow_admin_targets
     and exists (select 1 from public.admin_assignments a where a.member_id = p_member_id and a.ended_at is null) then
    raise exception 'Requests cannot target a member who holds an admin position' using errcode = 'PT409';
  end if;

  if v_member.anonymised_at is not null then
    raise exception 'Member was hard-deleted' using errcode = 'PT409';
  end if;

  return v_member;
end;
$$;

revoke execute on function private.lock_request_target(uuid, boolean) from public, anon, authenticated;

-- Profile update: full_name, preferred_name, gender, phone, region_id. RC: own region, not admins.
-- Super Admin: anyone except Super Admins. Only changed fields are kept.
create or replace function public.request_member_update(p_member_id uuid, p_changes jsonb, p_reason text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sa     boolean  := (select private.is_super_admin());
  v_member public.members%rowtype;
  v_reason text;
  v_key    text;
  v_val    text;
  v_change jsonb := '{}'::jsonb;
begin
  if not v_sa and (select private.my_rc_region()) is null then
    raise exception 'Only a Regional Coordinator or Super Admin can request profile changes'
      using errcode = 'insufficient_privilege';
  end if;

  v_reason := private.clean_reason(p_reason, true);
  v_member := private.lock_request_target(p_member_id, v_sa);

  if v_member.account_status = 'deleted' then
    raise exception 'Member is deleted; restore them first' using errcode = 'PT409';
  end if;

  if jsonb_typeof(p_changes) is distinct from 'object' then
    raise exception 'changes must be an object' using errcode = 'invalid_parameter_value';
  end if;

  for v_key in select jsonb_object_keys(p_changes) loop
    if v_key not in ('full_name', 'preferred_name', 'gender', 'phone', 'region_id') then
      raise exception 'Field % cannot be changed here', v_key using errcode = 'invalid_parameter_value';
    end if;
  end loop;

  if p_changes ? 'full_name' then
    v_val := btrim(coalesce(p_changes ->> 'full_name', ''));
    if length(v_val) not between 1 and 200 then
      raise exception 'Full name is required (up to 200 characters)' using errcode = 'invalid_parameter_value';
    end if;
    if v_val <> v_member.full_name then v_change := v_change || jsonb_build_object('full_name', v_val); end if;
  end if;

  if p_changes ? 'preferred_name' then
    v_val := nullif(btrim(coalesce(p_changes ->> 'preferred_name', '')), '');
    if v_val is not null and length(v_val) > 100 then
      raise exception 'Preferred name is too long (up to 100 characters)' using errcode = 'invalid_parameter_value';
    end if;
    if v_val is distinct from v_member.preferred_name then
      v_change := v_change || jsonb_build_object('preferred_name', v_val);
    end if;
  end if;

  if p_changes ? 'gender' then
    v_val := nullif(btrim(coalesce(p_changes ->> 'gender', '')), '');
    if v_val is not null and length(v_val) > 50 then
      raise exception 'Gender is too long (up to 50 characters)' using errcode = 'invalid_parameter_value';
    end if;
    if v_val is distinct from v_member.gender then v_change := v_change || jsonb_build_object('gender', v_val); end if;
  end if;

  if p_changes ? 'phone' then
    v_val := private.normalise_phone(p_changes ->> 'phone');
    if v_val <> v_member.phone then
      if exists (select 1 from public.members m where m.phone = v_val and m.id <> v_member.id)
         or exists (select 1 from public.member_roster r where r.phone = v_val) then
        raise exception 'This phone number already belongs to someone else' using errcode = 'unique_violation';
      end if;
      v_change := v_change || jsonb_build_object('phone', v_val);
    end if;
  end if;

  if p_changes ? 'region_id' then
    if not exists (select 1 from public.regions r where r.id = (p_changes ->> 'region_id')::smallint) then
      raise exception 'Choose a valid region' using errcode = 'invalid_parameter_value';
    end if;
    if (p_changes ->> 'region_id')::smallint <> v_member.region_id then
      v_change := v_change || jsonb_build_object('region_id', (p_changes ->> 'region_id')::smallint);
    end if;
  end if;

  if v_change = '{}'::jsonb then
    raise exception 'Nothing to change' using errcode = 'PT409';
  end if;

  return private.insert_request('member_profile_update', p_member_id, v_change, v_reason);
end;
$$;

-- Status change (Super Admin files): suspend, reinstate, restore, lift_blacklist.
create or replace function public.request_status_change(p_member_id uuid, p_action text, p_reason text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member public.members%rowtype;
  v_reason text;
begin
  if not (select private.is_super_admin()) then
    raise exception 'Only a Super Admin can request a status change' using errcode = 'insufficient_privilege';
  end if;

  if p_action is null or p_action not in ('suspend', 'reinstate', 'restore', 'lift_blacklist') then
    raise exception 'action must be suspend, reinstate, restore or lift_blacklist' using errcode = 'invalid_parameter_value';
  end if;

  v_reason := private.clean_reason(p_reason, true);
  v_member := private.lock_request_target(p_member_id, true);

  if (p_action = 'suspend' and v_member.account_status <> 'active')
     or (p_action = 'reinstate' and v_member.account_status <> 'suspended')
     or (p_action = 'restore' and v_member.account_status <> 'deleted')
     or (p_action = 'lift_blacklist'
         and not exists (select 1 from public.blacklist_entries b where b.member_id = p_member_id and b.lifted_at is null)) then
    raise exception 'Member is %; % does not apply', v_member.account_status, replace(p_action, '_', ' ')
      using errcode = 'PT409';
  end if;

  return private.insert_request('member_status_change', p_member_id, jsonb_build_object('action', p_action), v_reason);
end;
$$;

-- Position change (Super Admin files): assign or revoke RC / Head / Co-Head.
create or replace function public.request_position_change(
  p_member_id    uuid,
  p_action       text,
  p_position     public.admin_position default null,
  p_community_id smallint default null,
  p_reason       text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member public.members%rowtype;
  v_reason text;
  v_change jsonb;
begin
  if not (select private.is_super_admin()) then
    raise exception 'Only a Super Admin can request a position change' using errcode = 'insufficient_privilege';
  end if;

  if p_action is null or p_action not in ('assign', 'revoke') then
    raise exception 'action must be assign or revoke' using errcode = 'invalid_parameter_value';
  end if;

  v_reason := private.clean_reason(p_reason, true);
  v_member := private.lock_request_target(p_member_id, true);

  if p_action = 'assign' then
    if p_position is null then
      raise exception 'position is required' using errcode = 'invalid_parameter_value';
    end if;
    if v_member.account_status <> 'active' then
      raise exception 'Member is % and cannot hold a position', v_member.account_status using errcode = 'PT409';
    end if;
    if p_position = 'rc' and p_community_id is not null then
      raise exception 'An RC position has no community' using errcode = 'invalid_parameter_value';
    end if;
    if p_position <> 'rc' and not exists (select 1 from public.communities c where c.id = p_community_id) then
      raise exception 'Choose a community for this position' using errcode = 'invalid_parameter_value';
    end if;
    v_change := jsonb_build_object('action', 'assign', 'position', p_position,
                                   'community_id', case when p_position = 'rc' then null else p_community_id end,
                                   'region_id', case when p_position = 'rc' then v_member.region_id end);
  else
    if not exists (select 1 from public.admin_assignments a where a.member_id = p_member_id and a.ended_at is null) then
      raise exception 'Member has no active position' using errcode = 'PT409';
    end if;
    v_change := jsonb_build_object('action', 'revoke');
  end if;

  return private.insert_request('position_change', p_member_id, v_change, v_reason);
end;
$$;

revoke execute on function public.request_member_update(uuid, jsonb, text),
  public.request_status_change(uuid, text, text),
  public.request_position_change(uuid, text, public.admin_position, smallint, text) from public, anon;
grant execute on function public.request_member_update(uuid, jsonb, text),
  public.request_status_change(uuid, text, text),
  public.request_position_change(uuid, text, public.admin_position, smallint, text) to authenticated;

-- ── 4. Approval applies every request type ──────────────────────────────────
-- The direct actions below are kept as internal building blocks: approve_request (security
-- definer, owner) calls them as the approving Super Admin, so their own checks and audit rows
-- still apply.

create or replace function public.approve_request(p_request_id uuid, p_note text default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_request public.approval_requests%rowtype;
  v_note    text := private.clean_reason(p_note, false);
  v_member  public.members%rowtype;
  v_reg     public.community_registrations%rowtype;
  v_change  jsonb;
  v_action  text;
  v_before  jsonb;
  v_after   jsonb;
begin
  v_request := private.lock_request_for_review(p_request_id);
  v_change  := v_request.requested_change;
  v_action  := v_change ->> 'action';

  if v_request.type = 'member_hard_delete' then
    raise exception 'Hard delete is approved through the hard-delete-member Edge Function'
      using errcode = 'feature_not_supported';
  end if;

  -- Re-check the target now; things may have changed since the request was filed.
  select * into v_member from public.members where id = v_request.target_member_id for update;

  if exists (select 1 from public.super_admin_allowlist s where s.user_id = v_member.id) then
    raise exception 'Target is now a Super Admin; reject this request instead' using errcode = 'PT409';
  end if;

  -- Requests filed by an RC, and deletion / blacklist / community changes from anyone, may not touch
  -- position holders (revoke the position first, which is itself a request).
  if (v_request.type in ('member_deletion', 'member_blacklist', 'community_record_update', 'community_record_deletion')
      or (v_request.type = 'member_profile_update' and not private.is_super_admin_id(v_request.requested_by)))
     and exists (select 1 from public.admin_assignments a where a.member_id = v_member.id and a.ended_at is null) then
    raise exception 'Target now holds an admin position; reject this request instead' using errcode = 'PT409';
  end if;

  v_before := private.member_snapshot(v_member.id);

  if v_request.type = 'member_deletion' then
    if v_member.account_status = 'deleted' then
      raise exception 'Member is already deleted; reject this request instead' using errcode = 'PT409';
    end if;

    update public.members set account_status = 'deleted', deleted_at = now() where id = v_member.id;
    update public.regional_registrations set status = 'deleted' where member_id = v_member.id and status <> 'deleted';
    update public.community_registrations set status = 'deleted' where member_id = v_member.id and status <> 'deleted';

  elsif v_request.type = 'member_blacklist' then
    if v_member.account_status in ('deleted', 'blacklisted') then
      raise exception 'Member is already %; reject this request instead', v_member.account_status using errcode = 'PT409';
    end if;

    update public.members set account_status = 'blacklisted' where id = v_member.id;

    insert into public.blacklist_entries (member_id, email_hash, phone_hash, reason, request_id, created_by)
    values (v_member.id,
            private.identity_hash('email', v_member.email),
            private.identity_hash('phone', v_member.phone),
            v_request.reason, v_request.id, (select auth.uid()));

  elsif v_request.type = 'member_profile_update' then
    if v_member.account_status = 'deleted' then
      raise exception 'Member is deleted; reject this request instead' using errcode = 'PT409';
    end if;

    if v_change ? 'region_id' and (v_change ->> 'region_id')::smallint <> v_member.region_id then
      perform public.sa_change_member_region(v_member.id, (v_change ->> 'region_id')::smallint, v_request.reason);
    end if;

    begin
      update public.members
         set full_name      = case when v_change ? 'full_name' then v_change ->> 'full_name' else full_name end,
             preferred_name = case when v_change ? 'preferred_name' then v_change ->> 'preferred_name' else preferred_name end,
             gender         = case when v_change ? 'gender' then v_change ->> 'gender' else gender end,
             phone          = case when v_change ? 'phone' then v_change ->> 'phone' else phone end
       where id = v_member.id;
    exception when unique_violation then
      raise exception 'That phone number now belongs to another member; reject this request instead'
        using errcode = 'PT409';
    end;

  elsif v_request.type = 'member_status_change' then
    case v_action
      when 'suspend'        then perform public.sa_set_suspended(v_member.id, true, v_request.reason);
      when 'reinstate'      then perform public.sa_set_suspended(v_member.id, false, v_request.reason);
      when 'restore'        then perform public.sa_restore_member(v_member.id, v_request.reason);
      when 'lift_blacklist' then perform public.sa_lift_blacklist(v_member.id, v_request.reason);
      else raise exception 'Unknown status action %', v_action using errcode = 'invalid_parameter_value';
    end case;

  elsif v_request.type = 'position_change' then
    if v_action = 'assign' then
      if (v_change ->> 'position') = 'rc' and (v_change ->> 'region_id')::smallint is distinct from v_member.region_id then
        raise exception 'Member has moved region since this request; reject it and file a new one' using errcode = 'PT409';
      end if;
      perform public.assign_position(v_member.id, (v_change ->> 'position')::public.admin_position,
                                     (v_change ->> 'community_id')::smallint);
    else
      perform public.revoke_position(v_member.id);
    end if;

  else
    -- Community record change: the registration only. members is never written here.
    select * into v_reg from public.community_registrations where id = v_request.target_registration_id for update;

    if v_reg.status <> 'active' then
      raise exception 'Registration is now %; reject this request instead', v_reg.status using errcode = 'PT409';
    end if;

    v_before := jsonb_build_object('registration', to_jsonb(v_reg));

    if v_request.type = 'community_record_update' then
      update public.community_registrations set answers = v_change -> 'answers' where id = v_reg.id;
    else
      update public.community_registrations set status = 'deleted' where id = v_reg.id;
    end if;

    v_after := jsonb_build_object('registration',
      (select to_jsonb(c) from public.community_registrations c where c.id = v_reg.id));
  end if;

  v_after := coalesce(v_after, private.member_snapshot(v_member.id));

  update public.approval_requests
     set status = 'approved', reviewed_by = (select auth.uid()), reviewed_at = now(),
         review_note = v_note, executed_at = now()
   where id = v_request.id;

  perform private.write_audit(
    'request.approve', 'approval_requests', v_request.id::text,
    v_before, v_after || jsonb_build_object('type', v_request.type, 'review_note', v_note),
    v_request.id);

  return v_request.id;
end;
$$;

-- Two-person rule: signed-in users can no longer call the direct actions.
revoke execute on function
  public.sa_soft_delete_member(uuid, text),
  public.sa_restore_member(uuid, text),
  public.sa_blacklist_member(uuid, text),
  public.sa_lift_blacklist(uuid, text),
  public.sa_set_suspended(uuid, boolean, text),
  public.sa_change_member_region(uuid, smallint, text),
  public.assign_position(uuid, public.admin_position, smallint),
  public.revoke_position(uuid)
from public, anon, authenticated;

-- Super Admins no longer edit other members' safe fields directly either; members edit their own.
drop policy members_update on public.members;
create policy members_update on public.members
  for update to authenticated
  using (id = (select auth.uid()) and (select private.is_active_member()))
  with check (id = (select auth.uid()) and (select private.is_active_member()));

-- ── 5. Events: Regional Coordinators manage all events ──────────────────────

drop policy events_insert on public.events;
create policy events_insert on public.events
  for insert to authenticated
  with check (
    (select private.is_super_admin())
    or (select private.my_rc_region()) is not null
    or community_id = any ((select private.my_community_ids())::smallint[])
  );

drop policy events_update on public.events;
create policy events_update on public.events
  for update to authenticated
  using (
    (select private.is_super_admin())
    or (deleted_at is null and (select private.my_rc_region()) is not null)
    or (deleted_at is null and community_id = any ((select private.my_community_ids())::smallint[]))
  )
  with check (
    (select private.is_super_admin())
    or (select private.my_rc_region()) is not null
    or community_id = any ((select private.my_community_ids())::smallint[])
  );

drop policy events_select on public.events;
create policy events_select on public.events
  for select to authenticated
  using (
    (deleted_at is null and (select private.is_active_member()))
    or (select private.is_super_admin())
    or (select private.my_rc_region()) is not null
    or community_id = any ((select private.my_community_ids())::smallint[])
  );
