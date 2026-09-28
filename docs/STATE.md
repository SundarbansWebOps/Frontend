# Sundarbans House - State
> IITM BS Sundarbans House frontend and backend work · Last checkpoint: 2026-09-28

## In progress / next
- **The prototype is now the live site in `src/`** (2026-09-28, uncommitted on `feat/prototype-site-delta`). Home = Pat, typeface = Anek Latin, nav light/dark toggle. Next: Raja reviews it in the browser (`npm run dev`), then decides on commit/PR.
- **Old site files are still on disk, unrouted**: `src/views/*` (except `meetups/.../json/`, still imported by `src/lib/house.js`), `src/components/{AppFooter,DailyNotifications,MembersNavbar,PageHero,RegionMeetups}.vue`, `src/components/{community,dashboard,study}/`, `src/composables/`, `src/assets/{style,community,dashboard}.css`, `src/data/{dashboard.json,leaderboard.js,notifications.json}`. Deleting them was blocked by the permission classifier; Raja must approve/perform it. After deletion, move meetup JSON to `src/data/meetups/` and update `src/lib/house.js`.
- Not ported (were on old /study): doubts board, student tools, exam cities, contribute cards. Grade calculator and exam cities show "coming soon" in Resources tools.
- Backend v1 is built and fully tested locally (Supabase stack, 51/51 API checks). Next: owner creates the free cloud Supabase project (region **Mumbai / ap-south-1**), then `supabase link` + `db push` + `functions deploy` per `backend/README.md`. Members' sign-in waits on this.
- Council agenda (certificates, winners, rosters, meetup photos, lounge rooms): `docs/council-questions.md`.

## Status
- Routes (`src/router/index.js`): `/` Pat · `/resources` · `/events` · `/house` · `/teams` · `/lounge` (tour only) · `/login` (sign-in coming soon) · `/verify-certificate` (rethemed, same `public/data/certificates.json` lookup) · 404. Old URLs redirect: `/study`→Resources, `/about`→`/house#story`, `/meetups*`→`/house#regions`, `/community`→`/teams#communities`, `/community/{technical,cultural,esports}`→`/events?wing=`, `/contact`→`/house#contact` (footer), `/dashboard`→`/lounge`.
- Verified 2026-09-28 against the production build: `npm run lint` exit 0, `npm run build` ok, `npm run test:smoke` 19/19 (all routes + redirects, no console errors). Playwright/Chromium checks: every route light at 1366 and dark at 390, no horizontal overflow; theme toggle persists across reload and follows system until chosen; verify found/not-found; course sheet deep link + Back; event sheet open + Back keeps scroll; anchor redirects land on their sections.
- `npm run format:check` fails only on 7 untracked prototype "Current" files (`prototype/resource-hub/Current*.vue`, `LandingCurrent.vue`, `current-flow.js`) — pre-existing, not ported.
- Not verified: real phones/Safari, reduced-motion in a live browser, sustained frame rate, signed-in Chrome profile.
- Home (Pat) ignores the theme by design (Raja, 2026-09-28): the painted scroll looks identical in light and dark; only the nav and the thin footer strip under the scroll follow the theme, as in the prototype. Verified by pixel-diffing light vs dark screenshots at 1366 and 390.

## Architecture map
- Pages -> `src/pages/*Page.vue`; page components -> `src/components/site/`; shell -> `src/App.vue` (TopNav, RouterView, SiteFooter except Home, CourseSheet, toast)
- Shared state -> `src/lib/store.js` (`nav.go(page, anchor)` = router push; course sheet `?course=`), `src/lib/events.js` (`?event=`), `src/lib/house.js`, `src/lib/courses.js` (adapts `src/data/scData_generated.js`), `src/lib/pat.js`, `src/lib/theme.js`
- Snapshots/data -> `src/data/{events.data.js,house.data.js,teams.js}`; Pat plates -> `src/assets/pat/`; tokens -> `src/assets/tokens.css`
- Scroll/anchors/view transitions -> `scrollBehavior` + `beforeResolve` in `src/router/index.js`
- Prototype (Synchrony/Current variants remain here only) -> `prototype/resource-hub/`
- Backend -> `supabase/migrations/20260905000000_init.sql`, `supabase/functions/members-sync/`, `backend/README.md`, `backend/test/api.test.mjs`
- Glossary -> `CONTEXT.md` · Decisions -> `docs/decisions.md` · Conventions -> `docs/conventions.md`

## Stack & run
- Vue 3, vue-router 4 (hash history), Vite 6, static hosting. Backend: Supabase (local CLI + Docker).
- Node: `export PATH=$HOME/.local/share/mise/installs/node/26.8.1/bin:$PATH` (mise shim broken in fresh shells).
- Gates: `npm run format:check`, `npm run lint`, `npm run build`, `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium npm run test:smoke`.
- Backend tests: `supabase db reset && node backend/test/api.test.mjs` with `supabase start` + `functions serve` up.

## Key decisions
- 2026-09-28: Home = Pat; typeface = Anek Latin; prototype mapped one-to-one into `src/`; lounge is a tour, sign-in "coming soon". Details in `docs/decisions.md`.
- Backend v1 = Supabase local-first; free cloud project (Mumbai) next. Roster: Sheet is source of truth; Supabase holds a synced copy.
- Site direction: bespoke motion, warm palette, no green, no lock icons; nav Resources · Events · House · Teams · Lounge.

## Gotchas
- Vue scoped CSS: `:global(.a) .b` compiles to `.a` only. Write `:root[data-theme='dark'] .b` instead.
- Vue scoped styles: a parent class on a child component's root inherits the parent's scoped rules (bit the Lounge rail).
- Overlays that push history must keep vue-router's state: use `router.push({ query, state })` or spread `history.state` (see `PhotoViewer.vue`).
- Ports 5432x belong to another local Supabase project; ours is 5442x. Never stop their containers.
- Do not commit the member roster, OAuth secrets, or function secrets. `supabase/functions/.env` is gitignored; seed data is fake.
- Meetup photos use original Google delivery URLs; rewriting size/flags broke loads. Each retries once, then drops.
- Entry chunk is ~83 KB gzip because the global course sheet pulls course data; lazy-loading it is a possible follow-up.
- The live chatbot runs a separate React app; its backend is built externally.
