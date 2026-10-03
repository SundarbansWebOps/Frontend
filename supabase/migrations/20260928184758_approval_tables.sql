-- Migration 14: approval_requests and blacklist_entries
-- Spec §10 (approval workflows), §13 (approval_requests), §6 (blacklist_entries), §5, §14.
--
-- Both tables are written ONLY by the security definer RPCs in migration 15 (and later by
-- Edge Functions). No API role gets INSERT/UPDATE/DELETE. Requests are never deleted, which
-- a trigger enforces even for the table owner, and they keep target_snapshot, taken at
-- request time, so history survives later changes (§10, §13).
--
-- Decisions: target_snapshot is taken at request time (§13); approval writes the row state
-- just before the change into audit_log old_values. Blacklist hashes are HMAC-SHA256 with a
-- secret pepper from Supabase Vault (migration 15).

-- ── approval_requests ───────────────────────────────────────────────────────

create table public.approval_requests (
  id                     uuid primary key default gen_random_uuid(),
  type                   public.request_type   not null,
  status                 public.request_status not null default 'pending',

  -- References are never cascaded away (§13). Member rows are soft/anonymised, never removed.
  target_member_id       uuid not null references public.members (id),
  target_registration_id uuid references public.community_registrations (id),

  requested_change       jsonb not null default '{}'::jsonb,
  target_snapshot        jsonb not null,
  reason                 text  not null,

  requested_by           uuid not null references public.members (id),
  requested_at           timestamptz not null default now(),

  -- Decision. For a cancellation, reviewed_by is the requester who cancelled.
  reviewed_by            uuid references public.members (id),
  reviewed_at            timestamptz,
  review_note            text,
  executed_at            timestamptz,

  -- Member requests target a member only; community requests target one registration
  -- (target_member_id is then the registrant, kept for history and search).
  constraint approval_requests_target_shape check (
    (type in ('member_deletion', 'member_blacklist', 'member_hard_delete') and target_registration_id is null)
    or (type in ('community_record_update', 'community_record_deletion') and target_registration_id is not null)
  ),
  -- Lifecycle consistency. The last two branches also make "a Super Admin cannot approve or
  -- reject their own request" (§10) a table rule, not just a function check.
  constraint approval_requests_lifecycle check (
    (status = 'pending'   and reviewed_by is null and reviewed_at is null and executed_at is null)
    or (status = 'approved'  and reviewed_by is not null and reviewed_at is not null and executed_at is not null
                             and reviewed_by <> requested_by)
    or (status = 'rejected'  and reviewed_by is not null and reviewed_at is not null and executed_at is null
                             and reviewed_by <> requested_by)
    or (status = 'cancelled' and reviewed_by = requested_by and reviewed_at is not null and executed_at is null)
  ),
  constraint approval_requests_reason_length check (reason = btrim(reason) and length(reason) between 1 and 2000),
  constraint approval_requests_note_length   check (review_note is null or length(review_note) <= 2000),
  constraint approval_requests_change_object check (
    jsonb_typeof(requested_change) = 'object' and octet_length(requested_change::text) <= 25000
  ),
  constraint approval_requests_snapshot_object check (jsonb_typeof(target_snapshot) = 'object')
);

comment on table public.approval_requests is
  'Admin requests awaiting Super Admin review (§10, §13). Written only by request/approve/reject/cancel RPCs. Never deleted.';
comment on column public.approval_requests.target_snapshot is
  'Copy of the target taken when the request was filed. Never changed afterwards.';

-- Only one pending request of the same type per target (§10).
create unique index approval_requests_one_pending_per_member
  on public.approval_requests (type, target_member_id)
  where status = 'pending' and target_registration_id is null;

create unique index approval_requests_one_pending_per_registration
  on public.approval_requests (type, target_registration_id)
  where status = 'pending' and target_registration_id is not null;

create index approval_requests_queue_idx        on public.approval_requests (status, requested_at desc);
create index approval_requests_requested_by_idx on public.approval_requests (requested_by, requested_at desc);
create index approval_requests_target_member_idx on public.approval_requests (target_member_id);
create index approval_requests_target_reg_idx   on public.approval_requests (target_registration_id) where target_registration_id is not null;
create index approval_requests_reviewed_by_idx  on public.approval_requests (reviewed_by) where reviewed_by is not null;

-- Requests are never deleted (§10), whoever asks.
create function private.approval_requests_block_delete()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'approval_requests are never deleted: % is not allowed', tg_op
    using errcode = 'insufficient_privilege';
end;
$$;

revoke execute on function private.approval_requests_block_delete() from public, anon, authenticated, service_role;

create trigger approval_requests_no_delete
  before delete on public.approval_requests
  for each row execute function private.approval_requests_block_delete();

create trigger approval_requests_no_truncate
  before truncate on public.approval_requests
  for each statement execute function private.approval_requests_block_delete();

-- audit_log.request_id now has a table to point at (placeholder from migration 3).
alter table public.audit_log
  add constraint audit_log_request_id_fkey
  foreign key (request_id) references public.approval_requests (id);

-- ── blacklist_entries ───────────────────────────────────────────────────────

create table public.blacklist_entries (
  id          uuid primary key default gen_random_uuid(),
  member_id   uuid not null references public.members (id),
  -- HMAC-SHA256 (hex) of the normalised email / E.164 phone. Kept after hard delete so a
  -- blacklisted person re-registering can be detected (§6, §15).
  email_hash  text not null,
  phone_hash  text not null,
  reason      text not null,
  -- Null when a Super Admin blacklists directly (§10).
  request_id  uuid references public.approval_requests (id),
  created_by  uuid not null references public.members (id),
  created_at  timestamptz not null default now(),
  lifted_by   uuid references public.members (id),
  lifted_at   timestamptz,

  constraint blacklist_entries_hash_format check (email_hash ~ '^[0-9a-f]{64}$' and phone_hash ~ '^[0-9a-f]{64}$'),
  constraint blacklist_entries_reason_length check (reason = btrim(reason) and length(reason) between 1 and 2000),
  constraint blacklist_entries_lift_consistent check ((lifted_by is null) = (lifted_at is null)),
  constraint blacklist_entries_lift_after check (lifted_at is null or lifted_at >= created_at)
);

comment on table public.blacklist_entries is
  'Blacklist history with identity hashes (§6, §10). Active = lifted_at is null. Super Admin read only.';

-- At most one active blacklist entry per member; history rows stay.
create unique index blacklist_entries_one_active_per_member
  on public.blacklist_entries (member_id)
  where lifted_at is null;

-- Re-registration checks look up active entries by hash.
create index blacklist_entries_email_hash_idx on public.blacklist_entries (email_hash) where lifted_at is null;
create index blacklist_entries_phone_hash_idx on public.blacklist_entries (phone_hash) where lifted_at is null;
create index blacklist_entries_request_id_idx on public.blacklist_entries (request_id) where request_id is not null;
create index blacklist_entries_created_by_idx on public.blacklist_entries (created_by);
create index blacklist_entries_lifted_by_idx  on public.blacklist_entries (lifted_by) where lifted_by is not null;

-- ── RLS and grants ──────────────────────────────────────────────────────────

alter table public.approval_requests enable row level security;
alter table public.blacklist_entries enable row level security;

revoke all on table public.approval_requests, public.blacklist_entries
  from public, anon, authenticated, service_role;

-- Requester sees their own requests (to track and cancel them) | Super Admin: all.
create policy approval_requests_select on public.approval_requests
  for select to authenticated
  using (
    (requested_by = (select auth.uid()) and (select private.is_active_member()))
    or (select private.is_super_admin())
  );

-- Super Admin only. RCs and community admins never see blacklist hashes or reasons.
create policy blacklist_entries_select on public.blacklist_entries
  for select to authenticated
  using ((select private.is_super_admin()));

grant select on table public.approval_requests, public.blacklist_entries to authenticated, service_role;
;
