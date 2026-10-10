# Non-certificate audit fixes — 2026-10-10

## Result

Implemented the actionable non-certificate findings from [the original twenty-worker audit](2026-10-09-local-e2e-audit.md) in the local checkout. Independent Standards and Spec reviews found no remaining verified actionable non-certificate issue after corrections. Certificates are deferred as requested. Nothing was committed, pushed, deployed, or written to the live database.

This checkout already contained substantial uncommitted work. Review compared the changes with the captured starting checkout at `/tmp/sundarbans-fix-baseline`, rather than attributing all changes since Git HEAD to this task. Existing work was preserved.

## Fixed behavior

| Area | Result |
| --- | --- |
| Member Events filters | Removed cohort/term and region browsing controls. Organizer audience targeting remains; historical events retain the agreed public visibility. |
| Attendance display | Exact seconds determine Meet verdicts, with reviewed verdicts respected separately. 1,169/1,170/1,199 seconds remain below the threshold; 1,200 qualifies. Duration formatting no longer rounds 19m30s into an attended verdict. |
| Event lifecycle | Scheduled status follows the clock instead of stale serialized stage. Cancelled events have no Join/Register action. Explicit `accepting_responses:false` is respected. |
| Archive dates | NULL schedules preserve source text and date precision, with undated states. Lounge year groups and tiles no longer invent January 1970. Scheduled/public dates use Asia/Kolkata. |
| Group catalog | Server metadata distinguishes general forms, group applications, and recruitment. Short group labels/purposes replace full application titles on boats; the frontend UUID allowlist is removed. The migration classifies only ten previously verified membership sources. |
| Application state | Applied groups remain visible with available, unavailable, or failed invite retrieval states. Routed forms reload their invitation after submission, retain the Lounge shell/theme, and explain that applying is not admission. Public channel links remain separate. |
| Profile and region | Preferred name is optional and independent of roster/certificate name; unset or cleared preferred name shows no name. Initial region selection rebuilds the joined relation and refreshes regional data. Profile can reopen the picker; no-op correction is blocked. Tour failures surface. |
| Auth | Identity/role caches clear synchronously on account change. Late profile/hydration results cannot replace the current member. A stalled old profile cannot hold a guard waiting for a newer session. |
| Forms | Required multiselect and trimmed, capped Other answers are validated accessibly in the client and at the API. Source URLs survive edits. Canonical duplicate source URLs are rejected. Archive/restore controls enforce member discovery/submission rules while organizers and prior responders retain history. Invite removal is explicit, and its audit records only a change boolean. Current regional audience still gates private invite retrieval. |
| Attendance imports | Default merge preserves omitted rows; explicit replace reconciles only the named source, with a preview and confirmation. Masked rows keep source-row identities. Canonical identities shared by sources retain source ownership. Conflicting durations/verdicts across shared sources fail closed for reconciliation, including edits by an already shared source. Released attendance stays locked. |
| Roster integrity/privacy | Unknown nonblank region labels block import. Canonical email locking serializes concurrent single/bulk additions. RC bulk replies use an opaque `processed` result for both new and known identities; UI does not claim all processed identities were added. SA results retain accurate added/existing classification. |
| CSV | Captured schemas distinguish duplicate labels and renamed fields. Header and data values share quoting/formula protection. Exact zero attendee counts survive edits. |
| Organizer scope | Event actions and event-bound form options appear only for manageable scopes. Deleted events are visible/restorable only to SAs; scoped organizers remove owned events through a guarded RPC. Future-scheduled archive records are rejected after permission checks. |
| Cohorts | Options include older roster-only cohort prefixes, are unique, and align with calendar bounds. Duplicate/out-of-domain audience selections are rejected. Unknown allocation is preserved rather than guessed. |
| Notices | Saved links render. Mutation failures surface and partial mark-all-read failures reconcile server state. Future/expired banner bounds are enforced. Admin has paging beyond its first batch. Community scope copy describes publisher ownership and the actual house/cohort reach. |
| Erasure | Hard deletion clears approval snapshot, requested changes, reasons, and review notes in application tables without copying that free text into new audit rows. Historical immutable audit rows are preserved; see policy limits below. |
| Public navigation | Wing/region/search filters affect chart and log consistently and survive reload via URLs. Legacy meetup links retain region. Teams links select the intended region/community. Contact links land on the existing council section. Home navigation uses links; public pages expose a working skip link. Selected Lounge room survives the login doorway. |
| Resources accessibility | Course sheet traps/restores focus and inerts its background. Tabs have linked panels/keyboard navigation; PYQ empty copy is accurate. Search implements the combobox model, excluding both options and Chrome's scrollable listbox container from Tab order. Reduced motion skips close animation; flexible grid tracks avoid long-content expansion. |

Implementation pointers: `src/lib/auth-profile.js`, `src/components/lounge/session.js`, `src/components/lounge/events.js`, `src/lib/lounge.js`, `src/pages/FormPage.vue`, `src/lib/admin.js`, `src/components/admin/`, `src/components/site/`, and `supabase/migrations/20261010000000_audit_fixes.sql`.

Historical migrations were not rewritten for these fixes. The new migration must be applied together with the matching frontend before these backend/catalog changes can work on a deployed site.

## Fresh verification

| Gate | Final result |
| --- | --- |
| Production build | Exit 0 |
| Full Playwright, including enabled loopback fixture tests | **86 passed**, exit 0 |
| Disposable PostgreSQL/Supabase | **232 pgTAP assertions + 9 concurrency cases**, exit 0 |
| Full ESLint | Exit 0 |
| Prettier | All 54 changed source/test files compared with starting checkout passed; full-repo formatting was not run |
| Design guard | Passed |
| Study-data guard | Passed: 23 courses, 567 notes, 1,498 PYQs |
| Screenshot sweep | 36 light/dark desktop/phone screenshots; no page errors or sideways overflow. Anonymous Lounge shows Login; member flows were checked separately in Chrome. |
| Diff whitespace | Passed |
| Independent Standards review | Reported access, provenance, combobox and archive gaps were corrected and rechecked; no remaining verified production finding |
| Independent Spec review | No remaining verified actionable non-certificate finding against the original audit |

The earlier failing runs were repaired, not hidden: SQL attendance grouping and fixture setup, archive RLS/test expectations, independent concurrency secret setup, old roster/attendance assertions, and a host-clock `pauseAt` race. The clock test now installs an explicit time and pauses at a future value before testing route teardown. No retry was used to obtain the final green Playwright run.

Real Google Chrome checked the synthetic member Events on desktop/390×844 in day/night: relevant controls, 19m30s verdict, and month-only archive detail/year. It also checked routed group submission and reload with the Lounge shell/theme, and public dark-theme heading contrast. A clean load of Resources verified Tab leaves search results, Enter opens the course sheet, and focus stays in its modal. Development HMR had stale router bindings during concurrent edits; browser checks were repeated after a clean load.

Logs: `/tmp/sundarbans-fix-{build,e2e,backend,lint,format,design,study,shots}.log`. Real Chrome screenshots: `/tmp/sundarbans-fixes/`. Production route shots: `test-results/shots/`. These are temporary local artifacts.

## Deferred and unavailable inputs

- **Certificates:** confirmation before issuance, renderer duration/name behavior, certificate-name correction/revocation policy, and certificate download integration remain for the later certificate task. `CertificatesPopup.vue`, `cert.js`, `CertificatePage.vue`, and `VerifyPage.vue` remain byte-identical to the starting checkout. Existing certificate assertions passing is not a claim these known certificate gaps are solved.
- **Authentic source gaps:** approved house-wide group source/invite is missing; Hyderabad/Lucknow sources were inaccessible; International source was not found. Eight archive images, two unparseable date labels, two unknown roster regions, and two unknown member cohorts need authentic source information. No replacements, dates, images, member allocations, or invitations were invented. Prior read-only aggregate counts are in the original report; live data was not changed or re-audited in this correction task.
- **Policy limits:** community notice ownership is not verified WhatsApp membership. The UI now states its actual reach, while recipient-membership restrictions still need a product rule. Historical immutable audit retention remains a product/security decision; this task redacts operational request tables and avoids new erasure-related free-text copies, but does not rewrite old audit history. A gallery was not an established requirement. The suspected STABLE export-snapshot race remains rejected.
- **Environment limits:** local synthetic/mocked browser tests and real disposable PostgreSQL tests do not prove live OAuth, real signed-in Admin writes, external WhatsApp admission, deployed rollout, or every assistive-technology combination. No production authentication bypass exists.

## Local review

Open `http://127.0.0.1:5202/?local-lounge=1#/lounge`. The dev-only synthetic member has no Admin role and makes no Supabase writes. `local-region=0` exercises initial selection; region/tour scenarios have separate fixture storage. Production ignores this flag. Dev server PID 995098 remains available; unrelated port 5210 and other project/database processes were left alone.

![Applied group remains available after reload in the Lounge theme](/tmp/sundarbans-fixes/group-applied-invite-light-phone.jpg)
