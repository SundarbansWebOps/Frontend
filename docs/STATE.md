# Sundarbans House — State
> IITM BS frontend/backend · Last checkpoint: 2026-10-10 22:14 IST

## In progress / next
- **Resources 26F3 calendar compacted and expanded as an overlay.** The side card now shows only the month grid and a small Open calendar action; no Schedule heading/dot, no sticky overlap over Quick links. The overlay dims the page, expands from the lower-right toward the top-left, lists the full term dates, and closes with Escape/backdrop/close button. Desktop and phone screenshots reviewed; overlay interaction verified. See today’s session log.
- **Resources page visual refresh is local and verified.** Branch descriptions removed; warm marigold/ink palette and original delta/book SVG artwork rasterized to light/dark transparent WebP page backgrounds. Restored the warmly framed branch picker and gold card tops; retained the small pat emblem. Dense course grid uses a muted brown top rail/warm wash (light) and subdued brown-gold rail (dark), neutral Pin buttons, brighter hover/pinned states; drawer shares warm surfaces and gold accents. Design check, full lint, build, diff whitespace and 36-shot gate pass; course grid desktop/phone, light/dark captures reviewed. No commit/deployment.
- **Inactive Lounge motion fixed and committed locally.** Shared runtime pauses CSS/Web Animations on blur or hidden document, suspends decorative timers, restarts rare effects with fresh delays, and freezes tour scroll time. No frontend deployment. Gates/evidence in today’s session; native OS app switching still needs real-host verification.
- **Lantern return animation fixed and committed locally.** Document-lifetime `loungeArrived` guards both Home intro and shell build; first Lounge arrival/refresh animate, form/route returns stay settled. No frontend deployment authorized/performed. Regression and preview verified; see today’s session.
- **WhatsApp group catalog fixed live with explicit user approval.** `20261009200000_lounge_group_catalog.sql` applied alone via `/tmp/sundarbans-group-rollout`; pending audit migration now depends on it. Live member RPC verified Technical/Esports/Cultural plus Kolkata for a Kolkata member; region filtering PASS. Actual signed-in browser unavailable; ask user to refresh affected Lounge. Cultural invite remains missing.
- **Non-certificate audit fixes complete locally**, independently reviewed. Read `reports/2026-10-10-audit-fixes.md` for changes, fresh evidence and limits; original twenty-worker findings remain in `reports/2026-10-09-local-e2e-audit.md`.
- Certificates explicitly deferred: confirmation before issuance, renderer/name behavior, correction/revocation and download integration remain unresolved. Certificate feature files unchanged from this correction task's starting checkout.
- Remaining frontend/audit changes + `supabase/migrations/20261010000000_audit_fixes.sql` need an explicitly authorized rollout. No commit/push/PR/deploy/live mutation performed by this correction task.
- Authentic missing group sources, images, dates and allocations need approved inputs; community notice membership and historical audit retention still need product policy. No values invented.
- Branch `feat/lounge-backend-wiring`; group migration (`ad90985`), lantern arrival (`c2c4a85`), and inactivity motion (`97a0065`) committed at user request. Prior wiring/audit work is already in branch history. No push or frontend deployment. Preserve unrelated `supabase/tests/__pycache__/`. Starting audit checkout captured at `/tmp/sundarbans-fix-baseline`.

## Status
- Deputy Secretary added live to `public.super_admin_allowlist` using Supabase CLI at user request; active member and `private.is_super_admin() = true` verified. Existing admins preserved; total now four. No migration push or frontend changes.
- Fresh group audit (2026-10-10): live has 43 events, 17 forms / 15 published, 9 invites, 1 response; group metadata column absent before fix, now applied. Ten verified forms: Technical/Cultural/Esports + Bengaluru/Chandigarh/Chennai/Delhi/Kolkata/Mumbai/Patna. Cultural lacks invite. Targeted migration proved old RPC returns 0 groups before and 10 after, preserves titles/general forms; disposable transaction rolled back. Full 232 pgTAP + 9 concurrency checks, build, 2 relevant Playwright tests PASS. Logs `/tmp/sundarbans-group-{regression,db-tests,browser-tests,build}.log`. Post-rollout live catalog: 10 group forms / 9 invites; 43 events preserved; broader audit migration remains unapplied. Signed-in real browser unavailable in current CUA inventory; rendered live member UI still unverified.
- Member Events removes region/term browsing controls; audience enforcement remains. Lifecycle updates with clock, cancellation/availability respected, exact 1200-second attendance threshold and source-preserving archive dates fixed.
- Group discovery uses form metadata instead of frontend UUID allowlist; ten previously verified membership sources classified. Applied/invite/error states persist; routed forms use Lounge shell/theme. Missing approved house-wide source remains missing.
- Auth account-switch races guarded; optional preferred name stays independent of roster/certificate name. Region picker refreshes related data. Form validation, notices and public navigation/accessibility corrected.
- Backend migration adds source-owned attendance merge/replace, shared-source conflict rejection, canonical roster locking/opaque RC replies, form source/archive/invite protections, guarded event removal and operational erasure redaction. Admin scope, paging, import preview and CSV fixed.
- Final gates: **86 Playwright tests; 232 pgTAP assertions + 9 concurrency cases; build; full ESLint; Prettier for 54 changed source/test files; design; study data; diff whitespace — all PASS.** Full-repo formatting not run. Independent Standards and Spec review found no remaining verified actionable non-certificate finding.
- Screenshot sweep: 36 public/anonymous light/dark desktop/phone shots, no page errors/sideways overflow. Real Google Chrome separately checked synthetic member Events, routed group submission/reload/theme, public contrast and Resources keyboard/modal behavior. Evidence `/tmp/sundarbans-fixes/`, `test-results/shots/`; logs `/tmp/sundarbans-fix-*.log`.
- Local bypass requires Vite DEV + loopback + `?local-lounge=1`; synthetic member, no Admin role or Supabase writes. Production code excludes the fixture and flag still lands at Login. `local-region=0` tests initial selection.
- Prior live read-only audit (2026-10-09): 5 members, 3803 roster; 2 member cohorts and 2 roster regions unknown. 43 archive events with NULL schedules, 8 missing images, 22 approximate turnout labels; public adapter exposes 40 after intended meetup exclusion. 17 forms/15 published; no registrations/attendance/certificates/templates. Details in original report; no fresh live audit this correction task.
- Earlier session applied migrations 150000/150100/150200 live and added the exact testing OAuth redirect. Testing deployment still serves sample boats; current frontend/migration fixes are local. Live OAuth/Admin writes were not revalidated.

## Architecture map
- Auth/client/router: `src/lib/auth.js`, `auth-profile.js`, `supabase.js`, `src/router/index.js`; synthetic client `src/lib/local-lounge.js`.
- Lounge: `src/lib/lounge.js`, `src/components/lounge/{session,events}.js`, `src/pages/{LoungePage,FormPage}.vue`.
- Admin: `src/pages/AdminPage.vue`, `src/components/admin/`, `src/lib/admin.js`.
- Public archive/navigation: `src/lib/events.js`, `src/components/site/`, public pages; DB first, `src/data/events.data.js` fallback.
- Tests: `e2e/`, `supabase/tests/{020,031,concurrency.py,run-local.sh}`. New migration: `supabase/migrations/20261010000000_audit_fixes.sql`.

## Stack & run
- Vue3/router4/Vite6/supabase-js2.117.2. Node^22 declared; gates used installed Node26.8.2 directly because npm shim has had AppImage failures.
- Owned preview: `http://127.0.0.1:5202/?local-lounge=1#/lounge`, **PID259636**, exec59071. Started this session; synthetic member only. Port5210 belongs to Frontend-maintenance; leave it.
- Build: `node node_modules/vite/bin/vite.js build`. E2E after build: `LOCAL_LOUNGE_TEST_URL='http://127.0.0.1:5202/?local-lounge=1' node node_modules/@playwright/test/cli.js test --workers=3`.
- Gates: `node node_modules/eslint/bin/eslint.js .`, `node scripts/check-study-data.mjs`, `node scripts/check-design.mjs`. Backend: `bash supabase/tests/run-local.sh`, disposable5452x/self-cleaning.
- Linked Supabase `bqoejoznqudcyeaebmsm`. Query CLI returns last row-returning result; use aggregate-only read-only transactions for source audits.
- Real-browser gate: actual Google Chrome AJS connection, browser ID3. Generic Chrome alias can select Helium; inspect inventory. No signed-state substitution.

## Key decisions
- Roster-gated first Google login; optional editable name/phone; profile phone saved only with consent; tour seen flag persisted on Enter/Not now.
- Four SAs after the explicitly requested Deputy Secretary addition on 2026-10-10; 0–2 RCs/region; International no RC. Initial NULL region self-service; corrections approved by current-region RC or SA.
- Upcoming/live audience enforced; published past public. Preserve source date precision/NULL schedule and approximate turnout instead of manufacturing data.
- Forms members-only; response gates invitation, application is not admission. Group catalog uses verified metadata. Default attendance merge; explicit replacement removes only that source's ownership and rejects shared conflicts.
- Certificate design unchanged and deferred. Full decisions in `decisions.md` and `specs/003-backend-data-decisions.md`.

## Gotchas
- Preserve all unrelated changes. No raw member contacts, private invite URLs or secrets in docs/output; private imports stay outside repo.
- Fail closed and recheck authorization after locks. STABLE export reads share statement MVCC snapshot; suspected export race was rejected.
- Never touch5432x/metaverse or stale5442x stacks. Owned5452x test stack cleaned up; preserve other agents/servers.
- No source-form submissions/access requests/messages without scope. Blank optional roster names are intentional, not corruption.
- Lounge dialogs close through async history.back; tests wait for dialog disappearance and settled URL before reload. Fixed-clock tests pause in the future.
- Synthetic/mocked browser and disposable database tests do not prove live OAuth, external WhatsApp admission or deployment. Concurrent HMR can retain stale router state; real Chrome checks used clean loads.
