-- Keep Google-hosted profile photos with the member record so authorized admin views can show them.
alter table public.members
  add column google_avatar_url text
  check (
    google_avatar_url is null
    or (
      length(google_avatar_url) <= 2048
      and google_avatar_url !~ '[[:space:]]'
      and google_avatar_url ~* '^https://([a-z0-9-]+\.)*googleusercontent\.com/'
    )
  );

comment on column public.members.google_avatar_url is
  'Validated Google-hosted profile image URL copied from the account metadata.';

create function private.google_avatar_url(p_metadata jsonb)
returns text
language sql
immutable
set search_path = ''
as $$
  select candidate
  from pg_catalog.unnest(array[p_metadata->>'avatar_url', p_metadata->>'picture']) as urls(candidate)
  where candidate is not null
    and pg_catalog.length(candidate) <= 2048
    and candidate !~ '[[:space:]]'
    and candidate ~* '^https://([a-z0-9-]+\.)*googleusercontent\.com/'
  limit 1
$$;

revoke all on function private.google_avatar_url(jsonb) from public, anon, authenticated, service_role;

-- Existing function behavior remains the source of truth for roster claims and their audit record.
create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_email text := lower(btrim(new.email));
  r public.member_roster;
begin
  if not exists(select 1 from private.signup_email_domains where domain = split_part(v_email, '@', 2)) then
    raise exception 'Sign-up is restricted to approved email domains' using errcode = '42501';
  end if;
  select * into r from public.member_roster where email = v_email for update;
  if not found then
    raise exception 'This email is not on the house roster' using errcode = '42501';
  end if;
  if coalesce(new.raw_app_meta_data->>'provider', '') <> 'google' then
    raise exception 'Use Google sign-in to claim your roster account' using errcode = '42501';
  end if;
  if exists(
    select 1 from public.blacklist_entries b
    where b.lifted_at is null
      and (b.email_hash = private.identity_hash('email', v_email)
        or (r.phone is not null and b.phone_hash = private.identity_hash('phone', r.phone)))
  ) then
    raise exception 'Registration is not allowed for this account' using errcode = '42501';
  end if;
  insert into public.members(
    id, member_code, full_name, email, phone, gender, region_id, cohort, google_avatar_url
  ) values (
    new.id,
    private.member_code_for(v_email),
    r.full_name,
    v_email,
    r.phone,
    r.gender,
    r.region_id,
    upper(substring(split_part(v_email, '@', 1) from '^([0-9]{2}f[123])')),
    private.google_avatar_url(new.raw_user_meta_data)
  );
  delete from public.member_roster where email = v_email;
  perform private.write_audit(
    'roster.claim', 'members', new.id::text, to_jsonb(r),
    jsonb_build_object('member_id', new.id), null, 'success', new.id
  );
  return new;
end;
$$;

revoke execute on function private.handle_new_auth_user() from public, anon, authenticated, service_role;

-- Keep the cached photo in sync when Google refreshes account metadata. The URL helper rejects
-- non-Google hosts and malformed values before they reach any member-facing read model.
create function private.sync_member_google_avatar()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.members
  set google_avatar_url = case
    when coalesce(new.raw_app_meta_data->>'provider', '') = 'google'
      then private.google_avatar_url(new.raw_user_meta_data)
    else null
  end
  where id = new.id;
  return new;
end;
$$;

revoke execute on function private.sync_member_google_avatar() from public, anon, authenticated, service_role;

create trigger sync_member_google_avatar_after_metadata_update
  after update of raw_user_meta_data on auth.users
  for each row
  when (old.raw_user_meta_data is distinct from new.raw_user_meta_data)
  execute function private.sync_member_google_avatar();

-- Existing member rows are backfilled from Auth; member RLS continues to govern who can read them.
update public.members m
set google_avatar_url = case
  when coalesce(u.raw_app_meta_data->>'provider', '') = 'google'
    then private.google_avatar_url(u.raw_user_meta_data)
  else null
end
from auth.users u
where u.id = m.id;
