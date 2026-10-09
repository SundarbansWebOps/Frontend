// The Lounge's two view transitions, which never overlap (spec: _notes/motion.md):
// - the theme switch (B's): the new sky floods out of the sun or moon as a growing circle
//   (the new snapshot is live), while the scene inside it plays its own choreography keyed on
//   data-theme: the moon spins away and the sun spins in with a flash and dotted rings, the
//   lanterns turn edge-on, swap paper and swing up into the sky as kites (html.theme-move
//   outlasts the circle so their travel finishes). The other theme's art is decoded ahead
//   (warmOther), so the circle starts on the click.
// - the page switch: Home's content fades, its scene shrinks into the Events band while the
//   boat sails from its Home spot onto the band, then the Events content comes in;
//   Events -> Home is the reverse (CSS in lounge.css, "Page switch").
// One runs at a time. A page switch skips whatever is running (navigation wins); a theme
// switch waits for a running page switch, then plays.
// Exports kept for App/Nav: switchPage, toggleTheme, warmOther, tideSrc (always '' now: D's
// painted tide wave is cut). For lamps: fadeReady(), fadeDelay().
import { nextTick, ref } from 'vue';
import { boot, store, theme, wait } from './state.js';
import { otherThemeArt } from './home/art.js';

const FADE_MS = 1500; /* the circle's edge reaches the farthest corner */
const FADE_EASE = 'cubic-bezier(0.7, 0, 0.25, 1)';
/* The longest travel inside the switch: the last kite's 1.9s swing after its 1.02s delay. */
const MOVE_MS = 3100;

/* Kept for App.vue's <img v-if="tideSrc">; nothing sets it any more. */
export const tideSrc = ref('');
let busy = false;
let epoch = 0;
let disposed = true;
const current = (ticket) => !disposed && ticket === epoch;
const warmTimers = new Set();

export function activate() {
  epoch++;
  disposed = false;
  busy = false;
  warming = null;
  warmLater(4500);
}

/* The view transition on screen now, if any, and a promise that settles when it is gone. */
let active = null;
let settled = Promise.resolve();
function own(vt) {
  active = vt;
  settled = vt.finished
    .catch(() => {})
    .then(() => {
      if (active === vt) active = null;
    });
}
const reduced = () => boot.reduce || matchMedia('(prefers-reduced-motion: reduce)').matches;

/* Theme art on the page: painted scenes (.scene img) and sprites marked data-art. */
const themeImgs = () => [...document.querySelectorAll('.scene img, img[data-art]')];

/* Fetch and decode the other theme's art (the same files <picture> will pick). */
let warming = null;
export function warmOther() {
  if (disposed) return Promise.resolve();
  if (warming) return warming;
  const urls = [
    ...new Set(
      themeImgs()
        .map((i) => i.currentSrc || i.src)
        .filter(Boolean)
        .map(otherThemeArt)
        .filter(Boolean)
    ),
  ];
  warming = Promise.all(
    urls.map((u) => {
      const img = new Image();
      img.src = u;
      return img.decode().catch(() => {});
    })
  );
  return warming;
}

/* Decode the other theme's art once the load's build has settled (and again after each
   switch), so a click never waits on images. */
function warmLater(ms) {
  const ticket = epoch;
  const timer = setTimeout(() => {
    warmTimers.delete(timer);
    if (current(ticket))
      (window.requestIdleCallback ?? setTimeout)(() => current(ticket) && warmOther());
  }, ms);
  warmTimers.add(timer);
}
async function applyTheme(next, ticket) {
  if (!current(ticket)) return;
  document.documentElement.dataset.theme = next;
  theme.value = next;
  store('lounge-e-theme', next);
  await nextTick();
  /* Capped: a stalled decode must not hold the transition (or a waiting page switch). */
  await Promise.race([Promise.all(themeImgs().map((i) => i.decode().catch(() => {}))), wait(400)]);
}

/* ---------- Theme switch: the dissolve ---------- */

/* When the fade started (performance.now()), or null when no switch is on screen. */
let fadeT0 = null;

/* Theme watchers run while the new snapshot is being prepared. Wait for ready before
   asking fadeDelay; image decoding may hold that snapshot for up to 400ms. */
export async function fadeReady() {
  await nextTick();
  if (active) await active.ready.catch(() => {});
}

/* Milliseconds from now until the new theme is about half in, the moment a lamp should
   catch (0 when no switch is running or that moment has passed). */
export function fadeDelay() {
  if (fadeT0 == null) return 0;
  return Math.max(0, FADE_MS * 0.45 - (performance.now() - fadeT0));
}

/* Where the new sky comes from: the sun or moon if it is on screen, else the toggle. */
function origin(event) {
  const body = [...document.querySelectorAll('[data-sky-body]')]
    .map((el) => el.getBoundingClientRect())
    .find(
      (r) => r.width && r.bottom > 0 && r.top < innerHeight && r.right > 0 && r.left < innerWidth
    );
  if (body) return [body.left + body.width / 2, body.top + body.height / 2];
  const b = event?.currentTarget?.getBoundingClientRect?.();
  return b?.width ? [b.left + b.width / 2, b.top + b.height / 2] : [innerWidth / 2, 0];
}

let moveTimer = 0;
export async function toggleTheme(event) {
  const root = document.documentElement;
  if (busy || disposed) return;
  const ticket = epoch;
  busy = true;
  /* A page switch on screen finishes first. */
  while (active) await settled;
  if (!current(ticket)) return;
  const next = theme.value === 'light' ? 'dark' : 'light';
  if (reduced() || !document.startViewTransition) {
    await applyTheme(next, ticket);
    warming = null;
    busy = false;
    return;
  }
  try {
    /* Usually warm already (warmLater, or the toggle's hover); never wait long. */
    await Promise.race([warmOther(), wait(250)]);
    while (active) await settled;
    if (!current(ticket)) return;
    const [x, y] = origin(event);
    const r = Math.hypot(Math.max(x, innerWidth - x), Math.max(y, innerHeight - y));
    clearTimeout(moveTimer);
    root.classList.add('vt-theme', 'theme-move');
    moveTimer = setTimeout(() => root.classList.remove('theme-move'), MOVE_MS);
    const vt = document.startViewTransition(() => applyTheme(next, ticket));
    own(vt);
    await vt.ready;
    if (!current(ticket)) return;
    fadeT0 = performance.now();
    root.animate(
      { clipPath: [`circle(0px at ${x}px ${y}px)`, `circle(${Math.ceil(r)}px at ${x}px ${y}px)`] },
      { duration: FADE_MS, easing: FADE_EASE, pseudoElement: '::view-transition-new(root)' }
    );
    await vt.finished;
  } catch (err) {
    /* Skipped by a page switch: the theme is already applied, nothing to report. */
    if (!current(ticket)) return;
    if (err?.name !== 'AbortError') console.error(err);
    if (theme.value !== next) await applyTheme(next, ticket);
  } finally {
    if (!current(ticket)) return;
    root.classList.remove('vt-theme');
    fadeT0 = null;
    warming = null;
    busy = false;
    warmLater(300);
  }
}

/* ---------- Page switch: Home <-> Events ---------- */

/* Home's scene and Events' band are the same picture: the band's `.stage` is Home's scene
   at full size, shifted up by `t` so the window shows the treeline. Mid-switch both
   snapshots are drawn unscaled (object-fit: none) at the same object-position, which keeps
   the treeline still while the window around it shrinks or grows; the full scene stays
   opaque and the band fades over it. With Home's height H, the band's height h and its
   shift t, that position is t / (H - h). */
function sceneGeo() {
  const s = document.querySelector('#main .scene');
  if (!s) return null;
  const r = s.getBoundingClientRect();
  const stage = s.querySelector('.stage');
  return { h: r.height, t: stage ? r.top - stage.getBoundingClientRect().top : null };
}

function alignScenes(a, b) {
  const band = a?.t != null ? a : b;
  const full = band === a ? b : a;
  let p = 0.5;
  if (band?.t != null && full && full.t == null && full.h > band.h) {
    p = Math.min(1, Math.max(0, band.t / (full.h - band.h)));
  }
  document.documentElement.style.setProperty('--vt-p', `${(p * 100).toFixed(3)}%`);
}

const toTop = () => window.scrollTo({ top: 0, behavior: 'instant' });

async function morph(apply, ticket) {
  if (!current(ticket)) return;
  const root = document.documentElement;
  if (
    reduced() ||
    !document.startViewTransition ||
    root.classList.contains('is-filming') ||
    !document.querySelector('#main .scene')
  ) {
    apply();
    await nextTick();
    toTop();
    return;
  }
  const before = sceneGeo();
  root.classList.remove('vt-theme', 'theme-move');
  root.classList.add('vt-page');
  /* From the band out to the full scene: the band snapshot is the one that fades. */
  root.classList.toggle('vt-grow', before?.t != null);
  const vt = document.startViewTransition(async () => {
    if (!current(ticket)) return;
    apply();
    await nextTick();
    toTop();
    const imgs = [...document.querySelectorAll('#main .scene img, #main img[data-art]')];
    await Promise.race([Promise.all(imgs.map((i) => i.decode().catch(() => {}))), wait(400)]);
    if (current(ticket)) alignScenes(before, sceneGeo());
  });
  own(vt);
  /* A skipped switch rejects `ready`; that is expected, not an error. */
  vt.ready.catch(() => {});
  try {
    await vt.finished;
  } catch (err) {
    console.error(err);
  } finally {
    if (!current(ticket)) return;
    root.classList.remove('vt-page', 'vt-grow');
    root.style.removeProperty('--vt-p');
  }
}

/* Called on every hash change. `stale()` says whether the view still differs from the URL;
   `apply()` makes it match. Rapid changes coalesce: the running switch is skipped to its
   end and one more switch runs to wherever the URL is by then. */
let pageQueued = null;
let pageLoop = false;
export async function switchPage(stale, apply) {
  if (disposed) return;
  const ticket = epoch;
  pageQueued = { stale, apply };
  active?.skipTransition();
  if (pageLoop) return;
  pageLoop = true;
  try {
    while (pageQueued) {
      while (active) await settled;
      if (!current(ticket)) break;
      const job = pageQueued;
      pageQueued = null;
      if (job.stale()) await morph(job.apply, ticket);
    }
  } finally {
    if (current(ticket)) pageLoop = false;
  }
}

// A routed Lounge can leave while a transition or preload is pending.
export function dispose() {
  disposed = true;
  epoch++;
  busy = false;
  pageLoop = false;
  fadeT0 = null;
  for (const timer of warmTimers) clearTimeout(timer);
  warmTimers.clear();
  active?.skipTransition();
  pageQueued = null;
  clearTimeout(moveTimer);
  document.documentElement.classList.remove('vt-theme', 'theme-move', 'vt-page', 'vt-grow');
  document.documentElement.style.removeProperty('--vt-p');
}
