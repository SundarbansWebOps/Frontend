import assert from 'node:assert/strict';
import { test } from 'node:test';

// Exercise the real runtime with an inactive desktop and a deterministic animation clock.
test('motion freezes clocks, removes hidden timers, and resumes without a backlog', async (t) => {
  const classes = new Set();
  const doc = new EventTarget();
  doc.getAnimations = () => [];
  doc.hidden = false;
  doc.hasFocus = () => true;
  doc.documentElement = {
    classList: {
      toggle: (name, on) => (on ? classes.add(name) : classes.delete(name)),
      remove: (...names) => names.forEach((name) => classes.delete(name)),
    },
  };
  const win = new EventTarget();
  const preference = new EventTarget();
  preference.matches = false;
  Object.assign(globalThis, {
    document: doc,
    window: win,
    location: { search: '' },
    matchMedia: () => preference,
    CSSAnimation: class {},
    IntersectionObserver: class {
      observe() {}
      unobserve() {}
      disconnect() {}
    },
  });
  const runtime = await import('../src/components/lounge/home/motion.js');
  let now = 0;
  let id = 0;
  const timers = new Map();
  t.mock.method(globalThis, 'setTimeout', (fn, ms) => {
    const key = ++id;
    timers.set(key, { fn, at: now + ms });
    return key;
  });
  t.mock.method(globalThis, 'clearTimeout', (key) => timers.delete(key));
  t.mock.method(performance, 'now', () => now);
  function advance(ms) {
    const end = now + ms;
    while (true) {
      const entry = [...timers].sort((a, b) => a[1].at - b[1].at)[0];
      if (!entry || entry[1].at > end) break;
      now = entry[1].at;
      timers.delete(entry[0]);
      entry[1].fn();
    }
    now = end;
  }
  runtime.activateMotion();
  const animation = {
    playState: 'running',
    currentTime: 321,
    finished: new Promise(() => {}),
    pause() {
      this.playState = 'paused';
    },
    play() {
      this.playState = 'running';
    },
    cancel() {
      this.playState = 'idle';
    },
    finish() {
      this.playState = 'finished';
    },
  };
  runtime.animate({ isConnected: true, closest: () => null, animate: () => animation }, [], {});
  const fallback = { ...animation, currentTime: 777 };
  doc.getAnimations = () => [fallback];
  let deadlines = 0;
  let stars = 0;
  const cancel = runtime.motionTimeout(() => deadlines++, 1000);
  const stopStars = runtime.rare(() => stars++, { first: 3500, min: 11000, max: 26000 });
  advance(400);
  win.dispatchEvent(new Event('blur'));
  assert.equal(classes.has('m-hidden'), true);
  assert.equal(animation.playState, 'paused');
  assert.equal(fallback.playState, 'paused');
  assert.equal(timers.size, 0, 'inactive scenes have no decorative timer wakeups');
  advance(600000);
  assert.equal(deadlines, 0);
  assert.equal(stars, 0);
  win.dispatchEvent(new Event('focus'));
  assert.equal(animation.playState, 'running');
  assert.equal(fallback.playState, 'running');
  assert.equal(fallback.currentTime, 777);
  assert.equal(animation.currentTime, 321, 'resume preserves the animation position');
  advance(599);
  assert.equal(deadlines, 0);
  advance(1);
  assert.equal(deadlines, 1, 'deadline preserves its remaining active time');
  advance(2899);
  assert.equal(stars, 0, 'rare effects have a fresh delay after focus');
  advance(1);
  assert.equal(stars, 1);
  doc.hidden = true;
  doc.dispatchEvent(new Event('visibilitychange'));
  assert.equal(animation.playState, 'paused');
  assert.equal(timers.size, 0, 'hidden tabs also remove timers');
  win.dispatchEvent(new Event('focus'));
  assert.equal(animation.playState, 'paused', 'focus cannot override a hidden document');
  doc.hidden = false;
  doc.dispatchEvent(new Event('visibilitychange'));
  assert.equal(animation.playState, 'running');
  cancel();
  stopStars();
  Object.assign(globalThis, {
    requestAnimationFrame: (fn) => setTimeout(() => fn(now), 16),
    cancelAnimationFrame: (key) => clearTimeout(key),
  });
  const beforeFrame = runtime.motionNow();
  let frameTime = null;
  const stopFrame = runtime.motionFrame((time) => {
    frameTime = time;
  });
  win.dispatchEvent(new Event('blur'));
  assert.equal(timers.size, 0);
  advance(60000);
  assert.equal(runtime.motionNow(), beforeFrame, 'scene frame clock stays frozen');
  assert.equal(frameTime, null);
  win.dispatchEvent(new Event('focus'));
  advance(16);
  assert.equal(frameTime, beforeFrame + 16, 'scroll flight resumes with no elapsed-time jump');
  stopFrame();
  runtime.stopMotion();
  assert.equal(timers.size, 0);
  win.dispatchEvent(new Event('focus'));
  assert.equal(timers.size, 0, 'disposed runtime has no focus listeners or timers');
});
