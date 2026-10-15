// sign-event-image
// POST { "event_id": uuid }   Caller: a signed-in member who may manage that event (RC of its
// region, its community's Head/Co-Head, the RC who drafted an unpublished house-wide event, or a
// Super Admin) — the database decides (svc_event_image_target).
//
// Returns a short-lived signed Cloudinary upload for the event's poster. The browser then uploads
// the file straight to Cloudinary; the API secret never leaves this function. The signature fixes
// the folder (sundarbans/events/<event id>), the formats (jpg, png, webp) and an incoming resize to
// at most 1600 px, so the upload cannot go anywhere else or be anything else.
//
// Secrets: CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET (Edge Function secrets).
import { admin, HttpError, readJson, rpc, serve, uuidField } from '../_shared/common.ts';
// events.image_url only accepts this account's delivery URLs (constraint events_image_cloudinary).
const EXPECTED_CLOUD = 'l59gy0g2';
async function sha1Hex(text) {
  const digest = await crypto.subtle.digest('SHA-1', new TextEncoder().encode(text));
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}
serve('sign-event-image', async (req) => {
  const header = req.headers.get('Authorization') ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) throw new HttpError(401, 'unauthenticated', 'Missing bearer token');
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data?.user)
    throw new HttpError(401, 'unauthenticated', 'Invalid or expired session');
  const eventId = uuidField(await readJson(req), 'event_id');
  await rpc('svc_event_image_target', {
    p_actor: data.user.id,
    p_event_id: eventId,
  });
  const cloudName = Deno.env.get('CLOUDINARY_CLOUD_NAME');
  const apiKey = Deno.env.get('CLOUDINARY_API_KEY');
  const apiSecret = Deno.env.get('CLOUDINARY_API_SECRET');
  if (!cloudName || !apiKey || !apiSecret) {
    throw new HttpError(
      503,
      'not_configured',
      'Image uploads are not set up yet (Cloudinary secrets missing)'
    );
  }
  if (cloudName !== EXPECTED_CLOUD) {
    throw new HttpError(
      503,
      'not_configured',
      'CLOUDINARY_CLOUD_NAME does not match the house account'
    );
  }
  // Every signed parameter, sorted by name (Cloudinary's signature rule).
  const params = {
    allowed_formats: 'jpg,png,webp',
    folder: `sundarbans/events/${eventId}`,
    timestamp: String(Math.floor(Date.now() / 1000)),
    transformation: 'c_limit,w_1600',
  };
  const toSign = Object.keys(params)
    .sort()
    .map((k) => `${k}=${params[k]}`)
    .join('&');
  return {
    upload_url: `https://api.cloudinary.com/v1_1/${cloudName}/image/upload`,
    cloud_name: cloudName,
    api_key: apiKey,
    ...params,
    signature: await sha1Hex(toSign + apiSecret),
  };
});
