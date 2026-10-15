import { test, expect } from '@playwright/test';
import { mockSupabase } from './supabase-mock.js';

for (const initial of ['light', 'dark']) {
  test(`${initial} theme follows public, Lounge and reload`, async ({ page }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await mockSupabase(page);
    await page.goto('/#/resources');
    await page.evaluate((value) => {
      localStorage.setItem('sundarbans-theme', value);
      localStorage.setItem('lounge-e-theme', value === 'light' ? 'dark' : 'light');
    }, initial);
    await page.reload();
    await expect(page.locator('html')).toHaveAttribute('data-theme', initial);
    await page.evaluate(() => {
      location.hash = '/lounge';
    });
    await expect(page.locator('.home')).toBeVisible();
    await expect(page.locator('html')).toHaveAttribute('data-theme', initial);
    await page
      .getByRole('button', {
        name: initial === 'light' ? 'Switch to night' : 'Switch to day',
        exact: true,
      })
      .click();
    const selected = initial === 'light' ? 'dark' : 'light';
    await expect(page.locator('html')).toHaveAttribute('data-theme', selected);
    await page.evaluate(() => {
      location.hash = '/resources';
    });
    await expect(page.locator('.acts .theme')).toBeVisible();
    await expect(page.locator('html')).toHaveAttribute('data-theme', selected);
    await page.reload();
    await expect(page.locator('html')).toHaveAttribute('data-theme', selected);
    await page.locator('.acts .theme').click();
    await expect(page.locator('html')).toHaveAttribute('data-theme', initial);
    await page.evaluate(() => {
      location.hash = '/lounge';
    });
    await expect(page.locator('.home')).toBeVisible();
    await expect(page.locator('html')).toHaveAttribute('data-theme', initial);
    await page.reload();
    await expect(page.locator('.home')).toBeVisible();
    await expect(page.locator('html')).toHaveAttribute('data-theme', initial);
  });
}
