-- Review of form responses: managers approve or reject; a rejected member may resubmit in place.
alter table public.form_responses
  add column review_status text not null default 'pending' check (review_status in ('pending','approved','rejected')),
  add column review_reason text,
  add column reviewed_by uuid references public.members(id),
  add column reviewed_at timestamptz,
  add column resubmitted_at timestamptz,
  add constraint form_responses_review_reason_check check (
    (review_status = 'rejected' and review_reason is not null and review_reason = btrim(review_reason) and length(review_reason) between 1 and 500)
    or (review_status <> 'rejected' and review_reason is null));

-- p_expected_at is the coalesce(resubmitted_at, submitted_at) the reviewer loaded: a decision on a
-- version the reviewer never saw (the member resubmitted meanwhile) is refused with PT409.
create function public.review_form_response(p_response_id uuid, p_status text, p_expected_at timestamptz, p_reason text default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.form_responses; v_reason text := nullif(btrim(p_reason), '');
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 if p_status is null or p_status not in ('approved','rejected','pending') then raise exception 'Invalid review status' using errcode='22023'; end if;
 if p_status = 'rejected' and (v_reason is null or length(v_reason) > 500) then raise exception 'A rejection needs a reason of at most 500 characters' using errcode='22023'; end if;
 select * into r from public.form_responses where id = p_response_id for update;
 if not found or private.manages_form(r.form_id) is not true then raise exception 'This response is outside your organizer scope' using errcode='42501'; end if;
 if r.member_id = auth.uid() and not private.is_super_admin() then raise exception 'You cannot review your own response' using errcode='42501'; end if;
 if coalesce(r.resubmitted_at, r.submitted_at) is distinct from p_expected_at then raise exception 'This response changed since you loaded it. Refresh and review again.' using errcode='PT409'; end if;
 update public.form_responses set review_status = p_status,
   review_reason = case when p_status = 'rejected' then v_reason end,
   reviewed_by = case when p_status = 'pending' then null else auth.uid() end,
   reviewed_at = case when p_status = 'pending' then null else now() end
 where id = r.id returning * into r;
 perform private.write_audit('form.review', 'form_responses', r.id::text, null,
   jsonb_build_object('form_id', r.form_id, 'member_id', r.member_id, 'review_status', r.review_status, 'review_reason', r.review_reason));
 return jsonb_build_object('id', r.id, 'review_status', r.review_status, 'review_reason', r.review_reason, 'reviewed_at', r.reviewed_at);
end; $$;
revoke execute on function public.review_form_response(uuid,text,timestamptz,text) from public,anon,authenticated,service_role;
grant execute on function public.review_form_response(uuid,text,timestamptz,text) to authenticated;

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
  -- submitted_at stays the first-received time so serial numbers never move.
  update public.form_responses set submitted_email=(select email from public.members where id=auth.uid()),field_schema=f.fields,answers=a,resubmitted_at=now(),review_status='pending',review_reason=null,reviewed_by=null,reviewed_at=null where id=rid;
  -- Attendance import matches on the registration email, so it follows the corrected submission.
  if f.event_id is not null then
   update public.event_registrations set registered_email=(select email from public.members where id=auth.uid()) where event_id=f.event_id and member_id=auth.uid();
  end if;
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

-- A rejected application does not unlock the invite; resubmitting returns it to pending first.
create or replace function public.get_lounge_form_invite(p_form_id uuid) returns text language plpgsql stable security definer set search_path='' as $$
declare v_status text;
begin
 if not private.is_active_member() then raise exception 'Submit this application before viewing the invite' using errcode='42501'; end if;
 select review_status into v_status from public.form_responses where form_id=p_form_id and member_id=auth.uid();
 if not found then raise exception 'Submit this application before viewing the invite' using errcode='42501'; end if;
 if v_status='rejected' then raise exception 'Your response was not approved. Fix it and send it again to get the invite.' using errcode='42501'; end if;
 return (select i.invite_url from private.lounge_form_invites i join public.lounge_forms f on f.id=i.form_id left join public.events e on e.id=f.event_id where f.id=p_form_id and private.in_audience(f.region_id,f.audience_cohorts) and (f.event_id is null or private.in_audience(e.region_id,e.audience_cohorts)));
end; $$;

create or replace function public.export_form_responses(p_form_id uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if private.manages_form(p_form_id) is not true then raise exception 'This form is outside your organizer scope' using errcode='42501'; end if;
 -- serial = arrival order (1 = first received), stable regardless of how the caller sorts or filters.
 return coalesce((select jsonb_agg(jsonb_build_object('id',x.id,'email',x.submitted_email,'submitted_at',x.submitted_at,'answers',x.answers,'field_schema',x.field_schema,
   'serial',x.serial,'resubmitted_at',x.resubmitted_at,'review_status',x.review_status,'review_reason',x.review_reason,'reviewed_at',x.reviewed_at,
   'reviewer_name',x.reviewer_name,'reviewer_email',x.reviewer_email,'member_full_name',x.full_name,'member_preferred_name',x.preferred_name) order by x.submitted_at,x.id)
  from (select r.*,row_number() over(order by r.submitted_at,r.id) as serial,m.full_name,m.preferred_name,rv.full_name as reviewer_name,rv.email as reviewer_email
   from public.form_responses r join public.members m on m.id=r.member_id left join public.members rv on rv.id=r.reviewed_by where r.form_id=p_form_id) x),'[]');
end; $$;

-- Hard delete also redacts the review reason, which can quote the member's own details. A rejected
-- row keeps a placeholder because form_responses_review_reason_check forbids a null reason there.
-- Same body as the live function (20260928193310 as patched by 20261009150200) plus that one change.
create or replace function public.svc_execute_hard_delete(p_actor uuid, p_request_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare
  v_request public.approval_requests%rowtype;
  v_member  public.members%rowtype;
begin
  perform private.bind_super_admin_actor(p_actor);

  select * into v_request from public.approval_requests where id = p_request_id for update;
  if not found or v_request.type <> 'member_hard_delete' then
    raise exception 'Hard-delete request % does not exist', p_request_id using errcode = 'no_data_found';
  end if;

  select * into v_member from public.members where id = v_request.target_member_id for update;

  if v_request.status = 'approved' and v_member.anonymised_at is not null then
    return jsonb_build_object('member_id', v_member.id, 'state', 'already_executed');
  end if;

  if v_request.status <> 'pending' then
    raise exception 'Request is already %', v_request.status using errcode = 'PT409';
  end if;

  -- The second Super Admin rule (§10). The table's lifecycle CHECK enforces it again.
  if v_request.requested_by = p_actor then
    raise exception 'A different Super Admin must approve a hard delete' using errcode = 'insufficient_privilege';
  end if;

  if v_member.anonymised_at is not null then
    raise exception 'Member is already hard-deleted' using errcode = 'PT409';
  end if;
  if v_member.account_status <> 'deleted' or v_member.deleted_at > now() - interval '30 days' then
    raise exception 'Member must have been soft-deleted at least 30 days ago'
      using errcode = 'PT409';
  end if;
  if exists (select 1 from public.super_admin_allowlist s where s.user_id = v_member.id) then
    raise exception 'Target is a Super Admin' using errcode = 'PT409';
  end if;

  -- Do not copy the personal data being erased into new audit rows.
  perform set_config('app.suppress_row_audit', 'on', true);

  update public.members
     set full_name      = 'Deleted member',
         preferred_name = null,
         gender         = null,
         bio            = null,
         whatsapp_data  = null,
         email          = 'deleted-' || v_member.id::text || '@deleted.invalid',
         phone          = private.placeholder_phone(v_member.id),
         anonymised_at  = now()
   where id = v_member.id;

  update public.members set certificate_name = null, certificate_name_confirmed_at = null, cohort = null where id = v_member.id;
  update public.form_responses set submitted_email = 'deleted-' || v_member.id::text || '@deleted.invalid', answers = '{}'::jsonb,
         review_reason = case when review_status = 'rejected' then 'Redacted' else null end where member_id = v_member.id;
  update public.event_registrations set registered_email = 'deleted-' || v_member.id::text || '@deleted.invalid' where member_id = v_member.id;
  update public.event_attendance set email = null, row_key = 'redacted:' || id::text, raw_row = '{}'::jsonb where member_id = v_member.id or email = v_member.email;
  update public.issued_certificates set certificate_name = 'Deleted member' where member_id = v_member.id;
  update public.certificate_name_requests set old_name = null, new_name = 'Deleted member', reason = 'Redacted', review_note = null where member_id = v_member.id;
  update public.member_region_requests set reason = 'Redacted', review_note = null where member_id = v_member.id;
  update public.regional_registrations  set answers = '{}'::jsonb where member_id = v_member.id;
  update public.community_registrations set answers = '{}'::jsonb where member_id = v_member.id;

  -- Redact this member's personal data from every request about them (decision: snapshots
  -- are scrubbed; the requests themselves stay, §13).
  update public.approval_requests
     set target_snapshot  = jsonb_build_object('redacted', true, 'member_id', v_member.id,
                                               'member_code', v_member.member_code),
         requested_change = case when requested_change ? 'answers'
                                 then jsonb_build_object('answers', '{}'::jsonb)
                                 else requested_change end
   where target_member_id = v_member.id;

  update public.approval_requests
     set status = 'approved', reviewed_by = p_actor, reviewed_at = now(), executed_at = now()
   where id = v_request.id;

  perform set_config('app.suppress_row_audit', 'off', true);

  perform private.write_audit(
    'member.hard_delete', 'members', v_member.id::text, null,
    jsonb_build_object('member_id', v_member.id, 'member_code', v_member.member_code, 'anonymised', true),
    v_request.id);

  return jsonb_build_object('member_id', v_member.id, 'state', 'executed');
end;
$$;
