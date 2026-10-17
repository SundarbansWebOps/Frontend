// The launch film, for a browser that missed the live launch. The live countdown and film run on
// the maintenance page (public/launch/launch.js); both share these storage keys, so a browser is
// offered the film once, ever.
import { reactive } from 'vue';

const SEEN = 'sundarbans-launch-seen';
const CUT = 'sundarbans-launch-cut';

export const launch = reactive({ offer: false });

function seen() {
  try {
    return localStorage.getItem(SEEN) === '1';
  } catch {
    return true; // no storage, no way to show it only once: don't show it
  }
}

export function markLaunchSeen() {
  try {
    localStorage.setItem(SEEN, '1');
  } catch {
    /* storage blocked */
  }
}

// True once, on the page load that follows the live film.
export function takeLaunchCut() {
  try {
    const cut = sessionStorage.getItem(CUT) === '1';
    sessionStorage.removeItem(CUT);
    return cut;
  } catch {
    return false;
  }
}

// Only Vercel answers /launch/time (middleware.js), so local dev and previews without it skip this.
export async function checkLaunch() {
  if (!import.meta.env.PROD || seen()) return;
  try {
    const res = await fetch('/launch/time', { cache: 'no-store' });
    const { at, now } = await res.json();
    launch.offer = now >= at;
  } catch {
    /* not served here */
  }
}

export function filmSrc() {
  const side = Math.max(screen.width, screen.height) * (devicePixelRatio || 1);
  const big = side >= 1600 && !navigator.connection?.saveData;
  return `/launch/film-${big ? '1080p' : '720p'}.mp4`;
}
