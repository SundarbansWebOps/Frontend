// Members' sign-in: Google only, for people whose member profile exists (the database refuses
// anyone who is not on the house roster). Holds the session, the member's own row and their role
// from get_my_dashboard(). Imported first by main.js so a Google redirect is handled before the
// router reads the URL. supabase-js is loaded only when a member page or a Google redirect needs
// it, so the public pages stay light.
import { computed, reactive } from 'vue';
import { createProfileSession } from './auth-profile.js';

let client;
const sb = async () => (client ??= (await import('./supabase.js')).supabase);

export const auth = reactive({
  ready: false,
  session: null,
  profile: null, // own members row: phone, tour_seen_at, certificate_name, cohort, region
  dashboard: null, // { role: 'super_admin' | 'admin' | 'normal', position, region_id, community_id }
  error: '',
});

// Where to go once Google sends the member back (set before leaving for Google).
const NEXT_KEY = 'sundarbans_sign_in_next';

export const isSuperAdmin = computed(() => auth.dashboard?.role === 'super_admin');
export const isRc = computed(
  () => auth.dashboard?.role === 'admin' && auth.dashboard?.position === 'rc'
);
export const isHead = computed(
  () =>
    auth.dashboard?.role === 'admin' &&
    (auth.dashboard?.position === 'head' || auth.dashboard?.position === 'co_head')
);
// Heads and Co-Heads can open Admin; the admin page hides student tabs for them.
export const canAdmin = computed(() => isSuperAdmin.value || isRc.value || isHead.value);

function friendly(message) {
  const m = String(message ?? '');
  // Any refusal by the sign-up trigger (not on the roster, other domain, blacklisted) reaches the
  // browser as this one generic Auth message.
  if (/database error saving new user/i.test(m))
    return 'Access Denied. Sign in with your IITM student email or ask your regional coordinator to add you.';
  if (/banned/i.test(m)) return 'Your account is not active. Contact your Regional Coordinator.';
  if (/not active/i.test(m))
    return 'Your account is not active. Contact your Regional Coordinator.';
  return m ? `Sign-in failed: ${m}` : 'Sign-in failed. Please try again.';
}

// Google's answer comes back as ?code=… on success or ?error_description=… on failure (either
// in the query or, for some errors, in the # part). Take it out of the address bar, keep the
// error, and land on the sign-in door.
function readCallback() {
  const url = new URL(location.href);
  const hashParams = new URLSearchParams(url.hash.replace(/^#\/?/, '').split('?').pop());
  const description =
    url.searchParams.get('error_description') || hashParams.get('error_description');
  if (description) {
    auth.error = friendly(description.replace(/\+/g, ' '));
    history.replaceState(history.state, '', `${url.origin}${url.pathname}#/login`);
    return 'error';
  }
  if (!url.searchParams.has('code')) return null;
  // Back from Google: show the sign-in door, which carries on to the Lounge (or /admin).
  history.replaceState(history.state, '', `${url.origin}${url.pathname}${url.search}#/login`);
  return 'code';
}

const callback = readCallback();

function clearCodeFromUrl() {
  const url = new URL(location.href);
  if (!url.searchParams.has('code')) return;
  url.searchParams.delete('code');
  url.searchParams.delete('sb_flow_id');
  history.replaceState(history.state, '', `${url.origin}${url.pathname}${url.search}${url.hash}`);
}

const profiles = createProfileSession(auth, sb, friendly);

let readyPromise;
export function authReady() {
  readyPromise ??= (async () => {
    const supabase = await sb();
    const { data, error } = await supabase.auth.getSession();
    if (error && callback === 'code') auth.error = friendly(error.message);
    profiles.adopt(data?.session ?? null);
    if (callback === 'code') clearCodeFromUrl();
    await profiles.ready();
    auth.ready = true;
    supabase.auth.onAuthStateChange((_event, session) => {
      // Do not await Supabase calls inside its auth callback (the auth client holds a lock).
      profiles.adopt(session);
    });
  })();
  return readyPromise.then(() => profiles.ready());
}

export function takeNext() {
  try {
    const next = sessionStorage.getItem(NEXT_KEY);
    sessionStorage.removeItem(NEXT_KEY);
    return next;
  } catch {
    return null;
  }
}

export async function signInWithGoogle(next = '/lounge') {
  auth.error = '';
  try {
    sessionStorage.setItem(NEXT_KEY, next);
  } catch {
    /* Storage blocked: the member lands in the Lounge, the default. */
  }
  const supabase = await sb();
  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: `${location.origin}${location.pathname}`,
      // Four IITM domains are eligible; the roster check in the database is what enforces it.
      queryParams: { prompt: 'select_account' },
    },
  });
  if (error) {
    auth.error = friendly(error.message);
    throw error;
  }
}

export async function signOut() {
  const supabase = await sb();
  // This device only; a member signed in elsewhere stays signed in there.
  await supabase.auth.signOut({ scope: 'local' });
  profiles.adopt(null);
}

// Error text from an RPC, ready to show (the database writes them for people).
export function errorText(error) {
  if (!error) return '';
  if (error.code === '42501') return error.message || 'You are not allowed to do that.';
  return error.message || 'Something went wrong. Please try again.';
}

// Start at once when it matters: back from Google, or a saved session (the member is likely
// heading for the Lounge). Otherwise the guards and the sign-in door start it on demand.
function hasSavedSession() {
  try {
    return Object.keys(localStorage).some((k) => /^sb-.+-auth-token$/.test(k));
  } catch {
    return false;
  }
}
const savedSession = hasSavedSession();
// True from the first paint for a returning member, before their session is verified: a saved
// session on this device is the hint. The navbar shows "Lounge" and the avatar at once, then
// settles on the verified answer (no session or no member row flips it to "Sign in").
export const signedIn = computed(() =>
  auth.ready ? Boolean(auth.session && auth.profile) : savedSession
);
if (callback || savedSession) authReady();
