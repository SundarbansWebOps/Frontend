import { Buffer } from 'node:buffer';
import { test, expect } from '@playwright/test';
import { adminSections, callTo, mockSupabase, PEOPLE, pick } from './supabase-mock.js';

test.beforeEach(({ page }) => page.emulateMedia({ reducedMotion: 'reduce' }));

// Girls is the members-only community: only a Super Admin and its own Head see its tags.
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

const KAVYA = {
  kind: 'member',
  id: 'a9000000-0000-4000-8000-000000000020',
  email: '21f1000020@ds.study.iitm.ac.in',
  member_code: '21f1000020',
  full_name: 'Kavya Menon',
  preferred_name: 'Kavya',
  phone: '+919800000020',
  gender: 'Female',
  region_id: 1,
  account_status: 'active',
  joined_at: '2026-10-20T00:00:00Z',
  communities: [2, 4],
};
const WAITING = {
  kind: 'roster',
  id: null,
  email: '21f1000021@ds.study.iitm.ac.in',
  member_code: null,
  full_name: 'Isha Rao',
  preferred_name: null,
  phone: null,
  gender: null,
  region_id: 1,
  account_status: 'not_signed_in',
  joined_at: '2026-10-21T00:00:00Z',
  communities: [],
};

// A small stand-in for the tag RPCs: the tags are server state the add and remove calls change.
function studentsServer() {
  const rows = [structuredClone(KAVYA), structuredClone(WAITING)];
  return {
    list_students: ({ p_community }) => {
      const found = rows.filter((r) => !p_community || r.communities.includes(p_community));
      return { total: found.length, rows: found };
    },
    add_community_members: ({ p_community_id, p_emails }) => {
      const out = { added: 0, already: 0, invalid: [], not_in_house: [] };
      for (const email of p_emails) {
        const row = rows.find((r) => r.email === email);
        if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) out.invalid.push(email);
        else if (!row) out.not_in_house.push(email);
        else if (row.communities.includes(p_community_id)) out.already += 1;
        else {
          row.communities.push(p_community_id);
          out.added += 1;
        }
      }
      return out;
    },
    remove_community_member: ({ p_community_id, p_email }) => {
      const row = rows.find((r) => r.email === p_email);
      row.communities = row.communities.filter((c) => c !== p_community_id);
      return null;
    },
    request_community_tag_removal: () => 'b0000000-0000-4000-8000-000000000009',
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

// The community filter's options, once the panel has rendered.
async function communityOptions(page) {
  const select = page.getByRole('combobox', { name: 'Community', exact: true });
  await select.click();
  const names = await page.getByRole('option').allTextContents();
  await select.press('Escape');
  return names.map((n) => n.trim());
}

test('a Super Admin tags many students at once from a paste and a CSV', async ({ page }) => {
  const calls = await mockSupabase(page, { as: 'sa', data: studentsServer() });
  await withCommunities(page);
  await page.goto('/#/admin?tab=students');
  await expect(page.getByRole('heading', { name: 'Students', level: 1 })).toBeVisible();
  await expect(page.getByRole('table').getByRole('row')).toHaveCount(3);

  await page.getByRole('button', { name: 'Add to a community' }).click();
  const dialog = page.getByRole('dialog', { name: 'Add to a community' });
  await pick(dialog, 'Community', 'Girls');
  // Duplicates and header words drop out client-side; the server reports the rest.
  await dialog
    .getByLabel('Emails')
    .fill(
      'Email Address\n21F1000021@ds.study.iitm.ac.in, 21f1000021@ds.study.iitm.ac.in\n' +
        '21f1000020@ds.study.iitm.ac.in\tKavya\nfriend@gmail.com\nbad@nodot'
    );
  await expect(dialog.getByText('4 emails found.')).toBeVisible();
  await dialog.getByRole('button', { name: 'Add 4' }).click();
  const add = await callTo(calls, '/rest/v1/rpc/add_community_members');
  expect(JSON.parse(add.body)).toEqual({
    p_community_id: 4,
    p_emails: [
      '21f1000021@ds.study.iitm.ac.in',
      '21f1000020@ds.study.iitm.ac.in',
      'friend@gmail.com',
      'bad@nodot',
    ],
  });
  await expect(dialog.getByText('1 tagged, 1 already in this community.')).toBeVisible();
  await expect(dialog.getByText('1 skipped: not in the house')).toBeVisible();
  await expect(dialog.getByText('friend@gmail.com')).toBeVisible();
  await expect(dialog.getByText('1 not valid')).toBeVisible();

  // CSV: the Email Address column is read; other columns are ignored.
  await pick(dialog, 'Community', 'Cultural');
  await dialog.getByRole('button', { name: 'Upload CSV' }).click();
  await dialog.getByLabel('Upload members CSV').setInputFiles({
    name: 'responses.csv',
    mimeType: 'text/csv',
    buffer: Buffer.from(
      'Timestamp,Email Address,Name\n' +
        '2026/10/22,21f1000020@ds.study.iitm.ac.in,Kavya\n' +
        '2026/10/22,21f1000021@ds.study.iitm.ac.in,"Rao, Isha"\n'
    ),
  });
  await expect(dialog.getByText('2 emails found.')).toBeVisible();
  await dialog.getByRole('button', { name: 'Add 2' }).click();
  await expect(dialog.getByText('2 tagged, 0 already in this community.')).toBeVisible();
  await dialog.getByRole('button', { name: 'Close' }).click();

  // The list reloads with the new tags.
  const waiting = page.getByRole('row', { name: /Isha Rao/ });
  await expect(waiting.getByText('Girls', { exact: true })).toBeVisible();
  await expect(waiting.getByText('Cultural', { exact: true })).toBeVisible();
});

test('a CSV without an Email Address column is refused before any request', async ({ page }) => {
  const calls = await mockSupabase(page, { as: 'sa', data: studentsServer() });
  await withCommunities(page);
  await page.goto('/#/admin?tab=students');
  await page.getByRole('button', { name: 'Add to a community' }).click();
  const dialog = page.getByRole('dialog', { name: 'Add to a community' });
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

test('a Super Admin tags and untags one roster student from the drawer', async ({ page }) => {
  const calls = await mockSupabase(page, { as: 'sa', data: studentsServer() });
  await withCommunities(page);
  await page.goto('/#/admin?tab=students');
  await page.getByRole('button', { name: 'Open Isha Rao' }).click();
  const drawer = page.getByRole('dialog', { name: 'Isha Rao' });
  await expect(drawer.getByText('Not in any community.')).toBeVisible();
  await expect(drawer.getByText('This student has not signed in yet.')).toBeVisible();

  await pick(drawer, 'Add to', 'Technical');
  await drawer.getByRole('button', { name: 'Add', exact: true }).click();
  const add = await callTo(calls, '/rest/v1/rpc/add_community_members');
  expect(JSON.parse(add.body)).toEqual({
    p_community_id: 2,
    p_emails: ['21f1000021@ds.study.iitm.ac.in'],
  });
  await expect(drawer.getByText('Added to Technical.')).toBeVisible();

  await drawer.getByRole('button', { name: 'Remove', exact: true }).click();
  const confirm = page.getByRole('dialog', { name: 'Remove from Technical?' });
  await confirm.getByRole('button', { name: 'Remove' }).click();
  const removed = await callTo(calls, '/rest/v1/rpc/remove_community_member');
  expect(JSON.parse(removed.body)).toEqual({
    p_community_id: 2,
    p_email: '21f1000021@ds.study.iitm.ac.in',
  });
  await expect(drawer.getByText('Removed from Technical.')).toBeVisible();
  await expect(drawer.getByText('Not in any community.')).toBeVisible();
});

test('a Technical Head sees phone numbers and asks a Super Admin to remove a tag', async ({
  page,
}) => {
  const calls = await mockSupabase(page, { as: 'head', data: studentsServer() });
  await withCommunities(page);
  await page.goto('/#/admin');
  await adminSections(page).getByRole('button', { name: 'Students' }).click();
  await expect(page.getByText('Students in Technical Community.')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Add students' })).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'Add to a community' })).toHaveCount(0);
  // A Head sees only their own community's students: no community filter.
  await expect(page.getByRole('button', { name: 'Open Kavya' })).toBeVisible();
  await expect(page.getByRole('combobox', { name: 'Community', exact: true })).toHaveCount(0);
  expect(
    JSON.parse((await callTo(calls, '/rest/v1/rpc/list_students')).body).p_community
  ).toBeNull();

  await page.getByRole('button', { name: 'Open Kavya' }).click();
  const drawer = page.getByRole('dialog', { name: 'Kavya' });
  await expect(drawer.getByText('+919800000020')).toBeVisible();
  await expect(drawer.getByRole('button', { name: 'Remove', exact: true })).toHaveCount(0);
  await expect(drawer.getByRole('combobox', { name: 'Add to' })).toHaveCount(0);
  await drawer.getByRole('button', { name: 'Ask to remove' }).click();
  await drawer.getByLabel('Why').fill('Left the community');
  await drawer.getByRole('button', { name: 'Ask to remove' }).click();
  const asked = await callTo(calls, '/rest/v1/rpc/request_community_tag_removal');
  expect(JSON.parse(asked.body)).toEqual({
    p_community_id: 2,
    p_email: '21f1000020@ds.study.iitm.ac.in',
    p_reason: 'Left the community',
  });
  await expect(drawer.getByText('Request sent. A Super Admin will review it.')).toBeVisible();
});

test('the Girls Head sees Girls tags, publishes notices and Girls-only events', async ({
  page,
}) => {
  await mockSupabase(page, { as: 'girlsHead', data: studentsServer() });
  await withCommunities(page);
  await page.goto('/#/admin?tab=students');
  await expect(page.getByText('Students in Girls Community.')).toBeVisible();
  await expect(page.getByRole('combobox', { name: 'Community', exact: true })).toHaveCount(0);
  await expect(
    page.getByRole('row').filter({ hasText: 'Kavya' }).getByText('Girls', { exact: true })
  ).toBeVisible();

  // The head's own event editor says who sees a Girls event.
  const nav = adminSections(page);
  await nav.getByRole('button', { name: 'Events' }).click();
  await page.getByRole('button', { name: 'New event' }).click();
  await expect(
    page.getByText(
      'This event belongs to the Girls community. Only Girls Community members see it.'
    )
  ).toBeVisible();
  await expect(page.getByText('Public: also list it on the public Events page')).toHaveCount(0);

  // Girls notices reach only the tagged students, so its Head publishes them too.
  await page.getByRole('dialog').getByRole('button', { name: 'Close' }).click();
  await nav.getByRole('button', { name: 'Notices' }).click();
  await expect(page.getByRole('heading', { name: 'Notices', level: 1 })).toBeVisible();
});

test('a Regional Coordinator adds students but tags no one and sees no Girls tags', async ({
  page,
}) => {
  await mockSupabase(page, { as: 'rc', data: studentsServer() });
  await withCommunities(page);
  await page.goto('/#/admin?tab=students');
  await expect(page.getByLabel('Add students')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Add to a community' })).toHaveCount(0);
  expect(await communityOptions(page)).not.toContain('Girls');
  await expect(adminSections(page).getByRole('button', { name: /Community/ })).toHaveCount(0);
});
