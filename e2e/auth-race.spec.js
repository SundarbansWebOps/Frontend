import { test, expect } from '@playwright/test';
import { createProfileSession } from '../src/lib/auth-profile.js';

function deferred() {
  let resolve;
  const promise = new Promise((done) => (resolve = done));
  return { promise, resolve };
}

function setup() {
  const state = { session: null, profile: null, dashboard: null, error: '' };
  const requests = [];
  let signOuts = 0;
  const client = {
    rpc: async () => ({ data: { role: 'normal' }, error: null }),
    from: () => {
      let uid;
      const query = {
        select: () => query,
        eq: (_key, value) => {
          uid = value;
          return query;
        },
        maybeSingle: () => {
          const request = { uid, ...deferred() };
          requests.push(request);
          return request.promise;
        },
      };
      return query;
    },
    auth: { signOut: async () => signOuts++ },
  };
  return {
    state,
    requests,
    signOuts: () => signOuts,
    session: createProfileSession(
      state,
      async () => client,
      (m) => m
    ),
  };
}

test('account changes clear prior identity and late responses cannot overwrite the new member', async () => {
  const f = setup();
  f.session.adopt({ user: { id: 'admin' } });
  await expect.poll(() => f.requests.length).toBe(1);
  f.requests[0].resolve({ data: { id: 'admin' }, error: null });
  await f.session.ready();
  expect(f.state.profile.id).toBe('admin');
  f.state.dashboard = { role: 'super_admin' };
  f.session.adopt({ user: { id: 'old' } });
  expect(f.state.profile).toBeNull();
  expect(f.state.dashboard).toBeNull();
  await expect.poll(() => f.requests.length).toBe(2);
  f.session.adopt({ user: { id: 'new' } });
  await expect.poll(() => f.requests.length).toBe(3);
  f.requests[2].resolve({ data: { id: 'new' }, error: null });
  await f.session.ready();
  f.requests[1].resolve({ data: { id: 'old' }, error: null });
  await f.requests[1].promise;
  await f.session.ready();
  expect(f.state.profile.id).toBe('new');
  expect(f.state.dashboard.role).toBe('normal');
});

test('a stale profile refusal cannot sign out a newer session', async () => {
  const f = setup();
  f.session.adopt({ user: { id: 'old' } });
  await expect.poll(() => f.requests.length).toBe(1);
  f.session.adopt({ user: { id: 'new' } });
  await expect.poll(() => f.requests.length).toBe(2);
  f.requests[1].resolve({ data: { id: 'new' }, error: null });
  await f.session.ready();
  f.requests[0].resolve({ data: null, error: { message: 'Account is not active' } });
  await f.requests[0].promise;
  expect(f.signOuts()).toBe(0);
  expect(f.state.session.user.id).toBe('new');
  expect(f.state.error).toBe('');
});

test('sign-out invalidates profile work still in flight', async () => {
  const f = setup();
  f.session.adopt({ user: { id: 'old' } });
  await expect.poll(() => f.requests.length).toBe(1);
  f.session.adopt(null);
  f.requests[0].resolve({ data: { id: 'old' }, error: null });
  await f.requests[0].promise;
  await f.session.ready();
  expect(f.state.session).toBeNull();
  expect(f.state.profile).toBeNull();
  expect(f.state.dashboard).toBeNull();
});

test('a guard waiting on an old stalled profile follows the new account', async () => {
  const f = setup();
  f.session.adopt({ user: { id: 'old' } });
  await expect.poll(() => f.requests.length).toBe(1);
  let ready = false;
  const guard = f.session.ready().then(() => (ready = true));
  f.session.adopt({ user: { id: 'new' } });
  await expect.poll(() => f.requests.length).toBe(2);
  f.requests[1].resolve({ data: { id: 'new' }, error: null });
  await expect.poll(() => ready).toBe(true);
  await guard;
  expect(f.state.profile.id).toBe('new');
  // Old request deliberately remains unresolved.
});
