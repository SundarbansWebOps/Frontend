-- Data-integrity fixes found in the 2026-10-09 audit. Historical migrations are immutable.

-- Group metadata is source-backed and editable in the organizer UI. Only verified membership
-- applications are promoted; recruitment forms remain distinct. Missing source copy stays empty.
alter table public.lounge_forms
  add column form_kind text not null default 'general'
    check (form_kind in ('general','group','recruitment')),
  add column group_label text check (group_label is null or length(btrim(group_label)) between 1 and 80),
  add column group_purpose text check (group_purpose is null or length(btrim(group_purpose)) <= 300),
  add column archived_at timestamptz;
create unique index lounge_forms_canonical_source_unique
  on public.lounge_forms(regexp_replace(btrim(source_url), '/+$', '')) where source_url is not null;
update public.lounge_forms set form_kind='group',
  group_label=case id::text
    when '1cb30c9f-d48a-5fc4-b1db-5cb6f99cfb74' then 'Bengaluru'
    when '7bf59906-1960-5c2a-93c9-8624d70ac42e' then 'Chandigarh'
    when '67e5b09c-2b8a-52a0-b326-01d0a2bf54cb' then 'Chennai'
    when '0add795d-a412-5c49-bf58-bfad378e80ad' then 'Delhi'
    when '14cec811-73a5-54ef-a8f1-7b8222fbc691' then 'Kolkata'
    when '6d4f1bee-33f2-5f0f-a97b-4866993d7a39' then 'Mumbai'
    when 'ef6e5e79-5ea5-56dc-b81e-b5c75373694c' then 'Patna'
    when '2fe75761-88af-5422-a3c7-d8e86830d3e2' then 'Technical'
    when '5a905465-ec6c-50f2-9503-40cc2e97d00d' then 'Cultural'
    when '4f142402-d390-512b-89e3-8193705b809e' then 'Esports'
  end
where id in (
 '1cb30c9f-d48a-5fc4-b1db-5cb6f99cfb74','7bf59906-1960-5c2a-93c9-8624d70ac42e',
 '67e5b09c-2b8a-52a0-b326-01d0a2bf54cb','0add795d-a412-5c49-bf58-bfad378e80ad',
 '14cec811-73a5-54ef-a8f1-7b8222fbc691','6d4f1bee-33f2-5f0f-a97b-4866993d7a39',
 'ef6e5e79-5ea5-56dc-b81e-b5c75373694c','2fe75761-88af-5422-a3c7-d8e86830d3e2',
 '5a905465-ec6c-50f2-9503-40cc2e97d00d','4f142402-d390-512b-89e3-8193705b809e'
);

-- A field key is the captured identity. Keep distinct fields with the same label in exports.
create or replace function public.export_form_responses(p_form_id uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
begin
 if private.manages_form(p_form_id) is not true then raise exception 'This form is outside your organizer scope' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'email',r.submitted_email,'submitted_at',r.submitted_at,'answers',r.answers,'field_schema',r.field_schema) order by r.submitted_at) from public.form_responses r where r.form_id=p_form_id),'[]');
end; $$;

-- Cohort options use calendar years and unique values, include every roster/member prefix, and
-- offer exactly the immediately following cohort. Validation normalizes duplicate selections.
create or replace function public.get_available_cohorts() returns jsonb language sql stable security definer set search_path='' as $$
 with boundaries as (
   select (now() at time zone 'Asia/Kolkata')::date today,
     private.next_cohort() next_code,
     coalesce((select min(yy::integer) from (
                 select substring(cohort from 1 for 2) yy from public.members where cohort ~ '^[0-9]{2}F[123]$'
                 union all
                 select substring(email from 1 for 2) yy from public.member_roster where email ~ '^[0-9]{2}f[123][0-9]+@'
               ) cohort_years),
              extract(year from now() at time zone 'Asia/Kolkata')::integer % 100) first_yy
 ), options as (
   select distinct to_char(d,'YY')||'F'||case when extract(month from d)=1 then '1' when extract(month from d)=5 then '2' else '3' end code, d
   from boundaries b cross join lateral generate_series(make_date(2000+b.first_yy,1,1)::timestamp,
     date_trunc('year',b.today::timestamp)+make_interval(months=>case when extract(month from b.today)<5 then 4 when extract(month from b.today)<9 then 8 else 12 end),interval '4 months') d
 ) select jsonb_build_object('current',private.current_cohort(),'next',private.next_cohort(),'options',coalesce((select jsonb_agg(code order by d) from options),'[]'::jsonb));
$$;
create or replace function private.validate_audience(p_cohorts text[]) returns void language plpgsql stable set search_path='' as $$
declare c text; first_cohort text;
begin
 if p_cohorts is null or cardinality(p_cohorts)>300 or cardinality(p_cohorts)<>(select count(distinct x) from unnest(p_cohorts) x) then raise exception 'Invalid or duplicate cohort selection' using errcode='22023'; end if;
 select coalesce((select min(yy||'F1') from (
   select substring(cohort from 1 for 2) yy from public.members where cohort ~ '^[0-9]{2}F[123]$'
   union all
   select substring(email from 1 for 2) yy from public.member_roster where email ~ '^[0-9]{2}f[123][0-9]+@'
 ) cohort_years),
   to_char(now() at time zone 'Asia/Kolkata','YY')||'F1') into first_cohort
 ;
 foreach c in array p_cohorts loop
   if c is null or c !~ '^[0-9]{2}F[123]$' or c<first_cohort or c>private.next_cohort() then raise exception 'Only available cohorts and the immediately next cohort may be selected' using errcode='22023'; end if;
 end loop;
end; $$;

-- Preserve source links when older clients omit them; allow metadata edits and archive/unarchive.
do $$
declare body text; updated text;
begin
 body:=pg_get_functiondef('public.save_lounge_form(jsonb)'::regprocedure);
 updated:=replace(body,
  'insert into public.lounge_forms(id,title,description,fields,region_id,community_id,event_id,is_open,published_at,opens_at,closes_at,audience_cohorts,created_by,source_url)',
  'insert into public.lounge_forms(id,title,description,fields,region_id,community_id,event_id,is_open,published_at,opens_at,closes_at,audience_cohorts,created_by,source_url,form_kind,group_label,group_purpose,archived_at)');
 updated:=replace(updated,
  'values(fid,btrim(p_form->>''title''),nullif(btrim(p_form->>''description''),''''),fs,r,c,e,coalesce((p_form->>''is_open'')::boolean,true),(p_form->>''published_at'')::timestamptz,(p_form->>''opens_at'')::timestamptz,(p_form->>''closes_at'')::timestamptz,cohorts,auth.uid(),p_form->>''source_url'')',
  'values(fid,btrim(p_form->>''title''),nullif(btrim(p_form->>''description''),''''),fs,r,c,e,coalesce((p_form->>''is_open'')::boolean,true),(p_form->>''published_at'')::timestamptz,(p_form->>''opens_at'')::timestamptz,(p_form->>''closes_at'')::timestamptz,cohorts,auth.uid(),p_form->>''source_url'',coalesce(p_form->>''form_kind'',''general''),nullif(btrim(p_form->>''group_label''),''''),nullif(btrim(p_form->>''group_purpose''),''''),(p_form->>''archived_at'')::timestamptz)');
 updated:=replace(updated,
  'on conflict(id) do update set source_url=excluded.source_url,title=excluded.title,description=excluded.description,fields=excluded.fields,region_id=excluded.region_id,community_id=excluded.community_id,event_id=excluded.event_id,is_open=excluded.is_open,published_at=excluded.published_at,opens_at=excluded.opens_at,closes_at=excluded.closes_at,audience_cohorts=excluded.audience_cohorts,updated_at=now();',
  'on conflict(id) do update set source_url=coalesce(excluded.source_url,public.lounge_forms.source_url),title=excluded.title,description=excluded.description,fields=excluded.fields,region_id=excluded.region_id,community_id=excluded.community_id,event_id=excluded.event_id,is_open=excluded.is_open,published_at=excluded.published_at,opens_at=excluded.opens_at,closes_at=excluded.closes_at,audience_cohorts=excluded.audience_cohorts,form_kind=excluded.form_kind,group_label=excluded.group_label,group_purpose=excluded.group_purpose,archived_at=excluded.archived_at,updated_at=now();');
 updated:=replace(updated,
  'perform private.write_audit(''form.save'',''lounge_forms'',fid::text,to_jsonb(oldf),p_form-''invite_url'');',
  'perform private.write_audit(''form.save'',''lounge_forms'',fid::text,to_jsonb(oldf),(p_form-''invite_url'')||jsonb_build_object(''invite_changed'',p_form ? ''invite_url''));');
 if updated=body or position('form_kind=excluded.form_kind' in updated)=0 or position('coalesce(excluded.source_url' in updated)=0 then raise exception 'Could not safely extend save_lounge_form'; end if;
 execute updated;
end $$;

-- Archiving removes public discovery and submission but keeps organizer and prior responder history.
create or replace function private.can_submit_form(p_form uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.lounge_forms f where f.id=p_form and f.archived_at is null and f.is_open and f.published_at is not null and f.published_at<=now() and (f.opens_at is null or f.opens_at<=now()) and (f.closes_at is null or f.closes_at>now()) and private.in_audience(f.region_id,f.audience_cohorts) and (f.event_id is null or private.can_register_event(f.event_id)));
$$;
create or replace function public.list_lounge_forms() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(to_jsonb(f)||jsonb_build_object('submitted',exists(select 1 from public.form_responses where form_id=f.id and member_id=auth.uid()),'can_manage',private.manages_form(f.id),'accepting_responses',private.can_submit_form(f.id)) order by f.created_at desc) from public.lounge_forms f where private.manages_form(f.id) or (f.archived_at is null and f.published_at is not null and f.published_at<=now() and private.in_audience(f.region_id,f.audience_cohorts) and (f.event_id is null or private.can_register_event(f.event_id))) or exists(select 1 from public.form_responses where form_id=f.id and member_id=auth.uid())),'[]');
end; $$;
create or replace function public.get_lounge_form_invite(p_form_id uuid) returns text language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_active_member() or (private.manages_form(p_form_id) is not true and not exists(select 1 from public.form_responses where form_id=p_form_id and member_id=auth.uid())) then raise exception 'This invite is outside your organizer scope' using errcode='42501'; end if;
 return (select i.invite_url from private.lounge_form_invites i
   join public.lounge_forms f on f.id=i.form_id
   left join public.events e on e.id=f.event_id
   where i.form_id=p_form_id and (private.manages_form(f.id) or
     (private.in_audience(f.region_id,f.audience_cohorts) and
       (f.event_id is null or private.in_audience(e.region_id,e.audience_cohorts)))));
end; $$;
drop policy lounge_forms_read on public.lounge_forms;
create policy lounge_forms_read on public.lounge_forms for select to authenticated using (
 private.manages_form(id)
 or (
  private.is_active_member()
  and (
   (archived_at is null and published_at is not null and published_at<=now()
    and private.in_audience(region_id,audience_cohorts)
    and (event_id is null or private.can_register_event(event_id)))
   or exists(select 1 from public.form_responses r where r.form_id=lounge_forms.id and r.member_id=auth.uid())
  )
 )
);

-- Hard deletion redacts free-text request material held in approval rows while preserving the
-- immutable audit log. Existing audit entries predate this retention boundary and are not rewritten.
do $$
declare body text; updated text; anchor text := $anchor$update public.approval_requests
     set status = 'approved', reviewed_by = p_actor, reviewed_at = now(), executed_at = now()
   where id = v_request.id;$anchor$;
begin
 body:=pg_get_functiondef('public.svc_execute_hard_delete(uuid,uuid)'::regprocedure);
 updated:=replace(body,anchor,$replacement$update public.approval_requests
     set target_snapshot = jsonb_build_object('redacted', true, 'member_id', v_member.id, 'member_code', v_member.member_code),
         requested_change = '{}'::jsonb,
         reason = 'Redacted',
         review_note = null
   where target_member_id = v_member.id;

  update public.approval_requests
     set status = 'approved', reviewed_by = p_actor, reviewed_at = now(), executed_at = now()
   where id = v_request.id;$replacement$);
 if updated=body then raise exception 'Could not add hard-delete request redaction'; end if;
 execute updated;
end $$;

-- Select-other text is trimmed and limited to 300 characters at the API boundary.
do $$
declare body text; updated text;
begin
 body:=pg_get_functiondef('public.submit_lounge_form(uuid,jsonb,boolean)'::regprocedure);
 updated:=replace(body, 'length(x)>6', 'length(btrim(substring(x from 7))) between 1 and 300');
 updated:=replace(updated, 'length(a->>k)>6', 'length(btrim(substring(a->>k from 7))) between 1 and 300');
 if updated=body then raise exception 'Could not safely tighten Other answer validation'; end if;
 execute updated;
end $$;

-- Only Super Admins may inspect or restore deleted events. Public history remains unchanged.
drop policy events_select on public.events;
create policy events_select on public.events for select to authenticated
 using(private.is_super_admin() or (deleted_at is null and (private.manages_scope(region_id,community_id) or (published_at is not null and published_at<=now() and (archive or ends_at<=now() or private.in_audience(region_id,audience_cohorts))))));

-- Archive records may keep imprecise display dates, but cannot be scheduled into the future.
create function private.prevent_future_archive_schedule() returns trigger language plpgsql set search_path='' as $$
begin
 if new.archive and (new.starts_at>now() or new.ends_at>now()) then raise exception 'An archive event cannot have a future schedule' using errcode='22023'; end if;
 return new;
end; $$;
create trigger zz_events_archive_schedule_guard before insert or update of archive,starts_at,ends_at on public.events for each row execute function private.prevent_future_archive_schedule();
revoke execute on function private.prevent_future_archive_schedule() from public,anon,authenticated,service_role;

-- Soft deletion remains available to an event's organizer, while only Super Admins can read or
-- restore deleted rows. A definer RPC avoids exposing deleted events through the SELECT policy.
create function public.soft_delete_event(p_event_id uuid,p_deleted boolean default true) returns void
language plpgsql security definer set search_path='' as $$
declare e public.events;
begin
 select * into e from public.events where id=p_event_id for update;
 if not found or (not private.is_super_admin() and (e.deleted_at is not null or private.manages_scope(e.region_id,e.community_id) is not true)) then
  raise exception 'This event is outside your organizer scope' using errcode='42501';
 end if;
 if p_deleted is null then raise exception 'Choose whether to remove or restore this event' using errcode='22023'; end if;
 update public.events set deleted_at=case when p_deleted then coalesce(deleted_at,now()) else null end where id=e.id;
end; $$;
revoke execute on function public.soft_delete_event(uuid,boolean) from public,anon,authenticated,service_role;
grant execute on function public.soft_delete_event(uuid,boolean) to authenticated;

-- Preserve omitted attendance rows on merge. Replace is opt-in and is bounded to one named source;
-- unresolved rows use source-row identity so repeated identical masked rows remain distinguishable.
alter table public.event_attendance add column import_source text not null default 'default' check(length(import_source) between 1 and 120);
alter table public.event_attendance add column import_sources text[] not null default '{}';
update public.event_attendance set import_sources=array[import_source];
drop function public.import_event_attendance(uuid,jsonb);
create or replace function public.import_event_attendance(p_event_id uuid,p_rows jsonb,p_mode text default 'merge',p_source_id text default 'default') returns jsonb language plpgsql security definer set search_path='' as $$
declare e public.events; r jsonb; em text; mid uuid; key text; cat text; ds integer; counts jsonb; source_row text; row_counter integer:=0; seen text[]:='{}';
begin
 if private.manages_event(p_event_id) is not true then raise exception 'This event is outside your organizer scope' using errcode='42501'; end if;
 select * into e from public.events where id=p_event_id for update;
 if not found or private.manages_scope(e.region_id,e.community_id) is not true then raise exception 'This event is outside your organizer scope' using errcode='42501'; end if;
 if e.certificates_released_at is not null then raise exception 'Attendance is locked after certificate release' using errcode='PT409'; end if;
 p_source_id:=btrim(p_source_id);
 if p_mode not in ('merge','replace') or p_source_id is null or length(p_source_id) not between 1 and 120 then raise exception 'Choose merge or a named source replacement' using errcode='22023'; end if;
 if jsonb_typeof(p_rows) is distinct from 'array' or jsonb_array_length(p_rows) not between 1 and 2000 then raise exception 'Send between 1 and 2000 attendance rows' using errcode='22023'; end if;
 if exists(select 1 from jsonb_array_elements(p_rows) x where jsonb_typeof(x)<>'object' or (e.attendance_mode='meet' and (coalesce(x->>'duration_seconds','') !~ '^[0-9]+$' or (x->>'duration_seconds')::numeric>604800)) or (e.attendance_mode='reviewed' and jsonb_typeof(x->'eligible') is distinct from 'boolean')) then raise exception 'Attendance needs valid Meet duration or explicitly reviewed non-Meet eligibility' using errcode='22023'; end if;
 -- Combine multiple Meet sessions for a valid email. Keep invalid/masked rows individually.
 for r in
   with input as (
     select value, ordinality, lower(btrim(value->>'email')) eml
     from jsonb_array_elements(p_rows) with ordinality
   )
   select jsonb_build_object('email',eml,
     'duration_seconds',sum(case when e.attendance_mode='meet' then (value->>'duration_seconds')::integer else 0 end),
     'eligible',bool_or(coalesce((value->>'eligible')::boolean,false)),
     'sessions',jsonb_agg(value order by ordinality))
   from input where eml ~ '^[^@[:space:]*]+@[^@[:space:]*]+\.[^@[:space:]*]+$'
   group by eml
   union all
   select value||jsonb_build_object('source_row_id',coalesce(nullif(value->>'source_row_id',''),ordinality::text))
   from input where eml is null or eml !~ '^[^@[:space:]*]+@[^@[:space:]*]+\.[^@[:space:]*]+$'
 loop
  row_counter:=row_counter+1;
  if jsonb_typeof(r)<>'object' or octet_length(r::text)>10000 then raise exception 'Invalid attendance row' using errcode='22023'; end if;
  em:=lower(btrim(r->>'email')); mid:=null;
  if em is null or em !~ '^[^@[:space:]*]+@[^@[:space:]*]+\.[^@[:space:]*]+$' then
   cat:='unresolved'; source_row:=coalesce(nullif(r->>'source_row_id',''),row_counter::text); key:='unresolved:'||p_source_id||':'||source_row;
  else
   select member_id into mid from public.event_registrations where event_id=e.id and registered_email=em;
   cat:=case when mid is null then 'unregistered' else 'registered' end; key:=em;
  end if;
  if key=any(seen) then raise exception 'Duplicate attendance identity in one import' using errcode='22023'; end if; seen:=array_append(seen,key);
  ds:=case when e.attendance_mode='meet' then (r->>'duration_seconds')::integer else null end;
  if exists(select 1 from public.event_attendance a where a.event_id=e.id and a.row_key=key and cardinality(array_remove(a.import_sources,p_source_id))>0
      and (a.duration_seconds is distinct from ds or a.reviewed_eligible is distinct from case when e.attendance_mode='reviewed' then (r->>'eligible')::boolean else false end)) then
    raise exception 'This identity has different attendance values in another source; reconcile the source sheets before importing' using errcode='PT409';
  end if;
  insert into public.event_attendance(event_id,row_key,email,member_id,duration_seconds,reviewed_eligible,raw_row,category,imported_by,import_source,import_sources)
  values(e.id,key,em,mid,ds,case when e.attendance_mode='reviewed' then (r->>'eligible')::boolean else false end,r,cat,auth.uid(),p_source_id,array[p_source_id])
  on conflict(event_id,row_key) do update set email=excluded.email,member_id=excluded.member_id,duration_seconds=excluded.duration_seconds,reviewed_eligible=excluded.reviewed_eligible,raw_row=excluded.raw_row,category=excluded.category,imported_by=excluded.imported_by,imported_at=now(),import_source=excluded.import_source,
   import_sources=(select array_agg(distinct src order by src) from unnest(public.event_attendance.import_sources||excluded.import_sources) src);
 end loop;
 if p_mode='replace' then
  update public.event_attendance set import_sources=array_remove(import_sources,p_source_id)
   where event_id=e.id and p_source_id=any(import_sources) and not(row_key=any(seen));
  delete from public.event_attendance where event_id=e.id and cardinality(import_sources)=0;
 end if;
 select jsonb_build_object('matched',count(*) filter(where category='registered'),'unregistered',count(*) filter(where category='unregistered'),'unresolved',count(*) filter(where category='unresolved')) into counts from public.event_attendance where event_id=e.id;
 perform private.write_audit('attendance.import','events',e.id::text,null,jsonb_build_object('mode',p_mode,'source_id',p_source_id)||counts); return counts||jsonb_build_object('mode',p_mode,'source_id',p_source_id);
end; $$;

-- Security-definer batch import reports conflicting rows opaquely; after locking an existing
-- roster row it re-reads region and duplicate ownership to catch changes made while waiting.
create or replace function public.roster_add_many(p_rows jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare r jsonb; out_rows jsonb:='[]'; v_email text; v_region smallint; v_old_region smallint; existing boolean; category text; conflict boolean;
begin
 if not private.is_super_admin() and private.my_rc_region() is null then raise exception 'Only RCs or Super Admins add students' using errcode='42501'; end if;
 if jsonb_typeof(p_rows) is distinct from 'array' or jsonb_array_length(p_rows) not between 1 and 500 then raise exception 'Send between 1 and 500 rows' using errcode='22023'; end if;
 for r in select value from jsonb_array_elements(p_rows) loop
  begin
   if jsonb_typeof(r)<>'object' then raise exception 'Row must be an object' using errcode='22023'; end if;
   v_email:=lower(btrim(r->>'email')); v_region:=(r->>'region_id')::smallint;
   if v_email is null or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'Enter a valid email' using errcode='22023'; end if;
   -- Serialize absent as well as existing identities so simultaneous inserts have one winner.
   perform pg_advisory_xact_lock(hashtextextended('roster:'||v_email,0));
   if not private.is_super_admin() and private.my_rc_region() is null then raise exception 'Only RCs or Super Admins add students' using errcode='42501'; end if;
   select region_id into v_old_region from public.member_roster where email=v_email for update;
   existing:=exists(select 1 from public.members where email=v_email) or exists(select 1 from public.member_roster where email=v_email);
   perform public.roster_add(v_email,r->>'full_name',r->>'phone',v_region,r->>'gender');
   -- Re-read after the canonical RPC's insert/unique-key wait; the winner may have moved regions.
   select region_id into v_old_region from public.member_roster where email=v_email;
   -- Match the single-add opaque reply: an RC cannot distinguish a new email from a
   -- globally known identity. Only Super Admins receive existence classifications.
   category:=case when not private.is_super_admin() then 'processed' when existing then 'existing' else 'added' end;
   out_rows:=out_rows||jsonb_build_array(jsonb_build_object('email',v_email,'ok',true,'category',category));
  exception when others then
   out_rows:=out_rows||jsonb_build_array(jsonb_build_object('email',r->>'email','ok',false,'category',case when not private.is_super_admin() and sqlstate in ('23505','42501') then 'invalid' when sqlstate in ('23505','42501') then 'conflict' else 'invalid' end,'error',case when not private.is_super_admin() and sqlstate in ('23505','42501') then 'This row could not be added' when sqlstate in ('23505','42501') then 'This row conflicts with an existing record' else sqlerrm end));
  end;
 end loop;
 return out_rows;
end; $$;

-- Single-row additions share the same absent-identity lock as the batch API.
do $$
declare body text; updated text;
begin
 body:=pg_get_functiondef('public.roster_add(text,text,text,smallint,text)'::regprocedure);
 updated:=replace(body,
  $find$if v_email is null or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' or not exists(select 1 from private.signup_email_domains where domain=split_part(v_email,'@',2)) then raise exception 'Enter an approved IITM student email' using errcode='22023'; end if;$find$,
  $replace$if v_email is null or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' or not exists(select 1 from private.signup_email_domains where domain=split_part(v_email,'@',2)) then raise exception 'Enter an approved IITM student email' using errcode='22023'; end if;
 perform pg_advisory_xact_lock(hashtextextended('roster:'||v_email,0));
 if not private.is_super_admin() then if private.my_rc_region() is null or (p_region_id is not null and p_region_id<>private.my_rc_region()) then raise exception 'You can only add students to your own region' using errcode='42501'; end if; v_region:=private.my_rc_region(); end if;$replace$);
 if updated=body or position('hashtextextended(''roster:''||v_email,0)' in updated)=0 then raise exception 'Could not safely serialize roster_add'; end if;
 execute updated;
end $$;

revoke execute on function public.import_event_attendance(uuid,jsonb,text,text) from public,anon,authenticated,service_role;
grant execute on function public.import_event_attendance(uuid,jsonb,text,text) to authenticated;
revoke execute on function public.get_available_cohorts(),public.save_lounge_form(jsonb),public.submit_lounge_form(uuid,jsonb,boolean) from public,anon,authenticated,service_role;
grant execute on function public.get_available_cohorts(),public.save_lounge_form(jsonb),public.submit_lounge_form(uuid,jsonb,boolean) to authenticated;
