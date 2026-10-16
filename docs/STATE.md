# Sundarbans House — State

> IITM BS frontend/backend · Last checkpoint: 2026-10-16 16:20 IST

## In progress / next

- **Legacy Board portrait repair** — branch `feat/legacy-council-portraits`, local and uncommitted. Corrected portrait assets, existing real photos, team labels and all 2025 members are in place. Chrome preview remains at `http://127.0.0.1:5180/#/teams/legacy` (Vite PID 110532). **Next:** Raja reviews the page and provides the correct 2022 Secretary name when available. No commit, push, PR or deployment.
- **Contributors board at the bottom of Teams — branch `feat/teams-contributors-section` (worktree `~/Anuraj-dev/Frontend-teams-contributors`), PR open against upstream `main` (2026-10-16).** `/#/teams#contributors` ends with a "06 Contributors" section: Codex-generated pat art (`src/assets/art/contrib-ledger.webp`, `contrib-crew.webp`), `FireflyField.vue` motion, and `ContributorsBoard.vue` (counts from 1 July; hovering a name highlights its weeks). `ContributorsPage.vue`, the Helpers section and `src/data/helpers.js` are removed; `/contributors` redirects to `/teams#contributors`. Webops team cards untouched. Gates pass: lint, `check-design`, prettier, build, `npm run shots` (36 shots, no errors). Not verified: real signed-in Chrome, a physical phone, the hover highlight visually. **Next: Raja reviews the section in a browser and merges the PR.**
- **Lounge form audit and audience-status UI (2026-10-15).** All 13 URL-matched Admin records use the workbook URLs; all 10 group/community confirmation links were checked and five Lounge invite fields corrected/added. All four recruitment-titled forms are closed; all seven regional group forms remain globally open and published. Independent reviewer passed 4/4 recruitments and 7/7 regional groups. The Web Admin account is Patna; non-Patna form submission gates are false by design. Local UI changes now explain region/cohort restrictions, show the global form state in Admin, and let Super Admins open every group form from Lounge, with read-only previews when the server denies submission. Local build/lint/design checks pass; no deploy. See `sessions/2026-10-15.md`.
- **2023–24 tenure reading page + Legacy Board scroll — PR #163 (`feat/legacy-tenure-2023-story`), open.** `/#/teams/legacy/2023-24` → `src/pages/TenureReadPage.vue`: docs-style layout (Part dropdowns in a left sidebar, scroll-spy, "On this page" rail with margin art; sticky Contents dropdown under 1020px). Text is `src/data/tenure-2023.md` parsed at runtime, every word kept (Part VI and two editorial notes left out — Raja to confirm with the council). `LegacyPage.vue` now scrolls year to year (sticky view, snap, boat follows scroll, one year per wheel notch, `?year=` deep link, default 2021) with a "Read more" link on 2023. Shareable preview: https://sundarbans-legacy-2023-24.vercel.app (Vercel project `sundarbans-legacy-2023-24`, static build of a legacy-only router copy; see 2026-10-14 log). Old story view + prototype archived in `~/Anuraj-dev/legacy-board-designs/`. **Next: council/Raja review of the PR.** Unverified: real Chrome, physical phone touch scroll.
- **Legacy Board merged as PR #155 (2026-10-11).** `/#/teams/legacy` shows councils 2021–2025 with `?year=` and `?team=`. Still open from the 2026-10-11 log: Sol re-review of the fixes, real-browser animation checks, physical phone swipe and hidden-tab pause.
- **Prototype survey picker is on main.** `prototype/resource-hub/PrototypeSwitcher.vue`: Launch switches among three working designs and opens five static concepts. Resources keeps only Delta (A); B and C are dropped. Preview on the prototype dev server, port 5191.
- **Resources course board, tickets, drawer and two site fixes committed locally on `pr-156`; not pushed.** Commits `12bd110` (single-board subject picker, ticket and drawer redesign), `8726234` (calendar hover label readable), `b992411` (quick-link underline removed), `a5ef3ac` (calendar dialog uses smooth ease-out, no bounce). Lint, `scripts/check-design.mjs` and Playwright hover/motion/link checks pass. **Next: Raja reviews the calendar and quick links, then says whether to push and open the PR.** Do not open a PR before that. Carried over and unverified: dark-theme check of the new ticket and drawer, 360px width, phone word-breaking of long subject names.
- **PR #156 CI formatting fix passed.** Formatted `src/components/site/CourseTicket.vue` and `src/data/branches.js`. GitHub Actions run [38139553891](https://github.com/SundarbansWebOps/Frontend/actions/runs/38139553891) passes all checks. Maintainer @Anuraj-dev tagged on the PR. Vercel remains a separate failed status because the team must authorize the deployment.
- **Resources quick links use conditional anchored expansion.** Only branch-dependent links morph open: Student portal groups AE/ES at `es.study.iitm.ac.in` and DS/MG at `ds.study.iitm.ac.in`; Student handbook lists each branch choice. Other cards stay direct links or coming-soon actions. The floating window grows from the clicked card without shifting layout, using warm marigold-tinted paper, distinct choice cards and a themed scrollbar. Escape, outside click, close button, focus return and reduced-motion handling are supported. Design check, scoped ESLint, production build and diff whitespace pass. Screenshot sweep passed (36 shots, no errors). Local only; no commit/deployment. See today's session log.
- **Resources 26F3 calendar compacted and expanded as an overlay.** The side card now shows only the month grid and a small Open calendar action; no Schedule heading/dot, no sticky overlap over Quick links. The overlay dims the page, expands from the lower-right toward the top-left, lists the full term dates, and closes with Escape/backdrop/close button. Desktop and phone screenshots reviewed; overlay interaction verified. See today’s session log.
- **Resources page visual refresh is local and verified.** Branch descriptions removed; warm marigold/ink palette and original delta/book SVG artwork rasterized to light/dark transparent WebP page backgrounds. Restored the warmly framed branch picker and gold card tops; retained the small pat emblem. Dense course grid uses a muted brown top rail/warm wash (light) and subdued brown-gold rail (dark), neutral Pin buttons, brighter hover/pinned states; drawer shares warm surfaces and gold accents. Design check, full lint, build, diff whitespace and 36-shot gate pass; course grid desktop/phone, light/dark captures reviewed. No commit/deployment.
- **Inactive Lounge motion fixed and committed locally.** Shared runtime pauses CSS/Web Animations on blur or hidden document, suspends decorative timers, restarts rare effects with fresh delays, and freezes tour scroll time. No frontend deployment. Gates/evidence in today’s session; native OS app switching still needs real-host verification.
- **Lantern return animation fixed and committed locally.** Document-lifetime `loungeArrived` guards both Home intro and shell build; first Lounge arrival/refresh animate, form/route returns stay settled. No frontend deployment authorized/performed. Regression and preview verified; see today’s session.
- **WhatsApp group catalog fixed live with explicit user approval.** `20261009200000_lounge_group_catalog.sql` applied alone via `/tmp/sundarbans-group-rollout`; pending audit migration now depends on it. Live member RPC verified Technical/Esports/Cultural plus Kolkata for a Kolkata member; region filtering PASS. Actual signed-in browser unavailable; ask user to refresh affected Lounge. Cultural invite was added and verified on 2026-10-15.
- **Non-certificate audit fixes complete locally**, independently reviewed. Read `reports/2026-10-10-audit-fixes.md` for changes, fresh evidence and limits; original twenty-worker findings remain in `reports/2026-10-09-local-e2e-audit.md`.
- Certificates explicitly deferred: confirmation before issuance, renderer/name behavior, correction/revocation and download integration remain unresolved. Certificate feature files unchanged from this correction task's starting checkout.
- Remaining frontend/audit changes + `supabase/migrations/20261010000000_audit_fixes.sql` need an explicitly authorized rollout. No commit/push/PR/deploy/live mutation performed by this correction task.
- Authentic missing group sources, images, dates and allocations need approved inputs; community notice membership and historical audit retention still need product policy. No values invented.
- Branch `feat/lounge-backend-wiring`; group migration (`ad90985`), lantern arrival (`c2c4a85`), and inactivity motion (`97a0065`) committed at user request. Prior wiring/audit work is already in branch history. No push or frontend deployment. Preserve unrelated `supabase/tests/__pycache__/`. Starting audit checkout captured at `/tmp/sundarbans-fix-baseline`.

## Status

- Legacy Board portraits show the beige/gold tiger artwork inside each portrait or avatar; it is not a page background. Existing Cloudinary portraits were retained where available. 2021/22 RC folders did not expose photos in the connected Drive session; illustrated avatars are used where a photo was unavailable.
- 2021 Secretary is Kunal Chaturvedi and Deputy Secretary is Utkarsh Gaurav. Kunal is removed from 2022; its Secretary slot is blank pending Raja's confirmed name. 2025 renders all 11 team members.
- Lounge Tour uses the corrected 2021 leader portraits and updated 2025 Secretary/Deputy portraits. Assets and URLs are in `media/manifest.json`.
- Fresh local gates passed: production build, design check, targeted ESLint, Prettier check and `git diff --check`. Real Chrome showed the corrected Legacy years and portraits. GPT-6.1 Sol reviewed the current diff with no findings.
- Legacy Council update log: `sessions/2026-10-17.md`.
- Other Lounge/Admin, study, and audit work is documented in `sessions/` and `reports/`; certificates remain deferred, and live deployment requires explicit authorization.

## Architecture map

- Auth, client, router: `src/lib/{auth,auth-profile,supabase}.js`, `src/router/index.js`.
- Lounge: `src/lib/lounge.js`, `src/components/lounge/`, `src/pages/{LoungePage,FormPage}.vue`.
- Admin: `src/pages/AdminPage.vue`, `src/components/admin/`, `src/lib/admin.js`.
- Teams/Legacy: `src/pages/{TeamsPage,LegacyPage,TenureReadPage}.vue`, `src/data/{legacy,tenure-2023}*`, `src/assets/legacy/`.
- Public archive: `src/lib/events.js`, `src/data/events.data.js`.

## Stack & run

- Vue 3, vue-router 4, Vite 6, Supabase JS. Node 22 is declared; this host has Node 26.8.2.
- Run: `npm run dev` · Build: `node node_modules/vite/bin/vite.js build` · Design: `node scripts/check-design.mjs`.
- Current user preview: `http://127.0.0.1:5180/#/teams/legacy`, PID 110532. Leave it running for Raja.

## Key decisions

- Use real available portraits; use illustrated avatars only when no usable photo is available. Place the supplied tiger artwork inside every portrait image.
- Keep Kunal in 2021 only. Do not infer the 2022 Secretary; wait for Raja's name.
- Fix the team-data cap from each year's actual roster length so the complete roster renders without changing the two-row deck.
- No commit, push, PR or deployment without an explicit request.

## Gotchas

- Preserve unrelated work and never reset or clean the checkout. The current four modified source/manifest files are the Legacy portrait change.
- Drive folders for some 2021/22 RC photos returned Access Denied in the connected browser; do not claim those portraits are real photos.
- Vite can retain stale scoped style modules after HMR; verify visual changes in a fresh real Chrome page.
- Lounge database/auth behavior and mocked browser checks do not prove production deployment or external services.
