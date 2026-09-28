// Light / dark theme. A reader's explicit choice is remembered; until they make one, the site
// follows the system setting. index.html applies the same rule before first paint so there is
// no flash of the wrong theme.
import { nextTick, ref, watch } from 'vue';

const KEY = 'sundarbans-theme';
const BAR = { light: '#f7f2e8', dark: '#15120e' }; // --paper in each theme
const media = matchMedia('(prefers-color-scheme: dark)');

function stored() {
  try {
    const v = localStorage.getItem(KEY);
    return v === 'light' || v === 'dark' ? v : null;
  } catch {
    return null;
  }
}

export const theme = ref(stored() ?? (media.matches ? 'dark' : 'light'));

media.addEventListener('change', (e) => {
  if (!stored()) theme.value = e.matches ? 'dark' : 'light';
});

watch(
  theme,
  (t) => {
    document.documentElement.dataset.theme = t;
    document.querySelector('meta[name="theme-color"]')?.setAttribute('content', BAR[t]);
  },
  { immediate: true }
);

// The new theme ripples out of the toggle: a view transition snapshots the page before and
// after, then the new snapshot is clipped in as a circle growing from the button's centre, so
// the old theme stays fully painted until the edge sweeps over it. Without the View Transitions
// API, or with reduced motion, the theme simply switches.
const RIPPLE_MS = 700; // time for the edge to reach the farthest corner

function setTheme(t) {
  theme.value = t;
  try {
    localStorage.setItem(KEY, t);
  } catch {
    /* storage blocked: the choice lasts for this visit only */
  }
}

export function toggleTheme(event) {
  const next = theme.value === 'dark' ? 'light' : 'dark';
  const root = document.documentElement;
  if (!document.startViewTransition || matchMedia('(prefers-reduced-motion: reduce)').matches) {
    setTheme(next);
    return;
  }

  const box = event?.currentTarget?.getBoundingClientRect?.();
  const x = box ? box.left + box.width / 2 : innerWidth / 2;
  const y = box ? box.top + box.height / 2 : 0;
  // Reach the farthest corner, or the circle stops while a corner still shows the old theme.
  const radius = Math.hypot(Math.max(x, innerWidth - x), Math.max(y, innerHeight - y));

  root.classList.add('theme-ripple');
  const transition = document.startViewTransition(async () => {
    setTheme(next);
    await nextTick();
  });
  transition.ready
    .then(() =>
      root.animate(
        {
          clipPath: [`circle(0px at ${x}px ${y}px)`, `circle(${radius}px at ${x}px ${y}px)`],
        },
        {
          duration: RIPPLE_MS,
          easing: 'ease-in-out',
          pseudoElement: '::view-transition-new(root)',
        }
      )
    )
    .catch(() => {}); // skipped (a quick second click, a hidden tab): the theme still switched
  transition.finished.finally(() => root.classList.remove('theme-ripple'));
}
