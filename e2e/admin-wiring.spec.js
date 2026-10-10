import { Buffer } from 'node:buffer';
import { test, expect } from '@playwright/test';
import { mockSupabase, PEOPLE, callTo } from './supabase-mock.js';

test.beforeEach(({ page }) => page.emulateMedia({ reducedMotion: 'reduce' }));

test('roster searches beyond the first thousand rows and paginates matches', async ({ page }) => {
  await mockSupabase(page, { as: 'sa' });
  const rows = Array.from({ length: 1101 }, (_, i) => ({
    email: `99f90${String(i).padStart(5, '0')}@ds.study.iitm.ac.in`,
    full_name: i === 1100 ? 'Search Target' : null,
    region_id: 1,
    added_at: '2026-10-09T00:00:00Z',
  }));
  const requests = [];
  await page.route('**/rest/v1/member_roster?*', async (route) => {
    const request = route.request();
    const url = new URL(request.url());
    const headers = {
      'access-control-allow-origin': '*',
      'access-control-allow-headers': '*',
      'access-control-allow-methods': 'GET,HEAD,OPTIONS',
      'access-control-expose-headers': 'content-range',
    };
    if (request.method() === 'OPTIONS') return route.fulfill({ status: 204, headers });
    if (request.method() === 'HEAD')
      return route.fulfill({ status: 200, headers: { ...headers, 'content-range': '*/1101' } });
    requests.push(url.searchParams);
    const filter = url.searchParams.get('or');
    const matched = filter
      ? filter.includes('99f9001100') || filter.includes('Search Target')
        ? [rows[1100]]
        : []
      : rows;
    const offset = Number(url.searchParams.get('offset'));
    const limit = Number(url.searchParams.get('limit'));
    const result = matched.slice(offset, offset + limit);
    return route.fulfill({
      status: 200,
      headers: {
        ...headers,
        'content-type': 'application/json',
        'content-range': `${offset}-${offset + result.length - 1}/${matched.length}`,
      },
      body: JSON.stringify(result),
    });
  });
  await page.goto('/#/admin?tab=roster');
  await expect(page.getByText('Showing 50 of 1101 students.', { exact: false })).toBeVisible();
  await page.getByRole('button', { name: 'Show more (1051 left)' }).click();
  await expect(page.getByText('Showing 100 of 1101 students.', { exact: false })).toBeVisible();
  expect(requests.at(-1).get('offset')).toBe('50');
  expect(requests.at(-1).get('order')).toBe('added_at.desc,email.asc');

  await page.getByLabel('Search roster').fill('99f9001100');
  await page.getByRole('button', { name: 'Search', exact: true }).click();
  await expect(page.getByText('Showing 1 of 1 matching students.', { exact: false })).toBeVisible();
  await expect(page.getByText(rows[1100].email, { exact: true })).toBeVisible();
  expect(requests.at(-1).get('or')).toBe(
    '(email.ilike."%99f9001100%",full_name.ilike."%99f9001100%")'
  );
  expect(requests.at(-1).get('offset')).toBe('0');

  await page.getByLabel('Search roster').fill('Search Target');
  await page.getByLabel('Search roster').press('Enter');
  await expect
    .poll(() => requests.at(-1).get('or'))
    .toBe('(email.ilike."%Search Target%",full_name.ilike."%Search Target%")');
  await expect(page.getByText('Showing 1 of 1 matching students.', { exact: false })).toBeVisible();
  await page.getByLabel('Search roster').fill('missing');
  await page.getByLabel('Search roster').press('Enter');
  await expect(page.getByText(/No student matches that search/)).toBeVisible();
  await page.getByLabel('Search roster').fill('');
  await page.getByLabel('Search roster').press('Enter');
  await expect(page.getByText('Showing 50 of 1101 students.', { exact: false })).toBeVisible();
});

test('roster accepts an email without a name and maps a CSV', async ({ page }) => {
  const calls = await mockSupabase(page, {
    as: 'rc',
    data: {
      roster_add: 'ok',
      roster_add_many: [
        { email: '21f1000100@ds.study.iitm.ac.in', ok: true, category: 'processed' },
      ],
    },
  });
  await page.goto('/#/admin?tab=roster');
  await expect(page.getByText('Added to Patna.')).toBeVisible();
  await page.getByLabel('IITM email').fill('21f1000099@ds.study.iitm.ac.in');
  await page.getByRole('button', { name: 'Add to roster' }).first().click();
  await expect(
    page.getByText('21f1000099@ds.study.iitm.ac.in can now sign in with Google.')
  ).toBeVisible();
  const added = await callTo(calls, '/rest/v1/rpc/roster_add');
  expect(JSON.parse(added.body)).toMatchObject({
    p_email: '21f1000099@ds.study.iitm.ac.in',
    p_full_name: null,
    p_phone: null,
    p_region_id: null,
  });

  await page.setInputFiles('input[type="file"]', {
    name: 'members.csv',
    mimeType: 'text/csv',
    buffer: Buffer.from('Student_Email,Allocated_Region\n21f1000100@ds.study.iitm.ac.in,Patna\n'),
  });
  await expect(page.getByText('1 row after de-duplicating this file.')).toBeVisible();
  await expect(page.getByRole('combobox', { name: 'Email' })).toHaveValue(/0/);
  await page.getByRole('button', { name: /Import/ }).click();
  await expect(
    page.getByText('1 processed, 0 invalid. Existing identities are preserved.')
  ).toBeVisible();
  expect(calls.some((c) => c.path === '/rest/v1/rpc/roster_add_many')).toBe(true);
});

test('event editor saves a draft, publishes, and shows the Future badge on the next cohort', async ({
  page,
}) => {
  const eventId = 'e0000000-0000-4000-8000-000000000001';
  const calls = await mockSupabase(page, {
    as: 'sa',
    data: {
      events: [{ id: eventId }],
      get_available_cohorts: {
        current: '26F3',
        next: '27F1',
        options: ['25F1', '25F2', '25F3', '26F1', '26F2', '26F3', '27F1'],
      },
    },
  });
  await page.goto('/#/admin?tab=events');
  await page.getByRole('button', { name: 'New event' }).click();
  const dialog = page.getByRole('dialog');
  await expect(dialog.getByRole('heading', { name: 'New event' })).toBeVisible();
  await dialog.getByLabel('Name').fill('House meetup');
  await dialog.getByLabel('Year').selectOption('2027');
  await expect(dialog.getByText('Future', { exact: true })).toBeVisible();
  await dialog.getByRole('button', { name: /F1/ }).click();
  await dialog.getByRole('button', { name: 'Save draft' }).click();
  const saved = await callTo(calls, '/rest/v1/events', 'POST');
  expect(saved).toBeTruthy();
  const body = JSON.parse(saved.body);
  expect(body.published_at).toBeUndefined();
  expect(body.audience_cohorts).toEqual(['27F1']);
  expect(body.attendance_mode).toBe('meet');
});

test('form builder keeps field order, types, options and a post-submit invite', async ({
  page,
}) => {
  const calls = await mockSupabase(page, {
    as: 'sa',
    data: {
      list_lounge_forms: [],
      save_lounge_form: 'f0000000-0000-4000-8000-000000000001',
      get_available_cohorts: { current: '26F3', next: '27F1', options: ['26F3', '27F1'] },
    },
  });
  await page.goto('/#/admin?tab=forms');
  await page.getByRole('button', { name: 'New form' }).click();
  const dialog = page.getByRole('dialog');
  await dialog.getByLabel('Title').fill('Community join');
  await dialog.getByLabel('WhatsApp invite (optional)').fill('https://chat.whatsapp.com/AbC123xyz');
  await dialog.getByRole('button', { name: 'Add field' }).click();
  await dialog.getByLabel('Label').fill('Which games');
  await dialog.getByLabel('Type').selectOption('multiselect');
  await dialog.getByLabel('Options (one per line)').fill('Valorant\nBGMI');
  await dialog.getByText('Allow “Other”').click();
  await dialog.getByRole('button', { name: 'Publish' }).click();
  const saved = await callTo(calls, '/rest/v1/rpc/save_lounge_form');
  expect(saved).toBeTruthy();
  const payload = JSON.parse(saved.body).p_form;
  expect(payload.title).toBe('Community join');
  expect(payload.invite_url).toBe('https://chat.whatsapp.com/AbC123xyz');
  expect(payload.published_at).toBeTruthy();
  expect(payload.fields[0]).toMatchObject({
    label: 'Which games',
    type: 'multiselect',
    allow_other: true,
    options: ['Valorant', 'BGMI'],
  });
});

test('attendance preview classifies Meet rows before save', async ({ page }) => {
  const eventId = 'e0000000-0000-4000-8000-000000000002';
  const event = {
    id: eventId,
    name: 'Town hall',
    starts_at: '2026-12-01T10:00:00Z',
    ends_at: '2026-12-01T12:00:00Z',
    published_at: '2026-10-01T00:00:00Z',
    attendance_mode: 'meet',
    archive: false,
    cancelled_at: null,
    community_id: null,
    region_id: null,
  };
  const calls = await mockSupabase(page, {
    as: 'sa',
    data: {
      events: [event],
      event_registrations: [
        { event_id: eventId, registered_email: '21f1000001@ds.study.iitm.ac.in' },
      ],
      import_event_attendance: { matched: 1, unregistered: 1, unresolved: 1 },
    },
  });
  await page.goto('/#/admin?tab=events');
  await page.getByRole('button', { name: 'Attendance' }).click();
  const dialog = page.getByRole('dialog');
  await dialog.locator('input[type="file"]').setInputFiles({
    name: 'meet.csv',
    mimeType: 'text/csv',
    buffer: Buffer.from(
      [
        'First name,Last name,Email,Duration',
        'A,One,21f1000001@ds.study.iitm.ac.in,25 min',
        'B,Two,21f1000002@ds.study.iitm.ac.in,5 min',
        'C,Three,r****@ds.study.iitm.ac.in,40 min',
      ].join('\n')
    ),
  });
  await expect(dialog.getByText(/registered and attended/)).toBeVisible();
  await expect(dialog.getByRole('cell', { name: 'unresolved', exact: true })).toBeVisible();
  await dialog.getByRole('button', { name: 'Save attendance' }).click();
  const imported = await callTo(calls, '/rest/v1/rpc/import_event_attendance');
  expect(imported).toBeTruthy();
  const rows = JSON.parse(imported.body).p_rows;
  expect(
    rows.some((r) => r.email === '21f1000001@ds.study.iitm.ac.in' && r.duration_seconds === 1500)
  ).toBe(true);
  expect(rows.filter((r) => r.email.includes('*'))).toEqual([
    expect.objectContaining({
      email: 'r****@ds.study.iitm.ac.in',
      source_row_id: '3',
      duration_seconds: 2400,
    }),
  ]);
});

test('notices publish in scope and positions keep the two-RC cap with no Super Admin add', async ({
  page,
}) => {
  const calls = await mockSupabase(page, {
    as: 'sa',
    data: {
      save_announcement: 'n0000000-0000-4000-8000-000000000001',
      admin_assignments: [
        {
          id: 'p1',
          position: 'rc',
          region_id: 1,
          community_id: null,
          started_at: '2026-01-01T00:00:00Z',
          member: { id: PEOPLE.rc.id, full_name: 'Arjun Rao', member_code: '99f9000003' },
        },
      ],
    },
  });
  await page.goto('/#/admin?tab=notices');
  await page.getByRole('button', { name: 'New notice' }).click();
  const dialog = page.getByRole('dialog');
  await dialog.getByLabel('Title').fill('Meet this week');
  await dialog.getByLabel('Body').fill('Patna ghat, Saturday.');
  await dialog.getByRole('button', { name: 'Publish now' }).click();
  const saved = await callTo(calls, '/rest/v1/rpc/save_announcement');
  expect(JSON.parse(saved.body).p_announcement).toMatchObject({
    title: 'Meet this week',
    region_id: null,
    community_id: null,
    audience_cohorts: [],
  });

  await page.getByRole('tab', { name: 'Positions' }).click();
  await expect(page.getByText('A region may have none, one or two coordinators.')).toBeVisible();
  await expect(
    page.getByText('Super Admin login emails stay the three fixed accounts.')
  ).toBeVisible();
  await expect(page.getByRole('button', { name: /Add Super Admin/i })).toHaveCount(0);
});

test('a current-region RC reviews a student region request without the two-person queue', async ({
  page,
}) => {
  const request = {
    id: 'd0000000-0000-4000-8000-000000000001',
    member_id: PEOPLE.member.id,
    from_region_id: 1,
    to_region_id: 2,
    reason: 'Moved for work',
    status: 'pending',
    requested_at: '2026-10-08T10:00:00Z',
    reviewed_at: null,
    review_note: null,
    member: {
      full_name: 'Riya Venkataraman',
      member_code: '99f9000004',
      email: PEOPLE.member.email,
    },
  };
  const calls = await mockSupabase(page, {
    as: 'rc',
    data: { member_region_requests: [request], review_region_change: request.id },
  });
  await page.goto('/#/admin?tab=requests');
  await expect(page.getByRole('heading', { name: 'Student region corrections' })).toBeVisible();
  await expect(page.getByText('Patna → Delhi NCR')).toBeVisible();
  await page.getByRole('button', { name: 'Approve', exact: true }).click();
  await expect(page.getByRole('status')).toContainText('Region change applied.');
  const reviewed = await callTo(calls, '/rest/v1/rpc/review_region_change');
  expect(JSON.parse(reviewed.body)).toMatchObject({ p_request_id: request.id, p_approve: true });
  expect(calls.some((c) => c.path === '/rest/v1/rpc/approve_request')).toBe(false);
});
