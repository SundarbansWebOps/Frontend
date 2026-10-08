# Sundarbans House — State
> IITM BS frontend and backend · Last checkpoint: 2026-10-08

## In progress / next
- **Lounge E 1:1 port complete, ready for Raja's review.** Worktree `/home/raja/Anuraj-dev/Frontend-lounge-port`, branch `feat/lounge-production-entry`, committed in focused steps. Preview http://127.0.0.1:5202/#/login, owned detached Vite PID 106037. Main checkout `src/` is unchanged; port implementation lives in the worktree. Evidence/scope: `docs/reports/2026-10-08-lounge-port.md`.
- E remains fixture/local-storage backed. Backend wiring is separate work; requirements: `docs/specs/002-lounge-backend-needs.md`. Local sequential commits authorized; no backend writes, push, PR, merge, or deployment requested.
- Council change pushed on `fix/council-deputy-secretary` (`bb81c16`, council worktree; based on `origin/feat/prototype-site-delta`): Ansh Kumar is Deputy Secretary, Lucknow recruiting. No PR yet; base on `feat/prototype-site-delta`. Do not silently change Bengaluru's status.
- Public prototype site previously ported on pushed `feat/prototype-site-delta` (`be81d55`); no PR. Backend mirror on `refactor/backend-cloud-source-of-truth` (`c6d42cd` + `c29902d`).

## Status
- **Sign-in restored (Raja’s follow-up):** centered original swinging door + Sign in; site navbar/mobile tabs restored on `/login` per Raja’s correction, no Lounge preview/footer. Public Lounge links open `/login`; Sign in fades out 900ms, Tour fades in 900ms, then existing Tour→Lounge handoff. Every explicit sign-in resets the local tour flag for now; Google auth/backend once-only gating pending. Direct `/lounge` revisits retain the existing storage behavior. New `e2e/sign-in.spec.js`; fresh production suite32/32, build/lint/format/diff exit0, detector no findings; real Chrome desktop/phone and Sign in→Tour→Lounge verified. Final committed production code: fresh32/32 tests and build/lint/format/diff exit0.
- Port gates: build/lint/format/diff check exit 0; production smoke/regressions 28/28; six desktop/phone/day/night/reduced interaction scenarios pass; production Tour chapters, focus/scroll lock, naming/handoff and runtime reduced-motion gates pass. Known/missing certificate query IDs pass. Real Chrome Tour→Home/Events and 390px Events/theme inspected.
- Parity: 3,889 CSS declarations across 23 style blocks match E after asset-path/font-alias normalization. 24 source/port screenshots have identical measured geometry/type sizes/colors; pixel differences above RGB threshold 12 ≤0.0131%. Source E and its port5200 server preserved.
- Approved E source: `/home/raja/Anuraj-dev/Frontend-lounge-e/prototype/lounge-e`, branch `feat/lounge-b-story`. Read `_notes/{codex-takeover,motion,tour}.md` for history. Round10: B arrival and sun/moon circle, staggered fleet, single scrim on dialog hand-over, original E Events band, smaller Tour clouds. Round11: real rotateY turn, Home mud bank, night Tour island/council/ghat lamps and masked light layers. All retained.
- Sol high review findings resolved: accepted case/slash Lounge URLs, stale name-card remount, pending transition teardown, and registration/race test coverage. Font face has a Lounge-only alias using the same bytes. Source Sign out and slim Live row proposal were not expanded; strict 1:1 scope.
- Lounge D remains on hold in `/home/raja/Anuraj-dev/Frontend-lounge-d`, branch `feat/lounge-arrival-prototype`, prototype uncommitted. Port5199 PID982929 is not ours; never kill it. Auto-row remains 67.2s desktop/85.2s phone in E; full timed run not repeated this session.
- Lounge A/D production previews: https://sundarbans-lounge-a.vercel.app · https://sundarbans-lounge-d.vercel.app (2026-10-07, separate Vercel projects). No E/port deployment.
- Main public routes: `/` Pat, `/resources`, `/events`, `/house`, `/teams`, `/lounge`, `/login`, `/verify-certificate`, 404; old URLs redirect. Main checkout still has the earlier Lounge preview; the port replaces it only in the port worktree.
- Cloud Supabase `Website Backend` (`bqoejoznqudcyeaebmsm`, Mumbai/Postgres17) is the source of truth. Repo mirror:24 migrations,3 Edge Functions, linked and24/24 in sync at last backend gate. Frontend authentication/dashboard integration pending.
- Old study doubts board/student tools/exam cities/contribute cards were not ported. Grade calculator/exam cities show coming soon. Council agenda: `docs/council-questions.md`.

## Architecture map
- Commit sequence on the new branch: Lounge port/regressions `5ed4f86`, certificate query/stale responses `dfd974d`, centered sign-in/navbar/Tour fade/tests `588004b`, then docs/checkpoint.
- Port: `Frontend-lounge-port/src/pages/LoungePage.vue` → `src/components/lounge/App.vue`; Home/Events query views, lazy Tour, body-level native dialogs. All Lounge runtime/art/font/sound assets under `src/components/lounge/`.
- Port boundaries: `src/App.vue`, `src/router/index.js`, `index.html`, `src/lib/theme.js`; Lounge `boot.js`, `tide.js`, `home/motion.js`, `events.js` own boot/transition/runtime/clock lifecycle.
- Public site: pages `src/pages/*Page.vue`, components `src/components/site/`, shared state/adapters `src/lib/{store,events,house,courses,pat,theme}.js`, data `src/data/`, Pat assets `src/assets/pat/`.
- Backend: `supabase/migrations/`, functions `{apply-account-status,change-member-contact,hard-delete-member,_shared}`. No frontend backend calls yet.
- Glossary `CONTEXT.md`; decisions `docs/decisions.md`; conventions `docs/conventions.md`; prototypes remain source/history under `prototype/` and named worktrees.

## Stack & run
- Vue3, vue-router4 hash history, Vite6; static hosting; cloud Supabase mirror.
- Node: `export PATH=$HOME/.local/share/mise/installs/node/26.8.1/bin:$PATH` if mise shim fails.
- Port: `cd /home/raja/Anuraj-dev/Frontend-lounge-port`; `npm run dev -- --host 127.0.0.1 --port 5202 --strictPort` (already running).
- Gates: `npm run format:check`, `npm run lint`, `npm run build`, `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium npm run test:smoke`.
- Backend `supabase db push` / function deploy writes to the live project: only with Raja's explicit go-ahead.

## Key decisions
- E is B's painted look plus D's story, with expressive optimized motion. Porting preserves this approved source, including its fixture behavior.
- Home(Pat) ignores theme by design; public nav/footer follow it. Public site uses Anek Latin and warm palette, no green/lock icons.
- Lounge owns its shell, theme key and Home↔Events transitions. Public router skips its generic transition on Lounge entry/exit; CSS activation and font alias isolate public routes.
- Cloud schema is authoritative; repo backend mirrors it, not the retired local v1. Full history: `docs/decisions.md`.

## Gotchas
- Preserve source E/prototype work, active servers, unrelated branches and worktrees. Main docs/prototypes have pre-existing uncommitted work. Port is committed on `feat/lounge-production-entry`, not merged. The unused copied art-building helper remains untracked; prototype sources remain untouched.
- Original E Events band is Home's plate plus RiverBoat; Raja rejected copying D's band twice.
- Never rename hashes in built URLs by replacing filename substrings; theme partners are mapped before bundling.
- Theme/page work can resume after route unmount: keep epoch guards and runtime teardown. Clear shared nameCardOpen synchronously before dialog unmount events.
- Tests holding theme preloads must block decode before page navigation (idle warming otherwise caches a resolved promise), pause the clock, assert the pending state, and release the cap after route exit.
- Native overlays preserve Vue Router history state; registration is one-way; certificate name is the first confirmed name. Fixtures are not issued certificates or authenticated member data.
- `#app` z-index1 in public tokens requires Lounge's override toauto for body-level overlays. Scoped CSS `:global(.a) .b` compiles unexpectedly; use proper root/theme selectors.
- Home phone grids require minmax(0,1fr); bare1fr can stretch to poster width and move art off-screen. Keep programmatic Tour scroll behavior instant despite smooth global scrolling.
- Real Chrome background tabs can freeze motion; headless captures prove motion geometry/timing, not real phone/Safari performance or audio.
- Ports5432x belong to another Supabase project; this repo uses5442x. Never stop those containers. Never commit keys/member data. Edge functions need ALLOWED_ORIGINS.
- Cloud has events but no meetups/important_dates; those remain static. Meetup images use original Google delivery URLs, retry once, then drop.
- Entrypoint course data chunk remains ~85KB gzip; optimization is a separate follow-up. The chatbot is a separate React/backend project.
- Grok exploratory runs can consume turn limits without a final verdict; retain logs and narrow the prompt. One scoped Grok run exited143; final correctness judgment came from fresh Sol high reviews and root gates.
