-- Head and Co-Head forms go live only when a Super Admin approves (owner, 2026-10-24).
-- * A form in a community's scope (a community form, or one bound to a community event) that is
--   saved by anyone but a Super Admin cannot be published directly: its Head/Co-Head sends a
--   form_publish request, and approving it publishes the form. Forms already live stay live and
--   stay editable; unpublishing one and publishing it again needs a new approval.
-- * While the request is pending the form is frozen, so the Super Admin approves what they saw.
--   The requester cancels the request (cancel_request) to edit it again.
-- * Mirrors event_publish (20261013194628).

alter table public.approval_requests add column target_form_id uuid references public.lounge_forms (id);
create index approval_requests_target_form_idx on public.approval_requests (target_form_id)
  where target_form_id is not null;

-- From 20261023202050, with form_publish and target_form_id.
alter table public.approval_requests drop constraint approval_requests_target_shape;
alter table public.approval_requests add constraint approval_requests_target_shape check (
  (type in ('member_deletion','member_blacklist','member_hard_delete','member_profile_update','member_status_change','position_change','member_contact_change','community_tag_removal')
   and target_registration_id is null and target_event_id is null and target_form_id is null)
  or (type in ('community_record_update','community_record_deletion')
      and target_registration_id is not null and target_event_id is null and target_form_id is null)
  or (type='event_publish' and target_event_id is not null and target_registration_id is null and target_form_id is null)
  or (type='form_publish' and target_form_id is not null and target_registration_id is null and target_event_id is null));

-- One pending request per form; a Head may have several forms waiting at once.
drop index public.approval_requests_one_pending_per_member;
create unique index approval_requests_one_pending_per_member on public.approval_requests (type,target_member_id)
 where status='pending' and target_registration_id is null and target_event_id is null and target_form_id is null
   and type<>'community_tag_removal';
create unique index approval_requests_one_pending_per_form on public.approval_requests (target_form_id)
 where status='pending' and type='form_publish';

-- ── Which forms need approval ───────────────────────────────────────────────

-- manages_scope lets only a Super Admin or that community's Head/Co-Head manage a community-scoped
-- form, so "not a Super Admin" here means a Head or Co-Head.
create function private.form_needs_publish_approval(p_community smallint,p_event uuid) returns boolean language sql stable security definer set search_path='' as $$
 select not private.is_super_admin()
    and (p_community is not null or exists(select 1 from public.events e where e.id=p_event and e.community_id is not null));
$$;
revoke execute on function private.form_needs_publish_approval(smallint,uuid) from public,anon,service_role;
grant execute on function private.form_needs_publish_approval(smallint,uuid) to authenticated;

-- save_lounge_form upserts, so BEFORE INSERT also fires for a save of an existing form; look the
-- stored row up rather than trusting TG_OP. Approval runs as the Super Admin and passes.
create function private.gate_form_publish() returns trigger language plpgsql security definer set search_path='' as $$
declare v_was_published boolean;
begin
 if auth.uid() is null or private.is_super_admin() then return new; end if;
 if exists(select 1 from public.approval_requests r where r.target_form_id=new.id and r.type='form_publish' and r.status='pending') then
  raise exception 'This form is waiting for a Super Admin to publish it; cancel the request to edit it' using errcode='PT409';
 end if;
 if tg_op='UPDATE' then v_was_published:=old.published_at is not null;
 else v_was_published:=exists(select 1 from public.lounge_forms f where f.id=new.id and f.published_at is not null); end if;
 if new.published_at is not null and not v_was_published and private.form_needs_publish_approval(new.community_id,new.event_id) then
  raise exception 'A Super Admin publishes Head and Co-Head forms; send it for approval' using errcode='42501';
 end if;
 return new;
end; $$;
revoke execute on function private.gate_form_publish() from public,anon,authenticated,service_role;
create trigger lounge_forms_gate_publish before insert or update on public.lounge_forms
 for each row execute function private.gate_form_publish();

-- ── Asking and approving ────────────────────────────────────────────────────

create function public.request_form_publish(p_form_id uuid,p_reason text default null) returns uuid language plpgsql security definer set search_path='' as $$
declare
 v_form public.lounge_forms%rowtype;
 v_reason text:=coalesce(private.clean_reason(p_reason,false),'Publish this form');
 v_request public.approval_requests%rowtype;
begin
 select * into v_form from public.lounge_forms where id=p_form_id for update;
 if not found or not private.is_active_member() or not private.manages_form(v_form.id)
    or not private.form_needs_publish_approval(v_form.community_id,v_form.event_id) then
  raise exception 'Only a Head or Co-Head who manages this form can ask to publish it' using errcode='42501';
 end if;
 if v_form.published_at is not null then raise exception 'This form is already published' using errcode='PT409'; end if;
 if v_form.archived_at is not null then raise exception 'Restore this form before publishing it' using errcode='PT409'; end if;
 if v_form.closes_at is not null and v_form.closes_at<=now() then
  raise exception 'This form has already closed; change its closing time first' using errcode='PT409';
 end if;
 begin
  insert into public.approval_requests(type,target_member_id,target_form_id,target_snapshot,requested_change,reason,requested_by)
  values('form_publish',auth.uid(),v_form.id,jsonb_build_object('form',to_jsonb(v_form)),
         jsonb_build_object('form_id',v_form.id,'form_title',v_form.title),v_reason,auth.uid())
  returning * into v_request;
 exception when unique_violation then
  raise exception 'This form is already waiting for approval' using errcode='unique_violation';
 end;
 perform private.write_audit('request.create','approval_requests',v_request.id::text,null,
  jsonb_build_object('type',v_request.type,'form_id',v_form.id,'form_title',v_form.title,'reason',v_reason),v_request.id);
 return v_request.id;
end; $$;
revoke execute on function public.request_form_publish(uuid,text) from public,anon,service_role;
grant execute on function public.request_form_publish(uuid,text) to authenticated;

-- Called by approve_request after its review lock (Super Admin, not their own request, pending).
create function private.approve_form_publish(p_request public.approval_requests,p_note text) returns uuid language plpgsql security definer set search_path='' as $$
declare v_form public.lounge_forms%rowtype;
begin
 select * into v_form from public.lounge_forms where id=p_request.target_form_id for update;
 if not found then raise exception 'The form was removed; reject this request instead' using errcode='PT409'; end if;
 if v_form.published_at is not null then raise exception 'The form is already published; reject this request instead' using errcode='PT409'; end if;
 if v_form.archived_at is not null then raise exception 'The form was archived; reject this request instead' using errcode='PT409'; end if;
 if v_form.closes_at is not null and v_form.closes_at<=now() then
  raise exception 'The form has already closed; reject this request instead' using errcode='PT409';
 end if;
 update public.lounge_forms set published_at=now(),updated_at=now() where id=v_form.id;
 update public.approval_requests
    set status='approved',reviewed_by=auth.uid(),reviewed_at=now(),review_note=p_note,executed_at=now()
  where id=p_request.id;
 perform private.write_audit('request.approve','approval_requests',p_request.id::text,
  jsonb_build_object('form',to_jsonb(v_form)),
  jsonb_build_object('type',p_request.type,'form_id',v_form.id,'form_title',v_form.title,'published',true,'review_note',p_note),
  p_request.id);
 return p_request.id;
end; $$;
revoke execute on function private.approve_form_publish(public.approval_requests,text) from public,anon,authenticated,service_role;

-- Same anchor as the event_publish branch (20261013194628).
do $patch$ declare body text:=pg_get_functiondef('public.approve_request(uuid,text)'::regprocedure); anchor text:='  -- Re-check the target now; things may have changed since the request was filed.'; begin
 if position(anchor in body)=0 then raise exception 'approve_request changed: anchor not found, update this migration'; end if;
 execute replace(body,anchor,
  '  if v_request.type = ''form_publish'' then'||chr(10)||
  '    return private.approve_form_publish(v_request, v_note);'||chr(10)||
  '  end if;'||chr(10)||chr(10)||anchor);
end $patch$;
