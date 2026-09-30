# Sundarbans House - State
> IITM BS Sundarbans House frontend and backend work · Last checkpoint: 2026-09-30

## In progress / next
- **The prototype is the live site in `src/`**, committed on `feat/prototype-site-delta` (latest `0a7ea4c`; not pushed, no PR). Next: Raja reviews in the browser (`npm run dev`), then decides on push/PR.
- 2026-09-28 polish, all committed: theme switch ripples out of the nav toggle (copied from Raja's portfolio `ThemeToggle.tsx`); borderless round crest (`src/assets/crest.webp`, `public/favicon.png`, `public/apple-touch-icon.png`, cropped from `~/Downloads/sundarbans.png`); Home Events art sits beside the copy with less bottom space; panel art no longer off-screen on phones.
- Old site deleted; meetup JSON lives in `src/data/meetups/json/`.
- Not ported (were on old /study): doubts board, student tools, exam cities, contribute cards. Grade calculator and exam cities show "coming soon" in Resources tools.
- **Backend = cloud Supabase "Website Backend"** (`bqoejoznqudcyeaebmsm`, org "Sundarbans IITM", Mumbai, Postgres 17), the source of truth since 2026-09-30. Branch `refactor/backend-cloud-source-of-truth` (uncommitted) replaces the old local-only v1 with the cloud's 24 migrations + 3 Edge Functions, pulled read-only; repo is `supabase link`ed; `supabase migration list --linked` = 24/24 in sync. Next: Raja plans the Lounge features, then wire `src/` to the cloud (supabase-js, Google sign-in, `get_my_dashboard`).
- Council agenda (certificates, winners, rosters, meetup photos, lounge rooms): `docs/council-questions.md`.

## Status
- Routes (`src/router/index.js`): `/` Pat · `/resources` · `/events` · `/house` · `/teams` · `/lounge` (tour only) · `/login` (sign-in coming soon) · `/verify-certificate` (rethemed, same `public/data/certificates.json` lookup) · 404. Old URLs redirect: `/study`→Resources, `/about`→`/house#story`, `/meetups*`→`/house#regions`, `/community`→`/teams#communities`, `/community/{technical,cultural,esports}`→`/events?wing=`, `/contact`→`/house#contact` (footer), `/dashboard`→`/lounge`.
- Verified 2026-09-28 against the production build: `npm run lint` exit 0, `npm run build` ok, `npm run test:smoke` 19/19 (all routes + redirects, no console errors). Playwright/Chromium checks: every route light at 1366 and dark at 390, no horizontal overflow; theme toggle persists across reload and follows system until chosen; verify found/not-found; course sheet deep link + Back; event sheet open + Back keeps scroll; anchor redirects land on their sections.
- `npm run format:check` fails only on 7 untracked prototype "Current" files (`prototype/resource-hub/Current*.vue`, `LandingCurrent.vue`, `current-flow.js`) — pre-existing, not ported.
- Theme ripple, crest and Events layout verified in headless Chromium only (frames, screenshots at 1846/1366/1024/390/360); smoke 19/19, lint 0.
- Not verified: real phones/Safari, reduced-motion in a live browser, sustained frame rate, signed-in Chrome profile.
- Home (Pat) ignores the theme by design (Raja, 2026-09-28): the painted scroll looks identical in light and dark; only the nav and the thin footer strip under the scroll follow the theme, as in the prototype. Verified by pixel-diffing light vs dark screenshots at 1366 and 390.

## Architecture map
- Pages -> `src/pages/*Page.vue`; page components -> `src/components/site/`; shell -> `src/App.vue` (TopNav, RouterView, SiteFooter except Home, CourseSheet, toast)
- Shared state -> `src/lib/store.js` (`nav.go(page, anchor)` = router push; course sheet `?course=`), `src/lib/events.js` (`?event=`), `src/lib/house.js`, `src/lib/courses.js` (adapts `src/data/scData_generated.js`), `src/lib/pat.js`, `src/lib/theme.js`
- Snapshots/data -> `src/data/{events.data.js,house.data.js,teams.js}`; Pat plates -> `src/assets/pat/`; tokens -> `src/assets/tokens.css`
- Scroll/anchors/view transitions -> `scrollBehavior` + `beforeResolve` in `src/router/index.js`
- Prototype (Synchrony/Current variants remain here only) -> `prototype/resource-hub/`
- Backend (cloud mirror) -> `supabase/migrations/` (24 files, fetched from cloud), `supabase/functions/{apply-account-status,change-member-contact,hard-delete-member,_shared}`; `src/` does not call it yet
- Glossary -> `CONTEXT.md` · Decisions -> `docs/decisions.md` · Conventions -> `docs/conventions.md`

## Stack & run
- Vue 3, vue-router 4 (hash history), Vite 6, static hosting. Backend: cloud Supabase (Mumbai), linked via CLI.
- Node: `export PATH=$HOME/.local/share/mise/installs/node/26.8.1/bin:$PATH` (mise shim broken in fresh shells).
- Gates: `npm run format:check`, `npm run lint`, `npm run build`, `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium npm run test:smoke`.
- Backend changes: new migration in `supabase/migrations/` -> `supabase db push`; functions -> `supabase functions deploy <name>`. Only with Raja's go-ahead: these write to the live project.

## Key decisions
- 2026-09-28: Home = Pat; typeface = Anek Latin; prototype mapped one-to-one into `src/`; lounge is a tour, sign-in "coming soon". Details in `docs/decisions.md`.
- 2026-09-30: cloud Supabase is the backend source of truth; old repo backend v1 (profiles/meetups/important_dates, members-sync, Apps Script) deleted.
- Site direction: bespoke motion, warm palette, no green, no lock icons; nav Resources · Events · House · Teams · Lounge.

## Gotchas
- Theme ripple (`src/lib/theme.js` + `tokens.css`): a view-transition clip-path circle, 700ms ease-in-out. `html.theme-ripple` pauses colour transitions so the new snapshot is final; keep it if adding colour fades.
- Home phone grid must be `minmax(0, 1fr)`: a bare `1fr` grows to the poster line's ~5900px scroll width and pushes every panel's art off-screen.
- Vue scoped CSS: `:global(.a) .b` compiles to `.a` only. Write `:root[data-theme='dark'] .b` instead.
- Vue scoped styles: a parent class on a child component's root inherits the parent's scoped rules (bit the Lounge rail).
- Overlays that push history must keep vue-router's state: use `router.push({ query, state })` or spread `history.state` (see `PhotoViewer.vue`).
- Ports 5432x belong to another local Supabase project (`supabase_*_backend` containers); `supabase/config.toml` uses 5442x. Never stop their containers.
- Never commit Supabase secret keys, the DB password, or member data. Edge Functions need `ALLOWED_ORIGINS` set as a function secret or browsers get no CORS headers.
- Cloud schema has `events` but no meetups or important dates tables; `src/data/*` and the sample term calendar in `src/lib/courses.js` stay static until tables exist.
- Edge Function comments cite a "spec §10–§16 / Q7" that is not in this repo.
- Meetup photos use original Google delivery URLs; rewriting size/flags broke loads. Each retries once, then drops.
- Entry chunk is ~83 KB gzip because the global course sheet pulls course data; lazy-loading it is a possible follow-up.
- The live chatbot runs a separate React app; its backend is built externally.
