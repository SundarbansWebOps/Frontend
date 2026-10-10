-- Login email changes follow the two-person rule (owner, 2026-10-08)
-- A Super Admin files request_contact_change; a DIFFERENT Super Admin approves it through the
-- change-member-contact Edge Function, which moves the Auth email and members.email together.
-- The function no longer accepts direct changes. Phone numbers change through
-- member_profile_update requests (phone lives in members only).

alter table public.approval_requests drop constraint approval_requests_target_shape;
alter table public.approval_requests add constraint approval_requests_target_shape check (
  (type in ('member_deletion', 'member_blacklist', 'member_hard_delete', 'member_profile_update',
            'member_status_change', 'position_change', 'member_contact_change')
   and target_registration_id is null)
  or (type in ('community_record_update', 'community_record_deletion') and target_registration_id is not null)
);

-- File: Super Admin only; any member except Super Admins (their accounts are managed by migration).
create or replace function public.request_contact_change(p_member_id uuid, p_email text, p_reason text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reason text;
  v_plan   jsonb;
  v_email  text := lower(btrim(coalesce(p_email, '')));
begin
  if not (select private.is_super_admin()) then
    raise exception 'Only a Super Admin can request a login email change' using errcode = 'insufficient_privilege';
  end if;

  v_reason := private.clean_reason(p_reason, true);
  perform private.lock_request_target(p_member_id, true);

  if exists (select 1 from private.signup_email_domains)
     and not exists (select 1 from private.signup_email_domains d where d.domain = split_part(v_email, '@', 2)) then
    raise exception 'The new email must be an IITM student email (@ds.study.iitm.ac.in)'
      using errcode = 'invalid_parameter_value';
  end if;

  if exists (select 1 from public.member_roster r where r.email = v_email) then
    raise exception 'That email is on the roster for someone else' using errcode = 'unique_violation';
  end if;

  -- Same checks the Edge Function repeats at approval: format, unchanged, in use, Super Admin email.
  v_plan := private.validate_contact_change(p_member_id, v_email, null);

  return private.insert_request('member_contact_change', p_member_id,
                                jsonb_build_object('email', v_plan ->> 'new_email'), v_reason);
end;
$$;

revoke execute on function public.request_contact_change(uuid, text, text) from public, anon;
grant execute on function public.request_contact_change(uuid, text, text) to authenticated;

-- Shared checks for the approving Super Admin (Edge Function, service role only).
create or replace function private.lock_contact_request(p_actor uuid, p_request_id uuid)
returns public.approval_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_request public.approval_requests%rowtype;
begin
  perform private.bind_super_admin_actor(p_actor);

  select * into v_request from public.approval_requests where id = p_request_id for update;
  if not found or v_request.type <> 'member_contact_change' then
    raise exception 'Email change request % does not exist', p_request_id using errcode = 'no_data_found';
  end if;
  if v_request.status <> 'pending' then
    raise exception 'Request is already %', v_request.status using errcode = 'PT409';
  end if;
  if v_request.requested_by = p_actor then
    raise exception 'A different Super Admin must approve this change' using errcode = 'insufficient_privilege';
  end if;
  if exists (select 1 from public.super_admin_allowlist s where s.user_id = v_request.target_member_id) then
    raise exception 'Target is now a Super Admin; reject this request instead' using errcode = 'PT409';
  end if;

  return v_request;
end;
$$;

revoke execute on function private.lock_contact_request(uuid, uuid) from public, anon, authenticated;

-- Step 1 (no writes): re-validate and return the plan {member_id, old_email, new_email, ...}.
create or replace function public.svc_contact_request_plan(p_actor uuid, p_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_request public.approval_requests%rowtype := private.lock_contact_request(p_actor, p_request_id);
begin
  return private.validate_contact_change(v_request.target_member_id, v_request.requested_change ->> 'email', null)
         || jsonb_build_object('request_id', v_request.id);
end;
$$;

-- Step 3 (after Auth was updated): write members, mark the request approved, audit.
create or replace function public.svc_complete_contact_request(
  p_actor uuid, p_request_id uuid, p_expected_email text, p_note text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_request public.approval_requests%rowtype := private.lock_contact_request(p_actor, p_request_id);
  v_note    text := private.clean_reason(p_note, false);
  v         jsonb;
begin
  v := public.svc_apply_contact_change(p_actor, v_request.target_member_id,
                                       v_request.requested_change ->> 'email', null, p_expected_email);

  update public.approval_requests
     set status = 'approved', reviewed_by = p_actor, reviewed_at = now(), review_note = v_note,
         executed_at = now()
   where id = v_request.id;

  perform private.write_audit(
    'request.approve', 'approval_requests', v_request.id::text,
    jsonb_build_object('email', v ->> 'old_email'),
    jsonb_build_object('email', v ->> 'new_email', 'type', v_request.type, 'review_note', v_note),
    v_request.id);

  return v;
end;
$$;

revoke execute on function public.svc_contact_request_plan(uuid, uuid),
  public.svc_complete_contact_request(uuid, uuid, text, text) from public, anon, authenticated;
grant execute on function public.svc_contact_request_plan(uuid, uuid),
  public.svc_complete_contact_request(uuid, uuid, text, text) to service_role;

-- The direct path is closed: these were only used by the old change-member-contact.
-- svc_complete_contact_request still calls svc_apply_contact_change internally (as owner).
revoke execute on function public.svc_prepare_contact_change(uuid, uuid, text, text),
  public.svc_apply_contact_change(uuid, uuid, text, text, text) from public, anon, authenticated, service_role;

-- Ordinary approval refuses email changes (they need the Auth update in the Edge Function).
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

  if v_request.type = 'member_contact_change' then
    raise exception 'Login email changes are approved through the change-member-contact Edge Function'
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
