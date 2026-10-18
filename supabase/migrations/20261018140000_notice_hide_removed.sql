-- Members must not remove notices; only organizers delete them (delete_announcement).
-- Reverts the member hide added in 20261018120000_notice_delete.sql.
drop function if exists public.hide_my_notice(uuid);

create or replace function public.list_my_notices() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not private.is_active_member() then raise exception 'Account is not active' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(to_jsonb(a)||jsonb_build_object('read_at',s.read_at,'dismissed_at',s.dismissed_at,'show_banner',a.starts_at>now()-interval '72 hours' and (a.ends_at is null or a.ends_at>now()) and s.dismissed_at is null) order by a.starts_at desc) from public.announcements a left join public.member_notice_states s on s.announcement_id=a.id and s.member_id=auth.uid() where a.starts_at<=now() and private.in_audience(a.region_id,a.audience_cohorts)),'[]');
end; $$;

alter table public.member_notice_states drop column if exists hidden_at;
