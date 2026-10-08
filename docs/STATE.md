# Sundarbans House — State
> IITM BS frontend and backend · Last checkpoint: 2026-10-08

## In progress / next
- **Lounge E port, Raja's review round.** Worktree `/home/raja/Anuraj-dev/Frontend-lounge-port`, branch `feat/lounge-production-entry`, local commits only (not pushed, no PR). Preview http://127.0.0.1:5202/#/login (owned Vite PID 106037).
- Next: Raja reviews House card, sign-in door, boat on Events, and sign-out in real Chrome. Chrome tabs in the background pause animations; verify motion in a visible window.
- Google sign-in and the once-only tour seen flag are pending backend work. Sign-out currently just returns to `/login`; there is no session.
- Backend wiring is separate work: `docs/specs/002-lounge-backend-needs.md`. No backend writes, push, PR, merge, or deployment requested.
- Council change pushed on `fix/council-deputy-secretary` (`bb81c16`); no PR. Do not silently change Bengaluru's status.
- Cloud Supabase `Website Backend` (`bqoejoznqudcyeaebmsm`) is the source of truth; repo mirror in sync. Frontend auth/dashboard integration pending.

## Status
- Port commits on `feat/lounge-production-entry`: `5ed4f86` port, `dfd974d` certificate/stale responses, `588004b` centered sign-in, `ee2b355` docs, `76710a4` door rooms + sign-in cross-dissolve, `c106fbe` boat glide removed, `009b47c` sign-out to `/login`.
- House card (`src/components/site/LoungeDoor.vue`): one yellow "Sign in with IITM email" button with the tour button's hover; room list = what the launch contains (Live events, Regional groups, Certificates). Night Owl, Leaderboard, and "planned" tags removed. Shared list: `src/components/site/lounge-rooms.js`.
- Sign-in door (`src/pages/LoginPage.vue`): same button effect; the three rooms appear under Sign in once the door opens.
- Sign-in → tour: cross-dissolve via View Transitions (900ms, `html.sign-in-cross`). Timed fade remains the fallback (no API or reduced motion).
- Boat on Events: no arrival glide now (`ProfileMenu`/`EventsPage` `boat-arrived` removed). Only the 3px idle bob remains.
- Sign-out: closes the profile menu, waits for the pop-up's history Back, then routes to `/login` (`src/components/lounge/ProfileMenu.vue`).
- Gates at `009b47c`: format, lint, build exit 0; smoke 33/33 on two runs. One earlier run failed `e2e/lounge.spec.js:68` (theme switch on art); it passed alone and in two later runs, treated as a flake.
- Not verified: the cross-dissolve mid-frame (Chrome tab was hidden; screenshots landed after the overlap). Verify by eye.
- Untracked, not ours to commit: `src/components/lounge/art/r6/tour-graded/build.py`.
- Main checkout `/home/raja/Anuraj-dev/Frontend` has uncommitted user work (`M docs/*`, prototype dirs). Untouched by this session.

## Architecture map
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
- Port: `cd /home/raja/Anuraj-dev/Frontend-lounge-port`; `npm run dev -- --host 127.0.0.1 --port 5202 --strictPort` (running).
- Gates: `npm run format:check`, `npm run lint`, `npm run build`, `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium npm run test:smoke` (uses `vite preview` on 4173 — rebuild before running after source edits).
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
- Preserve source E/prototype work, active servers, and unrelated worktrees. Port is committed on `feat/lounge-production-entry`, not merged.
