import { Buffer } from 'node:buffer';
import { test, expect } from '@playwright/test';
import { adminSections, callTo, mockSupabase, PEOPLE } from './supabase-mock.js';

test.beforeEach(({ page }) => page.emulateMedia({ reducedMotion: 'reduce' }));

// Girls is the members-only community; its Head reads the list but cannot change it.
PEOPLE.girlsHead = {
  id: 'a9000000-0000-4000-8000-000000000006',
  email: '99f9000006@ds.study.iitm.ac.in',
  full_name: 'Ananya Iyer',
  dashboard: { role: 'admin', position: 'head', region_id: null, community_id: 4 },
};

const COMMUNITIES = [
  { id: 1, code: 'esports', name: 'E-Sports', members_only: false },
  { id: 2, code: 'technical', name: 'Technical', members_only: false },
  { id: 3, code: 'cultural', name: 'Cultural', members_only: false },
  { id: 4, code: 'girls', name: 'Girls', members_only: true },
];

const SIGNED_IN = {
  email: '21f1000020@ds.study.iitm.ac.in',
  added_at: '2026-10-20T00:00:00Z',
  member: {
    id: 'a9000000-0000-4000-8000-000000000020',
    full_name: 'Kavya Menon',
    preferred_name: 'Kavya',
    member_code: '21f1000020',
    cohort: '21F1',
    region_id: 9,
    account_status: 'active',
  },
  on_roster: true,
};
const WAITING = {
  email: '21f1000021@ds.study.iitm.ac.in',
  added_at: '2026-10-21T00:00:00Z',
  member: null,
  on_roster: true,
};
const OUTSIDE = {
  email: '21f1000022@ds.study.iitm.ac.in',
  added_at: '2026-10-22T00:00:00Z',
  member: null,
  on_roster: false,
};

// A small stand-in for the three RPCs: the list is server state the add and remove calls change.
function membersServer() {
  let rows = [SIGNED_IN, WAITING, OUTSIDE];
  return {
    list_community_members: () => [...rows].sort((a, b) => a.email.localeCompare(b.email)),
    add_community_members: ({ p_emails }) => {
      const out = { added: 0, already: 0, invalid: [], not_in_house: [] };
      for (const email of p_emails) {
        if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) out.invalid.push(email);
        else if (rows.some((r) => r.email === email)) out.already += 1;
        else {
          const onRoster = email.endsWith('@ds.study.iitm.ac.in');
          if (!onRoster) out.not_in_house.push(email);
          rows.push({ email, added_at: '2026-10-23T00:00:00Z', member: null, on_roster: onRoster });
          out.added += 1;
        }
      }
      return out;
    },
    remove_community_member: ({ p_email }) => {
      rows = rows.filter((r) => r.email !== p_email);
      return null;
    },
  };
}

// Girls in the communities table, and no trip to Cloudinary for the overview art (tests stay
// offline; a stalled image would hold the page's load event).
async function withCommunities(page) {
  await page.route('https://res.cloudinary.com/**', (route) => route.fulfill({ status: 204 }));
  await page.route(
    (url) => url.pathname === '/rest/v1/communities',
    (route) =>
      route.fulfill({
        status: 200,
        headers: { 'access-control-allow-origin': '*', 'content-type': 'application/json' },
        body: JSON.stringify(COMMUNITIES),
      })
  );
}

test('a Super Admin adds pasted and CSV emails, sees the summary and removes one', async ({
  page,
}) => {
  const calls = await mockSupabase(page, { as: 'sa', data: membersServer() });
  await withCommunities(page);
  await page.goto('/#/admin');
  await adminSections(page).getByRole('button', { name: 'Community' }).click();
  await expect(page.getByRole('heading', { name: 'Community', level: 1 })).toBeVisible();

  // One community today, so no picker; the list loads for Girls (id 4).
  await expect(page.getByLabel('Community', { exact: true })).toHaveCount(0);
  const list = await callTo(calls, '/rest/v1/rpc/list_community_members');
  expect(JSON.parse(list.body)).toEqual({ p_community_id: 4 });

  const table = page.getByRole('table');
  await expect(table.getByRole('row')).toHaveCount(4);
  await expect(table.getByText('Kavya', { exact: true })).toBeVisible();
  await expect(table.getByText('Signed in', { exact: true })).toBeVisible();
  await expect(table.getByText('Not signed in yet', { exact: true })).toBeVisible();
  await expect(table.getByText('Not in house roster', { exact: true })).toBeVisible();

  // Status chips filter the list and carry counts.
  const filters = page.getByRole('group', { name: 'Filter by status' });
  await filters.getByRole('button', { name: /^Not in house roster/ }).click();
  await expect(table.getByRole('row')).toHaveCount(2);
  await filters.getByRole('button', { name: /^All/ }).click();
  await page.getByLabel('Search').fill('kavya');
  await expect(table.getByRole('row')).toHaveCount(2);
  await page.getByLabel('Search').fill('');

  // Paste: duplicates and header words drop out client-side; the server reports the rest.
  await page.getByRole('button', { name: 'Add members' }).click();
  const dialog = page.getByRole('dialog', { name: 'Add Girls members' });
  await dialog
    .getByLabel('Emails')
    .fill(
      'Email Address\n21F1000030@ds.study.iitm.ac.in, 21f1000030@ds.study.iitm.ac.in\n' +
        '21f1000020@ds.study.iitm.ac.in\tKavya\nfriend@gmail.com\nbad@nodot'
    );
  await expect(dialog.getByText('4 emails found.')).toBeVisible();
  await dialog.getByRole('button', { name: 'Add 4' }).click();
  const add = await callTo(calls, '/rest/v1/rpc/add_community_members');
  expect(JSON.parse(add.body)).toEqual({
    p_community_id: 4,
    p_emails: [
      '21f1000030@ds.study.iitm.ac.in',
      '21f1000020@ds.study.iitm.ac.in',
      'friend@gmail.com',
      'bad@nodot',
    ],
  });
  await expect(dialog.getByText('2 added, 1 already on the list.')).toBeVisible();
  await expect(dialog.getByText('1 not found in the house')).toBeVisible();
  await expect(dialog.getByText('friend@gmail.com')).toBeVisible();
  await expect(dialog.getByText('1 not valid')).toBeVisible();
  await expect(dialog.getByText('bad@nodot')).toBeVisible();

  // CSV: the Email Address column is read; other columns are ignored.
  await dialog.getByRole('button', { name: 'Upload CSV' }).click();
  await dialog.getByLabel('Upload members CSV').setInputFiles({
    name: 'responses.csv',
    mimeType: 'text/csv',
    buffer: Buffer.from(
      'Timestamp,Email Address,Name\n' +
        '2026/10/22,21f1000031@ds.study.iitm.ac.in,Isha\n' +
        '2026/10/22,21f1000032@ds.study.iitm.ac.in,"Roy, Tara"\n'
    ),
  });
  await expect(dialog.getByText('2 emails found.')).toBeVisible();
  await dialog.getByRole('button', { name: 'Add 2' }).click();
  await expect(dialog.getByText('2 added, 0 already on the list.')).toBeVisible();
  await dialog.getByRole('button', { name: 'Close' }).click();
  await expect(table.getByRole('row')).toHaveCount(8);

  // Remove asks first, then calls the RPC and reloads.
  await table.getByRole('button', { name: 'Remove 21f1000022@ds.study.iitm.ac.in' }).click();
  const confirm = page.getByRole('dialog', { name: 'Remove from Girls?' });
  await expect(confirm).toContainText('will no longer see Girls Community events');
  await confirm.getByRole('button', { name: 'Remove' }).click();
  const removed = await callTo(calls, '/rest/v1/rpc/remove_community_member');
  expect(JSON.parse(removed.body)).toEqual({
    p_community_id: 4,
    p_email: '21f1000022@ds.study.iitm.ac.in',
  });
  await expect(table.getByText('21f1000022@ds.study.iitm.ac.in')).toHaveCount(0);
  await expect(table.getByRole('row')).toHaveCount(7);
});

test('a CSV without an Email Address column is refused before any request', async ({ page }) => {
  const calls = await mockSupabase(page, { as: 'sa', data: membersServer() });
  await withCommunities(page);
  await page.goto('/#/admin?tab=community');
  await page.getByRole('button', { name: 'Add members' }).click();
  const dialog = page.getByRole('dialog', { name: 'Add Girls members' });
  await dialog.getByRole('button', { name: 'Upload CSV' }).click();
  await dialog.getByLabel('Upload members CSV').setInputFiles({
    name: 'names.csv',
    mimeType: 'text/csv',
    buffer: Buffer.from('Name,Phone\nIsha,+919800000000\n'),
  });
  await expect(dialog.getByRole('alert')).toContainText('needs an Email Address column');
  await expect(dialog.getByRole('button', { name: /^Add/ })).toBeDisabled();
  expect(calls.some((c) => c.path === '/rest/v1/rpc/add_community_members')).toBe(false);
});

test('the Girls Head reads the list without add or remove controls', async ({ page }) => {
  const calls = await mockSupabase(page, { as: 'girlsHead', data: membersServer() });
  await withCommunities(page);
  await page.goto('/#/admin');
  const nav = adminSections(page);
  await nav.getByRole('button', { name: 'Girls Community' }).click();
  await expect(page.getByRole('heading', { name: 'Girls Community', level: 1 })).toBeVisible();
  await expect(page.getByText('Only a Super Admin can add or remove Girls members.')).toBeVisible();
  const table = page.getByRole('table');
  await expect(table.getByRole('row')).toHaveCount(4);
  await expect(table.getByText('Kavya', { exact: true })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Add members' })).toHaveCount(0);
  await expect(page.getByRole('button', { name: /^Remove/ })).toHaveCount(0);
  const list = await callTo(calls, '/rest/v1/rpc/list_community_members');
  expect(JSON.parse(list.body)).toEqual({ p_community_id: 4 });

  // The head's own event editor says who sees a Girls event.
  await nav.getByRole('button', { name: 'Events' }).click();
  await page.getByRole('button', { name: 'New event' }).click();
  await expect(
    page.getByText(
      'This event belongs to the Girls community. Only Girls Community members see it.'
    )
  ).toBeVisible();
  await expect(page.getByText('Public: also list it on the public Events page')).toHaveCount(0);

  // Girls notices reach only the list, so its Head publishes them too.
  await page.getByRole('dialog').getByRole('button', { name: 'Close' }).click();
  await nav.getByRole('button', { name: 'Notices' }).click();
  await expect(page.getByRole('heading', { name: 'Notices', level: 1 })).toBeVisible();
});

for (const as of ['head', 'rc']) {
  test(`a ${as === 'head' ? 'Technical Head' : 'Regional Coordinator'} has no Community tab`, async ({
    page,
  }) => {
    const calls = await mockSupabase(page, { as, data: membersServer() });
    await withCommunities(page);
    await page.goto('/#/admin?tab=community');
    const nav = adminSections(page);
    // A direct link falls back to the overview and never asks for the list.
    await expect(page.getByRole('heading', { name: 'Community', level: 1 })).toHaveCount(0);
    // Panels render only once the communities lookup is in, so the tab list is final here.
    await nav.getByRole('button', { name: 'Events' }).click();
    await expect(page.getByRole('button', { name: 'New event' })).toBeVisible();
    await expect(nav.getByRole('button', { name: /Community/ })).toHaveCount(0);
    // Only a members-only community's Head gets Notices; an RC keeps its own.
    await expect(nav.getByRole('button', { name: 'Notices' })).toHaveCount(as === 'rc' ? 1 : 0);
    expect(calls.some((c) => c.path === '/rest/v1/rpc/list_community_members')).toBe(false);
  });
}
