-- Migration 19: "wrong state" errors map to HTTP 409 over the Data API
-- Follow-up from phase 5 testing. PostgREST turns SQLSTATE 55000
-- (object_not_in_prerequisite_state) into HTTP 500, so a frontend would treat "request is
-- already approved", "member is not active" or "30-day wait not over" as a server fault.
-- PostgREST maps the custom SQLSTATE PTxyz to HTTP xyz, so these errors now raise PT409.
--
-- Mechanical change: each function below is re-created from its latest definition with
-- errcode 'object_not_in_prerequisite_state' replaced by 'PT409'. Nothing else changes;
-- CREATE OR REPLACE keeps existing grants and comments. private.identity_hash keeps 55000
-- (a missing Vault secret is a server misconfiguration, so 500 is right).
--
-- Error codes after this migration: 42501 -> 403 | 22023 -> 400 | P0002 -> 404 |
--                                   PT409 -> 409 (wrong state) | 23505 -> 409 (duplicate)

-- public.assign_position (from 20260928121200_role_assignment_rpcs.sql, 3 sites)
create or replace function public.assign_position(
  p_member_id    uuid,
  p_position     public.admin_position,
  p_community_id smallint default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member    public.members%rowtype;
  v_current   public.admin_assignments%rowtype;
  v_new       public.admin_assignments%rowtype;
  v_region_id smallint;
  v_holder    uuid;
begin
  if not (select private.is_super_admin()) then
    raise exception 'Only a Super Admin can assign positions'
      using errcode = 'insufficient_privilege';
  end if;

  if p_member_id is null or p_position is null then
    raise exception 'member_id and position are required'
      using errcode = 'invalid_parameter_value';
  end if;

  -- Lock the target so concurrent assign/revoke/region changes serialise on the member.
  select * into v_member from public.members where id = p_member_id for update;

  if not found then
    raise exception 'Member % does not exist', p_member_id
      using errcode = 'invalid_parameter_value';
  end if;

  if v_member.account_status <> 'active' or v_member.deleted_at is not null then
    raise exception 'Member % is not active (status: %) and cannot hold a position',
      p_member_id, v_member.account_status
      using errcode = 'PT409';
  end if;

  if exists (select 1 from public.super_admin_allowlist s where s.user_id = p_member_id) then
    raise exception 'Super Admins are not assigned positions; they already have global access'
      using errcode = 'PT409';
  end if;

  -- Resolve scope.
  if p_position = 'rc' then
    if p_community_id is not null then
      raise exception 'An RC position has no community; do not pass community_id for rc'
        using errcode = 'invalid_parameter_value';
    end if;

    select r.id into v_region_id from public.regions r where r.id = v_member.region_id;

    if v_region_id is null then
      raise exception 'Member % has no valid region and cannot be made RC', p_member_id
        using errcode = 'PT409';
    end if;
  else
    if p_community_id is null then
      raise exception 'community_id is required for position %', p_position
        using errcode = 'invalid_parameter_value';
    end if;

    if not exists (select 1 from public.communities c where c.id = p_community_id) then
      raise exception 'Community % does not exist', p_community_id
        using errcode = 'invalid_parameter_value';
    end if;
  end if;

  select * into v_current
  from public.admin_assignments
  where member_id = p_member_id and ended_at is null
  for update;

  if found
     and v_current.position = p_position
     and v_current.region_id    is not distinct from v_region_id
     and v_current.community_id is not distinct from (case when p_position = 'rc' then null else p_community_id end)
  then
    raise exception 'Member % already holds this position', p_member_id
      using errcode = 'invalid_parameter_value';
  end if;

  -- Slot must be free (clear error; the unique indexes still guard races below).
  select a.member_id into v_holder
  from public.admin_assignments a
  where a.ended_at is null
    and a.member_id <> p_member_id
    and a.position = p_position
    and (   (p_position = 'rc' and a.region_id = v_region_id)
         or (p_position <> 'rc' and a.community_id = p_community_id));

  if v_holder is not null then
    raise exception 'That % position is already held by member %; revoke it first', p_position, v_holder
      using errcode = 'unique_violation';
  end if;

  -- Handover: end the previous position in this same transaction.
  if v_current.id is not null then
    update public.admin_assignments
       set ended_at = now()
     where id = v_current.id
     returning * into v_current;

    perform private.write_audit(
      'position.revoke', 'admin_assignments', v_current.id::text,
      to_jsonb(v_current) - 'ended_at', to_jsonb(v_current) || jsonb_build_object('reason', 'replaced'));
  end if;

  begin
    insert into public.admin_assignments (member_id, position, region_id, community_id, assigned_by)
    values (p_member_id, p_position, v_region_id,
            case when p_position = 'rc' then null else p_community_id end,
            (select auth.uid()))
    returning * into v_new;
  exception when unique_violation then
    raise exception 'That % position was just taken by another assignment; reload and retry', p_position
      using errcode = 'unique_violation';
  end;

  perform private.write_audit(
    'position.assign', 'admin_assignments', v_new.id::text, null, to_jsonb(v_new));

  return v_new.id;
end;
$$;

-- private.assert_requestable_target (from 20260928121500_approval_rpcs.sql, 3 sites)
create or replace function private.assert_requestable_target(p_member_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_member_id = (select auth.uid()) then
    raise exception 'You cannot file a request about yourself'
      using errcode = 'PT409';
  end if;

  if exists (select 1 from public.super_admin_allowlist s where s.user_id = p_member_id) then
    raise exception 'Requests cannot target a Super Admin'
      using errcode = 'PT409';
  end if;

  if exists (select 1 from public.admin_assignments a where a.member_id = p_member_id and a.ended_at is null) then
    raise exception 'Requests cannot target a member who holds an admin position'
      using errcode = 'PT409';
  end if;
end;
$$;

-- private.file_member_request (from 20260928121500_approval_rpcs.sql, 2 sites)
create or replace function private.file_member_request(
  p_type      public.request_type,
  p_member_id uuid,
  p_reason    text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_region  smallint := (select private.my_rc_region());
  v_member  public.members%rowtype;
  v_reason  text;
  v_request public.approval_requests%rowtype;
begin
  if v_region is null then
    raise exception 'Only a Regional Coordinator can file this request'
      using errcode = 'insufficient_privilege';
  end if;

  if p_member_id is null then
    raise exception 'member_id is required' using errcode = 'invalid_parameter_value';
  end if;

  v_reason := private.clean_reason(p_reason, true);

  select * into v_member from public.members where id = p_member_id for update;

  -- Same answer for "does not exist" and "not in your region".
  if not found or v_member.region_id <> v_region then
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

-- private.lock_request_for_review (from 20260928121500_approval_rpcs.sql, 1 site)
create or replace function private.lock_request_for_review(p_request_id uuid)
returns public.approval_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_request public.approval_requests%rowtype;
begin
  if not (select private.is_super_admin()) then
    raise exception 'Only a Super Admin can review requests' using errcode = 'insufficient_privilege';
  end if;

  if p_request_id is null then
    raise exception 'request_id is required' using errcode = 'invalid_parameter_value';
  end if;

  select * into v_request from public.approval_requests where id = p_request_id for update;

  if not found then
    raise exception 'Request % does not exist', p_request_id using errcode = 'invalid_parameter_value';
  end if;

  if v_request.requested_by = (select auth.uid()) then
    raise exception 'You cannot review your own request' using errcode = 'insufficient_privilege';
  end if;

  if v_request.status <> 'pending' then
    raise exception 'Request is already %', v_request.status using errcode = 'PT409';
  end if;

  return v_request;
end;
$$;

-- public.approve_request (from 20260928121500_approval_rpcs.sql, 4 sites)
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
  v_before  jsonb;
  v_after   jsonb;
begin
  v_request := private.lock_request_for_review(p_request_id);

  if v_request.type = 'member_hard_delete' then
    raise exception 'Hard delete is approved through the hard-delete-member Edge Function'
      using errcode = 'feature_not_supported';
  end if;

  -- Re-check the target now; things may have changed since the request was filed.
  select * into v_member from public.members where id = v_request.target_member_id for update;

  if exists (select 1 from public.super_admin_allowlist s where s.user_id = v_member.id)
     or exists (select 1 from public.admin_assignments a where a.member_id = v_member.id and a.ended_at is null) then
    raise exception 'Target is now a Super Admin or holds an admin position; reject this request instead'
      using errcode = 'PT409';
  end if;

  if v_request.type = 'member_deletion' then
    if v_member.account_status = 'deleted' then
      raise exception 'Member is already deleted; reject this request instead'
        using errcode = 'PT409';
    end if;

    v_before := private.member_snapshot(v_member.id);

    update public.members
       set account_status = 'deleted', deleted_at = now()
     where id = v_member.id;
    update public.regional_registrations
       set status = 'deleted'
     where member_id = v_member.id and status <> 'deleted';
    update public.community_registrations
       set status = 'deleted'
     where member_id = v_member.id and status <> 'deleted';

    v_after := private.member_snapshot(v_member.id);

  elsif v_request.type = 'member_blacklist' then
    if v_member.account_status in ('deleted', 'blacklisted') then
      raise exception 'Member is already %; reject this request instead', v_member.account_status
        using errcode = 'PT409';
    end if;

    v_before := jsonb_build_object('member', to_jsonb(v_member));

    update public.members set account_status = 'blacklisted' where id = v_member.id;

    insert into public.blacklist_entries (member_id, email_hash, phone_hash, reason, request_id, created_by)
    values (v_member.id,
            private.identity_hash('email', v_member.email),
            private.identity_hash('phone', v_member.phone),
            v_request.reason, v_request.id, (select auth.uid()));

    v_after := jsonb_build_object('member', (select to_jsonb(m) from public.members m where m.id = v_member.id));

  else
    -- Community record change: the registration only. members is never written here.
    select * into v_reg from public.community_registrations where id = v_request.target_registration_id for update;

    if v_reg.status <> 'active' then
      raise exception 'Registration is now %; reject this request instead', v_reg.status
        using errcode = 'PT409';
    end if;

    v_before := jsonb_build_object('registration', to_jsonb(v_reg));

    if v_request.type = 'community_record_update' then
      update public.community_registrations
         set answers = v_request.requested_change -> 'answers'
       where id = v_reg.id;
    else
      update public.community_registrations
         set status = 'deleted'
       where id = v_reg.id;
    end if;

    v_after := jsonb_build_object('registration',
      (select to_jsonb(c) from public.community_registrations c where c.id = v_reg.id));
  end if;

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

-- public.cancel_request (from 20260928121500_approval_rpcs.sql, 1 site)
create or replace function public.cancel_request(p_request_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_request public.approval_requests%rowtype;
begin
  if p_request_id is null then
    raise exception 'request_id is required' using errcode = 'invalid_parameter_value';
  end if;

  select * into v_request from public.approval_requests where id = p_request_id for update;

  -- Only the requester, and only while their account is active. Others get "not found".
  if not found or v_request.requested_by is distinct from (select auth.uid())
     or not (select private.is_active_member()) then
    raise exception 'Request not found' using errcode = 'insufficient_privilege';
  end if;

  if v_request.status <> 'pending' then
    raise exception 'Request is already %', v_request.status using errcode = 'PT409';
  end if;

  update public.approval_requests
     set status = 'cancelled', reviewed_by = (select auth.uid()), reviewed_at = now()
   where id = v_request.id;

  perform private.write_audit(
    'request.cancel', 'approval_requests', v_request.id::text,
    jsonb_build_object('status', 'pending'),
    jsonb_build_object('status', 'cancelled', 'type', v_request.type),
    v_request.id);

  return v_request.id;
end;
$$;

-- public.svc_account_status_for_auth (from 20260928121800_edge_function_support.sql, 1 site)
create or replace function public.svc_account_status_for_auth(p_actor uuid, p_member_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member public.members%rowtype;
begin
  perform private.bind_super_admin_actor(p_actor);

  select * into v_member from public.members where id = p_member_id;
  if not found then
    raise exception 'Member % does not exist', p_member_id using errcode = 'no_data_found';
  end if;
  if v_member.anonymised_at is not null then
    raise exception 'Member % was hard-deleted; there is no Auth user', p_member_id
      using errcode = 'PT409';
  end if;

  return jsonb_build_object(
    'member_id', v_member.id,
    'account_status', v_member.account_status,
    'ban', v_member.account_status <> 'active');
end;
$$;

-- private.validate_contact_change (from 20260928121800_edge_function_support.sql, 1 site)
create or replace function private.validate_contact_change(p_member_id uuid, p_email text, p_phone text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member public.members%rowtype;
  v_email  text := nullif(lower(btrim(p_email)), '');
  v_phone  text;
begin
  select * into v_member from public.members where id = p_member_id for update;
  if not found then
    raise exception 'Member % does not exist', p_member_id using errcode = 'no_data_found';
  end if;
  if v_member.anonymised_at is not null then
    raise exception 'Member % was hard-deleted', p_member_id using errcode = 'PT409';
  end if;

  if v_email is null and nullif(btrim(p_phone), '') is null then
    raise exception 'Provide a new email and/or phone' using errcode = 'invalid_parameter_value';
  end if;

  if v_email is not null then
    if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' or length(v_email) > 254 then
      raise exception 'Invalid email address' using errcode = 'invalid_parameter_value';
    end if;
    if v_email = v_member.email then
      v_email := null;  -- unchanged
    end if;
  end if;

  if nullif(btrim(p_phone), '') is not null then
    v_phone := private.normalise_phone(p_phone);
    if v_phone = v_member.phone then
      v_phone := null;  -- unchanged
    end if;
  end if;

  if v_email is null and v_phone is null then
    raise exception 'Nothing to change: the new values equal the current ones'
      using errcode = 'invalid_parameter_value';
  end if;

  if v_email is not null then
    -- Never hand an address tied to a Super Admin account to anyone (§11).
    if exists (select 1 from public.super_admin_allowlist s
               left join auth.users u on u.id = s.user_id
               left join public.members m on m.id = s.user_id
               where lower(u.email) = v_email or lower(u.email_change) = v_email or m.email = v_email) then
      raise exception 'That email belongs to a Super Admin account' using errcode = 'insufficient_privilege';
    end if;
    if exists (select 1 from public.members where email = v_email and id <> p_member_id)
       or exists (select 1 from auth.users where lower(email) = v_email and id <> p_member_id) then
      raise exception 'That email is already in use' using errcode = 'unique_violation';
    end if;
  end if;

  if v_phone is not null and exists (select 1 from public.members where phone = v_phone and id <> p_member_id) then
    raise exception 'That phone number is already in use' using errcode = 'unique_violation';
  end if;

  return jsonb_build_object(
    'member_id', v_member.id,
    'old_email', v_member.email, 'new_email', v_email,
    'old_phone', v_member.phone, 'new_phone', v_phone);
end;
$$;

-- public.request_hard_delete (from 20260928121800_edge_function_support.sql, 3 sites)
create or replace function public.request_hard_delete(p_member_id uuid, p_reason text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member  public.members%rowtype;
  v_reason  text;
  v_request public.approval_requests%rowtype;
begin
  if not (select private.is_super_admin()) then
    raise exception 'Only a Super Admin can request a hard delete' using errcode = 'insufficient_privilege';
  end if;

  v_reason := private.clean_reason(p_reason, true);

  select * into v_member from public.members where id = p_member_id for update;
  if not found then
    raise exception 'Member % does not exist', p_member_id using errcode = 'invalid_parameter_value';
  end if;
  if v_member.anonymised_at is not null then
    raise exception 'Member is already hard-deleted' using errcode = 'PT409';
  end if;
  if v_member.account_status <> 'deleted' or v_member.deleted_at > now() - interval '30 days' then
    raise exception 'Only members soft-deleted at least 30 days ago can be hard-deleted'
      using errcode = 'PT409';
  end if;
  if exists (select 1 from public.super_admin_allowlist s where s.user_id = p_member_id) then
    raise exception 'Requests cannot target a Super Admin' using errcode = 'PT409';
  end if;

  begin
    insert into public.approval_requests (type, target_member_id, target_snapshot, reason, requested_by)
    values ('member_hard_delete', p_member_id,
            -- Minimal on purpose: this member's personal data is about to be erased.
            jsonb_build_object('member_id', v_member.id, 'member_code', v_member.member_code,
                               'deleted_at', v_member.deleted_at),
            v_reason, (select auth.uid()))
    returning * into v_request;
  exception when unique_violation then
    raise exception 'A pending hard-delete request already exists for this member' using errcode = 'unique_violation';
  end;

  perform private.write_audit(
    'request.create', 'approval_requests', v_request.id::text, null,
    jsonb_build_object('type', v_request.type, 'target_member_id', p_member_id, 'reason', v_reason),
    v_request.id);

  return v_request.id;
end;
$$;

-- public.svc_execute_hard_delete (from 20260928121800_edge_function_support.sql, 4 sites)
create or replace function public.svc_execute_hard_delete(p_actor uuid, p_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_request public.approval_requests%rowtype;
  v_member  public.members%rowtype;
begin
  perform private.bind_super_admin_actor(p_actor);

  select * into v_request from public.approval_requests where id = p_request_id for update;
  if not found or v_request.type <> 'member_hard_delete' then
    raise exception 'Hard-delete request % does not exist', p_request_id using errcode = 'no_data_found';
  end if;

  select * into v_member from public.members where id = v_request.target_member_id for update;

  if v_request.status = 'approved' and v_member.anonymised_at is not null then
    return jsonb_build_object('member_id', v_member.id, 'state', 'already_executed');
  end if;

  if v_request.status <> 'pending' then
    raise exception 'Request is already %', v_request.status using errcode = 'PT409';
  end if;

  -- The second Super Admin rule (§10). The table's lifecycle CHECK enforces it again.
  if v_request.requested_by = p_actor then
    raise exception 'A different Super Admin must approve a hard delete' using errcode = 'insufficient_privilege';
  end if;

  if v_member.anonymised_at is not null then
    raise exception 'Member is already hard-deleted' using errcode = 'PT409';
  end if;
  if v_member.account_status <> 'deleted' or v_member.deleted_at > now() - interval '30 days' then
    raise exception 'Member must have been soft-deleted at least 30 days ago'
      using errcode = 'PT409';
  end if;
  if exists (select 1 from public.super_admin_allowlist s where s.user_id = v_member.id) then
    raise exception 'Target is a Super Admin' using errcode = 'PT409';
  end if;

  -- Do not copy the personal data being erased into new audit rows.
  perform set_config('app.suppress_row_audit', 'on', true);

  update public.members
     set full_name      = 'Deleted member',
         preferred_name = null,
         gender         = null,
         bio            = null,
         whatsapp_data  = null,
         email          = 'deleted-' || v_member.id::text || '@deleted.invalid',
         phone          = private.placeholder_phone(v_member.id),
         anonymised_at  = now()
   where id = v_member.id;

  update public.regional_registrations  set answers = '{}'::jsonb where member_id = v_member.id;
  update public.community_registrations set answers = '{}'::jsonb where member_id = v_member.id;

  -- Redact this member's personal data from every request about them (decision: snapshots
  -- are scrubbed; the requests themselves stay, §13).
  update public.approval_requests
     set target_snapshot  = jsonb_build_object('redacted', true, 'member_id', v_member.id,
                                               'member_code', v_member.member_code),
         requested_change = case when requested_change ? 'answers'
                                 then jsonb_build_object('answers', '{}'::jsonb)
                                 else requested_change end
   where target_member_id = v_member.id;

  update public.approval_requests
     set status = 'approved', reviewed_by = p_actor, reviewed_at = now(), executed_at = now()
   where id = v_request.id;

  perform set_config('app.suppress_row_audit', 'off', true);

  perform private.write_audit(
    'member.hard_delete', 'members', v_member.id::text, null,
    jsonb_build_object('member_id', v_member.id, 'member_code', v_member.member_code, 'anonymised', true),
    v_request.id);

  return jsonb_build_object('member_id', v_member.id, 'state', 'executed');
end;
$$;
;
