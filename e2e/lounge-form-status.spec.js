// A student sees what the admins decided about their WhatsApp group forms: a rejected one says
// why and can be filled in again, an approved one leaves the Lounge, and "I've joined all my
// groups" hides the section (saved on the member row). Supabase is mocked; the backend contract
// is list_lounge_forms review_status / review_reason and submit_lounge_form replacing a
// rejected response.
import { test, expect } from '@playwright/test';
import { callTo, mockSupabase } from './supabase-mock.js';

const TECH = '41a00000-0000-4000-8000-000000000001';
const CULT = '41a00000-0000-4000-8000-000000000002';
const INVITE = 'https://chat.whatsapp.com/TESTINVITE';

test.beforeEach(({ page }) => page.emulateMedia({ reducedMotion: 'reduce' }));

const group = (id, label, extra = {}) => ({
  id,
  title: `${label} application`,
  form_kind: 'group',
  group_label: label,
  group_purpose: 'Build things together.',
  fields: [{ key: 'name', label: 'Name', type: 'text', required: true, prefill: 'name' }],
  region_id: null,
  community_id: 2,
  event_id: null,
  is_open: true,
  accepting_responses: true,
  published_at: '2026-10-01T00:00:00Z',
  submitted: false,
  review_status: null,
  review_reason: null,
  ...extra,
});
const approved = (id, label) => group(id, label, { submitted: true, review_status: 'approved' });
const rejected = (id, label, reason = 'Please use your full name.') =>
  group(id, label, { submitted: true, review_status: 'rejected', review_reason: reason });

test('a rejected form shows the reason and can be filled in again', async ({ page }) => {
  let form = rejected(TECH, 'Technical Circle');
  await mockSupabase(page, {
    data: {
      list_lounge_forms: () => [form],
      get_lounge_form_invite: INVITE,
      submit_lounge_form: () => {
        form = group(TECH, 'Technical Circle', { submitted: true, review_status: 'pending' });
        return { response_id: 'resp-2', invite_url: INVITE, registered: false };
      },
    },
  });
  await page.goto('/#/lounge?room=groups');
  const card = page.locator('.moor');
  await expect(card).toContainText('Technical Circle');
  await expect(card).toContainText('Not approved');
  await expect(card).toContainText('Note from the admins: Please use your full name.');
  await expect(card).toContainText('Fill again');
  await expect(card).not.toContainText('Open invite');

  await card.getByRole('link', { name: /Technical Circle/ }).click();
  await expect(page.getByRole('heading', { name: 'Technical Circle' })).toBeVisible();
  await expect(page.getByRole('status').first()).toContainText('Please use your full name.');
  await expect(page.getByText(/already saved|Your application is saved/)).toHaveCount(0);
  await page.getByLabel(/Name/).fill('Riya Venkataraman');
  await page.getByRole('button', { name: 'Send again' }).click();
  await expect(page.getByRole('status').filter({ hasText: 'One step left' })).toBeVisible();

  await page.goto('/#/lounge?room=groups');
  await expect(page.locator('.moor')).toContainText('Under review');
  await expect(page.locator('.moor')).not.toContainText('Not approved');
  await expect(page.locator('.moor a.mb')).toHaveAttribute('href', INVITE);
});

test('a pending form keeps its invite and says it is under review', async ({ page }) => {
  await mockSupabase(page, {
    data: {
      list_lounge_forms: [
        group(TECH, 'Technical Circle', { submitted: true, review_status: 'pending' }),
      ],
      get_lounge_form_invite: INVITE,
    },
  });
  await page.goto('/#/lounge?room=groups');
  await expect(page.locator('.moor')).toContainText('Under review');
  await expect(page.locator('.moor a.mb')).toHaveAttribute('href', INVITE);
  await expect(page.locator('.moor')).toContainText('Open invite');
});

test('an approved group card leaves the section; the others stay', async ({ page }) => {
  await mockSupabase(page, {
    data: {
      list_lounge_forms: [
        approved(TECH, 'Technical Circle'),
        group(CULT, 'Cultural Circle', { community_id: 3 }),
      ],
    },
  });
  await page.goto('/#/lounge?room=groups');
  await expect(page.locator('.moor')).toContainText('Cultural Circle');
  await expect(page.locator('.moor')).not.toContainText('Technical Circle');
});

test('when every group form is approved the whole section is removed', async ({ page }) => {
  await mockSupabase(page, {
    data: { list_lounge_forms: [approved(TECH, 'Technical Circle'), approved(CULT, 'Cultural')] },
  });
  await page.goto('/#/lounge');
  await expect(page.getByRole('button', { name: /^Your profile/ })).toBeVisible();
  await expect(page.locator('#groups')).toHaveCount(0);
  await expect(page.locator('.moor')).toHaveCount(0);
  await expect(page.locator('.h-cue')).toHaveCount(0);
});

test('groups not published yet keep the waiting note', async ({ page }) => {
  await mockSupabase(page, { data: { list_lounge_forms: [] } });
  await page.goto('/#/lounge');
  await expect(page.locator('#groups')).toContainText('will appear here when available');
});

test('"I\'ve joined all my groups" hides the section, saves, and can be undone', async ({
  page,
}) => {
  const calls = await mockSupabase(page, {
    data: { list_lounge_forms: [group(TECH, 'Technical Circle')] },
  });
  await page.goto('/#/lounge');
  await expect(page.locator('#groups')).toContainText('Technical Circle');

  await page.getByRole('button', { name: /^Your profile/ }).click();
  const sw = page.getByRole('switch', { name: /I've joined all my groups/ });
  await expect(sw).toHaveAttribute('aria-checked', 'false');
  await sw.click();
  const call = await callTo(calls, '/rest/v1/rpc/set_group_forms_hidden', 'POST');
  expect(JSON.parse(call.body)).toEqual({ p_hidden: true });
  await expect(sw).toHaveAttribute('aria-checked', 'true');
  await expect(page.locator('#groups')).toHaveCount(0);
  await expect(page.locator('.h-cue')).toHaveCount(0);

  // It is on the member row: a reload keeps it hidden.
  await page.reload();
  await expect(page.getByRole('button', { name: /^Your profile/ })).toBeVisible();
  await expect(page.locator('#groups')).toHaveCount(0);

  await page.getByRole('button', { name: /^Your profile/ }).click();
  const back = page.getByRole('switch', { name: /I've joined all my groups/ });
  await expect(back).toHaveAttribute('aria-checked', 'true');
  await back.click();
  await expect(back).toHaveAttribute('aria-checked', 'false');
  const hides = calls
    .filter((c) => c.path === '/rest/v1/rpc/set_group_forms_hidden')
    .map((c) => JSON.parse(c.body).p_hidden);
  expect(hides).toEqual([true, false]);
  await expect(page.locator('#groups')).toContainText('Technical Circle');
});

test('hidden still surfaces a rejected form as a small notice', async ({ page }) => {
  await mockSupabase(page, {
    profile: { group_forms_hidden: true },
    data: {
      list_lounge_forms: [
        rejected(TECH, 'Technical Circle', 'Phone number missing.'),
        group(CULT, 'Cultural Circle', { community_id: 3 }),
        { ...approved('41a00000-0000-4000-8000-000000000003', 'Esports') },
      ],
      get_lounge_form_invite: INVITE,
    },
  });
  await page.goto('/#/lounge?room=groups');
  const card = page.locator('.moor');
  await expect(card).toContainText("A group form wasn't approved");
  await expect(card).toContainText('Phone number missing.');
  await expect(card).toContainText('Fill again');
  await expect(card).not.toContainText('Cultural Circle');
});
