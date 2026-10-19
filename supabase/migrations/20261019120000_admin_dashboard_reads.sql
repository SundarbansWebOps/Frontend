-- Read models for the admin desk. Scope comes from the current database role.
create function public.admin_dashboard_requests(p_status text default 'pending', p_offset integer default 0)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_sa boolean := private.is_super_admin();
  v_rc smallint := private.my_rc_region();
  v_result jsonb;
begin
  if not v_sa and v_rc is null then
    raise exception 'Only a Regional Coordinator or Super Admin can read requests' using errcode = '42501';
  end if;
  if p_status is null or p_status not in ('pending', 'decided') or p_offset is null or p_offset < 0 then
    raise exception 'Invalid request filter' using errcode = '22023';
  end if;
  with visible as (
    select r.id, r.status::text, r.requested_at, r.target_member_id,
      to_jsonb(r) || jsonb_build_object('category', 'admin',
        'target', coalesce(r.target_snapshot->'member', r.target_snapshot),
        'requester', jsonb_build_object('full_name', m.full_name),
        'can_decide', r.status = 'pending' and v_sa and r.requested_by <> auth.uid(),
        'waiting_on', case when r.requested_by = auth.uid() and v_sa then 'Another Super Admin' else 'A Super Admin' end) as body
    from public.approval_requests r
    left join public.members m on m.id = r.requested_by
    where v_sa or r.requested_by = auth.uid()
    union all
    select r.id, r.status, r.requested_at, r.member_id,
      to_jsonb(r) || jsonb_build_object('category', 'region', 'type', 'region',
        'member', jsonb_build_object('id', m.id, 'full_name', m.full_name, 'preferred_name', m.preferred_name, 'email', m.email, 'member_code', m.member_code, 'region_id', m.region_id),
        'can_decide', r.status = 'pending' and r.member_id <> auth.uid() and (v_sa or r.from_region_id = v_rc),
        'waiting_on', 'Another coordinator or Super Admin')
    from public.member_region_requests r
    join public.members m on m.id = r.member_id
    where v_sa or r.from_region_id = v_rc
    union all
    select r.id, r.status, r.requested_at, r.member_id,
      to_jsonb(r) || jsonb_build_object('category', 'certificate', 'type', 'certificate',
        'member', jsonb_build_object('id', m.id, 'full_name', m.full_name, 'preferred_name', m.preferred_name, 'email', m.email, 'member_code', m.member_code, 'region_id', m.region_id),
        'can_decide', r.status = 'pending' and r.member_id <> auth.uid(),
        'waiting_on', 'Another Super Admin')
    from public.certificate_name_requests r
    join public.members m on m.id = r.member_id
    where v_sa
  ), filtered as (
    select * from visible where (p_status = 'pending') = (status = 'pending')
  ), page as (
    select * from filtered order by requested_at desc, id limit 100 offset p_offset
  )
  select jsonb_build_object(
    'total', (select count(*) from filtered),
    'rows', coalesce((select jsonb_agg(p.body || jsonb_build_object(
      'age_seconds', greatest(0, extract(epoch from now() - p.requested_at)),
      'history', coalesce((select jsonb_agg(h.body order by h.requested_at desc, h.id)
        from visible h where h.target_member_id = p.target_member_id and h.id <> p.id and h.status <> 'pending'), '[]'::jsonb)
    ) order by p.requested_at desc, p.id) from page p), '[]'::jsonb)
  ) into v_result;
  return v_result;
end;
$$;

create function public.admin_dashboard_summary()
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_sa boolean := private.is_super_admin();
  v_rc smallint := private.my_rc_region();
  v_members boolean;
  v_requests jsonb := '[]';
  v_result jsonb;
begin
  if not v_sa and v_rc is null and cardinality(private.my_community_ids()) = 0 then
    raise exception 'Admin access is required' using errcode = '42501';
  end if;
  v_members := v_sa or v_rc is not null;
  if v_members then
    v_requests := public.admin_dashboard_requests()->'rows';
  end if;
  with members as materialized (
    select m.* from public.members m
    where v_members and (v_sa or m.region_id = v_rc) and m.account_status <> 'deleted'
  ), roster as materialized (
    select r.* from public.member_roster r where v_members and (v_sa or r.region_id = v_rc)
  ), events as materialized (
    select e.* from public.events e
    where e.deleted_at is null and private.manages_event(e.id)
  ), queue as (
    select r.requested_at, v_sa and r.requested_by <> auth.uid() as can_decide
    from public.approval_requests r where v_members and r.status = 'pending' and (v_sa or r.requested_by = auth.uid())
    union all
    select r.requested_at, r.member_id <> auth.uid()
    from public.member_region_requests r where v_members and r.status = 'pending' and (v_sa or r.from_region_id = v_rc)
    union all
    select r.requested_at, r.member_id <> auth.uid()
    from public.certificate_name_requests r where v_sa and r.status = 'pending'
  )
  select jsonb_build_object(
    'counts', case when v_members then jsonb_build_object(
      'members', (select count(*) from members),
      'roster', (select count(*) from roster),
      'unassigned', (select count(*) from members where region_id is null) + (select count(*) from roster where region_id is null),
      'new_week', (select count(*) from members where created_at >= now() - interval '7 days'),
      'previous_week', (select count(*) from members where created_at >= now() - interval '14 days' and created_at < now() - interval '7 days')
    ) else null end,
    'queue', case when v_members then (
      select jsonb_build_object('for_you', count(*) filter (where q.can_decide),
        'waiting', count(*) filter (where not q.can_decide),
        'oldest_seconds', coalesce(max(extract(epoch from now() - q.requested_at)), 0))
      from queue q
    ) else null end,
    'requests', v_requests,
    'events', (select coalesce(jsonb_agg(to_jsonb(e) || jsonb_build_object('registrations',
      (select count(*) from public.event_registrations r where r.event_id = e.id)) order by e.starts_at, e.id), '[]')
      from (select * from events where published_at <= now() and ends_at > now() and cancelled_at is null and not archive order by starts_at, id limit 5) e),
    'forms', (select coalesce(jsonb_agg(to_jsonb(f) || jsonb_build_object('responses',
      (select count(*) from public.form_responses r where r.form_id = f.id)) order by f.closes_at, f.id), '[]')
      from (select f.id, f.title, f.closes_at from public.lounge_forms f
        where private.manages_form(f.id) and f.archived_at is null and f.is_open and f.published_at <= now()
          and (f.opens_at is null or f.opens_at <= now()) and (f.closes_at is null or f.closes_at > now()) order by f.closes_at, f.id limit 4) f),
    'notices', (select coalesce(jsonb_agg(to_jsonb(n) order by n.starts_at desc, n.id), '[]')
      from (select n.id, n.title, n.starts_at, n.ends_at, n.region_id from public.announcements n
        where v_members and private.manages_scope(n.region_id, n.community_id) and n.published_at is not null
          and n.starts_at <= now() and (n.ends_at is null or n.ends_at > now()) order by n.starts_at desc, n.id limit 4) n),
    'joins', (select coalesce(jsonb_agg(jsonb_build_object('day', d.day::date, 'count',
      (select count(*) from members m where (m.created_at at time zone 'Asia/Kolkata')::date = d.day::date)) order by d.day), '[]')
      from generate_series((now() at time zone 'Asia/Kolkata')::date - 6, (now() at time zone 'Asia/Kolkata')::date, interval '1 day') d(day) where v_members),
    'regions', (select coalesce(jsonb_agg(jsonb_build_object(
      'id', r.id, 'name', r.name, 'code', r.code,
      'members', (select count(*) from members m where m.region_id = r.id),
      'roster', (select count(*) from roster m where m.region_id = r.id),
      'new_week', (select count(*) from members m where m.region_id = r.id and m.created_at >= now() - interval '7 days'),
      'coordinators', (select count(*) from public.admin_assignments a join public.members m on m.id = a.member_id
        where a.region_id = r.id and a.position = 'rc' and a.ended_at is null and m.account_status = 'active' and m.deleted_at is null and m.region_id = r.id),
      'next_event', (select jsonb_build_object('id', e.id, 'name', e.name, 'starts_at', e.starts_at) from events e
        where e.region_id = r.id and e.published_at <= now() and e.starts_at > now() and e.cancelled_at is null and not e.archive order by e.starts_at, e.id limit 1)
    ) order by r.name), '[]') from public.regions r where v_members and (v_sa or r.id = v_rc)),
    'audit', (select coalesce(jsonb_agg(to_jsonb(a) order by a.created_at desc, a.id), '[]')
      from (select a.id, a.action, a.created_at, a.result, m.full_name as actor from public.audit_log a left join public.members m on m.id = a.actor_id where v_sa order by a.created_at desc, a.id limit 6) a)
  ) into v_result;
  return v_result;
end;
$$;

revoke execute on function public.admin_dashboard_requests(text, integer), public.admin_dashboard_summary() from public, anon, service_role;
grant execute on function public.admin_dashboard_requests(text, integer), public.admin_dashboard_summary() to authenticated;
