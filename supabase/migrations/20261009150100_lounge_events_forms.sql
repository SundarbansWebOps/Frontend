-- Scoped explicit publication, dynamic cohort cap, forms/responses and nonpublic invitations.
alter table public.events add column region_id smallint references public.regions(id);
alter table public.events add column published_at timestamptz;
alter table public.events add column audience_cohorts text[] not null default '{}';
alter table public.events add column attendance_mode text not null default 'meet' check(attendance_mode in('meet','reviewed'));
alter table public.events add column certificate_template_url text check(certificate_template_url is null or (certificate_template_url ~ '^https://[^[:space:]<>"[:cntrl:]]+$' and length(certificate_template_url)<=2048));
alter table public.events add column certificates_released_at timestamptz;
alter table public.events add column certificates_released_by uuid references public.members(id);
alter table public.events add column archive boolean not null default false;
alter table public.events add column source_key text unique check(length(source_key)<=200);
alter table public.events add column display_date text check(length(display_date)<=200);
alter table public.events add column image_url text check(image_url is null or (image_url ~ '^https://[^[:space:]<>"[:cntrl:]]+$' and length(image_url)<=2048));
alter table public.events add column event_type text check(length(event_type)<=100);
alter table public.events add column wing text check(length(wing)<=100);
alter table public.events add column location text check(length(location)<=500);
alter table public.events add column image_width integer check(image_width>0);
alter table public.events add column image_height integer check(image_height>0);
alter table public.events add column attendee_count integer check(attendee_count>=0);
-- Archive headcounts are display text ("50+"), never an invented exact count.
alter table public.events add column attendee_display text check(length(attendee_display)<=50);
alter table public.events add constraint events_one_scope check(not(region_id is not null and community_id is not null));
alter table public.events alter column starts_at drop not null;
alter table public.events alter column ends_at drop not null;
alter table public.events drop constraint events_period;
alter table public.events add constraint events_period check(archive or (starts_at is not null and ends_at is not null and ends_at>starts_at));

create function private.current_cohort(p_at timestamptz default now()) returns text language sql stable set search_path='' as $$
 select to_char(p_at at time zone 'Asia/Kolkata','YY')||'F'||case when extract(month from p_at at time zone 'Asia/Kolkata')<5 then '1' when extract(month from p_at at time zone 'Asia/Kolkata')<9 then '2' else '3' end;
$$;
create function private.next_cohort(p_at timestamptz default now()) returns text language sql stable set search_path='' as $$
 select private.current_cohort((date_trunc('year',p_at at time zone 'Asia/Kolkata')+make_interval(months=>case when extract(month from p_at at time zone 'Asia/Kolkata')<5 then 4 when extract(month from p_at at time zone 'Asia/Kolkata')<9 then 8 else 12 end)) at time zone 'Asia/Kolkata');
$$;
create function public.get_available_cohorts() returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('current',private.current_cohort(),'next',private.next_cohort(),'options',(select jsonb_agg(to_char(d,'YY')||'F'||case extract(month from d) when 1 then '1' when 5 then '2' else '3' end order by d) from generate_series(coalesce((select make_date(2000+min(substring(cohort from 1 for 2))::integer,1,1)::timestamp from public.members where cohort<=private.next_cohort()),date_trunc('year',now() at time zone 'Asia/Kolkata')), (date_trunc('year',now() at time zone 'Asia/Kolkata')+make_interval(months=>case when extract(month from now() at time zone 'Asia/Kolkata')<5 then 4 when extract(month from now() at time zone 'Asia/Kolkata')<9 then 8 else 12 end)),interval '4 months') d));
$$;
create function private.validate_audience(p_cohorts text[]) returns void language plpgsql stable set search_path='' as $$
declare c text;
begin
 if p_cohorts is null or cardinality(p_cohorts)>300 then raise exception 'Invalid cohort selection' using errcode='22023'; end if;
 foreach c in array p_cohorts loop
   if c is null or c !~ '^[0-9]{2}F[123]$' or c>private.next_cohort() then raise exception 'Only existing cohorts and the immediately next cohort may be selected' using errcode='22023'; end if;
 end loop;
end; $$;
create function private.manages_scope(p_region smallint,p_community smallint) returns boolean language sql stable security definer set search_path='' as $$
 select coalesce(private.is_super_admin() or (p_region is not null and p_community is null and p_region=private.my_rc_region()) or (p_region is null and p_community is not null and p_community=any(private.my_community_ids())),false);
$$;
create function private.manages_event(p_event uuid) returns boolean language sql stable security definer set search_path='' as $$
 select coalesce((select private.manages_scope(e.region_id,e.community_id) from public.events e where e.id=p_event),false);
$$;
create function private.in_audience(p_region smallint,p_cohorts text[]) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.members m where m.id=auth.uid() and m.account_status='active' and m.deleted_at is null and (p_region is null or m.region_id=p_region) and (cardinality(p_cohorts)=0 or m.cohort=any(p_cohorts)));
$$;
create function private.can_register_event(p_event uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.events e where e.id=p_event and e.published_at is not null and e.published_at<=now() and e.deleted_at is null and e.cancelled_at is null and not e.archive and e.ends_at>now() and private.in_audience(e.region_id,e.audience_cohorts));
$$;
create function private.validate_event() returns trigger language plpgsql security definer set search_path='' as $$
begin
 perform private.validate_audience(new.audience_cohorts);
 if auth.uid() is not null and not private.is_super_admin() and (new.archive or (tg_op='UPDATE' and old.archive)) then raise exception 'Only a Super Admin manages archived events' using errcode='42501'; end if;
 -- A signed template must be an object this event uploaded to the template bucket.
 if new.certificate_template_url is not null and (tg_op='INSERT' or new.certificate_template_url is distinct from old.certificate_template_url) and (
   new.certificate_template_url !~ ('^https://[a-z0-9]{20}\.supabase\.co/storage/v1/object/public/certificate-templates/'||new.id::text||'/[^/?#[:space:]]+$')
   or not exists(select 1 from storage.objects o where o.bucket_id='certificate-templates' and o.name=substring(new.certificate_template_url from '/certificate-templates/(.+)$'))) then
   raise exception 'Upload the signed template for this event first' using errcode='22023';
 end if;
 if tg_op='UPDATE' then
   if old.certificates_released_at is not null and (new.certificate_template_url is distinct from old.certificate_template_url or new.attendance_mode<>old.attendance_mode) then raise exception 'Released certificate template and attendance mode are locked' using errcode='PT409'; end if;
 end if;
 return new;
end; $$;
create trigger events_validate before insert or update on public.events for each row execute function private.validate_event();
drop policy events_select on public.events;
drop policy events_select_anon on public.events;
drop policy events_insert on public.events;
drop policy events_update on public.events;
create policy events_select on public.events for select to authenticated using(private.manages_scope(region_id,community_id) or (deleted_at is null and published_at is not null and published_at<=now() and (archive or ends_at<=now() or private.in_audience(region_id,audience_cohorts))));
create policy events_select_anon on public.events for select to anon using(deleted_at is null and published_at is not null and published_at<=now() and (archive or ends_at<=now()));
create policy events_insert on public.events for insert to authenticated with check(private.manages_scope(region_id,community_id));
create policy events_update on public.events for update to authenticated using(private.is_super_admin() or (deleted_at is null and private.manages_scope(region_id,community_id))) with check(private.manages_scope(region_id,community_id));
grant insert(region_id,published_at,audience_cohorts,attendance_mode,certificate_template_url,archive,source_key,display_date,image_url,event_type,wing,location,image_width,image_height,attendee_count,attendee_display) on public.events to authenticated;
grant update(region_id,published_at,audience_cohorts,attendance_mode,certificate_template_url,archive,source_key,display_date,image_url,event_type,wing,location,image_width,image_height,attendee_count,attendee_display) on public.events to authenticated;
-- A security-invoker view remains for existing public adapters; it cannot expose drafts/live rows.
drop view public.public_events;
grant select(published_at,region_id,archive,source_key,display_date,image_url,event_type,wing,location,image_width,image_height,attendee_count,attendee_display) on public.events to anon;
create view public.public_events with(security_invoker=true) as select id,name,description,registration_link,starts_at,ends_at,community_id,region_id,source_key,display_date,image_url,event_type,wing,location,image_width,image_height,attendee_count,attendee_display,'completed'::public.event_status as status from public.events where deleted_at is null and published_at is not null and published_at<=now() and (archive or ends_at<=now());
revoke all on public.public_events from public,anon,authenticated,service_role;
grant select on public.public_events to anon,authenticated,service_role;
create function public.list_public_past_events() returns setof public.public_events language sql stable security definer set search_path='' as $$ select * from public.public_events order by ends_at desc nulls last,display_date desc; $$;

create table public.lounge_forms(
 id uuid primary key default gen_random_uuid(),title text not null check(length(btrim(title)) between 1 and 200),description text check(length(description)<=4000),
 fields jsonb not null default '[]' check(jsonb_typeof(fields)='array' and jsonb_array_length(fields)<=100 and octet_length(fields::text)<=60000),
 region_id smallint references public.regions(id),community_id smallint references public.communities(id),event_id uuid references public.events(id),
 source_url text check(source_url is null or (source_url ~ '^https://[^[:space:]<>"[:cntrl:]]+$' and length(source_url)<=2048)),is_open boolean not null default true,published_at timestamptz,opens_at timestamptz,closes_at timestamptz,audience_cohorts text[] not null default '{}',
 created_by uuid not null references public.members(id),created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
 check(num_nonnulls(region_id,community_id,event_id)<=1),check(opens_at is null or closes_at is null or closes_at>opens_at)
);
create table private.lounge_form_invites(form_id uuid primary key references public.lounge_forms(id) on delete cascade,invite_url text not null check(invite_url ~ '^https://(chat\.whatsapp\.com/[A-Za-z0-9]+|wa\.me/[0-9]+)(\?[^[:space:]<>"[:cntrl:]]*)?$' and length(invite_url)<=2048));
alter table private.lounge_form_invites enable row level security;
revoke all on private.lounge_form_invites from public,anon,authenticated,service_role;
create table public.form_responses(
 id uuid primary key default gen_random_uuid(),form_id uuid not null references public.lounge_forms(id),member_id uuid not null references public.members(id),
 submitted_email text not null,field_schema jsonb not null,answers jsonb not null check(jsonb_typeof(answers)='object' and octet_length(answers::text)<=60000),submitted_at timestamptz not null default now(),unique(form_id,member_id)
);
create table public.event_registrations(
 event_id uuid not null references public.events(id),member_id uuid not null references public.members(id),response_id uuid not null references public.form_responses(id),registered_email text not null,
 registered_at timestamptz not null default now(),primary key(event_id,member_id)
);
create function private.manages_form(p_form uuid) returns boolean language sql stable security definer set search_path='' as $$
 select coalesce((select private.is_super_admin() or case when f.event_id is not null then private.manages_event(f.event_id) else private.manages_scope(f.region_id,f.community_id) end from public.lounge_forms f where f.id=p_form),false);
$$;
create function private.can_submit_form(p_form uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.lounge_forms f where f.id=p_form and f.is_open and f.published_at is not null and f.published_at<=now() and (f.opens_at is null or f.opens_at<=now()) and (f.closes_at is null or f.closes_at>now()) and private.in_audience(f.region_id,f.audience_cohorts) and (f.event_id is null or private.can_register_event(f.event_id)));
$$;
alter table public.lounge_forms enable row level security;
alter table public.form_responses enable row level security;
alter table public.event_registrations enable row level security;
revoke all on public.lounge_forms,public.form_responses,public.event_registrations from public,anon,authenticated,service_role;
grant select on public.lounge_forms,public.form_responses,public.event_registrations to authenticated;
create policy lounge_forms_read on public.lounge_forms for select to authenticated using(private.manages_form(id) or (private.is_active_member() and ((published_at is not null and published_at<=now() and private.in_audience(region_id,audience_cohorts) and (event_id is null or private.can_register_event(event_id))) or exists(select 1 from public.form_responses r where r.form_id=lounge_forms.id and r.member_id=auth.uid()))));
create policy form_responses_read on public.form_responses for select to authenticated using(private.is_active_member() and (member_id=auth.uid() or private.manages_form(form_id)));
create policy event_registrations_read on public.event_registrations for select to authenticated using(private.is_active_member() and (member_id=auth.uid() or private.manages_event(event_id)));
create function public.save_lounge_form(p_form jsonb) returns uuid language plpgsql security definer set search_path='' as $$
declare fid uuid:=coalesce((p_form->>'id')::uuid,gen_random_uuid()); oldf public.lounge_forms; r smallint:=(p_form->>'region_id')::smallint; c smallint:=(p_form->>'community_id')::smallint; e uuid:=(p_form->>'event_id')::uuid; fs jsonb:=coalesce(p_form->'fields','[]'); field jsonb; keys text[]:='{}'; cohorts text[]; phone_count integer:=0;
begin
 if jsonb_typeof(p_form) is distinct from 'object' then raise exception 'Form must be an object' using errcode='22023'; end if;
 perform pg_advisory_xact_lock(hashtextextended('form:'||fid::text,0));
 select * into oldf from public.lounge_forms where id=fid for update;
 -- Form ownership follows its linked event. Hold both the old and prospective scopes
 -- while authorizing a save, in deterministic order for a scope-changing edit.
 perform 1 from public.events where id=any(array[oldf.event_id,e]) order by id for share;
 if not private.is_active_member() or (oldf.id is not null and private.manages_form(fid) is not true) or (case when e is not null then private.manages_event(e) else private.manages_scope(r,c) end) is not true then raise exception 'This form is outside your organizer scope' using errcode='42501'; end if;
 if oldf.id is not null and (oldf.region_id is distinct from r or oldf.community_id is distinct from c or oldf.event_id is distinct from e) and exists(select 1 from public.form_responses where form_id=fid) then raise exception 'A submitted form cannot change scope' using errcode='PT409'; end if;
 if jsonb_typeof(fs) is distinct from 'array' or jsonb_array_length(fs)>100 then raise exception 'Invalid field schema' using errcode='22023'; end if;
 for field in select value from jsonb_array_elements(fs) loop
  if jsonb_typeof(field)<>'object' or jsonb_typeof(field->'key') is distinct from 'string' or jsonb_typeof(field->'label') is distinct from 'string' or jsonb_typeof(field->'type') is distinct from 'string' or (field->>'key') is null or (field->>'key') !~ '^[a-z][a-z0-9_]{0,63}$' or (field->>'key')=any(keys) or nullif(btrim(field->>'label'),'') is null or length(field->>'label')>300 or (field->>'type') is null or (field->>'type') not in('text','textarea','email','phone','select','checkbox','multiselect') or (field ? 'required' and jsonb_typeof(field->'required')<>'boolean') or (field ? 'allow_other' and jsonb_typeof(field->'allow_other')<>'boolean') or (field ? 'prefill' and coalesce(field->>'prefill','') not in('name','phone','email')) then raise exception 'Invalid or duplicate form field' using errcode='22023'; end if;
  if field->>'type' in('select','multiselect') and (jsonb_typeof(field->'options') is distinct from 'array' or jsonb_array_length(field->'options') not between 1 and 100 or exists(select 1 from jsonb_array_elements(field->'options') o where jsonb_typeof(o)<>'string' or length(o#>>'{}')>300)) then raise exception 'Select fields need text options' using errcode='22023'; end if;
  if field->>'type'='phone' then phone_count:=phone_count+1; end if;
  keys:=array_append(keys,field->>'key');
 end loop;
 if phone_count>1 then raise exception 'Use one phone field per form' using errcode='22023'; end if;
 select coalesce(array_agg(value),'{}') into cohorts from jsonb_array_elements_text(coalesce(p_form->'audience_cohorts','[]'));
 perform private.validate_audience(cohorts);
 insert into public.lounge_forms(id,title,description,fields,region_id,community_id,event_id,is_open,published_at,opens_at,closes_at,audience_cohorts,created_by,source_url)
 values(fid,btrim(p_form->>'title'),nullif(btrim(p_form->>'description'),''),fs,r,c,e,coalesce((p_form->>'is_open')::boolean,true),(p_form->>'published_at')::timestamptz,(p_form->>'opens_at')::timestamptz,(p_form->>'closes_at')::timestamptz,cohorts,auth.uid(),p_form->>'source_url')
 on conflict(id) do update set source_url=excluded.source_url,title=excluded.title,description=excluded.description,fields=excluded.fields,region_id=excluded.region_id,community_id=excluded.community_id,event_id=excluded.event_id,is_open=excluded.is_open,published_at=excluded.published_at,opens_at=excluded.opens_at,closes_at=excluded.closes_at,audience_cohorts=excluded.audience_cohorts,updated_at=now();
 if p_form ? 'invite_url' then
  if nullif(btrim(p_form->>'invite_url'),'') is null then delete from private.lounge_form_invites where form_id=fid;
  else insert into private.lounge_form_invites(form_id,invite_url) values(fid,btrim(p_form->>'invite_url')) on conflict(form_id) do update set invite_url=excluded.invite_url; end if;
 end if;
 perform private.write_audit('form.save','lounge_forms',fid::text,to_jsonb(oldf),p_form-'invite_url'); return fid;
end; $$;
create function public.list_lounge_forms() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(to_jsonb(f)||jsonb_build_object('submitted',exists(select 1 from public.form_responses where form_id=f.id and member_id=auth.uid()),'can_manage',private.manages_form(f.id),'accepting_responses',private.can_submit_form(f.id)) order by f.created_at desc) from public.lounge_forms f where private.manages_form(f.id) or (f.published_at is not null and f.published_at<=now() and private.in_audience(f.region_id,f.audience_cohorts) and (f.event_id is null or private.can_register_event(f.event_id))) or exists(select 1 from public.form_responses where form_id=f.id and member_id=auth.uid())),'[]');
end; $$;
create function public.get_lounge_form_invite(p_form_id uuid) returns text language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_active_member() or not exists(select 1 from public.form_responses where form_id=p_form_id and member_id=auth.uid()) then raise exception 'Submit this application before viewing the invite' using errcode='42501'; end if;
 return (select i.invite_url from private.lounge_form_invites i join public.lounge_forms f on f.id=i.form_id left join public.events e on e.id=f.event_id where f.id=p_form_id and private.in_audience(f.region_id,f.audience_cohorts) and (f.event_id is null or private.in_audience(e.region_id,e.audience_cohorts)));
end; $$;
create function public.submit_lounge_form(p_form_id uuid,p_answers jsonb,p_save_phone boolean default false) returns jsonb language plpgsql security definer set search_path='' as $$
declare f public.lounge_forms; field jsonb; k text; val jsonb; rid uuid; v_phone text; a jsonb:=p_answers;
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 select * into f from public.lounge_forms where id=p_form_id for share;
 if not found then raise exception 'This form is closed or outside your audience' using errcode='42501'; end if;
 -- Hold the event schedule/audience/publication stable through registration. A scope edit
 -- which was already in progress must commit before this lock and the checks below.
 if f.event_id is not null then perform 1 from public.events where id=f.event_id for share; end if;
 if not private.can_submit_form(f.id) then raise exception 'This form is closed or outside your audience' using errcode='42501'; end if;
 if jsonb_typeof(a) is distinct from 'object' or octet_length(a::text)>60000 then raise exception 'Invalid answers' using errcode='22023'; end if;
 if exists(select 1 from jsonb_object_keys(a) q(key) where not exists(select 1 from jsonb_array_elements(f.fields) x where x->>'key'=q.key)) then raise exception 'Unknown answer field' using errcode='22023'; end if;
 for field in select value from jsonb_array_elements(f.fields) loop
  k:=field->>'key'; val:=a->k;
  if coalesce((field->>'required')::boolean,false) and (val is null or val='null'::jsonb or (jsonb_typeof(val)='string' and nullif(btrim(a->>k),'') is null) or (field->>'type'='checkbox' and val<>'true'::jsonb)) then raise exception 'Required field: %',field->>'label' using errcode='22023'; end if;
  if val is null or val='null'::jsonb then continue; end if;
  if field->>'type'='checkbox' then
   if jsonb_typeof(val)<>'boolean' then raise exception 'Checkbox must be true or false' using errcode='22023'; end if;
  elsif field->>'type'='multiselect' then
   if jsonb_typeof(val)<>'array' or jsonb_array_length(val)>100 or exists(select 1 from jsonb_array_elements(val) x where jsonb_typeof(x)<>'string' or length(x#>>'{}')>300) or (select count(*) from jsonb_array_elements(val))<>(select count(distinct x) from jsonb_array_elements(val) x) then raise exception 'Choose distinct listed options' using errcode='22023'; end if;
   if exists(select 1 from jsonb_array_elements_text(val) x where not exists(select 1 from jsonb_array_elements_text(field->'options') o where o=x) and not(coalesce((field->>'allow_other')::boolean,false) and x like 'Other:%' and length(x)>6)) then raise exception 'Choose a listed option or permitted Other answer' using errcode='22023'; end if;
   if coalesce((field->>'required')::boolean,false) and jsonb_array_length(val)=0 then raise exception 'Required field: %',field->>'label' using errcode='22023'; end if;
  else
   if jsonb_typeof(val)<>'string' or length(a->>k)>10000 then raise exception 'Answer must be text, at most 10000 characters' using errcode='22023'; end if;
   if field->>'type' in('select','multiselect') and (a->>k)<>'' and not exists(select 1 from jsonb_array_elements_text(field->'options') o where o=a->>k) and not(coalesce((field->>'allow_other')::boolean,false) and (a->>k) like 'Other:%' and length(a->>k)>6) then raise exception 'Choose a listed option' using errcode='22023'; end if;
   if field->>'type'='email' and (a->>k)<>'' and (a->>k) !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'Invalid email answer' using errcode='22023'; end if;
   if field->>'type'='phone' then v_phone:=private.normalise_phone_optional(a->>k); a:=jsonb_set(a,array[k],coalesce(to_jsonb(v_phone),'null')); end if;
  end if;
 end loop;
 -- Serialize per-member writes; repeated submission returns the original response unchanged.
 perform 1 from public.members where id=auth.uid() for update;
 -- Region and suspension may have changed while waiting for the member lock. Authorize
 -- against that committed state; the held member/event/form locks then preserve it.
 if not private.is_active_member() or not private.can_submit_form(f.id) then raise exception 'This form is closed or outside your audience' using errcode='42501'; end if;
 select id into rid from public.form_responses where form_id=f.id and member_id=auth.uid();
 if rid is null then
  insert into public.form_responses(form_id,member_id,submitted_email,field_schema,answers) select f.id,id,email,f.fields,a from public.members where id=auth.uid() returning id into rid;
  if f.event_id is not null then
   insert into public.event_registrations(event_id,member_id,response_id,registered_email) select f.event_id,id,rid,email from public.members where id=auth.uid() on conflict do nothing;
  end if;
  if p_save_phone and v_phone is not null then
   if exists(select 1 from public.member_roster where phone=v_phone) then raise exception 'Phone already belongs to another student' using errcode='23505'; end if;
   update public.members set phone=v_phone where id=auth.uid();
  end if;
 end if;
 return jsonb_build_object('response_id',rid,'invite_url',public.get_lounge_form_invite(f.id),'registered',f.event_id is not null);
end; $$;
create function public.export_form_responses(p_form_id uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if private.manages_form(p_form_id) is not true then raise exception 'This form is outside your organizer scope' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'email',r.submitted_email,'submitted_at',r.submitted_at,'answers',r.answers,'field_schema',r.field_schema) order by r.submitted_at) from public.form_responses r where r.form_id=p_form_id),'[]');
end; $$;

revoke execute on function private.current_cohort(timestamptz),private.next_cohort(timestamptz),private.validate_audience(text[]),private.validate_event(),private.manages_scope(smallint,smallint),private.manages_event(uuid),private.in_audience(smallint,text[]),private.can_register_event(uuid),private.manages_form(uuid),private.can_submit_form(uuid) from public,anon,authenticated,service_role;
grant execute on function private.manages_scope(smallint,smallint),private.manages_event(uuid),private.in_audience(smallint,text[]),private.can_register_event(uuid),private.manages_form(uuid),private.can_submit_form(uuid) to authenticated;
revoke execute on function public.get_available_cohorts(),public.list_public_past_events(),public.save_lounge_form(jsonb),public.list_lounge_forms(),public.get_lounge_form_invite(uuid),public.submit_lounge_form(uuid,jsonb,boolean),public.export_form_responses(uuid) from public,anon,authenticated,service_role;
grant execute on function public.get_available_cohorts(),public.save_lounge_form(jsonb),public.list_lounge_forms(),public.get_lounge_form_invite(uuid),public.submit_lounge_form(uuid,jsonb,boolean),public.export_form_responses(uuid) to authenticated;
grant execute on function public.list_public_past_events() to anon,authenticated;
