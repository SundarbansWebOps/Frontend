// The Super Admin audit log: sentences from admin_audit_feed rows, filters that become RPC
// arguments and live in the URL, one member's timeline, the before/after detail and paging.
import { test, expect } from '@playwright/test';
import { mockSupabase, callTo } from './supabase-mock.js';

test.beforeEach(({ page }) => page.emulateMedia({ reducedMotion: 'reduce' }));

const FEED = '/rest/v1/rpc/admin_audit_feed';
const ago = (min) => new Date(Date.now() - min * 6e4).toISOString();
const ANANYA = 'a9000000-0000-4000-8000-000000000021';
const ARJUN = 'a9000000-0000-4000-8000-000000000003';
const ROHAN = 'a9000000-0000-4000-8000-000000000031';
const TARA = 'a9000000-0000-4000-8000-000000000032';

const by = (id, name, code, role) => ({
  actor_id: id,
  actor_name: name,
  actor_code: code,
  actor_role: role,
});
const about = (id, name, code) => ({ subject_id: id, subject_name: name, subject_code: code });
const row = (r) => ({
  result: 'success',
  actor_id: null,
  actor_name: null,
  actor_code: null,
  actor_role: 'system',
  target_table: null,
  target_id: null,
  target_label: null,
  subject_id: null,
  subject_name: null,
  subject_code: null,
  request_id: null,
  xact_id: null,
  old_values: null,
  new_values: null,
  ...r,
});

const PAGE_ONE = [
  row({
    id: 120,
    created_at: ago(4),
    action: 'member.region_change',
    ...by(ANANYA, 'Ananya Iyer', '21f1000021', 'super_admin'),
    ...about(ROHAN, 'Rohan Das', '22f2000031'),
    target_table: 'members',
    target_id: ROHAN,
    xact_id: 9001,
    old_values: { region_id: 1 },
    new_values: { region_id: 5, reason: 'Moved to Kolkata for work' },
  }),
  // The table trigger's row from the same transaction folds under the business action.
  row({
    id: 119,
    created_at: ago(4),
    action: 'members.update',
    ...by(ANANYA, 'Ananya Iyer', '21f1000021', 'super_admin'),
    ...about(ROHAN, 'Rohan Das', '22f2000031'),
    target_table: 'members',
    target_id: ROHAN,
    xact_id: 9001,
    old_values: { region_id: 1 },
    new_values: { region_id: 5 },
  }),
  row({
    id: 118,
    created_at: ago(30),
    action: 'events.update',
    ...by(ARJUN, 'Arjun Rao', '99f9000003', 'rc'),
    target_table: 'events',
    target_id: 'e1000000-0000-4000-8000-000000000001',
    target_label: 'Kolkata Monsoon Meetup',
    old_values: { venue: 'Park Street Social' },
    new_values: { venue: 'Salt Lake Central Park' },
  }),
  row({
    id: 117,
    created_at: ago(55),
    action: 'request.approve',
    ...by(ANANYA, 'Ananya Iyer', '21f1000021', 'super_admin'),
    ...about(TARA, 'Tara Banerjee', '21f1000010'),
    target_table: 'approval_requests',
    target_id: 'r1000000-0000-4000-8000-000000000001',
    request_id: 'r1000000-0000-4000-8000-000000000001',
    old_values: { status: 'pending' },
    new_values: { status: 'approved', type: 'member_deletion', review_note: 'Asked by email' },
  }),
  row({
    id: 116,
    created_at: ago(70),
    action: 'auth.ban',
    result: 'failure',
    ...about(TARA, 'Tara Banerjee', '21f1000010'),
    new_values: { account_status: 'deleted', error: 'User not found' },
  }),
  row({
    id: 115,
    created_at: ago(90),
    action: 'cohort.rollover',
    ...by(ANANYA, 'Ananya Iyer', '21f1000021', 'super_admin'),
    new_values: { from: '26F1', to: '26F2' },
  }),
];
const PAGE_TWO = [
  row({
    id: 80,
    created_at: ago(60 * 24 * 3),
    action: 'notice.publish',
    ...by(ANANYA, 'Ananya Iyer', '21f1000021', 'super_admin'),
    target_table: 'announcements',
    target_id: 'n1000000-0000-4000-8000-000000000001',
    target_label: 'Diwali meetups',
    old_values: { title: 'Diwali meetups', published_at: null },
    new_values: { title: 'Diwali meetups', published_at: ago(60 * 24 * 3) },
  }),
];

// Page one hands back a cursor; asking with it returns the older page and no further cursor.
const feed = (args) =>
  args.p_before_id
    ? { rows: PAGE_TWO, next: null }
    : { rows: PAGE_ONE, next: { at: PAGE_ONE.at(-1).created_at, id: 115 } };

const feedArgs = (calls) =>
  calls.filter((c) => c.path === FEED && c.method === 'POST').map((c) => JSON.parse(c.body));
const lastArgs = (calls) => feedArgs(calls).at(-1);

async function openAudit(page, query = '', data = { admin_audit_feed: feed }) {
  const calls = await mockSupabase(page, { as: 'sa', data });
  await page.goto(`/#/admin?tab=audit${query}`);
  await callTo(calls, FEED, 'POST');
  return calls;
}

test('rows read as sentences, linked rows fold together, and Older pages back', async ({
  page,
}) => {
  const calls = await openAudit(page);
  const entries = page.locator('.entry');
  await expect(entries).toHaveCount(5);

  const first = entries.first();
  await expect(first.locator('.say')).toContainText('Ananya Iyer moved Rohan Das to Kolkata');
  await expect(first.locator('.say')).toContainText('Patna → Kolkata · Moved to Kolkata for work');
  await expect(first.locator('.meta')).toContainText('People & roster');
  await expect(first.locator('.meta')).toContainText('Super Admin');
  await expect(first.locator('.meta')).toContainText('+1 linked');
  await expect(first.locator('time')).toHaveAttribute('title', /\d{4}/);

  // No sign-in, no catalogue entry: still a readable line.
  await expect(entries.nth(3)).toContainText('System blocked sign-in for Tara Banerjee');
  await expect(entries.nth(3).locator('.adm-badge.verm')).toHaveText('Failed');
  await expect(entries.nth(4)).toContainText('Ananya Iyer · cohort.rollover · from, to');
  await expect(entries.nth(4).locator('.meta')).toContainText('Other');

  expect(lastArgs(calls)).toMatchObject({
    p_actions: null,
    p_prefixes: null,
    p_member: null,
    p_before_at: null,
    p_before_id: null,
    p_limit: 50,
  });
  await page.getByRole('button', { name: 'Older' }).click();
  await expect(entries).toHaveCount(6);
  await expect(page.getByText('Ananya Iyer published the notice Diwali meetups')).toBeVisible();
  expect(lastArgs(calls)).toMatchObject({
    p_before_at: PAGE_ONE.at(-1).created_at,
    p_before_id: 115,
  });
  await expect(page.getByRole('button', { name: 'Older' })).toHaveCount(0);
});

test('filters become RPC arguments, live in the URL and survive a reload', async ({ page }) => {
  const calls = await openAudit(page);
  const filters = page.locator('#audit-filters');

  await filters.getByRole('button', { name: 'Roles', exact: true }).click();
  await expect.poll(() => lastArgs(calls).p_prefixes).toEqual(['position', 'admin_assignments']);
  expect(lastArgs(calls).p_actions).toBeNull();
  await expect(page).toHaveURL(/cat=roles/);

  await filters.getByText('All actions').click();
  await filters.getByLabel(/Assigned position/).check();
  await expect.poll(() => lastArgs(calls).p_actions).toEqual(['position.assign']);
  // The picker floats over the rows below; a click elsewhere closes it.
  await page.locator('.timeline, .day').first().click();
  await expect(filters.locator('.pop')).toBeHidden();
  expect(lastArgs(calls).p_prefixes).toBeNull();
  await expect(filters.getByText('Actions (1)')).toBeVisible();

  await filters.getByRole('button', { name: 'RC', exact: true }).click();
  await expect.poll(() => lastArgs(calls).p_role).toBe('rc');

  await filters.getByRole('button', { name: '7 days' }).click();
  await expect.poll(() => lastArgs(calls).p_from).not.toBeNull();
  const from = new Date(lastArgs(calls).p_from).getTime();
  expect(Math.abs(Date.now() - 7 * 24 * 36e5 - from)).toBeLessThan(5 * 6e4);

  await filters.getByRole('button', { name: 'Custom' }).click();
  await filters.getByLabel('From').fill('2026-10-01');
  await filters.getByLabel('To').fill('2026-10-07');
  // The "to" day counts in full: the RPC reads p_to as exclusive, so it is the next midnight.
  await expect.poll(() => lastArgs(calls).p_to).toBe(new Date(2026, 9, 8).toISOString());
  expect(lastArgs(calls).p_from).toBe(new Date(2026, 9, 1).toISOString());

  // Typing settles before it searches: one request for the whole word.
  const before = feedArgs(calls).length;
  await page.getByRole('searchbox', { name: 'Search activity' }).pressSequentially('Rohan', {
    delay: 40,
  });
  await expect.poll(() => lastArgs(calls).p_q).toBe('Rohan');
  expect(
    feedArgs(calls)
      .slice(before)
      .filter((a) => a.p_q)
  ).toHaveLength(1);
  await expect(page).toHaveURL(/q=Rohan/);

  const count = feedArgs(calls).length;
  await page.reload();
  await expect.poll(() => feedArgs(calls).length).toBeGreaterThan(count);
  expect(feedArgs(calls)[count]).toMatchObject({
    p_actions: ['position.assign'],
    p_role: 'rc',
    p_q: 'Rohan',
    p_from: new Date(2026, 9, 1).toISOString(),
    p_to: new Date(2026, 9, 8).toISOString(),
  });
  await expect(filters.getByRole('button', { name: 'Roles', exact: true })).toHaveAttribute(
    'aria-pressed',
    'true'
  );
  await expect(page.getByRole('searchbox', { name: 'Search activity' })).toHaveValue('Rohan');

  await filters.getByRole('button', { name: /^Clear \(\d\)$/ }).click();
  await expect.poll(() => lastArgs(calls).p_q).toBeNull();
  expect(lastArgs(calls)).toMatchObject({
    p_actions: null,
    p_prefixes: null,
    p_role: null,
    p_from: null,
    p_to: null,
  });
  await expect(page).toHaveURL(/tab=audit$/);
});

test('a name opens that member’s timeline, and the timeline deep-links', async ({ page }) => {
  const calls = await openAudit(page);
  await page.locator('.entry').first().getByRole('button', { name: 'Rohan Das' }).click();
  await expect.poll(() => lastArgs(calls).p_member).toBe(ROHAN);
  await expect(page.locator('.timeline')).toContainText('Everything involving Rohan Das');
  await expect(page).toHaveURL(new RegExp(`member=${ROHAN}`));

  await page.getByRole('button', { name: 'Show everyone' }).click();
  await expect.poll(() => lastArgs(calls).p_member).toBeNull();
  await expect(page.locator('.timeline')).toHaveCount(0);

  await page.goto(`/#/admin?tab=audit&member=${TARA}`);
  await expect.poll(() => lastArgs(calls).p_member).toBe(TARA);
  // The name comes from the loaded rows.
  await expect(page.locator('.timeline')).toContainText('Everything involving Tara Banerjee');
});

test('a row opens to its before and after values, and its record links into Admin', async ({
  page,
}) => {
  await openAudit(page);
  const first = page.locator('.entry').first();
  const chevron = first.getByRole('button', { name: 'Details of Changed region' });
  await expect(chevron).toHaveAttribute('aria-expanded', 'false');
  await chevron.click();
  await expect(chevron).toHaveAttribute('aria-expanded', 'true');

  const region = first.locator('.diff tr', { has: page.locator('th', { hasText: /^region_id$/ }) });
  await expect(region.first()).toHaveClass(/changed/);
  await expect(region.first().locator('td').nth(0)).toHaveText('Patna (1)');
  await expect(region.first().locator('td').nth(1)).toHaveText('Kolkata (5)');
  const reason = first.locator('.diff tr', { has: page.locator('th', { hasText: /^reason$/ }) });
  await expect(reason).not.toHaveClass(/changed/);
  await expect(reason.locator('td').nth(1)).toHaveText('Moved to Kolkata for work');
  await expect(first.getByText('Recorded in the same change')).toBeVisible();
  await expect(first.locator('.facts').first()).toContainText('22f2000031');
  await first.getByText('Raw JSON').click();
  await expect(first.locator('.raw pre')).toContainText('"xact_id": 9001');

  await page
    .locator('.entry')
    .nth(1)
    .getByRole('button', { name: 'Kolkata Monsoon Meetup' })
    .click();
  await expect(page).toHaveURL(/tab=events/);
});

test('a request link opens Requests', async ({ page }) => {
  await openAudit(page);
  await page.locator('.entry').nth(2).getByRole('button', { name: 'Request', exact: true }).click();
  await expect(page).toHaveURL(/tab=requests/);
});

test('empty feeds say why, and a failed load can be retried', async ({ page }) => {
  let fail = true;
  const calls = await mockSupabase(page, {
    as: 'sa',
    data: { admin_audit_feed: { rows: [], next: null } },
  });
  // Registered after the mock, so it answers first while `fail` is set.
  await page.route(`**${FEED}`, (route) =>
    fail && route.request().method() === 'POST'
      ? route.fulfill({
          status: 403,
          headers: { 'access-control-allow-origin': '*', 'content-type': 'application/json' },
          body: JSON.stringify({
            code: '42501',
            details: null,
            hint: null,
            message: 'Only a Super Admin can read the audit log',
          }),
        })
      : route.fallback()
  );

  await page.goto('/#/admin?tab=audit');
  const alert = page.getByRole('alert').filter({ hasText: 'Only a Super Admin' });
  await expect(alert).toBeVisible();
  await expect(page.getByText('No activity yet.')).toHaveCount(0);

  fail = false;
  await alert.getByRole('button', { name: 'Try again' }).click();
  await expect(page.getByText('No activity yet.')).toBeVisible();
  await expect(alert).toHaveCount(0);

  await page.locator('#audit-filters').getByRole('button', { name: 'Forms', exact: true }).click();
  await expect.poll(() => lastArgs(calls).p_prefixes).toEqual(['form']);
  await expect(page.getByText('No activity matches these filters.')).toBeVisible();
  await page.getByRole('button', { name: 'Clear filters' }).click();
  await expect(page).toHaveURL(/tab=audit$/);
  await expect(page.getByText('No activity yet.')).toBeVisible();
});

test('meetups by region now sits on the Super Admin overview', async ({ page }) => {
  await mockSupabase(page, { as: 'sa', data: { admin_audit_feed: feed } });
  await page.goto('/#/admin');
  await expect(page.getByRole('heading', { name: 'Meetups by region' })).toBeVisible();
  await page.goto('/#/admin?tab=audit');
  await expect(page.locator('.entry').first()).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Meetups by region' })).toHaveCount(0);
});
