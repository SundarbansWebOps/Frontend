-- Sundarbans House backend v1
-- Roles, roster-gated membership, and the first dynamic public content:
-- events, meetups, important dates. Lounge content tables come later; the
-- membership gate helper ships now so future lounge tables can use it.

-- ── Enums ────────────────────────────────────────────────────────────────
create type app_role as enum ('web_admin', 'admin', 'regional_coordinator', 'member');
create type content_status as enum ('draft', 'pending_review', 'published');
create type community as enum ('technical', 'cultural', 'esports');
create type date_category as enum ('academic', 'exam', 'event', 'holiday', 'other');

-- ── Tables ───────────────────────────────────────────────────────────────
-- Canonical chapter list, mirrored from the frontend's regionConfigs slugs.
create table public.regions (
  id         uuid primary key default gen_random_uuid(),
  slug       text not null unique,
  name       text not null,
  created_at timestamptz not null default now()
);

-- One row per auth user. Roles: web_admin > admin > regional_coordinator > member.
create table public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  email      text not null unique,
  full_name  text,
  role       app_role not null default 'member',
  region_id  uuid references public.regions (id), -- only for regional_coordinator
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Roster synced FROM the council Google Sheet (the Sheet stays the source of
-- truth). Written only by the members-sync Edge Function (service role) or a
-- web_admin. Never seeded with real people — fixtures only.
create table public.members (
  id                uuid primary key default gen_random_uuid(),
  email             text not null unique, -- lowercased
  full_name         text,
  region            text,
  roll_number       text,
  is_active         boolean not null default true,
  source_updated_at timestamptz,
  synced_at         timestamptz not null default now(),
  created_at        timestamptz not null default now()
);

-- Public events. Dates are ISO timestamptz on purpose: the RAG audit flagged
-- day/month-only records with no year as a P1 trust failure.
create table public.events (
  id               uuid primary key default gen_random_uuid(),
  title            text not null,
  description      text,
  community        community not null,
  starts_at        timestamptz,
  ends_at          timestamptz,
  venue            text,
  registration_url text,
  status           content_status not null default 'draft',
  created_by       uuid references public.profiles (id),
  published_at     timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- Region meetups. A regional_coordinator manages only their own region.
create table public.meetups (
  id             uuid primary key default gen_random_uuid(),
  region_id      uuid not null references public.regions (id),
  meetup_no      integer,
  title          text,
  description    text,
  venue          text,
  starts_at      timestamptz, -- nullable: imported past records may lack dates
  total_students integer,
  collaboration  text,
  social_url     text,
  poster_url     text,
  status         content_status not null default 'draft',
  created_by     uuid references public.profiles (id),
  published_at   timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- Semester-relevant dates the public site highlights.
create table public.important_dates (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  category    date_category not null default 'other',
  starts_on   date not null,
  ends_on     date,
  notes       text,
  status      content_status not null default 'draft',
  created_by  uuid references public.profiles (id),
  published_at timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index events_status_starts_idx on public.events (status, starts_at);
create index meetups_region_status_idx on public.meetups (region_id, status, starts_at);
create index important_dates_status_idx on public.important_dates (status, starts_on);
create index members_email_idx on public.members (email);

-- ── Triggers ─────────────────────────────────────────────────────────────
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger events_set_updated_at before update on public.events
  for each row execute function public.set_updated_at();
create trigger meetups_set_updated_at before update on public.meetups
  for each row execute function public.set_updated_at();
create trigger important_dates_set_updated_at before update on public.important_dates
  for each row execute function public.set_updated_at();

-- Freshness metadata: stamp published_at the moment a row first goes published.
create or replace function public.set_published_at()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'published' and old.status is distinct from 'published' then
    new.published_at = now();
  end if;
  return new;
end;
$$;

create trigger events_set_published_at before update on public.events
  for each row execute function public.set_published_at();
create trigger meetups_set_published_at before update on public.meetups
  for each row execute function public.set_published_at();
create trigger important_dates_set_published_at before update on public.important_dates
  for each row execute function public.set_published_at();

-- Every new auth user gets a profile with the default 'member' role.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    lower(new.email),
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── Role/membership helpers (SECURITY DEFINER: they read tables the caller
--    may not select from, e.g. members) ───────────────────────────────────
create or replace function public.my_role()
returns app_role
language sql
stable
security definer
set search_path = public
as $$
  select p.role from public.profiles p where p.id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select role from public.profiles where id = auth.uid()) in ('web_admin', 'admin'), false);
$$;

create or replace function public.is_web_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select role from public.profiles where id = auth.uid()) = 'web_admin', false);
$$;

create or replace function public.my_region_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select p.region_id from public.profiles p where p.id = auth.uid();
$$;

-- The Lounge gate. A caller is a member when their verified Google email is
-- on the roster (synced from the Sheet) and marked active. Used by every
-- future members-only table policy.
create or replace function public.is_active_member()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.members m
    where m.email = lower(coalesce(auth.jwt() ->> 'email', ''))
      and m.is_active
  );
$$;

-- One-call access snapshot for the frontend: role, lounge membership, and the
-- RC's region slug. Anonymous callers get the public shape.
create or replace function public.my_access()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select jsonb_build_object(
        'role', p.role,
        'is_member', exists (
          select 1 from public.members m
          where m.email = lower(coalesce(auth.jwt() ->> 'email', ''))
            and m.is_active
        ),
        'region_slug', r.slug
      )
      from public.profiles p
      left join public.regions r on r.id = p.region_id
      where p.id = auth.uid()
    ),
    jsonb_build_object('role', 'public', 'is_member', false, 'region_slug', null)
  );
$$;

-- Role and region assignment go through web_admin-only RPCs instead of
-- profile column updates, so no caller can ever promote themselves.
create or replace function public.assign_role(target_user uuid, new_role app_role)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_web_admin() then
    raise exception 'only a web_admin can assign roles' using errcode = 'insufficient_privilege';
  end if;
  update public.profiles set role = new_role where id = target_user;
  if not found then
    raise exception 'no such user: %', target_user;
  end if;
end;
$$;

create or replace function public.assign_region(target_user uuid, new_region_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_web_admin() then
    raise exception 'only a web_admin can assign regions' using errcode = 'insufficient_privilege';
  end if;
  update public.profiles set region_id = new_region_id where id = target_user;
  if not found then
    raise exception 'no such user: %', target_user;
  end if;
end;
$$;

grant execute on function public.my_access() to anon, authenticated;
grant execute on function public.assign_role(uuid, app_role) to authenticated;
grant execute on function public.assign_region(uuid, uuid) to authenticated;

-- ── Row Level Security ───────────────────────────────────────────────────
alter table public.regions enable row level security;
alter table public.profiles enable row level security;
alter table public.members enable row level security;
alter table public.events enable row level security;
alter table public.meetups enable row level security;
alter table public.important_dates enable row level security;

-- regions: the chapter list is public reference data.
create policy regions_read_all on public.regions
  for select using (true);

-- profiles: you can see yourself; admins can see everyone. Nobody updates
-- role/region_id directly — only via assign_role/assign_region.
create policy profiles_read_own_or_admin on public.profiles
  for select using (id = auth.uid() or public.is_admin());
create policy profiles_update_own on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- members: roster is PII. Admin roles may read; web_admin may write. The
-- roster sync itself runs as service_role, which bypasses RLS.
create policy members_read_admin on public.members
  for select using (public.is_admin());
create policy members_write_web_admin on public.members
  for insert with check (public.is_web_admin());
create policy members_update_web_admin on public.members
  for update using (public.is_web_admin()) with check (public.is_web_admin());
create policy members_delete_web_admin on public.members
  for delete using (public.is_web_admin());

-- Content pattern: published rows are world-readable; drafts and
-- pending_review stay with their creator and the admin roles.
create policy events_read on public.events
  for select using (
    status = 'published' or created_by = auth.uid() or public.is_admin()
  );
create policy events_write_admin on public.events
  for insert with check (public.is_admin());
create policy events_update_admin on public.events
  for update using (public.is_admin()) with check (public.is_admin());
create policy events_delete_admin on public.events
  for delete using (public.is_admin());

create policy meetups_read on public.meetups
  for select using (
    status = 'published'
    or created_by = auth.uid()
    or public.is_admin()
    or (public.my_role() = 'regional_coordinator' and region_id = public.my_region_id())
  );
create policy meetups_insert on public.meetups
  for insert with check (
    public.is_admin()
    or (public.my_role() = 'regional_coordinator' and region_id = public.my_region_id())
  );
create policy meetups_update on public.meetups
  for update using (
    public.is_admin()
    or (public.my_role() = 'regional_coordinator' and region_id = public.my_region_id())
  ) with check (
    public.is_admin()
    or (public.my_role() = 'regional_coordinator' and region_id = public.my_region_id())
  );
create policy meetups_delete on public.meetups
  for delete using (
    public.is_admin()
    or (public.my_role() = 'regional_coordinator' and region_id = public.my_region_id())
  );

create policy important_dates_read on public.important_dates
  for select using (
    status = 'published' or created_by = auth.uid() or public.is_admin()
  );
create policy important_dates_write_admin on public.important_dates
  for insert with check (public.is_admin());
create policy important_dates_update_admin on public.important_dates
  for update using (public.is_admin()) with check (public.is_admin());
create policy important_dates_delete_admin on public.important_dates
  for delete using (public.is_admin());
