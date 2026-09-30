-- Migration 3: audit_log
-- Spec §13 (Requests and audit), §5 (only Super Admins read the audit log).
--
-- Append-only: no API role holds UPDATE/DELETE/TRUNCATE, and a trigger blocks those
-- operations for every role, including the table owner.
--
-- RLS is enabled now with NO policies, so the table is unreadable over the API.
-- The Super Admin SELECT policy and the matching grant arrive in migration 8, once
-- is_super_admin() exists.

create table public.audit_log (
  id           bigint generated always as identity primary key,
  created_at   timestamptz not null default now(),
  -- No FK: actors may be the system (null) and the log must never block or cascade.
  actor_id     uuid,
  action       text not null,
  target_table text,
  -- text, because targets have different key types (uuid members, lookup ids, ...).
  target_id    text,
  old_values   jsonb,
  new_values   jsonb,
  -- FK to approval_requests is added in migration 13, when that table exists.
  request_id   uuid,
  result       text not null default 'success',

  constraint audit_log_action_format check (action ~ '^[a-z][a-z0-9_.]{2,63}$'),
  constraint audit_log_result_check  check (result in ('success', 'failure'))
);

comment on table public.audit_log is
  'Append-only audit trail (§13). Written only by triggers and privileged functions via private.write_audit(). Readable only by Super Admins.';

create index audit_log_created_at_idx on public.audit_log (created_at desc);
create index audit_log_target_idx     on public.audit_log (target_table, target_id, created_at desc);
create index audit_log_actor_idx      on public.audit_log (actor_id, created_at desc) where actor_id is not null;
create index audit_log_request_idx    on public.audit_log (request_id) where request_id is not null;

alter table public.audit_log enable row level security;

-- Nobody talks to the table directly. Writes go through private.write_audit();
-- service_role may read (Edge Functions), but may not insert, update, or delete.
revoke all on table public.audit_log from public, anon, authenticated, service_role;
grant select on table public.audit_log to service_role;

-- Append-only enforcement, independent of grants.
create function private.audit_log_block_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'audit_log is append-only: % is not allowed', tg_op
    using errcode = 'insufficient_privilege';
end;
$$;

revoke execute on function private.audit_log_block_mutation() from public, anon, authenticated, service_role;

create trigger audit_log_no_update_delete
  before update or delete on public.audit_log
  for each row execute function private.audit_log_block_mutation();

create trigger audit_log_no_truncate
  before truncate on public.audit_log
  for each statement execute function private.audit_log_block_mutation();

-- The only write path. The actor is always auth.uid() when a user session exists;
-- p_actor_id is honoured only when there is no session (service-role Edge Functions,
-- which pass the caller they verified; or system triggers, which pass null).
create function private.write_audit(
  p_action       text,
  p_target_table text  default null,
  p_target_id    text  default null,
  p_old_values   jsonb default null,
  p_new_values   jsonb default null,
  p_request_id   uuid  default null,
  p_result       text  default 'success',
  p_actor_id     uuid  default null
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id bigint;
begin
  insert into public.audit_log
    (actor_id, action, target_table, target_id, old_values, new_values, request_id, result)
  values
    (coalesce((select auth.uid()), p_actor_id), p_action, p_target_table, p_target_id,
     p_old_values, p_new_values, p_request_id, p_result)
  returning id into v_id;

  return v_id;
end;
$$;

comment on function private.write_audit(text, text, text, jsonb, jsonb, uuid, text, uuid) is
  'Sole write path into audit_log. Called by security definer functions/triggers (owned by postgres) and by Edge Functions via service_role.';

revoke execute on function private.write_audit(text, text, text, jsonb, jsonb, uuid, text, uuid)
  from public, anon, authenticated;
grant execute on function private.write_audit(text, text, text, jsonb, jsonb, uuid, text, uuid)
  to service_role;
;
