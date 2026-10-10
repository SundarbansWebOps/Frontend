// Keep the approved Lounge's local preview state when it moves into the site.
const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
let theme = null;
let arrived = false;
try {
  theme = localStorage.getItem('lounge-e-theme');
} catch {
  /* storage blocked */
}
try {
  arrived = sessionStorage.getItem('lounge-e-arrived') === '1';
  sessionStorage.setItem('lounge-e-arrived', '1');
} catch {
  /* storage blocked */
}
if (theme !== 'light' && theme !== 'dark') {
  theme = matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}
export const boot = { theme, reduce, tour: true, arrived };
