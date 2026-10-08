// Motion runtime shared by Home, the tour and Events (spec: _notes/motion.md).
// - reduced(): prefers-reduced-motion right now.
// - lite: a low-end device (Save-Data, <= 2 GB memory, or <= 4 cores). Fewer loops, no
//   free-flying fireflies, static far lanterns. Set once as html.lite.
// - html.m-hidden while the tab is hidden, which pauses every CSS loop (motion.css).
// - vLoop: a directive that adds .m-off to its element while it is off screen, which pauses
//   every CSS animation inside it.
// - rare(fn, min, max): a scheduler for the rare one-shot moments (shooting stars, birds,
//   the firefly sync). It only fires while the page is visible and the target is on screen,
//   so nobody comes back to a backlog.

const rm = matchMedia('(prefers-reduced-motion: reduce)');
export const reduced = () => rm.matches;

const nav = navigator;
/* Raja (2026-10-07): target a Rs 50-60k laptop, not every device. Lite is now opt-in only. */
export const lite = !!nav.connection?.saveData || new URLSearchParams(location.search).has('lite');

const root = document.documentElement;
const animations = new Map();
function syncAnimation(animation, el) {
  if (!el.isConnected) {
    animation.cancel();
  } else if (reduced()) {
    animation.finish();
  } else if (document.hidden || el.closest('.m-off')) {
    if (animation.playState === 'running') animation.pause();
  } else if (animation.playState === 'paused') {
    animation.play();
  }
}
function syncAnimations() {
  for (const [animation, el] of animations) syncAnimation(animation, el);
}

/* CSS animation-play-state does not pause Web Animations. Keep rare flights and tap
   feedback on the same visibility gate as the CSS loops, without a frame ticker. */
export function animate(el, keyframes, options) {
  const animation = el.animate(keyframes, options);
  animations.set(animation, el);
  const forget = () => animations.delete(animation);
  animation.finished.then(forget, forget);
  syncAnimation(animation, el);
  return animation;
}

const hidden = () => {
  root.classList.toggle('m-hidden', document.visibilityState === 'hidden');
  syncAnimations();
};
export function activateMotion() {
  root.classList.toggle('lite', lite);
  rm.addEventListener('change', syncAnimations);
  document.addEventListener('visibilitychange', hidden);
  hidden();
}
export function stopMotion() {
  rm.removeEventListener('change', syncAnimations);
  document.removeEventListener('visibilitychange', hidden);
  io.disconnect();
  for (const animation of animations.keys()) animation.cancel();
  root.classList.remove('lite', 'm-hidden');
}

const seen = new WeakMap();
const io = new IntersectionObserver(
  (entries) => {
    for (const e of entries) {
      e.target.classList.toggle('m-off', !e.isIntersecting);
      seen.set(e.target, e.isIntersecting);
      syncAnimations();
    }
  },
  { rootMargin: '80px 0px' }
);

export const vLoop = {
  mounted(el) {
    io.observe(el);
  },
  unmounted(el) {
    io.unobserve(el);
    for (const [animation, target] of animations) {
      if (el.contains(target)) animation.cancel();
    }
  },
};

/* Is this element (observed by vLoop) on screen? Unknown counts as yes. */
export const onScreen = (el) => !!el && seen.get(el) !== false;

/* Run fn now and then: first after `first` ms, then every min..max ms, only while the
   page is visible and `when()` is true. Returns a stop function. */
export function rare(fn, { first, min, max, when = () => true }) {
  let t = 0;
  let dead = false;
  const next = (ms) => {
    t = setTimeout(tick, ms);
  };
  const tick = () => {
    if (dead) return;
    if (!reduced() && document.visibilityState === 'visible' && when()) fn();
    if (!dead) next(min + Math.random() * (max - min));
  };
  next(first);
  return () => {
    dead = true;
    clearTimeout(t);
  };
}
