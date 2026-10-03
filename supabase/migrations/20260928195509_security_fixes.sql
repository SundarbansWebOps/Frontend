-- Migration 22: security review fixes (phase 7)
--
-- F1  Scoped admins could not soft-delete events. Postgres checks the updated row against the
--     SELECT policy, which hid deleted events from everyone but Super Admins, so the UPDATE
--     failed. Scoped admins now also see deleted events in their own scope (read-only: the
--     UPDATE policy still requires deleted_at is null for them, so only Super Admins restore).
--
-- F2  Members could change their own login email (or phone) through Supabase Auth's "update
--     user" endpoint, bypassing §11 and leaving auth.users and members out of sync. A trigger
--     on auth.users now refuses any email/phone change unless change-member-contact has
--     authorized exactly that address for that user a moment before (one-time, 5 minutes).
--     The Auth server runs every update as the same role, so a one-time authorization is the
--     only reliable way to tell the Admin API path from a user's self-service request.
--     Bans, sign-ins, password resets and other Auth updates are unaffected.
--
-- F3  Sign-up did not check blacklist hashes (§6, Q11). handle_new_auth_user now refuses a new
--     account whose email or phone matches an active blacklist entry. The hash is only computed
--     when active entries exist, so environments without the Vault key can still sign up.

-- ── F1: events visibility for scoped admins ─────────────────────────────────

drop policy events_select on public.events;

create policy events_select on public.events
  for select to authenticated
  using (
    (deleted_at is null and (select private.is_active_member()))
    or (select private.is_super_admin())
    or (community_id is null and (select private.my_rc_region()) is not null)
    or (community_id = any ((select private.my_community_ids())::smallint[]))
  );

-- ── F2: only authorized email/phone changes in auth.users ──────────────────

create table private.auth_email_authorizations (
  user_id    uuid primary key,
  email      text not null,
  expires_at timestamptz not null,
  created_by uuid not null
);

comment on table private.auth_email_authorizations is
  'One-time permission for the Auth Admin API to set a user''s email (change-member-contact). Consumed by the auth.users guard trigger.';

alter table private.auth_email_authorizations enable row level security;
revoke all on table private.auth_email_authorizations from public, anon, authenticated, service_role;

-- Called by change-member-contact right before each Auth email update (the change, and the
-- revert if the members update fails).
create function public.svc_authorize_auth_email(p_actor uuid, p_member_id uuid, p_email text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text := lower(btrim(p_email));
begin
  perform private.bind_super_admin_actor(p_actor);

  if not exists (select 1 from public.members m where m.id = p_member_id and m.anonymised_at is null) then
    raise exception 'Member % does not exist', p_member_id using errcode = 'no_data_found';
  end if;
  if v_email is null or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'Invalid email address' using errcode = 'invalid_parameter_value';
  end if;

  insert into private.auth_email_authorizations (user_id, email, expires_at, created_by)
  values (p_member_id, v_email, now() + interval '5 minutes', p_actor)
  on conflict (user_id) do update
    set email = excluded.email, expires_at = excluded.expires_at, created_by = excluded.created_by;
end;
$$;

comment on function public.svc_authorize_auth_email(uuid, uuid, text) is
  'Edge Functions only. Lets the next Auth Admin API update set this user''s email to exactly p_email (5 minutes, one use).';

revoke execute on function public.svc_authorize_auth_email(uuid, uuid, text) from public, anon, authenticated;
grant execute on function public.svc_authorize_auth_email(uuid, uuid, text) to service_role;

create function private.guard_auth_contact_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_target text;
begin
  -- Phone is not used for login (Q7); members.phone is the source of truth. Never change it here.
  if new.phone is distinct from old.phone
     or coalesce(new.phone_change, '') not in ('', coalesce(old.phone_change, '')) then
    raise exception 'Phone numbers are changed only by a Super Admin (change-member-contact)'
      using errcode = 'insufficient_privilege';
  end if;

  -- Email: either set directly (Admin API) or staged in email_change (self-service flow).
  if lower(new.email) is distinct from lower(old.email) then
    v_target := lower(new.email);
  elsif coalesce(new.email_change, '') <> '' and new.email_change is distinct from old.email_change then
    v_target := lower(new.email_change);
  else
    return new;
  end if;

  delete from private.auth_email_authorizations a
  where a.user_id = new.id and a.email = v_target and a.expires_at > now();

  if not found then
    raise exception 'Email addresses are changed only by a Super Admin (change-member-contact)'
      using errcode = 'insufficient_privilege';
  end if;

  return new;
end;
$$;

revoke execute on function private.guard_auth_contact_change() from public, anon, authenticated, service_role;

create trigger guard_auth_contact_change
  before update of email, email_change, phone, phone_change on auth.users
  for each row execute function private.guard_auth_contact_change();

-- ── F3: blacklist check at sign-up ──────────────────────────────────────────
-- Same as migration 9 plus the blacklist check before the member row is created.

create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_meta      jsonb    := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_email     text     := lower(btrim(new.email));
  v_full_name text     := btrim(v_meta ->> 'full_name');
  v_gender    text     := nullif(btrim(v_meta ->> 'gender'), '');
  v_region_id smallint;
  v_phone     text;
begin
  if v_email is null or v_email = '' then
    raise exception 'An email address is required to sign up'
      using errcode = 'invalid_parameter_value';
  end if;

  if v_full_name is null or v_full_name = '' then
    raise exception 'full_name is required'
      using errcode = 'invalid_parameter_value';
  end if;

  select r.id into v_region_id
  from public.regions r
  where r.code = lower(btrim(v_meta ->> 'region_code'));

  if v_region_id is null then
    raise exception 'A valid region_code is required'
      using errcode = 'invalid_parameter_value';
  end if;

  v_phone := private.normalise_phone(v_meta ->> 'phone');

  -- Blacklisted people may not register again under the same email or phone (§6, Q11).
  -- The reason is not revealed to the client (Auth reports a generic database error).
  if exists (select 1 from public.blacklist_entries b where b.lifted_at is null) then
    if exists (select 1 from public.blacklist_entries b
               where b.lifted_at is null
                 and (b.email_hash = private.identity_hash('email', v_email)
                      or b.phone_hash = private.identity_hash('phone', v_phone))) then
      raise exception 'Registration is not allowed for this account'
        using errcode = 'insufficient_privilege';
    end if;
  end if;

  insert into public.members (id, member_code, full_name, email, phone, gender, region_id)
  values (
    new.id,
    private.member_code_for(v_email),
    v_full_name,
    v_email,
    v_phone,
    v_gender,
    v_region_id
  );

  return new;
end;
$$;
;
