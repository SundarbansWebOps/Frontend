import { test, expect } from '@playwright/test';
import { mockSupabase } from './supabase-mock.js';

// A member who is already signed in with Google (Supabase mocked): the door offers to enter.
// The tour flag lives on the member row, so most tests here are first-time members.
const firstTime = { tour_seen_at: null };
const tourCalls = (calls) =>
  calls.filter((c) => c.path === '/rest/v1/rpc/set_my_tour_seen').map((c) => JSON.parse(c.body));

for (const viewport of [
  { width: 1366, height: 900 },
  { width: 390, height: 844 },
]) {
  test(`centered sign-in → tour → Lounge at ${viewport.width}px`, async ({ page }) => {
    await page.setViewportSize(viewport);
    await page.emulateMedia({ reducedMotion: 'reduce' });
    const calls = await mockSupabase(page, { profile: firstTime });
    await page.goto('/#/resources');
    await page
      .getByRole('link', { name: /Lounge/ })
      .filter({ visible: true })
      .click();
    await expect(page).toHaveURL(/#\/login$/);
    await expect(page.getByRole('button', { name: 'Enter the lounge', exact: true })).toBeVisible();
    await expect(page.locator('.nav')).toBeVisible();
    await expect(page.locator('.tabbar')).toBeVisible({ visible: viewport.width <= 760 });
    await expect(page.locator('footer, .rooms, .home, .tour')).toHaveCount(0);
    const rect = await page.locator('.sign-in > section').boundingBox();
    expect(Math.abs(rect.x + rect.width / 2 - viewport.width / 2)).toBeLessThan(1);
    const availableCenter = await page.locator('.sign-in').evaluate((el) => {
      const box = el.getBoundingClientRect();
      const css = getComputedStyle(el);
      const top = parseFloat(css.paddingTop);
      const bottom = parseFloat(css.paddingBottom);
      return box.y + top + (box.height - top - bottom) / 2;
    });
    expect(Math.abs(rect.y + rect.height / 2 - availableCenter)).toBeLessThan(1);
    if (viewport.width <= 760) {
      const bar = await page.locator('.tabbar').boundingBox();
      expect(rect.y + rect.height).toBeLessThan(bar.y);
    }
    expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBe(viewport.width);
    await expect(page.locator('.lounge.entry')).toHaveClass(/open/);
    await page.screenshot({ path: `/tmp/lounge-sign-in-${viewport.width}.png` });
    await page.getByRole('button', { name: 'Enter the lounge', exact: true }).press('Enter');
    await expect(page.locator('.tour')).toBeVisible();
    await expect(page.locator('.home')).toHaveCount(0);
    expect(tourCalls(calls)).toEqual([]);
    await page.getByRole('button', { name: 'Skip tour', exact: true }).click();
    await page.getByRole('button', { name: 'Save', exact: true }).click();
    await page.getByRole('button', { name: 'Enter the Lounge', exact: true }).click();
    await expect(page.locator('.tour')).toHaveCount(0);
    await expect(page.locator('.home')).toBeVisible();
    // Entering recorded the tour as seen on the member row, not in the browser.
    await expect.poll(() => tourCalls(calls)).toEqual([{ p_seen: true }]);
    expect(await page.evaluate(() => localStorage.getItem('lounge-e-tour-seen'))).toBeNull();
    await page.goto('/#/login');
    await page.getByRole('button', { name: 'Enter the lounge', exact: true }).click();
    await expect(page.locator('.home')).toBeVisible();
    await expect(page.locator('.tour')).toHaveCount(0);
  });
}

test('sign-in fades slowly and cannot navigate after leaving the page', async ({ page }) => {
  await mockSupabase(page, { profile: firstTime });
  await page.emulateMedia({ reducedMotion: 'no-preference' });
  // Without View Transitions the sign-in takes its timed fade instead of the cross-dissolve.
  await page.addInitScript(() => {
    document.startViewTransition = undefined;
  });
  await page.clock.install();
  await page.goto('/#/login');
  await page.getByRole('button', { name: 'Enter the lounge', exact: true }).click();
  await expect(page.locator('.sign-in')).toHaveClass(/leaving/);
  await expect(page.getByRole('button', { name: 'Entering…' })).toBeDisabled();
  await expect(page.locator('.sign-in')).toHaveCSS('transition-duration', '0.9s');
  await expect
    .poll(async () =>
      Number(await page.locator('.sign-in').evaluate((el) => getComputedStyle(el).opacity))
    )
    .toBeLessThan(0.95);
  await page.evaluate(() => {
    location.hash = '/resources';
  });
  await expect(
    page.getByRole('link', { name: 'Resources', exact: true }).filter({ visible: true })
  ).toBeVisible();
  // The shared navbar is already visible on sign-in; wait for actual page teardown.
  await expect(page.locator('.sign-in')).toHaveCount(0);
  await expect(page).toHaveURL(/#\/resources$/);
  // Cross the fade deadline after unmount: the stale click must not send us to the Tour.
  await page.clock.runFor(2000);
  await expect(page).toHaveURL(/#\/resources$/);
  await expect(page.locator('html')).not.toHaveClass(
    /sign-in-active|sign-in-arrival|lounge-active/
  );
});

test('normal-motion sign-in cross-dissolves into the painted tour', async ({ page }) => {
  await mockSupabase(page, { profile: firstTime });
  await page.emulateMedia({ reducedMotion: 'no-preference' });
  await page.goto('/#/login');
  await page.getByRole('button', { name: 'Enter the lounge', exact: true }).click();
  await expect(page.locator('.tour')).toBeVisible();
  await expect(page.locator('.sign-in')).toHaveCount(0);
  await expect(page.locator('html')).not.toHaveClass(/sign-in-cross|sign-in-arrival/);
  await expect(page.locator('.tour')).toHaveCSS('opacity', '1');
  await expect(page.locator('.home')).toHaveCount(0);
});

test('sign out returns to the sign-in door', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await mockSupabase(page, { profile: { preferred_name: 'Riya' } });
  await page.goto('/#/lounge');
  await page.getByRole('button', { name: /Your profile/ }).click();
  await page.getByRole('button', { name: 'Sign out', exact: true }).click();
  await expect(page).toHaveURL(/#\/login$/);
  await expect(
    page.getByRole('button', { name: 'Sign in with Google', exact: true })
  ).toBeVisible();
});
