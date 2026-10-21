-- House-wide exact-email lookup for admins. Any active Super Admin, Regional Coordinator, Head
-- or Co-Head may ask "does this email exist anywhere in the house?" This deliberately crosses
-- region and community scope, so it takes one exact address, never lists, and always leaves an
-- audit row (member.lookup) because it returns personal data. Because the audit trail is also the
-- meter, one caller is limited to 60 lookups an hour (Super Admins included). Soft-deleted
-- members are invisible to everyone except Super Admins.
create function public.admin_lookup_email(p_email text)
returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_email   text := lower(btrim(coalesce(p_email, '')));
  v_member  public.members;
  v_roster  public.member_roster;
  v_student jsonb;
  v_pending jsonb;
  v_source  text;
  v_uid     uuid := (select auth.uid());
  v_super   boolean;
begin
  -- Each helper checks that the caller is an active member; positions and Super Admin rows
  -- are read live, so a revoked admin loses access on the next call.
  if not private.is_active_member()
     or not (private.is_super_admin() or private.my_rc_region() is not null
             or cardinality(private.my_community_ids()) > 0) then
    raise exception 'Admin access is required' using errcode = '42501';
  end if;
  -- Rate limit: the audit log is the meter (actor index), so a throttled call writes nothing.
  if (select count(*) from public.audit_log l
      where l.actor_id = v_uid and l.action = 'member.lookup'
        and l.created_at > now() - interval '1 hour') >= 60 then
    raise exception 'Too many lookups in the last hour. Try again later.' using errcode = '54000';
  end if;
  v_super := private.is_super_admin();
  if length(v_email) > 320 or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'Enter a full email address' using errcode = '22023';
  end if;

  select * into v_member from public.members m where m.email = v_email;
  select * into v_roster from public.member_roster r where r.email = v_email;

  -- A soft-deleted member reads as not found to everyone but Super Admins, with no fields at all.
  if v_member.id is not null and not v_super
     and (v_member.account_status = 'deleted' or v_member.deleted_at is not null) then
    v_member := null;
    v_roster := null;
  end if;

  if v_member.id is not null then
    select jsonb_build_object(
      'id', v_member.id,
      'email', v_member.email,
      'full_name', v_member.full_name,
      'preferred_name', v_member.preferred_name,
      'roll_number', v_member.member_code,
      'phone', v_member.phone,
      'gender', v_member.gender,
      'region_id', v_member.region_id,
      'region_name', (select r.name from public.regions r where r.id = v_member.region_id),
      'cohort', v_member.cohort,
      'account_status', v_member.account_status,
      'created_at', v_member.created_at,
      'last_login_at', v_member.last_login_at,
      'deleted_at', v_member.deleted_at,
      'is_super_admin', exists (select 1 from public.super_admin_allowlist s where s.user_id = v_member.id),
      'position', (
        select jsonb_build_object(
          'position', a.position,
          'region_id', a.region_id,
          'region_name', (select r.name from public.regions r where r.id = a.region_id),
          'community_id', a.community_id,
          'community_name', (select c.name from public.communities c where c.id = a.community_id),
          'started_at', a.started_at)
        from public.admin_assignments a
        where a.member_id = v_member.id and a.ended_at is null),
      'forms', coalesce((
        select jsonb_agg(jsonb_build_object(
          'response_id', fr.id,
          'form_id', f.id,
          'form_title', f.title,
          'form_kind', f.form_kind,
          'group_label', f.group_label,
          'submitted_at', fr.submitted_at) order by fr.submitted_at desc, fr.id)
        from public.form_responses fr
        join public.lounge_forms f on f.id = fr.form_id
        where fr.member_id = v_member.id), '[]'::jsonb)
    ) into v_student;
  end if;

  if v_roster.email is not null then
    select jsonb_build_object(
      'email', v_roster.email,
      'full_name', v_roster.full_name,
      'phone', v_roster.phone,
      'gender', v_roster.gender,
      'region_id', v_roster.region_id,
      'region_name', (select r.name from public.regions r where r.id = v_roster.region_id),
      'cohort', upper(substring(split_part(v_roster.email, '@', 1) from '^([0-9]{2}f[123])')),
      'account_status', 'pending',
      'added_at', v_roster.added_at,
      'added_by', (
        select jsonb_build_object('id', m.id, 'full_name', m.full_name, 'email', m.email)
        from public.members m where m.id = v_roster.added_by)
    ) into v_pending;
  end if;

  v_source := case when v_student is not null then 'student' when v_pending is not null then 'pending' end;

  perform private.write_audit(
    'member.lookup',
    case when v_student is not null then 'members' when v_pending is not null then 'member_roster' end,
    case when v_student is not null then v_member.id::text when v_pending is not null then v_roster.email end,
    null,
    jsonb_build_object('email', v_email, 'found', v_source is not null, 'source', v_source));

  return jsonb_build_object(
    'found', v_source is not null,
    'source', v_source,
    'student', v_student,
    'pending', v_pending);
end;
$$;

comment on function public.admin_lookup_email(text) is
  'Exact-email lookup across members and the pending roster for any active admin (house-wide). Audited as member.lookup.';

revoke execute on function public.admin_lookup_email(text) from public, anon, service_role;
grant execute on function public.admin_lookup_email(text) to authenticated;
