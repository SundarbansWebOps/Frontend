-- Review of form responses: managers approve or reject; a rejected member may resubmit in place.
alter table public.form_responses
  add column review_status text not null default 'pending' check (review_status in ('pending','approved','rejected')),
  add column review_reason text,
  add column reviewed_by uuid references public.members(id),
  add column reviewed_at timestamptz,
  add constraint form_responses_review_reason_check check (
    (review_status = 'rejected' and review_reason is not null and review_reason = btrim(review_reason) and length(review_reason) between 1 and 500)
    or (review_status <> 'rejected' and review_reason is null));

create function public.review_form_response(p_response_id uuid, p_status text, p_reason text default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.form_responses; v_reason text := nullif(btrim(p_reason), '');
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 if p_status is null or p_status not in ('approved','rejected','pending') then raise exception 'Invalid review status' using errcode='22023'; end if;
 if p_status = 'rejected' and (v_reason is null or length(v_reason) > 500) then raise exception 'A rejection needs a reason of at most 500 characters' using errcode='22023'; end if;
 select * into r from public.form_responses where id = p_response_id for update;
 if not found or private.manages_form(r.form_id) is not true then raise exception 'This response is outside your organizer scope' using errcode='42501'; end if;
 update public.form_responses set review_status = p_status,
   review_reason = case when p_status = 'rejected' then v_reason end,
   reviewed_by = case when p_status = 'pending' then null else auth.uid() end,
   reviewed_at = case when p_status = 'pending' then null else now() end
 where id = r.id returning * into r;
 perform private.write_audit('form.review', 'form_responses', r.id::text, null,
   jsonb_build_object('form_id', r.form_id, 'member_id', r.member_id, 'review_status', r.review_status, 'review_reason', r.review_reason));
 return jsonb_build_object('id', r.id, 'review_status', r.review_status, 'review_reason', r.review_reason, 'reviewed_at', r.reviewed_at);
end; $$;
revoke execute on function public.review_form_response(uuid,text,text) from public,anon,authenticated,service_role;
grant execute on function public.review_form_response(uuid,text,text) to authenticated;

create or replace function public.submit_lounge_form(p_form_id uuid,p_answers jsonb,p_save_phone boolean default false) returns jsonb language plpgsql security definer set search_path='' as $$
declare f public.lounge_forms; field jsonb; k text; val jsonb; rid uuid; v_phone text; a jsonb:=p_answers; v_status text; v_wrote boolean:=false;
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
 select id,review_status into rid,v_status from public.form_responses where form_id=f.id and member_id=auth.uid() for update;
 if rid is null then
  insert into public.form_responses(form_id,member_id,submitted_email,field_schema,answers) select f.id,id,email,f.fields,a from public.members where id=auth.uid() returning id into rid;
  if f.event_id is not null then
   insert into public.event_registrations(event_id,member_id,response_id,registered_email) select f.event_id,id,rid,email from public.members where id=auth.uid() on conflict do nothing;
  end if;
  v_wrote:=true;
 elsif v_status='rejected' then
  -- A rejected application is corrected in place: same response row (and event registration), back to pending.
  update public.form_responses set submitted_email=(select email from public.members where id=auth.uid()),field_schema=f.fields,answers=a,submitted_at=now(),review_status='pending',review_reason=null,reviewed_by=null,reviewed_at=null where id=rid;
  perform private.write_audit('form.resubmit','form_responses',rid::text,jsonb_build_object('review_status','rejected'),jsonb_build_object('review_status','pending','form_id',f.id));
  v_wrote:=true;
 end if;
 if v_wrote and p_save_phone and v_phone is not null then
  if exists(select 1 from public.member_roster where phone=v_phone) then raise exception 'Phone already belongs to another student' using errcode='23505'; end if;
  update public.members set phone=v_phone where id=auth.uid();
 end if;
 return jsonb_build_object('response_id',rid,'invite_url',public.get_lounge_form_invite(f.id),'registered',f.event_id is not null);
end; $$;

create or replace function public.list_lounge_forms() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(to_jsonb(f)||jsonb_build_object('submitted',exists(select 1 from public.form_responses where form_id=f.id and member_id=auth.uid()),'can_manage',private.manages_form(f.id),'accepting_responses',private.can_submit_form(f.id),'review_status',(select r.review_status from public.form_responses r where r.form_id=f.id and r.member_id=auth.uid()),'review_reason',(select r.review_reason from public.form_responses r where r.form_id=f.id and r.member_id=auth.uid())) order by f.created_at desc) from public.lounge_forms f where private.manages_form(f.id) or (f.published_at is not null and f.published_at<=now() and private.in_audience(f.region_id,f.audience_cohorts) and (f.event_id is null or private.can_register_event(f.event_id))) or exists(select 1 from public.form_responses where form_id=f.id and member_id=auth.uid())),'[]');
end; $$;

create or replace function public.export_form_responses(p_form_id uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if private.manages_form(p_form_id) is not true then raise exception 'This form is outside your organizer scope' using errcode='42501'; end if;
 -- serial = arrival order (1 = first received), stable regardless of how the caller sorts or filters.
 return coalesce((select jsonb_agg(jsonb_build_object('id',x.id,'email',x.submitted_email,'submitted_at',x.submitted_at,'answers',x.answers,'field_schema',x.field_schema,
   'serial',x.serial,'review_status',x.review_status,'review_reason',x.review_reason,'reviewed_at',x.reviewed_at,
   'reviewer_name',x.reviewer_name,'reviewer_email',x.reviewer_email,'member_full_name',x.full_name,'member_preferred_name',x.preferred_name) order by x.submitted_at,x.id)
  from (select r.*,row_number() over(order by r.submitted_at,r.id) as serial,m.full_name,m.preferred_name,rv.full_name as reviewer_name,rv.email as reviewer_email
   from public.form_responses r join public.members m on m.id=r.member_id left join public.members rv on rv.id=r.reviewed_by where r.form_id=p_form_id) x),'[]');
end; $$;
