-- Migration 2: enums
-- Spec §6 (Enums). Values are exactly as specified.
--
-- location_visibility (Q9) and event_status (§8) are created in their own phases
-- (migrations 5 and 12) once those decisions are confirmed. Enum values can be added
-- later but never removed, so only confirmed values go in.

create type public.account_status as enum ('active', 'suspended', 'blacklisted', 'deleted');
comment on type public.account_status is
  'Member account state. Anything other than active is denied by RLS and banned in Auth (§14).';

create type public.admin_position as enum ('rc', 'head', 'co_head');
comment on type public.admin_position is
  'Admin positions. rc is scoped to one region; head and co_head to one community (§2).';

create type public.request_type as enum (
  'member_deletion',
  'member_blacklist',
  'community_record_update',
  'community_record_deletion',
  'member_hard_delete'
);
comment on type public.request_type is 'Kinds of approval request (§10, §13).';

create type public.request_status as enum ('pending', 'approved', 'rejected', 'cancelled');
comment on type public.request_status is 'Lifecycle of an approval request (§10).';

create type public.registration_status as enum ('active', 'withdrawn', 'deleted');
comment on type public.registration_status is
  'State of a regional or community registration (§6, §10).';
;
