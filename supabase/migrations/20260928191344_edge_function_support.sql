-- Migration 18: database side of the phase 5 Edge Functions
-- Spec §10 (hard delete), §11 (change-member-contact), §14 (ban at login), §15, §16.
-- Decisions (phase 5): apply-account-status syncs the Auth ban to members.account_status;
-- hard delete = request_hard_delete RPC (30-day wait) + approval through the
-- hard-delete-member Edge Function by a different Super Admin; anonymisation uses
-- placeholders and redacts the member's request snapshots. Past audit rows are kept as-is.
--
-- How the Edge Functions authorize:
--   1. The function verifies the caller's JWT with Supabase Auth (auth.getUser) -> user id.
--   2. Every svc_* RPC below takes that id as p_actor and checks it with
--      private.is_super_admin_id() INSIDE the database before doing anything.
--   3. svc_* RPCs are executable by service_role only (the Edge Functions' secret key), never
--      by anon/authenticated, so no client can call them or pass a forged p_actor.
-- The Auth Admin API calls (ban, email change, delete user) happen in the Edge Function
-- between/after these RPCs, since the database cannot reach Auth.

-- ── Audit plumbing ──────────────────────────────────────────────────────────

-- Actor fallback for service_role calls: with no user session, auth.uid() is null, so the
-- svc_* RPCs set app.actor_id (transaction-local) and triggers inherit the verified actor.
create or replace function private.write_audit(
  p_action       text,
  p_target_table text  default null,
  p_target_id    text  default null,
  p_old_values   jsonb default null,
  p_new_values   jsonb default null,
  p_request_id   uuid  default null,
  p_result       text  default 'success',
  p_actor_id     uuid  default null
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id bigint;
begin
  insert into public.audit_log
    (actor_id, action, target_table, target_id, old_values, new_values, request_id, result)
  values
    (coalesce((select auth.uid()), p_actor_id, nullif(current_setting('app.actor_id', true), '')::uuid),
     p_action, p_target_table, p_target_id, p_old_values, p_new_values, p_request_id, p_result)
  returning id into v_id;

  return v_id;
end;
$$;

-- Hard delete must not copy the personal data it is erasing into new audit rows, so the
-- row-level trigger can be switched off for one transaction by definer code only
-- (app.suppress_row_audit; not settable through the Data API).
create or replace function private.audit_row_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old     jsonb := case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end;
  v_new     jsonb := case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end;
  v_id      text  := coalesce(v_new ->> 'id', v_old ->> 'id');
  v_changed text[];
begin
  if current_setting('app.suppress_row_audit', true) = 'on' then
    return null;
  end if;

  if tg_op = 'UPDATE' then
    select array_agg(k order by k) into v_changed
    from jsonb_object_keys(v_new) as k
    where (tg_nargs = 0 or k = any (tg_argv))
      and v_old -> k is distinct from v_new -> k;

    if v_changed is null then
      return null;
    end if;

    select jsonb_object_agg(k, v_old -> k), jsonb_object_agg(k, v_new -> k)
      into v_old, v_new
    from unnest(v_changed) as k;
  end if;

  perform private.write_audit(
    tg_table_name || '.' || lower(tg_op),
    tg_table_name,
    v_id,
    v_old,
    v_new);

  return null;
end;
$$;

-- ── Super Admin check for an explicit id ────────────────────────────────────

create function private.is_super_admin_id(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_user_id is not null and exists (
    select 1
    from public.super_admin_allowlist s
    join public.members m on m.id = s.user_id
    where s.user_id = p_user_id
      and m.account_status = 'active'
      and m.deleted_at is null
  );
$$;

revoke execute on function private.is_super_admin_id(uuid) from public, anon, authenticated;
grant execute on function private.is_super_admin_id(uuid) to service_role;

-- Verifies the actor and binds it for audit rows written later in this transaction.
create function private.bind_super_admin_actor(p_actor uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.is_super_admin_id(p_actor) then
    raise exception 'Only a Super Admin can do this' using errcode = 'insufficient_privilege';
  end if;
  perform set_config('app.actor_id', p_actor::text, true);
end;
$$;

revoke execute on function private.bind_super_admin_actor(uuid) from public, anon, authenticated, service_role;

-- ── members.anonymised_at ───────────────────────────────────────────────────

alter table public.members add column anonymised_at timestamptz;

alter table public.members add constraint members_anonymised_deleted
  check (anonymised_at is null or (account_status = 'deleted' and deleted_at is not null));

comment on column public.members.anonymised_at is
  'Set by hard delete (§10, §15). Personal fields are placeholders; the Auth user is removed.';

-- ── Gate used first by every Edge Function ──────────────────────────────────

create function public.svc_assert_super_admin(p_actor uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.bind_super_admin_actor(p_actor);
  return true;
end;
$$;

comment on function public.svc_assert_super_admin(uuid) is
  'Edge Functions only (service_role). Raises 42501 unless p_actor is an active Super Admin.';

-- ── apply-account-status ────────────────────────────────────────────────────

create function public.svc_account_status_for_auth(p_actor uuid, p_member_id uuid)
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
      using errcode = 'object_not_in_prerequisite_state';
  end if;

  return jsonb_build_object(
    'member_id', v_member.id,
    'account_status', v_member.account_status,
    'ban', v_member.account_status <> 'active');
end;
$$;

comment on function public.svc_account_status_for_auth(uuid, uuid) is
  'Edge Functions only. Returns the ban decision for a member: banned unless account_status = active (§14).';

-- Audit entry for an Auth Admin API action taken by an Edge Function (success or failure).
create function public.svc_record_auth_action(
  p_actor     uuid,
  p_member_id uuid,
  p_action    text,
  p_details   jsonb,
  p_result    text default 'success'
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.bind_super_admin_actor(p_actor);

  if p_action not in ('auth.ban', 'auth.unban', 'auth.email_change', 'auth.email_revert', 'auth.delete_user') then
    raise exception 'Unknown auth action %', p_action using errcode = 'invalid_parameter_value';
  end if;

  perform private.write_audit(p_action, 'auth.users', p_member_id::text, null,
                              coalesce(p_details, '{}'::jsonb), null, p_result);
end;
$$;

-- ── change-member-contact ───────────────────────────────────────────────────

-- Shared validation. Returns the normalised old/new values; raises on any rule violation.
create function private.validate_contact_change(p_member_id uuid, p_email text, p_phone text)
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
    raise exception 'Member % was hard-deleted', p_member_id using errcode = 'object_not_in_prerequisite_state';
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

revoke execute on function private.validate_contact_change(uuid, text, text) from public, anon, authenticated, service_role;

-- Step 1 (before touching Auth): validate only, no writes.
create function public.svc_prepare_contact_change(p_actor uuid, p_member_id uuid, p_email text, p_phone text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.bind_super_admin_actor(p_actor);
  return private.validate_contact_change(p_member_id, p_email, p_phone);
end;
$$;

-- Step 2 (after Auth accepted the email): re-validate under lock and write members.
-- p_expected_email guards against a concurrent change between the two steps.
create function public.svc_apply_contact_change(
  p_actor          uuid,
  p_member_id      uuid,
  p_email          text,
  p_phone          text,
  p_expected_email text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v jsonb;
begin
  perform private.bind_super_admin_actor(p_actor);
  v := private.validate_contact_change(p_member_id, p_email, p_phone);

  if v ->> 'old_email' is distinct from lower(btrim(p_expected_email)) then
    raise exception 'The member''s email changed meanwhile; reload and retry'
      using errcode = 'serialization_failure';
  end if;

  update public.members
     set email = coalesce(v ->> 'new_email', email),
         phone = coalesce(v ->> 'new_phone', phone)
   where id = p_member_id;

  -- members.update (trigger) records the field-level old/new values with this actor.
  perform private.write_audit(
    'member.contact_change', 'members', p_member_id::text,
    jsonb_strip_nulls(jsonb_build_object(
      'email', case when v ->> 'new_email' is not null then v ->> 'old_email' end,
      'phone', case when v ->> 'new_phone' is not null then v ->> 'old_phone' end)),
    jsonb_strip_nulls(jsonb_build_object('email', v ->> 'new_email', 'phone', v ->> 'new_phone')));

  return v;
end;
$$;

-- ── hard delete ─────────────────────────────────────────────────────────────

-- A Super Admin files the request (§10). A different Super Admin executes it through the
-- hard-delete-member Edge Function; approve_request keeps refusing this type.
create function public.request_hard_delete(p_member_id uuid, p_reason text)
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
    raise exception 'Member is already hard-deleted' using errcode = 'object_not_in_prerequisite_state';
  end if;
  if v_member.account_status <> 'deleted' or v_member.deleted_at > now() - interval '30 days' then
    raise exception 'Only members soft-deleted at least 30 days ago can be hard-deleted'
      using errcode = 'object_not_in_prerequisite_state';
  end if;
  if exists (select 1 from public.super_admin_allowlist s where s.user_id = p_member_id) then
    raise exception 'Requests cannot target a Super Admin' using errcode = 'object_not_in_prerequisite_state';
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

comment on function public.request_hard_delete(uuid, text) is
  'Super Admin only (§10, §15). Target must be soft-deleted >= 30 days. Executed by a different Super Admin via hard-delete-member.';

-- Placeholder phone: +999 is an unassigned country code; 11 digits from the member id keep it
-- unique and E.164-valid.
create function private.placeholder_phone(p_member_id uuid)
returns text
language sql
immutable
set search_path = ''
as $$
  select '+999' || lpad((('x' || substr(md5(p_member_id::text), 1, 12))::bit(48)::bigint % 100000000000)::text, 11, '0');
$$;

revoke execute on function private.placeholder_phone(uuid) from public, anon, authenticated, service_role;

-- Anonymises the member and marks the request approved + executed, in one transaction.
-- Idempotent for retries: if the request was already executed, returns state
-- 'already_executed' so the Edge Function can retry deleting the Auth user.
create function public.svc_execute_hard_delete(p_actor uuid, p_request_id uuid)
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
    raise exception 'Request is already %', v_request.status using errcode = 'object_not_in_prerequisite_state';
  end if;

  -- The second Super Admin rule (§10). The table's lifecycle CHECK enforces it again.
  if v_request.requested_by = p_actor then
    raise exception 'A different Super Admin must approve a hard delete' using errcode = 'insufficient_privilege';
  end if;

  if v_member.anonymised_at is not null then
    raise exception 'Member is already hard-deleted' using errcode = 'object_not_in_prerequisite_state';
  end if;
  if v_member.account_status <> 'deleted' or v_member.deleted_at > now() - interval '30 days' then
    raise exception 'Member must have been soft-deleted at least 30 days ago'
      using errcode = 'object_not_in_prerequisite_state';
  end if;
  if exists (select 1 from public.super_admin_allowlist s where s.user_id = v_member.id) then
    raise exception 'Target is a Super Admin' using errcode = 'object_not_in_prerequisite_state';
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

comment on function public.svc_execute_hard_delete(uuid, uuid) is
  'Edge Functions only. Second Super Admin approves + executes a member_hard_delete request: anonymise, redact snapshots, mark approved.';

-- ── Grants ──────────────────────────────────────────────────────────────────
-- svc_*: service_role only. request_hard_delete: signed-in users (Super Admin check inside).

revoke execute on function public.svc_assert_super_admin(uuid)                              from public, anon, authenticated;
revoke execute on function public.svc_account_status_for_auth(uuid, uuid)                   from public, anon, authenticated;
revoke execute on function public.svc_record_auth_action(uuid, uuid, text, jsonb, text)     from public, anon, authenticated;
revoke execute on function public.svc_prepare_contact_change(uuid, uuid, text, text)        from public, anon, authenticated;
revoke execute on function public.svc_apply_contact_change(uuid, uuid, text, text, text)    from public, anon, authenticated;
revoke execute on function public.svc_execute_hard_delete(uuid, uuid)                       from public, anon, authenticated;
revoke execute on function public.request_hard_delete(uuid, text)                           from public, anon, service_role;

grant execute on function public.svc_assert_super_admin(uuid)                              to service_role;
grant execute on function public.svc_account_status_for_auth(uuid, uuid)                   to service_role;
grant execute on function public.svc_record_auth_action(uuid, uuid, text, jsonb, text)     to service_role;
grant execute on function public.svc_prepare_contact_change(uuid, uuid, text, text)        to service_role;
grant execute on function public.svc_apply_contact_change(uuid, uuid, text, text, text)    to service_role;
grant execute on function public.svc_execute_hard_delete(uuid, uuid)                       to service_role;
grant execute on function public.request_hard_delete(uuid, text)                           to authenticated;
;
