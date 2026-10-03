-- Migration 13: close advisor finding 0028/0029 on public.rls_auto_enable
-- public.rls_auto_enable() is Supabase's platform function behind the ensure_rls event
-- trigger (auto-enables RLS on new public tables). It is SECURITY DEFINER in the exposed
-- public schema with default PUBLIC EXECUTE, so anon/authenticated can call it via
-- /rest/v1/rpc/rls_auto_enable (verified: the call succeeds, though it does nothing outside
-- a DDL event).
--
-- Event triggers do not check EXECUTE on their function when they fire, so revoking it does
-- not stop RLS auto-enable. We also enable RLS explicitly on every table, so nothing here
-- depends on it.

revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
;
