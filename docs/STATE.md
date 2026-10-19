# Sundarbans House — State

> IITM BS frontend/backend · Last checkpoint: 2026-10-19 13:04 IST

## In progress / next

- **Admin Command Desk port — branch `feat/admin-dashboard-port`, worktree `~/Anuraj-dev/Frontend-admin-dashboard`.** Prototype A is ported across the overview and admin tabs. The single top bar centers Lounge/Website and keeps Add students, Create, theme, and profile controls; the admin has no search field, region chip, Home/Events links, duplicate sidebar identity, or footer. The overview uses the Google profile's full name, Kolkata-time greeting and morning/afternoon/evening art. Students can see their region-request status and review note. Positions use initials so the page does not depend on the optional Google avatar column. Roster now follows the Students table pattern; form responses open in a full-screen table; notice Delete has been replaced with reversible Publish/Unpublish. The new notice state migration is `supabase/migrations/20261019130300_notice_publishing.sql`; it must be applied to the connected database before the updated Notice page can load its publication state. No migration has been applied. Lint, design, source Prettier, production build and `git diff --check` passed. The signed-in Admin pages still need real-browser review. **Next:** apply the notice migration through the intended Supabase workflow and review `http://localhost:5173/#/admin` while signed in. See `specs/005-admin-lounge-ux.md` and `sessions/2026-10-19.md`.
- **Admin database work.** `supabase/migrations/20261019120000_admin_dashboard_reads.sql`, `supabase/migrations/20261019130000_member_google_avatars.sql`, and `supabase/migrations/20261019130300_notice_publishing.sql` are source migrations; do not apply to production without an explicit request. Prior port session reported 23 SQL assertions passing for the dashboard-read migration.
- **Legacy Board portraits** — branch `feat/legacy-council-portraits`, separate worktree, uncommitted. Raja to review; 2022 Secretary remains blank pending his confirmed name.
- **Tenure story** — PR #163 is open for review. **Contributors board** — PR is open against upstream `main`. **Resources page** — local work remains uncommitted for Raja's review. See dated session logs.

## Status

- Admin entry is `/#/admin`; shell and panels live in `src/pages/AdminPage.vue` and `src/components/admin/`. Prototype A is in `prototype/admin-dashboards/a-command-desk/`.
- Admin changes are committed locally on `feat/admin-dashboard-port`; no push, deployment or external change is implied by a local commit.
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
- Profile avatars are optional; admin member lists must keep working with initials when the database has no Google avatar column.
- Overview only shows metrics supported by current backend data; no invented telemetry.
- No commit, push, PR, deployment or live database migration without explicit authorization.

## Gotchas

- Preserve unrelated changes in every worktree; don't reset or clean.
- The local IAB session has no admin credentials and redirects to `/#/login?next=/admin`; verify in Raja's signed-in browser.
- Vite can retain stale scoped CSS after HMR; use a fresh page load for visual review.
- Mocked browser checks and local SQL tests do not prove live auth or deployed database behavior.
