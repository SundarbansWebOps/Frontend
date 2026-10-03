-- Migration 10: access helper functions
-- CLAUDE.md "Helper functions", spec §2 (role derivation), §14.
--
-- All four are stable security definer with an empty search_path. They read the database
-- on every statement (never JWT claims), so revoking a position takes effect on the very
-- next query, in the same session (§2, §14).
--
-- They live in the private schema: callable from RLS policies (authenticated has USAGE and
-- EXECUTE) but not exposed as RPC endpoints.
--
-- Every helper requires the CALLER to be an active member. A suspended, blacklisted or
-- deleted account gets false / null / empty, which makes every policy deny (§14 second layer).

create function private.is_active_member()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.members m
    where m.id = (select auth.uid())
      and m.account_status = 'active'
      and m.deleted_at is null
  );
$$;

create function private.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.super_admin_allowlist s
    join public.members m on m.id = s.user_id
    where s.user_id = (select auth.uid())
      and m.account_status = 'active'
      and m.deleted_at is null
  );
$$;

-- The caller's RC region, or null. Defensive: the assignment's region must still equal the
-- member's current region, and Super Admins never hold positions.
create function private.my_rc_region()
returns smallint
language sql
stable
security definer
set search_path = ''
as $$
  select a.region_id
  from public.admin_assignments a
  join public.members m on m.id = a.member_id
  where a.member_id = (select auth.uid())
    and a.position = 'rc'
    and a.ended_at is null
    and a.region_id = m.region_id
    and m.account_status = 'active'
    and m.deleted_at is null
    and not exists (select 1 from public.super_admin_allowlist s where s.user_id = a.member_id);
$$;

-- The caller's Head/Co-Head communities (at most one today; an array keeps policies stable
-- if that rule is ever relaxed). Empty array when none.
create function private.my_community_ids()
returns smallint[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(a.community_id), '{}'::smallint[])
  from public.admin_assignments a
  join public.members m on m.id = a.member_id
  where a.member_id = (select auth.uid())
    and a.position in ('head', 'co_head')
    and a.ended_at is null
    and m.account_status = 'active'
    and m.deleted_at is null
    and not exists (select 1 from public.super_admin_allowlist s where s.user_id = a.member_id);
$$;

revoke execute on function private.is_active_member() from public, anon;
revoke execute on function private.is_super_admin()   from public, anon;
revoke execute on function private.my_rc_region()     from public, anon;
revoke execute on function private.my_community_ids() from public, anon;

grant execute on function private.is_active_member() to authenticated, service_role;
grant execute on function private.is_super_admin()   to authenticated, service_role;
grant execute on function private.my_rc_region()     to authenticated, service_role;
grant execute on function private.my_community_ids() to authenticated, service_role;
;
