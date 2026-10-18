-- Notice removal, two ways.
-- 1. A member hides a notice from their own bell (hidden_at). Separate from dismissed_at, which only
--    closes the banner and must keep the notice in the bell.
-- 2. An organizer deletes a notice for everyone. The full row goes into the audit log first, so an
--    accidental delete can be restored by hand from audit_log.old_values.
alter table public.member_notice_states add column hidden_at timestamptz;

create or replace function public.list_my_notices() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(to_jsonb(a)||jsonb_build_object('read_at',s.read_at,'dismissed_at',s.dismissed_at,'show_banner',a.starts_at>now()-interval '72 hours' and (a.ends_at is null or a.ends_at>now()) and s.dismissed_at is null) order by a.starts_at desc) from public.announcements a left join public.member_notice_states s on s.announcement_id=a.id and s.member_id=auth.uid() where a.starts_at<=now() and s.hidden_at is null and private.in_audience(a.region_id,a.audience_cohorts)),'[]');
end; $$;

create function public.hide_my_notice(p_announcement_id uuid) returns void language plpgsql security definer set search_path='' as $$
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 if not exists(select 1 from public.announcements a where a.id=p_announcement_id and a.starts_at<=now() and private.in_audience(a.region_id,a.audience_cohorts)) then raise exception 'Notice is outside your audience' using errcode='42501'; end if;
 insert into public.member_notice_states(announcement_id,member_id,read_at,dismissed_at,hidden_at) values(p_announcement_id,auth.uid(),now(),now(),now())
 on conflict(announcement_id,member_id) do update set read_at=coalesce(member_notice_states.read_at,now()),dismissed_at=coalesce(member_notice_states.dismissed_at,now()),hidden_at=coalesce(member_notice_states.hidden_at,now());
end; $$;

create function public.delete_announcement(p_announcement_id uuid) returns void language plpgsql security definer set search_path='' as $$
declare oldn public.announcements;
begin
 perform pg_advisory_xact_lock(hashtextextended('notice:'||p_announcement_id::text,0));
 select * into oldn from public.announcements where id=p_announcement_id for update;
 if not found or private.manages_scope(oldn.region_id,oldn.community_id) is not true then raise exception 'This notice is outside your organizer scope' using errcode='42501'; end if;
 perform private.write_audit('notice.delete','announcements',oldn.id::text,to_jsonb(oldn),null);
 delete from public.member_notice_states where announcement_id=oldn.id;
 delete from public.announcements where id=oldn.id;
end; $$;

revoke execute on function public.hide_my_notice(uuid),public.delete_announcement(uuid) from public,anon,authenticated,service_role;
grant execute on function public.hide_my_notice(uuid),public.delete_announcement(uuid) to authenticated;
