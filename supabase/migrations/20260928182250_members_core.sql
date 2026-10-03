-- Migration 6: members and super_admin_allowlist
-- Spec §2 (allowlist keyed by auth user id), §6 (members), §11 (protected fields).
-- Decisions: Q2 (no FK from members.id to auth.users, so hard delete can remove the auth
-- user while keeping the member id), Q8 (phone must be full international / E.164),
-- Q10 (member_code = IITM roll number, else SB######), Q23 (email/phone stay NOT NULL).
--
-- RLS on, no policies yet (phase 2). All API privileges revoked; phase 2 grants SELECT and
-- the safe-column UPDATE list.

-- ── Shared helpers ──────────────────────────────────────────────────────────

-- Generic updated_at maintenance for every table that has the column.
create function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke execute on function private.set_updated_at() from public, anon, authenticated, service_role;

-- Normalise a phone number to E.164. Accepts "+..." or "00..." with spaces, dashes,
-- dots and parentheses; rejects anything without an explicit country code (Q8).
create function private.normalise_phone(p_phone text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  v text := regexp_replace(coalesce(p_phone, ''), '[[:space:]().-]', '', 'g');
begin
  if v ~ '^00[1-9]' then
    v := '+' || substr(v, 3);
  end if;

  if v !~ '^\+[1-9][0-9]{7,14}$' then
    raise exception 'Phone number must be in international format, e.g. +919876543210'
      using errcode = 'invalid_parameter_value';
  end if;

  return v;
end;
$$;

revoke execute on function private.normalise_phone(text) from public, anon, authenticated;
grant execute on function private.normalise_phone(text) to service_role;

-- member_code: the IITM roll number for @ds.study.iitm.ac.in addresses (e.g. 21f3001973),
-- otherwise SB000001, SB000002, ... The roll number is only taken from the IITM domain, so
-- nobody can claim another student's code with 21f3001973@gmail.com. Set once at signup and
-- never derived again, even if the email later changes.
create sequence private.member_code_seq as bigint start with 1;
revoke all on sequence private.member_code_seq from public, anon, authenticated, service_role;

create function private.member_code_for(p_email text)
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  v_local  text := split_part(p_email, '@', 1);
  v_domain text := split_part(p_email, '@', 2);
  v_n      bigint;
begin
  if v_domain = 'ds.study.iitm.ac.in' and v_local ~ '^[0-9]{2}[a-z]{1,2}[0-9]{5,8}$' then
    return v_local;
  end if;

  v_n := nextval('private.member_code_seq');
  return 'SB' || case when v_n < 1000000 then lpad(v_n::text, 6, '0') else v_n::text end;
end;
$$;

revoke execute on function private.member_code_for(text) from public, anon, authenticated, service_role;

-- ── members ─────────────────────────────────────────────────────────────────

create table public.members (
  -- Equals auth.users.id. Deliberately no FK (Q2): hard delete removes the auth user but
  -- keeps this id. The link is created by the auth.users insert trigger (migration 9).
  id             uuid primary key,
  member_code    text not null,

  -- Safe profile fields (editable by the member; column grants in phase 2).
  full_name      text not null,
  preferred_name text,
  gender         text,
  bio            text,

  -- Protected fields (never granted for UPDATE to authenticated).
  email          text not null,
  phone          text not null,
  region_id      smallint not null references public.regions (id),
  whatsapp_data  jsonb,
  account_status public.account_status not null default 'active',

  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  last_login_at  timestamptz,
  deleted_at     timestamptz,

  constraint members_member_code_key    unique (member_code),
  constraint members_email_key          unique (email),
  constraint members_phone_key          unique (phone),
  constraint members_member_code_format check (member_code ~ '^([0-9]{2}[a-z]{1,2}[0-9]{5,8}|SB[0-9]{6,12})$'),
  -- Stored lowercase, so the plain unique constraint is case-insensitive.
  constraint members_email_format       check (email = lower(email) and email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
  constraint members_phone_e164         check (phone ~ '^\+[1-9][0-9]{7,14}$'),
  constraint members_full_name_length   check (full_name = btrim(full_name) and length(full_name) between 1 and 200),
  constraint members_preferred_name_len check (preferred_name is null or length(preferred_name) between 1 and 100),
  constraint members_gender_length      check (gender is null or length(gender) between 1 and 50),
  constraint members_bio_length         check (bio is null or length(bio) <= 2000),
  constraint members_whatsapp_object    check (whatsapp_data is null or (jsonb_typeof(whatsapp_data) = 'object' and octet_length(whatsapp_data::text) <= 20000)),
  -- Soft delete: status 'deleted' and deleted_at always move together.
  constraint members_deleted_consistent check ((account_status = 'deleted') = (deleted_at is not null))
);

comment on table public.members is
  'Central identity record (§6). id = auth.users.id. Role/position/community are NOT stored here (§2).';
comment on column public.members.member_code is
  'IITM roll number for @ds.study.iitm.ac.in signups, otherwise SB######. Immutable after signup.';

create index members_region_id_idx on public.members (region_id);

create trigger members_set_updated_at
  before update on public.members
  for each row execute function private.set_updated_at();

alter table public.members enable row level security;
revoke all on table public.members from public, anon, authenticated, service_role;

-- ── super_admin_allowlist ───────────────────────────────────────────────────

create table public.super_admin_allowlist (
  user_id    uuid primary key references auth.users (id),
  label      text not null,
  created_at timestamptz not null default now(),

  constraint super_admin_allowlist_label_length check (label = btrim(label) and length(label) between 1 and 100)
);

comment on table public.super_admin_allowlist is
  'Super Admins by auth user id (§2). No RLS policies and no API grants by design: changed only by migration.';

alter table public.super_admin_allowlist enable row level security;
revoke all on table public.super_admin_allowlist from public, anon, authenticated, service_role;
;
