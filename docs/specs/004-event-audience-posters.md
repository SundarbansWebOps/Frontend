# Spec 004 — Event audience, posters and RC house-wide approval

> Status: built 2026-10-13 on `feat/event-posters-audience`. Backend applied to the cloud:
> migrations `20261013194447_event_publish_request_type.sql`, `20261013194628_event_audience_posters.sql`
> (rename to the cloud versions before merge), Edge Function `sign-event-image`.
> Tests: `supabase/tests/040_event_audience_posters_test.sql` (25), `e2e/event-posters.spec.js` (3).

## Audience

- **Who:** House (everyone), a region, or a community, plus optional cohorts (unchanged).
- **Public / Members only** (`events.is_public`): a Public upcoming event is listed in "Coming up" on
  `/#/events`; a members-only one stays in the Lounge for its audience. Every published event joins the
  public archive once it ends (unchanged). `list_public_events()` returns archive + past + upcoming
  Public events with a `stage`.

## Who manages which event

|                | Own region            | House-wide                                                                                               | Other region / community |
| -------------- | --------------------- | -------------------------------------------------------------------------------------------------------- | ------------------------ |
| RC             | create, edit, publish | draft; **Ask a Super Admin to publish** (`event_publish` request); after approval only Super Admins edit | no                       |
| Head / Co-Head | –                     | –                                                                                                        | own community only       |
| Super Admin    | all                   | all                                                                                                      | all                      |

While a publish request is pending the draft is frozen (`events_freeze_under_review`), so the Super
Admin approves exactly what they reviewed. Approve/reject in Admin → Requests.

## Posters (Cloudinary)

1. Save the event (draft is fine), then **Upload poster** in the event form.
2. The site calls `sign-event-image`; it checks the caller may manage that event
   (`svc_event_image_target` → `manages_event`) and signs an upload fixed to
   `sundarbans/events/<event id>`, JPG/PNG/WebP, resized on arrival to ≤1600 px.
3. The browser uploads straight to Cloudinary; the site saves the delivery URL
   (`…/image/upload/f_auto,q_auto:good,w_1000,c_limit/v…/…`), width and height. `events.image_url` only
   accepts `https://res.cloudinary.com/l59gy0g2/image/upload/…` (constraint `events_image_cloudinary`).
4. Posters show on the public cards and sheet, the admin list and the Lounge event pop-up.

**Setup (Supabase → Edge Functions → Secrets):** `CLOUDINARY_CLOUD_NAME` = `l59gy0g2`,
`CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`. Never put the API secret in the site, `.env` files that
reach Vite (`VITE_*`) or the repo. Until they are set the upload answers "Image uploads are not set up
yet". Browser uploads also need `ALLOWED_ORIGINS` to include the site's origin. CSP `connect-src`
allows `https://api.cloudinary.com`.
