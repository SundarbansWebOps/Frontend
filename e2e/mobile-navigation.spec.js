import { test, expect } from '@playwright/test';
import { mockSupabase } from './supabase-mock.js';

for (const theme of ['light', 'dark']) {
  for (const width of [320, 360, 390, 480, 560, 640, 759, 760, 761, 860, 1020, 1366]) {
    for (const area of ['public', 'lounge', 'admin']) {
      test(`${area} navigation fits and stays aligned at ${width}px in ${theme}`, async ({
        page,
      }) => {
        await page.setViewportSize({ width, height: 844 });
        await page.emulateMedia({ reducedMotion: 'reduce', colorScheme: theme });
        await mockSupabase(page, { as: 'sa' });
        await page.addInitScript((value) => localStorage.setItem('sundarbans-theme', value), theme);
        const route = { public: '/resources', lounge: '/lounge', admin: '/admin' }[area];
        const prefix = { public: '', lounge: 'l', admin: 'a' }[area];
        await page.goto(`/#${route}`);
        const header = page.locator(`header.${prefix}nav`);
        await expect(header).toBeVisible();
        await expect(page.locator('html')).toHaveAttribute('data-theme', theme);
        if (area === 'admin') {
          const fontSize = await page
            .locator('.anav-links a')
            .first()
            .evaluate((el) => parseFloat(getComputedStyle(el).fontSize));
          expect(fontSize).toBeGreaterThanOrEqual(12);
        }
        await page.evaluate(() => document.fonts.ready);
        if (width === 390 || width === 1366) {
          await page.screenshot({ path: `test-results/nav-${area}-${theme}-${width}.png` });
        }
        const layout = await header.evaluate((el) => {
          const visible = (e) => e.getBoundingClientRect().width > 0;
          const brand = el.querySelector('.brand, .lnav-brand, .anav-brand');
          const actions = el.querySelector('.acts, .lnav-acts, .anav-actions');
          const links = el.querySelector('.links, .lnav-links, .anav-links');
          const rect = (e) => {
            const { left, right, top, bottom } = e.getBoundingClientRect();
            return { left, right, top, bottom };
          };
          return {
            brand: rect(brand),
            actions: rect(actions),
            links: visible(links) ? rect(links) : null,
            controls: [...actions.children].filter(visible).map(rect),
            overflow: document.documentElement.scrollWidth - innerWidth,
          };
        });
        expect(layout.overflow).toBeLessThanOrEqual(1);
        expect(layout.brand.right).toBeLessThanOrEqual(layout.links?.left ?? layout.actions.left);
        if (layout.links) expect(layout.links.right).toBeLessThanOrEqual(layout.actions.left);
        for (const rect of layout.controls) {
          expect(rect.left).toBeGreaterThanOrEqual(0);
          expect(rect.right).toBeLessThanOrEqual(width);
        }
        if (width <= 760) {
          expect(width - layout.actions.right).toBeGreaterThanOrEqual(8);
          expect(width - layout.actions.right).toBeLessThanOrEqual(16);
          const tabs = page.locator(
            { public: '.tabbar', lounge: '.lnav-tabs', admin: '.bottom-nav' }[area]
          );
          await expect(tabs).toBeVisible();
          const bounds = await tabs.boundingBox();
          expect(Math.round(bounds.y + bounds.height)).toBe(844);
          const items = tabs.locator('a, button');
          const itemWidths = await items.evaluateAll((els) =>
            els.map((el) => el.getBoundingClientRect().width)
          );
          expect(Math.max(...itemWidths) - Math.min(...itemWidths)).toBeLessThanOrEqual(4);
        }
      });
    }
  }
}

for (const role of ['member', 'rc', 'sa']) {
  test(`${role} can navigate mobile shells without stale navbars`, async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await mockSupabase(page, { as: role });
    await page.goto('/#/lounge');
    const loungeTabs = page.locator('.lnav-tabs');
    await loungeTabs.getByRole('link', { name: 'Events', exact: true }).click();
    await expect(page).toHaveURL(/view=events/);
    await expect(loungeTabs.getByRole('link', { name: 'Events', exact: true })).toHaveAttribute(
      'aria-current',
      'page'
    );
    await loungeTabs.getByRole('link', { name: 'Home', exact: true }).click();
    await page.getByRole('button', { name: /^Your profile/ }).click();
    await expect(page.getByRole('button', { name: 'Edit profile', exact: true })).toBeVisible();
    await page.keyboard.press('Escape');
    await expect(page.getByRole('button', { name: 'Edit profile', exact: true })).toBeHidden();
    if (role !== 'member') {
      await page.goto('/#/admin');
      await page.locator('.bottom-nav').getByRole('button', { name: 'More', exact: true }).click();
      await expect(page.locator('.menu-list')).toBeVisible();
      await page.keyboard.press('Escape');
      await page.locator('.anav-links').getByRole('link', { name: 'Lounge', exact: true }).click();
      await expect(page.locator('.lnav-tabs')).toBeVisible();
    }
    await page.locator('.lnav-tabs').getByRole('link', { name: 'Website', exact: true }).click();
    await expect(page.locator('.tabbar')).toBeVisible();
    await expect(page.locator('.lnav-tabs, .bottom-nav')).toHaveCount(0);
    await page.locator('.tabbar').getByRole('link', { name: 'Resources', exact: true }).click();
    await expect(page).toHaveURL(/#\/resources$/);
    await page.locator('.tabbar').getByRole('link', { name: 'Lounge', exact: true }).click();
    await expect(page.locator('.lnav-tabs')).toBeVisible();
    await expect(page.locator('.tabbar')).toHaveCount(0);
  });
}
