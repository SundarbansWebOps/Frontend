// Maintenance gate. Runs on Vercel only, and only for the production deployment, so preview
// links and local dev keep showing the real site. Reopen by setting MAINTENANCE to false and
// shipping that change to main.
const MAINTENANCE = true;

// Served as-is so the maintenance page itself loads. Everything else in the built site,
// including the JS bundle, is answered with the maintenance page.
const OPEN_PATHS = new Set(['/maintenance.html', '/favicon.png', '/apple-touch-icon.png']);

export default function middleware(request) {
  if (!MAINTENANCE || process.env.VERCEL_ENV !== 'production') return;

  const { pathname } = new URL(request.url);
  if (OPEN_PATHS.has(pathname) || pathname.startsWith('/maintenance/')) return;

  return fetch(new URL('/maintenance.html', request.url));
}
