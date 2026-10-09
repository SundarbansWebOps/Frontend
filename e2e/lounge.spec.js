import { test, expect } from '@playwright/test';
import { mockSupabase } from './supabase-mock.js';

// The Lounge needs a signed-in member; Supabase is mocked (see supabase-mock.js).
test.beforeEach(({ page }) => mockSupabase(page));

async function returningMember(page) {
  await page.addInitScript(() => {
    localStorage.setItem('lounge-e-tour-seen', '1');
    localStorage.setItem('lounge-e-theme', 'dark');
    localStorage.setItem('sundarbans-theme', 'light');
    localStorage.setItem('lounge-e-preferred-name', 'Riya Venkataraman');
    localStorage.setItem('lounge-e-cert-name', 'Riya Venkataraman');
  });
  await page.goto('/#/lounge');
  await expect(page.locator('.home')).toBeVisible();
}

test('Lounge view navigation survives Back, Forward and reload', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await returningMember(page);
  await page.getByRole('link', { name: 'Events', exact: true }).click();
  await expect(page).toHaveURL(/#\/lounge\?view=events$/);
  await expect(page.getByRole('heading', { name: 'Events', exact: true })).toBeVisible();
  await page.goBack();
  await expect(page.locator('.home')).toBeVisible();
  await page.goForward();
  await expect(page.locator('.evp')).toBeVisible();
  await page.reload();
  await expect(page.locator('.evp')).toBeVisible();
  await expect(page.locator('.lnav-links a[aria-current="page"]')).toHaveText('Events');
});

test('Back closes a handed-over name dialog without leaving Lounge', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await returningMember(page);
  await page.getByRole('button', { name: /^Your profile/ }).click();
  await page.getByRole('button', { name: 'Edit name', exact: true }).click();
  await expect(page.getByRole('dialog')).toHaveCount(1);
  await page.goBack();
  await expect(page.locator('dialog[open]')).toHaveCount(0);
  await expect(page).toHaveURL(/#\/lounge$/);
  await expect(page.locator('.home')).toBeVisible();
});

test('Skipping the tour leaves it unseen and preferred-name edits keep the certificate name', async ({
  page,
}) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.goto('/#/lounge');
  await page.getByRole('button', { name: 'Skip tour' }).click();
  await expect(page.getByLabel(/^Your name/)).toBeVisible();
  expect(await page.evaluate(() => localStorage.getItem('lounge-e-tour-seen'))).toBeNull();
  await page.getByLabel(/^Your name/).fill('Riya Venkataraman');
  await page.getByRole('button', { name: 'Save', exact: true }).click();
  await page.getByRole('button', { name: 'Enter the Lounge', exact: true }).click();
  await expect(page.locator('.tour')).toHaveCount(0);
  await page.getByRole('button', { name: /^Your profile/ }).click();
  await page.getByRole('button', { name: 'Edit name', exact: true }).click();
  await page.getByLabel(/^Name in the Lounge/).fill('Riya');
  await page.getByRole('button', { name: 'Save', exact: true }).click();
  await expect(page.locator('dialog[open]')).toHaveCount(0);
  expect(
    await page.evaluate(() => ({
      preferred: localStorage.getItem('lounge-e-preferred-name'),
      certificate: localStorage.getItem('lounge-e-cert-name'),
      seen: localStorage.getItem('lounge-e-tour-seen'),
    }))
  ).toEqual({ preferred: 'Riya', certificate: 'Riya Venkataraman', seen: '1' });
});

test('a theme switch waiting on art cannot mutate the public page after route exit', async ({
  page,
}) => {
  // Install before navigation: the idle warm-up must not cache an already-resolved decode.
  await page.addInitScript(() => {
    const decode = HTMLImageElement.prototype.decode;
    HTMLImageElement.prototype.decode = () => new Promise(() => {});
    window.restoreLoungeDecode = () => {
      HTMLImageElement.prototype.decode = decode;
    };
  });
  await returningMember(page);
  await expect(page.locator('html')).not.toHaveClass(/building/);
  await page.clock.install();
  await page.clock.pauseAt(new Date());
  // Keep both exits from the preload race pending until after route teardown.
  await page.evaluate(() => {
    const setTimer = window.setTimeout;
    window.loungePreloadCapScheduled = false;
    window.setTimeout = (fn, ms, ...args) => {
      if (ms === 250) window.loungePreloadCapScheduled = true;
      return setTimer(fn, ms, ...args);
    };
  });
  await page.getByRole('button', { name: 'Switch to day', exact: true }).click();
  expect(await page.evaluate(() => window.loungePreloadCapScheduled)).toBe(true);
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await expect(page.locator('html')).not.toHaveClass(/vt-theme|theme-move/);
  await page.evaluate(() => {
    location.hash = '/resources';
  });
  await expect(page.getByRole('link', { name: 'Resources', exact: true }).first()).toBeVisible();
  await page.evaluate(() => {
    window.loungeExitMutations = [];
    const root = document.documentElement;
    new MutationObserver(() => {
      if (
        root.dataset.theme !== 'light' ||
        /vt-theme|theme-move|vt-page|lounge-active/.test(root.className)
      ) {
        window.loungeExitMutations.push({ theme: root.dataset.theme, classes: root.className });
      }
    }).observe(root, { attributes: true });
  });
  // Advance through the held 250 ms cap only after the public view is mounted.
  await page.clock.runFor(300);
  expect(await page.evaluate(() => window.loungeExitMutations)).toEqual([]);
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  await expect(page.locator('html')).not.toHaveClass(/lounge-active|vt-theme|theme-move|vt-page/);
  await page.evaluate(() => window.restoreLoungeDecode());
  await page.clock.resume();
  // Direct revisit tests runtime recovery; the public Lounge link now opens sign-in.
  await page.evaluate(() => {
    location.hash = '/lounge';
  });
  await expect(page.locator('.home')).toBeVisible();
  await expect(page.locator('html')).toHaveClass(/lounge-active/);
});

for (const path of ['/lounge/', '/Lounge']) {
  test(`accepted Lounge URL ${path} uses only the Lounge shell`, async ({ page }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await returningMember(page);
    await page.goto(`/#${path}`);
    await expect(page.locator('.home')).toBeVisible();
    await expect(page.getByRole('link', { name: 'Resources', exact: true })).toHaveCount(0);
    await expect(page.locator('.lnav')).toHaveCount(1);
  });
}

test('leaving with the name card open does not reopen it on return', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.addInitScript(() => {
    localStorage.setItem('lounge-e-tour-seen', '1');
    localStorage.setItem('lounge-e-theme', 'dark');
  });
  await page.goto('/#/lounge');
  await page.getByRole('button', { name: 'Name your lantern', exact: true }).first().click();
  await expect(page.locator('dialog[open]')).toHaveCount(1);
  await page.evaluate(() => {
    location.hash = '/resources';
  });
  await expect(page.getByRole('link', { name: /Lounge members/ })).toBeVisible();
  // Direct revisit tests runtime recovery; the public Lounge link now opens sign-in.
  await page.evaluate(() => {
    location.hash = '/lounge';
  });
  await expect(page.locator('.home')).toBeVisible();
  await expect(page.locator('dialog[open]')).toHaveCount(0);
});

test('registering an upcoming event persists that exact event into Mine after reload', async ({
  page,
}) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await returningMember(page);
  await page.getByRole('link', { name: 'Events', exact: true }).click();
  await page.getByRole('tab', { name: /Upcoming/ }).click();
  const title = 'Build night: your first portfolio site';
  await page.getByRole('button', { name: title, exact: true }).click();
  await page.getByRole('button', { name: 'Register', exact: true }).click();
  await page.getByLabel(/^Your name/).fill('Riya Venkataraman');
  await page.getByRole('button', { name: 'Register', exact: true }).click();
  await expect(page.getByText("You're in, Riya.", { exact: true })).toBeVisible();
  expect(
    await page.evaluate(() => JSON.parse(localStorage.getItem('lounge-e-registered')))
  ).toContain('e-next');
  await page.getByRole('button', { name: 'Back to the river' }).click();
  await expect(page.locator('dialog[open]')).toHaveCount(0);
  await page.reload();
  await page.getByRole('tab', { name: /Mine/ }).click();
  const row = page
    .locator('.er')
    .filter({ has: page.getByRole('button', { name: title, exact: true }) });
  await expect(row.getByText('Registered', { exact: true })).toBeVisible();
});

test('Lounge font registration leaves the public site font family intact', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await returningMember(page);
  expect(await page.evaluate(() => getComputedStyle(document.body).fontFamily)).toContain(
    'Anek Latin Lounge'
  );
  await page.evaluate(() => {
    location.hash = '/resources';
  });
  await expect(page.getByRole('link', { name: /Lounge members/ })).toBeVisible();
  expect(await page.evaluate(() => getComputedStyle(document.body).fontFamily)).not.toContain(
    'Anek Latin Lounge'
  );
  expect(
    await page.evaluate(
      () =>
        [...document.fonts].filter(
          (face) =>
            face.family === 'Anek Latin' &&
            face.weight === '400 800' &&
            face.stretch === '75% 112.5%'
        ).length
    )
  ).toBe(0);
});
