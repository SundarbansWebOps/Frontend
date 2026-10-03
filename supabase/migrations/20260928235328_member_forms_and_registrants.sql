-- Migration 23: member forms, member_private, community registrants, sign-up domain allowlist
-- Spec §7 (forms), §6/§9 (community_registrants_view, Q1), §17 (member_private, Q9), Q7.
--
-- Forms (§7): every submission is keyed on auth.uid() (never a member id from the client),
-- requires an active account, validates answers server-side, and upserts, so resubmitting
-- updates the existing record. A member can withdraw their own community registration.
--
-- member_private (§17): location, stored privately. Only the member and Super Admins can read
-- it; RCs and community admins cannot. Visibility options for Study Buddy come later (Q9).
--
-- get_community_registrants() (§6, §9, Q1): the only way a Head/Co-Head reads registrant
-- contact details: active registrations in their own community, with name, member code,
-- email, phone and region. Super Admins get every community.
--
-- Sign-up domains (Q7, pending decision): private.signup_email_domains. Empty = open sign-up
-- (current behaviour). Adding rows (by migration) restricts sign-up to those domains.

-- ── Answer validation shared by all forms ───────────────────────────────────

create function private.validate_answers(p_answers jsonb)
returns jsonb
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_key text;
  v_val jsonb;
begin
  if p_answers is null or jsonb_typeof(p_answers) <> 'object' then
    raise exception 'Answers must be a JSON object' using errcode = 'invalid_parameter_value';
  end if;
  if octet_length(p_answers::text) > 20000 then
    raise exception 'Answers are too large' using errcode = 'invalid_parameter_value';
  end if;
  if (select count(*) from jsonb_object_keys(p_answers)) > 50 then
    raise exception 'Too many fields' using errcode = 'invalid_parameter_value';
  end if;

  -- Flat forms only: string/number/boolean/null values, or arrays of strings. Keys are plain names.
  for v_key, v_val in select key, value from jsonb_each(p_answers) loop
    if v_key !~ '^[a-z][a-z0-9_]{0,63}$' then
      raise exception 'Invalid field name %', left(v_key, 64) using errcode = 'invalid_parameter_value';
    end if;
    if jsonb_typeof(v_val) = 'string' and length(v_val #>> '{}') > 2000 then
      raise exception 'Field % is too long', v_key using errcode = 'invalid_parameter_value';
    elsif jsonb_typeof(v_val) = 'object' then
      raise exception 'Field % must not be an object', v_key using errcode = 'invalid_parameter_value';
    elsif jsonb_typeof(v_val) = 'array' and exists (
            select 1 from jsonb_array_elements(v_val) e
            where jsonb_typeof(e) <> 'string' or length(e #>> '{}') > 200) then
      raise exception 'Field % must be a list of short texts', v_key using errcode = 'invalid_parameter_value';
    end if;
  end loop;

  return p_answers;
end;
$$;

revoke execute on function private.validate_answers(jsonb) from public, anon, authenticated, service_role;

-- The caller, who must be an active member. Used by every self-service RPC.
create function private.require_active_caller()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not (select private.is_active_member()) then
    raise exception 'Your account is not active' using errcode = 'insufficient_privilege';
  end if;
  return (select auth.uid());
end;
$$;

revoke execute on function private.require_active_caller() from public, anon, authenticated, service_role;

-- ── Forms ───────────────────────────────────────────────────────────────────

create function public.submit_whatsapp_form(p_data jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_active_caller();
begin
  update public.members set whatsapp_data = private.validate_answers(p_data) where id = v_uid;
end;
$$;

comment on function public.submit_whatsapp_form(jsonb) is
  'Member stores their own WhatsApp form (§7). Keyed on auth.uid(); resubmitting replaces it.';

create function public.submit_regional_registration(p_answers jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_active_caller();
  v_id  uuid;
begin
  -- region_id is forced to the member's own region by the regional_registrations trigger.
  insert into public.regional_registrations (member_id, region_id, answers)
  values (v_uid, (select m.region_id from public.members m where m.id = v_uid), private.validate_answers(p_answers))
  on conflict (member_id) do update
    set answers = excluded.answers, status = 'active'
  returning id into v_id;
  return v_id;
end;
$$;

comment on function public.submit_regional_registration(jsonb) is
  'Member submits or updates their regional form (§7). Region always comes from their member record.';

create function public.submit_community_registration(p_community_id smallint, p_answers jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_active_caller();
  v_id  uuid;
begin
  if p_community_id is null or not exists (select 1 from public.communities c where c.id = p_community_id) then
    raise exception 'Community % does not exist', p_community_id using errcode = 'invalid_parameter_value';
  end if;

  insert into public.community_registrations (member_id, community_id, answers)
  values (v_uid, p_community_id, private.validate_answers(p_answers))
  on conflict (member_id, community_id) do update
    set answers = excluded.answers, status = 'active'
  returning id into v_id;
  return v_id;
end;
$$;

comment on function public.submit_community_registration(smallint, jsonb) is
  'Member joins a community or updates their registration (§7). One row per (member, community).';

create function public.withdraw_community_registration(p_community_id smallint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_active_caller();
begin
  update public.community_registrations
     set status = 'withdrawn'
   where member_id = v_uid and community_id = p_community_id and status = 'active';

  if not found then
    raise exception 'You have no active registration in that community' using errcode = 'no_data_found';
  end if;
end;
$$;

comment on function public.withdraw_community_registration(smallint) is
  'Member withdraws their own community registration (§7).';

-- ── member_private ──────────────────────────────────────────────────────────

create table public.member_private (
  member_id  uuid primary key references public.members (id),
  location   text,
  updated_at timestamptz not null default now(),

  constraint member_private_location_length check (location is null or (location = btrim(location) and length(location) between 1 and 200))
);

comment on table public.member_private is
  'Private member data (§17): location. Readable by the member and Super Admins only; never by RCs or community admins.';

create trigger member_private_set_updated_at
  before update on public.member_private
  for each row execute function private.set_updated_at();

alter table public.member_private enable row level security;
revoke all on table public.member_private from public, anon, authenticated, service_role;

create policy member_private_select on public.member_private
  for select to authenticated
  using (
    (member_id = (select auth.uid()) and (select private.is_active_member()))
    or (select private.is_super_admin())
  );

grant select on table public.member_private to authenticated, service_role;

create function public.set_my_location(p_location text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_active_caller();
  v_loc text := nullif(btrim(p_location), '');
begin
  if v_loc is not null and length(v_loc) > 200 then
    raise exception 'Location must be at most 200 characters' using errcode = 'invalid_parameter_value';
  end if;

  insert into public.member_private (member_id, location) values (v_uid, v_loc)
  on conflict (member_id) do update set location = excluded.location;
end;
$$;

comment on function public.set_my_location(text) is 'Member sets or clears their own private location (§17).';

-- ── get_community_registrants ───────────────────────────────────────────────

create function public.get_community_registrants()
returns table (
  registration_id uuid,
  community_id    smallint,
  answers         jsonb,
  registered_at   timestamptz,
  updated_at      timestamptz,
  member_id       uuid,
  member_code     text,
  full_name       text,
  preferred_name  text,
  email           text,
  phone           text,
  region_id       smallint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_is_sa       boolean := (select private.is_super_admin());
  v_communities smallint[] := (select private.my_community_ids());
begin
  if not v_is_sa and cardinality(v_communities) = 0 then
    raise exception 'Only community admins can list registrants' using errcode = 'insufficient_privilege';
  end if;

  return query
  select r.id, r.community_id, r.answers, r.created_at, r.updated_at,
         m.id, m.member_code, m.full_name, m.preferred_name, m.email, m.phone, m.region_id
  from public.community_registrations r
  join public.members m on m.id = r.member_id
  where r.status = 'active'
    and m.account_status <> 'deleted'
    and (v_is_sa or r.community_id = any (v_communities))
  order by r.community_id, m.full_name;
end;
$$;

comment on function public.get_community_registrants() is
  'Registrant contact view (§6, §9, Q1): active registrations of the caller''s community (all for Super Admins).';

-- ── Sign-up domain allowlist (Q7) ───────────────────────────────────────────

create table private.signup_email_domains (
  domain text primary key,
  constraint signup_email_domains_format check (domain = lower(domain) and domain ~ '^[a-z0-9.-]+\.[a-z]{2,}$')
);

comment on table private.signup_email_domains is
  'Allowed sign-up email domains (Q7). Empty = open sign-up. Changed by migration only.';

alter table private.signup_email_domains enable row level security;
revoke all on table private.signup_email_domains from public, anon, authenticated, service_role;

-- Migration 22 version plus the domain allowlist check.
create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_meta      jsonb    := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_email     text     := lower(btrim(new.email));
  v_full_name text     := btrim(v_meta ->> 'full_name');
  v_gender    text     := nullif(btrim(v_meta ->> 'gender'), '');
  v_region_id smallint;
  v_phone     text;
begin
  if v_email is null or v_email = '' then
    raise exception 'An email address is required to sign up'
      using errcode = 'invalid_parameter_value';
  end if;

  if exists (select 1 from private.signup_email_domains)
     and not exists (select 1 from private.signup_email_domains d where d.domain = split_part(v_email, '@', 2)) then
    raise exception 'Sign-up is restricted to approved email domains'
      using errcode = 'insufficient_privilege';
  end if;

  if v_full_name is null or v_full_name = '' then
    raise exception 'full_name is required'
      using errcode = 'invalid_parameter_value';
  end if;

  select r.id into v_region_id
  from public.regions r
  where r.code = lower(btrim(v_meta ->> 'region_code'));

  if v_region_id is null then
    raise exception 'A valid region_code is required'
      using errcode = 'invalid_parameter_value';
  end if;

  v_phone := private.normalise_phone(v_meta ->> 'phone');

  -- Blacklisted people may not register again under the same email or phone (§6, Q11).
  if exists (select 1 from public.blacklist_entries b where b.lifted_at is null) then
    if exists (select 1 from public.blacklist_entries b
               where b.lifted_at is null
                 and (b.email_hash = private.identity_hash('email', v_email)
                      or b.phone_hash = private.identity_hash('phone', v_phone))) then
      raise exception 'Registration is not allowed for this account'
        using errcode = 'insufficient_privilege';
    end if;
  end if;

  insert into public.members (id, member_code, full_name, email, phone, gender, region_id)
  values (new.id, private.member_code_for(v_email), v_full_name, v_email, v_phone, v_gender, v_region_id);

  return new;
end;
$$;

-- ── Grants ──────────────────────────────────────────────────────────────────

revoke execute on function public.submit_whatsapp_form(jsonb)                       from public, anon, service_role;
revoke execute on function public.submit_regional_registration(jsonb)               from public, anon, service_role;
revoke execute on function public.submit_community_registration(smallint, jsonb)    from public, anon, service_role;
revoke execute on function public.withdraw_community_registration(smallint)         from public, anon, service_role;
revoke execute on function public.set_my_location(text)                             from public, anon, service_role;
revoke execute on function public.get_community_registrants()                       from public, anon, service_role;

grant execute on function public.submit_whatsapp_form(jsonb)                       to authenticated;
grant execute on function public.submit_regional_registration(jsonb)               to authenticated;
grant execute on function public.submit_community_registration(smallint, jsonb)    to authenticated;
grant execute on function public.withdraw_community_registration(smallint)         to authenticated;
grant execute on function public.set_my_location(text)                             to authenticated;
grant execute on function public.get_community_registrants()                       to authenticated;
;
