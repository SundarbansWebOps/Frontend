// Identity and role always move together. A previous account's late query must not hydrate
// the current account, including when the previous query reports an error.
export function createProfileSession(state, getClient, formatError) {
  let generation = 0;
  let pending = Promise.resolve();
  let signalChange;
  let changed = new Promise((resolve) => (signalChange = resolve));
  const current = (uid, token) => token === generation && state.session?.user?.id === uid;

  async function load(uid, token) {
    try {
      const client = await getClient();
      if (!current(uid, token)) return;
      const [dash, me] = await Promise.all([
        client.rpc('get_my_dashboard'),
        client
          .from('members')
          .select(
            'id, member_code, full_name, preferred_name, email, phone, region_id, tour_seen_at, certificate_name, certificate_name_confirmed_at, cohort, region:regions(code, name)'
          )
          .eq('id', uid)
          .maybeSingle(),
      ]);
      if (!current(uid, token)) return;
      if (dash.error || me.error || !me.data || me.data.id !== uid) {
        state.error = formatError(
          dash.error?.message || me.error?.message || 'Account is not active'
        );
        await client.auth.signOut({ scope: 'local' });
        if (!current(uid, token)) return;
        state.session = state.profile = state.dashboard = null;
        return;
      }
      state.profile = me.data;
      state.dashboard = dash.data;
    } catch (error) {
      if (!current(uid, token)) return;
      state.error = formatError(error?.message);
      state.profile = state.dashboard = null;
    }
  }

  function adopt(session) {
    const before = state.session?.user?.id;
    const uid = session?.user?.id;
    state.session = session;
    if (uid && uid === before && state.profile?.id === uid) return;
    signalChange();
    changed = new Promise((resolve) => (signalChange = resolve));
    const token = ++generation;
    state.profile = state.dashboard = null;
    pending = uid ? load(uid, token) : Promise.resolve();
  }

  async function ready() {
    // An account change while a guard waits must also finish loading before the guard proceeds.
    let waiting;
    do {
      waiting = pending;
      // A stalled old account must not block navigation for the current account.
      await Promise.race([waiting, changed]);
    } while (waiting !== pending);
  }

  return { adopt, ready };
}
