# Sundarbans House — State
> IITM BS frontend and backend · Last checkpoint: 2026-10-08 15:16

## In progress / next
- **PR #145** (`fix/home-hero-boat-tiger-ground` → `upstream/main`, open, not draft): Lounge boat on the Home river, tiger on a mud bank (`78ed11d`), Resources art shrunk ~4% (`48e16ad`). Next: Raja reviews Home on desktop and phone in a visible window, then merges. No merge done by the agent.
- **Next chat: backend + Google sign-in.** Design agreed (no code yet): the Lounge has **sign-in only, no sign-up**. Accounts are pre-created from the student roster (real full name + roll/code); Google sign-in only logs into an existing account; no seeded account means "not on the roster". Full name field may be removed later (not now). Raja sends details later. Open: roster source, matching key (suggest IITM email), seed users vs link on first sign-in, profile fields/editability, turn off public sign-up (live change, ask first). Requirements: `docs/specs/002-lounge-backend-needs.md`.
- Frontend has no Supabase code yet (`@supabase/supabase-js` not installed). The sign-up trigger needing `full_name`/`phone`/`region_code` is moot if accounts are pre-created.
- Cloud Supabase `Website Backend` (`bqoejoznqudcyeaebmsm`): CLI logged in, repo linked, 31/31 migrations in sync. Google provider/redirect settings in the cloud not verified (no readable API token); check the dashboard. `db push` and function deploys write to the live project: ask first.
- Council: Bengaluru status is not to be changed silently.
- **Admin lounge + real Google sign-in** on `feat/admin-panel-supabase` (spec `docs/specs/003-admin-lounge-and-sign-in.md`). Backend applied to the cloud (roster-only sign-up, two-person rule, RCs manage all events; 53/53 pgTAP in a rolled-back run; phone optional; email changes two-person; security headers in `vercel.json`). Front end: `/login` signs in with Google, `/lounge` and `/admin` are guarded, Lounge profile menu has "Admin lounge" for RCs/Super Admins. Gates: format, lint, design, study, build, Playwright 40/40 (Supabase mocked), shots OK.
- **Before merge:** rename the five `20261008120000/120100/130000/140000/140100_*.sql` migration files to the versions `supabase migration list --linked` shows for `admin_request_types` / `admin_panel_backend` / `optional_phone` / `contact_change_request_type` / `contact_change_two_person` (applied via MCP; versions differ). Then enable the Google provider + redirect URLs + `ALLOWED_ORIGINS` (spec 003, Setup) and test a real Google sign-in.
- **Lounge E port, Raja's review round.** Worktree `/home/raja/Anuraj-dev/Frontend-lounge-port`, branch `feat/lounge-production-entry`, local commits only (not pushed, no PR). Preview http://127.0.0.1:5202/#/login (owned Vite PID 106037).
- Next: Raja reviews House card, sign-in door, boat on Events, and sign-out in real Chrome. Chrome tabs in the background pause animations; verify motion in a visible window.
- Once-only tour seen flag and the rest of spec 002 are pending backend work. Sign-out now ends the Supabase session (this device) and returns to `/login`.
- Backend wiring is separate work: `docs/specs/002-lounge-backend-needs.md`. No backend writes, push, PR, merge, or deployment requested.
- Council change pushed on `fix/council-deputy-secretary` (`bb81c16`); no PR. Do not silently change Bengaluru's status.
- Cloud Supabase `Website Backend` (`bqoejoznqudcyeaebmsm`) is the source of truth; repo mirror in sync. Frontend auth/dashboard integration pending.

## Status
- **Lounge is merged to `main`** (PR #144, `1d45fcd`): sign-in door, welcome tour, Lounge Home/Events, sign-out to `/login`. Still fixtures + local storage; Google auth and once-only tour flag pending backend.
- **Home hero (PR #145):** the Lounge boatman replaces the painted boat and rocks/sinks on the river; the tiger stands on `tiger-bank.webp` and is smaller on phones.
- **Resources panel art (PR #145, `48e16ad`):** `.art` is `width: 96%; max-width: 650px` (was 100% / 680px). Measured: 390px phone 346→332, 1836px desktop 680→650, no horizontal scroll at 360–2560px.
- Gates at `48e16ad`: format:check, lint, check:design, build pass; `test:smoke` 33/33.
- Repo: one worktree, only `main` locally plus this branch. Remotes: `origin` = Anuraj-dev/Frontend (fork), `upstream` = SundarbansWebOps/Frontend (PRs and `main` live here).
- CI: `build-and-smoke` runs format, lint, `check:study`, `check:design`, build, smoke, shots. `scripts/check-design.mjs` exempts `src/components/lounge/`, `LoungePage.vue`, `LoginPage.vue` (own palette, self-hosted Anek Latin for the name fitter, global styles). Bringing the Lounge onto tokens is an open option.
- Archive outside the repo: `~/Anuraj-dev/Sundarbans-prototype/` (all lounge prototypes, old worktrees, `study-utility-salvage/`).

## Architecture map
- Home hero + panels: `src/pages/HomePage.vue` (boat sprite `.boat`, tiger `.stage`/`.bank`, panel art `.art`); plate and boat coords in `src/lib/pat.js`.
- Lounge entry: `src/pages/LoungePage.vue` → `src/components/lounge/App.vue`; `src/pages/LoginPage.vue` (sign-in door).
- House teaser: `src/components/site/LoungeDoor.vue` (teaser and entry modes); room data `src/components/site/lounge-rooms.js`.
- Home ↔ Events transition and boat: `src/components/lounge/tide.js` (switchPage, view transitions), `EventsPage.vue`, `events.css`, `lounge.css` (boat view-transition-name), `home/RiverBoat.vue`.
- Pop-up history: `src/components/lounge/layers.js` (one history entry per open pop-up); dialogs `LoungeDialog.vue`, `ProfileMenu.vue`.
- Public site: pages `src/pages/*Page.vue`, components `src/components/site/`, shared state `src/lib/{store,events,house,courses,pat,theme}.js`, data `src/data/`.
- Router: `src/router/index.js` (hash history; skips the generic view transition for Lounge entry/exit).
- Backend: `supabase/migrations/`, functions `{apply-account-status,change-member-contact,hard-delete-member,_shared}`. No frontend backend calls yet.
- Glossary `CONTEXT.md`; decisions `docs/decisions.md`; conventions `docs/conventions.md`.

## Stack & run
- Vue 3, vue-router 4 (hash history), Vite 6; static hosting; cloud Supabase mirror.
- Node: `export PATH=$HOME/.local/share/mise/installs/node/26.8.1/bin:$PATH` if the mise shim fails.
- Run: `npm run dev -- --host 127.0.0.1 --port 5202 --strictPort` from the repo root. `vite preview` binds `localhost:4173` (not 127.0.0.1).
- Gates: `npm run format:check`, `npm run lint`, `npm run check:design`, `npm run build`, `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium npm run test:smoke` (rebuild before smoke after source edits).
- Backend `supabase db push` / function deploy writes to the live project: only with Raja's explicit go-ahead.

## Key decisions (top 5)
- E is B's painted look plus D's story, with expressive optimized motion. Porting preserves approved source behavior.
- Sign-in cross-dissolves into the lounge; the lounge owns its own arrival. Full log: `docs/decisions.md`.
- Sign-out returns to the sign-in door until a real session exists.
- Home (Pat) ignores theme by design; public nav/footer follow it.
- Cloud schema is authoritative; repo backend mirrors it.

## Gotchas
- Closing a Lounge pop-up from the UI runs `history.back()` asynchronously (`layers.js`). A router push issued right after close is cancelled by that Back. Wait for the popstate first (see `ProfileMenu.signOut`).
- Background or hidden Chrome tabs pause Web Animations. Anything awaiting `animation.finished` (dialog close, view transitions) stalls there. Test motion in a visible window; headless Playwright is fine.
- `e2e/lounge.spec.js` theme-on-art test flaked once; rerun before blaming the change.
- Never stop the ports 5432x containers (other Supabase project); this repo uses 5442x. Never commit keys or member data. Edge functions need `ALLOWED_ORIGINS`.
- Native overlays preserve Vue Router history state; certificate name is the first confirmed name. Fixtures are not issued certificates or member data.
- Home phone grids require `minmax(0,1fr)`; bare `1fr` can stretch to poster width.
- A `max-width` cap on Home panel art only bites above ~1490px viewports (column width is the limit below that). To resize art at every width, change the percentage width too.
- Never commit to `main`; branch first. Design-system hard limits: `src/assets/tokens.css`, `index.html` font link, `scripts/design-baseline.json`, `package.json` deps (see `.agents/skills/sundarbans-design/SKILL.md`).
