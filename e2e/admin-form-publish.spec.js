import { test, expect } from '@playwright/test';
import { callTo, mockSupabase, PEOPLE } from './supabase-mock.js';

test.beforeEach(async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  // Council photos come from Cloudinary, which the test machine cannot reach.
  await page.route('https://res.cloudinary.com/**', (route) => route.fulfill({ status: 204 }));
});

const FORM_ID = 'f1300000-0000-4000-8000-0000000000a1';
const REQUEST_ID = 'b1300000-0000-4000-8000-0000000000a1';
const draft = {
  id: FORM_ID,
  title: 'Join Technical',
  fields: [{ key: 'name', label: 'Name', type: 'text' }],
  community_id: 2,
  published_at: null,
  is_open: true,
  can_manage: true,
};

test('a Head sends a community form to a Super Admin and can cancel it', async ({ page }) => {
  // A table read returns this array as it stands, so the request shows up on the next load.
  const approval_requests = [];
  const calls = await mockSupabase(page, {
    as: 'head',
    data: {
      approval_requests,
      list_lounge_forms: [draft],
      save_lounge_form: FORM_ID,
      request_form_publish: () => {
        approval_requests.push({
          id: REQUEST_ID,
          type: 'form_publish',
          status: 'pending',
          target_form_id: FORM_ID,
        });
        return REQUEST_ID;
      },
      cancel_request: () => {
        approval_requests.length = 0;
        return REQUEST_ID;
      },
    },
  });
  await page.goto('/#/admin?tab=forms');
  await page.getByRole('button', { name: 'Edit' }).click();
  await expect(page.getByRole('button', { name: 'Publish', exact: true })).toHaveCount(0);
  await page.getByRole('button', { name: 'Ask a Super Admin to publish' }).click();
  await expect(
    page.getByRole('status').filter({ hasText: 'Sent to a Super Admin.' })
  ).toBeVisible();

  const save = await callTo(calls, '/rest/v1/rpc/save_lounge_form');
  expect(JSON.parse(save.body).p_form.published_at).toBeNull();
  const ask = await callTo(calls, '/rest/v1/rpc/request_form_publish');
  expect(JSON.parse(ask.body).p_form_id).toBe(FORM_ID);

  const row = page.locator('.adm-row').filter({ hasText: 'Join Technical' });
  await expect(row.getByText('waiting for approval')).toBeVisible();
  await expect(row.getByRole('button', { name: 'Edit' })).toHaveCount(0);
  await row.getByRole('button', { name: 'Cancel request' }).click();
  await expect(page.getByRole('status').filter({ hasText: 'Request cancelled.' })).toBeVisible();
  const cancel = await callTo(calls, '/rest/v1/rpc/cancel_request');
  expect(JSON.parse(cancel.body).p_request_id).toBe(REQUEST_ID);
  await expect(row.getByText('draft')).toBeVisible();
  await expect(row.getByRole('button', { name: 'Edit' })).toBeVisible();
});

test('a Super Admin sees the publish request and opens the form from it', async ({ page }) => {
  const request = {
    id: REQUEST_ID,
    type: 'form_publish',
    status: 'pending',
    reason: 'Recruitment opens Monday',
    requested_change: { form_id: FORM_ID, form_title: 'Join Technical' },
    target_snapshot: {},
    review_note: null,
    requested_at: '2026-10-24T10:00:00Z',
    reviewed_at: null,
    requested_by: PEOPLE.head.id,
    reviewed_by: null,
    target_member_id: PEOPLE.head.id,
    target_form_id: FORM_ID,
    target: { full_name: 'Meera Nair', member_code: '99f9000005' },
    requester: { full_name: 'Meera Nair' },
  };
  const calls = await mockSupabase(page, {
    as: 'sa',
    data: {
      approval_requests: [request],
      list_lounge_forms: [draft],
      approve_request: REQUEST_ID,
    },
  });
  await page.goto('/#/admin?tab=requests');
  await expect(page.getByText('Publish form').first()).toBeVisible();
  await expect(page.getByText('Join Technical').first()).toBeVisible();
  await expect(page.getByRole('cell', { name: 'Published' })).toBeVisible();

  await page.getByRole('button', { name: 'Open the form' }).click();
  const dialog = page.getByRole('dialog', { name: 'Edit form' });
  await expect(dialog).toBeVisible();
  await expect(
    dialog.getByText('A Head asked to publish this form. Approve or reject it in Requests.')
  ).toBeVisible();
  expect(calls.some((c) => c.path === '/rest/v1/rpc/approve_request')).toBe(false);
});
