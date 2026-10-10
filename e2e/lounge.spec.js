import { test, expect } from '@playwright/test';
import { mockSupabase, callTo } from './supabase-mock.js';

// The Lounge needs a signed-in member; Supabase is mocked (see supabase-mock.js). The tour flag
// and names live on the member row, so a returning member is a profile with tour_seen_at set
// (the mock default); only the theme is a browser preference.
const tourRpcs = (calls) =>
  calls.filter((c) => c.path === '/rest/v1/rpc/set_my_tour_seen').map((c) => JSON.parse(c.body));

async function returningMember(page, options = {}) {
  const calls = await mockSupabase(page, options);
  await page.addInitScript(() => {
    localStorage.setItem('lounge-e-theme', 'dark');
    localStorage.setItem('sundarbans-theme', 'light');
  });
  await page.goto('/#/lounge');
  await expect(page.locator('.home')).toBeVisible();
  return calls;
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
  await page.getByRole('button', { name: 'Edit profile', exact: true }).click();
  await expect(page.getByRole('dialog')).toHaveCount(1);
  await page.goBack();
  await expect(page.locator('dialog[open]')).toHaveCount(0);
  await expect(page).toHaveURL(/#\/lounge$/);
  await expect(page.locator('.home')).toBeVisible();
});

test('Skipping the tour leaves it unseen, entering marks it seen, and name edits keep the certificate name', async ({
  page,
}) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  const calls = await mockSupabase(page, {
    profile: { tour_seen_at: null, certificate_name: 'Riya Venkataraman' },
  });
  await page.goto('/#/lounge');
  await page.getByRole('button', { name: 'Skip tour' }).click();
  await expect(page.getByLabel(/^Your name/)).toBeVisible();
  // Skip only advances to the ghat; nothing is recorded as seen yet.
  expect(tourRpcs(calls)).toEqual([]);
  await page.getByLabel(/^Your name/).fill('Riya Venkataraman');
  await page.getByRole('button', { name: 'Save', exact: true }).click();
  await page.getByRole('button', { name: 'Enter the Lounge', exact: true }).click();
  await expect(page.locator('.tour')).toHaveCount(0);
  await expect.poll(() => tourRpcs(calls)).toEqual([{ p_seen: true }]);
  await page.getByRole('button', { name: /^Your profile/ }).click();
  await page.getByRole('button', { name: 'Edit profile', exact: true }).click();
  await page.getByLabel(/^Name in the Lounge/).fill('Riya');
  await page.getByRole('button', { name: 'Save', exact: true }).click();
  await expect(page.locator('dialog[open]')).toHaveCount(0);
  const saves = calls
    .filter((c) => c.path === '/rest/v1/rpc/update_my_profile')
    .map((c) => JSON.parse(c.body).p_preferred_name);
  expect(saves).toEqual(['Riya Venkataraman', 'Riya']);
  // Editing the Lounge name never touches the printed certificate name.
  expect(calls.some((c) => c.path === '/rest/v1/rpc/confirm_my_certificate_name')).toBe(false);
  expect(
    await page.evaluate(() => ({
      preferred: localStorage.getItem('lounge-e-preferred-name'),
      certificate: localStorage.getItem('lounge-e-cert-name'),
      seen: localStorage.getItem('lounge-e-tour-seen'),
    }))
  ).toEqual({ preferred: null, certificate: null, seen: null });
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
  const clockStart = new Date('2026-10-10T00:00:00Z');
  await page.clock.install({ time: clockStart });
  // pauseAt advances time; host Date.now() can already be behind the browser clock.
  await page.clock.pauseAt(new Date(clockStart.getTime() + 60_000));
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
  // A member the roster has no name for sees the empty lantern with its naming chip.
  await mockSupabase(page, { profile: { full_name: '', preferred_name: null } });
  await page.addInitScript(() => localStorage.setItem('lounge-e-theme', 'dark'));
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
  const title = 'Build night: your first portfolio site';
  const EVENT_ID = '33333333-3333-4333-8333-333333333333';
  const FORM_ID = '44444444-4444-4444-8444-444444444444';
  const decoy = {
    ...{ id: '55555555-5555-4555-8555-555555555555', name: 'Other night' },
    stage: 'upcoming',
    starts_at: '2099-01-02T10:00:00Z',
    ends_at: '2099-01-02T11:00:00Z',
    registration: null,
  };
  // The server remembers the registration: events come back with it once the form is submitted.
  let registered = false;
  const event = () => ({
    id: EVENT_ID,
    name: title,
    stage: 'upcoming',
    starts_at: '2099-01-01T10:00:00Z',
    ends_at: '2099-01-01T11:00:00Z',
    community_id: 2,
    registration: registered ? { event_id: EVENT_ID } : null,
  });
  const form = () => ({
    id: FORM_ID,
    title,
    fields: [{ key: 'name', label: 'Your name', type: 'text', required: true, prefill: 'name' }],
    event_id: EVENT_ID,
    is_open: true,
    submitted: registered,
    accepting_responses: true,
  });
  const calls = await mockSupabase(page, {
    data: {
      list_lounge_events: () => [event(), decoy],
      list_lounge_forms: () => [form()],
      submit_lounge_form: () => {
        registered = true;
        return { response_id: 'resp-1', invite_url: null, registered: true };
      },
    },
  });
  await page.goto('/#/lounge?view=events');
  await page.getByRole('tab', { name: /Upcoming/ }).click();
  await page.getByRole('button', { name: title, exact: true }).click();
  await page.getByRole('button', { name: 'Register', exact: true }).click();
  await page.getByLabel(/^Your name/).fill('Riya Venkataraman');
  await page.getByRole('button', { name: 'Register', exact: true }).click();
  await expect(page.getByText("You're in, Riya.", { exact: true })).toBeVisible();
  const submit = await callTo(calls, '/rest/v1/rpc/submit_lounge_form');
  expect(JSON.parse(submit.body)).toMatchObject({
    p_form_id: FORM_ID,
    p_answers: { name: 'Riya Venkataraman' },
  });
  await page.getByRole('button', { name: 'Back to the river' }).click();
  await expect(page.locator('dialog[open]')).toHaveCount(0);
  // Dialog teardown precedes the asynchronous history.back navigation.
  await expect(page).toHaveURL(/#\/lounge\?view=events$/);
  await page.reload();
  await page.getByRole('tab', { name: /Mine/ }).click();
  const row = page
    .locator('.er')
    .filter({ has: page.getByRole('button', { name: title, exact: true }) });
  await expect(row.getByText('Registered', { exact: true })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Other night', exact: true })).toHaveCount(0);
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
