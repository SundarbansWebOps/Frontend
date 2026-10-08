import { test, expect } from '@playwright/test';

for (const viewport of [
  { width: 1366, height: 900 },
  { width: 390, height: 844 },
]) {
  test(`centered sign-in → tour → Lounge at ${viewport.width}px`, async ({ page }) => {
    await page.setViewportSize(viewport);
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.addInitScript(() => {
      localStorage.setItem('lounge-e-tour-seen', '1');
      localStorage.setItem('lounge-e-preferred-name', 'Riya');
      localStorage.setItem('lounge-e-cert-name', 'Riya');
    });
    await page.goto('/#/resources');
    await page
      .getByRole('link', { name: /Lounge/ })
      .filter({ visible: true })
      .click();
    await expect(page).toHaveURL(/#\/login$/);
    await expect(page.getByRole('button', { name: 'Sign in', exact: true })).toBeVisible();
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
    await page.getByRole('button', { name: 'Sign in', exact: true }).press('Enter');
    await expect(page.locator('.tour')).toBeVisible();
    await expect(page.locator('.home')).toHaveCount(0);
    expect(await page.evaluate(() => localStorage.getItem('lounge-e-tour-seen'))).toBeNull();
    await page.getByRole('button', { name: 'Skip tour', exact: true }).click();
    await page.getByRole('button', { name: 'Save', exact: true }).click();
    await page.getByRole('button', { name: 'Enter the Lounge', exact: true }).click();
    await expect(page.locator('.tour')).toHaveCount(0);
    await expect(page.locator('.home')).toBeVisible();
    expect(await page.evaluate(() => localStorage.getItem('lounge-e-tour-seen'))).toBe('1');
    await page.goto('/#/login');
    await page.getByRole('button', { name: 'Sign in', exact: true }).click();
    await expect(page.getByRole('button', { name: 'Skip tour', exact: true })).toBeVisible();
    await expect(page.locator('.home')).toHaveCount(0);
  });
}

test('sign-in fades slowly and cannot navigate after leaving the page', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'no-preference' });
  await page.clock.install();
  await page.goto('/#/login');
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
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

test('normal-motion sign-in fades into the painted tour', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'no-preference' });
  await page.goto('/#/login');
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page.locator('.sign-in')).toHaveClass(/leaving/);
  await expect(page.locator('.tour')).toBeVisible();
  await expect(page.locator('.tour')).toHaveCSS('animation-name', 'sign-in-arrive');
  await expect(page.locator('.tour')).toHaveCSS('animation-duration', '0.9s');
  await expect(page.locator('html')).not.toHaveClass(/sign-in-arrival/);
  await expect(page.locator('.tour')).toHaveCSS('opacity', '1');
  await expect(page.locator('.home')).toHaveCount(0);
});
