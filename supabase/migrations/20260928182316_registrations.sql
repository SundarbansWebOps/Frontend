-- Migration 8: regional_registrations and community_registrations
-- Spec §6, §7. Decision Q4: regional_registrations gets a status column so soft delete
-- can mark it 'deleted'.
--
-- Writes will go through the form RPCs (later phase), which validate answers server-side.
-- RLS on, no policies yet (phase 2). All API privileges revoked.

-- ── regional_registrations ──────────────────────────────────────────────────

create table public.regional_registrations (
  id         uuid primary key default gen_random_uuid(),
  member_id  uuid not null references public.members (id),
  -- Always copied from members.region_id by trigger; any supplied value is overwritten.
  region_id  smallint not null references public.regions (id),
  answers    jsonb not null default '{}'::jsonb,
  status     public.registration_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint regional_registrations_member_id_key unique (member_id),
  constraint regional_registrations_answers_object check (
    jsonb_typeof(answers) = 'object' and octet_length(answers::text) <= 20000
  )
);

comment on table public.regional_registrations is
  'One regional form per member (§6, §7). region_id is always the member''s region, never client input.';

create index regional_registrations_region_id_idx on public.regional_registrations (region_id, status);

-- Region is taken from the member record, whatever the caller sent (CLAUDE.md, §7).
create function private.regional_registration_force_region()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  select m.region_id into new.region_id
  from public.members m
  where m.id = new.member_id;

  if new.region_id is null then
    raise exception 'Member % has no region', new.member_id
      using errcode = 'foreign_key_violation';
  end if;

  return new;
end;
$$;

revoke execute on function private.regional_registration_force_region() from public, anon, authenticated, service_role;

create trigger regional_registrations_force_region
  before insert or update of region_id, member_id on public.regional_registrations
  for each row execute function private.regional_registration_force_region();

create trigger regional_registrations_set_updated_at
  before update on public.regional_registrations
  for each row execute function private.set_updated_at();

-- ── community_registrations ─────────────────────────────────────────────────

create table public.community_registrations (
  id           uuid primary key default gen_random_uuid(),
  member_id    uuid not null references public.members (id),
  community_id smallint not null references public.communities (id),
  answers      jsonb not null default '{}'::jsonb,
  status       public.registration_status not null default 'active',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),

  -- Resubmission updates the existing row instead of creating a duplicate (§6, §7).
  constraint community_registrations_member_id_community_id_key unique (member_id, community_id),
  constraint community_registrations_answers_object check (
    jsonb_typeof(answers) = 'object' and octet_length(answers::text) <= 20000
  )
);

comment on table public.community_registrations is
  'Single table for all communities (§6). Community separation is by community_id + RLS.';

create index community_registrations_community_id_idx on public.community_registrations (community_id, status);

create trigger community_registrations_set_updated_at
  before update on public.community_registrations
  for each row execute function private.set_updated_at();

alter table public.regional_registrations  enable row level security;
alter table public.community_registrations enable row level security;

revoke all on table public.regional_registrations, public.community_registrations
  from public, anon, authenticated, service_role;
;
