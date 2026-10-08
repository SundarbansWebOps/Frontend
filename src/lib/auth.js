// Members' sign-in: Google only, for people whose member profile exists (the database refuses
// anyone who is not on the house roster). Holds the session, the member's own row and their role
// from get_my_dashboard(). Imported first by main.js so a Google redirect is handled before the
// router reads the URL. supabase-js is loaded only when a member page or a Google redirect needs
// it, so the public pages stay light.
import { computed, reactive } from 'vue';

let client;
const sb = async () => (client ??= (await import('./supabase.js')).supabase);

export const auth = reactive({
  ready: false,
  session: null,
  profile: null, // { id, member_code, full_name, preferred_name, email, region_id, region: { code, name } }
  dashboard: null, // { role: 'super_admin' | 'admin' | 'normal', position, region_id, community_id }
  error: '',
});

// Where to go once Google sends the member back (set before leaving for Google).
const NEXT_KEY = 'sundarbans_sign_in_next';

export const isSuperAdmin = computed(() => auth.dashboard?.role === 'super_admin');
export const isRc = computed(
  () => auth.dashboard?.role === 'admin' && auth.dashboard?.position === 'rc'
);
// The admin lounge is for Regional Coordinators and Super Admins only.
export const canAdmin = computed(() => isSuperAdmin.value || isRc.value);

function friendly(message) {
  const m = String(message ?? '');
  // Any refusal by the sign-up trigger (not on the roster, other domain, blacklisted) reaches the
  // browser as this one generic Auth message.
  if (/database error saving new user/i.test(m))
    return 'This Google account is not on the house roster. Sign in with your IITM student email, or ask your Regional Coordinator to add you.';
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

async function loadProfile() {
  const supabase = await sb();
  const uid = auth.session?.user?.id;
  if (!uid) {
    auth.profile = auth.dashboard = null;
    return;
  }
  const [dash, me] = await Promise.all([
    supabase.rpc('get_my_dashboard'),
    supabase
      .from('members')
      .select(
        'id, member_code, full_name, preferred_name, email, region_id, region:regions(code, name)'
      )
      .eq('id', uid)
      .maybeSingle(),
  ]);
  if (dash.error || me.error || !me.data) {
    // Signed in to Auth but not an active member: never leave a half-open session behind.
    auth.error = friendly(dash.error?.message || me.error?.message || 'Account is not active');
    await supabase.auth.signOut({ scope: 'local' });
    auth.session = auth.profile = auth.dashboard = null;
    return;
  }
  auth.dashboard = dash.data;
  auth.profile = me.data;
}

let readyPromise;
export function authReady() {
  readyPromise ??= (async () => {
    const supabase = await sb();
    const { data, error } = await supabase.auth.getSession();
    if (error && callback === 'code') auth.error = friendly(error.message);
    auth.session = data?.session ?? null;
    if (callback === 'code') clearCodeFromUrl();
    await loadProfile();
    auth.ready = true;
    supabase.auth.onAuthStateChange((event, session) => {
      const before = auth.session?.user?.id;
      auth.session = session;
      if (event === 'SIGNED_OUT') auth.profile = auth.dashboard = null;
      else if (session?.user?.id !== before) loadProfile();
    });
  })();
  return readyPromise;
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
      // Suggest the IITM student account; the roster check in the database is what enforces it.
      queryParams: { hd: 'ds.study.iitm.ac.in', prompt: 'select_account' },
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
  auth.session = auth.profile = auth.dashboard = null;
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
if (callback || hasSavedSession()) authReady();
