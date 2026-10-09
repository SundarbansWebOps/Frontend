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
- At the end of the tour the member confirms their details (name editable; roll and region read-only)
  and saves. The saved name goes to `preferred_name`. The profile's Edit also writes it.
- The member must be able to update their own `preferred_name` (check RLS / an RPC for this).
- Roll or region wrong → the UI tells them to contact their coordinator; no member write.

## 3. Event registration (exists in part)
`registrations` exists. Lounge rules:
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

## 6. Certificates
Profile → **My certificates** pop-up and Events → Mine both list the member's certificates, each with
a download and a public verify link. Needs a per-member certificate list (today only the static
`public/data/certificates.json` lookup exists).
- A per-member **certificate name**, locked after the member first saves a name (later preferred-name
  edits don't change it). Changes go through a request to the council.
- The verify link is `/verify-certificate?id=<certificate id>`; `src/pages/VerifyPage.vue` must read
  `?id=` and look it up on load (it doesn't yet).

## Open
- Whether "live" stays derived from `events.starts_at/ends_at` (current assumption).
- Certificate name changes go through a request to the council, not a member edit.
