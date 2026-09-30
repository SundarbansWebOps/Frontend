// Screenshots every page in light and dark, at desktop and phone width (`npm run shots`, after
// `npm run build`). Saves them to test-results/shots/ for a reviewer to compare against the live
// site, and fails if any page scrolls sideways on a phone, the most common layout break.
import { mkdirSync } from 'node:fs';
import { preview } from 'vite';
import { chromium } from '@playwright/test';

const ROUTES = [
  '/',
  '/resources',
  '/events',
  '/house',
  '/teams',
  '/lounge',
  '/login',
  '/verify-certificate',
  '/404',
];
const WIDTHS = [
  { name: 'desktop', width: 1366, height: 900 },
  { name: 'phone', width: 390, height: 844 },
];
const OUT = 'test-results/shots';

mkdirSync(OUT, { recursive: true });
const server = await preview({ preview: { port: 4174, host: '127.0.0.1' }, logLevel: 'silent' });
const base = 'http://127.0.0.1:4174/#';
const browser = await chromium.launch({
  executablePath: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH || undefined,
});
const problems = [];

for (const scheme of ['light', 'dark']) {
  for (const size of WIDTHS) {
    // Reduced motion lands every entrance animation on its final frame.
    const context = await browser.newContext({
      viewport: { width: size.width, height: size.height },
      colorScheme: scheme,
      reducedMotion: 'reduce',
    });
    const page = await context.newPage();
    page.on('pageerror', (e) =>
      problems.push(`${page.url()} (${scheme}, ${size.name}): ${e.message}`)
    );
    for (const route of ROUTES) {
      await page.goto(base + route, { waitUntil: 'networkidle' });
      // Scroll through once so scroll-triggered reveals and lazy images are in the shot.
      await page.evaluate(async () => {
        for (let y = 0; y < document.body.scrollHeight; y += innerHeight / 2) {
          scrollTo(0, y);
          await new Promise((r) => setTimeout(r, 60));
        }
        scrollTo(0, 0);
      });
      await page.waitForTimeout(400);
      const name = `${route === '/' ? 'home' : route.slice(1)}-${scheme}-${size.name}.png`;
      await page.screenshot({ path: `${OUT}/${name}`, fullPage: true });
      const overflow = await page.evaluate(
        () => document.documentElement.scrollWidth - document.documentElement.clientWidth
      );
      if (overflow > 1) {
        problems.push(
          `${route} (${scheme}, ${size.name}): page is ${overflow}px wider than the screen and scrolls sideways.`
        );
      }
    }
    await context.close();
  }
}
await browser.close();
server.httpServer.close();

console.log(`Saved ${ROUTES.length * WIDTHS.length * 2} screenshots to ${OUT}/`);
if (problems.length) {
  console.error(`\n✘ ${problems.length} problem(s):`);
  for (const p of problems) console.error(`  - ${p}`);
  process.exit(1);
}
console.log('✔ No page errors and no sideways scrolling.');
