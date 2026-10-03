-- Migration 15: approval workflow RPCs
-- Spec §10 (general rules, deletion, blacklist, community record changes), §5, §13, §14.
--
--   request_member_deletion(member_id, reason)            RC, own region only
--   request_blacklist(member_id, reason)                  RC, own region only
--   request_community_change(registration_id, type, reason, new_answers)
--                                                         Head/Co-Head, own community only
--   approve_request(request_id, note)                     Super Admin, not own request
--   reject_request(request_id, note)                      Super Admin, not own request
--   cancel_request(request_id)                            the requester, pending only
--
-- All are security definer with an empty search_path. Scope comes from auth.uid() through
-- the helpers; ids from the client only name the target and are checked against that scope.
-- Out-of-scope and non-existent targets return the same error, so ids cannot be probed.
--
-- General rules (§10, default confirmed): nobody may target a Super Admin, a member with an
-- active position, or themselves. One pending request per (type, target). Approval
-- re-checks the target and applies the change and the decision in one transaction.
-- Community changes touch community_registrations only, never members.
--
-- Out of scope here: member_hard_delete (needs the hard-delete-member Edge Function; it
-- cannot be created or approved yet), Super Admin direct actions, and the Auth ban (the
-- apply-account-status Edge Function). Until that function exists, RLS is the only block on
-- a deleted/blacklisted account (§14 second layer).
--
-- Error codes: 42501 caller not allowed or target out of scope | 22023 invalid input |
--              55000 target or request in the wrong state | 23505 duplicate pending request |
--              0A000 request type not supported yet

-- ── Identity hashes (blacklist) ─────────────────────────────────────────────
-- HMAC-SHA256 keyed by the Vault secret 'blacklist_hash_pepper'. The kind prefix keeps
-- email and phone hashes in separate spaces. The secret is created per environment
-- (seed.sql for dev; separately in production), never in a migration.

create function private.identity_hash(p_kind text, p_value text)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_key   text;
  v_value text;
begin
  if p_kind = 'email' then
    v_value := lower(btrim(p_value));
  elsif p_kind = 'phone' then
    v_value := private.normalise_phone(p_value);
  else
    raise exception 'Unknown identity kind %', p_kind using errcode = 'invalid_parameter_value';
  end if;

  if v_value is null or v_value = '' then
    raise exception 'A % value is required', p_kind using errcode = 'invalid_parameter_value';
  end if;

  select s.decrypted_secret into v_key
  from vault.decrypted_secrets s
  where s.name = 'blacklist_hash_pepper';

  if v_key is null or length(v_key) < 32 then
    raise exception 'Vault secret blacklist_hash_pepper is missing or too short'
      using errcode = 'object_not_in_prerequisite_state';
  end if;

  return encode(extensions.hmac(p_kind || ':' || v_value, v_key, 'sha256'), 'hex');
end;
$$;

comment on function private.identity_hash(text, text) is
  'HMAC-SHA256 of a normalised email or phone, keyed by Vault secret blacklist_hash_pepper (§6).';

revoke execute on function private.identity_hash(text, text) from public, anon, authenticated;
grant execute on function private.identity_hash(text, text) to service_role;

-- ── Shared checks ───────────────────────────────────────────────────────────

-- The general targeting rule (§10). Called with the target already locked.
create function private.assert_requestable_target(p_member_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_member_id = (select auth.uid()) then
    raise exception 'You cannot file a request about yourself'
      using errcode = 'object_not_in_prerequisite_state';
  end if;

  if exists (select 1 from public.super_admin_allowlist s where s.user_id = p_member_id) then
    raise exception 'Requests cannot target a Super Admin'
      using errcode = 'object_not_in_prerequisite_state';
  end if;

  if exists (select 1 from public.admin_assignments a where a.member_id = p_member_id and a.ended_at is null) then
    raise exception 'Requests cannot target a member who holds an admin position'
      using errcode = 'object_not_in_prerequisite_state';
  end if;
end;
$$;

revoke execute on function private.assert_requestable_target(uuid) from public, anon, authenticated, service_role;

create function private.clean_reason(p_text text, p_required boolean)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  v text := nullif(btrim(p_text), '');
begin
  if v is null and p_required then
    raise exception 'A reason is required' using errcode = 'invalid_parameter_value';
  end if;
  if v is not null and length(v) > 2000 then
    raise exception 'Text must be at most 2000 characters' using errcode = 'invalid_parameter_value';
  end if;
  return v;
end;
$$;

revoke execute on function private.clean_reason(text, boolean) from public, anon, authenticated, service_role;

-- Snapshot of a member and their registrations, for member requests.
create function private.member_snapshot(p_member_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'member', (select to_jsonb(m) from public.members m where m.id = p_member_id),
    'regional_registration',
      (select to_jsonb(r) from public.regional_registrations r where r.member_id = p_member_id),
    'community_registrations',
      coalesce((select jsonb_agg(to_jsonb(c) order by c.community_id)
                from public.community_registrations c where c.member_id = p_member_id), '[]'::jsonb)
  );
$$;

revoke execute on function private.member_snapshot(uuid) from public, anon, authenticated, service_role;

-- Shared body of the two RC request functions.
create function private.file_member_request(
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
    raise exception 'Member is already deleted' using errcode = 'object_not_in_prerequisite_state';
  end if;

  if p_type = 'member_blacklist' and v_member.account_status = 'blacklisted' then
    raise exception 'Member is already blacklisted' using errcode = 'object_not_in_prerequisite_state';
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

revoke execute on function private.file_member_request(public.request_type, uuid, text) from public, anon, authenticated, service_role;

-- ── RC requests ─────────────────────────────────────────────────────────────

create function public.request_member_deletion(p_member_id uuid, p_reason text)
returns uuid
language sql
security definer
set search_path = ''
as $$
  select private.file_member_request('member_deletion', p_member_id, p_reason);
$$;

comment on function public.request_member_deletion(uuid, text) is
  'RC only, member of own region (§10). Files a member_deletion request; the member is unchanged until approval.';

create function public.request_blacklist(p_member_id uuid, p_reason text)
returns uuid
language sql
security definer
set search_path = ''
as $$
  select private.file_member_request('member_blacklist', p_member_id, p_reason);
$$;

comment on function public.request_blacklist(uuid, text) is
  'RC only, member of own region (§10). Files a member_blacklist request; nothing changes until approval.';

-- ── Community admin requests ────────────────────────────────────────────────

create function public.request_community_change(
  p_registration_id uuid,
  p_type            public.request_type,
  p_reason          text,
  p_new_answers     jsonb default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_communities smallint[] := (select private.my_community_ids());
  v_reg         public.community_registrations%rowtype;
  v_reason      text;
  v_change      jsonb;
  v_request     public.approval_requests%rowtype;
begin
  if cardinality(v_communities) = 0 then
    raise exception 'Only a Community Head or Co-Head can file this request'
      using errcode = 'insufficient_privilege';
  end if;

  if p_registration_id is null or p_type is null then
    raise exception 'registration_id and type are required' using errcode = 'invalid_parameter_value';
  end if;

  if p_type not in ('community_record_update', 'community_record_deletion') then
    raise exception 'type must be community_record_update or community_record_deletion'
      using errcode = 'invalid_parameter_value';
  end if;

  v_reason := private.clean_reason(p_reason, true);

  if p_type = 'community_record_update' then
    if p_new_answers is null or jsonb_typeof(p_new_answers) <> 'object' then
      raise exception 'new_answers must be a JSON object for an update request'
        using errcode = 'invalid_parameter_value';
    end if;
    if octet_length(p_new_answers::text) > 20000 then
      raise exception 'new_answers is too large' using errcode = 'invalid_parameter_value';
    end if;
    v_change := jsonb_build_object('answers', p_new_answers);
  else
    if p_new_answers is not null then
      raise exception 'new_answers is only allowed for an update request'
        using errcode = 'invalid_parameter_value';
    end if;
    v_change := '{}'::jsonb;
  end if;

  select * into v_reg from public.community_registrations where id = p_registration_id for update;

  -- Same answer for "does not exist", "other community" and "not active" (they cannot see it).
  if not found or not (v_reg.community_id = any (v_communities)) or v_reg.status <> 'active' then
    raise exception 'Registration not found in your community' using errcode = 'insufficient_privilege';
  end if;

  perform private.assert_requestable_target(v_reg.member_id);

  begin
    insert into public.approval_requests
      (type, target_member_id, target_registration_id, requested_change, target_snapshot, reason, requested_by)
    values
      (p_type, v_reg.member_id, v_reg.id, v_change, jsonb_build_object('registration', to_jsonb(v_reg)),
       v_reason, (select auth.uid()))
    returning * into v_request;
  exception when unique_violation then
    raise exception 'A pending % request already exists for this registration', p_type
      using errcode = 'unique_violation';
  end;

  perform private.write_audit(
    'request.create', 'approval_requests', v_request.id::text, null,
    jsonb_build_object('type', v_request.type, 'target_registration_id', v_request.target_registration_id,
                       'requested_change', v_request.requested_change, 'reason', v_request.reason),
    v_request.id);

  return v_request.id;
end;
$$;

comment on function public.request_community_change(uuid, public.request_type, text, jsonb) is
  'Head/Co-Head only, registration in own community (§10). Update (new_answers) or deletion request; never touches members.';

-- ── Review ──────────────────────────────────────────────────────────────────

-- Locks and returns a pending request the calling Super Admin may review.
create function private.lock_request_for_review(p_request_id uuid)
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
    raise exception 'Request is already %', v_request.status using errcode = 'object_not_in_prerequisite_state';
  end if;

  return v_request;
end;
$$;

revoke execute on function private.lock_request_for_review(uuid) from public, anon, authenticated, service_role;

create function public.approve_request(p_request_id uuid, p_note text default null)
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
      using errcode = 'object_not_in_prerequisite_state';
  end if;

  if v_request.type = 'member_deletion' then
    if v_member.account_status = 'deleted' then
      raise exception 'Member is already deleted; reject this request instead'
        using errcode = 'object_not_in_prerequisite_state';
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
        using errcode = 'object_not_in_prerequisite_state';
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
        using errcode = 'object_not_in_prerequisite_state';
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

comment on function public.approve_request(uuid, text) is
  'Super Admin only, not own request (§10). Re-checks the target, applies the change and records the decision in one transaction. Audited.';

create function public.reject_request(p_request_id uuid, p_note text default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_request public.approval_requests%rowtype;
  v_note    text := private.clean_reason(p_note, false);
begin
  v_request := private.lock_request_for_review(p_request_id);

  update public.approval_requests
     set status = 'rejected', reviewed_by = (select auth.uid()), reviewed_at = now(), review_note = v_note
   where id = v_request.id;

  perform private.write_audit(
    'request.reject', 'approval_requests', v_request.id::text,
    jsonb_build_object('status', 'pending'),
    jsonb_build_object('status', 'rejected', 'type', v_request.type, 'review_note', v_note),
    v_request.id);

  return v_request.id;
end;
$$;

comment on function public.reject_request(uuid, text) is
  'Super Admin only, not own request (§10). Marks the request rejected; the target is not touched. Audited.';

create function public.cancel_request(p_request_id uuid)
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
    raise exception 'Request is already %', v_request.status using errcode = 'object_not_in_prerequisite_state';
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

comment on function public.cancel_request(uuid) is
  'The requester cancels their own pending request (§10). Audited.';

-- ── Grants ──────────────────────────────────────────────────────────────────

revoke execute on function public.request_member_deletion(uuid, text)                           from public, anon, service_role;
revoke execute on function public.request_blacklist(uuid, text)                                 from public, anon, service_role;
revoke execute on function public.request_community_change(uuid, public.request_type, text, jsonb) from public, anon, service_role;
revoke execute on function public.approve_request(uuid, text)                                   from public, anon, service_role;
revoke execute on function public.reject_request(uuid, text)                                    from public, anon, service_role;
revoke execute on function public.cancel_request(uuid)                                          from public, anon, service_role;

grant execute on function public.request_member_deletion(uuid, text)                           to authenticated;
grant execute on function public.request_blacklist(uuid, text)                                 to authenticated;
grant execute on function public.request_community_change(uuid, public.request_type, text, jsonb) to authenticated;
grant execute on function public.approve_request(uuid, text)                                   to authenticated;
grant execute on function public.reject_request(uuid, text)                                    to authenticated;
grant execute on function public.cancel_request(uuid)                                          to authenticated;
;
