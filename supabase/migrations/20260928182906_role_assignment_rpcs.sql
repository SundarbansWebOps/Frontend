-- Migration 12: role assignment RPCs
-- Spec §3 (role assignment, validation, handover, RC region changes), §2, §13.
--
-- assign_position / revoke_position are the ONLY write path into admin_assignments.
-- Both are security definer with an empty search_path and check the caller inside:
-- only an active Super Admin may call them (private.is_super_admin(), looked up live).
--
-- Rules:
--   * rc: the region is read from members.region_id. There is no region parameter, so the
--     client cannot supply one. Passing a community for rc is rejected as conflicting input.
--   * head / co_head: p_community_id is required and must exist.
--   * Target must be an active member (not suspended, blacklisted or deleted) and must not
--     be a Super Admin.
--   * The slot must be free: an occupied RC region / community Head / Co-Head is rejected
--     with a clear error (never silently taken over). The partial unique indexes from
--     migration 7 remain the final guard under concurrency.
--   * Assigning ends the member's previous active assignment in the same transaction.
--     Re-assigning the exact position and scope they already hold is rejected.
--   * Every assignment and revocation is written to audit_log.
--   * A trigger ends an active RC assignment when that member's region_id changes (§3
--     "Region changes for an RC"), and logs it.
--
-- Failed calls raise and roll back, so they leave no audit row (a rolled-back transaction
-- cannot persist one). Successful changes are always audited.
--
-- Error codes: 42501 not a Super Admin | 22023 invalid/missing input |
--              55000 target not eligible | 23505 slot already held | P0002 nothing to revoke

-- ── assign_position ─────────────────────────────────────────────────────────

create function public.assign_position(
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
      using errcode = 'object_not_in_prerequisite_state';
  end if;

  if exists (select 1 from public.super_admin_allowlist s where s.user_id = p_member_id) then
    raise exception 'Super Admins are not assigned positions; they already have global access'
      using errcode = 'object_not_in_prerequisite_state';
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
        using errcode = 'object_not_in_prerequisite_state';
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

comment on function public.assign_position(uuid, public.admin_position, smallint) is
  'Super Admin only (§3). Assigns rc (region from members.region_id) or head/co_head (community required). Ends any previous active position in the same transaction. Audited.';

-- ── revoke_position ─────────────────────────────────────────────────────────
-- "Normal User" in the §3 table: ends the member's active position.

create function public.revoke_position(p_member_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old public.admin_assignments%rowtype;
begin
  if not (select private.is_super_admin()) then
    raise exception 'Only a Super Admin can revoke positions'
      using errcode = 'insufficient_privilege';
  end if;

  if p_member_id is null then
    raise exception 'member_id is required'
      using errcode = 'invalid_parameter_value';
  end if;

  update public.admin_assignments
     set ended_at = now()
   where member_id = p_member_id and ended_at is null
  returning * into v_old;

  if not found then
    raise exception 'Member % has no active position to revoke', p_member_id
      using errcode = 'no_data_found';
  end if;

  perform private.write_audit(
    'position.revoke', 'admin_assignments', v_old.id::text,
    to_jsonb(v_old) - 'ended_at', to_jsonb(v_old) || jsonb_build_object('reason', 'revoked'));

  return v_old.id;
end;
$$;

comment on function public.revoke_position(uuid) is
  'Super Admin only (§3). Ends the member''s active position (reverts to Normal User). Audited.';

revoke execute on function public.assign_position(uuid, public.admin_position, smallint) from public, anon, service_role;
revoke execute on function public.revoke_position(uuid)                                 from public, anon, service_role;
grant  execute on function public.assign_position(uuid, public.admin_position, smallint) to authenticated;
grant  execute on function public.revoke_position(uuid)                                 to authenticated;

-- ── RC region change ends the RC assignment (§3) ────────────────────────────

create function private.end_rc_on_region_change()
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
   where member_id = new.id and position = 'rc' and ended_at is null
  returning * into v_old;

  if found then
    perform private.write_audit(
      'position.revoke', 'admin_assignments', v_old.id::text,
      to_jsonb(v_old) - 'ended_at',
      to_jsonb(v_old) || jsonb_build_object('reason', 'region_changed',
                                            'old_region_id', old.region_id,
                                            'new_region_id', new.region_id));
  end if;

  return null;
end;
$$;

revoke execute on function private.end_rc_on_region_change() from public, anon, authenticated, service_role;

create trigger members_end_rc_on_region_change
  after update of region_id on public.members
  for each row
  when (old.region_id is distinct from new.region_id)
  execute function private.end_rc_on_region_change();
;
