-- Migration 11: RLS policies and API grants for phase 1 tables + audit_log
-- Spec §5 (permission matrix), §9, §11, §14. CLAUDE.md security rules.
--
-- Pattern: one permissive policy per table per command, with the role branches OR-ed
-- together (avoids the multiple-permissive-policies performance warning). Helpers are
-- wrapped in (select ...) so they run once per statement, not once per row.
--
-- This phase grants READ access only (plus safe-column profile UPDATE). All other writes
-- arrive with their RPCs in later phases: forms, assign_position, requests, events.
--
-- Decisions baked in (confirm at approval):
--   Q19a  RCs see members of their region except soft-deleted ones (blacklisted/suspended
--         stay visible so the RC understands the state of their region).
--   Q19b  Community admins see only ACTIVE registrations of their community.
--   Q19c  RCs read the members table directly, so they also see whatsapp_data
--         (they already see email and phone). This reverses my earlier recommendation.
--   Q5    super_admin_allowlist keeps RLS on with ZERO policies: no API role can read it,
--         not even Super Admins (CLAUDE.md: "No RLS policy exposes this table").

-- ── regions, communities ────────────────────────────────────────────────────
-- Any active member may read the lookups. No write policies: rows change by migration.

create policy regions_select on public.regions
  for select to authenticated
  using ((select private.is_active_member()));

create policy communities_select on public.communities
  for select to authenticated
  using ((select private.is_active_member()));

grant select on table public.regions, public.communities to authenticated;

-- ── members ─────────────────────────────────────────────────────────────────
-- Self | RC: own region (not soft-deleted) | Super Admin: all.
-- Community admins get NO access here; they read registrant contact details only through
-- get_community_registrants() in a later phase (Q1).

create policy members_select on public.members
  for select to authenticated
  using (
    (id = (select auth.uid()) and (select private.is_active_member()))
    or (region_id = (select private.my_rc_region()) and account_status <> 'deleted')
    or (select private.is_super_admin())
  );

-- Self edits own row; Super Admin may edit any row. WHICH columns can change is decided by
-- the column grants below, not by this policy.
create policy members_update on public.members
  for update to authenticated
  using (
    (id = (select auth.uid()) and (select private.is_active_member()))
    or (select private.is_super_admin())
  )
  with check (
    (id = (select auth.uid()) and (select private.is_active_member()))
    or (select private.is_super_admin())
  );

-- Protected-field enforcement (§11). RLS is row-level only, so UPDATE is revoked from
-- authenticated and granted back on safe profile columns only. email, phone, region_id,
-- account_status, whatsapp_data, member_code and the deletion fields can never be changed
-- by a normal update, whatever the request contains.
revoke insert, update, delete on table public.members from authenticated;
grant select on table public.members to authenticated;
grant update (full_name, preferred_name, gender, bio) on table public.members to authenticated;

-- ── super_admin_allowlist ───────────────────────────────────────────────────
-- Intentionally no policies and no authenticated grant (Q5). Edge Functions read it with
-- the service role to verify Super Admin callers.
grant select on table public.super_admin_allowlist to service_role;

-- ── admin_assignments ───────────────────────────────────────────────────────
-- Self (own history) | Super Admin: all. Writes only via assign_position/revoke_position.

create policy admin_assignments_select on public.admin_assignments
  for select to authenticated
  using (
    (member_id = (select auth.uid()) and (select private.is_active_member()))
    or (select private.is_super_admin())
  );

grant select on table public.admin_assignments to authenticated;

-- ── regional_registrations ──────────────────────────────────────────────────
-- Self | RC: own region (not deleted) | Super Admin: all. Community admins: none (§5).

create policy regional_registrations_select on public.regional_registrations
  for select to authenticated
  using (
    (member_id = (select auth.uid()) and (select private.is_active_member()))
    or (region_id = (select private.my_rc_region()) and status <> 'deleted')
    or (select private.is_super_admin())
  );

grant select on table public.regional_registrations to authenticated;

-- ── community_registrations ─────────────────────────────────────────────────
-- Self | Head/Co-Head: own community, active rows | Super Admin: all. RCs: none (§5, §9).

create policy community_registrations_select on public.community_registrations
  for select to authenticated
  using (
    (member_id = (select auth.uid()) and (select private.is_active_member()))
    or (community_id = any ((select private.my_community_ids())::smallint[]) and status = 'active')
    or (select private.is_super_admin())
  );

grant select on table public.community_registrations to authenticated;

-- ── audit_log ───────────────────────────────────────────────────────────────
-- Super Admins only (§5, §13). Still no INSERT/UPDATE/DELETE for any API role.

create policy audit_log_select on public.audit_log
  for select to authenticated
  using ((select private.is_super_admin()));

grant select on table public.audit_log to authenticated;

-- ── service_role ────────────────────────────────────────────────────────────
-- Read access for Edge Functions. Write grants are added with each Edge Function's phase.
grant select on table
  public.regions, public.communities, public.members, public.admin_assignments,
  public.regional_registrations, public.community_registrations
to service_role;
;
