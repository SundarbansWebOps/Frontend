-- Migration 20: events
-- Spec §8 (fields, who manages which events), §5 (Manage events), §13 (event changes audited),
-- CLAUDE.md (events.community_id nullable: null = house-wide).
--
-- Management scope (§8 default, confirmed with phase 6):
--   Super Admin: every event.  RC: house-wide events (community_id is null).
--   Head / Co-Head: their own community's events.  Everyone else: view only.
-- Scope is checked against the row, not the creator, so an event outlives its creator's term
-- and is managed by whoever holds that scope now (§8).
--
-- Visibility (decision, phase 6): every active member sees every non-deleted event, house-wide
-- and community ones ("members view Intra-House events", §8). Super Admins also see deleted ones.
--
-- Writes go through RLS + column grants (no RPC needed): INSERT/UPDATE of content columns
-- only. created_by/updated_by/timestamps are stamped by trigger from auth.uid(); deletion is
-- soft (deleted_at) and there is no DELETE grant. Status is derived from the dates by
-- public.event_status(events), usable as a computed column: select=*,event_status.

create type public.event_status as enum ('upcoming', 'ongoing', 'completed', 'cancelled');
comment on type public.event_status is 'Derived event state (§8): from dates, or cancelled when cancelled_at is set.';

create table public.events (
  id                uuid primary key default gen_random_uuid(),
  name              text not null,
  description       text,
  gmail_link        text,
  registration_link text,
  starts_at         timestamptz not null,
  ends_at           timestamptz not null,
  -- null = house-wide event (CLAUDE.md).
  community_id      smallint references public.communities (id),
  cancelled_at      timestamptz,
  created_by        uuid not null references public.members (id),
  updated_by        uuid not null references public.members (id),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz,

  constraint events_name_length        check (name = btrim(name) and length(name) between 1 and 200),
  constraint events_description_length check (description is null or length(description) <= 4000),
  -- Links are shown to members and opened in a browser: https only, no whitespace.
  constraint events_gmail_link_https   check (gmail_link is null or (gmail_link ~ '^https://[^[:space:]<>"]+$' and length(gmail_link) <= 2048)),
  constraint events_registration_https check (registration_link is null or (registration_link ~ '^https://[^[:space:]<>"]+$' and length(registration_link) <= 2048)),
  constraint events_period             check (ends_at > starts_at)
);

comment on table public.events is
  'Intra-House events (§8). community_id null = house-wide. Soft delete; status via public.event_status(events).';

create index events_upcoming_idx     on public.events (starts_at) where deleted_at is null;
create index events_community_id_idx on public.events (community_id, starts_at) where community_id is not null;
create index events_created_by_idx   on public.events (created_by);
create index events_updated_by_idx   on public.events (updated_by);

-- ── Stamping: authorship and timestamps never come from the client ──────────

create function private.events_stamp()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
begin
  if tg_op = 'INSERT' then
    new.created_by := coalesce(v_uid, new.created_by);
    new.created_at := now();
    new.deleted_at := null;
    new.cancelled_at := case when new.cancelled_at is not null then now() end;
  else
    new.created_by := old.created_by;
    new.created_at := old.created_at;
    -- Setting deleted_at / cancelled_at records "now"; clearing cancelled_at un-cancels.
    -- Only Super Admins can see (and so restore) deleted events, per the RLS policies.
    new.deleted_at   := case when new.deleted_at is null then null
                             when old.deleted_at is not null then old.deleted_at else now() end;
    new.cancelled_at := case when new.cancelled_at is null then null
                             when old.cancelled_at is not null then old.cancelled_at else now() end;
  end if;
  new.updated_by := coalesce(v_uid, new.updated_by, new.created_by);
  new.updated_at := now();
  return new;
end;
$$;

revoke execute on function private.events_stamp() from public, anon, authenticated, service_role;

create trigger events_stamp
  before insert or update on public.events
  for each row execute function private.events_stamp();

-- Every event creation, change and deletion is audited (§13).
create trigger events_audit
  after insert or update or delete on public.events
  for each row execute function private.audit_row_change();

-- ── Derived status (computed column) ────────────────────────────────────────

create function public.event_status(e public.events)
returns public.event_status
language sql
stable
set search_path = ''
as $$
  select case
    when e.cancelled_at is not null then 'cancelled'::public.event_status
    when now() < e.starts_at        then 'upcoming'::public.event_status
    when now() < e.ends_at          then 'ongoing'::public.event_status
    else 'completed'::public.event_status
  end;
$$;

comment on function public.event_status(public.events) is
  'Computed column for events (§8): cancelled | upcoming | ongoing | completed.';

revoke execute on function public.event_status(public.events) from public, anon;
grant execute on function public.event_status(public.events) to authenticated, service_role;

-- ── RLS ─────────────────────────────────────────────────────────────────────

alter table public.events enable row level security;
revoke all on table public.events from public, anon, authenticated, service_role;

create policy events_select on public.events
  for select to authenticated
  using (
    (deleted_at is null and (select private.is_active_member()))
    or (select private.is_super_admin())
  );

create policy events_insert on public.events
  for insert to authenticated
  with check (
    (select private.is_super_admin())
    or (community_id is null and (select private.my_rc_region()) is not null)
    or (community_id = any ((select private.my_community_ids())::smallint[]))
  );

-- USING: which existing rows the caller may change. WITH CHECK: the row after the change must
-- still be in scope, so an event cannot be moved into another community or made house-wide.
create policy events_update on public.events
  for update to authenticated
  using (
    (select private.is_super_admin())
    or (deleted_at is null and community_id is null and (select private.my_rc_region()) is not null)
    or (deleted_at is null and community_id = any ((select private.my_community_ids())::smallint[]))
  )
  with check (
    (select private.is_super_admin())
    or (community_id is null and (select private.my_rc_region()) is not null)
    or (community_id = any ((select private.my_community_ids())::smallint[]))
  );

grant select on table public.events to authenticated, service_role;
grant insert (name, description, gmail_link, registration_link, starts_at, ends_at, community_id, cancelled_at)
  on table public.events to authenticated;
grant update (name, description, gmail_link, registration_link, starts_at, ends_at, community_id, cancelled_at, deleted_at)
  on table public.events to authenticated;
;
