import { test, expect } from '@playwright/test';
import { mockSupabase } from './supabase-mock.js';

const FORM_ID = '11111111-1111-4111-8111-111111111111';
const CERT_ID = '22222222-2222-4222-8222-222222222222';

const loungeData = {
  list_lounge_events: [],
  list_lounge_forms: [
    {
      id: FORM_ID,
      title: 'Technical community',
      description: 'Coding and projects.',
      fields: [
        { key: 'name', label: 'Name', type: 'text', required: true, prefill: 'name' },
        { key: 'phone', label: 'Phone', type: 'phone', required: false, prefill: 'phone' },
      ],
      region_id: null,
      community_id: 2,
      event_id: null,
      is_open: true,
      published_at: '2026-10-01T00:00:00Z',
      submitted: false,
      accepting_responses: true,
    },
  ],
  list_my_notices: [],
  list_my_certificates: [],
  get_available_cohorts: { current: '26F2', next: '26F3', options: ['26F1', '26F2'] },
  list_public_past_events: [],
  submit_lounge_form: {
    response_id: 'resp-1',
    invite_url: 'https://chat.whatsapp.com/TESTINVITE',
    registered: false,
  },
  get_lounge_form_invite: 'https://chat.whatsapp.com/TESTINVITE',
  set_my_tour_seen: '2026-10-09T12:00:00Z',
  update_my_profile: {
    preferred_name: 'Riya',
    phone: '+919990000004',
    tour_seen_at: null,
  },
  verify_issued_certificate: {
    id: CERT_ID,
    event_name: 'Build night',
    issued_at: '2026-09-01T00:00:00Z',
    valid: true,
  },
};

test.beforeEach(({ page }) => page.emulateMedia({ reducedMotion: 'reduce' }));

test('signed-in member opens a routed form and sees the invite only after submit', async ({
  page,
}) => {
  await mockSupabase(page, { data: loungeData });
  await page.goto(`/#/lounge/forms/${FORM_ID}`);
  await expect(page.getByRole('heading', { name: 'Technical community' })).toBeVisible();
  await expect(page.getByText('Open the group')).toHaveCount(0);
  await page.getByLabel(/Name/).fill('Riya');
  await page.getByRole('button', { name: 'Send' }).click();
  await expect(page.getByRole('status')).toContainText('WhatsApp invite');
  await expect(page.getByRole('link', { name: 'Open the group' })).toHaveAttribute(
    'href',
    'https://chat.whatsapp.com/TESTINVITE'
  );
  await expect(page.getByText(/Sending this form is not admission/)).toBeVisible();
});

test('public verify shows only the issued record, not a recipient name', async ({ page }) => {
  await mockSupabase(page, { signedIn: false, data: loungeData });
  await page.goto(`/#/verify-certificate?id=${CERT_ID}`);
  await expect(page.getByRole('heading', { name: 'Build night' })).toBeVisible();
  await expect(page.getByText('Verified')).toBeVisible();
  await expect(page.getByText('Riya')).toHaveCount(0);
  await expect(page.getByText(CERT_ID)).toBeVisible();
});

test('preferred name is not stored in browser-global localStorage keys', async ({ page }) => {
  await mockSupabase(page, { data: loungeData });
  await page.goto('/#/lounge');
  await expect(page.locator('.tour, .home, .lounge-boot').first()).toBeVisible();
  const leaked = await page.evaluate(() => ({
    name: localStorage.getItem('lounge-e-preferred-name'),
    cert: localStorage.getItem('lounge-e-cert-name'),
  }));
  expect(leaked.name).toBeNull();
  expect(leaked.cert).toBeNull();
});
