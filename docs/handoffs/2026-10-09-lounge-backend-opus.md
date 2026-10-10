# Continue Lounge/backend wiring — Claude Opus 5.5 High

You are taking over the coordinator role from Codex because Raja requested a quota-based handoff. **Use Claude Opus 5.5 at High effort. Do not dispatch Codex models. Use Sonnet 5.5 sub-agents for isolated remaining work and independent reviews.** Existing Grok implementation workers should finish their assigned work; do not duplicate them. The earlier GPT 6.1 Sol Medium backend review is recorded below. Raja's latest direction asks you to review everything when all implementation tasks finish.

## Objective and authority

Complete the confirmed design in `docs/specs/003-backend-data-decisions.md` and `docs/specs/002-lounge-backend-needs.md`: real Lounge/member profiles, first-entry tour flag, events, audiences, forms, CSV import/export, region corrections, notices, WhatsApp invites, attendance and certificates, and the Admin controls for all of them. Do not stop after planning or partial implementation. Verify the integrated system and resolve real review findings before the final claim.

Raja explicitly authorized implementation and live backend/data updates. **No production frontend deployment, commit, push or PR is authorized.** Work locally using Google Chrome Default profile and the existing local server. Preserve existing accounts and exactly three existing super-admin email identities. Do not invent council assignments, recipients, source questions, registration records or attendance. Report missing/inaccessible form sources so Raja can arrange council access/replacements. When a Google Form denies access, switch to Sundarbans Web Admin; do not send access requests or external messages.

Read AGENTS.md, STATE.md and INDEX.md first. Follow `.agents/skills/sundarbans-design/SKILL.md` before UI work. Checkpoint at the end. User decisions supersede old docs saying implementation/import is not yet authorized.

## Workspace and protected processes

- Checkout `/home/raja/Anuraj-dev/Frontend`; branch `feat/lounge-backend-wiring`, base `3fd970c`. No commits made. All worker edits are shared uncommitted files in this checkout.
- Pre-existing user docs must be preserved: CONTEXT.md, INDEX/STATE/decisions, sessions/2026-10-08.md, specs/002, and untracked ADR/session/spec003 files.
- Existing Vite PID **341684**, `http://127.0.0.1:5202`. Preserve it; HMR uses this checkout. Never stop unrelated processes.
- Other project uses 5432x and metaverse containers; never reset/stop those. Our local Supabase test stack uses **5442x**, workdir `/tmp/sundarbans-db-test`; backend worker started it. Disposable checked-in runner uses5452x and cleans only its stack.
- Linked Supabase project **bqoejoznqudcyeaebmsm**. CLI already authenticated; never read/export credentials.
- Private evidence/data directory, chmod700: `/home/raja/Anuraj-dev/sundarbans-imports/2026-10-09-wiring/`. No member rows, contact info, invite links or secrets in repo/docs.

## Active implementation workers: finish, then integrate

Workers have been asked to publish durable results in `/tmp/sundarbans-{backend,admin,member}-status.md`. These may not exist until they finish; inspect actual diffs and rerun checks rather than trusting messages.

1. Native `/root/backend`, GPT6.1SolHigh: owns three new migrations, `src/lib/lounge.js`, Supabase tests/runner. Latest local runner passed **166 pgTAP tests**, exit0; no live writes. Fresh follow-up is fixing concurrency review findings below. No further Codex work should be dispatched after quota transition; if it cannot finish, take its ownership only once it stops. Current native agent communication belongs to originating root thread; durable status is the cross-provider bridge.
2. Grok4.6High Admin task, active: owns `src/components/admin/**`, `src/pages/AdminPage.vue`, `src/lib/admin.js`, Admin e2e tests. Task ID `node:delegated-task:command%3Amcp%3A94b2ec4e-c24e-413f-9d73-2fa636f41196%3Adelegate-task%3Alounge-admin-implementation-20261009-r1`. Backing thread ID is same suffix with `thread:delegated-task:` prefix.
3. Grok4.6High Member task, active: owns `src/components/lounge/**`, Lounge/Login/Events/VerifyCertificate pages, new Form/Certificate pages, router, auth.js/events.js and member tests. Task ID same prefix ending `lounge-member-implementation-20261009-r1`.

Use T3 `t3_thread_read` for existing worker outputs if task ownership prevents task_status from this child. `t3_thread_send` may steer active implementations, never reuse a child thread for another review round. Avoid polling loops. Do not start another writer on their paths while they are active.

Shared adapter contract: `/tmp/sundarbans-wiring-contract.md`; read actual `src/lib/lounge.js` for latest signatures. Forms have field types text, textarea, email, phone, select, checkbox, multiselect with optional Other. Exported responses include captured `field_schema`, answers and authenticated submitter email, not unrequested profile contact details. Notices now support community scope and cohort audiences. Events include archive/source metadata. Blank signed certificate template upload is supported; only images up to10MiB. Issued certificates remain private; public verification returns safe event/issue metadata without recipient email/name.

## Backend review: HOLD LIVE migration until resolved

Independent **GPT6.1SolMedium** review identified four P1 authorization defects in the new migrations. NULL bugs were fixed and tested; concurrency defects were sent to backend for fixes and real two-connection regression proof. Verify final status/source, and run a fresh independent Sonnet5.5 review before live updates.

1. `private.manages_scope` previously returned NULL for ordinary members with no RC role; `IF NOT NULL` skipped rejection. Ordinary members could CREATE regional forms and CREATE/UPDATE regional notices; suspended users also lacked an explicit notice active check. Fixed helper COALESCE(false), `IS NOT TRUE` gates. Verify suspended notice negative test.
2. `review_region_change` previously had nullable current-RC expression, letting unrelated members approve a valid existing request. Fixed fail-closed gate. Original negative test used nonexistent request and falsely passed; now explicit valid fixture ID proves denial.
3. `import_event_attendance` and `release_event_certificates` authorize before acquiring event `FOR UPDATE`. Concurrent SA scope change can commit during RC lock wait, then old-region RC operates on new-region event. Recheck authority against locked event. Require two-connection regression, not only static reasoning.
4. `submit_lounge_form` checks member active status/audience before member lock. A concurrent suspension/region correction can commit during lock wait and then allow ineligible registration. Recheck after lock and protect linked event scope/audience/publication against concurrent mutation.

Inspect other scopes and mutable checks for the same pattern. Tests that only reject missing entities do not prove permission enforcement. Independent reviewer did NOT run concurrency reproduction; the races were inferred from explicit lock ordering. No review-clean claim is justified yet.

Migrations: `20261009150000_member_lounge.sql`, `20261009150100_lounge_events_forms.sql`, `20261009150200_attendance_certificates_notices.sql`. Root reconciled five older filenames to their exact remote versions (normalized SQL content equality confirmed): 20261008155748,155946,162947,164200,164310. No historical SQL content changed. Migration list aligned, only three new files pending. Do not repair/reapply old ones.

Local tests: `bash supabase/tests/run-local.sh`. It copies migrations to temporary workdir and bootstraps a missing cloud platform function locally; historical files remain intact. `010_admin_panel_test.sql` updated old all-region RC expectations and setup; `020_member_lounge_test.sql` covers new contracts. Service eslint/prettier passed, full integrated frontend checks not yet run.

## Live backend/data work still pending

No new migrations or roster/forms/events have been applied live in this implementation session. Last live baseline:3members,3fixedSAs,0roster,0events,0scopedassignments. Existing Google OAuth login/reload/Admin access verified in real Chrome before this work. Third SA's intended Deputy identity is unverified; preserve the account rather than reassigning it.

CLI supports `supabase db query --linked --file /absolute/file.sql --output json` (Management API), migration list, push/dry-run. Do not print private rows. Run read/write SQL from private files; no shell-interpolated JSON or secrets. Before push, fresh local tests and security review must pass; then `supabase db push --dry-run`, inspect, push only three new files.

Backup `pre-wiring-schema.sql` completed. Public/private data dump started with exec session **87217**; poll if accessible or verify `pre-wiring-data.sql` is complete. Schema backup session59711 finished exit0. Do not expose backup contents in output.

Initial roster input: `/home/raja/Anuraj-dev/sundarbans-imports/2026-10-08/user-current-email-source/reconciled-students.json`, shape `{students:[...]}`. It has4089union rows; **filter `listed_in_preferred_email_source===true` =>3808 uniqueemails**, never import the281allocation-only extras. DS3534, ES146, MG100, AE28. All names/phones null; do not populate unverified source candidates. Existing region IDs1–9 in private regions.json;8International rows (`region_name_raw='International Region'`) map to new International lookup (expected10, query afterpush);4 truly unknown stayNULL and first-entry region selection. Existing member emails remain accounts, not roster duplicates; conflicts must not overwrite profiles/regions/roles/status.

Use approved business RPC `roster_add_many` in chunks<=500 with existing WebAdmin authenticated claims in a transaction. Management SQL is privileged but do not bypass business validation. Set request.jwt.claim.sub/claims to actual existing SA id resolved privately, do not invent an identity. RPC reports added/existing/conflict/invalid. Audit totals; rerun idempotency and explain any existing-account conflict. No Auth pre-creation: first Google sign-in claims roster.

Events: real public archive contains **43** `EVENTS` records in `src/data/events.data.js`. Import idempotently as published **archive=true** with stable source_key, original title/description/display_date/image_url/type/wing/location/image dimensions. Actual past dates vary and some say Online Submission; do not fabricate schedules. Archive allows nullable times. Attendee strings like50+ must not silently become exact50; preserve display metadata or leave numericcountNULL. No invented upcoming/live events or attendance. Community IDs:1esports,2technical,3cultural. Also assess existing regional meetup sources for duplicates/scope before claiming every events section is wired.

## Google Forms:17 accurate definitions prepared;5 blocked sources

Private `form-sources.json`:22sources extracted via visible Chrome UI, with original question labels/types/options/required flags; no hidden Google runtime scraping. `ported-forms.json`:17deterministic source-URL UUID definitions; `form-port-report.json`:22source statuses. **Not imported yet.** Check field type/phone limits and Other values against backend/UI contracts before importing. Two historical recruitments (RC and Cultural) must remain closed/unpublished; source sheet saysClosed even though responderUIlooksopen. Other prepared active forms publish/open after actual insertion. Cultural membership invite missing; do not invent one or imply admission.9available group invites privately sourced:5fresh editor confirmation pages,4unique regional-sheet links (older, not live validated).

Membership forms: Bengaluru, Chandigarh, Chennai, Delhi, Kolkata, Mumbai, Patna; Technical, Cultural, Esports. GHC forms: Chandigarh, Delhi, Mumbai, Patna. Recruitments: RC(closed), Cultural(closed), Sports(open). Scope and exact questions reside private JSON.

Confirmed council access needs (already switched to WebAdmin; do not request again as if untried):
- Hyderabad WhatsApp form AccessDenied: https://forms.gle/BTCEdUqBMudbUm699
- Lucknow WhatsApp form AccessDenied: https://forms.gle/5HxZWeQKMCgHvdLt6
- Lucknow GHC form AccessDenied: https://forms.gle/gMdiCL67CAMkR7Ws9
- CoreTeam recruitment closed, questions/editor unavailable: https://forms.gle/QR8mQLmmt41WNtrV6
- Technical recruitment closed, questions/editor unavailable: https://forms.gle/JBD4VCf7XHNYnCTU6
- Cultural membership questions readable but invite/editor unavailable: https://forms.gle/JN4cUzhJc7bedcqHA (needs invite or editoraccess).
- No International membership form found in current central inventory.

Potential additional source not explored yet: Meetup Records https://forms.gle/6bGNvqVhyoN8fKNx6 from workbook index. If readable, inspect whether fileupload fields are required and implement coherent attachment support rather than replacing uploads with arbitrarytext. Do not claim literally all sourceforms ported while blockers/unexploredsource remain. Still finish every accessible independent feature and report precise source-only exceptions.

Browser: use Chrome Default, never IAB/production/Brave. Old app tab821727333 and sourceform tab821727351 may survive. CUA bindings don't transfer; initialize and follow docs. If contextcompactedcall cua.rewriteDocumentation. Accountauthuser1WebAdmin was observed; personalauthuser0. Googleeditorloadwait for AddshortcuttoDrive button before Settings → Presentation → Confirmation; earlySettingsclick can reset and falsely suggest emptyinvite. Read only; no sourceformsubmission/editing. Save localapp verification screenshots, not OAuthcallbackcodes/contactlists.

## Required completion gates and handback

1. Finish existing workers; inspect diffs and service contracts, remove prototype identity/global-name leakage and mock/sample-data paths from real member/admin flows. Verify backend tour flag is set on successful complete/skip, not reset every login. Optional names/phones and Savephoneconsent; certificate name separate/locked with correctionrequest.
2. Fresh backend tests and independent Sonnet security/spec review; resolve allP1s and prove scope races. Only then live schema/data update with aggregate audit and idempotency.
3. Verify forms builder/publication/windows/audiences/cohorts, response CSV capturedschema, seed CSVdedupe/headers/preview/chunks/conflicts, attendanceGoogleMeetCSV duration/duplicateconnections/20minute rule/registeredonly and export, signedtemplate release, unconfirmednameissuance afterward, name snapshot/publicprivacy.
4. Full local gates: formatcheck, lint, check:study, check:design, build, `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium npm run test:smoke`; meaningful new tests, no timingfalsepositives. Rebuild before smoke. Existing smoke mockedSupabase50tests is not realOAuthproof. No package/dependency/font/token/baseline changes without need/authorization.
5. Real Chrome local verification with existingWebAdmin, liveDBprofile/session/tour/Lounge/Admin/formbuilder/importexport, and light/dark desktop/phone screenshots inspected. Prefer rolled-backSQL fixtures or private clearlylabelledtemporarydraft UI records; don't leave invented publicbusinessdata or mutate otherusers.
6. **After all implementation tasks finish, perform final independent Sonnet5.5 review of full integrated diff for standards, spec, privacy/security and tests, while Opus owns final integration judgment. No Codex review dispatch.** Fresh reviewer for each round. Fix real findings, rerun proportionatechecks, state unresolved externalgates honestly.
7. Checkpoint STATE/session/INDEX with actual live totals, exact source gaps, gates and nextactions. No commit/push/deploy. Final concise outcome + evidence + sourceaccessneeds + local screenshot.

## Orchestration selection and quota

Climit binary `/home/raja/.local/bin/climit`; invoking `climit --help` actually reports usage. At13:40IST: Codex5h90%, weekly71%, reset15:50; Grokweekly16%. Recheck before transition. Live T3catalog confirms provider `claudeAgent`, model `claude-opus-5-5`, options `{effort:'high'}` and `claude-sonnet-5-5`, options `{effort:'high'}`. Use T3delegate_task for crossprovider childwork. Do not start independent top-level conversations unless Raja asks. Taskcontinuation must keep this same checkout/uncommittedchanges; worktreecreation wouldn't copy them.

### Transition update —13:45IST
Climit now **95%5h**, weekly71%, reset15:50. Both schema and public/private data backups finished exit0; pre-wiring-data.sql complete. Backend worker reports race fixes implemented and old-code bug reproduced by real two-connection harness (old-region RC imported after scope move). Fresh patched runner with five concurrency cases and suspended-notice gate is running; final proof still pending. Admin delegated task just reached terminal state; read its result/durable status and inspect diffs. Member task remains independent until status confirms completion. Opus owns coordination from this point; originating Codex stops new work at quota threshold.

### Opus checkpoint — 14:05 IST (read this first after compaction)

All workers are terminal; Opus owns every file. **Raja: use Haiku 5.5 subagents (not Sonnet), no Codex.** Worker evidence: `/tmp/sundarbans-{backend,admin,member}-status.md`.

Done since takeover (uncommitted, verified):
- Backend handover verified: run-local 166 pgTAP + 7 race checks PASS; earlier 4 Sol P1s confirmed fixed by an independent Sonnet review.
- Frontend integration: `cert.js renderOnTemplate` composites the confirmed name + verify line onto the signed template (CertificatesPopup/CertificatePage); FormFields single-select "Other" (`Other:<text>`) and autocomplete fix; events.js filters Offline Meetups from the DB path too and maps `attendee_display`; admin.js selects/saves `attendee_display`; lounge/fixtures.js reduced to the `member` shell.
- e2e updated by a Sonnet worker (mock carries tour_seen_at/cohort, RPC defaults, `callTo` helper; hd assertion removed). Full smoke: 58 pass, 1 `test.fixme`, exit 0. format/lint/study/design/build all exit 0.
- Private generators (not yet run): `~/Anuraj-dev/sundarbans-imports/2026-10-09-scripts/gen_roster.py <reconciled-students.json> <out.sql> <international_id>`, `gen_events.mjs <repo> <out.sql>` (uses `attendee_display`; meetups → regions 8/2/9; wings cultural3/esports1/tech2; insert-once on source_key), `gen_forms.py <ported-forms.json> <out.sql>` (insert-once by id; published_at=now(); Sports recruitment community→NULL), `audit.sql` (aggregates only). Write generated SQL into the private dir (0600), never /tmp or repo.

**Fix before live (from the 14:00 independent review; none applied yet):**
1. P1 `private.file_member_request` (20261008155946:301) `v_member.region_id <> v_region` is NULL for NULL-region members → RC can file deletion/blacklist requests and read the snapshot. `create or replace` it in migration 150000 with `is distinct from`; pgTAP negative test with an existing NULL-region member.
2. P2 `<>` NULL comparisons silently drop name/region updates: 20261008162947 lines ~193, ~231 and 20261008164310 ~218 → `is distinct from` via create-or-replace in 150000 (don't edit historical files).
3. P2 `svc_execute_hard_delete` doesn't redact new PII (members.certificate_name/cohort/tour; form_responses; event_registrations.registered_email; event_attendance email/raw_row; issued_certificates name; certificate_name_requests; member_region_requests.reason). Extend it.
4. P2 roster_add conflict for non-SA reveals other-region identities → return like `existing` for non-SA callers.
5. P2 CSV formula injection in admin.js `toCsv` (~335): prefix `'` for cells starting = + - @ tab; quote \r.
6. P3 `lounge_forms_read` policy unqualified `id` → `r.form_id = lounge_forms.id`.
7. P3 events_select/events_update let RC/Heads see/restore soft-deleted events → add `deleted_at is null` for non-SA.
8. P3 issued_by = events.updated_by → add `certificates_released_by`, set on release, use it.
9. P3 restrict certificate_template_url to this project's storage `certificate-templates/<event_id>/` prefix (image_url stays https).
10. Own additions: add `events.attendee_display text check(length<=50)` in 150100 (insert/update grants, anon select grant, public_events view column); accept `allow_other` on `select` in `submit_lounge_form` (`Other:%`, length>6).
11. Tests: assign_position second/third RC via RPC; different-region RC reviewing region change; validate_event archive guard; search_members returns row; drop 54422 from concurrency.py allow-list.
12. Frontend bug: `AdminCohortSelect.vue` disables Year/term controls when selection is empty, so audiences can't be narrowed (used by AdminEvents/Forms/Notices). Fix, then un-fixme the admin-wiring Future-badge test. Also ProfileEdit.vue:4 comment says "Edit name".
13. Ask Raja (product, don't guess): community-scoped notices currently reach every member — intended? Name-correction approval doesn't reissue already-issued certificates — acceptable?

Then: `bash supabase/tests/run-local.sh` → fresh Haiku security re-review of the fixes (new reviewer, include this list) → `supabase db push --linked --dry-run` (expect 3 files) → push → audit.sql (get international_id) → run roster (expect added 3808 minus existing-member overlaps; explain conflicts) → events (43) → forms (17) → rerun all three to prove idempotency (0 new) → audit again → real Chrome Default verification on 127.0.0.1:5202 as Web Admin (Lounge profile/tour/forms/notices, Admin builder/import/export, public Events), light/dark desktop/phone screenshots → final Haiku full-diff review → checkpoint. No commit/push/deploy.

### Opus progress — after compaction
- Items 1–12 of the 14:05 list fixed (create-or-replace / guarded `pg_get_functiondef` rewrites in 150000 and 150200; 150100 columns/policies/template check; admin.js CSV; AdminCohortSelect; comments). Template URL must be `https://<20-char ref>.supabase.co/storage/v1/object/public/certificate-templates/<event id>/<file>` and the object must exist.
- `bash supabase/tests/run-local.sh`: 198 pgTAP + 7 race PASS, exit 0. Frontend gates 0; smoke 59 pass (fixme removed). Dry-run lists exactly the 3 migrations. Haiku 5.5 security re-review running.
- 15:35: Raja stopped the Haiku re-review ("you verify"). Live push done; imports done and idempotent (see STATE). Remaining: signed-in Chrome verification once Web Admin is signed into Chrome Default; two product questions; council-source gaps.
