# Sundarbans House — State

> IITM BS frontend/backend · Last checkpoint: 2026-10-19 14:44 IST

## In progress / next

- **Admin Command Desk — PR #204 (`feat/admin-dashboard-port`, worktree `~/Anuraj-dev/Frontend-admin-dashboard`).** Prototype A is ported across the overview and admin tabs. Admin, public, and Lounge navbars use the full viewport with responsive edge padding; brand is left, links centered, and actions right. The public subtitle is “IIT Madras BS”; phone tab bars remain. Production Admin art is on Cloudinary under `sundarbans/admin-command-desk/`. **Next:** Raja reviews signed-in Admin/Lounge in Chrome and merges the PR. Throwaway prototype assets remain local. See https://github.com/SundarbansWebOps/SundarbansWeb/pull/204.
- **Admin backend rollout.** Remote Website Backend now has migrations `20261019110000_notice_publishing.sql`, `20261019120000_admin_dashboard_reads.sql`, and `20261019130000_member_google_avatars.sql`; `supabase migration list --linked` confirmed all three applied. The dashboard hides unpublished notices, and anonymization clears cached avatars. `20261010000000_audit_fixes.sql` is preserved under `supabase/held-migrations/` and excluded from the active migration set because it conflicts with the live Oct 16 event policy. Add migrations using the workflow in `conventions.md`; port any still-needed held fixes through a separate forward migration.
- **Legacy Board portraits** — branch `feat/legacy-council-portraits`, separate worktree, uncommitted. Raja to review; 2022 Secretary remains blank pending his confirmed name.
- **Tenure story** — PR #163 is open for review. **Contributors board** — PR is open against upstream `main`. **Resources page** — local work remains uncommitted for Raja's review. See dated session logs.

## Status

- Admin entry is `/#/admin`; shell and panels live in `src/pages/AdminPage.vue` and `src/components/admin/`. Prototype A is in `prototype/admin-dashboards/a-command-desk/`.
- Admin Command Desk is on `feat/admin-dashboard-port` as PR #204 against upstream `main`. Production Admin art is on Cloudinary. Design, formatting, lint, build, screenshot, and whitespace checks pass. Signed-in Admin/Lounge remain unverified. The Supabase schema migrations were already applied to the linked Website Backend; no migration was rerun.
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
- Admin preview: `http://localhost:5173/#/admin`; Vite server PID 22789 from the Admin dashboard worktree. Leave it running for Raja.

## Key decisions

- Admin prototype A remains selected; reuse public design tokens and the shared navigation frame.
- Admin profile matches Lounge's avatar treatment: use a Google photo when available, otherwise the circular Sundarbans crest; member Google photos remain optional, and anonymization clears cached photos.
- Keep the old Oct 10 audit migration out of the active Supabase migration directory until its remaining fixes are reconciled; it conflicts with the Oct 16 event scope policy.
- Overview only shows metrics supported by current backend data; no invented telemetry.
- No commit, push, PR, deployment or live database migration without explicit authorization.

## Gotchas

- Preserve unrelated changes in every worktree; don't reset or clean.
- The local IAB session has no admin credentials and redirects to sign-in for Admin and Lounge; verify those signed-in views in Raja's browser.
- Vite can retain stale scoped CSS after HMR; use a fresh page load for visual review.
- Keep `padding: 0` on the Admin avatar button so its image fills the circle like Lounge's profile button.
- The local shadow database diff stops at `20260928183510_revoke_rls_auto_enable_execute.sql` because Supabase's platform `public.rls_auto_enable()` is absent there; remote migrations were verified by the linked project and schema dump.
