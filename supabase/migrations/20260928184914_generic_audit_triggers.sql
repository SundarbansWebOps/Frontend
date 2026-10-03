-- Migration 16: generic row-change audit triggers
-- Spec §13 (logged actions), §3, §8. Decisions: one reusable trigger function; attached now
-- to members (protected fields only) and admin_assignments (every change); attached to
-- events when the events table is built (§8 phase).
--
-- These triggers log at the table level, so changes are audited whatever path made them
-- (RPC, Edge Function via service_role, or a migration). RPCs still write their own
-- higher-level entries (position.assign, request.approve, ...) with the business context.
--
-- Usage: execute function private.audit_row_change('col_a', 'col_b', ...)
--   With column names, an UPDATE is logged only when one of them changed, and only those
--   columns go into old_values/new_values. With no arguments, every column is compared.
--   INSERT and DELETE log the full row. Action = '<table>.<insert|update|delete>'.
--   The actor is auth.uid() (null for system changes), via private.write_audit().

create function private.audit_row_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old     jsonb := case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end;
  v_new     jsonb := case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end;
  v_id      text  := coalesce(v_new ->> 'id', v_old ->> 'id');
  v_changed text[];
begin
  if tg_op = 'UPDATE' then
    select array_agg(k order by k) into v_changed
    from jsonb_object_keys(v_new) as k
    where (tg_nargs = 0 or k = any (tg_argv))
      and v_old -> k is distinct from v_new -> k;

    if v_changed is null then
      return null;
    end if;

    select jsonb_object_agg(k, v_old -> k), jsonb_object_agg(k, v_new -> k)
      into v_old, v_new
    from unnest(v_changed) as k;
  end if;

  perform private.write_audit(
    tg_table_name || '.' || lower(tg_op),
    tg_table_name,
    v_id,
    v_old,
    v_new);

  return null;
end;
$$;

comment on function private.audit_row_change() is
  'Generic AFTER ROW audit trigger (§13). Optional TG_ARGV = columns to watch on UPDATE.';

revoke execute on function private.audit_row_change() from public, anon, authenticated, service_role;

-- members: protected fields only (§11, §13): email, phone, region, account status, deletion.
-- Safe profile edits (name, bio, ...) are not logged. Signup inserts are not logged here.
create trigger members_audit_protected
  after update of email, phone, region_id, account_status, deleted_at on public.members
  for each row
  execute function private.audit_row_change('email', 'phone', 'region_id', 'account_status', 'deleted_at');

-- admin_assignments: every change (§3, §13).
create trigger admin_assignments_audit
  after insert or update or delete on public.admin_assignments
  for each row
  execute function private.audit_row_change();
;
