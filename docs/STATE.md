# Sundarbans House — State

> IITM BS frontend/backend · Last checkpoint: 2026-10-19 12:41 IST

## In progress / next

- **Admin Command Desk port — branch `feat/admin-dashboard-port`, worktree `~/Anuraj-dev/Frontend-admin-dashboard`.** Selected prototype A is ported across the overview and admin tabs. Admin uses one top bar with centered Lounge/Website links, Add students, Create, theme and Google avatar; no search field, region chip, Home/Events links, duplicate sidebar identity or Admin footer. Overview uses the Google profile's full name, Kolkata-time greeting and matching morning/afternoon/evening art; no “Whole house” or night greeting. Students see their latest region-request status and review note in Edit profile. Positions show assignment holders by name, member ID, email, assignment date and Google photo when available; initials remain the fallback. Destructive actions use red styling while Restore actions stay neutral. Avatar schema/backfill/sync is in `supabase/migrations/20261019130000_member_google_avatars.sql`; it must be applied to the target Supabase database before remote avatars can load. Local commit: `e1d473d`. Lint, design, source Prettier, build and 36 public-route screenshot checks pass. The signed-in Admin and student flows still need Raja's browser review because no signed-in local browser session is available. **Next:** apply the avatar migration through the intended Supabase workflow, then review `http://localhost:5173/#/admin?tab=positions` while signed in. See `specs/005-admin-lounge-ux.md` and `sessions/2026-10-19.md`.
- **Admin database work.** `supabase/migrations/20261019120000_admin_dashboard_reads.sql` and `supabase/migrations/20261019130000_member_google_avatars.sql` are local source migrations; do not apply to production without an explicit request. Prior port session reported 23 SQL assertions passing for the dashboard-read migration.
- **Legacy Board portraits** — branch `feat/legacy-council-portraits`, separate worktree, uncommitted. Raja to review; 2022 Secretary remains blank pending his confirmed name.
- **Tenure story** — PR #163 is open for review. **Contributors board** — PR is open against upstream `main`. **Resources page** — local work remains uncommitted for Raja's review. See dated session logs.

## Status

- Admin entry is `/#/admin`; shell and panels live in `src/pages/AdminPage.vue` and `src/components/admin/`. Prototype A is in `prototype/admin-dashboards/a-command-desk/`.
- Recent feature work remains local until explicitly delivered. No deployment or external changes are implied by a local build.
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
- Admin profile avatar uses Google's photo when present, with the house crest as fallback.
- Overview only shows metrics supported by current backend data; no invented telemetry.
- No commit, push, PR, deployment or live database migration without explicit authorization.

## Gotchas

- Preserve unrelated changes in every worktree; don't reset or clean.
- The local IAB session has no admin credentials and redirects to `/#/login?next=/admin`; verify in Raja's signed-in browser.
- Vite can retain stale scoped CSS after HMR; use a fresh page load for visual review.
- Mocked browser checks and local SQL tests do not prove live auth or deployed database behavior.
