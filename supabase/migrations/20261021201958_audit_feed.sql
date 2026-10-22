-- Super Admin audit feed: who did what, as which role, with full before/after values.
--
-- 1. audit_log gains actor_role (the actor's role when the row was written) and xact_id (groups
--    rows written by one transaction, e.g. an RPC row and the trigger rows it caused). Both are
--    nullable with no backfill: rows written before this migration keep null, and the table
--    stays append-only (adding columns and a default fires no row trigger).
-- 2. private.write_audit records actor_role. Same signature, grants and actor rule as
--    20260928191344 (auth.uid(), else p_actor_id, else the bound app.actor_id).
-- 3. Form and event exports leave a data.export row (row counts only, never answers or
--    contacts), so they become volatile.
-- 4. public.admin_audit_feed: filtered, keyset-paginated read for Super Admins only.
-- Direct SELECT on audit_log for Super Admins (audit_log_select policy) is unchanged.

-- ── Columns ─────────────────────────────────────────────────────────────────
alter table public.audit_log
  add column actor_role text,
  add column xact_id bigint;

alter table public.audit_log
  add constraint audit_log_actor_role_check
  check (actor_role is null or actor_role in ('super_admin', 'rc', 'head', 'co_head', 'member', 'system'));

-- Set after the column exists so historical rows stay null; only new inserts get the id.
alter table public.audit_log
  alter column xact_id set default (pg_current_xact_id()::text::bigint);

comment on column public.audit_log.actor_role is
  'Actor role when the row was written: super_admin, rc, head, co_head, member, or system (no actor). Null for rows written before 20261021201958.';
comment on column public.audit_log.xact_id is
  'Writing transaction id; rows sharing it were written together. Null for rows written before 20261021201958.';

-- ── Indexes ─────────────────────────────────────────────────────────────────
-- Feed order is (created_at desc, id desc); the old index could not break created_at ties.
drop index public.audit_log_created_at_idx;
create index audit_log_created_at_id_idx on public.audit_log (created_at desc, id desc);
create index audit_log_action_idx on public.audit_log (action text_pattern_ops, created_at desc, id desc);

-- ── Write path ──────────────────────────────────────────────────────────────
-- Role precedence mirrors the access helpers: a Super Admin never holds a position, and a member
-- holds at most one open position (admin_assignments_one_active_per_member). Positions and the
-- allowlist are read as stored, without the helpers' active-account check, so the snapshot shows
-- the authority the actor held rather than masking it behind their account status.
create or replace function private.write_audit(
  p_action       text,
  p_target_table text  default null,
  p_target_id    text  default null,
  p_old_values   jsonb default null,
  p_new_values   jsonb default null,
  p_request_id   uuid  default null,
  p_result       text  default 'success',
  p_actor_id     uuid  default null
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id    bigint;
  v_actor uuid := coalesce((select auth.uid()), p_actor_id,
                           nullif(current_setting('app.actor_id', true), '')::uuid);
  v_role  text;
begin
  if v_actor is null then
    v_role := 'system';
  elsif exists (select 1 from public.super_admin_allowlist s where s.user_id = v_actor) then
    v_role := 'super_admin';
  else
    select a.position::text into v_role
    from public.admin_assignments a
    where a.member_id = v_actor and a.ended_at is null
    order by case a.position when 'rc' then 1 when 'head' then 2 else 3 end
    limit 1;
    -- A future admin_position value must never make audit writes (and so every audited
    -- action) fail audit_log_actor_role_check; it reads as member until the check learns it.
    v_role := case when v_role in ('rc', 'head', 'co_head') then v_role else 'member' end;
  end if;

  insert into public.audit_log
    (actor_id, actor_role, action, target_table, target_id, old_values, new_values, request_id, result)
  values
    (v_actor, v_role, p_action, p_target_table, p_target_id, p_old_values, p_new_values, p_request_id, p_result)
  returning id into v_id;

  return v_id;
end;
$$;

comment on function private.write_audit(text, text, text, jsonb, jsonb, uuid, text, uuid) is
  'Sole write path into audit_log. Records the actor role at write time. Called by security definer functions/triggers (owned by postgres) and by Edge Functions via service_role.';

revoke execute on function private.write_audit(text, text, text, jsonb, jsonb, uuid, text, uuid)
  from public, anon, authenticated;
grant execute on function private.write_audit(text, text, text, jsonb, jsonb, uuid, text, uuid)
  to service_role;

-- ── Audited exports ─────────────────────────────────────────────────────────
-- Bodies and checks as 20261021180243 (forms) and 20261009150200 (events); only the audit row
-- and volatility are new. The audit row carries counts only.
create or replace function public.export_form_responses(p_form_id uuid) returns jsonb language plpgsql volatile security definer set search_path='' as $$
declare
 v_result jsonb;
begin
 if private.manages_form(p_form_id) is not true then raise exception 'This form is outside your organizer scope' using errcode='42501'; end if;
 -- serial = arrival order (1 = first received), stable regardless of how the caller sorts or filters.
 v_result := coalesce((select jsonb_agg(jsonb_build_object('id',x.id,'email',x.submitted_email,'submitted_at',x.submitted_at,'answers',x.answers,'field_schema',x.field_schema,
   'serial',x.serial,'resubmitted_at',x.resubmitted_at,'review_status',x.review_status,'review_reason',x.review_reason,'reviewed_at',x.reviewed_at,
   'reviewer_name',x.reviewer_name,'reviewer_email',x.reviewer_email,'member_full_name',x.full_name,'member_preferred_name',x.preferred_name) order by x.submitted_at,x.id)
  from (select r.*,row_number() over(order by r.submitted_at,r.id) as serial,m.full_name,m.preferred_name,rv.full_name as reviewer_name,rv.email as reviewer_email
   from public.form_responses r join public.members m on m.id=r.member_id left join public.members rv on rv.id=r.reviewed_by where r.form_id=p_form_id) x),'[]');
 perform private.write_audit('data.export','lounge_forms',p_form_id::text,null,
  jsonb_build_object('rows',jsonb_array_length(v_result)));
 return v_result;
end; $$;

create or replace function public.export_event_records(p_event_id uuid) returns jsonb language plpgsql volatile security definer set search_path='' as $$
declare
 v_result jsonb;
begin
 if private.manages_event(p_event_id) is not true then raise exception 'This event is outside your organizer scope' using errcode='42501'; end if;
 v_result := jsonb_build_object('registrations',coalesce((select jsonb_agg(to_jsonb(r)||jsonb_build_object('answers',f.answers,'field_schema',f.field_schema,'attendance',to_jsonb(a),'certificate_id',c.id) order by r.registered_at) from public.event_registrations r join public.form_responses f on f.id=r.response_id left join public.event_attendance a on a.event_id=r.event_id and a.member_id=r.member_id left join public.issued_certificates c on c.event_id=r.event_id and c.member_id=r.member_id where r.event_id=p_event_id),'[]'),'attendance',coalesce((select jsonb_agg(to_jsonb(a) order by a.category,a.email) from public.event_attendance a where a.event_id=p_event_id),'[]'));
 -- rows = registrations (the primary sheet); attendance_rows = the attendance sheet.
 perform private.write_audit('data.export','events',p_event_id::text,null,
  jsonb_build_object('rows',jsonb_array_length(v_result->'registrations'),'attendance_rows',jsonb_array_length(v_result->'attendance')));
 return v_result;
end; $$;

revoke execute on function public.export_form_responses(uuid), public.export_event_records(uuid) from public, anon, authenticated, service_role;
grant execute on function public.export_form_responses(uuid), public.export_event_records(uuid) to authenticated;

-- ── Feed ────────────────────────────────────────────────────────────────────
-- Super Admin only. Full old/new values, unmasked (deliberate: the reader already holds direct
-- SELECT on audit_log). Names are resolved at read time; target_id is text, so every uuid or
-- smallint cast is guarded by a format check and an unexpected id yields null, never an error.
create function public.admin_audit_feed(
  p_actions   text[]      default null,
  p_prefixes  text[]      default null,
  p_actor     uuid        default null,
  p_member    uuid        default null,
  p_role      text        default null,
  p_result    text        default null,
  p_from      timestamptz default null,
  p_to        timestamptz default null,
  p_q         text        default null,
  p_before_at timestamptz default null,
  p_before_id bigint      default null,
  p_limit     int         default 50
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_limit    int    := least(greatest(coalesce(p_limit, 50), 1), 100);
  -- An empty selection means "no filter", like null.
  v_actions  text[] := nullif(p_actions, '{}'::text[]);
  v_prefixes text[];
  v_q        text   := nullif(btrim(p_q), '');
  v_like     text;
  v_rows     jsonb;
  v_next     jsonb;
begin
  if not coalesce((select private.is_super_admin()), false) then
    raise exception 'Only a Super Admin can read the audit log' using errcode = '42501';
  end if;
  if (p_before_at is null) <> (p_before_id is null) then
    raise exception 'The cursor needs both p_before_at and p_before_id' using errcode = '22023';
  end if;
  if p_role is not null and p_role not in ('super_admin', 'rc', 'head', 'co_head', 'member', 'system') then
    raise exception 'Unknown role filter' using errcode = '22023';
  end if;
  if p_result is not null and p_result not in ('success', 'failure') then
    raise exception 'Unknown result filter' using errcode = '22023';
  end if;

  -- Escape LIKE metacharacters ('_' appears in real action names) before adding the wildcard.
  select array_agg(replace(replace(replace(x.prefix, '\', '\\'), '%', '\%'), '_', '\_') || '.%')
    into v_prefixes
  from unnest(p_prefixes) as x(prefix)
  where x.prefix is not null and x.prefix <> '';
  if v_q is not null then
    v_like := '%' || replace(replace(replace(v_q, '\', '\\'), '%', '\%'), '_', '\_') || '%';
  end if;

  with page as (
    select a.id, a.created_at, a.action, a.result, a.actor_id, a.actor_role, a.target_table,
           a.target_id, a.request_id, a.xact_id, a.old_values, a.new_values,
           t.target_uuid, s.subject_id,
           am.full_name as actor_name, am.member_code as actor_code,
           sm.full_name as subject_name, sm.member_code as subject_code
    from public.audit_log a
    cross join lateral (
      select case when a.target_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
                  then a.target_id::uuid end as target_uuid
    ) t
    cross join lateral (
      select case a.target_table
        when 'members' then t.target_uuid
        when 'form_responses' then
          (select r.member_id from public.form_responses r where r.id = t.target_uuid)
        when 'member_region_requests' then
          (select r.member_id from public.member_region_requests r where r.id = t.target_uuid)
        when 'certificate_name_requests' then
          (select r.member_id from public.certificate_name_requests r where r.id = t.target_uuid)
      end as subject_id
    ) s
    left join public.members am on am.id = a.actor_id
    left join public.members sm on sm.id = s.subject_id
    where (p_before_at is null or (a.created_at, a.id) < (p_before_at, p_before_id))
      and ((v_actions is null and v_prefixes is null)
           or a.action = any (v_actions)
           or a.action like any (v_prefixes))
      and (p_actor is null or a.actor_id = p_actor)
      and (p_member is null or a.actor_id = p_member or s.subject_id = p_member)
      and (p_role is null or a.actor_role = p_role)
      and (p_result is null or a.result = p_result)
      and (p_from is null or a.created_at >= p_from)
      and (p_to is null or a.created_at < p_to)
      and (v_q is null
           or am.full_name ilike v_like escape '\'
           or am.member_code ilike v_like escape '\'
           or sm.full_name ilike v_like escape '\'
           or sm.member_code ilike v_like escape '\'
           or lower(a.target_id) = lower(v_q))
    order by a.created_at desc, a.id desc
    limit v_limit + 1
  )
  select coalesce(jsonb_agg(jsonb_build_object(
      'id', p.id,
      'created_at', p.created_at,
      'action', p.action,
      'result', p.result,
      'actor_id', p.actor_id,
      'actor_name', p.actor_name,
      'actor_code', p.actor_code,
      'actor_role', p.actor_role,
      'target_table', p.target_table,
      'target_id', p.target_id,
      'target_label', case p.target_table
        when 'members' then p.subject_name
        when 'events' then (select e.name from public.events e where e.id = p.target_uuid)
        when 'announcements' then (select n.title from public.announcements n where n.id = p.target_uuid)
        when 'lounge_forms' then (select f.title from public.lounge_forms f where f.id = p.target_uuid)
        when 'form_responses' then (select f.title from public.form_responses r
          join public.lounge_forms f on f.id = r.form_id where r.id = p.target_uuid)
        when 'regions' then (select r.name from public.regions r
          where r.id = case when p.target_id ~ '^[0-9]{1,4}$' then p.target_id::smallint end)
      end,
      'subject_id', p.subject_id,
      'subject_name', p.subject_name,
      'subject_code', p.subject_code,
      'request_id', p.request_id,
      'xact_id', p.xact_id,
      'old_values', p.old_values,
      'new_values', p.new_values
    ) order by p.created_at desc, p.id desc), '[]'::jsonb)
    into v_rows
  from page p;

  -- One extra row was fetched only to learn whether another page exists.
  if jsonb_array_length(v_rows) > v_limit then
    v_rows := v_rows - v_limit;
    v_next := jsonb_build_object('at', v_rows -> (v_limit - 1) -> 'created_at',
                                 'id', v_rows -> (v_limit - 1) -> 'id');
  end if;

  return jsonb_build_object('rows', v_rows, 'next', v_next);
end;
$$;

comment on function public.admin_audit_feed(text[], text[], uuid, uuid, text, text, timestamptz, timestamptz, text, timestamptz, bigint, int) is
  'Super Admin audit feed: filtered, newest first, keyset cursor (created_at, id). Full old/new values.';

revoke execute on function public.admin_audit_feed(text[], text[], uuid, uuid, text, text, timestamptz, timestamptz, text, timestamptz, bigint, int)
  from public, anon, authenticated, service_role;
grant execute on function public.admin_audit_feed(text[], text[], uuid, uuid, text, text, timestamptz, timestamptz, text, timestamptz, bigint, int)
  to authenticated;
