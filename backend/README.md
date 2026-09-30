# Sundarbans House — backend v1 (local-first Supabase)

The backend lives in this repo beside the Vue SPA but touches nothing in `src/`.
It is built on the **Supabase stack** so the exact schema, Row Level Security
policies, and Edge Functions tested locally push to a free cloud project later
with a few CLI commands (see [Connect a cloud project](#connect-a-cloud-project)).

**v1 scope** (agreed 2026-09-05):

| Area | Status |
|---|---|
| Public content: events, meetups, important dates | DB-driven, admin-editable, draft → pending_review → published |
| Members Lounge | **Gate only** — roster-backed membership check; content tables come later |
| Member roster | Google Sheet stays source of truth; synced via `members-sync` Edge Function |
| Roles | `web_admin` > `admin` > `regional_coordinator` > `member` |
| RAG chatbot | Out of scope (built separately by a teammate; will wire in later) |

## Layout

```
supabase/
  config.toml              local stack config (ports 5442x, see below)
  migrations/…_init.sql    enums, tables, triggers, helpers, ALL RLS policies
  seed.sql                 fixtures ONLY — fake members, sample content
  functions/members-sync/  Sheet → Supabase roster sync (Deno Edge Function)
  functions/.env           MEMBERS_SYNC_SECRET (gitignored)
backend/
  test/api.test.mjs        51-check API + permission suite (zero dependencies)
  apps-script/Code.gs      the Google Apps Script half of the roster sync
```

## Run it locally

Prereqs: Docker running, Supabase CLI, Node (or Deno) for the tests.

```bash
supabase start                                   # boots Postgres, Auth, REST, Studio
supabase functions serve --env-file supabase/functions/.env   # terminal 2
supabase db reset                                # re-apply migrations + seed anytime
SUPABASE_SECRET_KEY=<secret key from supabase status> node backend/test/api.test.mjs   # 51 checks, needs the stack up
```

- API:      http://127.0.0.1:54421 (REST under `/rest/v1`, auth under `/auth/v1`)
- Studio:   http://127.0.0.1:54423 (table editor — how the council edits content
  until an admin UI exists)
- **Ports are 5442x, not the default 5432x**, because another local Supabase
  project (the chatbot backend) already binds the defaults on this machine.
- Keys: `supabase status` prints the publishable + secret keys. The test suite
  falls back to the local publishable key and URL, but needs `SUPABASE_SECRET_KEY`
  set (no secret is kept in the repo).

## Data model

- `regions` — 9 chapter slugs mirrored from `src/views/meetups/regionConfigs.js`.
- `profiles` — one per auth user; `role` + optional `region_id` (for RCs).
  Auto-created by a trigger on signup with role `member`.
- `members` — synced roster copy (PII: locked down to admins). `is_active`
  flag drives Lounge access.
- `events` / `meetups` / `important_dates` — public content with
  `status: draft → pending_review → published`, real ISO/timestamp dates
  (the RAG audit flagged year-less dates as a P1 trust failure), and
  `published_at` stamped automatically on first publish.

## Security model (all enforced by RLS, not app code)

- Published rows are world-readable; drafts/`pending_review` are visible only
  to their creator and admin roles.
- Events and important dates: admin roles only.
- Meetups: RCs get full CRUD **only inside their own region**; admins
  everywhere.
- `members`: readable by admin roles, written only by `web_admin` or the
  service role (the sync). Anonymous/member reads return zero rows.
- Role and region assignment happen only through the `assign_role` /
  `assign_region` RPCs, callable by `web_admin` alone — no caller can
  self-promote by patching their profile.
- `is_active_member()` is the Lounge gate helper; `my_access()` returns
  `{ role, is_member, region_slug }` for the signed-in caller (public shape
  for anonymous).

## Roster sync (Sheet → Supabase)

1. Council edits the member Google Sheet as today.
2. `backend/apps-script/Code.gs` (bound to that Sheet) POSTs changed rows to
   the `members-sync` function with the `x-sync-secret` header.
3. The function upserts by lowercased email and, with `replace: true`,
   deactivates anyone missing from the Sheet (no deletes — history stays).

Setup steps are in the `Code.gs` header comment. The secret lives in
`supabase/functions/.env` locally and in function secrets in the cloud.

## Connect a cloud project

Create the free project **in Mumbai (ap-south-1)** first — region is fixed at
creation. Then:

```bash
supabase link --project-ref <ref>
supabase db push                          # applies the same migrations
supabase functions deploy members-sync
supabase secrets set MEMBERS_SYNC_SECRET=<real secret>
```

In the dashboard: enable the Google auth provider with the existing OAuth
client ID, add `https://<ref>.supabase.co/auth/v1/callback` to the Google app's
redirect URIs, and keep images on Cloudinary / PDFs on Drive (unchanged
decisions). `seed.sql` is **not** applied to the cloud — the roster arrives via
sync, sample content via the council.

Frontend wiring (later, by whoever owns `src/`): `supabase-js` +
`signInWithOAuth({ provider: 'google' })`, `my_access()` for the Lounge gate,
and plain REST/JS queries defaulting to `status=eq.published`.
