# Sundarbans House — State

> IITM BS frontend/backend · Last checkpoint: 2026-10-19 13:24 IST

## In progress / next

- **Admin Command Desk — branch `feat/admin-dashboard-port`, worktree `~/Anuraj-dev/Frontend-admin-dashboard`.** Prototype A is ported across the overview and admin tabs. The merged top bar centers Lounge/Website and keeps Add students, Create, theme, and profile controls; Admin has no search, region chip, Home/Events links, duplicate sidebar identity, or footer. The overview uses the saved profile name, Kolkata-time greeting, and matching daypart art. Students see their region-request status and review note. Roster follows the Students table pattern; form responses open in a full-screen table; notices use reversible Publish/Unpublish. The profile control now shows a Google photo when available and a marigold initials fallback otherwise. **Next:** review `http://localhost:5173/#/admin` in the signed-in Chrome profile. See `specs/005-admin-lounge-ux.md` and `sessions/2026-10-19.md`.
- **Admin backend rollout.** Remote Website Backend now has migrations `20261019110000_notice_publishing.sql`, `20261019120000_admin_dashboard_reads.sql`, and `20261019130000_member_google_avatars.sql`; `supabase migration list --linked` confirmed all three applied. The dashboard hides unpublished notices, and anonymization clears cached avatars. `20261010000000_audit_fixes.sql` is preserved under `supabase/held-migrations/` and excluded from the active migration set because it conflicts with the live Oct 16 event policy. Add migrations using the workflow in `conventions.md`; port any still-needed held fixes through a separate forward migration.
- **Legacy Board portraits** — branch `feat/legacy-council-portraits`, separate worktree, uncommitted. Raja to review; 2022 Secretary remains blank pending his confirmed name.
- **Tenure story** — PR #163 is open for review. **Contributors board** — PR is open against upstream `main`. **Resources page** — local work remains uncommitted for Raja's review. See dated session logs.

## Status

- Admin entry is `/#/admin`; shell and panels live in `src/pages/AdminPage.vue` and `src/components/admin/`. Prototype A is in `prototype/admin-dashboards/a-command-desk/`.
- Admin changes are committed locally on `feat/admin-dashboard-port`; no push, frontend deployment, or external notification is implied by a local commit. The Supabase schema migrations were applied to the linked Website Backend after a reviewed dry run.
- Older Lounge, Resources, Teams and audit decisions remain in `sessions/` and `decisions.md`; certificates are deferred.

## Architecture map

- Auth, client, router: `src/lib/{auth,auth-profile,supabase}.js`, `src/router/index.js`.
- Admin: `src/pages/AdminPage.vue`, `src/components/admin/`, `src/lib/admin.js`.
- Lounge: `src/lib/lounge.js`, `src/components/lounge/`, `src/pages/{LoungePage,FormPage}.vue`.
- Teams and Legacy: `src/pages/{TeamsPage,LegacyPage,TenureReadPage}.vue`, `src/data/`, `src/assets/legacy/`.
- Public archive: `src/lib/events.js`, `src/data/events.data.js`.

## Stack & run

- Vue 3, vue-router 4, Vite 6, Supabase JS. Node 22 is declared; host currently has Node 26.8.2.
- Run: `npm run dev` · Build: `npm run build` · Design: `npm run check:design` · Lint: `npm run lint`.
- Admin preview: `http://localhost:5173/#/admin`; existing dev server PID 666911. Leave it running for Raja.

## Key decisions

- Admin prototype A remains selected; reuse public design tokens and the shared navigation frame.
- Google profile photos are optional; Admin always has an initials fallback, and anonymization clears the cached photo.
- Keep the old Oct 10 audit migration out of the active Supabase migration directory until its remaining fixes are reconciled; it conflicts with the Oct 16 event scope policy.
- Overview only shows metrics supported by current backend data; no invented telemetry.
- No commit, push, PR, deployment or live database migration without explicit authorization.

## Gotchas

- Preserve unrelated changes in every worktree; don't reset or clean.
- The local IAB session has no admin credentials and redirects to `/#/login?next=/admin`; verify in Raja's signed-in browser.
- Vite can retain stale scoped CSS after HMR; use a fresh page load for visual review.
- The local shadow database diff stops at `20260928183510_revoke_rls_auto_enable_execute.sql` because Supabase's platform `public.rls_auto_enable()` is absent there; remote migrations were verified by the linked project and schema dump.
