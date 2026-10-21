import { test, expect } from '@playwright/test';
import { adminSections, mockSupabase, callTo } from './supabase-mock.js';

test.beforeEach(({ page }) => page.emulateMedia({ reducedMotion: 'reduce' }));

const STUDENT = {
  found: true,
  source: 'student',
  pending: null,
  student: {
    id: 'a9000000-0000-4000-8000-000000000010',
    email: '21f1000010@ds.study.iitm.ac.in',
    full_name: 'Tara Banerjee',
    preferred_name: 'Tara',
    roll_number: '21f1000010',
    phone: '+919810000010',
    gender: 'F',
    region_id: 5,
    region_name: 'Kolkata',
    cohort: '21F1',
    account_status: 'active',
    created_at: '2026-10-02T00:00:00Z',
    last_login_at: '2026-10-20T00:00:00Z',
    is_super_admin: false,
    position: {
      position: 'head',
      community_id: 3,
      community_name: 'Cultural',
      region_id: null,
      region_name: null,
    },
    forms: [
      {
        response_id: 'f1',
        form_id: 'g1',
        form_title: 'Join the Kolkata group',
        form_kind: 'group',
        group_label: 'Kolkata Group A',
        submitted_at: '2026-10-05T00:00:00Z',
      },
    ],
  },
};
const PENDING = {
  found: true,
  source: 'pending',
  student: null,
  pending: {
    email: '21f1000011@ds.study.iitm.ac.in',
    full_name: 'Waiting Student',
    phone: null,
    gender: null,
    region_id: 1,
    region_name: 'Patna',
    cohort: '21F1',
    account_status: 'pending',
    added_at: '2026-10-09T00:00:00Z',
    added_by: {
      id: 'a9000000-0000-4000-8000-000000000003',
      full_name: 'Arjun Rao',
      email: 'x@y.z',
    },
  },
};
const NOT_FOUND = { found: false, source: null, student: null, pending: null };

const lookup = (args) =>
  ({
    '21f1000010@ds.study.iitm.ac.in': STUDENT,
    '21f1000011@ds.study.iitm.ac.in': PENDING,
  })[args.p_email] ?? NOT_FOUND;

test('a head sees the Find email tab and nothing else from the student desk', async ({ page }) => {
  await mockSupabase(page, { as: 'head', data: { admin_lookup_email: lookup } });
  await page.goto('/#/admin');
  const nav = adminSections(page);
  for (const label of ['Overview', 'Events', 'Forms', 'Find email'])
    await expect(nav.getByRole('button', { name: new RegExp(`^${label}`) })).toBeVisible();
  for (const label of ['Students', 'Roster', 'Requests', 'Positions'])
    await expect(nav.getByRole('button', { name: new RegExp(`^${label}`) })).toHaveCount(0);
  await nav.getByRole('button', { name: 'Find email' }).click();
  await expect(page.getByRole('heading', { name: 'Find email' })).toBeVisible();
  // Nothing is shown before a search.
  await expect(page.getByRole('article')).toHaveCount(0);
  await expect(page.getByText('No one in Sundarbans House')).toHaveCount(0);
});

test('lookup shows a student across regions and records one RPC per search', async ({ page }) => {
  const calls = await mockSupabase(page, { as: 'head', data: { admin_lookup_email: lookup } });
  await page.goto('/#/admin?tab=lookup');
  await page.getByLabel('Email').fill('  21F1000010@DS.study.iitm.ac.in ');
  await page.getByRole('button', { name: 'Find', exact: true }).click();
  const card = page.getByRole('article', { name: 'Student' });
  await expect(card.getByRole('heading', { name: 'Kolkata' })).toBeVisible();
  await expect(card.getByText('Student', { exact: true })).toBeVisible();
  await expect(card.getByText('active', { exact: true })).toBeVisible();
  await expect(card.getByText('+919810000010')).toBeVisible();
  await expect(card.getByText('21f1000010', { exact: true })).toBeVisible();
  await expect(card.getByText('Head, Cultural')).toBeVisible();
  await expect(card.getByText('Join the Kolkata group')).toBeVisible();
  await expect(card.getByText('Kolkata Group A')).toBeVisible();
  const call = await callTo(calls, '/rest/v1/rpc/admin_lookup_email');
  expect(JSON.parse(call.body)).toEqual({ p_email: '21f1000010@ds.study.iitm.ac.in' });
  expect(calls.filter((c) => c.path === '/rest/v1/rpc/admin_lookup_email')).toHaveLength(1);
});

test('lookup shows a pending roster entry and a clear not-found message', async ({ page }) => {
  await mockSupabase(page, { as: 'rc', data: { admin_lookup_email: lookup } });
  await page.goto('/#/admin?tab=lookup');
  const email = page.getByLabel('Email');
  await email.fill('21f1000011@ds.study.iitm.ac.in');
  await page.getByRole('button', { name: 'Find', exact: true }).click();
  const card = page.getByRole('article', { name: 'Pending roster entry' });
  await expect(card.getByRole('heading', { name: 'Patna' })).toBeVisible();
  await expect(card.getByText('Pending roster', { exact: true })).toBeVisible();
  await expect(card.getByText('Arjun Rao')).toBeVisible();
  await expect(card.getByText(/have not signed in/)).toBeVisible();

  await email.fill('nobody@ds.study.iitm.ac.in');
  await expect(page.getByRole('article')).toHaveCount(0);
  await page.getByRole('button', { name: 'Find', exact: true }).click();
  await expect(page.getByText('No one in Sundarbans House uses this email.')).toBeVisible();
});

test('an invalid email is stopped before any request and errors are shown', async ({ page }) => {
  const calls = await mockSupabase(page, {
    as: 'sa',
    data: { admin_lookup_email: lookup },
  });
  await page.goto('/#/admin?tab=lookup');
  await expect(page.getByText('Loading admin data...')).toHaveCount(0);
  await page.getByLabel('Email').fill('not-an-email');
  await page.getByRole('button', { name: 'Find', exact: true }).click();
  await expect(page.getByRole('alert')).toContainText('Enter the full email');
  await page.getByLabel('Email').fill('');
  await page.getByRole('button', { name: 'Find', exact: true }).click();
  await expect(page.getByRole('alert')).toContainText('Type an email');
  expect(calls.some((c) => c.path === '/rest/v1/rpc/admin_lookup_email')).toBe(false);
});

test('a refused lookup shows the error', async ({ page }) => {
  await mockSupabase(page, { as: 'rc' });
  await page.route('**/rest/v1/rpc/admin_lookup_email', (route) =>
    route.fulfill({
      status: 403,
      headers: { 'access-control-allow-origin': '*', 'content-type': 'application/json' },
      body: JSON.stringify({ code: '42501', message: 'Admin access is required' }),
    })
  );
  await page.goto('/#/admin?tab=lookup');
  await page.getByLabel('Email').fill('21f1000010@ds.study.iitm.ac.in');
  await page.getByRole('button', { name: 'Find', exact: true }).click();
  await expect(page.getByRole('alert')).toBeVisible();
});

test('hitting the hourly limit shows the server message and can be retried', async ({ page }) => {
  await mockSupabase(page, { as: 'head' });
  await page.route('**/rest/v1/rpc/admin_lookup_email', (route) =>
    route.fulfill({
      status: 400,
      headers: { 'access-control-allow-origin': '*', 'content-type': 'application/json' },
      body: JSON.stringify({
        code: '54000',
        message: 'Too many lookups in the last hour. Try again later.',
      }),
    })
  );
  await page.goto('/#/admin?tab=lookup');
  await page.getByLabel('Email').fill('21f1000010@ds.study.iitm.ac.in');
  await page.getByRole('button', { name: 'Find', exact: true }).click();
  await expect(page.getByRole('alert')).toContainText(
    'Too many lookups in the last hour. Try again later.'
  );
  await expect(page.getByRole('article')).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'Find', exact: true })).toBeEnabled();
});

test('a Super Admin sees a soft-deleted student with the deleted badge', async ({ page }) => {
  const deleted = {
    ...STUDENT,
    student: { ...STUDENT.student, account_status: 'deleted', deleted_at: '2026-10-15T00:00:00Z' },
  };
  await mockSupabase(page, { as: 'sa', data: { admin_lookup_email: () => deleted } });
  await page.goto('/#/admin?tab=lookup');
  await page.getByLabel('Email').fill('21f1000010@ds.study.iitm.ac.in');
  await page.getByRole('button', { name: 'Find', exact: true }).click();
  const card = page.getByRole('article', { name: 'Student' });
  await expect(card.getByText('deleted', { exact: true })).toBeVisible();
});
