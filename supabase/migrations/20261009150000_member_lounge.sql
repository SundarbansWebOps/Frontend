-- Confirmed member/profile and scope contracts. Existing two-person admin actions remain intact.
alter table public.members alter column full_name drop not null;
alter table public.members alter column region_id drop not null;
alter table public.member_roster alter column full_name drop not null;
alter table public.member_roster alter column region_id drop not null;
alter table public.members add column tour_seen_at timestamptz;
alter table public.members add column certificate_name text check (certificate_name is null or length(btrim(certificate_name)) between 1 and 200);
alter table public.members add column certificate_name_confirmed_at timestamptz;
alter table public.members add column cohort text check (cohort is null or cohort ~ '^[0-9]{2}F[123]$');
update public.members set cohort = upper(substring(split_part(email, '@', 1) from '^([0-9]{2}f[123])'));
insert into private.signup_email_domains (domain) values ('es.study.iitm.ac.in'),('mg.study.iitm.ac.in'),('ae.study.iitm.ac.in') on conflict do nothing;
insert into public.regions(code,name) values('international','International') on conflict(code) do nothing;

drop index public.admin_assignments_one_active_rc_per_region;
create function private.enforce_rc_limit() returns trigger language plpgsql security definer set search_path='' as $$
begin
  if new.position = 'rc' and new.ended_at is null then
    -- Lock the common region row, rather than individual assignments, to serialize vacant slots.
    perform 1 from public.regions where id=new.region_id for update;
    if exists(select 1 from public.regions where id=new.region_id and code='international') then
      raise exception 'International has no Regional Coordinator' using errcode='22023';
    end if;
    if (select count(*) from public.admin_assignments where position='rc' and ended_at is null and region_id=new.region_id and id<>new.id)>=2 then
      raise exception 'A region may have at most two Regional Coordinators' using errcode='23505';
    end if;
  end if;
  return new;
end; $$;
create trigger admin_assignments_rc_limit before insert or update on public.admin_assignments for each row execute function private.enforce_rc_limit();
-- Retain existing assign_position checks/audit, replacing only its obsolete single-slot check.
do $$ declare body text; begin
 select pg_get_functiondef('public.assign_position(uuid,public.admin_position,smallint)'::regprocedure) into body;
 body:=replace(body,'if v_holder is not null then','if v_holder is not null and (p_position <> ''rc'' or (select count(*) from public.admin_assignments a where a.position = ''rc'' and a.region_id = v_region_id and a.ended_at is null and a.member_id <> p_member_id) >= 2) then');
 execute body;
end $$;

create or replace function public.roster_add(p_email text,p_full_name text,p_phone text,p_region_id smallint default null,p_gender text default null)
returns text language plpgsql security definer set search_path='' as $$
declare v_email text:=lower(btrim(p_email)); v_region smallint:=p_region_id; v_phone text; v_name text:=nullif(btrim(p_full_name),''); v_row public.member_roster;
begin
 if not private.is_super_admin() then
   if private.my_rc_region() is null or (p_region_id is not null and p_region_id<>private.my_rc_region()) then raise exception 'You can only add students to your own region' using errcode='42501'; end if;
   v_region:=private.my_rc_region();
 end if;
 if v_region is not null and not exists(select 1 from public.regions where id=v_region) then raise exception 'Choose a valid region' using errcode='22023'; end if;
 if v_email is null or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' or not exists(select 1 from private.signup_email_domains where domain=split_part(v_email,'@',2)) then raise exception 'Enter an approved IITM student email' using errcode='22023'; end if;
 if length(v_name)>200 or length(p_gender)>50 then raise exception 'Profile field is too long' using errcode='22023'; end if;
 v_phone:=private.normalise_phone_optional(p_phone);
 -- An RC learns only that the email is already known, never which region holds it.
 if exists(select 1 from public.members where email=v_email) or exists(select 1 from public.member_roster where email=v_email) then
   if not private.is_super_admin() then return v_email; end if;
   if p_region_id is not null and (exists(select 1 from public.members where email=v_email and region_id is distinct from p_region_id) or exists(select 1 from public.member_roster where email=v_email and region_id is distinct from p_region_id)) then raise exception 'Existing identity has a conflicting region; additions never overwrite profiles' using errcode='23505'; end if;
   return v_email;
 end if;
 if v_phone is not null and exists(select 1 from public.members where phone=v_phone) then raise exception 'Phone already belongs to another member' using errcode='23505'; end if;
 if exists(select 1 from public.blacklist_entries b where b.lifted_at is null and (b.email_hash=private.identity_hash('email',v_email) or (v_phone is not null and b.phone_hash=private.identity_hash('phone',v_phone)))) then raise exception 'This person cannot be added' using errcode='42501'; end if;
 insert into public.member_roster(email,full_name,phone,region_id,gender,added_by) values(v_email,v_name,v_phone,v_region,nullif(btrim(p_gender),''),auth.uid()) on conflict(email) do nothing returning * into v_row;
 if v_row.email is not null then perform private.write_audit('roster.add','member_roster',v_email,null,to_jsonb(v_row)); end if;
 return v_email;
end; $$;
create or replace function public.roster_add_many(p_rows jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare r jsonb; out_rows jsonb:='[]'; v_email text; existing boolean; category text;
begin
 if not private.is_super_admin() and private.my_rc_region() is null then raise exception 'Only RCs or Super Admins add students' using errcode='42501'; end if;
 if jsonb_typeof(p_rows) is distinct from 'array' or jsonb_array_length(p_rows) not between 1 and 500 then raise exception 'Send between 1 and 500 rows' using errcode='22023'; end if;
 for r in select value from jsonb_array_elements(p_rows) loop
   begin
     if jsonb_typeof(r)<>'object' then raise exception 'Row must be an object' using errcode='22023'; end if;
     v_email:=lower(btrim(r->>'email'));
     existing:=exists(select 1 from public.members where email=v_email) or exists(select 1 from public.member_roster where email=v_email);
     perform public.roster_add(v_email,r->>'full_name',r->>'phone',(r->>'region_id')::smallint,r->>'gender');
     category:=case when existing then 'existing' else 'added' end;
     out_rows:=out_rows||jsonb_build_array(jsonb_build_object('email',v_email,'ok',true,'category',category));
   exception when others then
     out_rows:=out_rows||jsonb_build_array(jsonb_build_object('email',r->>'email','ok',false,'category',case when sqlstate in ('23505','42501') then 'conflict' else 'invalid' end,'error',sqlerrm));
   end;
 end loop;
 return out_rows;
end; $$;
create or replace function private.handle_new_auth_user() returns trigger language plpgsql security definer set search_path='' as $$
declare v_email text:=lower(btrim(new.email)); r public.member_roster;
begin
 if not exists(select 1 from private.signup_email_domains where domain=split_part(v_email,'@',2)) then raise exception 'Sign-up is restricted to approved email domains' using errcode='42501'; end if;
 select * into r from public.member_roster where email=v_email for update;
 if not found then raise exception 'This email is not on the house roster' using errcode='42501'; end if;
 if coalesce(new.raw_app_meta_data->>'provider','')<>'google' then raise exception 'Use Google sign-in to claim your roster account' using errcode='42501'; end if;
 if exists(select 1 from public.blacklist_entries b where b.lifted_at is null and (b.email_hash=private.identity_hash('email',v_email) or (r.phone is not null and b.phone_hash=private.identity_hash('phone',r.phone)))) then raise exception 'Registration is not allowed for this account' using errcode='42501'; end if;
 insert into public.members(id,member_code,full_name,email,phone,gender,region_id,cohort) values(new.id,private.member_code_for(v_email),r.full_name,v_email,r.phone,r.gender,r.region_id,upper(substring(split_part(v_email,'@',1) from '^([0-9]{2}f[123])')));
 delete from public.member_roster where email=v_email;
 perform private.write_audit('roster.claim','members',new.id::text,to_jsonb(r),jsonb_build_object('member_id',new.id),null,'success',new.id);
 return new;
end; $$;
create function public.update_my_profile(p_preferred_name text,p_phone text) returns public.members language plpgsql security definer set search_path='' as $$
declare r public.members; n text:=nullif(btrim(p_preferred_name),''); p text;
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 if length(n)>100 then raise exception 'Name must be at most 100 characters' using errcode='22023'; end if;
 p:=private.normalise_phone_optional(p_phone);
 if p is not null and exists(select 1 from public.member_roster where phone=p) then raise exception 'Phone already belongs to another student' using errcode='23505'; end if;
 update public.members set preferred_name=n,phone=p where id=auth.uid() returning * into r;
 return r;
end; $$;
create function public.set_my_tour_seen(p_seen boolean) returns timestamptz language plpgsql security definer set search_path='' as $$
declare t timestamptz;
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 if p_seen is null then raise exception 'Choose seen or unseen' using errcode='22023'; end if;
 update public.members set tour_seen_at=case when p_seen then coalesce(tour_seen_at,now()) else null end where id=auth.uid() returning tour_seen_at into t; return t;
end; $$;
create function public.select_my_initial_region(p_region_id smallint) returns public.members language plpgsql security definer set search_path='' as $$
declare r public.members;
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 if not exists(select 1 from public.regions where id=p_region_id) then raise exception 'Choose a valid region' using errcode='22023'; end if;
 select * into r from public.members where id=auth.uid() for update;
 if r.region_id is not null then raise exception 'Your region is already set; request a correction' using errcode='PT409'; end if;
 update public.members set region_id=p_region_id where id=auth.uid() returning * into r; return r;
end; $$;
create table public.member_region_requests(
 id uuid primary key default gen_random_uuid(), member_id uuid not null references public.members(id),
 from_region_id smallint not null references public.regions(id), to_region_id smallint not null references public.regions(id),
 reason text not null check(length(btrim(reason)) between 1 and 2000), status text not null default 'pending' check(status in('pending','approved','rejected')),
 requested_at timestamptz not null default now(), reviewed_by uuid references public.members(id), reviewed_at timestamptz, review_note text check(length(review_note)<=2000), check(from_region_id<>to_region_id)
);
create unique index one_pending_region_request on public.member_region_requests(member_id) where status='pending';
alter table public.member_region_requests enable row level security;
revoke all on public.member_region_requests from public,anon,authenticated,service_role;
grant select on public.member_region_requests to authenticated;
create policy member_region_requests_read on public.member_region_requests for select to authenticated using(private.is_active_member() and (member_id=auth.uid() or private.is_super_admin() or from_region_id=private.my_rc_region()));
create function public.request_my_region_change(p_region_id smallint,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare r public.members; rid uuid;
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 select * into r from public.members where id=auth.uid() for update;
 if r.region_id is null then raise exception 'Select your initial region first' using errcode='22023'; end if;
 insert into public.member_region_requests(member_id,from_region_id,to_region_id,reason) values(r.id,r.region_id,p_region_id,private.clean_reason(p_reason,true)) returning id into rid; return rid;
end; $$;
create function public.review_region_change(p_request_id uuid,p_approve boolean,p_note text default null) returns uuid language plpgsql security definer set search_path='' as $$
declare r public.member_region_requests; m public.members;
begin
 select * into r from public.member_region_requests where id=p_request_id for update;
 if not found or not private.is_active_member() or (private.is_super_admin() or r.from_region_id=private.my_rc_region()) is not true or r.member_id=auth.uid() then raise exception 'Only the current-region RC or a Super Admin may review this request' using errcode='42501'; end if;
 if p_approve is null or length(p_note)>2000 then raise exception 'Invalid review' using errcode='22023'; end if;
 if r.status<>'pending' then raise exception 'Request already reviewed' using errcode='PT409'; end if;
 select * into m from public.members where id=r.member_id for update;
 if m.region_id is distinct from r.from_region_id or m.account_status<>'active' then raise exception 'Member region or account has changed; reject or file a new request' using errcode='PT409'; end if;
 if p_approve then
  -- The existing member trigger closes an RC assignment; the legacy region registration follows.
  update public.members set region_id=r.to_region_id where id=r.member_id;
  update public.regional_registrations set region_id=r.to_region_id where member_id=r.member_id;
 end if;
 update public.member_region_requests set status=case when p_approve then 'approved' else 'rejected' end,reviewed_by=auth.uid(),reviewed_at=now(),review_note=nullif(btrim(p_note),'') where id=r.id;
 perform private.write_audit('region_request.review','member_region_requests',r.id::text,to_jsonb(r),jsonb_build_object('approved',p_approve)); return r.id;
end; $$;

-- Public RPCs start closed even on installations with broader inherited default privileges.
revoke execute on function public.update_my_profile(text,text),public.set_my_tour_seen(boolean),public.select_my_initial_region(smallint),public.request_my_region_change(smallint,text),public.review_region_change(uuid,boolean,text) from public,anon,authenticated,service_role;
grant execute on function public.update_my_profile(text,text),public.set_my_tour_seen(boolean),public.select_my_initial_region(smallint),public.request_my_region_change(smallint,text),public.review_region_change(uuid,boolean,text) to authenticated;
revoke execute on function private.enforce_rc_limit() from public,anon,authenticated,service_role;

-- Name and region are now nullable: older `<>` gates and change detection must treat NULL as
-- different (fail closed). Each expected fragment must exist, so a drifted body stops the migration.
do $$ declare p record; body text; fixed text; begin
 for p in select * from (values
  ('private.file_member_request(public.request_type,uuid,text)','v_member.region_id <> v_region','v_member.region_id is distinct from v_region'),
  ('public.request_member_update(uuid,jsonb,text)','if v_val <> v_member.full_name then','if v_val is distinct from v_member.full_name then'),
  ('public.request_member_update(uuid,jsonb,text)','(p_changes ->> ''region_id'')::smallint <> v_member.region_id','(p_changes ->> ''region_id'')::smallint is distinct from v_member.region_id'),
  ('public.approve_request(uuid,text)','(v_change ->> ''region_id'')::smallint <> v_member.region_id','(v_change ->> ''region_id'')::smallint is distinct from v_member.region_id')
 ) t(sig,old_text,new_text) loop
  body:=pg_get_functiondef(p.sig::regprocedure); fixed:=replace(body,p.old_text,p.new_text);
  if fixed=body then raise exception 'Expected fragment not found in %', p.sig; end if;
  execute fixed;
 end loop;
end $$;

-- Search must also find identities whose optional name is missing.
do $$ declare body text; begin
 select pg_get_functiondef('public.search_members(text,boolean)'::regprocedure) into body;
 body:=replace(body,'m.full_name ||', 'coalesce(m.full_name, '''') ||');
 execute body;
end $$;
