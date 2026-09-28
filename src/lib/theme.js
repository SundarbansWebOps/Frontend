// Light / dark theme. A reader's explicit choice is remembered; until they make one, the site
// follows the system setting. index.html applies the same rule before first paint so there is
// no flash of the wrong theme.
import { ref, watch } from 'vue';

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

export function toggleTheme() {
  theme.value = theme.value === 'dark' ? 'light' : 'dark';
  try {
    localStorage.setItem(KEY, theme.value);
  } catch {
    /* storage blocked: the choice lasts for this visit only */
  }
}
