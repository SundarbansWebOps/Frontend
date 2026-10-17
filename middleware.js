// Launch gate. Runs on Vercel only. Until LAUNCH_AT the production deployment answers every page
// with the maintenance page, which runs the countdown and the launch film; from LAUNCH_AT on, the
// real site is served. Preview links and local dev always show the real site. A Vercel project can
// move the launch with a LAUNCH_AT environment variable (an ISO date).
const LAUNCH_AT = Date.parse(process.env.LAUNCH_AT || '2026-10-17T19:15:00+05:30');

// Served as-is so the maintenance page itself loads. Everything else in the built site,
// including the JS bundle, is answered with the maintenance page.
const OPEN_PATHS = new Set(['/maintenance.html', '/favicon.png', '/apple-touch-icon.png']);

export default async function middleware(request) {
  const { pathname } = new URL(request.url);

  // The launch time and the server's clock, so every visitor's countdown hits zero together.
  if (pathname === '/launch/time') {
    return Response.json(
      { at: LAUNCH_AT, now: Date.now() },
      { headers: { 'cache-control': 'no-store' } }
    );
  }

  if (process.env.VERCEL_ENV !== 'production' || Date.now() >= LAUNCH_AT) return;
  if (
    OPEN_PATHS.has(pathname) ||
    pathname.startsWith('/maintenance/') ||
    pathname.startsWith('/launch/')
  )
    return;

  // Never cached, so the first load after the launch is the real site.
  const page = await fetch(new URL('/maintenance.html', request.url));
  return new Response(page.body, {
    headers: { 'content-type': 'text/html; charset=utf-8', 'cache-control': 'no-store' },
  });
}
