-- Organizer soft delete. 20261010000000_audit_fixes.sql defines this RPC but is not applied to the
-- live project, so every Remove in the admin panel failed with "function does not exist". This
-- forward migration adds the RPC and the deleted-row SELECT policy from that audit file, and nothing
-- else. Do not push 20261010000000 afterwards: it would recreate the function and policy here.
-- The RPC uses private.manages_event so an RC can also remove their own unpublished house-wide
-- draft, which the admin UI offers; the audit version checked only manages_scope and would refuse
-- that. Archived events stay Super Admin-only via events_validate.
create or replace function public.soft_delete_event(p_event_id uuid,p_deleted boolean default true) returns void
language plpgsql security definer set search_path='' as $$
declare e public.events;
begin
 select * into e from public.events where id=p_event_id for update;
 if not found or (not private.is_super_admin() and (e.deleted_at is not null or private.manages_event(e.id) is not true)) then
  raise exception 'This event is outside your organizer scope' using errcode='42501';
 end if;
 if p_deleted is null then raise exception 'Choose whether to remove or restore this event' using errcode='22023'; end if;
 update public.events set deleted_at=case when p_deleted then coalesce(deleted_at,now()) else null end where id=e.id;
end; $$;
revoke execute on function public.soft_delete_event(uuid,boolean) from public,anon,authenticated,service_role;
grant execute on function public.soft_delete_event(uuid,boolean) to authenticated;

-- Organizers must not read soft-deleted rows; only Super Admins can inspect or restore them.
-- 20261013194628 replaced the audit policy and dropped this deleted_at check from the manager branch.
drop policy events_select on public.events;
create policy events_select on public.events for select to authenticated
  using (private.is_super_admin()
         or (deleted_at is null and (private.manages_scope(region_id, community_id)
                                     or private.is_my_house_draft(region_id, community_id, published_at, created_by)
                                     or (published_at is not null and published_at <= now()
                                         and (archive or ends_at <= now() or private.in_audience(region_id, audience_cohorts))))));
