# Backend data and access decisions

Status: design confirmed by Raja, 2026-10-09. Q1–Q30 and the consolidated design review
are complete. Keep individual answers separate from inherited rules and derived defaults. Implementation, live imports,
role changes and deployment are not authorized by this interview.

## Confirmed decisions

### Q1 — Initial member roster

Use the 3,808 unique emails from the **Sundarbans Members** workbook, **Members** tab,
**Student_Email** column. Repeated email rows represent one member, not additional accounts.
Raja confirmed this after checking the source and duplicate counts.

The reviewed export contains 7,608 data rows: 3,800 emails occur twice and 8 once.
The count is from this sheet alone, not the allocation comparison. Private source evidence:
`~/Anuraj-dev/sundarbans-imports/2026-10-08/user-current-email-source/primary-review.md`.

The 281 allocation-only identities are outside this chosen initial import. Their later
eligibility and any changes to existing accounts remain unresolved; no automatic removal
or suspension was agreed.

### Q2 — Optional, editable student name

A student's name is optional. Ask for it at first Lounge entry, allow skipping, and
save it when supplied. A student may add or edit their name later. A missing name must
not prevent account provisioning or Lounge access.

This revises the earlier requirement for a real full name before account creation.
The current backend's required-name contract must change during implementation.
Raja did not select automatic Google-name prefilling; do not assume it is agreed.
Final-review default: retain the existing optional profile fields; do not require a
name until a form/certificate actually needs one. Keep certificate-name confirmation
separate from freely editable Lounge names, following the existing Lounge spec.

### Q3 — Optional phone with explicit saving from forms

Phone is completely optional and must not block account provisioning or Lounge access.
Expose an optional phone field in Edit profile for members to supply/edit their number.

Future event or community WhatsApp application forms that ask for a phone number offer
a checkbox labelled **Save your phone number for later**. Checking it saves the submitted
number to the member's profile for prefilling future phone fields. An unchecked box must
not update the saved profile phone; it does not decide whether the form response itself
retains the submitted number.

The pulled backend already supports optional phone, with unique E.164 values when
supplied; member profile editing and form save consent still need implementation.
Q30 confirms saved profile phone and name prefill the corresponding form fields.
Retain existing validation as a default; no additional phone verification is selected.
Form-specific required fields follow the original form being ported.

### Q4 — All four roster domains are eligible

Allow DS, ES, MG and AE domains, restricted to exact emails on the approved roster.
The selected roster contains DS 3,534, ES 146, MG 100 and AE 28 unique emails.
A matching domain alone does not grant Lounge membership.

The last backend inspection found DS-only provisioning rules; those rules need changing
during implementation. Non-DS roll/member-code derivation remains a separate question.

### Q5 — International is a region without an RC

Add International as a distinct region, preserving the source allocation. Raja explicitly
confirmed there is no Regional Coordinator for International; do not assign or invent one.
An International member's region must not depend on a coordinator assignment existing.

Source: Sundarbans House Allocation, `Sheet1`, column D (`Allocated_Region`), where
12 cells contain the literal value `International Region` (e.g. D13). Eight of those
allocation emails are in the selected 3,808-email roster. The saved XLSX was rechecked
directly during the interview. This is a planned tenth region; no live region was added.
Any International WhatsApp group remains a separate decision.

### Q6 — Students with unknown allocation select their region

The four approved roster students without an allocation match are asked to choose their
own region at first Lounge entry. Save their selection from the supported region list,
including International. Do not invent an allocation for them.

This is the initial region-selection flow for missing allocations, not permission for
every member to change an existing region freely. Whether selection may be skipped
remains unresolved; later corrections follow Q7/Q8.

### Q7 — Later region changes require approval

Once a region is set, a member requests a change and an admin must approve it. This
applies to both imported allocations and initially self-selected regions. The saved
region remains unchanged until approval; members cannot directly edit it in their profile.
Q6's initial selection for missing allocations remains allowed.

### Q8 — Current-region RC or UHC approves

A region-change request may be approved by the member's current-region RC or UHC.
UHC handles members in International and any other region without an RC. The target
region's RC is not an additional required approver in the selected workflow.

Approval authority is based on the member's saved current region, not a new region
they request. A request cannot itself change the saved region or grant operator powers.
Regional permissions must continue to reflect the saved region until approval.

### Q9 — UHC super-admin access (appointment rule revised by Q17)

Secretary, Deputy Secretary and Web Admin receive super-admin access: house-wide member
access, role assignments, account controls and approval powers. Raja initially allowed
adding additional super admins, then explicitly replaced that rule in Q17: exactly
three fixed super-admin email accounts, with changing office-holders.

Explicit role assignment remains separate from importing public directory titles.
Verify the three intended email identities; no roles have been granted during this
interview. Term handover and permanent-deletion policy are later questions.
This supersedes the glossary's earlier implication that only WebAdmin is a super admin.

### Q10 — Zero to two active RCs per region

Each region may have a minimum of zero and a maximum of two active RCs. A region may
have none while recruitment is ongoing; having an RC is not required for the region
or its members to exist. International currently has zero RCs, per Q5.

Raja expressed the limit in terms of RCs, rather than unlimited additional regional
admins. Preserve the two-RC cap. Appointment remains a super-admin action from the Q10
brief; public directory imports do not automatically grant access.

The backend's one-active-RC-per-region constraint needs changing during implementation.
Where no RC is assigned, region-change approvals are handled by UHC, per Q8.

### Q11 — One active regional/community admin role per person

A person may hold only one active regional/community admin role at a time. For example,
an active RC cannot simultaneously be a community Head or Co-Head. This preserves the
backend's one-active-scoped-position-per-member rule; Q10 still permits up to two
different active RCs per region.

This limits admin assignments, not ordinary community membership or public team listings.
Whether a super admin can additionally hold a scoped office remains a separate issue;
the current backend rejects scoped assignments to super admins.

### Q12 — RC event management is restricted to the assigned region

RCs may create and edit only events owned by their assigned region. Super admins manage
house-wide events and may manage events in any region. International has no RC, so its
events are managed by super admins while that remains the case.

The inspected backend has no event region field and lets RCs manage all house-wide
events. Add explicit regional event ownership and enforce the chosen scope in backend
policies during implementation. Publication approval and audience are separate decisions.

### Q13 — RCs publish regional events directly

An RC may publish events belonging to their assigned region without prior UHC approval.
Use an explicit Publish action; saving a draft does not make it visible in event listings.
Super admins retain oversight and management access under Q12.

The inspected backend exposes non-deleted public event fields immediately and has no
draft/publish state. Publication state and matching visibility policies need implementing
alongside regional ownership. Published-event editing and unpublishing remain follow-ups.

### Q14 — Roster-gated account creation at first Google sign-in

Keep the pulled account-creation flow: add approved emails to the roster, then create
each student's account on their first Google sign-in. The interface remains sign-in
only; unlisted emails are refused. This supersedes the earlier requirement to pre-create
all Auth accounts and is recorded in `../adr/0001-roster-gated-first-sign-in.md`.

Q1's initial 3,808-email list, optional-name/phone requirements, four-domain support and
initial region selection remain unchanged. Existing accounts remain intact; no roster
import or live account changes were performed as part of accepting this decision.

## Pulled implementation — 2026-10-09

Raja requested updating local main from the refreshed fork, then continuing the interview
against that code. Local `main` now matches `origin/main` at `6f1c908` (also `upstream/main`).
Earlier answers remain requirements; pulling code does not silently supersede them.

| Area | Pulled code | Interview impact |
| --- | --- | --- |
| Sign-in | Supabase client, Google sign-in, member/admin guards and Admin lounge exist | Earlier notes saying no frontend backend code are obsolete |
| Account creation | `member_roster` gates first Google sign-in; trigger creates the member and consumes the pending row | Accepted in Q14, superseding pre-created-account direction |
| Names/regions | Roster add still requires full name and valid region | Q2 optional names and Q6 initially unknown regions still need changes |
| Phone | Database/roster/admin phone is optional; supplied values remain unique and E.164 | Core Q3 optionality exists; member profile editing and form save checkbox remain to implement |
| Domains | Checked-in domain seed remains DS-only; Google sign-in hints DS | Q4's DS/ES/MG/AE support still needs changes |
| Approval | Admin student-data/status/position/email changes require approval by a different super admin | Reconcile Q8 allowing current-region RC approval and future self-service flows |
| RC slots | One active RC per region; one scoped position per person | Q10's two-RC limit needs change; Q11 matches current constraint |
| Events | RCs may create/edit all events; no regional ownership or draft/publish state | Q12/Q13 remain unimplemented requirements |
| Lounge data | Real session, roll and region are wired; preferred name editing still uses local state and other features use fixtures | Persist names, phone, tour, notices, groups, attendance and certificates later |

Evidence: `docs/specs/003-admin-lounge-and-sign-in.md`, `src/lib/{auth,admin}.js`,
`src/components/admin/AdminRoster.vue`, `src/components/lounge/{ProfileEdit.vue,state.js}`,
and migrations `20261008120100_admin_panel_backend.sql` / `20261008130000_optional_phone.sql`.
These are source observations, not fresh proof of live deployment or real OAuth behavior.
The five newly pulled migration filenames differ from recorded cloud versions; see the
existing 2026-10-09 session log before any separately authorized migration push.

### Q15 — Student-initiated region corrections retain RC/super-admin approval

Retain the Q7/Q8 correction flow after inspecting the new code: the student files a
region-change request, and their current-region RC or a super admin may approve it.
Super admins handle regions without an RC, including International. The saved region
does not change until approval.

This is a deliberate exception to the pulled admin workflow requiring an admin to file
the change and a different super admin to approve it. It applies to student-initiated
region corrections; it does not authorize direct edits of other students' records.
The member request flow and scoped RC review are not implemented in the pulled code.

### Q16 — Two-person approval for admin-initiated student changes

Keep the pulled two-person approval rule for an admin changing another student's
details, account status or RC/Head/Co-Head assignment. An authorized admin files the
request and a different super admin approves it, including requests filed by a super
admin. The requester cannot approve their own request.

This does not expand which roles may file each request type. Student self-editable
name/phone fields, Q15's student-initiated region corrections and Q13's regional event
publication retain their separately agreed flows. Changes to super-admin membership
are not decided by Q16.

### Q17 — Exactly three fixed super-admin email accounts

There are exactly three super-admin accounts. Their login emails remain the same as
council terms change; the people operating those accounts may change. Do not build
the proposed feature to add or remove super admins. This explicitly supersedes Q9's
earlier permission to appoint additional super admins.

Super-admin account identities and public office-holder identities are distinct: a
change of office-holder does not imply a new super-admin login email. The exact intended
three-account alignment still needs checking against the approved council accounts;
do not infer it solely from the existing allowlist count.

Q16's two-person rule still applies to admin-initiated student changes: approval comes
from a different one of the three super-admin accounts.

### Q18 — Event visibility by region, lifecycle and cohort

- Regional upcoming/live events are visible only to signed-in members of that region.
- House-wide events reach members across all regions.
- Completed/past events become public and accessible to everyone, including events
  that were regional while upcoming/live.
- Provide event filters by region and student cohort/entry-term code, such as `26F1`
  (January 2026) and `25F3` (September 2025), for freshers and older student groups.
- Raja described January, May and September terms. Use **term** for the four-month
  period; three terms make a year. Do not use "four-month academic year" as a domain term.

Q19 resolves the house-wide visibility overlap: all upcoming/live events require sign-in;
only completed/past listings are public. House-wide is an all-region scope, not an
exception to the upcoming/live authentication requirement.

Cohort filters are requested; whether cohort is merely a browsing filter or also an
event eligibility restriction remains a follow-up. Exact cohort derivation from email
versus authoritative allocation, event completion timing, registration and meeting-link
privacy remain separate questions. Making past listings public does not authorize
publishing attendee data, phone numbers or other private member records.

### Q19 — Upcoming/live requires sign-in; past listings are public

| Published event | Listing audience |
| --- | --- |
| House-wide, upcoming/live | All signed-in roster members across all regions |
| Regional, upcoming/live | Signed-in roster members of the event's region only |
| House-wide or regional, completed/past | Everyone, including signed-out visitors |

Drafts remain hidden under Q13; reaching an end time does not itself publish a draft.
This supersedes the ambiguous "house-wide events are public" wording in Q18. Cohort
rules, community-event scope and completion-state calculation still need decisions.

### Q20 — Publisher cohort selector and automatic term options

Event publishers, including super admins and scoped admins, can select **All students**
or choose a specific year and then **F1**, **F2**, **F3**, or **All terms** for that year.
The examples identify January as F1 and September as F3; May is the remaining F2 term.
Represent the year/term combination as a cohort code such as `26F1` or `27F2`.

Available years/terms advance automatically with the calendar as new terms arrive;
adding a term must not require manual backend/code changes. This concerns cohort
selector options, not automatic membership grants or an approved source for new students.
Q23 permits only the immediately next future cohort with a Future badge. Q24 confirms
that the selector advances on January 1, May 1 and September 1.

Q21 confirms that this publisher selection controls upcoming/live visibility, rather
than serving only as descriptive metadata or a browsing filter.

### Q21 — Publisher cohort selection restricts upcoming/live visibility

Only selected cohorts may see an upcoming/live event, in addition to the Q19 sign-in
and region requirements. A regional event targeting 2026 F1 reaches signed-in 26F1
members of that region; a house-wide event targeting 2026 F1 reaches signed-in 26F1
members across all regions. **All students** removes the cohort restriction but keeps
the event's region/sign-in requirements.

Published completed/past listings become public under Q19, including listings that
were cohort-restricted while upcoming/live. Publisher permissions to manage events
remain governed separately by role and event ownership.

### Q22 — Scheduled times determine event stage and public release

Derive the event stage automatically from its scheduled start/end times: Upcoming
before the start, Live from the start until the end, and Past at the scheduled end
and afterward. No manual completion action is required. An authorized organizer can
extend the scheduled end if needed.

At the scheduled end, a published event's listing becomes public under Q19, including
previously regional/cohort-restricted events. Drafts remain unpublished; passing their
end time does not publish them.

### Q23 — Only the next future cohort, with a Future badge

Allow advance planning for the immediately next future cohort, alongside current and
past cohort choices. During the September 2026 term, offer 27F1 but hide 27F2 and 27F3.
Show a **Future** badge when choosing the future year/term. This limits which future
cohorts are available, rather than limiting how many cohorts an event may target.
The badge describes the cohort; the event's own schedule determines its event stage.
Selecting a future cohort does not grant roster membership or bypass audience checks.

Raja's supplied September 2026 academic-calendar image lists Term start as October 2,
2026, and END TERM (DAD_Qualifier) as January 10, 2027, with results January 18–23.
January 10 is an examination date, not a confirmed term-end boundary. The named term
month and actual academic dates can differ; the next term's start is not provided.
Q24 settles the selector rollover rule. All terms follows the derived availability
rule below.

### Q24 — Cohort selector follows label-month boundaries

Advance the current cohort and next Future option on January 1, May 1 and September 1,
independently of actual teaching/exam dates. On January 1, 2027, 27F1 loses its Future
badge and 27F2 becomes the next future option. Use the site's India timezone for these
boundaries (implementation default, inferred from the site's audience).

Derived from Q20/Q23: All terms selects the currently available terms in the chosen
year; it cannot bypass the one-future-cohort limit. During 26F3, choosing 2027 All terms
therefore selects only 27F1. Store the selected cohorts explicitly so an event's audience
does not silently expand at the next rollover (implementation default). All students
retains its separately agreed meaning of every eligible cohort.

### Interview scope refinement

Raja requests the minimum set of relevant questions. Ask only unresolved product choices
that affect access, admin powers or core behavior. Infer consequences of accepted rules,
combine related decisions, and record routine implementation defaults as defaults rather
than separate accepted answers. Do not re-ask settled decisions.

### Q25 — Heads and Co-Heads manage their own community's events

Both Heads and Co-Heads can create, edit and directly publish their own community's
events, matching the RC ownership pattern. Super admins retain oversight across all
communities. Heads/Co-Heads cannot manage another community's events. Use the same
explicit Publish action and hidden drafts as Q13 (derived from the accepted RC pattern).
This event permission does not itself grant member or role-change powers; Q11's one
active regional/community admin role per person still applies.

### Q26 — Community events reach house members across regions

Upcoming/live community event listings are visible to all signed-in house members
across regions, subject to the publisher's cohort selection. Students need not join
the community first. Published past listings remain public under Q19. Community event
ownership controls who manages the event, not which region its viewers belong to.

### Q27 — House-themed forms, then manually verified WhatsApp admission

Port the house's Google Forms to website forms matching the house theme. For a community
or group application, the student fills the form, then sees the WhatsApp invite and
requests entry in WhatsApp. A super admin or admin checks the Google Sheet to verify
Sundarbans house membership and, for regional groups, regional eligibility before
allowing entry. No entry without verification. Submission and invite access must not
be presented as approved group membership.

Google Sheets remain the main membership and operational recordkeeping surface. Q29
clarifies that new website form responses/attendance are stored in the DB and downloadable
as CSV for Sheets; automatic writes into Google Sheets are not a requirement. Raja's word
"seed" is interpreted as "Sheet" from the explicit references to Google Sheets and the
previous source exploration; this does not make a SQL seed file the live authority.
Reviewed source evidence includes the Sundarbans Members roster and separate allocation
and form-response workbooks. Current repo references seed.sql, but that file is absent;
reference-data migrations seed lookup rows instead. These are separate from the Sheets.

Derived requirements: preserve each form's questions and response mapping when porting;
provide CSV exports for operational records in Google Sheets; apply Q3's explicit optional
phone-save consent. Form submission is an application record, not proof of WhatsApp
membership. Do not invent a WhatsApp API integration or website approval requirement:
the approval described by Raja happens in WhatsApp after a Sheet check. Exact form
inventory/mappings and record delivery are implementation work, not additional product
questions. No form migration, Sheet edit or live import has occurred.

### Q28 — Bulk CSV additions and manual single additions

Admins can upload a CSV exported from the approved Sheet for bulk roster additions;
the import script adds unique emails without duplicates. Admins can also add one student
manually. No automatic Sheet polling/sync is selected. Imports populate sign-in eligibility;
accounts are still created at first Google sign-in under Q14.

Email and region are the two important input fields. Interpreting Raja's "reason" as
"region": the saved allocation workbook headers were freshly checked as Student_Email,
Term, Allocated_House and Allocated_Region. The preferred Sundarbans Members workbook
has only Student_Email; it remains the chosen initial 3,808-email authority under Q1.
Future CSVs can carry email/region without requiring names or phones. Source mappings
and missing allocation handling are implementation work, following Q6/Q7.

Derived import behavior: normalize email whitespace/case, deduplicate within the file
and against existing pending/member identities, and preserve existing account IDs.
Additions do not overwrite existing member details, change roles/status, or remove
members absent from a file. Existing-member changes follow Q15/Q16 rather than being
smuggled through an import. Preserve existing authorized roster scope: RCs their own
region, super admins all regions. Q25's community event controls do not grant roster
addition powers. Show import results for added, existing, invalid and conflicting rows
as an implementation default; a repeat import must not create more accounts.

### Q29 — Organizer release, bulk attendance upload, DB records and CSV exports

The event's responsible RC/Head/Co-Head authorizes participation certificates for their
own event, with super-admin oversight; no per-event super-admin approval is required.
Provide an attendance-sheet bulk upload and review before certificate release. Students
must have registered using the event's house-themed form: match registered emails with
attendance emails. A student who attended but did not register receives no certificate;
registration without attendance is also insufficient. A signed template is used for
eligible students to generate/download their certificates after release.

Store website form responses, event registrations and imported attendance in the DB.
Provide CSV downloads so admins can keep working with these records in Google Sheets.
This clarifies Q27: CSV export is required; automatic Google Sheets delivery is not.
Exports follow the responsible organizer's event scope and super-admin oversight, not
public access to attendees' personal data (derived from existing permissions).

The supplied attendance screenshot's Attendees tab has First name, Last name, Email,
Duration, Time joined and Time exited. Durations include seconds, minutes and hours;
some emails are masked and some display names are roll numbers. Do not use display
names to infer identity or overwrite student profiles. Normalize full emails for the
registration match; masked/missing/unmatched values require review and do not confer
certificate eligibility automatically. Repeat uploads must not duplicate attendance
or certificates. Keep review categories for registered/attended, unregistered attendees,
registered absentees and unresolved rows (implementation defaults).

Existing Lounge spec retains its >=20-minute Meet attendance rule; this answer adds
the registration prerequisite rather than replacing duration eligibility. Other event
types must provide a reviewed eligible attendance list rather than pretending they
have Meet durations. Certificate-name reconciliation remains a final-summary default:
keep a separate confirmed certificate name requested only when needed for a certificate,
as in Spec 002; optional editable Lounge names still never block Lounge access.

### Q30 — All forms require member sign-in and prefill saved profile details

All website forms require approved-member sign-in; no public forms mode is selected.
When the student's profile has a name or optional phone number, prefill the corresponding
form fields. Provide the optional phone field in Edit profile, as Q3 already requires.
Missing profile values remain blank rather than being invented. Keep Q3's Save your
phone number for later checkbox: form submission updates saved phone only with consent.
Event registration also respects the event's region/cohort audience (derived from Q21).

## Confirmed consolidated design

- Membership: initial 3,808 unique approved emails across DS/ES/MG/AE. Manual single
  additions or deduplicated Sheet CSV import; first Google sign-in creates the account.
  Name/phone optional and editable. Initial missing region selection, later approved
  region-change request. International exists without an RC.
- Governance: exactly three fixed super-admin emails; 0–2 RCs per region; one scoped
  regional/community admin role per person. RCs own region events, Heads/Co-Heads own
  community events, super admins oversee all. Both scoped event roles publish directly.
  Other admin changes to members/status/roles need a different super admin's approval.
- Events: explicit hidden drafts/Publish; upcoming/live signed-in only, with regional
  and selected-cohort restrictions. House/community events span regions. Published
  past listings become public at scheduled end; private responses/attendance do not.
- Cohorts: year then F1/F2/F3/All terms, or All students. January 1/May 1/September 1
  rollover, only the immediately next future cohort offered with a Future badge.
- Forms/groups: house-themed replacements for Google Forms, all requiring member
  sign-in; saved name/phone prefill. DB responses and CSV downloads for Sheets. Group
  form submission reveals invite, followed by WhatsApp join request and manual admin
  Sheet verification before admission; submission does not prove group membership.
- Certificates: responsible organizer reviews bulk attendance uploads, matches email
  to event registration and releases eligible participation certificates from a signed
  template. DB attendance/registration and CSV exports. Unregistered attendees excluded.

Inherited rules/defaults included in the confirmed review, not individually answered questions: existing
>=20-minute Meet attendance rule; separate confirmed certificate name only when needed,
with correction requests as in Spec 002; no unregister as previously decided; existing
phone validation; once-per-member tour and read/dismissed notices from Spec 002. Preserve
existing public directory fields/history and keep directory titles separate from admin
access. Scoped operators manage their own form/attendance records, super admins all;
do not silently grant house-wide student controls to community operators. Keep raw
imports/contacts private and repeated imports/issuance idempotent.

## Final confirmation — 2026-10-09

Raja answered **Yes, this matches the design** to the consolidated review, including
the existing 20-minute Meet attendance rule and separately confirmed certificate name.
The interview is complete; no further product question is pending for this design.
Implementation is a separate next step. This confirmation does not authorize source
implementation, commits, live imports, migration pushes or deployment.

## Implementation facts still to verify

- Exact accessible Google Form questions/mappings, signed certificate templates and
  operational group links; inaccessible source documents remain unavailable, not guessed.
- Three intended super-admin account identities, real Google OAuth setup and live role
  checks; existing current code/live observations are dated separately above.
- Source/schema gaps: nullable names/missing regions, four-domain support, region/role
  limits, event ownership/audience/draft policies, member editing, forms, exports and
  attendance/certificate records. Reconcile migration versions before any authorized push.
- No live import or source implementation was performed in this interview. Further
  delivery work needs an implementation request and proportionate local/real checks.
