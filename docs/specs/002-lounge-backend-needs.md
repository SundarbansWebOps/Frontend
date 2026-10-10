# Spec 002 — What the Lounge needs from the backend

> Status: requested 2026-10-06 by Raja (Web Admin). For the backend team. Source of truth for the
> schema is the cloud Supabase project (`supabase/migrations/`); this lists only what the Lounge
> front end needs and does not have yet. Prototype: `~/Anuraj-dev/Frontend-lounge-d/prototype/lounge-d/`.

## 1. Welcome tour seen flag (new)
New members see the welcome tour once ever, on any device.
- Per-member field, e.g. `members.tour_seen_at timestamptz null`.
- Set when the member presses **Enter the Lounge** or **Skip tour**. Closing the tab mid-tour leaves it null.
- Cleared only by the member, from the profile's **Retake the tour**.
- The member can read and write their own flag; nobody else needs it.

## 2. Preferred name (exists)
`members.full_name` (roster) and `members.preferred_name` already exist.
- Updated 2026-10-08: name is optional. Ask at first Lounge entry, allow skipping,
  and let the member add/edit it later; missing name must not block access. See
  `003-backend-data-decisions.md`, Q2. Roll remains read-only. Q6 allows the four members
  without allocation to choose their region at first entry; later changes require an
  admin-approved request (Q7).
- The chosen Lounge name goes to `preferred_name`; the profile's Edit also writes it.
  Retain the existing optional profile-name fields as a confirmed-review default.
- The member must be able to update their own `preferred_name` (check RLS / an RPC for this).
- Roll wrong → the UI tells them to contact their coordinator; no member write.
  Region wrong → submit a region-change request; the saved region changes only after
  approval by the member's current-region RC or a super admin. Super admins handle
  International and other regions without an RC (Q8/Q15). Q15 confirms this member
  request flow as an exception to the pulled admin two-person workflow.

### Optional phone (decision added 2026-10-08)
- A missing phone must not block account creation or Lounge access. Edit profile offers
  an optional phone field.
- Future forms asking for a phone offer **Save your phone number for later**. Only
  checking it updates the saved profile phone; future forms can prefill that value.
- Q30: all website forms require member sign-in; prefill saved profile name and optional
  phone when present. Edit profile includes the optional phone field. Missing values stay blank.
- Form-response storage and whether a particular form requires phone are separate
  decisions. See `003-backend-data-decisions.md`, Q3.

## 3. Event registration (exists in part)
Regional/community registration tables cover scoped form responses; event registration
still needs implementation. Lounge rules:
- Event visibility decisions Q18/Q19: upcoming/live listings require sign-in; regional
  listings reach only that region, house-wide listings reach all regions. Published
  completed/past listings are public. Add region and cohort filters. Publisher cohort
  controls (Q20): All students, or year → F1/F2/F3/All terms, with options advancing
  automatically as terms arrive. Q21 confirms only the selected cohorts can see an
  upcoming/live event within its region/house-wide scope; All students removes the cohort
  restriction. Published past listings become public regardless of their earlier audience.
- Q22: derive Upcoming/Live/Past automatically from scheduled start/end times; published
  listings become public at the scheduled end. An authorized organizer may extend the end.
  A draft is not published automatically when its end time passes.
- Q23: offer only the immediately next future cohort, marked **Future** in the year/term
  selector. During the September 2026 term, 27F1 is available; 27F2/27F3 are hidden.
- Q24: advance cohort options and Future badges on January 1, May 1 and September 1.
  Derived rule: All terms includes only available terms in the chosen year.
- Q25: Heads and Co-Heads can create, edit and directly publish their own community's
  events; super admins oversee all communities. Explicit Publish and hidden drafts apply.
- Q26: upcoming/live community events reach signed-in house members across all regions,
  subject to cohort selection. Community membership is not required; published past
  listings are public.
- A member registers once per event. No unregister. The UI shows "Registered".
- The Events page needs, per event: the member's registration and attendance (≥20 min in the Meet
  attendance report) and a certificate if one was issued.

## 4. Notices (new)
Lounge shows a notice banner (<72h, dismissible) and a bell panel with history.
- An `announcements` table: title, body, link (optional), starts_at, ends_at/expiry, audience
  (all members or a region), created_by.
- Per-member read/dismissed state, so the bell badge and banner dismissal survive devices.

## 5. WhatsApp groups (new)
Home lists the member's WhatsApp groups with one-line purposes.
- A table of groups: name, purpose, invite link, scope (house-wide, region, community).
- The member sees house-wide groups, their region's group and their communities' groups.
- Q27/Q29: replace house Google Forms with house-themed website forms, saving responses
  in the DB and offering CSV downloads for Google Sheets. After submitting a community/group form, reveal the WhatsApp
  invite; the student then requests entry in WhatsApp. A super admin/admin checks the
  membership Sheet and regional eligibility where applicable before approving entry.
  Submission/invite access is not verified membership. Q3's phone-save consent applies.

## 6. Certificates
Profile → **My certificates** pop-up and Events → Mine both list the member's certificates, each with
a download and a public verify link. Needs a per-member certificate list (today only the static
`public/data/certificates.json` lookup exists).
- Q29: the event's responsible organizer can bulk-upload and review attendance, then
  release participation certificates using a signed template; super admins retain
  oversight. Match attendance emails against that event's registration-form records:
  unregistered attendees are ineligible. Store registrations and attendance in the DB;
  provide CSV exports. Preserve the existing >=20-minute Meet attendance requirement.
  Masked/unmatched emails need review; repeated uploads must not duplicate records.
- A per-member **certificate name**, confirmed only when a certificate is needed, then
  locked (later preferred-name edits don't change it). Changes go through a request to
  the council. Confirmed-review default reconciling optional names with certificate identity.
- The verify link is `/verify-certificate?id=<certificate id>`; `src/pages/VerifyPage.vue` must read
  `?id=` and look it up on load (it doesn't yet).

## Final review
- Raja confirmed the consolidated Q1–Q30 design on 2026-10-09. Inherited defaults are
  listed separately in `003-backend-data-decisions.md`. Implementation remains a next step.

## Roster additions (Q28)
- Bulk CSV import from the approved Sheet, with unique normalized emails and region
  mapping; manual single-student additions are also available. No automatic Sheet sync.
- Preserve RC own-region / super-admin all-region roster scope. Additions preserve
  existing accounts and details; existing-member changes use their approval workflows.
