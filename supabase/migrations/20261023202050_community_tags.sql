-- Community tags for every community, and one Students list (owner, 2026-10-24).
-- * public.community_members (20261023120000) becomes the tag list of every community, not only
--   members-only ones. Keyed by email so students who have not signed in yet can be tagged; a
--   student may carry several tags. Only Girls (members_only) gates content; the other tags are
--   for filtering and for their Head/Co-Head's view.
-- * A form marked joins_community tags a student when its Head/Co-Head (or a Super Admin)
--   approves the response. Only a Super Admin removes a tag; a Head/Co-Head asks through Requests.
-- * public.list_students is the one Students list: signed-in members and roster students together,
--   scoped to the caller (Super Admin: all; RC: own region; Head/Co-Head: own community's tags).

-- ── Tag list ────────────────────────────────────────────────────────────────

comment on table public.community_members is
  'Community tags by email. Added by a Super Admin (add_community_members) or by approving a response on a joins_community form; removed only by a Super Admin. Read by Super Admins and that community''s Head/Co-Head.';

-- From 20261023120000: any community, and only emails already in the house (an account that is
-- not deleted, or a roster row). not_in_house now lists emails that were skipped, not added.
create or replace function public.add_community_members(p_community_id smallint,p_emails text[]) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_valid text[]; v_invalid text[]; v_house text[]; v_added text[]; v_not_in_house text[]; v_result jsonb;
begin
 if not private.is_super_admin() then raise exception 'Only a Super Admin can add community members' using errcode='42501'; end if;
 if p_emails is null or cardinality(p_emails) not between 1 and 2000 then raise exception 'Send between 1 and 2000 emails' using errcode='22023'; end if;
 if not exists(select 1 from public.communities c where c.id=p_community_id) then raise exception 'Choose a community' using errcode='22023'; end if;
 with normal as (
  select distinct lower(btrim(x,E' \t\r\n')) as email from unnest(p_emails) x where nullif(btrim(x,E' \t\r\n'),'') is not null
 )
 select coalesce(array_agg(email order by email) filter(where email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),'{}'),
        coalesce(array_agg(email order by email) filter(where email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),'{}')
   into v_valid,v_invalid from normal;
 select coalesce(array_agg(x order by x) filter(where h),'{}'),coalesce(array_agg(x order by x) filter(where not h),'{}') into v_house,v_not_in_house
  from (select x,exists(select 1 from public.members m where m.email=x and m.account_status<>'deleted' and m.deleted_at is null)
                  or exists(select 1 from public.member_roster r where r.email=x) as h from unnest(v_valid) x) s;
 with ins as (
  insert into public.community_members(community_id,email,added_by) select p_community_id,x,auth.uid() from unnest(v_house) x
  on conflict(community_id,email) do nothing returning email
 )
 select coalesce(array_agg(email order by email),'{}') into v_added from ins;
 v_result:=jsonb_build_object('added',cardinality(v_added),'already',cardinality(v_house)-cardinality(v_added),'invalid',to_jsonb(v_invalid),'not_in_house',to_jsonb(v_not_in_house));
 perform private.write_audit('community_member.add','community_members',p_community_id::text,null,
  jsonb_build_object('community_id',p_community_id,'added',cardinality(v_added),'already',cardinality(v_house)-cardinality(v_added),'invalid',cardinality(v_invalid),'not_in_house',cardinality(v_not_in_house)));
 return v_result;
end; $$;

-- Replaced by list_students; the members-only list screen it served is gone.
drop function public.list_community_members(smallint);

-- ── Join forms tag on approval ──────────────────────────────────────────────

alter table public.lounge_forms add column joins_community boolean not null default false,
  add constraint lounge_forms_joins_community_check check (not joins_community or (community_id is not null and event_id is null));
comment on column public.lounge_forms.joins_community is
  'Approving a response tags the respondent with the form''s community (public.community_members).';

-- The tag follows the account's current email; an existing tag is kept.
create function private.tag_join_response(p_form uuid,p_member uuid,p_by uuid) returns void language sql security definer set search_path='' as $$
 insert into public.community_members(community_id,email,added_by)
 select f.community_id,m.email,p_by from public.lounge_forms f join public.members m on m.id=p_member
 where f.id=p_form and f.joins_community and m.deleted_at is null
 on conflict(community_id,email) do nothing;
$$;
create function private.tag_on_join_approval() returns trigger language plpgsql security definer set search_path='' as $$
begin
 perform private.tag_join_response(new.form_id,new.member_id,new.reviewed_by);
 return null;
end; $$;
create trigger form_responses_join_tag after update of review_status on public.form_responses for each row
 when (new.review_status='approved' and old.review_status is distinct from 'approved')
 execute function private.tag_on_join_approval();
-- Marking a form as a join form tags the responses it already approved.
create function private.tag_on_join_form() returns trigger language plpgsql security definer set search_path='' as $$
begin
 perform private.tag_join_response(r.form_id,r.member_id,r.reviewed_by) from public.form_responses r where r.form_id=new.id and r.review_status='approved';
 return null;
end; $$;
create trigger lounge_forms_join_tag after update of joins_community on public.lounge_forms for each row
 when (new.joins_community and not old.joins_community)
 execute function private.tag_on_join_form();
revoke execute on function private.tag_join_response(uuid,uuid,uuid),private.tag_on_join_approval(),private.tag_on_join_form() from public,anon,authenticated,service_role;

-- save_lounge_form (20261009150100) stores the switch; a save that omits it keeps the old value.
do $patch$ declare body text:=pg_get_functiondef('public.save_lounge_form(jsonb)'::regprocedure); fixed text; begin
 fixed:=replace(body,'audience_cohorts,created_by,source_url)','audience_cohorts,created_by,source_url,joins_community)');
 fixed:=replace(fixed,',auth.uid(),p_form->>''source_url'')',',auth.uid(),p_form->>''source_url'',coalesce((p_form->>''joins_community'')::boolean,false))');
 fixed:=replace(fixed,'audience_cohorts=excluded.audience_cohorts,updated_at=now();','audience_cohorts=excluded.audience_cohorts,joins_community=case when p_form ? ''joins_community'' then excluded.joins_community else lounge_forms.joins_community end,updated_at=now();');
 -- Each anchor must have matched exactly once.
 if length(fixed)-length(body) <> length(',joins_community')+length(',coalesce((p_form->>''joins_community'')::boolean,false)')
    +length('joins_community=case when p_form ? ''joins_community'' then excluded.joins_community else lounge_forms.joins_community end,') then
  raise exception 'save_lounge_form changed: anchors not found, update this migration';
 end if;
 execute fixed;
end $patch$;

-- The three live join forms (Technical, Cultural, E-Sports); the trigger tags their approved
-- responses. Not the Cultural core-team recruitment form. No-op where these forms do not exist.
update public.lounge_forms set joins_community=true where id in
 ('2fe75761-88af-5422-a3c7-d8e86830d3e2','5a905465-ec6c-50f2-9503-40cc2e97d00d','4f142402-d390-512b-89e3-8193705b809e');

-- ── Removal requests ────────────────────────────────────────────────────────
-- target_member_id is the student's account when they have signed in, otherwise the requester
-- (the column is required); requested_change carries the community and the email.

alter table public.approval_requests drop constraint approval_requests_target_shape;
alter table public.approval_requests add constraint approval_requests_target_shape check (
  (type in ('member_deletion','member_blacklist','member_hard_delete','member_profile_update','member_status_change','position_change','member_contact_change','community_tag_removal')
   and target_registration_id is null and target_event_id is null)
  or (type in ('community_record_update','community_record_deletion') and target_registration_id is not null and target_event_id is null)
  or (type='event_publish' and target_event_id is not null and target_registration_id is null));

drop index public.approval_requests_one_pending_per_member;
create unique index approval_requests_one_pending_per_member on public.approval_requests (type,target_member_id)
 where status='pending' and target_registration_id is null and target_event_id is null and type<>'community_tag_removal';
create unique index approval_requests_one_pending_per_tag on public.approval_requests ((requested_change->>'community_id'),(requested_change->>'email'))
 where status='pending' and type='community_tag_removal';

create function public.request_community_tag_removal(p_community_id smallint,p_email text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare
 v_email text:=lower(btrim(coalesce(p_email,'')));
 v_reason text;
 v_member public.members%rowtype;
 v_roster public.member_roster%rowtype;
 v_request public.approval_requests%rowtype;
begin
 if private.is_super_admin() then raise exception 'Super Admins remove community members directly' using errcode='42501'; end if;
 if p_community_id is null or not (p_community_id=any(private.my_community_ids())) then raise exception 'This community is outside your scope' using errcode='42501'; end if;
 v_reason:=private.clean_reason(p_reason,true);
 perform 1 from public.community_members where community_id=p_community_id and email=v_email for update;
 if not found then raise exception 'That email is not in this community' using errcode='P0002'; end if;
 select * into v_member from public.members where email=v_email and deleted_at is null;
 if v_member.id is null then select * into v_roster from public.member_roster where email=v_email; end if;
 begin
  insert into public.approval_requests(type,target_member_id,target_snapshot,requested_change,reason,requested_by)
  values('community_tag_removal',coalesce(v_member.id,auth.uid()),
   jsonb_build_object('member',case when v_member.id is not null
     then jsonb_build_object('full_name',v_member.full_name,'preferred_name',v_member.preferred_name,'email',v_member.email,'member_code',v_member.member_code,'region_id',v_member.region_id)
     else jsonb_build_object('full_name',v_roster.full_name,'email',v_email,'region_id',v_roster.region_id) end),
   jsonb_build_object('community_id',p_community_id,'community_name',(select c.name from public.communities c where c.id=p_community_id),'email',v_email),
   v_reason,auth.uid())
  returning * into v_request;
 exception when unique_violation then
  raise exception 'Removing this student is already waiting for approval' using errcode='unique_violation';
 end;
 perform private.write_audit('request.create','approval_requests',v_request.id::text,null,
  jsonb_build_object('type',v_request.type,'community_id',p_community_id,'reason',v_reason),v_request.id);
 return v_request.id;
end; $$;
revoke execute on function public.request_community_tag_removal(smallint,text,text) from public,anon,service_role;
grant execute on function public.request_community_tag_removal(smallint,text,text) to authenticated;

-- Called by approve_request after its review lock (Super Admin, not their own request, pending).
create function private.approve_community_tag_removal(p_request public.approval_requests,p_note text) returns uuid language plpgsql security definer set search_path='' as $$
declare v_row public.community_members;
begin
 delete from public.community_members where community_id=(p_request.requested_change->>'community_id')::smallint and email=p_request.requested_change->>'email' returning * into v_row;
 if not found then raise exception 'The student is no longer in this community; reject this request instead' using errcode='PT409'; end if;
 update public.approval_requests set status='approved',reviewed_by=auth.uid(),reviewed_at=now(),review_note=p_note,executed_at=now() where id=p_request.id;
 perform private.write_audit('request.approve','approval_requests',p_request.id::text,to_jsonb(v_row),
  jsonb_build_object('type',p_request.type,'community_id',v_row.community_id,'removed',true,'review_note',p_note),p_request.id);
 return p_request.id;
end; $$;
revoke execute on function private.approve_community_tag_removal(public.approval_requests,text) from public,anon,authenticated,service_role;

-- Same anchor as the event_publish branch (20261013194628).
do $patch$ declare body text:=pg_get_functiondef('public.approve_request(uuid,text)'::regprocedure); anchor text:='  -- Re-check the target now; things may have changed since the request was filed.'; begin
 if position(anchor in body)=0 then raise exception 'approve_request changed: anchor not found, update this migration'; end if;
 execute replace(body,anchor,
  '  if v_request.type = ''community_tag_removal'' then'||chr(10)||
  '    return private.approve_community_tag_removal(v_request, v_note);'||chr(10)||
  '  end if;'||chr(10)||chr(10)||anchor);
end $patch$;

-- admin_dashboard_requests (20261019120000): a Head/Co-Head reads their own requests too.
do $patch$ declare body text:=pg_get_functiondef('public.admin_dashboard_requests(text,integer)'::regprocedure); anchor text:='  if not v_sa and v_rc is null then'; begin
 if position(anchor in body)=0 then raise exception 'admin_dashboard_requests changed: anchor not found, update this migration'; end if;
 execute replace(body,anchor,'  if not v_sa and v_rc is null and cardinality(private.my_community_ids()) = 0 then');
end $patch$;

-- ── One Students list ───────────────────────────────────────────────────────

-- p_status: current (signed in and not deleted, plus not signed in yet), signed_in (active),
-- not_signed_in (roster), suspended, blacklisted, deleted (Super Admin). Name and phone match
-- signed-in students only; email and roll number match everyone. 50 rows a page.
-- communities lists only tags the caller may see: a members-only community's tags are visible to
-- Super Admins and its own Head/Co-Head.
create function public.list_students(p_query text default null,p_status text default 'current',p_region smallint default null,p_community smallint default null,p_offset integer default 0) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare
 v_sa boolean:=private.is_super_admin();
 v_rc smallint:=private.my_rc_region();
 v_heads smallint[]:=coalesce(private.my_community_ids(),'{}');
 v_q text:=lower(btrim(coalesce(p_query,'')));
 v_pat text; v_digit_pat text;
 v_hidden smallint[];
 v_result jsonb;
begin
 if not v_sa and v_rc is null and cardinality(v_heads)=0 then raise exception 'Students are outside your scope' using errcode='42501'; end if;
 if p_status is null or p_status not in('current','signed_in','not_signed_in','suspended','blacklisted','deleted') or (p_status='deleted' and not v_sa)
    or p_offset is null or p_offset<0 then raise exception 'Invalid student filter' using errcode='22023'; end if;
 if v_q<>'' and length(v_q) not between 3 and 100 then raise exception 'Search text must be 3 to 100 characters' using errcode='22023'; end if;
 select coalesce(array_agg(c.id),'{}') into v_hidden from public.communities c where c.members_only and not v_sa and not (c.id=any(v_heads));
 if p_community=any(v_hidden) then raise exception 'This community is outside your scope' using errcode='42501'; end if;
 if v_q<>'' then
  v_pat:='%'||replace(replace(replace(v_q,'\','\\'),'%','\%'),'_','\_')||'%';
  -- "98765 43210" or "+91-98765..." finds a stored +919876543210.
  if v_q ~ '^[0-9+() .-]+$' and length(regexp_replace(v_q,'[^0-9]','','g'))>=4 then v_digit_pat:='%'||regexp_replace(v_q,'[^0-9]','','g')||'%'; end if;
 end if;
 with students as (
  select 'member' as kind,m.id,m.email,m.member_code,m.full_name,m.preferred_name,m.phone,m.gender,m.region_id,m.account_status::text as account_status,m.created_at as joined_at
  from public.members m
  where p_status<>'not_signed_in'
    and case p_status when 'current' then m.account_status<>'deleted' and m.deleted_at is null
                      when 'signed_in' then m.account_status='active' and m.deleted_at is null
                      else m.account_status::text=p_status end
    and (v_q='' or lower(concat_ws(' ',m.full_name,m.preferred_name,m.email,m.phone,m.member_code)) like v_pat
         or (v_digit_pat is not null and m.phone like v_digit_pat))
  union all
  select 'roster',null,r.email,null,r.full_name,null,r.phone,r.gender,r.region_id,'not_signed_in',r.added_at
  from public.member_roster r
  where p_status in('current','not_signed_in') and (v_q='' or r.email like v_pat)
 ), scoped as (
  select s.* from students s
  where (v_sa or (v_rc is not null and s.region_id=v_rc)
         or exists(select 1 from public.community_members cm where cm.email=s.email and cm.community_id=any(v_heads)))
    and (p_region is null or s.region_id=p_region)
    and (p_community is null or exists(select 1 from public.community_members cm where cm.email=s.email and cm.community_id=p_community))
 ), page as (
  select * from scoped order by lower(coalesce(full_name,email)),email limit 50 offset p_offset
 )
 select jsonb_build_object('total',(select count(*) from scoped),
  'rows',coalesce((select jsonb_agg(to_jsonb(p)||jsonb_build_object('communities',
    coalesce((select jsonb_agg(cm.community_id order by cm.community_id) from public.community_members cm where cm.email=p.email and not (cm.community_id=any(v_hidden))),'[]'::jsonb))
   order by lower(coalesce(p.full_name,p.email)),p.email) from page p),'[]'::jsonb)) into v_result;
 return v_result;
end; $$;
revoke execute on function public.list_students(text,text,smallint,smallint,integer) from public,anon,service_role;
grant execute on function public.list_students(text,text,smallint,smallint,integer) to authenticated;
