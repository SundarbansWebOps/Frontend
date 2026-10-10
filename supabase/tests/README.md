Run `bash supabase/tests/run-local.sh` with Docker, Supabase CLI and Python 3 installed.
It starts a disposable project on ports **5452x**, applies the complete migration history,
runs pgTAP and concurrent lock-wait regressions, and removes only that project's containers and volumes. Keep these ports free.
The repo's development stack on 5442x and other projects are untouched.

The runner adds a temporary bootstrap for the cloud-provided `rls_auto_enable()` function:
existing migration 20260928183510 revokes it before 20261001221137 creates it, while fresh
Supabase CLI images do not include it. Historical migration files are not rewritten.
This bootstrap is local testing infrastructure and must not be pushed to production.

Tests create synthetic roster identities, exercise the real Google claim trigger and run
inside transactions that roll back. They do not need real accounts, seed.sql or credentials.
The fixture-only Vault pepper is created inside the rollback transaction. No operational
roster, form submissions, group invitations or certificate recipients are committed here.

`concurrency.py` uses two independent persistent PostgreSQL sessions plus a monitoring query.
It waits until `pg_blocking_pids` confirms the intended row-lock conflict, commits the scope,
region, suspension or publication change, and asserts rejection with no protected write.
It also proves suspended notice writers are rejected. Fixtures are synthetic and removed
afterward; the disposable database and its audit trail are removed by the runner. `psql`
must be on PATH. The script refuses non-loopback database URLs and other project ports.
