import { test, expect } from '@playwright/test';
import process from 'node:process';

// Door hold (dev only: needs the Vite fixture). While doorHold is up when the Lounge mounts, every
// motion clock holds at its first frame; releasing starts the arrival. The flag is set on the
// canonical state.js module, which the Lounge shares in a fresh dev server. If the Lounge ever
// reads another instance (Vite ?t= copies after a hot update), the held-class checks below fail.
const local = process.env.LOCAL_LOUNGE_TEST_URL;
test.skip(!local, 'Set LOCAL_LOUNGE_TEST_URL to the loopback Vite fixture URL.');

const STATE = '/src/components/lounge/state.js';
const setHold = (page, on) =>
  page.evaluate(
    async ([path, value]) => {
      (await import(path)).doorHold.value = value;
    },
    [STATE, on]
  );

async function openLounge(page, { hold, tour = false }) {
  const url = new URL(local);
  if (tour) url.searchParams.set('local-tour', '1');
  await page.goto(`${url.href}#/`);
  await setHold(page, hold);
  await page.evaluate(() => {
    location.hash = '#/lounge';
  });
  await expect(page.locator('html')).toHaveClass(/lounge-active/);
}

const running = (page) =>
  page.evaluate(() => document.getAnimations().filter((a) => a.playState === 'running').length);

/* Visible navs (header and phone tab bar) must be hidden while held. */
const navOpacities = (page) =>
  page.evaluate(() =>
    [...document.querySelectorAll('.lnav, .lnav-tabs')]
      .filter((el) => getComputedStyle(el).display !== 'none')
      .map((el) => getComputedStyle(el).opacity)
  );

for (const [label, size] of [
  ['1366x900', { width: 1366, height: 900 }],
  ['390x844', { width: 390, height: 844 }],
]) {
  test.describe(`door hold at ${label}`, () => {
    test.use({ viewport: size });

    test('returning member holds at the resting pose, then the build plays on release', async ({
      page,
    }) => {
      await openLounge(page, { hold: true });
      const html = page.locator('html');
      await expect(html).toHaveClass(/m-hidden/);
      await expect(html).toHaveClass(/from-door/);

      await page.waitForTimeout(1000);
      expect(await running(page)).toBe(0);
      const pose = () =>
        page.evaluate(() => getComputedStyle(document.querySelector('.h-mine-in')).transform);
      const first = await pose();
      await page.waitForTimeout(1500);
      expect(await pose()).toBe(first);
      expect((await navOpacities(page)).every((o) => o === '0')).toBe(true);

      await setHold(page, false);
      await expect(html).not.toHaveClass(/m-hidden/);
      await expect.poll(() => running(page)).toBeGreaterThan(0);
      await expect(html).not.toHaveClass(/from-door/, { timeout: 8000 });
    });

    test('first-time member: the tour mounts held and its intro starts on release', async ({
      page,
    }) => {
      await openLounge(page, { hold: true, tour: true });
      const skip = page.getByRole('button', { name: 'Skip tour' });
      await expect(skip).toBeVisible();
      await page.waitForTimeout(1500);
      expect(await running(page)).toBe(0);

      await setHold(page, false);
      await expect(page.locator('html')).not.toHaveClass(/m-hidden/);
      await expect.poll(() => running(page)).toBeGreaterThan(0);
    });
  });
}

test('reduced motion never holds', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await openLounge(page, { hold: true });
  await expect(page.locator('html')).not.toHaveClass(/m-hidden|from-door/);
});

test('without the hold the Lounge starts at once', async ({ page }) => {
  await openLounge(page, { hold: false });
  await expect(page.locator('html')).not.toHaveClass(/m-hidden|from-door/);
  await expect.poll(() => running(page)).toBeGreaterThan(0);
});

/* The safety valve in LoungePage.vue (HOLD_MAX_MS = 6000) releases a door that never lifts. */
test('safety valve releases a door that stays up', async ({ page }) => {
  await openLounge(page, { hold: true });
  await expect(page.locator('html')).toHaveClass(/m-hidden/);
  await expect(page.locator('html')).not.toHaveClass(/m-hidden/, { timeout: 9000 });
});
