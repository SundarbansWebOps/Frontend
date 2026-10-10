-- Private operational records and signed blank templates; verification exposes no recipient PII.
create table public.event_attendance(
 id uuid primary key default gen_random_uuid(),event_id uuid not null references public.events(id),row_key text not null,
 email text,member_id uuid references public.members(id),duration_seconds integer check(duration_seconds between 0 and 604800),
 reviewed_eligible boolean not null default false,raw_row jsonb not null check(octet_length(raw_row::text)<=10000),
 category text not null check(category in('registered','unregistered','unresolved')),imported_by uuid not null references public.members(id),imported_at timestamptz not null default now(),unique(event_id,row_key)
);
create table public.issued_certificates(
 id uuid primary key default gen_random_uuid(),event_id uuid not null references public.events(id),member_id uuid not null references public.members(id),
 certificate_name text not null check(length(btrim(certificate_name)) between 1 and 200),template_url text not null,
 issued_by uuid not null references public.members(id),issued_at timestamptz not null default now(),unique(event_id,member_id)
);
create table public.certificate_name_requests(
 id uuid primary key default gen_random_uuid(),member_id uuid not null references public.members(id),old_name text,new_name text not null check(new_name=btrim(new_name) and length(new_name) between 1 and 200),
 reason text not null check(length(btrim(reason)) between 1 and 2000),status text not null default 'pending' check(status in('pending','approved','rejected')),
 requested_at timestamptz not null default now(),reviewed_by uuid references public.members(id),reviewed_at timestamptz,review_note text check(length(review_note)<=2000)
);
create unique index one_pending_certificate_name_request on public.certificate_name_requests(member_id) where status='pending';
alter table public.event_attendance enable row level security;
alter table public.issued_certificates enable row level security;
alter table public.certificate_name_requests enable row level security;
revoke all on public.event_attendance,public.issued_certificates,public.certificate_name_requests from public,anon,authenticated,service_role;
grant select on public.event_attendance,public.issued_certificates,public.certificate_name_requests to authenticated;
create policy attendance_read on public.event_attendance for select to authenticated using(private.is_active_member() and (member_id=auth.uid() or private.manages_event(event_id)));
create policy certificates_read on public.issued_certificates for select to authenticated using(private.is_active_member() and (member_id=auth.uid() or private.manages_event(event_id)));
create policy certificate_name_requests_read on public.certificate_name_requests for select to authenticated using(private.is_active_member() and (member_id=auth.uid() or private.is_super_admin()));
create function public.import_event_attendance(p_event_id uuid,p_rows jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare e public.events; r jsonb; em text; mid uuid; key text; cat text; ds integer; counts jsonb;
begin
 if private.manages_event(p_event_id) is not true then raise exception 'This event is outside your organizer scope' using errcode='42501'; end if;
 select * into e from public.events where id=p_event_id for update;
 if not found or private.manages_scope(e.region_id,e.community_id) is not true then raise exception 'This event is outside your organizer scope' using errcode='42501'; end if;
 if e.certificates_released_at is not null then raise exception 'Attendance is locked after certificate release' using errcode='PT409'; end if;
 if jsonb_typeof(p_rows) is distinct from 'array' or jsonb_array_length(p_rows) not between 1 and 2000 then raise exception 'Send between 1 and 2000 attendance rows' using errcode='22023'; end if;
 if exists(select 1 from jsonb_array_elements(p_rows) x where jsonb_typeof(x)<>'object' or (e.attendance_mode='meet' and (coalesce(x->>'duration_seconds','') !~ '^[0-9]+$' or (x->>'duration_seconds')::numeric>604800)) or (e.attendance_mode='reviewed' and jsonb_typeof(x->'eligible') is distinct from 'boolean')) then raise exception 'Attendance needs valid Meet duration or explicitly reviewed non-Meet eligibility' using errcode='22023'; end if;
 -- Within one sheet, multiple Meet sessions for the same email are summed. Reimports replace
 -- that sheet's total, rather than accumulating it, so the same report is idempotent.
 for r in
  select case when normal_email ~ '^[^@[:space:]*]+@[^@[:space:]*]+\.[^@[:space:]*]+$' then
    jsonb_build_object('email',normal_email,'duration_seconds',sum(coalesce((value->>'duration_seconds')::integer,0)),'eligible',bool_or(coalesce((value->>'eligible')::boolean,false)),'sessions',jsonb_agg(value))
    else (array_agg(value))[1] end
  from (select value,lower(btrim(value->>'email')) normal_email from jsonb_array_elements(p_rows)) t
  group by normal_email,case when normal_email ~ '^[^@[:space:]*]+@[^@[:space:]*]+\.[^@[:space:]*]+$' then null else value end
 loop
  if jsonb_typeof(r)<>'object' or octet_length(r::text)>10000 then raise exception 'Invalid attendance row' using errcode='22023'; end if;
  em:=lower(btrim(r->>'email')); mid:=null;
  if em is null or em !~ '^[^@[:space:]*]+@[^@[:space:]*]+\.[^@[:space:]*]+$' then
   cat:='unresolved'; key:='unresolved:'||md5(r::text);
  else
   select member_id into mid from public.event_registrations where event_id=e.id and registered_email=em;
   cat:=case when mid is null then 'unregistered' else 'registered' end; key:=em;
  end if;
  ds:=case when e.attendance_mode='meet' then (r->>'duration_seconds')::integer else null end;
  if e.attendance_mode='meet' and (ds is null or ds<0 or ds>604800) then raise exception 'Meet attendance needs a valid duration in seconds' using errcode='22023'; end if;
  if e.attendance_mode='reviewed' and jsonb_typeof(r->'eligible') is distinct from 'boolean' then raise exception 'Non-Meet attendance needs reviewed eligibility' using errcode='22023'; end if;
  insert into public.event_attendance(event_id,row_key,email,member_id,duration_seconds,reviewed_eligible,raw_row,category,imported_by)
  values(e.id,key,em,mid,ds,case when e.attendance_mode='reviewed' then (r->>'eligible')::boolean else false end,r,cat,auth.uid())
  on conflict(event_id,row_key) do update set email=excluded.email,member_id=excluded.member_id,duration_seconds=excluded.duration_seconds,reviewed_eligible=excluded.reviewed_eligible,raw_row=excluded.raw_row,category=excluded.category,imported_by=excluded.imported_by,imported_at=now();
 end loop;
 select jsonb_build_object('matched',count(*) filter(where category='registered'),'unregistered',count(*) filter(where category='unregistered'),'unresolved',count(*) filter(where category='unresolved')) into counts from public.event_attendance where event_id=e.id;
 perform private.write_audit('attendance.import','events',e.id::text,null,counts); return counts;
end; $$;
create function private.issue_eligible_certificates(p_event uuid,p_member uuid default null) returns integer language plpgsql security definer set search_path='' as $$
declare n integer;
begin
 insert into public.issued_certificates(event_id,member_id,certificate_name,template_url,issued_by)
 select e.id,m.id,m.certificate_name,e.certificate_template_url,e.certificates_released_by
 from public.events e join public.event_registrations r on r.event_id=e.id
 join public.members m on m.id=r.member_id join public.event_attendance a on a.event_id=e.id and a.member_id=m.id
 where e.id=p_event and e.certificates_released_at is not null and e.certificate_template_url is not null and e.deleted_at is null and e.cancelled_at is null
 and m.account_status='active' and m.certificate_name is not null and m.certificate_name_confirmed_at is not null and (p_member is null or m.id=p_member)
 and ((e.attendance_mode='meet' and a.duration_seconds>=1200) or (e.attendance_mode='reviewed' and a.reviewed_eligible))
 on conflict(event_id,member_id) do nothing;
 get diagnostics n=row_count; return n;
end; $$;
create function public.release_event_certificates(p_event_id uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare e public.events; n integer; pending integer;
begin
 if private.manages_event(p_event_id) is not true then raise exception 'This event is outside your organizer scope' using errcode='42501'; end if;
 select * into e from public.events where id=p_event_id for update;
 if not found or private.manages_scope(e.region_id,e.community_id) is not true then raise exception 'This event is outside your organizer scope' using errcode='42501'; end if;
 if e.certificate_template_url is null or e.published_at is null or e.deleted_at is not null or e.cancelled_at is not null then raise exception 'A published active event and signed template are required' using errcode='22023'; end if;
 update public.events set certificates_released_by=case when certificates_released_at is null then auth.uid() else certificates_released_by end,certificates_released_at=coalesce(certificates_released_at,now()) where id=e.id;
 n:=private.issue_eligible_certificates(e.id);
 select count(*) into pending from public.event_registrations r join public.members m on m.id=r.member_id join public.event_attendance a on a.event_id=r.event_id and a.member_id=r.member_id
 where r.event_id=e.id and m.account_status='active' and m.certificate_name is null and ((e.attendance_mode='meet' and a.duration_seconds>=1200) or (e.attendance_mode='reviewed' and a.reviewed_eligible));
 perform private.write_audit('certificates.release','events',e.id::text,null,jsonb_build_object('issued',n,'pending_names',pending)); return jsonb_build_object('issued',n,'pending_names',pending);
end; $$;
create function public.confirm_my_certificate_name(p_name text) returns text language plpgsql security definer set search_path='' as $$
declare m public.members; n text:=btrim(p_name); eid uuid;
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 if n is null or length(n) not between 1 and 200 then raise exception 'Enter your certificate name, at most 200 characters' using errcode='22023'; end if;
 select * into m from public.members where id=auth.uid() for update;
 if m.certificate_name is not null and m.certificate_name<>n then raise exception 'Certificate name is locked; request a correction' using errcode='PT409'; end if;
 if not exists(select 1 from public.event_registrations r join public.events e on e.id=r.event_id join public.event_attendance a on a.event_id=e.id and a.member_id=r.member_id where r.member_id=m.id and e.certificates_released_at is not null and ((e.attendance_mode='meet' and a.duration_seconds>=1200) or (e.attendance_mode='reviewed' and a.reviewed_eligible))) then raise exception 'A released event certificate must need your name first' using errcode='PT409'; end if;
 update public.members set certificate_name=n,certificate_name_confirmed_at=coalesce(certificate_name_confirmed_at,now()) where id=m.id;
 for eid in select event_id from public.event_registrations where member_id=m.id loop perform private.issue_eligible_certificates(eid,m.id); end loop;
 return n;
end; $$;
create function public.request_certificate_name_change(p_name text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare rid uuid; m public.members;
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 select * into m from public.members where id=auth.uid() for update;
 if m.certificate_name is null or m.certificate_name=btrim(p_name) then raise exception 'No confirmed name to correct' using errcode='PT409'; end if;
 insert into public.certificate_name_requests(member_id,old_name,new_name,reason) values(m.id,m.certificate_name,btrim(p_name),private.clean_reason(p_reason,true)) returning id into rid; return rid;
end; $$;
create function public.review_certificate_name_change(p_request_id uuid,p_approve boolean,p_note text default null) returns uuid language plpgsql security definer set search_path='' as $$
declare r public.certificate_name_requests; m public.members;
begin
 if not private.is_super_admin() then raise exception 'Only a Super Admin reviews certificate names' using errcode='42501'; end if;
 select * into r from public.certificate_name_requests where id=p_request_id for update;
 if not found or r.status<>'pending' then raise exception 'Request is missing or already reviewed' using errcode='PT409'; end if;
 if r.member_id=auth.uid() then raise exception 'You cannot review your own request' using errcode='42501'; end if;
 if p_approve is null or length(p_note)>2000 then raise exception 'Invalid review' using errcode='22023'; end if;
 select * into m from public.members where id=r.member_id for update;
 if p_approve then
  if m.account_status<>'active' then raise exception 'Member is not active' using errcode='PT409'; end if;
  if m.certificate_name is distinct from r.old_name then raise exception 'Certificate name has changed; file a new request' using errcode='PT409'; end if;
  -- Issued records retain their immutable recipient names. This correction applies to future issuance.
  update public.members set certificate_name=r.new_name,certificate_name_confirmed_at=now() where id=r.member_id;
 end if;
 update public.certificate_name_requests set status=case when p_approve then 'approved' else 'rejected' end,reviewed_by=auth.uid(),reviewed_at=now(),review_note=nullif(btrim(p_note),'') where id=r.id;
 perform private.write_audit('certificate_name.review','certificate_name_requests',r.id::text,to_jsonb(r),jsonb_build_object('approved',p_approve)); return r.id;
end; $$;
create function public.list_my_certificates() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(to_jsonb(c)||jsonb_build_object('event_name',e.name,'event_date',coalesce(e.display_date,to_char(e.starts_at at time zone 'Asia/Kolkata','DD Mon YYYY'))) order by c.issued_at desc) from public.issued_certificates c join public.events e on e.id=c.event_id where c.member_id=auth.uid()),'[]');
end; $$;
create function public.verify_issued_certificate(p_id uuid) returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('id',c.id,'event_name',e.name,'issued_at',c.issued_at,'valid',true) from public.issued_certificates c join public.events e on e.id=c.event_id where c.id=p_id;
$$;
create function public.export_event_records(p_event_id uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if private.manages_event(p_event_id) is not true then raise exception 'This event is outside your organizer scope' using errcode='42501'; end if;
 return jsonb_build_object('registrations',coalesce((select jsonb_agg(to_jsonb(r)||jsonb_build_object('answers',f.answers,'field_schema',f.field_schema,'attendance',to_jsonb(a),'certificate_id',c.id) order by r.registered_at) from public.event_registrations r join public.form_responses f on f.id=r.response_id left join public.event_attendance a on a.event_id=r.event_id and a.member_id=r.member_id left join public.issued_certificates c on c.event_id=r.event_id and c.member_id=r.member_id where r.event_id=p_event_id),'[]'),'attendance',coalesce((select jsonb_agg(to_jsonb(a) order by a.category,a.email) from public.event_attendance a where a.event_id=p_event_id),'[]'));
end; $$;
create function public.list_lounge_events() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(to_jsonb(e)||jsonb_build_object('stage',case when e.archive or e.ends_at<=now() then 'past' when e.starts_at<=now() then 'live' else 'upcoming' end,'can_manage',private.manages_event(e.id),'registration',(select to_jsonb(r) from public.event_registrations r where r.event_id=e.id and r.member_id=auth.uid()),'attendance',(select to_jsonb(a)-'raw_row'-'imported_by' from public.event_attendance a where a.event_id=e.id and a.member_id=auth.uid()),'certificate',(select to_jsonb(c) from public.issued_certificates c where c.event_id=e.id and c.member_id=auth.uid()),'needs_certificate_name',e.certificates_released_at is not null and exists(select 1 from public.event_registrations r join public.event_attendance a on a.event_id=r.event_id and a.member_id=r.member_id where r.event_id=e.id and r.member_id=auth.uid() and ((e.attendance_mode='meet' and a.duration_seconds>=1200) or (e.attendance_mode='reviewed' and a.reviewed_eligible))) and (select certificate_name is null from public.members where id=auth.uid())) order by e.starts_at desc nulls last) from public.events e where e.deleted_at is null and (private.manages_event(e.id) or (e.published_at is not null and e.published_at<=now() and (e.archive or e.ends_at<=now() or private.in_audience(e.region_id,e.audience_cohorts))))),'[]');
end; $$;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('certificate-templates','certificate-templates',true,10485760,array['image/png','image/jpeg','image/webp']) on conflict(id) do nothing;
create function private.manages_template_path(p_path text) returns boolean language plpgsql stable security definer set search_path='' as $$
begin
 if split_part(p_path,'/',1) !~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' then return false; end if;
 return private.manages_event(split_part(p_path,'/',1)::uuid) and not exists(select 1 from public.events where id=split_part(p_path,'/',1)::uuid and certificates_released_at is not null);
end; $$;
create policy certificate_templates_upload on storage.objects for insert to authenticated with check(bucket_id='certificate-templates' and private.manages_template_path(name));
-- Upload new object names instead of replacing released template assets.
create policy certificate_templates_read on storage.objects for select to authenticated using(bucket_id='certificate-templates' and private.manages_template_path(name));

create table public.announcements(
 id uuid primary key default gen_random_uuid(),title text not null check(length(btrim(title)) between 1 and 200),body text not null check(length(btrim(body)) between 1 and 4000),
 link text check(link is null or (link ~ '^https://[^[:space:]<>"[:cntrl:]]+$' and length(link)<=2048)),region_id smallint references public.regions(id),community_id smallint references public.communities(id),audience_cohorts text[] not null default '{}',
 starts_at timestamptz not null default now(),ends_at timestamptz,created_by uuid not null references public.members(id),created_at timestamptz not null default now(),check(ends_at is null or ends_at>starts_at),check(not(region_id is not null and community_id is not null))
);
create table public.member_notice_states(
 announcement_id uuid not null references public.announcements(id),member_id uuid not null references public.members(id),read_at timestamptz,dismissed_at timestamptz,primary key(announcement_id,member_id)
);
alter table public.announcements enable row level security;
alter table public.member_notice_states enable row level security;
revoke all on public.announcements,public.member_notice_states from public,anon,authenticated,service_role;
grant select on public.announcements,public.member_notice_states to authenticated;
create policy announcements_read on public.announcements for select to authenticated using(private.in_audience(region_id,audience_cohorts) and starts_at<=now() or private.manages_scope(region_id,community_id));
create policy notice_states_read on public.member_notice_states for select to authenticated using(private.is_active_member() and member_id=auth.uid());
create function public.save_announcement(p_announcement jsonb) returns uuid language plpgsql security definer set search_path='' as $$
declare aid uuid:=coalesce((p_announcement->>'id')::uuid,gen_random_uuid()); r smallint:=(p_announcement->>'region_id')::smallint; c smallint:=(p_announcement->>'community_id')::smallint; oldn public.announcements; cohorts text[];
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 perform pg_advisory_xact_lock(hashtextextended('notice:'||aid::text,0));
 select * into oldn from public.announcements where id=aid for update;
 if private.manages_scope(r,c) is not true or (oldn.id is not null and private.manages_scope(oldn.region_id,oldn.community_id) is not true) then raise exception 'This notice is outside your organizer scope' using errcode='42501'; end if;
 select coalesce(array_agg(value),'{}') into cohorts from jsonb_array_elements_text(coalesce(p_announcement->'audience_cohorts','[]'));
 perform private.validate_audience(cohorts);
 insert into public.announcements(id,title,body,link,region_id,starts_at,ends_at,created_by,community_id,audience_cohorts) values(aid,btrim(p_announcement->>'title'),btrim(p_announcement->>'body'),nullif(btrim(p_announcement->>'link'),''),r,coalesce((p_announcement->>'starts_at')::timestamptz,now()),(p_announcement->>'ends_at')::timestamptz,auth.uid(),c,cohorts)
 on conflict(id) do update set community_id=excluded.community_id,audience_cohorts=excluded.audience_cohorts,title=excluded.title,body=excluded.body,link=excluded.link,region_id=excluded.region_id,starts_at=excluded.starts_at,ends_at=excluded.ends_at;
 perform private.write_audit('notice.save','announcements',aid::text,null,p_announcement); return aid;
end; $$;
create function public.list_my_notices() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(to_jsonb(a)||jsonb_build_object('read_at',s.read_at,'dismissed_at',s.dismissed_at,'show_banner',a.starts_at>now()-interval '72 hours' and (a.ends_at is null or a.ends_at>now()) and s.dismissed_at is null) order by a.starts_at desc) from public.announcements a left join public.member_notice_states s on s.announcement_id=a.id and s.member_id=auth.uid() where a.starts_at<=now() and private.in_audience(a.region_id,a.audience_cohorts)),'[]');
end; $$;
create function public.set_my_notice_state(p_announcement_id uuid,p_read boolean default true,p_dismiss boolean default false) returns void language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.announcements a where a.id=p_announcement_id and a.starts_at<=now() and private.in_audience(a.region_id,a.audience_cohorts)) then raise exception 'Notice is outside your audience' using errcode='42501'; end if;
 insert into public.member_notice_states(announcement_id,member_id,read_at,dismissed_at) values(p_announcement_id,auth.uid(),case when p_read then now() end,case when p_dismiss then now() end)
 on conflict(announcement_id,member_id) do update set read_at=case when p_read then coalesce(member_notice_states.read_at,now()) else member_notice_states.read_at end,dismissed_at=case when p_dismiss then coalesce(member_notice_states.dismissed_at,now()) else member_notice_states.dismissed_at end;
end; $$;
revoke execute on function private.issue_eligible_certificates(uuid,uuid),private.manages_template_path(text) from public,anon,authenticated,service_role;
grant execute on function private.manages_template_path(text) to authenticated;
revoke execute on function public.import_event_attendance(uuid,jsonb),public.release_event_certificates(uuid),public.confirm_my_certificate_name(text),public.request_certificate_name_change(text,text),public.review_certificate_name_change(uuid,boolean,text),public.list_my_certificates(),public.verify_issued_certificate(uuid),public.export_event_records(uuid),public.list_lounge_events(),public.save_announcement(jsonb),public.list_my_notices(),public.set_my_notice_state(uuid,boolean,boolean) from public,anon,authenticated,service_role;
grant execute on function public.import_event_attendance(uuid,jsonb),public.release_event_certificates(uuid),public.confirm_my_certificate_name(text),public.request_certificate_name_change(text,text),public.review_certificate_name_change(uuid,boolean,text),public.list_my_certificates(),public.export_event_records(uuid),public.list_lounge_events(),public.save_announcement(jsonb),public.list_my_notices(),public.set_my_notice_state(uuid,boolean,boolean) to authenticated;
grant execute on function public.verify_issued_certificate(uuid) to anon,authenticated;

-- Hard delete also erases the Lounge copies of the member's identity (names, emails, answers,
-- attendance rows, reasons). Records stay so counts and verification IDs remain consistent.
do $$ declare body text; fixed text; anchor text:='update public.regional_registrations  set answers = ''{}''::jsonb where member_id = v_member.id;'; begin
 body:=pg_get_functiondef('public.svc_execute_hard_delete(uuid,uuid)'::regprocedure);
 fixed:=replace(body,anchor,'update public.members set certificate_name = null, certificate_name_confirmed_at = null, cohort = null where id = v_member.id;
  update public.form_responses set submitted_email = ''deleted-'' || v_member.id::text || ''@deleted.invalid'', answers = ''{}''::jsonb where member_id = v_member.id;
  update public.event_registrations set registered_email = ''deleted-'' || v_member.id::text || ''@deleted.invalid'' where member_id = v_member.id;
  update public.event_attendance set email = null, row_key = ''redacted:'' || id::text, raw_row = ''{}''::jsonb where member_id = v_member.id or email = v_member.email;
  update public.issued_certificates set certificate_name = ''Deleted member'' where member_id = v_member.id;
  update public.certificate_name_requests set old_name = null, new_name = ''Deleted member'', reason = ''Redacted'', review_note = null where member_id = v_member.id;
  update public.member_region_requests set reason = ''Redacted'', review_note = null where member_id = v_member.id;
  '||anchor);
 if fixed=body then raise exception 'Expected hard-delete anchor not found'; end if;
 execute fixed;
end $$;
