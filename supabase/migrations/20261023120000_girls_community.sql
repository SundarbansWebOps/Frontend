-- Girls community: a members-only community (owner, 2026-10-23).
-- * communities.members_only marks a community whose events, forms and notices are visible only to
--   the students on its email list, its Head/Co-Head and Super Admins. Never in the public archive.
-- * public.community_members is the email-keyed list. Students may not have signed in yet (accounts
--   are created at first Google sign-in, ADR 0001), so the list is by email, not member id.
--   Only a Super Admin adds or removes emails; the Head/Co-Head can only read their own list.
-- * private.sees_community() is added to every member-facing read/act path that relied on
--   private.in_audience() for events, lounge forms and notices, and the public archive paths
--   exclude members-only communities outright. Each redefinition below copies the latest body
--   (named per object) and only adds the community check; other communities are unchanged.

-- ── Schema ──────────────────────────────────────────────────────────────────

-- communities has a table-level SELECT grant (authenticated, anon), so the new column is readable
-- wherever communities already is.
alter table public.communities add column members_only boolean not null default false;
comment on column public.communities.members_only is
  'Members-only community: its events, forms and notices are visible only to emails on public.community_members, its Head/Co-Head and Super Admins, and never in the public archive.';

insert into public.communities (code, name, members_only) values ('girls', 'Girls', true)
on conflict (code) do update set members_only = true;

create table public.community_members (
  community_id smallint not null references public.communities (id),
  email        text not null,
  added_by     uuid references public.members (id),
  added_at     timestamptz not null default now(),
  primary key (community_id, email),
  constraint community_members_email_format check (email = lower(email) and email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$')
);
comment on table public.community_members is
  'Email list of a members-only community. Written only by Super Admins through add_community_members/remove_community_member; read by Super Admins and that community''s Head/Co-Head.';

alter table public.community_members enable row level security;
revoke all on table public.community_members from public, anon, authenticated, service_role;
grant select on table public.community_members to authenticated;
-- manages_scope(null, c): Super Admin, or Head/Co-Head of c. RCs and members read nothing.
create policy community_members_read on public.community_members for select to authenticated
  using (private.manages_scope(null, community_id));

-- ── Visibility helpers ──────────────────────────────────────────────────────

-- True for content outside any members-only community; otherwise only for the community's
-- managers and active members whose email is on its list.
create function private.sees_community(p_community smallint) returns boolean language sql stable security definer set search_path='' as $$
 select p_community is null
  or not coalesce((select c.members_only from public.communities c where c.id=p_community),false)
  or private.manages_scope(null,p_community)
  or exists(select 1 from public.members m join public.community_members cm on cm.community_id=p_community and cm.email=m.email
            where m.id=auth.uid() and m.account_status='active' and m.deleted_at is null);
$$;
-- The event's community, read without the caller's RLS (for policies on forms linked to an event).
create function private.sees_event(p_event uuid) returns boolean language sql stable security definer set search_path='' as $$
 select coalesce((select private.sees_community(e.community_id) from public.events e where e.id=p_event),false);
$$;
revoke execute on function private.sees_community(smallint),private.sees_event(uuid) from public,anon,authenticated,service_role;
grant execute on function private.sees_community(smallint),private.sees_event(uuid) to authenticated;

-- ── Events ──────────────────────────────────────────────────────────────────

-- From 20261009150100; adds the community check.
create or replace function private.can_register_event(p_event uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.events e where e.id=p_event and e.published_at is not null and e.published_at<=now() and e.deleted_at is null and e.cancelled_at is null and not e.archive and e.ends_at>now() and private.in_audience(e.region_id,e.audience_cohorts) and private.sees_community(e.community_id));
$$;

-- From 20261016120000; the published branch adds the community check (also for past events).
drop policy events_select on public.events;
create policy events_select on public.events for select to authenticated
  using (private.is_super_admin()
         or (deleted_at is null and (private.manages_scope(region_id, community_id)
                                     or private.is_my_house_draft(region_id, community_id, published_at, created_by)
                                     or (published_at is not null and published_at <= now()
                                         and (archive or ends_at <= now() or private.in_audience(region_id, audience_cohorts))
                                         and private.sees_community(community_id)))));

-- From 20261013194628; members-only community events never reach signed-out visitors.
-- anon has no access to the private schema, so the check reads communities (anon-readable) inline.
drop policy events_select_anon on public.events;
create policy events_select_anon on public.events for select to anon
  using (deleted_at is null and published_at is not null and published_at <= now()
         and (archive or ends_at <= now() or (is_public and cancelled_at is null))
         and (community_id is null or not exists (select 1 from public.communities c where c.id = events.community_id and c.members_only)));

-- is_public lists an upcoming event on the public Events page. A members-only community event can
-- never be public: rejected at write here (every writer, Super Admin included) and excluded at read
-- above and below. Patches the live validate_event (20261009150100) after its first statement.
do $patch$ declare body text; fixed text; anchor text:=' perform private.validate_audience(new.audience_cohorts);'; begin
 body:=pg_get_functiondef('private.validate_event()'::regprocedure);
 fixed:=replace(body,anchor,anchor||'
 if new.is_public and new.community_id is not null and exists(select 1 from public.communities c where c.id=new.community_id and c.members_only) then raise exception ''Members-only community events cannot be public'' using errcode=''22023''; end if;');
 if fixed=body then raise exception 'Expected validate_event anchor not found'; end if;
 execute fixed;
end $patch$;

-- From 20261009150100; the archive view (and list_public_past_events, which reads it as definer)
-- excludes members-only communities for every caller, list members included.
create or replace view public.public_events with(security_invoker=true) as select id,name,description,registration_link,starts_at,ends_at,community_id,region_id,source_key,display_date,image_url,event_type,wing,location,image_width,image_height,attendee_count,attendee_display,'completed'::public.event_status as status from public.events where deleted_at is null and published_at is not null and published_at<=now() and (archive or ends_at<=now())
 and (community_id is null or not exists(select 1 from public.communities c where c.id=events.community_id and c.members_only));

-- From 20261013194628; adds the members-only exclusion.
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
    and (e.archive or e.ends_at <= now() or (e.is_public and e.cancelled_at is null))
    and (e.community_id is null or not exists (select 1 from public.communities c where c.id = e.community_id and c.members_only));
$$;

-- From 20261009150200; the published branch adds the community check.
create or replace function public.list_lounge_events() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(to_jsonb(e)||jsonb_build_object('stage',case when e.archive or e.ends_at<=now() then 'past' when e.starts_at<=now() then 'live' else 'upcoming' end,'can_manage',private.manages_event(e.id),'registration',(select to_jsonb(r) from public.event_registrations r where r.event_id=e.id and r.member_id=auth.uid()),'attendance',(select to_jsonb(a)-'raw_row'-'imported_by' from public.event_attendance a where a.event_id=e.id and a.member_id=auth.uid()),'certificate',(select to_jsonb(c) from public.issued_certificates c where c.event_id=e.id and c.member_id=auth.uid()),'needs_certificate_name',e.certificates_released_at is not null and exists(select 1 from public.event_registrations r join public.event_attendance a on a.event_id=r.event_id and a.member_id=r.member_id where r.event_id=e.id and r.member_id=auth.uid() and ((e.attendance_mode='meet' and a.duration_seconds>=1200) or (e.attendance_mode='reviewed' and a.reviewed_eligible))) and (select certificate_name is null from public.members where id=auth.uid())) order by e.starts_at desc nulls last) from public.events e where e.deleted_at is null and (private.manages_event(e.id) or (e.published_at is not null and e.published_at<=now() and (e.archive or e.ends_at<=now() or private.in_audience(e.region_id,e.audience_cohorts)) and private.sees_community(e.community_id)))),'[]');
end; $$;

-- ── Lounge forms ────────────────────────────────────────────────────────────

-- From 20261009150100; adds the community check (an event form also passes can_register_event).
create or replace function private.can_submit_form(p_form uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.lounge_forms f where f.id=p_form and f.is_open and f.published_at is not null and f.published_at<=now() and (f.opens_at is null or f.opens_at<=now()) and (f.closes_at is null or f.closes_at>now()) and private.in_audience(f.region_id,f.audience_cohorts) and private.sees_community(f.community_id) and (f.event_id is null or private.can_register_event(f.event_id)));
$$;

-- From 20261009150100; a non-manager needs the form's (or its event's) community, including for a
-- form they already answered (e.g. after being removed from the list).
drop policy lounge_forms_read on public.lounge_forms;
create policy lounge_forms_read on public.lounge_forms for select to authenticated using(private.manages_form(id) or (private.is_active_member() and private.sees_community(community_id) and (event_id is null or private.sees_event(event_id)) and ((published_at is not null and published_at<=now() and private.in_audience(region_id,audience_cohorts) and (event_id is null or private.can_register_event(event_id))) or exists(select 1 from public.form_responses r where r.form_id=lounge_forms.id and r.member_id=auth.uid()))));

-- From 20261021180243; same community gate as lounge_forms_read.
create or replace function public.list_lounge_forms() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(to_jsonb(f)||jsonb_build_object('submitted',exists(select 1 from public.form_responses where form_id=f.id and member_id=auth.uid()),'can_manage',private.manages_form(f.id),'accepting_responses',private.can_submit_form(f.id),'review_status',(select r.review_status from public.form_responses r where r.form_id=f.id and r.member_id=auth.uid()),'review_reason',(select r.review_reason from public.form_responses r where r.form_id=f.id and r.member_id=auth.uid())) order by f.created_at desc) from public.lounge_forms f where private.manages_form(f.id) or (private.sees_community(f.community_id) and (f.event_id is null or private.sees_event(f.event_id)) and ((f.published_at is not null and f.published_at<=now() and private.in_audience(f.region_id,f.audience_cohorts) and (f.event_id is null or private.can_register_event(f.event_id))) or exists(select 1 from public.form_responses where form_id=f.id and member_id=auth.uid())))),'[]');
end; $$;

-- From 20261021180243; the invite needs the form's and the event's community too.
create or replace function public.get_lounge_form_invite(p_form_id uuid) returns text language plpgsql stable security definer set search_path='' as $$
declare v_status text;
begin
 if not private.is_active_member() then raise exception 'Submit this application before viewing the invite' using errcode='42501'; end if;
 select review_status into v_status from public.form_responses where form_id=p_form_id and member_id=auth.uid();
 if not found then raise exception 'Submit this application before viewing the invite' using errcode='42501'; end if;
 if v_status='rejected' then raise exception 'Your response was not approved. Fix it and send it again to get the invite.' using errcode='42501'; end if;
 return (select i.invite_url from private.lounge_form_invites i join public.lounge_forms f on f.id=i.form_id left join public.events e on e.id=f.event_id where f.id=p_form_id and private.in_audience(f.region_id,f.audience_cohorts) and private.sees_community(f.community_id) and (f.event_id is null or (private.in_audience(e.region_id,e.audience_cohorts) and private.sees_community(e.community_id))));
end; $$;
-- submit_lounge_form (20261021180243) authorizes through can_submit_form and returns
-- get_lounge_form_invite, so it inherits both checks unchanged.

-- ── Notices ─────────────────────────────────────────────────────────────────

-- From 20261019110000; the member branch adds the community check.
drop policy announcements_read on public.announcements;
create policy announcements_read on public.announcements for select to authenticated using(
  (published_at is not null and private.in_audience(region_id,audience_cohorts) and starts_at<=now() and private.sees_community(community_id))
  or private.manages_scope(region_id,community_id)
);

-- From 20261019110000; adds the community check.
create or replace function public.list_my_notices() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(to_jsonb(a)||jsonb_build_object('read_at',s.read_at,'dismissed_at',s.dismissed_at,'show_banner',a.starts_at>now()-interval '72 hours' and (a.ends_at is null or a.ends_at>now()) and s.dismissed_at is null) order by a.starts_at desc) from public.announcements a left join public.member_notice_states s on s.announcement_id=a.id and s.member_id=auth.uid() where a.published_at is not null and a.starts_at<=now() and private.in_audience(a.region_id,a.audience_cohorts) and private.sees_community(a.community_id)),'[]');
end; $$;

-- From 20261019110000; adds the community check.
create or replace function public.set_my_notice_state(p_announcement_id uuid,p_read boolean default true,p_dismiss boolean default false) returns void language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.announcements a where a.id=p_announcement_id and a.published_at is not null and a.starts_at<=now() and private.in_audience(a.region_id,a.audience_cohorts) and private.sees_community(a.community_id)) then raise exception 'Notice is outside your audience' using errcode='42501'; end if;
 insert into public.member_notice_states(announcement_id,member_id,read_at,dismissed_at) values(p_announcement_id,auth.uid(),case when p_read then now() end,case when p_dismiss then now() end)
 on conflict(announcement_id,member_id) do update set read_at=case when p_read then coalesce(member_notice_states.read_at,now()) else member_notice_states.read_at end,dismissed_at=case when p_dismiss then coalesce(member_notice_states.dismissed_at,now()) else member_notice_states.dismissed_at end;
end; $$;

-- ── Self-join ───────────────────────────────────────────────────────────────

-- From 20260928235328; a members-only community is joined only through its email list.
create or replace function public.submit_community_registration(p_community_id smallint, p_answers jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_active_caller();
  v_id  uuid;
begin
  if p_community_id is null or not exists (select 1 from public.communities c where c.id = p_community_id) then
    raise exception 'Community % does not exist', p_community_id using errcode = 'invalid_parameter_value';
  end if;
  if exists (select 1 from public.communities c where c.id = p_community_id and c.members_only) then
    raise exception 'This community is joined by invitation only' using errcode = '42501';
  end if;

  insert into public.community_registrations (member_id, community_id, answers)
  values (v_uid, p_community_id, private.validate_answers(p_answers))
  on conflict (member_id, community_id) do update
    set answers = excluded.answers, status = 'active'
  returning id into v_id;
  return v_id;
end;
$$;

-- ── List management RPCs ────────────────────────────────────────────────────

-- Super Admin, or Head/Co-Head of this community. member = the signed-in active account with that
-- email (null if not signed in yet); on_roster = added to the house but not signed in yet.
create function public.list_community_members(p_community_id smallint) returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if p_community_id is null or private.manages_scope(null,p_community_id) is not true then raise exception 'This community is outside your scope' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(jsonb_build_object(
   'email',cm.email,'added_at',cm.added_at,
   'member',(select jsonb_build_object('id',m.id,'full_name',m.full_name,'preferred_name',m.preferred_name,'member_code',m.member_code,'cohort',m.cohort,'region_id',m.region_id,'account_status',m.account_status)
             from public.members m where m.email=cm.email and m.account_status='active' and m.deleted_at is null),
   'on_roster',exists(select 1 from public.member_roster r where r.email=cm.email)) order by cm.email)
  from public.community_members cm where cm.community_id=p_community_id),'[]');
end; $$;

-- Super Admin only. Trims and lowercases, drops blanks and duplicates, reports malformed emails
-- without adding them. not_in_house lists added emails with neither an active account nor a
-- roster row (still added). The audit row carries counts only, never the email list.
create function public.add_community_members(p_community_id smallint,p_emails text[]) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_valid text[]; v_invalid text[]; v_added text[]; v_not_in_house text[]; v_result jsonb;
begin
 if not private.is_super_admin() then raise exception 'Only a Super Admin can add community members' using errcode='42501'; end if;
 if p_emails is null or cardinality(p_emails) not between 1 and 2000 then raise exception 'Send between 1 and 2000 emails' using errcode='22023'; end if;
 if not exists(select 1 from public.communities c where c.id=p_community_id and c.members_only) then raise exception 'Choose a members-only community' using errcode='22023'; end if;
 with normal as (
  select distinct lower(btrim(x,E' \t\r\n')) as email from unnest(p_emails) x where nullif(btrim(x,E' \t\r\n'),'') is not null
 )
 select coalesce(array_agg(email order by email) filter(where email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),'{}'),
        coalesce(array_agg(email order by email) filter(where email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),'{}')
   into v_valid,v_invalid from normal;
 with ins as (
  insert into public.community_members(community_id,email,added_by) select p_community_id,x,auth.uid() from unnest(v_valid) x
  on conflict(community_id,email) do nothing returning email
 )
 select coalesce(array_agg(email order by email),'{}') into v_added from ins;
 select coalesce(array_agg(x order by x),'{}') into v_not_in_house from unnest(v_added) x
  where not exists(select 1 from public.members m where m.email=x and m.account_status='active' and m.deleted_at is null)
    and not exists(select 1 from public.member_roster r where r.email=x);
 v_result:=jsonb_build_object('added',cardinality(v_added),'already',cardinality(v_valid)-cardinality(v_added),'invalid',to_jsonb(v_invalid),'not_in_house',to_jsonb(v_not_in_house));
 perform private.write_audit('community_member.add','community_members',p_community_id::text,null,
  jsonb_build_object('community_id',p_community_id,'added',cardinality(v_added),'already',cardinality(v_valid)-cardinality(v_added),'invalid',cardinality(v_invalid),'not_in_house',cardinality(v_not_in_house)));
 return v_result;
end; $$;

-- Super Admin only. Removing an email that is not on the list is P0002.
create function public.remove_community_member(p_community_id smallint,p_email text) returns void language plpgsql security definer set search_path='' as $$
declare v_row public.community_members;
begin
 if not private.is_super_admin() then raise exception 'Only a Super Admin can remove community members' using errcode='42501'; end if;
 if p_community_id is null or nullif(btrim(p_email),'') is null then raise exception 'Choose a community and an email' using errcode='22023'; end if;
 delete from public.community_members where community_id=p_community_id and email=lower(btrim(p_email)) returning * into v_row;
 if not found then raise exception 'That email is not on this community list' using errcode='P0002'; end if;
 perform private.write_audit('community_member.remove','community_members',p_community_id::text,to_jsonb(v_row),null);
end; $$;

revoke execute on function public.list_community_members(smallint),public.add_community_members(smallint,text[]),public.remove_community_member(smallint,text) from public,anon,authenticated,service_role;
grant execute on function public.list_community_members(smallint),public.add_community_members(smallint,text[]),public.remove_community_member(smallint,text) to authenticated;

-- ── Hard delete ─────────────────────────────────────────────────────────────
-- Hard delete erases the member's email; drop it from community lists too. Patches the live
-- function (20261021180243) at the same anchor 20261009150200 used, keeping every other line.
do $patch$ declare body text; fixed text; anchor text:='  update public.regional_registrations  set answers = ''{}''::jsonb where member_id = v_member.id;'; begin
 body:=pg_get_functiondef('public.svc_execute_hard_delete(uuid,uuid)'::regprocedure);
 fixed:=replace(body,anchor,'  delete from public.community_members where email = v_member.email;
'||anchor);
 if fixed=body then raise exception 'Expected hard-delete anchor not found'; end if;
 execute fixed;
end $patch$;
