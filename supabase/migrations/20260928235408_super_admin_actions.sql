-- Migration 24: Super Admin direct actions, automatic position ending, hard-delete cleanup
-- Spec §10 ("Super Admins may soft-delete / blacklist and lift directly; audited"), §11
-- (region is a protected field changed by a Super Admin), §15 (soft delete reversible), §3.
--
-- sa_soft_delete_member(member_id, reason)      active/suspended/blacklisted -> deleted
-- sa_restore_member(member_id, note)            deleted (not hard-deleted) -> active
-- sa_blacklist_member(member_id, reason)        -> blacklisted + blacklist_entries row
-- sa_lift_blacklist(member_id, note)            lifts the active entry; blacklisted -> active
-- sa_set_suspended(member_id, suspended, note)  active <-> suspended
-- sa_change_member_region(member_id, region_id, reason)
--
-- All: active Super Admin only; never against a Super Admin (allowlist changes by migration)
-- or the caller themselves; audited. After any status change the frontend calls the
-- apply-account-status Edge Function so the Auth ban follows (§14).
-- Restoring a member does not revive their registrations; they resubmit the forms.
--
-- Positions (§3): when an account stops being active (suspended, blacklisted, deleted), its
-- active admin position ends automatically and the revocation is audited.
-- Hard delete: member_private is cleared when a member is anonymised.

-- ── Shared target lookup ────────────────────────────────────────────────────

create function private.lock_sa_target(p_member_id uuid)
returns public.members
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member public.members%rowtype;
begin
  if not (select private.is_super_admin()) then
    raise exception 'Only a Super Admin can do this' using errcode = 'insufficient_privilege';
  end if;

  select * into v_member from public.members where id = p_member_id for update;
  if not found then
    raise exception 'Member % does not exist', p_member_id using errcode = 'no_data_found';
  end if;
  if v_member.id = (select auth.uid()) then
    raise exception 'You cannot do this to your own account' using errcode = 'PT409';
  end if;
  if exists (select 1 from public.super_admin_allowlist s where s.user_id = v_member.id) then
    raise exception 'Super Admin accounts are managed by migration' using errcode = 'PT409';
  end if;
  if v_member.anonymised_at is not null then
    raise exception 'Member was hard-deleted' using errcode = 'PT409';
  end if;

  return v_member;
end;
$$;

revoke execute on function private.lock_sa_target(uuid) from public, anon, authenticated, service_role;

-- ── Soft delete / restore ───────────────────────────────────────────────────

create function public.sa_soft_delete_member(p_member_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member public.members%rowtype := private.lock_sa_target(p_member_id);
  v_reason text := private.clean_reason(p_reason, true);
  v_before jsonb := private.member_snapshot(p_member_id);
begin
  if v_member.account_status = 'deleted' then
    raise exception 'Member is already deleted' using errcode = 'PT409';
  end if;

  update public.members set account_status = 'deleted', deleted_at = now() where id = p_member_id;
  update public.regional_registrations  set status = 'deleted' where member_id = p_member_id and status <> 'deleted';
  update public.community_registrations set status = 'deleted' where member_id = p_member_id and status <> 'deleted';

  perform private.write_audit('member.soft_delete', 'members', p_member_id::text, v_before,
                              jsonb_build_object('reason', v_reason, 'direct', true));
end;
$$;

create function public.sa_restore_member(p_member_id uuid, p_note text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member public.members%rowtype := private.lock_sa_target(p_member_id);
  v_note   text := private.clean_reason(p_note, false);
begin
  if v_member.account_status <> 'deleted' then
    raise exception 'Member is not deleted' using errcode = 'PT409';
  end if;
  if exists (select 1 from public.blacklist_entries b where b.member_id = p_member_id and b.lifted_at is null) then
    raise exception 'Member is blacklisted; lift the blacklist instead' using errcode = 'PT409';
  end if;

  update public.members set account_status = 'active', deleted_at = null where id = p_member_id;

  perform private.write_audit('member.restore', 'members', p_member_id::text,
                              jsonb_build_object('account_status', 'deleted'),
                              jsonb_build_object('account_status', 'active', 'note', v_note));
end;
$$;

-- ── Blacklist / lift ────────────────────────────────────────────────────────

create function public.sa_blacklist_member(p_member_id uuid, p_reason text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member public.members%rowtype := private.lock_sa_target(p_member_id);
  v_reason text := private.clean_reason(p_reason, true);
  v_entry  uuid;
begin
  if v_member.account_status in ('deleted', 'blacklisted') then
    raise exception 'Member is already %', v_member.account_status using errcode = 'PT409';
  end if;

  update public.members set account_status = 'blacklisted' where id = p_member_id;

  insert into public.blacklist_entries (member_id, email_hash, phone_hash, reason, created_by)
  values (p_member_id, private.identity_hash('email', v_member.email), private.identity_hash('phone', v_member.phone),
          v_reason, (select auth.uid()))
  returning id into v_entry;

  perform private.write_audit('member.blacklist', 'members', p_member_id::text,
                              jsonb_build_object('account_status', v_member.account_status),
                              jsonb_build_object('account_status', 'blacklisted', 'reason', v_reason,
                                                 'blacklist_entry_id', v_entry, 'direct', true));
  return v_entry;
end;
$$;

create function public.sa_lift_blacklist(p_member_id uuid, p_note text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member public.members%rowtype := private.lock_sa_target(p_member_id);
  v_note   text := private.clean_reason(p_note, false);
begin
  update public.blacklist_entries
     set lifted_at = now(), lifted_by = (select auth.uid())
   where member_id = p_member_id and lifted_at is null;

  if not found then
    raise exception 'Member is not blacklisted' using errcode = 'PT409';
  end if;

  -- A blacklisted member becomes active again; a deleted one stays deleted (restore separately).
  if v_member.account_status = 'blacklisted' then
    update public.members set account_status = 'active' where id = p_member_id;
  end if;

  perform private.write_audit('member.blacklist_lift', 'members', p_member_id::text,
                              jsonb_build_object('account_status', v_member.account_status),
                              jsonb_build_object('account_status',
                                case when v_member.account_status = 'blacklisted' then 'active'
                                     else v_member.account_status::text end,
                                'note', v_note));
end;
$$;

-- ── Suspend / reinstate ─────────────────────────────────────────────────────

create function public.sa_set_suspended(p_member_id uuid, p_suspended boolean, p_note text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member public.members%rowtype := private.lock_sa_target(p_member_id);
  v_note   text := private.clean_reason(p_note, false);
  v_from   public.account_status := case when p_suspended then 'active' else 'suspended' end;
  v_to     public.account_status := case when p_suspended then 'suspended' else 'active' end;
begin
  if p_suspended is null then
    raise exception 'suspended must be true or false' using errcode = 'invalid_parameter_value';
  end if;
  if v_member.account_status <> v_from then
    raise exception 'Member is %, expected %', v_member.account_status, v_from using errcode = 'PT409';
  end if;

  update public.members set account_status = v_to where id = p_member_id;

  perform private.write_audit(case when p_suspended then 'member.suspend' else 'member.reinstate' end,
                              'members', p_member_id::text,
                              jsonb_build_object('account_status', v_from),
                              jsonb_build_object('account_status', v_to, 'note', v_note));
end;
$$;

-- ── Region change (§11) ─────────────────────────────────────────────────────

create function public.sa_change_member_region(p_member_id uuid, p_region_id smallint, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member public.members%rowtype := private.lock_sa_target(p_member_id);
  v_reason text := private.clean_reason(p_reason, true);
begin
  if p_region_id is null or not exists (select 1 from public.regions r where r.id = p_region_id) then
    raise exception 'Region % does not exist', p_region_id using errcode = 'invalid_parameter_value';
  end if;
  if v_member.region_id = p_region_id then
    raise exception 'Member is already in that region' using errcode = 'PT409';
  end if;

  -- An active RC position ends automatically (members_end_rc_on_region_change, §3).
  update public.members set region_id = p_region_id where id = p_member_id;
  -- The regional registration follows the member (its trigger copies the member's region).
  update public.regional_registrations set region_id = p_region_id where member_id = p_member_id;

  perform private.write_audit('member.region_change', 'members', p_member_id::text,
                              jsonb_build_object('region_id', v_member.region_id),
                              jsonb_build_object('region_id', p_region_id, 'reason', v_reason));
end;
$$;

-- ── Positions end when an account stops being active (§3) ──────────────────

create function private.end_position_on_inactive()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old public.admin_assignments%rowtype;
begin
  update public.admin_assignments
     set ended_at = now()
   where member_id = new.id and ended_at is null
  returning * into v_old;

  if found then
    perform private.write_audit(
      'position.revoke', 'admin_assignments', v_old.id::text,
      to_jsonb(v_old) - 'ended_at',
      to_jsonb(v_old) || jsonb_build_object('reason', 'account_' || new.account_status));
  end if;
  return null;
end;
$$;

revoke execute on function private.end_position_on_inactive() from public, anon, authenticated, service_role;

create trigger members_end_position_on_inactive
  after update of account_status on public.members
  for each row
  when (old.account_status = 'active' and new.account_status <> 'active')
  execute function private.end_position_on_inactive();

-- ── Hard delete also clears member_private (§15) ────────────────────────────

create function private.clear_private_on_anonymise()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.member_private where member_id = new.id;
  return null;
end;
$$;

revoke execute on function private.clear_private_on_anonymise() from public, anon, authenticated, service_role;

create trigger members_clear_private_on_anonymise
  after update of anonymised_at on public.members
  for each row
  when (old.anonymised_at is null and new.anonymised_at is not null)
  execute function private.clear_private_on_anonymise();

-- ── Grants ──────────────────────────────────────────────────────────────────

revoke execute on function public.sa_soft_delete_member(uuid, text)              from public, anon, service_role;
revoke execute on function public.sa_restore_member(uuid, text)                  from public, anon, service_role;
revoke execute on function public.sa_blacklist_member(uuid, text)                from public, anon, service_role;
revoke execute on function public.sa_lift_blacklist(uuid, text)                  from public, anon, service_role;
revoke execute on function public.sa_set_suspended(uuid, boolean, text)          from public, anon, service_role;
revoke execute on function public.sa_change_member_region(uuid, smallint, text)  from public, anon, service_role;

grant execute on function public.sa_soft_delete_member(uuid, text)              to authenticated;
grant execute on function public.sa_restore_member(uuid, text)                  to authenticated;
grant execute on function public.sa_blacklist_member(uuid, text)                to authenticated;
grant execute on function public.sa_lift_blacklist(uuid, text)                  to authenticated;
grant execute on function public.sa_set_suspended(uuid, boolean, text)          to authenticated;
grant execute on function public.sa_change_member_region(uuid, smallint, text)  to authenticated;
;
