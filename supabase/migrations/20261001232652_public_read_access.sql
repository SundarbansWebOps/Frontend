-- Public (signed-out) read access (frontend review item 4)
-- * regions, communities: the sign-up form must list regions before the user has an account.
--   These are lookup rows with no personal data.
-- * events: the public Events page. Signed-out visitors read the view public.public_events, which
--   exposes only display columns of non-deleted events plus a derived status. It hides gmail_link
--   (members-only contact link), created_by/updated_by (member ids) and all timestamps except the
--   schedule and cancellation. A "published" flag can be added later (review: "events has no public
--   published concept"); until then every non-deleted event is public.
-- Nothing else becomes readable by anon. Writes stay closed to anon everywhere.

-- ── Lookups ─────────────────────────────────────────────────────────────────

create policy regions_select_anon on public.regions
  for select to anon
  using (true);

create policy communities_select_anon on public.communities
  for select to anon
  using (true);

grant select on table public.regions, public.communities to anon;

-- ── Public events ───────────────────────────────────────────────────────────

-- Row access for anon: non-deleted events only. Column access: only what the view uses.
create policy events_select_anon on public.events
  for select to anon
  using (deleted_at is null);

grant select (id, name, description, registration_link, starts_at, ends_at, community_id, cancelled_at, deleted_at)
  on table public.events to anon;

-- security_invoker: the caller's own RLS and column grants apply (views otherwise bypass RLS).
create view public.public_events
with (security_invoker = true)
as
select e.id,
       e.name,
       e.description,
       e.registration_link,
       e.starts_at,
       e.ends_at,
       e.community_id,
       case
         when e.cancelled_at is not null then 'cancelled'::public.event_status
         when now() < e.starts_at        then 'upcoming'::public.event_status
         when now() < e.ends_at          then 'ongoing'::public.event_status
         else 'completed'::public.event_status
       end as status
from public.events e
where e.deleted_at is null;

comment on view public.public_events is
  'Public Events page: non-deleted events, display columns and derived status only. Readable signed-out.';

revoke all on table public.public_events from public, anon, authenticated, service_role;
grant select on table public.public_events to anon, authenticated, service_role;
