import { test, expect } from '@playwright/test';
import process from 'node:process';
import { mockSupabase } from './supabase-mock.js';

// Local fixture checks require the Vite dev server; production uses the normal suite server.
const local = process.env.LOCAL_LOUNGE_TEST_URL;

test('production ignores the local login flag', async ({ page }) => {
  const calls = await mockSupabase(page, { signedIn: false });
  await page.goto('/?local-lounge=1#/lounge');
  await expect(page).toHaveURL(/#\/login/);
  expect(calls.some((c) => c.path === '/rest/v1/rpc/list_lounge_events')).toBe(false);
  await expect(page.getByText('Local Test Student')).toHaveCount(0);
});

test('loopback fixture registers the exact event and persists after reload without database calls', async ({
  page,
}) => {
  test.skip(!local, 'Set LOCAL_LOUNGE_TEST_URL to the loopback Vite fixture URL.');
  await page.emulateMedia({ reducedMotion: 'reduce' });
  const external = [];
  await page.route('**/*.supabase.co/**', (route) => {
    external.push(route.request().url());
    return route.abort();
  });
  await page.goto(`${local}#/lounge?view=events`);
  await page.getByRole('tab', { name: /Upcoming/ }).click();
  await page.getByRole('button', { name: 'Local build night', exact: true }).click();
  await page.getByRole('button', { name: 'Register', exact: true }).click();
  await page.getByLabel(/^Name/).fill('Local Test Student');
  await page.getByRole('button', { name: 'Register', exact: true }).click();
  await expect(page.getByText(/You're in/)).toBeVisible();
  await page.reload();
  await page.getByRole('tab', { name: /Mine/ }).click();
  await expect(page.locator('.er').filter({ hasText: 'Local build night' })).toContainText(
    'Registered'
  );
  expect(external).toEqual([]);
});

test('loopback fixture reveals the group destination only after submission', async ({ page }) => {
  test.skip(!local, 'Set LOCAL_LOUNGE_TEST_URL to the loopback Vite fixture URL.');
  await page.emulateMedia({ reducedMotion: 'reduce' });
  const external = [];
  await page.route('**/*.supabase.co/**', (route) => {
    external.push(route.request().url());
    return route.abort();
  });
  await page.goto(`${local}#/lounge/forms/2fe75761-88af-5422-a3c7-d8e86830d3e2`);
  await expect(page.getByRole('link', { name: 'Open the group' })).toHaveCount(0);
  await page.getByLabel(/^Name/).fill('Local Test Student');
  await page.getByRole('button', { name: 'Send', exact: true }).click();
  await expect(page.getByRole('link', { name: 'Open the group' })).toHaveAttribute(
    'href',
    'https://example.invalid/local-whatsapp'
  );
  await page.reload();
  await expect(
    page.getByText('Your application is saved. Sending this form is not WhatsApp admission.', {
      exact: true,
    })
  ).toBeVisible();
  await expect(page.getByRole('link', { name: 'Open the group' })).toHaveAttribute(
    'href',
    'https://example.invalid/local-whatsapp'
  );
  await page.goto(`${local}#/lounge`);
  await expect(page.locator('.moor a[href="https://example.invalid/local-whatsapp"]')).toHaveCount(
    1
  );
  expect(external).toEqual([]);
});
