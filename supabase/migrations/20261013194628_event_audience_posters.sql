-- Event audience, posters and RC house-wide approval (owner, 2026-10-13)
-- * is_public: an upcoming event marked Public is listed on the public Events page; otherwise it
--   stays in the Lounge for its audience until it ends (then it joins the public archive as before).
-- * RCs manage their own region's events directly. They may also draft a house-wide event (no
--   region, no community); it goes live only when a Super Admin approves an event_publish request.
--   Once published, a house-wide event is managed by Super Admins only.
-- * Posters: image_url must be a delivery URL from the house Cloudinary account. Uploads are signed
--   by the sign-event-image Edge Function, which checks svc_event_image_target first.

-- ── Columns ─────────────────────────────────────────────────────────────────

alter table public.events add column is_public boolean not null default false;
grant insert (is_public), update (is_public) on public.events to authenticated;

alter table public.events add constraint events_image_cloudinary check (
  image_url is null or image_url like 'https://res.cloudinary.com/l59gy0g2/image/upload/%'
);

alter table public.approval_requests add column target_event_id uuid references public.events (id);
create index approval_requests_target_event_idx on public.approval_requests (target_event_id)
  where target_event_id is not null;

alter table public.approval_requests drop constraint approval_requests_target_shape;
alter table public.approval_requests add constraint approval_requests_target_shape check (
  (type in ('member_deletion', 'member_blacklist', 'member_hard_delete', 'member_profile_update',
            'member_status_change', 'position_change', 'member_contact_change')
   and target_registration_id is null and target_event_id is null)
  or (type in ('community_record_update', 'community_record_deletion')
      and target_registration_id is not null and target_event_id is null)
  or (type = 'event_publish' and target_event_id is not null and target_registration_id is null)
);

-- One pending request per event; the per-member rule no longer applies to event requests.
drop index public.approval_requests_one_pending_per_member;
create unique index approval_requests_one_pending_per_member on public.approval_requests (type, target_member_id)
  where status = 'pending' and target_registration_id is null and target_event_id is null;
create unique index approval_requests_one_pending_per_event on public.approval_requests (type, target_event_id)
  where status = 'pending' and target_event_id is not null;

-- ── Who manages an event ────────────────────────────────────────────────────

-- An RC's own house-wide draft (unpublished, created by them).
create or replace function private.is_my_house_draft(p_region smallint, p_community smallint,
                                                     p_published_at timestamptz, p_created_by uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_region is null and p_community is null and p_published_at is null
     and p_created_by = (select auth.uid()) and (select private.my_rc_region()) is not null;
$$;

revoke execute on function private.is_my_house_draft(smallint, smallint, timestamptz, uuid) from public, anon;
grant execute on function private.is_my_house_draft(smallint, smallint, timestamptz, uuid) to authenticated;

create or replace function private.manages_event(p_event uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select private.manages_scope(e.region_id, e.community_id)
                       or private.is_my_house_draft(e.region_id, e.community_id, e.published_at, e.created_by)
                   from public.events e where e.id = p_event), false);
$$;

drop policy events_insert on public.events;
create policy events_insert on public.events for insert to authenticated
  with check (private.manages_scope(region_id, community_id)
              or private.is_my_house_draft(region_id, community_id, published_at, created_by));

drop policy events_update on public.events;
create policy events_update on public.events for update to authenticated
  using (private.is_super_admin()
         or (deleted_at is null and (private.manages_scope(region_id, community_id)
                                     or private.is_my_house_draft(region_id, community_id, published_at, created_by))))
  with check (private.manages_scope(region_id, community_id)
              or private.is_my_house_draft(region_id, community_id, published_at, created_by));

drop policy events_select on public.events;
create policy events_select on public.events for select to authenticated
  using (private.manages_scope(region_id, community_id)
         or private.is_my_house_draft(region_id, community_id, published_at, created_by)
         or (deleted_at is null and published_at is not null and published_at <= now()
             and (archive or ends_at <= now() or private.in_audience(region_id, audience_cohorts))));

-- Signed-out visitors: the archive and past events as before, plus upcoming events marked Public.
drop policy events_select_anon on public.events;
create policy events_select_anon on public.events for select to anon
  using (deleted_at is null and published_at is not null and published_at <= now()
         and (archive or ends_at <= now() or (is_public and cancelled_at is null)));
grant select (is_public) on public.events to anon;

-- While a publish request is pending the draft is frozen, so the Super Admin approves what they saw.
create or replace function private.freeze_event_under_review()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null and not private.is_super_admin()
     and exists (select 1 from public.approval_requests r
                 where r.target_event_id = old.id and r.type = 'event_publish' and r.status = 'pending') then
    raise exception 'This event is waiting for a Super Admin to publish it; cancel the request to edit it'
      using errcode = 'PT409';
  end if;
  return new;
end;
$$;

create trigger events_freeze_under_review before update on public.events
  for each row execute function private.freeze_event_under_review();

-- ── Publishing a house-wide event (RC → Super Admin) ────────────────────────

create or replace function public.request_event_publish(p_event_id uuid, p_reason text default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event   public.events%rowtype;
  v_reason  text := coalesce(private.clean_reason(p_reason, false), 'Publish this house-wide event');
  v_request public.approval_requests%rowtype;
begin
  select * into v_event from public.events where id = p_event_id for update;

  if not found or not private.is_my_house_draft(v_event.region_id, v_event.community_id,
                                                v_event.published_at, v_event.created_by)
     or v_event.deleted_at is not null then
    raise exception 'Only the Regional Coordinator who drafted a house-wide event can ask to publish it'
      using errcode = 'insufficient_privilege';
  end if;

  if v_event.cancelled_at is not null or v_event.ends_at <= now() then
    raise exception 'This event is cancelled or already over' using errcode = 'PT409';
  end if;

  begin
    insert into public.approval_requests (type, target_member_id, target_event_id, target_snapshot,
                                          requested_change, reason, requested_by)
    values ('event_publish', (select auth.uid()), v_event.id, jsonb_build_object('event', to_jsonb(v_event)),
            jsonb_build_object('event_id', v_event.id, 'event_name', v_event.name), v_reason, (select auth.uid()))
    returning * into v_request;
  exception when unique_violation then
    raise exception 'This event is already waiting for approval' using errcode = 'unique_violation';
  end;

  perform private.write_audit('request.create', 'approval_requests', v_request.id::text, null,
    jsonb_build_object('type', v_request.type, 'event_id', v_event.id, 'reason', v_reason), v_request.id);
  return v_request.id;
end;
$$;

revoke execute on function public.request_event_publish(uuid, text) from public, anon;
grant execute on function public.request_event_publish(uuid, text) to authenticated;

-- Called by approve_request (already checked: Super Admin, not their own request, pending).
create or replace function private.approve_event_publish(p_request public.approval_requests, p_note text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.events%rowtype;
begin
  select * into v_event from public.events where id = p_request.target_event_id for update;

  if not found or v_event.deleted_at is not null or v_event.cancelled_at is not null then
    raise exception 'The event was removed or cancelled; reject this request instead' using errcode = 'PT409';
  end if;
  if v_event.published_at is not null then
    raise exception 'The event is already published; reject this request instead' using errcode = 'PT409';
  end if;
  if v_event.region_id is not null or v_event.community_id is not null then
    raise exception 'The event is no longer house-wide; reject this request instead' using errcode = 'PT409';
  end if;

  update public.events set published_at = now() where id = v_event.id;

  update public.approval_requests
     set status = 'approved', reviewed_by = (select auth.uid()), reviewed_at = now(),
         review_note = p_note, executed_at = now()
   where id = p_request.id;

  perform private.write_audit('request.approve', 'approval_requests', p_request.id::text,
    jsonb_build_object('event', to_jsonb(v_event)),
    jsonb_build_object('type', p_request.type, 'event_id', v_event.id, 'published', true, 'review_note', p_note),
    p_request.id);
  return p_request.id;
end;
$$;

revoke execute on function private.approve_event_publish(public.approval_requests, text) from public, anon, authenticated;

-- Patch the live approve_request (keeps every later change to it): event requests branch off first.
do $patch$
declare
  v_body   text := pg_get_functiondef('public.approve_request(uuid,text)'::regprocedure);
  v_anchor text := '  -- Re-check the target now; things may have changed since the request was filed.';
begin
  if position(v_anchor in v_body) = 0 then
    raise exception 'approve_request changed: anchor not found, update this migration';
  end if;
  execute replace(v_body, v_anchor,
    '  if v_request.type = ''event_publish'' then' || chr(10) ||
    '    return private.approve_event_publish(v_request, v_note);' || chr(10) ||
    '  end if;' || chr(10) || chr(10) || v_anchor);
end;
$patch$;

-- ── Public listing: archive + past + upcoming Public events ─────────────────

create or replace function public.list_public_events()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', e.id, 'name', e.name, 'description', e.description,
           'registration_link', e.registration_link, 'starts_at', e.starts_at, 'ends_at', e.ends_at,
           'community_id', e.community_id, 'region_id', e.region_id, 'source_key', e.source_key,
           'display_date', e.display_date, 'image_url', e.image_url, 'event_type', e.event_type,
           'wing', e.wing, 'location', e.location, 'image_width', e.image_width,
           'image_height', e.image_height, 'attendee_count', e.attendee_count,
           'attendee_display', e.attendee_display, 'archive', e.archive, 'is_public', e.is_public,
           'stage', case when e.archive or e.ends_at <= now() then 'past'
                         when e.starts_at <= now() then 'live' else 'upcoming' end)
         order by e.starts_at desc nulls last, e.display_date desc), '[]'::jsonb)
  from public.events e
  where e.deleted_at is null and e.published_at is not null and e.published_at <= now()
    and (e.archive or e.ends_at <= now() or (e.is_public and e.cancelled_at is null));
$$;

revoke execute on function public.list_public_events() from public;
grant execute on function public.list_public_events() to anon, authenticated, service_role;

-- ── Poster upload check for the sign-event-image Edge Function ──────────────
-- Evaluates the same rule as the site (manages_event) as the calling member.
create or replace function public.svc_event_image_target(p_actor uuid, p_event_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.events%rowtype;
begin
  perform set_config('request.jwt.claims', jsonb_build_object('sub', p_actor, 'role', 'authenticated')::text, true);

  select * into v_event from public.events where id = p_event_id;
  if not found or v_event.deleted_at is not null then
    raise exception 'Event not found' using errcode = 'no_data_found';
  end if;
  if not private.is_active_member() or not private.manages_event(p_event_id)
     or (v_event.archive and not private.is_super_admin()) then
    raise exception 'You cannot change this event' using errcode = 'insufficient_privilege';
  end if;
  if exists (select 1 from public.approval_requests r
             where r.target_event_id = p_event_id and r.type = 'event_publish' and r.status = 'pending')
     and not private.is_super_admin() then
    raise exception 'This event is waiting for approval; cancel the request to change it' using errcode = 'PT409';
  end if;

  return jsonb_build_object('event_id', v_event.id);
end;
$$;

revoke execute on function public.svc_event_image_target(uuid, uuid) from public, anon, authenticated;
grant execute on function public.svc_event_image_target(uuid, uuid) to service_role;
