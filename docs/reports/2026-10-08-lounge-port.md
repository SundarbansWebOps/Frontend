# Lounge E 1:1 production port — 2026-10-08

The approved Lounge E now runs through the production Vue router in `/home/raja/Anuraj-dev/Frontend-lounge-port`, branch `feat/lounge-production-entry`. Production changes are committed in focused steps. Preview: http://127.0.0.1:5202/#/login (owned detached Vite PID 106037).

## Scope and implementation

- Source: `/home/raja/Anuraj-dev/Frontend-lounge-e/prototype/lounge-e`, including rounds 10/11. Source worktree and port 5200 were preserved.
- Copied Home, Events, Tour, profile/name, certificates, notices, dialogs, sound, fixtures, and runtime assets into `src/components/lounge`; retained approved copy, art, breakpoints, motion timings, and storage keys. Removed prototype controls and unreferenced archived art from the port.
- `/lounge` has its own shell; `?view=events` selects its Events view. Public routes remain separate. Named route matching handles accepted case/trailing-slash variants.
- Zero-specificity CSS activation under `html.lounge-active` preserves the cascade and prevents Lounge palette/layout rules leaking onto public routes. The identical font bytes register as `Anek Latin Lounge`, including canvas/name measurement, without replacing the public site's font face.
- Added direct-entry theme/canvas boot, transition epoch guards, runtime/clock teardown, and synchronous name-card reset. These address route mount/unmount behavior absent from the standalone prototype.
- Carried forward E's existing certificate-query verification/stale-response fix into `src/pages/VerifyPage.vue`.

## Verification

Fresh local results:

- `npm run build`: exit 0. Inherited informational warning: NameBeacon is imported both statically and dynamically.
- `npm run lint`, `npm run format:check`, `git diff --check`: exit 0.
- `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium npm run test:smoke`: 28/28, exit 0. Nine Lounge regression tests cover navigation/reload, modal Back, first certificate-name creation and lock, controlled pending-theme teardown, route variants, name-card remount, exact event registration/reload, and font isolation.
- Production six-scenario matrix: desktop 1366, phone 390, reduced-motion 360/390, both themes; Home/theme/Events/registration persistence/Mine/groups/certificate/modal Back/long-name fit/Tour arrival passed. Zero captured warnings, errors, failed requests, and horizontal overflow.
- Source/port parity: 24 matched screenshots of Home/Events/ghat at 1366/390 in both themes. All measured geometry, font sizes, colors, and backgrounds match. Final pixel differences above RGB threshold 12 are at most 0.0131%; this is tolerance-based evidence, not a claim of byte-identical screenshots.
- CSS declaration audit: all 3,889 declarations across 23 style blocks match after normalizing asset paths and font alias. Motion keyframes/durations/easings are preserved.
- Motion captures: intro rises to center, turns, holds, and settles; theme circle and staggered fleet travel preserved; dialog hand-over dim stays 0.66 night / 0.42 day and fades on close.
- Production Tour: four chapter/size/theme runs plus reduced Skip/Not now passed; council bubbles, community-sheet focus/scroll lock, unseen-on-Skip, naming and Home handoff passed. Runtime reduced preference stops auto-row, hides offstage council from AX, and leaves zero running animations at 1366/390. Auto-row timing remains 67.2 s desktop / 85.2 s phone; full timed auto-row was not rerun this session.
- Known/missing production certificate query links passed, zero page errors.
- Real Raja Chrome: first Tour, Skip/ghat, Not now→Home, Home↔Events, phone Events at 390×844, and theme switch inspected. Temporary viewport override reset; final Home tab retained.

Evidence: `/tmp/lounge-port-evidence/` (flows, parity, CSS audit, motion, tour, lifecycle), `/tmp/lounge-port-*.txt` gates. Dispatch prompts/results: `/tmp/lounge-port-agents/`.

## Agent work and findings

- Six `gpt-6-luna` high read-only investigations: assets, Home/motion, Tour, Events, profile/dialogs, parity/boot. Primary performed the mechanical copy and integration.
- Four Grok 4.6 high dispatches: two exploratory runs did not produce final verdicts (one hit the turn cap); one focused run exited 143 without output; the focused CSS/asset review completed. Its font registration issue was addressed. Its selection-color claim was not reproduced; source and port computed selection colors matched. Selection scope now explicitly includes descendants.
- Fresh GPT-6.1 Sol high reviews found case/slash shell matching, name-card reopen on remount, and weak registration/race assertions. Fixed all. Follow-up found no production blocker; its remaining timing-test finding was fixed by pausing the clock, blocking decode before navigation, asserting pending state, then advancing the preload cap after teardown. Final suite passes.

## Boundaries

E's fixture/local-storage behavior is preserved. Authentication, real registration/attendance, certificate issuance, WhatsApp/Meet fixture links, council requests, and Supabase writes are not newly integrated. Original prototype Sign out behavior remains. Real phones/Safari and listening to audio remain unverified. Local commits only; no push, PR, merge, or deployment.

## Sign-in follow-up and commit delivery

Raja requested the original swinging door with centered Sign in and no Lounge preview, then clarified that the public navbar must stay. `/login` now retains desktop navigation/mobile tabs, hides the footer, and centers the door beneath navigation. Public Lounge links open sign-in. Sign in fades out for900ms, then the Tour fades in for900ms; reduced motion skips both. Every explicit sign-in resets the local tour-seen flag until Google auth/backend once-only gating is connected. The approved Tour→Lounge handoff is retained.

Final fresh gates on the delivery branch: build/lint/format exit0; production smoke/regressions32/32, exit0. Sign-in tests cover desktop/phone centering and navigation, repeated sign-ins, reduced motion, normal fade and cancelled route exit. Real Chrome desktop/phone and Sign in→Tour→Lounge were verified before committing.

Sequential code commits: `5ed4f86` Lounge/runtime assets/regressions; `dfd974d` certificate query verification; `588004b` sign-in/navbar/fade/regressions. Documentation follows separately. No `prototype/` or `prototypes/` paths were staged. The unused copied art build helper remains untracked. The original backend branch had only docs and excluded prototypes outstanding, so no unrelated-code commit was needed there.
