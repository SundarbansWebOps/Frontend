# Spec 003 — Google sign-in, the roster and the admin lounge

> Status: built 2026-10-08 on `feat/admin-panel-supabase`. Backend: migrations
> `…_admin_request_types.sql`, `…_admin_panel_backend.sql` and `…_optional_phone.sql` (applied to the cloud project).
> Tests: `supabase/tests/010_admin_panel_test.sql` (42 checks), `e2e/admin.spec.js`.

## Who gets in

- **Members sign in with Google only**, and only if their member profile already exists or they are
  on the **roster**. A first Google sign-in with a rostered email creates the member from the roster
  row (name, phone, region) and removes the row. Anyone else is refused by the database; the sign-in
  door explains: "This Google account is not on the house roster…".
- **Phone number is optional** (roster, profile edits, sign-up). When given it must be in
  international format and unique; blank clears it. Without a phone, blacklisting matches by email
  only.
- Existing accounts (the three Super Admins) are linked to their Google identity automatically by
  Supabase (same confirmed email), so they sign in with Google too.
- Suspended, blacklisted and deleted members are banned in Auth (`apply-account-status`), so Google
  sign-in fails for them; if a session slips through, the site signs them out.
- **The admin lounge (`/admin`)** is for Regional Coordinators and Super Admins. It opens from the
  Lounge's profile menu ("Admin lounge"); the router sends everyone else back to the Lounge, and the
  database checks every call again.

## What each role can do

| | Regional Coordinator | Super Admin |
|---|---|---|
| Students | Own region: view, search | All regions, including deleted |
| Roster (add before first sign-in) | Own region, one by one or pasted from a sheet | Any region |
| Edit a student (name, preferred name, gender, phone, region) | Request | Request |
| Delete / blacklist | Request | Request |
| Suspend, reinstate, restore, lift blacklist, erase permanently | – | Request |
| Give or revoke RC / Head / Co-Head | – | Request |
| Approve or reject requests | – | Anyone's except their own |
| Events | Create, edit, cancel, remove **all** events | Same, and sees removed events |
| Audit log | – | Read |

**Two-person rule:** every change to a student's data is a request; a different Super Admin approves
it, and only then is it applied (in one transaction, audited). The old direct `sa_*` actions and
`assign_position` / `revoke_position` can no longer be called from the website. Email changes are not
in the panel (the IITM email is the login); the `change-member-contact` Edge Function is still a
direct Super Admin tool for exceptional cases.

## Setup a person must do (Supabase and Google dashboards)

1. **Google Cloud Console** → OAuth client (Web): authorised redirect URI
   `https://bqoejoznqudcyeaebmsm.supabase.co/auth/v1/callback`. Consent screen: Internal to the IITM
   Workspace if available, otherwise External.
2. **Supabase → Authentication → Sign In / Providers → Google**: enable; paste the client ID and
   secret.
3. **Supabase → Authentication → URL Configuration**: Site URL `https://sundarbans.iitmbs.org`;
   Redirect URLs `https://sundarbans.iitmbs.org/**`, `http://localhost:5173/**` and the Vercel
   domain(s), e.g. `https://*-sundarbans-projects.vercel.app/**`.
4. **Supabase → Edge Functions → Secrets**: `ALLOWED_ORIGINS` = the same origins, comma-separated
   (no wildcards). Needed for approving deletions / status changes (sign-in access sync) and erasure.
5. **Vercel** (optional): `VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY`. The code defaults to
   the production project, so builds work without them.
6. **Supabase → Authentication → Sign In / Providers → Email**: optionally turn off email sign-up;
   the database refuses non-roster sign-ups anyway.

## Front end map

- `src/lib/supabase.js` — the client (PKCE flow, publishable key). Loaded lazily.
- `src/lib/auth.js` — session, own profile, role (`get_my_dashboard`), Google sign-in, sign-out,
  redirect handling. Imported first by `main.js`.
- `src/router/index.js` — `meta.member` / `meta.admin` guards.
- `src/pages/LoginPage.vue` — "Sign in with Google"; continues to `?next=` (Lounge or admin) after
  Google.
- `src/pages/AdminPage.vue`, `src/components/admin/*` — the admin lounge; `src/lib/admin.js` — its
  data calls.
- `src/pages/LoungePage.vue` — shows the member's real roll, region and RC; the rest of the Lounge
  still runs on sample data (spec 002).
- `e2e/supabase-mock.js` — browser tests answer every Supabase call locally (incl. the Google
  round-trip), so CI needs no secrets.
