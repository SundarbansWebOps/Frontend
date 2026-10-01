-- Migration 12b: placeholder public.rls_auto_enable() where Supabase has not created it
-- Migration 13 (20260928183510) revokes EXECUTE on public.rls_auto_enable(), a function Supabase creates
-- on hosted projects for its "auto-enable RLS" feature (behind the ensure_rls event trigger). This file
-- creates a harmless placeholder ONLY when the function is missing; where it exists (as on the cloud
-- project) it does nothing.
--
-- Ordering caveat: it was applied to the cloud after migration 13, so its version is 20261001221137 and
-- it sorts AFTER migration 13 here (the version must match the cloud's history for `db push`). On a fresh
-- local stack without rls_auto_enable, migration 13 can therefore still fail; if it does, copy this file
-- locally to a name that sorts before 20260928183510 for that reset only (never commit the copy).
--
-- The placeholder does nothing, is attached to no event trigger, and migration 13 revokes EXECUTE on
-- it like on the real one. If Supabase later installs its feature, its CREATE OR REPLACE takes over.

do $outer$
begin
  if not exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'rls_auto_enable' and p.pronargs = 0
  ) then
    execute $create$
      create function public.rls_auto_enable()
      returns event_trigger
      language plpgsql
      set search_path = pg_catalog
      as $body$
      begin
        -- Placeholder: see the header of this migration. Every table enables RLS explicitly anyway.
        return;
      end;
      $body$
    $create$;
  end if;
end;
$outer$;
