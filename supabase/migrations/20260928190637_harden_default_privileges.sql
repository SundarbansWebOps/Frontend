-- Migration 17: harden default privileges in public
-- Found in the phase 4 database review. pg_default_acl for role postgres in schema public
-- grants anon/authenticated/service_role TRUNCATE, REFERENCES, TRIGGER and MAINTAIN
-- (Dxtm) on every table created from now on. TRUNCATE is not subject to RLS, so a future
-- table whose migration forgot "revoke all" could be emptied by anon over the API.
--
-- Every existing table already revokes these explicitly (verified: anon holds no table
-- privilege anywhere). This closes the default so new tables start with nothing and each
-- migration grants exactly what it needs (CLAUDE.md security rules).
--
-- Objects created by supabase_admin (platform-managed) are not affected.

alter default privileges for role postgres in schema public
  revoke truncate, references, trigger, maintain on tables from anon, authenticated, service_role;

alter default privileges for role postgres in schema public
  revoke all on sequences from anon, authenticated, service_role;

alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon, authenticated, service_role;
;
