-- Migration 4: pgTAP
-- CLAUDE.md workflow: every RLS policy and privileged function gets SQL tests.
-- Installed by migration because execute_sql is never used for DDL.
-- NOTE: this migration will also run in production when migrations are pushed. pgTAP only
-- adds test functions in the extensions schema (no data, no API surface), but drop this
-- file from the production pipeline if you prefer to keep it dev-only.

create extension if not exists pgtap with schema extensions;
;
