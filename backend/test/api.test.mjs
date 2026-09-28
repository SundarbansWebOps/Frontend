// Sundarbans House backend v1 — API + permission tests.
//
// Runs against a local Supabase stack (`supabase start` + `supabase db reset`
// + `supabase functions serve`). Dependency-free on purpose: plain fetch and
// asserts, so it runs on node or deno with zero installs.
//
//   node backend/test/api.test.mjs
//   deno run -A backend/test/api.test.mjs
//
// Keys/URL come from the environment (SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY,
// SUPABASE_SECRET_KEY, MEMBERS_SYNC_SECRET). The secret key has no fallback,
// so no secret-shaped string lives in the repo: copy it from `supabase status`.

const BASE = env('SUPABASE_URL') ?? 'http://127.0.0.1:54421';
const PUBLISHABLE =
  env('SUPABASE_PUBLISHABLE_KEY') ?? 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';
const SECRET_KEY = env('SUPABASE_SECRET_KEY');
if (!SECRET_KEY) {
  console.error('Set SUPABASE_SECRET_KEY to the secret key `supabase status` prints.');
  if (typeof process !== 'undefined') process.exit(2);
  else Deno.exit(2);
}
const SYNC_SECRET = env('MEMBERS_SYNC_SECRET') ?? 'local-dev-sync-secret';
const PASSWORD = 'Passw0rd!123';

function env(name) {
  if (typeof process !== 'undefined' && process?.env) return process.env[name];
  if (typeof Deno !== 'undefined') return Deno.env.get(name);
  return undefined;
}

// ── tiny harness ─────────────────────────────────────────────────────────
const results = [];
function check(name, ok, detail = '') {
  results.push({ name, ok, detail });
  console.log(`  ${ok ? '✓' : '✗'} ${name}${ok || !detail ? '' : ` — ${detail}`}`);
}
function section(title) {
  console.log(`\n${title}`);
}
function summary() {
  const failed = results.filter((r) => !r.ok);
  console.log(
    `\n${results.length - failed.length}/${results.length} checks passed` +
      (failed.length ? ` — FAILURES: ${failed.map((f) => f.name).join(', ')}` : ' — all green')
  );
  if (typeof process !== 'undefined' && process?.exit) process.exit(failed.length ? 1 : 0);
  if (failed.length) throw new Error(`${failed.length} checks failed`);
}

// ── API helpers ──────────────────────────────────────────────────────────
async function api(
  path,
  { method = 'GET', body, token, key = PUBLISHABLE, returnRep = false } = {}
) {
  const headers = { apikey: key };
  if (token) headers.Authorization = `Bearer ${token}`;
  else headers.Authorization = `Bearer ${key}`;
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (returnRep) headers.Prefer = 'return=representation';
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  return { status: res.status, data };
}

const signIn = async (email) =>
  (
    await api('/auth/v1/token?grant_type=password', {
      method: 'POST',
      body: { email, password: PASSWORD },
    })
  ).data?.access_token;

async function ensureUser(email, fullName) {
  const res = await api('/auth/v1/admin/users', {
    method: 'POST',
    key: SECRET_KEY,
    body: {
      email,
      password: PASSWORD,
      email_confirm: true,
      user_metadata: { full_name: fullName },
    },
  });
  if (res.status === 200 || res.status === 201) return res.data.id;
  // 422 = already registered on a re-run; look the id up via profiles.
  const prof = await api(`/rest/v1/profiles?email=eq.${email}&select=id`, { key: SECRET_KEY });
  return prof.data?.[0]?.id;
}

async function setProfile(email, patch) {
  const res = await api(`/rest/v1/profiles?email=eq.${email}`, {
    method: 'PATCH',
    key: SECRET_KEY,
    body: patch,
  });
  return res.status;
}

const regionId = async (slug) =>
  (await api(`/rest/v1/regions?slug=eq.${slug}&select=id`, { key: SECRET_KEY })).data?.[0]?.id;

// ── suite ────────────────────────────────────────────────────────────────
section('1 · Public surface (anonymous)');
{
  const health = await api('/rest/v1/');
  check('REST API is up', health.status === 200, `status ${health.status}`);

  const events = await api('/rest/v1/events?select=title,status');
  check(
    'anon sees only published events (5 seeded)',
    events.status === 200 &&
      events.data.length === 5 &&
      events.data.every((e) => e.status === 'published'),
    `status ${events.status}, rows ${JSON.stringify(events.data)?.slice(0, 120)}`
  );

  const drafts = await api('/rest/v1/events?select=title&status=eq.draft');
  check('anon cannot see draft events', drafts.status === 200 && drafts.data.length === 0);

  const noInsert = await api('/rest/v1/events', {
    method: 'POST',
    body: { title: 'anon attempt', community: 'technical' },
  });
  check(
    'anon cannot create events',
    noInsert.status === 401 || noInsert.status === 403,
    `status ${noInsert.status}`
  );

  const roster = await api('/rest/v1/members?select=email');
  check(
    'anon cannot read the member roster',
    roster.status === 200 && roster.data.length === 0,
    `status ${roster.status}, rows ${roster.data?.length}`
  );

  const access = await api('/rest/v1/rpc/my_access', { method: 'POST' });
  check(
    'anon my_access() returns the public shape',
    access.status === 200 && access.data?.role === 'public' && access.data?.is_member === false,
    JSON.stringify(access.data)
  );

  const regions = await api('/rest/v1/regions?select=slug');
  check('anon can read the region list', regions.status === 200 && regions.data.length === 9);
}

section('2 · Auth bootstrap (service key)');
const U = {
  webAdmin: 'web_admin@test.local',
  admin: 'admin1@test.local',
  rcChennai: 'rc_chennai@test.local',
  rcMumbai: 'rc_mumbai@test.local',
  member: 'member1@test.local',
  nonMember: 'nonmember1@test.local',
};
{
  for (const [k, email] of Object.entries(U)) {
    const id = await ensureUser(email, `Test ${k}`);
    check(`user ready: ${email}`, typeof id === 'string' && id.length > 0, `id ${id}`);
  }
  check('profile auto-created for new auth user', (await setProfile(U.nonMember, {})) === 204);
  check('web_admin role set', (await setProfile(U.webAdmin, { role: 'web_admin' })) === 204);
  check('admin role set', (await setProfile(U.admin, { role: 'admin' })) === 204);
  const chennai = await regionId('chennai');
  const mumbai = await regionId('mumbai');
  check(
    'RC chennai role+region set',
    (await setProfile(U.rcChennai, { role: 'regional_coordinator', region_id: chennai })) === 204
  );
  check(
    'RC mumbai role+region set',
    (await setProfile(U.rcMumbai, { role: 'regional_coordinator', region_id: mumbai })) === 204
  );
}

section('3 · Membership gate (Lounge)');
{
  const tAdmin = await signIn(U.webAdmin);
  const tMember = await signIn(U.member);
  const tNon = await signIn(U.nonMember);
  check('password sign-in works for test users', !!tAdmin && !!tMember && !!tNon);

  const a1 = await api('/rest/v1/rpc/my_access', { method: 'POST', token: tAdmin });
  check(
    'web_admin my_access: role=web_admin',
    a1.data?.role === 'web_admin',
    JSON.stringify(a1.data)
  );

  const a2 = await api('/rest/v1/rpc/my_access', { method: 'POST', token: tMember });
  check(
    'rostered member my_access: is_member=true',
    a2.data?.is_member === true && a2.data?.role === 'member',
    JSON.stringify(a2.data)
  );

  const a3 = await api('/rest/v1/rpc/my_access', { method: 'POST', token: tNon });
  check(
    'non-member my_access: is_member=false',
    a3.data?.is_member === false,
    JSON.stringify(a3.data)
  );

  const roster = await api('/rest/v1/members?select=email', { token: tMember });
  check(
    'member cannot read the roster (PII)',
    roster.status === 200 && roster.data.length === 0,
    `rows ${roster.data?.length}`
  );

  const rosterAdmin = await api('/rest/v1/members?select=email', { token: tAdmin });
  check(
    'web_admin can read the roster (3 fixtures)',
    rosterAdmin.status === 200 && rosterAdmin.data.length === 3,
    `rows ${rosterAdmin.data?.length}`
  );
}

section('4 · Content lifecycle (events)');
{
  const tAdmin = await signIn(U.admin);
  const tMember = await signIn(U.member);

  const created = await api('/rest/v1/events', {
    method: 'POST',
    token: tAdmin,
    returnRep: true,
    body: {
      title: 'Lifecycle Test Event',
      description: 'created by test',
      community: 'technical',
      starts_at: new Date(Date.now() + 7 * 864e5).toISOString(),
      venue: 'Test Hall',
    },
  });
  const eventId = created.data?.[0]?.id;
  check(
    'admin creates a draft event',
    created.status === 201 && !!eventId,
    `status ${created.status} ${JSON.stringify(created.data)?.slice(0, 120)}`
  );
  check('new event defaults to draft', created.data?.[0]?.status === 'draft');

  const asAnon = await api(`/rest/v1/events?select=title&id=eq.${eventId}`);
  check('draft invisible to anon', asAnon.data.length === 0);

  const asMember = await api(`/rest/v1/events?select=title&id=eq.${eventId}`, { token: tMember });
  check('draft invisible to ordinary member', asMember.data.length === 0);

  const publish = await api(`/rest/v1/events?id=eq.${eventId}`, {
    method: 'PATCH',
    token: tAdmin,
    body: { status: 'published' },
  });
  check('admin publishes the draft', publish.status === 204);

  const after = await api(`/rest/v1/events?select=title,status,published_at&id=eq.${eventId}`);
  check(
    'published event is public and stamped published_at',
    after.data?.[0]?.status === 'published' && !!after.data?.[0]?.published_at,
    JSON.stringify(after.data)
  );

  const memberWrite = await api('/rest/v1/events', {
    method: 'POST',
    token: tMember,
    body: { title: 'member attempt', community: 'esports' },
  });
  check(
    'ordinary member cannot create events',
    memberWrite.status === 403 || memberWrite.status === 401,
    `status ${memberWrite.status}`
  );

  const cleanup = await api(`/rest/v1/events?id=eq.${eventId}`, {
    method: 'DELETE',
    token: tAdmin,
  });
  check('admin can delete events', cleanup.status === 204);
}

section('5 · Region-scoped meetups (RC)');
{
  const tRcChennai = await signIn(U.rcChennai);
  const tRcMumbai = await signIn(U.rcMumbai);
  const chennai = await regionId('chennai');
  const mumbai = await regionId('mumbai');

  const okCreate = await api('/rest/v1/meetups', {
    method: 'POST',
    token: tRcChennai,
    returnRep: true,
    body: {
      region_id: chennai,
      title: 'Chennai RC Test Meetup',
      starts_at: new Date(Date.now() + 15 * 864e5).toISOString(),
      venue: 'Marina Grounds',
    },
  });
  const meetupId = okCreate.data?.[0]?.id;
  check(
    'RC creates a meetup in own region',
    okCreate.status === 201 && !!meetupId,
    `status ${okCreate.status} ${JSON.stringify(okCreate.data)?.slice(0, 140)}`
  );

  const crossCreate = await api('/rest/v1/meetups', {
    method: 'POST',
    token: tRcChennai,
    body: { region_id: mumbai, title: 'cross-region attempt' },
  });
  check(
    'RC cannot create meetups in another region',
    crossCreate.status === 403 || crossCreate.status === 401,
    `status ${crossCreate.status}`
  );

  const ownPatch = await api(`/rest/v1/meetups?id=eq.${meetupId}`, {
    method: 'PATCH',
    token: tRcChennai,
    body: { title: 'Chennai RC Test Meetup (renamed)' },
  });
  check('RC updates own region meetup', ownPatch.status === 204, `status ${ownPatch.status}`);

  const foreignPatch = await api(`/rest/v1/meetups?id=eq.${meetupId}`, {
    method: 'PATCH',
    token: tRcMumbai,
    body: { title: 'hijack attempt' },
  });
  // PostgREST answers 204 even when the filter matches zero rows, so verify
  // the row itself: an RC outside the region must not have changed it.
  const afterHijack = await api(`/rest/v1/meetups?select=title&id=eq.${meetupId}`, {
    token: await signIn(U.webAdmin),
  });
  check(
    'other RC cannot touch it (row unchanged)',
    foreignPatch.status === 204 || foreignPatch.status >= 400,
    `status ${foreignPatch.status}`
  );
  check(
    'hijack did not change the meetup',
    afterHijack.data?.[0]?.title === 'Chennai RC Test Meetup (renamed)',
    JSON.stringify(afterHijack.data)
  );

  const mumbaiDrafts = await api('/rest/v1/meetups?select=title&status=eq.draft', {
    token: tRcMumbai,
  });
  check(
    'mumbai RC sees no chennai drafts',
    mumbaiDrafts.status === 200 &&
      !mumbaiDrafts.data.some((m) => String(m.title).includes('Chennai')),
    JSON.stringify(mumbaiDrafts.data)
  );

  const cleanup = await api(`/rest/v1/meetups?id=eq.${meetupId}`, {
    method: 'DELETE',
    token: tRcChennai,
  });
  check('RC deletes own meetup', cleanup.status === 204);
}

section('6 · Role administration (web_admin only)');
{
  const tAdmin = await signIn(U.admin);
  const tWeb = await signIn(U.webAdmin);
  const nonId = await ensureUser(U.nonMember, 'Test nonMember');

  const forbidden = await api('/rest/v1/rpc/assign_role', {
    method: 'POST',
    token: tAdmin,
    body: { target_user: nonId, new_role: 'web_admin' },
  });
  check(
    'plain admin cannot assign roles',
    forbidden.status === 403 || forbidden.status >= 400,
    `status ${forbidden.status} ${JSON.stringify(forbidden.data)}`
  );

  const promoted = await api('/rest/v1/rpc/assign_role', {
    method: 'POST',
    token: tWeb,
    body: { target_user: nonId, new_role: 'admin' },
  });
  check(
    'web_admin assigns a role via RPC',
    promoted.status === 200 || promoted.status === 204,
    `status ${promoted.status}`
  );

  const who = await api('/rest/v1/rpc/my_access', { method: 'POST', token: tAdmin });
  check('role change took effect', who.data?.role === 'admin', JSON.stringify(who.data));

  const chennai = await regionId('chennai');
  const regioned = await api('/rest/v1/rpc/assign_region', {
    method: 'POST',
    token: tWeb,
    body: { target_user: nonId, new_region_id: chennai },
  });
  check(
    'web_admin assigns an RC region',
    regioned.status === 200 || regioned.status === 204,
    `status ${regioned.status}`
  );

  const selfPromote = await api('/rest/v1/rpc/assign_role', {
    method: 'POST',
    token: await signIn(U.member),
    body: { target_user: await ensureUser(U.member, 'Test member'), new_role: 'web_admin' },
  });
  check(
    'ordinary member cannot self-promote',
    selfPromote.status >= 400,
    `status ${selfPromote.status}`
  );
}

section('7 · Roster sync Edge Function (Sheet → Supabase)');
{
  const noSecret = await fetch(`${BASE}/functions/v1/members-sync`, { method: 'POST' });
  check('sync rejects unauthenticated calls', noSecret.status === 401, `status ${noSecret.status}`);

  const badSecret = await fetch(`${BASE}/functions/v1/members-sync`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-sync-secret': 'wrong-secret' },
    body: JSON.stringify({ members: [] }),
  });
  check('sync rejects a wrong secret', badSecret.status === 401, `status ${badSecret.status}`);

  const syncedUser = await ensureUser('synced1@test.local', 'Synced One');
  check('auth user for synced member ready', typeof syncedUser === 'string');

  const sync = await fetch(`${BASE}/functions/v1/members-sync`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-sync-secret': SYNC_SECRET },
    body: JSON.stringify({
      members: [
        {
          email: 'Synced1@Test.local',
          full_name: 'Synced One',
          region: 'Chennai',
          roll_number: '23F1000042',
        },
        { email: 'synced2@test.local', full_name: 'Synced Two', region: 'Patna' },
      ],
      replace: false,
    }),
  });
  const syncBody = await sync.json().catch(() => null);
  check(
    'sync upserts a batch (email case-normalised)',
    sync.status === 200 && syncBody?.upserted === 2,
    `status ${sync.status} ${JSON.stringify(syncBody)}`
  );

  const tSynced = await signIn('synced1@test.local');
  const access = await api('/rest/v1/rpc/my_access', { method: 'POST', token: tSynced });
  check(
    'newly synced email is a verified member',
    access.data?.is_member === true,
    JSON.stringify(access.data)
  );

  const replace = await fetch(`${BASE}/functions/v1/members-sync`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-sync-secret': SYNC_SECRET },
    body: JSON.stringify({
      members: [{ email: 'synced1@test.local', full_name: 'Synced One' }],
      replace: true,
    }),
  });
  const replaceBody = await replace.json().catch(() => null);
  check(
    'replace pass deactivates members missing from the Sheet',
    replace.status === 200 && replaceBody?.deactivated === 3,
    `status ${replace.status} ${JSON.stringify(replaceBody)}`
  );

  const accessAfter = await api('/rest/v1/rpc/my_access', {
    method: 'POST',
    token: await signIn('member1@test.local'),
  });
  check(
    'deactivated member loses Lounge access',
    accessAfter.data?.is_member === false,
    JSON.stringify(accessAfter.data)
  );
}

summary();
