// Keep the approved Lounge's local preview state when it moves into the site.
const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
let arrived = false;
try {
  arrived = sessionStorage.getItem('lounge-e-arrived') === '1';
  sessionStorage.setItem('lounge-e-arrived', '1');
} catch {
  /* storage blocked */
}
export const boot = { reduce, tour: true, arrived };
