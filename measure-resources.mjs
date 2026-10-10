import { preview } from 'vite';
import { chromium } from '@playwright/test';

const server = await preview({
  root: process.cwd(),
  preview: { port: 4175, host: '127.0.0.1' },
  logLevel: 'silent',
});
const base = 'http://127.0.0.1:4175/#';
const browser = await chromium.launch({
  executablePath: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH || undefined,
});

const grid = (page, parent, item) =>
  page.evaluate(
    ({ parent, item }) => {
      const items = [...document.querySelectorAll(item)];
      const rects = items.map((b) => {
        const r = b.getBoundingClientRect();
        return { top: Math.round(r.top), left: Math.round(r.left), w: Math.round(r.width) };
      });
      const tops = [...new Set(rects.map((r) => r.top))];
      return {
        count: items.length,
        rows: tops.length,
        cols: items.length / tops.length,
        w: Math.round(items[0]?.getBoundingClientRect().width || 0),
        h: Math.round(items[0]?.getBoundingClientRect().height || 0),
        rects,
      };
    },
    { parent, item }
  );

for (const size of [
  { name: 'desktop', width: 1366, height: 900 },
  { name: 'mid', width: 1100, height: 900 },
  { name: 'phone', width: 390, height: 844 },
]) {
  const ctx = await browser.newContext({
    viewport: { width: size.width, height: size.height },
    reducedMotion: 'reduce',
  });
  const page = await ctx.newPage();
  await page.goto(base + '/resources', { waitUntil: 'networkidle' });
  await page.waitForTimeout(250);

  const branch = await grid(page, '.branches', '.branch');
  await page.click('.branches .branch');
  await page.waitForTimeout(400);
  const flowHeading1 = await page.textContent('.flow-h');
  const levels = await grid(page, '.levels', '.level');
  await page.click('.levels .level');
  await page.waitForTimeout(400);
  const flowHeading2 = await page.textContent('.flow-h');
  const courses = await grid(page, '.courses', '.course');

  console.log('\n=== ' + size.name + ' (' + size.width + ') ===');
  console.log(JSON.stringify({ branch, flowHeading1, levels, flowHeading2, courses }, null, 2));
  await ctx.close();
}

await browser.close();
server.httpServer.close();
