import { test, expect } from '@playwright/test';
import { mockSupabase, PEOPLE, callTo } from './supabase-mock.js';

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
  await expect(page.getByRole('button', { name: 'Sign out', exact: true })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Admin lounge' })).toHaveCount(0);
});

test('a Regional Coordinator opens the admin lounge from the Lounge', async ({ page }) => {
  const calls = await mockSupabase(page, { as: 'rc', data: { roster_add: 'ok' } });
  await page.goto('/#/lounge');
  await page.getByRole('button', { name: /Your profile/ }).click();
  await page.getByRole('button', { name: 'Admin lounge' }).click();
  await expect(page).toHaveURL(/#\/admin/);
  await expect(page.getByRole('heading', { name: 'Admin lounge', level: 1 })).toBeVisible();
  await expect(page.getByText('Regional Coordinator · Patna')).toBeVisible();
  const tabs = page.getByRole('tab');
  await expect(tabs).toHaveText(['Students', 'Roster', 'Events', 'Forms', 'Notices', 'Requests']);
  await page.getByRole('tab', { name: 'Roster' }).click();
  await expect(page.getByText('Added to Patna.')).toBeVisible();
  // Phone is optional: a student can be added with email and name only.
  await page.getByLabel('IITM email').fill('21f1000001@ds.study.iitm.ac.in');
  await page.getByLabel(/^Full name/).fill('No Phone Student');
  await page.getByRole('button', { name: 'Add to roster' }).first().click();
  await expect(
    page.getByText('21f1000001@ds.study.iitm.ac.in can now sign in with Google.')
  ).toBeVisible();
  const added = await callTo(calls, '/rest/v1/rpc/roster_add');
  expect(JSON.parse(added.body)).toMatchObject({
    p_email: '21f1000001@ds.study.iitm.ac.in',
    p_phone: null,
    p_region_id: null,
  });
  expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBe(
    await page.evaluate(() => innerWidth)
  );
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
  await expect(page.getByRole('tab')).toHaveText([
    'Students',
    'Roster',
    'Events',
    'Forms',
    'Notices',
    /Requests/,
    'Positions',
    'Audit log',
  ]);
  await expect(page.getByText('Phone → +919990000044')).toBeVisible();
  await expect(page.getByText('Asked by Arjun Rao')).toBeVisible();
  await page.getByRole('button', { name: 'Approve', exact: true }).click();
  await expect(page.getByRole('status')).toHaveText('Approved and applied.');
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
  await expect(page.getByText('Login email → 21f1000099@ds.study.iitm.ac.in')).toBeVisible();
  await page.getByPlaceholder('Note (optional)').fill('Checked with the student');
  await page.getByRole('button', { name: 'Approve', exact: true }).click();
  await expect(page.getByRole('status')).toHaveText(
    'Approved. Their sign-in now uses the new email.'
  );
  const fn = await callTo(calls, '/functions/v1/change-member-contact');
  expect(JSON.parse(fn.body)).toEqual({ request_id: request.id, note: 'Checked with the student' });
  expect(calls.some((c) => c.path === '/rest/v1/rpc/approve_request')).toBe(false);
});
