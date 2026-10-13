import { test, expect } from '@playwright/test';
import { mockSupabase } from './supabase-mock.js';

for (const width of [390, 900, 1366, 1920]) {
  test(`cloud drift stays clear of painted clouds at ${width}px`, async ({ page }) => {
    await page.setViewportSize({ width, height: 900 });
    await page.emulateMedia({ reducedMotion: 'no-preference' });
    await mockSupabase(page);
    await page.goto('/#/resources');
    await page.evaluate(() => localStorage.setItem('sundarbans-theme', 'light'));
    await page.goto('/#/lounge');
    await expect(page.locator('.home')).not.toHaveClass(/intro/, { timeout: 15000 });
    const clouds = await page.locator('.clouds img').evaluateAll((images) => {
      const plate = document.querySelector('.world .plate').getBoundingClientRect();
      // Conservative bounds of the three cloud silhouettes already painted into the plate.
      const painted = [
        [0.05, 0.125, 0.126, 0.174],
        [0.108, 0.035, 0.235, 0.108],
        [0.25, 0.091, 0.361, 0.155],
      ];
      return images.map((img) => {
        const animation = img
          .getAnimations()
          .find((a) => a.animationName?.startsWith('cloud-drift'));
        const shifts = animation.effect
          .getKeyframes()
          .map(
            (frame) => new DOMMatrix(frame.transform === 'none' ? undefined : frame.transform).m41
          );
        const current = new DOMMatrix(
          getComputedStyle(img).transform === 'none' ? undefined : getComputedStyle(img).transform
        ).m41;
        const box = img.getBoundingClientRect();
        const left = box.left - current + Math.min(...shifts);
        const right = box.right - current + Math.max(...shifts);
        return {
          duration: animation.effect.getTiming().duration,
          drift: Math.max(...shifts) - Math.min(...shifts),
          overlaps: painted.some(
            ([x1, y1, x2, y2]) =>
              left < plate.left + x2 * plate.width &&
              right > plate.left + x1 * plate.width &&
              box.top < plate.top + y2 * plate.height &&
              box.bottom > plate.top + y1 * plate.height
          ),
        };
      });
    });
    expect(clouds.length).toBeGreaterThan(0);
    for (const cloud of clouds) {
      expect(cloud.overlaps).toBe(false);
      expect(cloud.duration).toBeGreaterThanOrEqual(180000);
      expect(cloud.drift).toBeLessThanOrEqual(24);
    }
    await page.screenshot({ path: `/tmp/sundarbans-sky-clouds-${width}.png` });
  });
}

test('birds cross at half speed with slower wingbeats and glides', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'no-preference' });
  await mockSupabase(page);
  await page.goto('/#/resources');
  await page.evaluate(() => localStorage.setItem('sundarbans-theme', 'light'));
  await page.clock.install();
  await page.goto('/#/lounge');
  await expect(page.locator('.home')).toBeVisible();
  await expect(page.locator('.home')).not.toHaveClass(/intro/, { timeout: 15000 });
  for (let i = 0; i < 70 && !(await page.locator('.flock').count()); i++)
    await page.clock.runFor(1000);
  await expect(page.locator('.flock')).toHaveCount(1);
  const flight = await page
    .locator('.flock')
    .evaluate((el) => el.getAnimations()[0].effect.getTiming().duration);
  expect(flight).toBeGreaterThanOrEqual(18000);
  expect(flight).toBeLessThanOrEqual(24000);
  const wings = await page
    .locator('.flock img')
    .first()
    .evaluate((el) => {
      const a = el.getAnimations()[0];
      return {
        duration: a.effect.getTiming().duration,
        frames: a.effect.getKeyframes().map((k) => ({ offset: k.offset, transform: k.transform })),
      };
    });
  expect(wings.duration).toBeGreaterThanOrEqual(3360);
  expect(wings.duration).toBeLessThanOrEqual(4640);
  expect(
    wings.frames.some((k) => k.offset === 0.5 && k.transform === wings.frames.at(-1).transform)
  ).toBe(true);
});
