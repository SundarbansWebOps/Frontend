// members-sync — Google Sheet → Supabase roster sync.
//
// The council's Google Sheet stays the source of truth for membership. This
// Edge Function is the only door into the members table for the sync: it
// accepts a batch of members from Google Apps Script, upserts them by email
// (lowercased), and optionally deactivates anyone missing from the payload.
//
// Auth: requires the `x-sync-secret` header to equal the MEMBERS_SYNC_SECRET
// secret (a service-role bearer token is also accepted for manual runs).
// JWT verification is disabled for this function in supabase/config.toml
// because Apps Script cannot obtain a Supabase JWT.
//
// POST /functions/v1/members-sync
// {
//   "members": [
//     { "email": "a@student.iitm.ac.in", "full_name": "...", "region": "Chennai",
//       "roll_number": "21F1000001", "is_active": true, "source_updated_at": "2026-09-05T10:00:00Z" }
//   ],
//   "replace": true   // mark members not in this payload as is_active=false
// }

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? 'http://kong:8000';
const SERVICE_KEY =
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SECRET_KEY') ?? '';
const SYNC_SECRET = Deno.env.get('MEMBERS_SYNC_SECRET') ?? '';

const json = (status, body) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return json(405, { error: 'POST only' });
  }

  const bearer = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
  const authorized =
    (SYNC_SECRET !== '' && req.headers.get('x-sync-secret') === SYNC_SECRET) ||
    (SERVICE_KEY !== '' && bearer === SERVICE_KEY);
  if (!authorized) {
    return json(401, { error: 'unauthorized' });
  }

  let payload;
  try {
    payload = await req.json();
  } catch {
    return json(400, { error: 'invalid JSON body' });
  }

  const rows = Array.isArray(payload?.members) ? payload.members : null;
  if (!rows) {
    return json(400, { error: 'body must contain a "members" array' });
  }

  const syncStamp = new Date().toISOString();

  const clean = [];
  for (const [i, m] of rows.entries()) {
    const email = typeof m?.email === 'string' ? m.email.trim().toLowerCase() : '';
    if (!email || !email.includes('@')) {
      return json(422, { error: `members[${i}]: a valid email is required` });
    }
    clean.push({
      email,
      full_name: m.full_name ?? null,
      region: m.region ?? null,
      roll_number: m.roll_number ?? null,
      is_active: m.is_active ?? true,
      source_updated_at: m.source_updated_at ?? null,
      synced_at: syncStamp,
    });
  }

  const restHeaders = {
    'Content-Type': 'application/json',
    apikey: SERVICE_KEY,
    Authorization: `Bearer ${SERVICE_KEY}`,
  };

  // Upsert in one shot on the email unique constraint.
  if (clean.length > 0) {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/members?on_conflict=email`, {
      method: 'POST',
      headers: {
        ...restHeaders,
        Prefer: 'resolution=merge-duplicates,return=representation-minimal',
      },
      body: JSON.stringify(clean),
    });
    if (!res.ok) {
      return json(502, { error: 'member upsert failed', detail: await res.text() });
    }
  }

  let deactivated = 0;
  if (payload.replace === true) {
    const emails = clean.map((m) => `"${m.email.replace(/"/g, '""')}"`).join(',');
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/members?select=email&email=not.in.(${emails})&is_active=eq.true`,
      {
        method: 'PATCH',
        headers: { ...restHeaders, Prefer: 'return=representation' },
        body: JSON.stringify({ is_active: false, synced_at: syncStamp }),
      }
    );
    if (!res.ok) {
      return json(502, { error: 'deactivation pass failed', detail: await res.text() });
    }
    deactivated = ((await res.json()) ?? []).length;
  }

  return json(200, { upserted: clean.length, replace: payload.replace === true, deactivated });
});
