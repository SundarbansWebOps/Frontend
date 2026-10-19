# Held migrations

`20261010000000_audit_fixes.sql` was never applied to the live project and must stay out of
`supabase/migrations/` until its remaining fixes are reconciled into a reviewed forward migration.
It recreates `public.soft_delete_event` and replaces `events_select`, which are already defined by
`20261016120000_soft_delete_event_scope.sql` with broader RC draft access. The old migration fails
on the duplicate function and contains a narrower policy that would remove that RC draft access if
forced past the failure.
