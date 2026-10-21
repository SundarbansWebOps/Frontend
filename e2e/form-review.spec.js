import { readFile } from 'node:fs/promises';
import { test, expect } from '@playwright/test';
import { callTo, mockSupabase } from './supabase-mock.js';

test.beforeEach(({ page }) => page.emulateMedia({ reducedMotion: 'reduce' }));

const FORM_ID = 'f1000000-0000-4000-8000-0000000000aa';
const SCHEMA = [{ key: 'name', label: 'Name', type: 'text' }];
const ids = [1, 2, 3].map((n) => `a1000000-0000-4000-8000-00000000000${n}`);

// A stateful stand-in for export_form_responses / review_form_response.
function reviewDesk() {
  const rows = ['Asha', 'Bilal', 'Chitra'].map((name, i) => ({
    id: ids[i],
    serial: i + 1,
    email: `26f100000${i + 1}@ds.study.iitm.ac.in`,
    member_full_name: `${name} Full`,
    member_preferred_name: name,
    submitted_at: `2026-10-0${i + 1}T10:00:00Z`,
    resubmitted_at: null,
    answers: { name },
    field_schema: SCHEMA,
    review_status: 'pending',
    review_reason: null,
    reviewed_at: null,
    reviewer_name: null,
    reviewer_email: null,
  }));
  return {
    list_lounge_forms: [
      {
        id: FORM_ID,
        title: 'Patna group',
        fields: SCHEMA,
        published_at: '2026-10-01T00:00:00Z',
        is_open: true,
        can_manage: true,
      },
    ],
    export_form_responses: () => rows,
    review_form_response: (args) => {
      const row = rows.find((r) => r.id === args.p_response_id);
      row.review_status = args.p_status;
      row.review_reason = args.p_status === 'rejected' ? args.p_reason : null;
      row.reviewed_at = args.p_status === 'pending' ? null : '2026-10-10T09:00:00Z';
      row.reviewer_name = args.p_status === 'pending' ? null : 'House Secretary';
      return { id: row.id, review_status: row.review_status, review_reason: row.review_reason };
    },
    get_available_cohorts: { current: '26F3', next: '27F1', options: ['26F3', '27F1'] },
  };
}

async function openResponses(page, data = reviewDesk()) {
  const calls = await mockSupabase(page, { as: 'sa', data });
  await page.goto('/#/admin?tab=forms');
  await page.getByRole('button', { name: 'Responses' }).click();
  return { calls, dialog: page.getByRole('dialog', { name: 'Patna group responses' }) };
}

const serialsInOrder = (dialog) => dialog.locator('tbody .serial').allTextContents();

test('responses show arrival serials; sort and filter never renumber them', async ({ page }) => {
  const { dialog } = await openResponses(page);
  await expect(dialog.locator('tbody tr')).toHaveCount(3);
  expect(await serialsInOrder(dialog)).toEqual(['#3', '#2', '#1']);
  await expect(dialog.getByText('Asha Full')).toBeVisible();

  await dialog.getByLabel('Sort').selectOption('oldest');
  expect(await serialsInOrder(dialog)).toEqual(['#1', '#2', '#3']);

  await dialog.getByRole('button', { name: 'Approve 26f1000002@ds.study.iitm.ac.in' }).click();
  await expect(dialog.getByRole('button', { name: /^Approved\s*1$/ })).toBeVisible();
  await expect(dialog.getByRole('button', { name: /^Pending\s*2$/ })).toBeVisible();
  await expect(dialog.getByRole('button', { name: /^All\s*3$/ })).toBeVisible();

  await dialog.getByRole('button', { name: /^Approved/ }).click();
  expect(await serialsInOrder(dialog)).toEqual(['#2']);
  await dialog.getByRole('button', { name: /^Rejected/ }).click();
  await expect(dialog.getByText('No rejected responses.')).toBeVisible();
  await dialog.getByRole('button', { name: /^Pending/ }).click();
  await dialog.getByLabel('Sort').selectOption('newest');
  expect(await serialsInOrder(dialog)).toEqual(['#3', '#1']);
});

test('a resent response keeps its serial and place, and says when it was resent', async ({
  page,
}) => {
  const data = reviewDesk();
  const rows = data.export_form_responses();
  rows[0].resubmitted_at = '2026-10-12T08:00:00Z';
  const { dialog } = await openResponses(page, data);
  await expect(dialog.locator('tbody tr')).toHaveCount(3);
  // Resent #1 stays #1: serial and order follow the first-received time.
  expect(await serialsInOrder(dialog)).toEqual(['#3', '#2', '#1']);
  await expect(dialog.getByText(/^Resent /)).toHaveCount(1);
  await expect(
    dialog
      .locator('tbody tr')
      .nth(2)
      .getByText(/^Resent /)
  ).toBeVisible();
  await dialog.getByLabel('Sort').selectOption('oldest');
  expect(await serialsInOrder(dialog)).toEqual(['#1', '#2', '#3']);
});

test('approve sends the decision and shows who made it', async ({ page }) => {
  const { calls, dialog } = await openResponses(page);
  await dialog.getByRole('button', { name: 'Approve 26f1000001@ds.study.iitm.ac.in' }).click();
  const call = await callTo(calls, '/rest/v1/rpc/review_form_response');
  expect(JSON.parse(call.body)).toEqual({
    p_response_id: ids[0],
    p_status: 'approved',
    p_reason: null,
  });
  const row = dialog.locator('tbody tr', { hasText: '#1' });
  await expect(row.getByText('Approved', { exact: true })).toBeVisible();
  await expect(row.getByText(/House Secretary/)).toBeVisible();
  await row.getByRole('button', { name: /^Undo review/ }).click();
  await expect(row.getByText('Pending', { exact: true })).toBeVisible();
});

test('reject needs a reason, accepts a quick pick, and undo clears it', async ({ page }) => {
  const { calls, dialog } = await openResponses(page);
  await dialog.getByRole('button', { name: 'Reject 26f1000003@ds.study.iitm.ac.in' }).click();
  const reject = page.getByRole('dialog', { name: 'Reject #3' });
  const submit = reject.getByRole('button', { name: 'Reject response' });
  await expect(submit).toBeDisabled();

  await reject.getByRole('button', { name: 'Wrong region for this group' }).click();
  await expect(reject.getByRole('textbox')).toHaveValue('Wrong region for this group');
  await reject.getByRole('textbox').fill('  Wrong region for this group — try Delhi NCR  ');
  await submit.click();

  const call = await callTo(calls, '/rest/v1/rpc/review_form_response');
  expect(JSON.parse(call.body)).toEqual({
    p_response_id: ids[2],
    p_status: 'rejected',
    p_reason: 'Wrong region for this group — try Delhi NCR',
  });
  await expect(reject).toHaveCount(0);
  const row = dialog.locator('tbody tr', { hasText: '#3' });
  await expect(row.getByText('Rejected', { exact: true })).toBeVisible();
  await expect(row.getByText('Wrong region for this group — try Delhi NCR')).toBeVisible();
  await expect(row.getByRole('button', { name: /^Reject / })).toHaveCount(0);

  await row.getByRole('button', { name: /^Undo review/ }).click();
  await expect(row.getByText('Pending', { exact: true })).toBeVisible();
  await expect(row.getByText('Wrong region')).toHaveCount(0);
});

test('a failed review shows the error and leaves the row alone', async ({ page }) => {
  const { dialog } = await openResponses(page);
  await page.route('**/rest/v1/rpc/review_form_response', (route) =>
    route.request().method() === 'OPTIONS'
      ? route.fulfill({
          status: 204,
          headers: { 'access-control-allow-origin': '*', 'access-control-allow-headers': '*' },
        })
      : route.fulfill({
          status: 403,
          headers: { 'access-control-allow-origin': '*', 'content-type': 'application/json' },
          body: JSON.stringify({
            code: '42501',
            message: 'This response is outside your organizer scope',
          }),
        })
  );
  await dialog.getByRole('button', { name: 'Approve 26f1000001@ds.study.iitm.ac.in' }).click();
  await expect(dialog.getByRole('alert')).toContainText('outside your organizer scope');
  await expect(
    dialog.locator('tbody tr', { hasText: '#1' }).getByText('Pending', { exact: true })
  ).toBeVisible();
});

test('CSV export carries the serial and review columns', async ({ page }) => {
  const { dialog } = await openResponses(page);
  await dialog.getByRole('button', { name: 'Approve 26f1000001@ds.study.iitm.ac.in' }).click();
  await expect(dialog.locator('tbody tr', { hasText: '#1' }).getByText('Approved')).toBeVisible();
  const downloadPromise = page.waitForEvent('download');
  await dialog.getByRole('button', { name: 'Download CSV' }).click();
  const csv = await readFile(await (await downloadPromise).path(), 'utf8');
  const [header, first] = csv.split('\n');
  expect(header).toBe(
    'serial,email,full_name,preferred_name,submitted_at,review_status,review_reason,reviewed_by,reviewed_at,Name'
  );
  expect(first).toBe(
    '1,26f1000001@ds.study.iitm.ac.in,Asha Full,Asha,2026-10-01T10:00:00Z,approved,,House Secretary,2026-10-10T09:00:00Z,Asha'
  );
});
