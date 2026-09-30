-- Migration 7: admin_assignments
-- Spec §2 (positions and counts), §3 (validation, history), §6.
-- Position limits are enforced by partial unique indexes + CHECK constraints (CLAUDE.md),
-- not by application code. Rows are never deleted: ended_at closes an assignment.
--
-- Cross-table rules (target must be active, not a Super Admin, RC region = member's region)
-- are enforced by assign_position() in a later phase; they cannot be CHECK constraints.

create table public.admin_assignments (
  id           uuid primary key default gen_random_uuid(),
  member_id    uuid not null references public.members (id),
  position     public.admin_position not null,
  region_id    smallint references public.regions (id),
  community_id smallint references public.communities (id),
  assigned_by  uuid not null references public.members (id),
  started_at   timestamptz not null default now(),
  ended_at     timestamptz,

  -- RC carries a region and no community; Head/Co-Head carry a community and no region.
  constraint admin_assignments_scope_check check (
    (position = 'rc'                  and region_id is not null and community_id is null)
    or (position in ('head', 'co_head') and community_id is not null and region_id is null)
  ),
  constraint admin_assignments_period_check check (ended_at is null or ended_at >= started_at)
);

comment on table public.admin_assignments is
  'Admin positions with history (§3). Active = ended_at is null. Never deleted.';

-- One active position per member (§2, confirmed default).
create unique index admin_assignments_one_active_per_member
  on public.admin_assignments (member_id)
  where ended_at is null;

-- One active RC per region.
create unique index admin_assignments_one_active_rc_per_region
  on public.admin_assignments (region_id)
  where position = 'rc' and ended_at is null;

-- One active Head and one active Co-Head per community.
create unique index admin_assignments_one_active_per_community_position
  on public.admin_assignments (community_id, position)
  where position in ('head', 'co_head') and ended_at is null;

-- History lookups and FK support.
create index admin_assignments_member_history_idx on public.admin_assignments (member_id, started_at desc);
create index admin_assignments_region_id_idx      on public.admin_assignments (region_id)    where region_id is not null;
create index admin_assignments_community_id_idx   on public.admin_assignments (community_id) where community_id is not null;
create index admin_assignments_assigned_by_idx    on public.admin_assignments (assigned_by);

alter table public.admin_assignments enable row level security;
revoke all on table public.admin_assignments from public, anon, authenticated, service_role;
;
