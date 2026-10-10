// The Content-Security-Policy in vercel.json must not block anything the site uses. vite preview
// ignores vercel.json, so this test applies the same policy to every page it serves and fails on
// any violation (e.g. index.html's inline script changed and its hash in vercel.json did not).
import { readFileSync } from 'node:fs';
import { test, expect } from '@playwright/test';
import { mockSupabase } from './supabase-mock.js';

const vercel = JSON.parse(readFileSync(new URL('../vercel.json', import.meta.url), 'utf8'));
const headers = Object.fromEntries(vercel.headers[0].headers.map((h) => [h.key, h.value]));
// The preview server is plain http; upgrading its requests to https would break the test only.
const CSP = headers['Content-Security-Policy'].replace(/;\s*upgrade-insecure-requests/, '');

async function withPolicy(page) {
  const violations = [];
  await page.exposeFunction('reportCsp', (v) => violations.push(v));
  await page.addInitScript(() =>
    document.addEventListener('securitypolicyviolation', (e) =>
      window.reportCsp(`${e.violatedDirective} blocked ${e.blockedURI || '(inline)'}`)
    )
  );
  await page.route('http://127.0.0.1:4173/**', async (route) => {
    if (route.request().resourceType() !== 'document') return route.continue();
    const response = await route.fetch();
    await route.fulfill({
      response,
      headers: { ...response.headers(), 'content-security-policy': CSP },
    });
  });
  return violations;
}

test('vercel.json sends the security headers', () => {
  for (const key of [
    'Content-Security-Policy',
    'Strict-Transport-Security',
    'X-Content-Type-Options',
    'X-Frame-Options',
    'Referrer-Policy',
    'Permissions-Policy',
  ])
    expect(headers[key], key).toBeTruthy();
  expect(headers['Content-Security-Policy']).toContain("frame-ancestors 'none'");
  expect(headers['Content-Security-Policy']).not.toContain("'unsafe-eval'");
});

for (const path of [
  '/',
  '/resources',
  '/events',
  '/house',
  '/teams',
  '/login',
  '/verify-certificate',
])
  test(`no CSP violations on ${path}`, async ({ page }) => {
    const violations = await withPolicy(page);
    await page.goto(`/#${path}`);
    await page.waitForLoadState('networkidle');
    // The theme script (inline, allowed by hash) ran: <html> has its theme set.
    await expect(page.locator('html')).toHaveAttribute('data-theme', /light|dark/);
    expect(violations).toEqual([]);
  });

test('no CSP violations in the Lounge and the admin lounge (signed in)', async ({ page }) => {
  const violations = await withPolicy(page);
  await mockSupabase(page, { as: 'sa' });
  await page.goto('/#/lounge');
  await expect(page.locator('.home')).toBeVisible();
  await page.goto('/#/admin?tab=events');
  await expect(page.getByRole('heading', { name: 'Admin lounge', level: 1 })).toBeVisible();
  await page.waitForLoadState('networkidle');
  expect(violations).toEqual([]);
});
