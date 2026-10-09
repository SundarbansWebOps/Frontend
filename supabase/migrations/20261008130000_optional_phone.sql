-- Phone number is optional (owner, 2026-10-08)
-- A student can be added to the roster, sign in and be managed without a phone number. When one is
-- given it is still checked (international format) and unique. Blacklist entries for someone with
-- no phone have no phone hash, so they are matched by email only.

alter table public.members alter column phone drop not null;
alter table public.member_roster alter column phone drop not null;
alter table public.blacklist_entries alter column phone_hash drop not null;

-- Blank → null; anything else must be a valid international number.
create or replace function private.normalise_phone_optional(p_phone text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case when nullif(btrim(coalesce(p_phone, '')), '') is null then null
              else private.normalise_phone(p_phone) end;
$$;

revoke execute on function private.normalise_phone_optional(text) from public, anon, authenticated;

-- A missing phone has no hash (null), instead of an error. Email stays required.
create or replace function private.identity_hash(p_kind text, p_value text)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_key   text;
  v_value text;
begin
  if p_kind = 'email' then
    v_value := lower(btrim(p_value));
  elsif p_kind = 'phone' then
    v_value := private.normalise_phone_optional(p_value);
    if v_value is null then
      return null;
    end if;
  else
    raise exception 'Unknown identity kind %', p_kind using errcode = 'invalid_parameter_value';
  end if;

  if v_value is null or v_value = '' then
    raise exception 'A % value is required', p_kind using errcode = 'invalid_parameter_value';
  end if;

  select s.decrypted_secret into v_key
  from vault.decrypted_secrets s
  where s.name = 'blacklist_hash_pepper';

  if v_key is null or length(v_key) < 32 then
    raise exception 'Vault secret blacklist_hash_pepper is missing or too short'
      using errcode = 'object_not_in_prerequisite_state';
  end if;

  return encode(extensions.hmac(p_kind || ':' || v_value, v_key, 'sha256'), 'hex');
end;
$$;

-- Roster: phone optional.
create or replace function public.roster_add(
  p_email     text,
  p_full_name text,
  p_phone     text,
  p_region_id smallint default null,
  p_gender    text default null
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sa     boolean  := (select private.is_super_admin());
  v_rc     smallint := (select private.my_rc_region());
  v_email  text     := lower(btrim(coalesce(p_email, '')));
  v_name   text     := btrim(coalesce(p_full_name, ''));
  v_gender text     := nullif(btrim(coalesce(p_gender, '')), '');
  v_region smallint;
  v_phone  text;
  v_row    public.member_roster%rowtype;
begin
  if not v_sa and v_rc is null then
    raise exception 'Only a Regional Coordinator or Super Admin can add students'
      using errcode = 'insufficient_privilege';
  end if;

  if v_sa then
    v_region := p_region_id;
  else
    if p_region_id is not null and p_region_id <> v_rc then
      raise exception 'You can only add students to your own region' using errcode = 'insufficient_privilege';
    end if;
    v_region := v_rc;
  end if;

  if v_region is null or not exists (select 1 from public.regions r where r.id = v_region) then
    raise exception 'Choose a valid region' using errcode = 'invalid_parameter_value';
  end if;

  if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'Enter a valid email address' using errcode = 'invalid_parameter_value';
  end if;

  if exists (select 1 from private.signup_email_domains)
     and not exists (select 1 from private.signup_email_domains d where d.domain = split_part(v_email, '@', 2)) then
    raise exception 'Only IITM student emails (@ds.study.iitm.ac.in) can be added' using errcode = 'invalid_parameter_value';
  end if;

  if length(v_name) not between 1 and 200 then
    raise exception 'Full name is required (up to 200 characters)' using errcode = 'invalid_parameter_value';
  end if;

  if v_gender is not null and length(v_gender) > 50 then
    raise exception 'Gender is too long (up to 50 characters)' using errcode = 'invalid_parameter_value';
  end if;

  v_phone := private.normalise_phone_optional(p_phone);

  if exists (select 1 from public.members m where m.email = v_email) then
    raise exception 'This email already belongs to a member' using errcode = 'unique_violation';
  end if;

  if v_phone is not null and exists (select 1 from public.members m where m.phone = v_phone) then
    raise exception 'This phone number already belongs to a member' using errcode = 'unique_violation';
  end if;

  if exists (select 1 from public.blacklist_entries b
             where b.lifted_at is null
               and (b.email_hash = private.identity_hash('email', v_email)
                    or (v_phone is not null and b.phone_hash = private.identity_hash('phone', v_phone)))) then
    raise exception 'This person cannot be added' using errcode = 'insufficient_privilege';
  end if;

  begin
    insert into public.member_roster (email, full_name, phone, region_id, gender, added_by)
    values (v_email, v_name, v_phone, v_region, v_gender, (select auth.uid()))
    returning * into v_row;
  exception when unique_violation then
    raise exception 'This email or phone number is already on the roster' using errcode = 'unique_violation';
  end;

  perform private.write_audit('roster.add', 'member_roster', v_email, null, to_jsonb(v_row));
  return v_email;
end;
$$;

-- Profile update: phone optional (empty clears it).
create or replace function public.request_member_update(p_member_id uuid, p_changes jsonb, p_reason text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sa     boolean  := (select private.is_super_admin());
  v_member public.members%rowtype;
  v_reason text;
  v_key    text;
  v_val    text;
  v_change jsonb := '{}'::jsonb;
begin
  if not v_sa and (select private.my_rc_region()) is null then
    raise exception 'Only a Regional Coordinator or Super Admin can request profile changes'
      using errcode = 'insufficient_privilege';
  end if;

  v_reason := private.clean_reason(p_reason, true);
  v_member := private.lock_request_target(p_member_id, v_sa);

  if v_member.account_status = 'deleted' then
    raise exception 'Member is deleted; restore them first' using errcode = 'PT409';
  end if;

  if jsonb_typeof(p_changes) is distinct from 'object' then
    raise exception 'changes must be an object' using errcode = 'invalid_parameter_value';
  end if;

  for v_key in select jsonb_object_keys(p_changes) loop
    if v_key not in ('full_name', 'preferred_name', 'gender', 'phone', 'region_id') then
      raise exception 'Field % cannot be changed here', v_key using errcode = 'invalid_parameter_value';
    end if;
  end loop;

  if p_changes ? 'full_name' then
    v_val := btrim(coalesce(p_changes ->> 'full_name', ''));
    if length(v_val) not between 1 and 200 then
      raise exception 'Full name is required (up to 200 characters)' using errcode = 'invalid_parameter_value';
    end if;
    if v_val <> v_member.full_name then v_change := v_change || jsonb_build_object('full_name', v_val); end if;
  end if;

  if p_changes ? 'preferred_name' then
    v_val := nullif(btrim(coalesce(p_changes ->> 'preferred_name', '')), '');
    if v_val is not null and length(v_val) > 100 then
      raise exception 'Preferred name is too long (up to 100 characters)' using errcode = 'invalid_parameter_value';
    end if;
    if v_val is distinct from v_member.preferred_name then
      v_change := v_change || jsonb_build_object('preferred_name', v_val);
    end if;
  end if;

  if p_changes ? 'gender' then
    v_val := nullif(btrim(coalesce(p_changes ->> 'gender', '')), '');
    if v_val is not null and length(v_val) > 50 then
      raise exception 'Gender is too long (up to 50 characters)' using errcode = 'invalid_parameter_value';
    end if;
    if v_val is distinct from v_member.gender then v_change := v_change || jsonb_build_object('gender', v_val); end if;
  end if;

  if p_changes ? 'phone' then
    -- Optional: an empty value clears the phone number.
    v_val := private.normalise_phone_optional(p_changes ->> 'phone');
    if v_val is distinct from v_member.phone then
      if v_val is not null
         and (exists (select 1 from public.members m where m.phone = v_val and m.id <> v_member.id)
              or exists (select 1 from public.member_roster r where r.phone = v_val)) then
        raise exception 'This phone number already belongs to someone else' using errcode = 'unique_violation';
      end if;
      v_change := v_change || jsonb_build_object('phone', v_val);
    end if;
  end if;

  if p_changes ? 'region_id' then
    if not exists (select 1 from public.regions r where r.id = (p_changes ->> 'region_id')::smallint) then
      raise exception 'Choose a valid region' using errcode = 'invalid_parameter_value';
    end if;
    if (p_changes ->> 'region_id')::smallint <> v_member.region_id then
      v_change := v_change || jsonb_build_object('region_id', (p_changes ->> 'region_id')::smallint);
    end if;
  end if;

  if v_change = '{}'::jsonb then
    raise exception 'Nothing to change' using errcode = 'PT409';
  end if;

  return private.insert_request('member_profile_update', p_member_id, v_change, v_reason);
end;
$$;

-- Search: a member without a phone must still be found (null || text would hide them).
create or replace function public.search_members(p_query text, p_include_deleted boolean default false)
returns table(id uuid, member_code text, full_name text, preferred_name text, email text, phone text,
              region_id smallint, account_status public.account_status, score real)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_query       text := btrim(p_query);
  v_needle      text;
  v_pattern     text;
  v_digits      text;
  v_digit_pat   text;
  v_is_sa       boolean := (select private.is_super_admin());
  v_region      smallint := (select private.my_rc_region());
  v_communities smallint[] := (select private.my_community_ids());
begin
  if not v_is_sa and v_region is null and cardinality(v_communities) = 0 then
    raise exception 'Search is not available for your account' using errcode = 'insufficient_privilege';
  end if;

  if v_query is null or length(v_query) < 3 or length(v_query) > 100 then
    raise exception 'Search text must be 3 to 100 characters' using errcode = 'invalid_parameter_value';
  end if;

  -- Literal match only: escape the escape character first, then the wildcards.
  v_needle  := lower(v_query);
  v_pattern := '%' || replace(replace(replace(v_needle, '\', '\\'), '%', '\%'), '_', '\_') || '%';

  -- "+1 202-555 0106" should find +12025550106: also try the digits alone for phone-like input.
  v_digits := regexp_replace(v_query, '[^0-9]', '', 'g');
  if v_query ~ '^[0-9+() .-]+$' and length(v_digits) >= 4 then
    v_digit_pat := '%' || v_digits || '%';
  end if;

  return query
  select m.id, m.member_code, m.full_name, m.preferred_name, m.email, m.phone, m.region_id, m.account_status,
         extensions.similarity(
           lower(m.full_name || ' ' || coalesce(m.preferred_name, '') || ' ' || m.email || ' ' || coalesce(m.phone, '') || ' ' || m.member_code),
           v_needle) as score
  from public.members m
  where (   lower(m.full_name || ' ' || coalesce(m.preferred_name, '') || ' ' || m.email || ' ' || coalesce(m.phone, '') || ' ' || m.member_code)
              like v_pattern
         or (v_digit_pat is not null
             and lower(m.full_name || ' ' || coalesce(m.preferred_name, '') || ' ' || m.email || ' ' || coalesce(m.phone, '') || ' ' || m.member_code)
                   like v_digit_pat))
    and (
          (v_is_sa and (p_include_deleted or m.account_status <> 'deleted'))
       or (not v_is_sa and v_region is not null
           and m.region_id = v_region and m.account_status <> 'deleted')
       or (not v_is_sa and v_region is null and cardinality(v_communities) > 0
           and m.account_status <> 'deleted'
           and exists (select 1 from public.community_registrations r
                       where r.member_id = m.id and r.status = 'active'
                         and r.community_id = any (v_communities)))
        )
  -- By position: "score" alone would be ambiguous with the OUT parameter of the same name.
  order by 9 desc, 3, 1
  limit 50;
end;
$$;
