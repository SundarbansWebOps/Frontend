-- Migration 5: regions and communities
-- Spec §6 (lookup tables). New regions/communities are added as rows, never as tables.
-- Rows are NOT inserted here: dev rows come from seed.sql. Production rows need a
-- separate data migration once the real region names are confirmed (Q24).
--
-- RLS is enabled with no policies (phase 2 adds them). All default API privileges are
-- revoked so nothing is reachable until phase 2 grants exactly what is needed.

create table public.regions (
  id         smallint generated always as identity primary key,
  code       text not null,
  name       text not null,
  created_at timestamptz not null default now(),

  constraint regions_code_key   unique (code),
  constraint regions_name_key   unique (name),
  constraint regions_code_format check (code ~ '^[a-z0-9_]{2,40}$'),
  constraint regions_name_length check (name = btrim(name) and length(name) between 1 and 100)
);

comment on table public.regions is 'Lookup: the house regions (§6). RC scope is a region.';

create table public.communities (
  id         smallint generated always as identity primary key,
  code       text not null,
  name       text not null,
  created_at timestamptz not null default now(),

  constraint communities_code_key   unique (code),
  constraint communities_name_key   unique (name),
  constraint communities_code_format check (code ~ '^[a-z0-9_]{2,40}$'),
  constraint communities_name_length check (name = btrim(name) and length(name) between 1 and 100)
);

comment on table public.communities is 'Lookup: communities (esports, technical, cultural) (§6). Head/Co-Head scope is a community.';

alter table public.regions     enable row level security;
alter table public.communities enable row level security;

revoke all on table public.regions, public.communities from public, anon, authenticated, service_role;
;
