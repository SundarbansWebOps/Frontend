import { test, expect } from '@playwright/test';
import { adminSections, mockSupabase, PEOPLE, callTo } from './supabase-mock.js';

test.beforeEach(({ page }) => page.emulateMedia({ reducedMotion: 'reduce' }));

test('signed-out visitors are sent to the sign-in door', async ({ page }) => {
  await mockSupabase(page, { signedIn: false });
  await page.goto('/#/lounge');
  await expect(page).toHaveURL(/#\/login\?next=\/lounge$/);
  await expect(
    page.getByRole('button', { name: 'Sign in with Google', exact: true })
  ).toBeVisible();
  await page.goto('/#/admin');
  await expect(page).toHaveURL(/#\/login\?next=\/admin$/);
});

test('Google sign-in for a rostered member lands in the Lounge', async ({ page }) => {
  const calls = await mockSupabase(page, { signedIn: false, google: 'ok' });
  await page.goto('/#/login');
  await page.getByRole('button', { name: 'Sign in with Google', exact: true }).click();
  await expect(page.locator('.lounge-active, .home, .tour').first()).toBeVisible();
  await expect(page).toHaveURL(/#\/lounge/);
  const authorize = calls.find((c) => c.path === '/auth/v1/authorize');
  const params = new URL(authorize.url).searchParams;
  expect(params.get('provider')).toBe('google');
  expect(params.get('prompt')).toBe('select_account');
  expect(params.has('hd')).toBe(false);
  expect(params.get('code_challenge_method')).toBe('s256');
  // The code was exchanged and the address bar is clean again.
  expect(calls.some((c) => c.path === '/auth/v1/token')).toBe(true);
  expect(new URL(page.url()).search).toBe('');
});

test('Google sign-in for someone not on the roster is refused with a clear message', async ({
  page,
}) => {
  await mockSupabase(page, { signedIn: false, google: 'refused' });
  await page.goto('/#/login');
  await page.getByRole('button', { name: 'Sign in with Google', exact: true }).click();
  await expect(page.getByRole('alert')).toHaveText(
    'Access Denied. Sign in with your IITM student email or ask your regional coordinator to add you.'
  );
  await expect(page).toHaveURL(/#\/login$/);
  await expect(page.locator('.home, .tour')).toHaveCount(0);
});

test('a normal member cannot open the admin lounge', async ({ page }) => {
  await mockSupabase(page, { as: 'member' });
  await page.goto('/#/admin');
  await expect(page).toHaveURL(/#\/lounge$/);
  await page.getByRole('button', { name: /Your profile/ }).click();
  await expect(page.getByRole('button', { name: /My certificates/ })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Admin lounge' })).toHaveCount(0);
});

test('a Regional Coordinator opens the admin lounge from the Lounge', async ({ page }) => {
  const calls = await mockSupabase(page, {
    as: 'rc',
    data: {
      roster_add_many: (args) =>
        (args.p_rows || []).map((r) => ({ email: r.email, ok: true, category: 'processed' })),
    },
  });
  await page.goto('/#/lounge');
  await page.getByRole('button', { name: /Your profile/ }).click();
  await page.getByRole('button', { name: 'Admin lounge' }).click();
  await expect(page).toHaveURL(/#\/admin/);
  await expect(page.getByRole('heading', { name: /Good .+, Arjun Rao/ })).toBeVisible();
  await page.getByRole('button', { name: 'Your account' }).click();
  const account = page.getByRole('dialog', { name: 'Your account' });
  await expect(account.getByText('Regional Coordinator')).toBeVisible();
  await expect(account.getByText('Patna', { exact: true })).toBeVisible();
  await account.getByRole('button', { name: 'Close' }).click();
  const nav = adminSections(page);
  for (const label of ['Overview', 'Requests', 'Students', 'Roster', 'Events', 'Forms', 'Notices'])
    await expect(nav.getByRole('button', { name: new RegExp(`^${label}`) })).toBeVisible();
  await expect(nav.getByRole('button', { name: 'Positions' })).toHaveCount(0);
  await nav.getByRole('button', { name: 'Roster' }).click();
  await expect(page.getByRole('heading', { name: 'Roster' })).toBeVisible();
  await expect(page.getByText('Loading admin data...')).toHaveCount(0);
  await page.getByRole('button', { name: 'Add students' }).click();
  const dialog = page.getByRole('dialog', { name: 'Add students' });
  await expect(dialog.getByText('Added to Patna.')).toBeVisible();
  // Phone is optional: a student can be added with email and name only.
  await dialog.getByLabel('IITM email').fill('21f1000001@ds.study.iitm.ac.in');
  await dialog.getByLabel(/^Full name/).fill('No Phone Student');
  await dialog.getByRole('button', { name: 'Add to roster' }).click();
  await expect(
    dialog.getByText('1 processed, 0 invalid. Existing identities are preserved.')
  ).toBeVisible();
  const added = await callTo(calls, '/rest/v1/rpc/roster_add_many');
  expect(JSON.parse(added.body).p_rows[0]).toMatchObject({
    email: '21f1000001@ds.study.iitm.ac.in',
    full_name: 'No Phone Student',
    region_id: null,
  });
  await dialog.getByRole('button', { name: 'Close' }).click();
  await expect(dialog).toHaveCount(0);
  await expect(page.locator('html.adm-sheet-open')).toHaveCount(0);
  expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBe(
    await page.evaluate(() => innerWidth)
  );
});

test('the account menu hangs from the profile button', async ({ page }) => {
  await mockSupabase(page, { as: 'sa' });
  for (const width of [1366, 390]) {
    await page.setViewportSize({ width, height: 900 });
    await page.goto('/#/admin');
    const avatar = page.getByRole('button', { name: 'Your account' });
    await avatar.click();
    const dialog = page.getByRole('dialog', { name: 'Your account' });
    await expect(dialog).toBeVisible();
    const a = await avatar.boundingBox();
    const d = await dialog.boundingBox();
    expect(Math.abs(a.x + a.width - (d.x + d.width))).toBeLessThanOrEqual(8);
    expect(d.y).toBeGreaterThan(a.y + a.height - 4);
    await dialog.getByRole('button', { name: 'Close' }).click();
  }
});

test('a Super Admin approves another admin’s request', async ({ page }) => {
  const request = {
    id: 'b0000000-0000-4000-8000-000000000001',
    type: 'member_profile_update',
    status: 'pending',
    reason: 'New WhatsApp number',
    requested_change: { phone: '+919990000044' },
    target_snapshot: {},
    review_note: null,
    requested_at: '2026-10-08T10:00:00Z',
    reviewed_at: null,
    requested_by: PEOPLE.rc.id,
    reviewed_by: null,
    target_member_id: PEOPLE.member.id,
    target: { full_name: 'Riya Venkataraman', member_code: '99f9000004', region_id: 1 },
    requester: { full_name: 'Arjun Rao' },
  };
  const calls = await mockSupabase(page, {
    as: 'sa',
    data: { approval_requests: [request], approve_request: request.id },
  });
  await page.goto('/#/admin?tab=requests');
  const nav = adminSections(page);
  for (const label of [
    'Overview',
    'Requests',
    'Students',
    'Roster',
    'Events',
    'Forms',
    'Notices',
    'Positions',
    'Activity',
  ])
    await expect(nav.getByRole('button', { name: new RegExp(`^${label}`) })).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Requests' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Phone' })).toBeVisible();
  await expect(page.getByRole('cell', { name: '+919990000044' })).toBeVisible();
  await expect(page.getByText('Arjun Rao')).toBeVisible();
  await page.getByRole('button', { name: 'Approve', exact: true }).click();
  await expect(page.getByRole('status').filter({ hasText: 'Approved and applied.' })).toBeVisible();
  expect(calls.some((c) => c.path === '/rest/v1/rpc/approve_request')).toBe(true);
});

test('a login email change is approved through change-member-contact', async ({ page }) => {
  const request = {
    id: 'b0000000-0000-4000-8000-000000000002',
    type: 'member_contact_change',
    status: 'pending',
    reason: 'Roll number corrected',
    requested_change: { email: '21f1000099@ds.study.iitm.ac.in' },
    target_snapshot: {},
    review_note: null,
    requested_at: '2026-10-08T10:00:00Z',
    reviewed_at: null,
    requested_by: PEOPLE.rc.id,
    reviewed_by: null,
    target_member_id: PEOPLE.member.id,
    target: { full_name: 'Riya Venkataraman', member_code: '99f9000004', region_id: 1 },
    requester: { full_name: 'Another Super Admin' },
  };
  const calls = await mockSupabase(page, { as: 'sa', data: { approval_requests: [request] } });
  await page.goto('/#/admin?tab=requests');
  await expect(page.getByRole('heading', { name: 'Requests' })).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Login email' })).toBeVisible();
  await expect(page.getByRole('cell', { name: '21f1000099@ds.study.iitm.ac.in' })).toBeVisible();
  await page.getByLabel('Review note, optional').fill('Checked with the student');
  await page.getByRole('button', { name: 'Approve', exact: true }).click();
  await expect(
    page.getByRole('status').filter({ hasText: 'Approved. Their sign-in now uses the new email.' })
  ).toBeVisible();
  const fn = await callTo(calls, '/functions/v1/change-member-contact');
  expect(JSON.parse(fn.body)).toEqual({ request_id: request.id, note: 'Checked with the student' });
  expect(calls.some((c) => c.path === '/rest/v1/rpc/approve_request')).toBe(false);
});
