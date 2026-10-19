-- Keep notices recoverable: organizers can unpublish and republish within their existing scope.
alter table public.announcements add column published_at timestamptz;
update public.announcements set published_at = created_at;
alter table public.announcements alter column published_at set default now();

drop policy announcements_read on public.announcements;
create policy announcements_read on public.announcements for select to authenticated using(
  (published_at is not null and private.in_audience(region_id,audience_cohorts) and starts_at<=now())
  or private.manages_scope(region_id,community_id)
);

create or replace function public.save_announcement(p_announcement jsonb) returns uuid language plpgsql security definer set search_path='' as $$
declare aid uuid:=coalesce((p_announcement->>'id')::uuid,gen_random_uuid()); r smallint:=(p_announcement->>'region_id')::smallint; c smallint:=(p_announcement->>'community_id')::smallint; oldn public.announcements; cohorts text[];
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 perform pg_advisory_xact_lock(hashtextextended('notice:'||aid::text,0));
 select * into oldn from public.announcements where id=aid for update;
 if private.manages_scope(r,c) is not true or (oldn.id is not null and private.manages_scope(oldn.region_id,oldn.community_id) is not true) then raise exception 'This notice is outside your organizer scope' using errcode='42501'; end if;
 select coalesce(array_agg(value),'{}') into cohorts from jsonb_array_elements_text(coalesce(p_announcement->'audience_cohorts','[]'));
 perform private.validate_audience(cohorts);
 insert into public.announcements as current_notice(id,title,body,link,region_id,starts_at,ends_at,created_by,community_id,audience_cohorts) values(aid,btrim(p_announcement->>'title'),btrim(p_announcement->>'body'),nullif(btrim(p_announcement->>'link'),''),r,coalesce((p_announcement->>'starts_at')::timestamptz,now()),(p_announcement->>'ends_at')::timestamptz,auth.uid(),c,cohorts)
 on conflict(id) do update set community_id=excluded.community_id,audience_cohorts=excluded.audience_cohorts,title=excluded.title,body=excluded.body,link=excluded.link,region_id=excluded.region_id,starts_at=excluded.starts_at,ends_at=excluded.ends_at,published_at=coalesce(current_notice.published_at,now());
 perform private.write_audit('notice.save','announcements',aid::text,null,p_announcement); return aid;
end; $$;

create or replace function public.list_my_notices() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(to_jsonb(a)||jsonb_build_object('read_at',s.read_at,'dismissed_at',s.dismissed_at,'show_banner',a.starts_at>now()-interval '72 hours' and (a.ends_at is null or a.ends_at>now()) and s.dismissed_at is null) order by a.starts_at desc) from public.announcements a left join public.member_notice_states s on s.announcement_id=a.id and s.member_id=auth.uid() where a.published_at is not null and a.starts_at<=now() and private.in_audience(a.region_id,a.audience_cohorts)),'[]');
end; $$;

create or replace function public.set_my_notice_state(p_announcement_id uuid,p_read boolean default true,p_dismiss boolean default false) returns void language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.announcements a where a.id=p_announcement_id and a.published_at is not null and a.starts_at<=now() and private.in_audience(a.region_id,a.audience_cohorts)) then raise exception 'Notice is outside your audience' using errcode='42501'; end if;
 insert into public.member_notice_states(announcement_id,member_id,read_at,dismissed_at) values(p_announcement_id,auth.uid(),case when p_read then now() end,case when p_dismiss then now() end)
 on conflict(announcement_id,member_id) do update set read_at=case when p_read then coalesce(member_notice_states.read_at,now()) else member_notice_states.read_at end,dismissed_at=case when p_dismiss then coalesce(member_notice_states.dismissed_at,now()) else member_notice_states.dismissed_at end;
end; $$;

create function public.set_announcement_published(p_announcement_id uuid,p_published boolean) returns void language plpgsql security definer set search_path='' as $$
declare oldn public.announcements; v_published_at timestamptz;
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 if p_announcement_id is null or p_published is null then raise exception 'Choose a notice and publication state' using errcode='22023'; end if;
 perform pg_advisory_xact_lock(hashtextextended('notice:'||p_announcement_id::text,0));
 select * into oldn from public.announcements where id=p_announcement_id for update;
 if not found then raise exception 'Notice not found' using errcode='P0002'; end if;
 if private.manages_scope(oldn.region_id,oldn.community_id) is not true then raise exception 'This notice is outside your organizer scope' using errcode='42501'; end if;
 v_published_at:=case when p_published then coalesce(oldn.published_at,now()) else null end;
 update public.announcements set published_at=v_published_at where id=oldn.id;
 perform private.write_audit(case when p_published then 'notice.publish' else 'notice.unpublish' end,'announcements',oldn.id::text,to_jsonb(oldn),jsonb_set(to_jsonb(oldn),'{published_at}',coalesce(to_jsonb(v_published_at),'null'::jsonb)));
end; $$;

revoke execute on function public.set_announcement_published(uuid,boolean) from public,anon,authenticated,service_role;
grant execute on function public.set_announcement_published(uuid,boolean) to authenticated;
