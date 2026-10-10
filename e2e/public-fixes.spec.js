import { expect, test } from '@playwright/test';

const hashUrl = (path) => `/#${path}`;

test('public skip link focuses the routed page main', async ({ page }) => {
  await page.goto(hashUrl('/'));
  const skip = page.getByRole('link', { name: 'Skip to main content' });
  await skip.focus();
  await page.keyboard.press('Enter');
  await expect(page.locator('#main-content')).toBeFocused();
});

test('legacy regional meetup URL selects and preserves its region', async ({ page }) => {
  await page.goto(hashUrl('/meetups/delhi-ncr'));
  await expect(page).toHaveURL(/#\/house\?region=delhi-ncr#regions/);
  await expect(page.getByRole('heading', { name: 'Delhi NCR', exact: true })).toBeVisible();
});

test('community event links and filters produce a shareable URL', async ({ page }) => {
  await page.goto(hashUrl('/community/technical'));
  await expect(page).toHaveURL(/#\/events\?wing=tech/);
  await expect(page.getByRole('radio', { name: /Tech/ })).toHaveAttribute('aria-checked', 'true');
  await page.getByRole('searchbox', { name: 'Search events' }).fill('python');
  await expect(page).toHaveURL(/q=python/);
  await page.reload();
  await expect(page.getByRole('searchbox', { name: 'Search events' })).toHaveValue('python');
  await expect(page.getByRole('radio', { name: /Tech/ })).toHaveAttribute('aria-checked', 'true');
});

test('contact compatibility link lands on the existing council section', async ({ page }) => {
  await page.goto(hashUrl('/contact'));
  await expect(page).toHaveURL(/#\/house#council/);
  await expect(page.getByRole('heading', { name: /The council, 2026–27/ })).toBeVisible();
});

test('Lounge room selection survives the sign-in doorway', async ({ page }) => {
  await page.goto(hashUrl('/house#lounge'));
  await page.getByRole('link', { name: /Regional groups/ }).click();
  await expect(page).toHaveURL(/#\/login\?room=groups/);
});

test('course search exposes a keyboard tabbed modal and restores focus', async ({ page }) => {
  await page.goto(hashUrl('/resources'));
  const search = page.getByRole('combobox', { name: 'Search courses, notes and past papers' });
  await search.fill('BSMA1001');
  await expect(search).toHaveAttribute('aria-expanded', 'true');
  const firstOption = page.getByRole('option').first();
  await expect(firstOption).toBeVisible();
  await expect(firstOption).toHaveAttribute('tabindex', '-1');
  await search.press('Tab');
  expect(await page.evaluate(() => !!document.activeElement.closest('[role="listbox"]'))).toBe(
    false
  );
  await search.focus();
  await firstOption.click();

  const dialog = page.getByRole('dialog');
  await expect(dialog).toBeVisible();
  const papersTab = page.getByRole('tab', { name: /Past papers/ });
  const notesTab = page.getByRole('tab', { name: /Notes/ });
  await expect(papersTab).toHaveAttribute('aria-controls', 'course-panel');
  await expect(notesTab).toHaveAttribute('aria-controls', 'course-panel');
  await papersTab.focus();
  await page.keyboard.press('ArrowRight');
  await expect(notesTab).toBeFocused();
  await expect(notesTab).toHaveAttribute('aria-selected', 'true');
  await page.getByRole('button', { name: 'Close', exact: true }).click();
  await expect(dialog).toHaveCount(0);
  await expect(search).toBeFocused();
});
