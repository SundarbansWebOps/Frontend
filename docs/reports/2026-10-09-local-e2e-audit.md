# Local website audit — 2026-10-09

Twenty GPT-6 Luna subagents completed ten frontend and ten backend/data audits through the native subagent tool. The session permits four active agents including the primary agent, so workers ran in waves. The primary agent performed integration checks, real Google Chrome checks, source spot-checks, and a read-only live database aggregate audit. No commits, deployment, migrations, live data changes, or source-form submissions were performed.

## Result and evidence limits

The current checkout has substantial existing uncommitted backend/lounge work. This audit evaluates that local state, not the deployed testing website. The new local login uses synthetic data; it does not create a real Supabase session or grant database access. Source audits identify contracts and gaps, not proof that every reported scenario occurred live.

| Check | Fresh result |
| --- | --- |
| Production build | Exit 0 |
| Full Playwright suite, including enabled local fixture tests | **62 passed, 1 failed**; exit 1 |
| Remaining failing test | `e2e/admin.spec.js:40` expects old wording “not on the house roster”; actual alert is the approved “Access Denied…” wording |
| Initial full Playwright run | 58 passed, 2 failed; second failure was `page.reload: net::ERR_ABORTED` in registration test |
| Registration isolated rerun | 1 passed; also passed in final full run; initial reload race remains a test-stability finding |
| Local bypass tests | 3 passed: production flag ignored, registration persisted in Mine, group invite appears after submission and persists in Home |
| Backend | 198 pgTAP assertions + 7 concurrency cases passed; exit 0 |
| ESLint | Full repo passed; exit 0 |
| Prettier | Three newly touched code/test files passed; full-repo formatting not run |
| Design guard | Passed |
| Study-data guard | Passed: 23 courses, 567 notes, 1,498 PYQs |
| Screenshot sweep | 36 public/anonymous route shots; no page errors or sideways overflow. Lounge route redirects to login in this sweep |
| Real Chrome | Synthetic member Home/Events/form flow checked on desktop and 390×844 phone, day/night; application submission and reload checked |
| Live Supabase | Aggregate-only query inside a read-only transaction; no member contacts or invitation links extracted |

Real OAuth, signed-in live Admin mutations, actual WhatsApp admission, signed-template certificate downloads, external links, and every keyboard/assistive-technology flow were not exercised. Passing existing tests does not cover the missing scenarios below.

## Local login

Open [local Lounge](http://127.0.0.1:5202/?local-lounge=1#/lounge).

- Vite development mode + explicit loopback hostname + `local-lounge=1` are all required.
- The synthetic client replaces Supabase at its existing client seam: [supabase.js](/home/raja/Anuraj-dev/Frontend/src/lib/supabase.js:15), [local-lounge.js](/home/raja/Anuraj-dev/Frontend/src/lib/local-lounge.js:1).
- Data stays in this tab's sessionStorage; unsupported operations return an explicit fixture error. Admin access is not granted. External destinations use `example.invalid`.
- `local-region=2` exercises Delhi NCR; `local-region=21` International; `local-tour=1` starts a fresh-tour fixture. Fixture state is separated by region/tour scenario. Clear the matching `sundarbans-local-lounge:*` sessionStorage entry to reset it.
- Production bundle inspection found no synthetic identity or fixture module, and the production browser test confirms the query flag still redirects an anonymous visitor to login.
- Server PID **995098**, port **5202**, started by this session. Leave port 5210 and other projects' servers alone.

Run the focused checks with the dev server active:

```sh
LOCAL_LOUNGE_TEST_URL='http://127.0.0.1:5202/?local-lounge=1' node node_modules/@playwright/test/cli.js test e2e/local-lounge.spec.js --workers=1
```

The two development tests skip in the normal suite unless that variable is supplied; the production security check always runs.

## Fix first

### 1. Certificate-name confirmation is unreachable before issuance — high priority, source-confirmed

Issuance requires a confirmed certificate name. `list_my_certificates` returns issued rows only, and the confirmation UI requires a selected issued certificate. An eligible member without a name therefore cannot reach the action that would create their first certificate. Both popup and routed certificate page have the same dependence. `needs_certificate_name` is present on the event payload but no event action exposes it.

Evidence: [SQL issuance](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261009150200_attendance_certificates_notices.sql:63), [certificate list](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261009150200_attendance_certificates_notices.sql:127), [popup](/home/raja/Anuraj-dev/Frontend/src/components/lounge/CertificatesPopup.vue:20), [confirmation guard](/home/raja/Anuraj-dev/Frontend/src/components/lounge/CertificatesPopup.vue:182), [event action](/home/raja/Anuraj-dev/Frontend/src/components/lounge/EventDetail.vue:64).

Expose a pending certificate/name-confirmation action on the eligible event and in My certificates. Test release with no name → confirmation → issuance → download. This scenario was not run against a live issued certificate.

### 2. Attendance verdict disagrees with the backend — high priority, Chrome-reproduced

A synthetic 1,170-second attendance record shows **“Attended · 20 min”** and the detail says the member was in the call for 20 minutes. Backend eligibility requires at least 1,200 seconds. `minutesOf` rounds, and `markOf` uses the rounded minutes as an independent eligibility test. That shortcut can also override a reviewed-ineligible verdict.

Evidence: [attendance helpers](/home/raja/Anuraj-dev/Frontend/src/components/lounge/events.js:91), [SQL threshold](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261009150200_attendance_certificates_notices.sql:72), [Chrome screenshot](/tmp/sundarbans-e2e-audit/attendance-1170s-phone.png).

Use exact seconds or reviewed eligibility for the verdict; format minutes separately. Test 1,169/1,170/1,199/1,200 seconds and both reviewed states. The generic certificate renderer also invents a 20-minute duration when absent; this is a latent fallback issue, since current signed-template rendering does not print that claim. Evidence: [fallback mapping](/home/raja/Anuraj-dev/Frontend/src/components/lounge/events.js:128), [generic certificate](/home/raja/Anuraj-dev/Frontend/src/components/lounge/cert.js:181).

### 3. Live event lifecycle freezes until refresh — high priority, source-confirmed

The RPC serializes `stage` at hydration. `status()` returns it before comparing the minute clock with start/end timestamps. A loaded upcoming event does not become live, and a loaded live event does not become past. Cancelled events remain listable and the member controls can still offer Join/Register. Register also uses `accepting_responses || is_open`, overriding an explicit false availability result.

Evidence: [RPC](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261009150200_attendance_certificates_notices.sql:143), [status](/home/raja/Anuraj-dev/Frontend/src/components/lounge/events.js:66), [registration control](/home/raja/Anuraj-dev/Frontend/src/components/lounge/EventDetail.vue:57), [server submit gate](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261009150100_lounge_events_forms.sql:112).

Derive scheduled lifecycle from timestamps, honor cancellation explicitly, and preserve `accepting_responses:false`. Add time-advance and cancellation tests. These were source-reviewed, not clock-advanced in Chrome.

### 4. Historical events show fabricated 1970 dates — high priority, Chrome-reproduced

The Lounge metadata line respects `display_date`, but its date tile, year grouping, and detail span use `new Date(null)`. An undated archive with “September 2024” appears under **1970 / 1 Jan**. All 43 live archive rows have null schedules, so this is material to the imported archive, not merely a rare fixture shape.

Evidence: [tile](/home/raja/Anuraj-dev/Frontend/src/components/lounge/events.js:227), [grouping](/home/raja/Anuraj-dev/Frontend/src/components/lounge/EventsPage.vue:451), [detail span](/home/raja/Anuraj-dev/Frontend/src/components/lounge/events.js:215), [desktop screenshot](/tmp/sundarbans-e2e-audit/member-archive-dark-desktop.png), [phone screenshot](/tmp/sundarbans-e2e-audit/member-archive-light-phone.png).

Share the public archive's date-precision handling with Lounge. Preserve original text and use an explicit undated state; never manufacture a day or year.

### 5. Corrected attendance imports retain removed participants — high priority, SQL/test-confirmed

Reimports upsert rows but do not reconcile omitted identities. The existing pgTAP case imports three identities, then only one, and still expects three records. An omitted previously eligible attendance row can continue to support issuance. The UI previews absentees but submits only import rows.

Evidence: [import](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261009150200_attendance_certificates_notices.sql:36), [test](/home/raja/Anuraj-dev/Frontend/supabase/tests/020_member_lounge_test.sql:173), [UI submission](/home/raja/Anuraj-dev/Frontend/src/components/admin/AdminEvents.vue:594).

Choose explicit merge versus replace semantics, preserve import provenance, preview removals, and reconcile atomically before certificate release. Do not silently delete all event records if multiple source sheets are valid. Exact duplicate masked rows also collapse in storage while the preview counts each line; preserve a source-row identity for unresolved records.

### 6. CSV exports can lose answers or create malformed headers — high priority, deterministic probe-confirmed

Distinct fields sharing a label overwrite each other because export row objects use labels as keys. Edited schemas reuse a key under the first encountered label. Header text bypasses CSV quoting and formula-prefix protection even though data values are protected.

Evidence: [export mapping](/home/raja/Anuraj-dev/Frontend/src/lib/admin.js:547), [CSV encoder](/home/raja/Anuraj-dev/Frontend/src/lib/admin.js:341), [probe](/tmp/sundarbans-e2e-audit/probe-csv.mjs), [probe result](/tmp/sundarbans-e2e-audit/csv-probe.json).

The probe confirmed a comma-bearing label creates a malformed header, `=1+1` remains an active formula header, and two “Same label” fields retain only the second answer. Use stable column identities, schema-aware mapping, disambiguated labels, and the same safe CSV encoder for headers and values.

### 7. Member filters conflict with the current requested flow — medium priority, Chrome-reproduced

A Patna fixture shows a Delhi NCR filter and unrelated cohort options, including when browsing Live/Upcoming. Regional upcoming/live access is enforced server-side; public past-event visibility across regions is an intentional rule. The defect is the student filter UI, not proof of cross-region upcoming-event access.

Evidence: [filter controls](/home/raja/Anuraj-dev/Frontend/src/components/lounge/EventsPage.vue:103), [global chip/options derivation](/home/raja/Anuraj-dev/Frontend/src/components/lounge/EventsPage.vue:337), [audience enforcement](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261009150100_lounge_events_forms.sql:50), screenshots above.

Keep audience targeting in organizer controls. For members, remove term/cohort browsing controls per Raja's current direction; show house-wide/own-region choices only if useful. Preserve the agreed public historical archive.

### 8. WhatsApp discovery needs a coherent catalog and application states — medium priority

- **Chrome-reproduced:** reopening a submitted form loses its invite link; the routed page only says “You already sent this one.” Home still contains the submitted invite. [FormPage.vue](/home/raja/Anuraj-dev/Frontend/src/pages/FormPage.vue:19), [reload screenshot](/tmp/sundarbans-e2e-audit/submitted-form-reload-phone.png).
- **Snapshot/source-confirmed:** Cultural has no prepared invite; once submitted, it disappears from both open applications and invite boats. Group loading errors are also collapsed to an empty list. [group loader](/home/raja/Anuraj-dev/Frontend/src/lib/lounge.js:81), [hydrate](/home/raja/Anuraj-dev/Frontend/src/components/lounge/session.js:89). Cultural's current live invite was not individually queried.
- **Source-confirmed:** membership boats depend on ten hardcoded source UUIDs; newly created group forms need a frontend release to appear. [catalog](/home/raja/Anuraj-dev/Frontend/src/lib/lounge.js:61).
- **Source gaps:** approved house-wide membership source/link is missing; Hyderabad/Lucknow forms were inaccessible, International source not found. Do not invent replacements or use the public WhatsApp channel as a private group substitute. [handoff](/home/raja/Anuraj-dev/Frontend/docs/handoffs/2026-10-09-lounge-backend-opus.md:67).
- **Fresh data/source-confirmed:** every form description exceeds 150 characters; six titles exceed 50. Full application titles/descriptions are used on compact boats. These lengths are allowed by the schema but poor display copy. [boat mapping](/home/raja/Anuraj-dev/Frontend/src/components/lounge/home/MooredBoats.vue:126).
- **Chrome-reproduced design discontinuity:** a day-theme Lounge application opens under the public shell/site theme, with a public WhatsApp channel link and Lounge navigation leading to login. The route is functional, but the visual/navigation context changes abruptly. [shell classification](/home/raja/Anuraj-dev/Frontend/src/App.vue:31).

Use a server-maintained group purpose/type, short display name/purpose, and explicit available/applied/invite-unavailable states. Keep public channel, house membership, regional group, community application, and recruitment distinct. Submission remains an application, not admission; no verified WhatsApp membership integration exists.

## Further findings by audit owner

Each row is a condensed individual report. “Source” means inspected contracts, not live reproduction. Primary-agent reproductions are identified in the priority sections above.

| Audit | Scope | Additional result and evidence |
| --- | --- | --- |
| Frontend 01 | Lounge Events filters/audience | Other-region and global cohort controls confirmed; no evidence they bypass backend audience rules. [EventsPage](/home/raja/Anuraj-dev/Frontend/src/components/lounge/EventsPage.vue:337) |
| Frontend 02 | WhatsApp discovery | Missing-invite applications disappear; raw source copy and incomplete regional coverage; no duplicate boat path found. [open forms](/home/raja/Anuraj-dev/Frontend/src/components/lounge/session.js:204) |
| Frontend 03 | Public archive/filter styling | Region-only log filter leaves all chart bubbles active; filter URL state is transient; timestamp formatting follows visitor timezone. Gallery support was not found, but is not a defect without a requirement. [chart IDs](/home/raja/Anuraj-dev/Frontend/src/pages/EventsPage.vue:180), [date formatting](/home/raja/Anuraj-dev/Frontend/src/lib/events.js:97) |
| Frontend 04 | Auth/router/dialogs | Account changes retain previous profile/role while async loading runs; overlapping results can overwrite newer identity. Clear identity caches and apply only results matching current UID. Server access remains separate. Runtime race unverified. [auth](/home/raja/Anuraj-dev/Frontend/src/lib/auth.js:99) |
| Frontend 05 | Profile/region/tour | Initial-region RPC returns no joined region; client retains old relation and does not refresh regional data. Cancelled initial picker has no profile reopen action. Clearing preferred name falls back to roster name despite empty-name copy. Current region can be selected as a correction; retake-tour errors are unsurfaced. [region save](/home/raja/Anuraj-dev/Frontend/src/components/lounge/session.js:135), [picker](/home/raja/Anuraj-dev/Frontend/src/components/lounge/RegionSelect.vue:27), [display name](/home/raja/Anuraj-dev/Frontend/src/components/lounge/state.js:36) |
| Frontend 06 | Forms/registration | Required multiselect has no client validation; server rejects empty selection after submission. Submitted-form invite revisit gap. [fields](/home/raja/Anuraj-dev/Frontend/src/components/lounge/FormFields.vue:52) |
| Frontend 07 | Notices/certificates | Name-confirmation dead end; exact-threshold mismatch; generic duration fallback. Partial mark-all-read failures leave UI stale; read/dismiss errors swallowed. Future-notice fallback lacks lower time bound, but current RPC prevents that path. [notice operations](/home/raja/Anuraj-dev/Frontend/src/components/lounge/session.js:177) |
| Frontend 08 | Admin workflows | Edit/Attendance/Remove actions and event form options appear for readable events the organizer cannot manage; server denies them. Form badges use `is_open` instead of effective availability. [actions](/home/raja/Anuraj-dev/Frontend/src/components/admin/AdminEvents.vue:39), [form status](/home/raja/Anuraj-dev/Frontend/src/components/admin/AdminForms.vue:20) |
| Frontend 09 | Public navigation/directory | Region meetup redirects drop region; Teams region nodes just scroll generic council section; selected Lounge room lost through sign-in; community wing filter transient; public shell lacks skip link; Home navigation buttons lose normal link behavior. [redirects](/home/raja/Anuraj-dev/Frontend/src/router/index.js:46), [room link](/home/raja/Anuraj-dev/Frontend/src/components/site/LoungeDoor.vue:13), [shell](/home/raja/Anuraj-dev/Frontend/src/App.vue:13) |
| Frontend 10 | Study Resources/accessibility | Course modal lacks focus trap/restore; tabs lack panel linkage/keyboard model; search lacks full combobox semantics; PYQ empty state says notes; closing ignores reduced motion. Bare grid tracks are a design-contract concern, not measured overflow; screenshot sweep found none. Interaction tests missing. [sheet](/home/raja/Anuraj-dev/Frontend/src/components/site/CourseSheet.vue:172), [close animation](/home/raja/Anuraj-dev/Frontend/src/components/site/CourseSheet.vue:264), [search](/home/raja/Anuraj-dev/Frontend/src/components/site/SearchBar.vue:10) |
| Backend 01 | Event audience/cohorts | Archive flag permits a future-scheduled row to become public; live aggregate found **zero** such rows. Unknown cohort cannot see targeted events. Options derive from claimed members, omitting older roster-only cohorts. Accepted cohort domain and UI options differ. [archive constraint](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261009150100_lounge_events_forms.sql:24), [cohort options](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261009150100_lounge_events_forms.sql:33) |
| Backend 02 | Form/group model | Admin editing omits `source_url`; SQL upsert overwrites it with null. Group classification client-only, no source uniqueness constraint or archival workflow. Existing live sources are unique. Invite changes lack explicit removal UI. [editor payload](/home/raja/Anuraj-dev/Frontend/src/components/admin/AdminForms.vue:469), [upsert](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261009150100_lounge_events_forms.sql:144) |
| Backend 03 | Roster/member hygiene | Unknown nonblank region values silently become null. Concurrent same-email imports can both report added despite one insert losing and conflicting region being discarded. Email normalization, four domains, optional phone, pagination and sequential import idempotency look sound. [mapping](/home/raja/Anuraj-dev/Frontend/src/lib/admin.js:222), [insert conflict](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261009150000_member_lounge.sql:50) |
| Backend 04 | Attendance/issuance | Stale omitted rows and collapsed identical unresolved rows. Suggested export scope race was rejected after independent review: see below. Exact eligibility, registration locks and issuance uniqueness are tested. [attendance](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261009150200_attendance_certificates_notices.sql:36) |
| Backend 05 | Roles/approvals/privacy | Bulk roster result reveals global email-existence status to RCs, bypassing single-add opaque response. Scoped admins can directly read soft-deleted own-scope events despite older hide policy intent. Invite audit omits a redacted change indicator. Two-person approvals/current-role checks verified in source/tests. [bulk result](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261009150000_member_lounge.sql:70), [event read policy](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261009150100_lounge_events_forms.sql:76) |
| Backend 06 | Notice lifecycle | Notice link stored but never rendered; Admin list stops at 200 with no pagination. Community scope controls organizer ownership but not recipient membership: resolve intended audience before changing access. Expiry suppresses banner while history remains, consistent with spec. [member panel](/home/raja/Anuraj-dev/Frontend/src/components/lounge/NoticesPanel.vue:50), [limit](/home/raja/Anuraj-dev/Frontend/src/lib/admin.js:733), [audience RPC](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261009150200_attendance_certificates_notices.sql:186) |
| Backend 07 | Imported source quality | 43 unique event source keys; 3 meetup duplicates intentionally excluded from public archive; 2 source dates unparseable into year/month. 17/19 listed form sources ported, 2 explicitly unavailable; 131 fields valid and unique by key. Stale `imported:false` metadata not evidence of failure. No guessed dates/contacts/invites. [public date mapper](/home/raja/Anuraj-dev/Frontend/src/lib/events.js:107), [archive exclusion](/home/raja/Anuraj-dev/Frontend/src/lib/events.js:145) |
| Backend 08 | Schema/response export | CSV key/label collisions and unsafe headers reproduced by primary. Server allows whitespace-only/overlong Other suffix, unlike UI's trimmed 300-character contract. Unknown keys, required answers, option membership and phone-save consent are enforced. [Other validation](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261009150100_lounge_events_forms.sql:183) |
| Backend 09 | Erasure/retention | Hard delete leaves approval reasons/non-answer requested changes containing identity data; prior audit rows also retain personal data. Redact approval fields and settle audit retention. Existing certificate name corrections preserve old issued names; cancellation does not revoke certificates: product rules, not automatically defects. [hard delete](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20260928193310_wrong_state_http_409.sql:632), [audit creation](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261008155946_admin_panel_backend.sql:354) |
| Backend 10 | Adapter contracts/test gaps | Stage freeze, cancellation controls, null-date archive, availability false override, rounded eligibility. Exact zero attendee count is nulled by `|| null`. Independently rejected suspected export race. [save count](/home/raja/Anuraj-dev/Frontend/src/lib/admin.js:425) |

## Fresh aggregate data findings

Queried read-only on 2026-10-09, approximately 23:40 IST; values may change as real members sign in.

| Data | Observed |
| --- | --- |
| Members | 5; 2 null cohorts; 0 null regions; all 5 certificate names unconfirmed; no unnormalized emails |
| Pending roster | 3,803; all names blank; 2 null regions; no unnormalized emails |
| Events | 43 archives; all 43 null schedule; all have display_date/source_key; 0 future-ended archives; 8 missing images; 22 approximate turnout values |
| Public view versus page | View has 43; public adapter intentionally excludes 3 meetup rows → 40, not missing imports |
| Event scopes | 40 null regions; 21 null communities; these house/community scopes are not automatically bad data |
| Forms | 17 total, 15 published, 11 regional, 4 community, 2 house, 0 event forms; 0 missing sources, duplicate source groups, or empty schemas |
| Compact-card copy | All 17 descriptions >150 characters; 6 titles >50 |
| Operational readiness | 0 event registrations, attendance records, issued certificates, or certificate templates; 1 notice |

Blank roster names are intentional in the chosen email-only source and optional-name design. Two unallocated students and two unknown member cohorts need source-aware review, not guessed values. The zero operational counts mean real imported registration/attendance/issuance has not been demonstrated; local fixtures and SQL tests exercise those contracts instead.

## Proposed cleanup order

1. Fix the student contracts: exact attendance verdict, pending certificate-name action, lifecycle/cancellation, and date precision. These are functional correctness issues.
2. Simplify member Events to their relevant view. Keep term/region targeting in organizer controls. Reconcile member filters with the new direction without altering public historical visibility.
3. Establish one WhatsApp catalog with short display copy, purpose/type, scope, source identity, and application state. Preserve private invites and manual admission; show unavailable sources explicitly.
4. Repair import/edit/export integrity: preserve source URLs, block unknown region labels, clarify attendance replacement, disambiguate versioned fields, escape headers, and retain unresolved source-row identities.
5. Improve operational feedback: manageable-only Admin actions, effective form status, links in notices, recoverable loading/read errors, and region refresh/reopen behavior.
6. Settle retention/revocation/community-notice rules before changing data semantics. Then add the missing lifecycle, boundary, schema-change, account-switch and keyboard regression checks.

## Findings rejected or limited after integration review

- **Export scope race not established.** `export_event_records` is a `STABLE` PL/pgSQL function; its reads use the calling query's fixed snapshot. A concurrent scope commit between internal reads does not produce the hypothesized mixed authorization/data snapshot. [Function](/home/raja/Anuraj-dev/Frontend/supabase/migrations/20261009150200_attendance_certificates_notices.sql:135), [PostgreSQL volatility documentation](https://www.postgresql.org/docs/current/xfunc-volatility.html). Do not count this as a confirmed vulnerability.
- Missing multi-image gallery, certificate revocation after event cancellation, and audit retention require an agreed requirement. They are decision points, not proven implementation defects.
- Bare `1fr` tracks and visitor-timezone behavior are source concerns; no actual overflow was found by the screenshot sweep, and India-based Chrome did not test foreign timezones.
- Historical events from other regions are intentionally public. Their presence is not an access-control failure.

## Artifacts

Real Chrome screenshots and the synthetic CSV probe are in [/tmp/sundarbans-e2e-audit](/tmp/sundarbans-e2e-audit). Test command outputs are `/tmp/sundarbans-audit-{build,final-e2e,backend,bypass,shots-final}.log`; generated public route shots are `test-results/shots/`. These local artifacts are temporary and uncommitted.

![Phone: unrelated region/cohort controls and 1970 archive tile](/tmp/sundarbans-e2e-audit/member-archive-light-phone.png)
