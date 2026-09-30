-- Migration 1: extensions and private schema
-- Spec §12 (trigram search), §14 (privileged helpers are not exposed through the Data API).
--
-- pg_net (Q13) is deliberately NOT installed here; it arrives with the auth-sync hook
-- (migration 15) so the database cannot make outbound HTTP calls before it needs to.

create extension if not exists pg_trgm with schema extensions;

-- Internal helpers (audit writer, phone normaliser, hashing, anonymisation) live here.
-- This schema must never be added to the Data API's exposed schemas, so nothing in it
-- is reachable over REST/RPC. EXECUTE is still granted per function, never by default.
create schema if not exists private;

comment on schema private is
  'Internal helpers for the Members Lounge. Not exposed via the Data API. EXECUTE is granted per function.';

revoke all on schema private from public;

-- authenticated needs USAGE so RLS policies can call helper functions in this schema;
-- service_role needs it for Edge Functions. anon gets nothing.
grant usage on schema private to authenticated, service_role;
;
