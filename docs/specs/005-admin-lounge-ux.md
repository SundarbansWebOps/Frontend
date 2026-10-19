# Spec 005 — Admin lounge UX/UI update

> Status: **planned, deferred** (2026-10-18). Not started. Reviewed by GPT-6.1 Sol and Grok 4.7
> (source reading only, nothing executed).

## Problem

The admin lounge (`src/pages/AdminPage.vue`, `src/components/admin/*`, `src/lib/admin.js`) is not
self-explanatory. Non-technical admins (RCs, Heads/Co-Heads, Super Admins) cannot tell what to do —
e.g. adding a roster entry with only email + region, they don't know what to put in name/phone
(answer: leave blank). Roster entries cannot be edited, only added/removed.

Goal: an admin knows on sight what to do and how.

## PR1 — Roster: edit + clarity

Backend — new `roster_update(p_email, p_changes jsonb)`:
- Allow-list `full_name`, `phone`, `gender`; `region_id` Super Admin only. Omitted key = unchanged,
  JSON null = clear. Keep `added_by`/`added_at`. Audit `roster.update` with before/after.
- Email is immutable (primary key; remove+add risks lockout or two claimable rows). Login email
  changes stay on `request_contact_change`.
- Race with first sign-in (claim copies then deletes the row, `20261009150000_member_lounge.sql:84`):
  take the `roster:{email}` advisory lock (as `roster_add_many`, `20261010000000_audit_fixes.sql:241`),
  `FOR UPDATE` the row, re-check members, fail when zero rows change. Add the same lock to
  `roster_remove`.
- No existence oracle for RCs: other-region and missing emails return the same "Not on the roster in
  your scope". Phone clash / blacklist stay generic for RCs. Keep `roster_add_many`'s RC result
  categories (`audit_fixes.sql:248`).

Roster tab:
- One **Add students** action → One student / Paste from Sheets / Upload CSV.
- Email required; hint lists all approved domains (ds, es, mg, ae — today only ds is shown).
- **Optional details** group (name, phone, gender) with field-specific blank-field copy. Do not
  promise "the student can fill it in": students can change preferred name and phone only.
- RC: region as fixed text; region column in paste/CSV ignored, not validated (`admin.js:333`).
- Super Admin leaving region blank: warn that no RC can see that student.
- Honest result copy (today a no-op add still says "they can sign in", `AdminRoster.vue:359`).
- CSV: preview before import; fix duplicates dropping every occurrence (`admin.js:337`); retry failed
  rows.
- List: name ("Name not set"), region, phone, added by ("You" / role word — never another admin's
  name), "Waiting for first sign-in", **Edit** / **Remove**. Remove confirms the consequence (that
  email can no longer sign in). Search on input; don't blank the list while loading.

## PR2 — Honest and safe elsewhere

- Students: copy says blank name is fine but `request_member_update` rejects it — align. Say edits go
  to a Super Admin for approval; explain Current vs Active; correct empty-state copy.
- Requests: show before → after; split "Needs your review" from "Waiting for someone else".
- Forms/Events: "Save draft" on a published record changes it live — label "Save changes" and say so.
  Dirty-state guard on dialog close (`AdminDialog.vue:10`).
- Form builder: plain labels and automatic defaults instead of Key / textarea / multiselect / Prefill.
- Heads/Co-Heads: hide member/roster counts they cannot read (always 0).

## PR3 — Only if still needed

Confirms on every destructive action, one primary button per view, consistent success messages. A
"Start here" tab only if admins still get lost (tab sub-lines and scope note already exist).

## Verification

- SQL tests: RC same error for other-region vs missing; RC cannot move region; claim vs update in
  both orders; phone/blacklist generic for RCs.
- Playwright behavioural assertions per role on result copy; then real signed-in Chrome.
- Follow `.agents/skills/sundarbans-design/SKILL.md` for all UI.
