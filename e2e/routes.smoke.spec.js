import { test, expect } from '@playwright/test';

/**
 * Every page in src/router/index.js (hash history), mapped to where it should land.
 * Old-site paths redirect to the page that now holds their content.
 * Catch-all NotFound is omitted — the goal is to smoke the declared pages, not 404 UX.
 */
const ROUTES = {
  '/': '/',
  '/resources': '/resources',
  '/events': '/events',
  '/house': '/house',
  '/teams': '/teams',
  // Members-only: a signed-out visitor lands on the sign-in door.
  '/lounge': '/login',
  '/admin': '/login',
  '/login': '/login',
  '/verify-certificate': '/verify-certificate',
  // Old site
  '/study': '/resources',
  '/about': '/house',
  '/meetups': '/house',
  '/meetups/delhi-ncr': '/house',
  '/meetups/patna': '/house',
  '/community': '/teams',
  '/community/technical': '/events',
  '/community/cultural': '/events',
  '/community/esports': '/events',
  '/contact': '/house',
  '/dashboard': '/login',
};

function hashUrl(path) {
  // Hash router: base is origin only; route lives after #.
  return path === '/' ? '/#/' : `/#${path}`;
}

/** Path portion of location.hash (no leading #, query or section). e.g. "#/house#story" → "/house" */
function hashPathFromUrl(url) {
  let hash = new URL(url).hash || '';
  if (hash.startsWith('#')) hash = hash.slice(1);
  hash = hash.split('?')[0].split('#')[0];
  if (!hash) return '/';
  return hash.startsWith('/') ? hash : `/${hash}`;
}

// CDN/hotlink resource failures (fonts, Cloudinary, Google photos) are noise for smoke.
function isCdnResourceFailure(text) {
  return /Failed to load resource/i.test(text);
}

test.describe('route smoke', () => {
  for (const [path, landing] of Object.entries(ROUTES)) {
    test(`renders ${path} without console errors`, async ({ page }) => {
      const consoleErrors = [];
      const pageErrors = [];

      page.on('console', (msg) => {
        if (msg.type() !== 'error') return;
        const text = msg.text();
        if (isCdnResourceFailure(text)) return;
        consoleErrors.push(text);
      });
      page.on('pageerror', (err) => {
        pageErrors.push(err.message);
      });

      await page.goto(hashUrl(path), { waitUntil: 'load' });

      const app = page.locator('#app');
      await expect(app).toBeVisible();

      await expect
        .poll(() => hashPathFromUrl(page.url()), { message: `${path} should land on ${landing}` })
        .toBe(landing);

      // Declared routes must not render the 404 page.
      await expect(page.getByText('This channel runs dry', { exact: true })).toHaveCount(0);

      expect(pageErrors, `pageerror on ${path}: ${pageErrors.join(' | ')}`).toEqual([]);
      expect(consoleErrors, `console error on ${path}: ${consoleErrors.join(' | ')}`).toEqual([]);
    });
  }
});
