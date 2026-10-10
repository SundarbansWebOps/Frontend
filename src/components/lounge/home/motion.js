// Motion runtime shared by Home, the tour and Events (spec: _notes/motion.md).
// - reduced(): prefers-reduced-motion right now.
// - lite: a low-end device (Save-Data, <= 2 GB memory, or <= 4 cores). Fewer loops, no
//   free-flying fireflies, static far lanterns. Set once as html.lite.
// - html.m-hidden while hidden or unfocused, which pauses every CSS loop (motion.css).
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
const suspended = new Set();
let focused = document.hasFocus();
let enabled = true;
export const motionActive = () => enabled && focused && !document.hidden;
let inactiveSince = motionActive() ? null : performance.now();
let inactiveDuration = 0;
export const motionNow = () => (inactiveSince ?? performance.now()) - inactiveDuration;
const activityListeners = new Set();
export function onMotionChange(fn) {
  activityListeners.add(fn);
  return () => activityListeners.delete(fn);
}
function syncAnimation(animation, el) {
  if (!el.isConnected) {
    animation.cancel();
  } else if (reduced()) {
    animation.finish();
  } else if (!motionActive() || el.closest('.m-off')) {
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

function syncActivity() {
  const active = motionActive();
  if (!active && inactiveSince === null) inactiveSince = performance.now();
  else if (active && inactiveSince !== null) {
    inactiveDuration += performance.now() - inactiveSince;
    inactiveSince = null;
  }
  // Include transition/fallback animations started outside animate(), without a ticker.
  if (!active) {
    for (const animation of document.getAnimations()) {
      if (
        !animations.has(animation) &&
        animation.playState === 'running' &&
        !(animation instanceof CSSAnimation)
      ) {
        suspended.add(animation);
        animation.pause();
      }
    }
  } else {
    for (const animation of suspended) {
      if (animation.playState === 'paused') animation.play();
    }
    suspended.clear();
  }
  root.classList.toggle('m-hidden', !active);
  syncAnimations();
  for (const fn of activityListeners) fn(motionActive());
}
const focus = () => {
  focused = true;
  syncActivity();
};
const blur = () => {
  focused = false;
  syncActivity();
};
const visibility = () => {
  focused = document.hasFocus();
  syncActivity();
};
export function activateMotion() {
  enabled = true;
  focused = document.hasFocus();
  root.classList.toggle('lite', lite);
  rm.addEventListener('change', syncActivity);
  document.addEventListener('visibilitychange', visibility);
  window.addEventListener('focus', focus);
  window.addEventListener('blur', blur);
  syncActivity();
}
export function stopMotion() {
  enabled = false;
  syncActivity();
  rm.removeEventListener('change', syncActivity);
  document.removeEventListener('visibilitychange', visibility);
  window.removeEventListener('focus', focus);
  window.removeEventListener('blur', blur);
  io.disconnect();
  for (const animation of animations.keys()) animation.cancel();
  for (const animation of suspended) animation.cancel();
  suspended.clear();
  root.classList.remove('lite', 'm-hidden');
}

// One frame on the active scene clock. A paused scroll flight resumes without a time jump.
export function motionFrame(fn) {
  let frame = null;
  const cancel = () => {
    if (frame !== null) cancelAnimationFrame(frame);
    unsubscribe();
  };
  const sync = (active) => {
    if (!active) {
      if (frame !== null) cancelAnimationFrame(frame);
      frame = null;
    } else if (frame === null) {
      frame = requestAnimationFrame(() => {
        cancel();
        fn(motionNow());
      });
    }
  };
  const unsubscribe = onMotionChange(sync);
  sync(motionActive());
  return cancel;
}

// Decorative deadlines share the animation clock: no wakeups or elapsed hidden time.
// Returns a cancellation function, just like rare().
export function motionTimeout(fn, ms) {
  let timer = null;
  let started = 0;
  let remaining = ms;
  let dead = false;
  const cancel = () => {
    dead = true;
    clearTimeout(timer);
    unsubscribe();
  };
  const sync = (active) => {
    if (dead) return;
    if (!active) {
      if (timer !== null) {
        remaining = Math.max(0, remaining - (performance.now() - started));
        clearTimeout(timer);
        timer = null;
      }
    } else if (timer === null) {
      started = performance.now();
      timer = setTimeout(() => {
        cancel();
        fn();
      }, remaining);
    }
  };
  const unsubscribe = onMotionChange(sync);
  sync(motionActive());
  return cancel;
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
  let timer = null;
  let dead = false;
  const next = (ms) => {
    if (motionActive() && !reduced()) timer = setTimeout(tick, ms);
  };
  const tick = () => {
    timer = null;
    if (dead) return;
    if (motionActive() && !reduced() && when()) fn();
    if (!dead) next(min + Math.random() * (max - min));
  };
  const unsubscribe = onMotionChange((active) => {
    if (!active || reduced()) {
      clearTimeout(timer);
      timer = null;
    } else if (!dead && timer === null) {
      // Resume with a fresh delay, never a backlog of overdue stars or birds.
      next(first);
    }
  });
  next(first);
  return () => {
    dead = true;
    clearTimeout(timer);
    unsubscribe();
  };
}
