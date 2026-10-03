-- Migration 9: auth.users -> members trigger
-- CLAUDE.md: members.id = auth.users.id; a trigger on auth.users insert creates the member row.
-- Spec §6, §7. Decisions: Q7 (email-only login; region set once at signup, then protected),
-- Q8 (international phone), Q10 (member_code).
--
-- raw_user_meta_data is client-controlled. Only full_name, phone, region_code and gender are
-- read from it, and all of them are validated. account_status, member_code and every other
-- protected value are set here, never from metadata.
--
-- If validation fails the whole signup fails (Auth returns "Database error saving new user"),
-- so no auth user can exist without a valid member row.
--
-- Not yet included (later phases): blacklist-hash check at signup (Q11), member_private row
-- (Q9), email-domain restriction (Q7 follow-up).

create function private.handle_new_auth_user()
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
begin
  if v_email is null or v_email = '' then
    raise exception 'An email address is required to sign up'
      using errcode = 'invalid_parameter_value';
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

  insert into public.members (id, member_code, full_name, email, phone, gender, region_id)
  values (
    new.id,
    private.member_code_for(v_email),
    v_full_name,
    v_email,
    private.normalise_phone(v_meta ->> 'phone'),
    v_gender,
    v_region_id
  );

  return new;
end;
$$;

revoke execute on function private.handle_new_auth_user() from public, anon, authenticated, service_role;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_auth_user();
;
