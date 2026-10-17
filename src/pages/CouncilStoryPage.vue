<!--
  One council's story, opened from the Legacy Board. A sideways voyage: the page scrolls down, the
  story travels right. Stops are the opening, one per chapter, and a closing stop, all on one track.
  The Legacy Board's boat sails the river below and docks at each chapter's post, always bow-first
  on the post's left.

  Scroll drives one number, `--p` (0 … LAST, fractional while moving), set straight on the DOM each
  frame: the track, the panel parallax, the progress rail and the boat all read it. Snap markers
  turn each wheel step or swipe into one stop.
-->
<template>
  <main
    id="main-content"
    ref="mainRef"
    class="journey"
    tabindex="-1"
    :style="{ '--n': STOPS.length, '--last': LAST }"
  >
    <i
      v-for="(s, i) in STOPS"
      :key="`snap-${s.key}`"
      class="snap"
      :style="{ top: `calc(${i} * var(--step))` }"
      aria-hidden="true"
    />

    <div ref="viewRef" class="view">
      <header class="bar">
        <RouterLink class="back" :to="BACK">
          <span aria-hidden="true">←</span> Legacy Board
        </RouterLink>
        <p class="where">
          <b>{{ S.label }}</b>
          <Transition name="swap" mode="out-in">
            <span :key="STOPS[active].key">{{ STOPS[active].label }}</span>
          </Transition>
        </p>
        <div class="rail" aria-hidden="true"><span class="rail-fill" /></div>
        <p class="count mono" aria-hidden="true">
          {{ pad(active + 1) }}<span> / {{ pad(STOPS.length) }}</span>
        </p>
        <div class="steps">
          <button
            type="button"
            class="step"
            :disabled="active === 0"
            aria-label="Previous stop"
            @click="go(active - 1)"
          >
            ‹
          </button>
          <button
            type="button"
            class="step"
            :disabled="active === LAST"
            aria-label="Next stop"
            @click="go(active + 1)"
          >
            ›
          </button>
        </div>
      </header>

      <div class="stage">
        <div class="track">
          <!-- The opening -->
          <section
            class="panel open"
            :class="panelClass(0)"
            style="--i: 0"
            :inert="active !== 0"
            aria-labelledby="open-h"
          >
            <div class="open-copy">
              <p class="kicker rise" style="--r: 0">{{ S.account }}</p>
              <h1 id="open-h" class="headline rise" style="--r: 1">{{ S.headline }}</h1>
              <p class="vision rise" style="--r: 2">{{ S.vision }}</p>
              <ul class="people rise" style="--r: 3" aria-label="The council">
                <li v-for="person in people" :key="person.role">
                  <b>{{ person.name }}</b>
                  <span>{{ person.role }}</span>
                </li>
              </ul>
              <button type="button" class="cue rise" style="--r: 4" @click="go(1)">
                Scroll to set sail <span aria-hidden="true">→</span>
              </button>
            </div>
            <div class="why rise par-slow" style="--r: 2">
              <div class="why-plate">
                <img
                  class="why-art"
                  :src="plate('opening')"
                  alt=""
                  width="720"
                  height="720"
                  decoding="async"
                />
              </div>
            </div>
          </section>

          <!-- One stop per chapter -->
          <section
            v-for="(c, s) in S.chapters"
            :key="c.id"
            class="panel area"
            :class="panelClass(s + 1)"
            :style="{ '--i': s + 1 }"
            :inert="active !== s + 1"
            :aria-labelledby="`area-${c.id}`"
          >
            <div class="lead">
              <p class="num mono rise" style="--r: 0">
                {{ pad(s + 1) }} <span>/ {{ pad(S.chapters.length) }}</span>
              </p>
              <h2 :id="`area-${c.id}`" class="area-name rise par-fast" style="--r: 1">
                {{ c.title }}
              </h2>
              <p class="area-line rise" style="--r: 2">{{ c.line }}</p>
              <img
                class="art par-slow"
                :src="plate(c.art)"
                alt=""
                width="720"
                height="720"
                decoding="async"
              />
            </div>

            <article class="sheet rise" style="--r: 2" :aria-labelledby="`sheet-${c.id}`">
              <div class="band" aria-hidden="true" />
              <div class="sheet-body">
                <p :id="`sheet-${c.id}`" class="sheet-name">{{ c.label }}</p>
                <p class="body-text">{{ c.body }}</p>
                <ul v-if="c.points.length" class="points" aria-label="Highlights">
                  <li v-for="point in c.points" :key="point">{{ point }}</li>
                </ul>
                <figure class="claim">
                  <figcaption class="cap">In the council’s words</figcaption>
                  <blockquote>{{ c.quote }}</blockquote>
                </figure>
              </div>
            </article>
          </section>

          <!-- Looking back -->
          <section
            class="panel creed-panel"
            :class="panelClass(LAST)"
            :style="{ '--i': LAST }"
            :inert="active !== LAST"
            aria-labelledby="closing-h"
          >
            <div class="floor">
              <p class="kicker rise" style="--r: 0">{{ S.label }}</p>
              <h2 id="closing-h" class="area-name rise par-fast" style="--r: 1">
                {{ S.closing.title }}
              </h2>
              <p class="floor-text rise" style="--r: 2">{{ S.closing.text }}</p>
              <RouterLink class="home rise" style="--r: 4" :to="BACK">
                <span aria-hidden="true">←</span> Back to the Legacy Board
              </RouterLink>
            </div>
            <p class="creed par-slow">
              <span class="rise" style="--r: 2">{{ S.closing.quote }}</span>
            </p>
            <p v-if="S.credit" class="kicker rise" style="--r: 3">{{ S.credit }}</p>
          </section>
        </div>
      </div>

      <nav ref="riverRef" class="river" aria-label="Stops on the river">
        <div
          class="plate"
          :style="{ backgroundImage: `url(${theme === 'dark' ? plateNight : plateDay})` }"
          aria-hidden="true"
        />
        <div ref="worldRef" class="world">
          <button
            v-for="(post, k) in POSTS"
            :key="post.key"
            type="button"
            class="post"
            :style="{ left: `${postX[k] ?? 0}px` }"
            :aria-current="active === post.stop ? 'step' : undefined"
            @click="go(post.stop)"
          >
            <img class="post-img" :src="mooringArt" alt="" width="493" height="1200" />
            <span class="post-tag">{{ post.label }}</span>
          </button>
          <div ref="boatRef" class="boat" aria-hidden="true">
            <img class="boat-img" :src="boatArt" alt="" width="1200" height="494" />
          </div>
        </div>
      </nav>
    </div>
  </main>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue';
import boatArt from '../assets/legacy/a-boat.webp';
import mooringArt from '../assets/legacy/a-mooring.webp';
import plateDay from '../components/lounge/home/art/plate-day-1536.webp';
import plateNight from '../components/lounge/home/art/plate-night-1536.webp';
import { LEGACY } from '../data/legacy.data.js';
import { STORIES } from '../data/council-stories.data.js';
import { theme as themeRef } from '../lib/theme.js';

const props = defineProps({
  // The key into STORIES, for example '2021-22'.
  story: { type: String, required: true },
});

const S = STORIES[props.story];
const council = LEGACY.find((d) => d.year === Number(S.key.slice(0, 4)));
const people = [council.secretary, council.deputy];
const BACK = { path: '/teams/legacy', query: { year: S.key.slice(0, 4) } };
const theme = computed(() => themeRef.value);

const PLATES = import.meta.glob('../assets/legacy/council/*.webp', {
  eager: true,
  import: 'default',
});
const plate = (art) => PLATES[`../assets/legacy/council/${S.key}-${art}.webp`];
const pad = (n) => String(n).padStart(2, '0');

// Stops: the opening, one per chapter, then the closing. The posts on the river are the chapters.
const STOPS = [
  { key: 'open', label: 'The story' },
  ...S.chapters.map((c) => ({ key: c.id, label: c.label })),
  { key: 'closing', label: 'Looking back' },
];
const LAST = STOPS.length - 1;
const POSTS = S.chapters.map((c, k) => ({ key: c.id, label: c.label, stop: k + 1 }));

const mainRef = ref(null);
const viewRef = ref(null);
const riverRef = ref(null);
const worldRef = ref(null);
const boatRef = ref(null);

const active = ref(0);
const seen = reactive(new Set([0]));
const postX = ref([]);
const reduceQuery = matchMedia('(prefers-reduced-motion: reduce)');
const reduced = ref(reduceQuery.matches);

const panelClass = (i) => ({ on: active.value === i, seen: seen.has(i) });

// Scroll per stop, as a share of the viewport: one wheel step or swipe moves one stop.
const STEP_VH = 0.8;
// Bow-to-post air when docked.
const DOCK_GAP = 10;

let step = 1;
let viewTop = 0;
let p = 0;
let lastP = 0;
let frame = 0;
let settleTimer = 0;
let geo = null;

function measure() {
  const main = mainRef.value;
  const river = riverRef.value;
  const boat = boatRef.value;
  if (!main || !river || !boat) return;
  step = Math.round(innerHeight * STEP_VH);
  main.style.setProperty('--step', `${step}px`);
  viewTop = parseFloat(getComputedStyle(viewRef.value).top) || 0;

  // River geometry in px. On a narrow screen the posts keep a boat's length between them and the
  // river becomes wider than the screen; the camera then follows the boat.
  const w = river.clientWidth;
  const bw = boat.offsetWidth;
  const space = Math.max(w * 0.135, bw + 56);
  const first = Math.max(w * 0.2, bw + 64);
  const xs = Array.from({ length: POSTS.length }, (_, k) => first + k * space);
  postX.value = xs;
  const dock = (x) => x - bw - DOCK_GAP;
  // Where the boat rests at each stop: waiting upstream, docked at each chapter, then docked at
  // the last post for the closing stop.
  const lastX = xs[xs.length - 1];
  geo = {
    w,
    bw,
    world: lastX + Math.max(96, w * 0.1),
    rest: [Math.max(16, first - bw - space * 0.9), ...xs.map(dock), dock(lastX)],
  };
}

function boatAt(t) {
  const a = Math.floor(t);
  const b = Math.min(LAST, a + 1);
  return geo.rest[a] + (geo.rest[b] - geo.rest[a]) * (t - a);
}

function paint() {
  frame = 0;
  const main = mainRef.value;
  if (!main || !geo) return;
  p = Math.min(LAST, Math.max(0, (viewTop - main.getBoundingClientRect().top) / step));
  main.style.setProperty('--p', p.toFixed(4));

  const x = boatAt(p);
  const cam = Math.min(Math.max(0, geo.world - geo.w), Math.max(0, x + geo.bw / 2 - geo.w * 0.42));
  worldRef.value.style.transform = `translate3d(${-cam}px,0,0)`;
  boatRef.value.style.transform = `translate3d(${x}px,0,0)`;

  // The hull leans into the travel, then settles; at a chapter post it rests against the post.
  const v = p - lastP;
  lastP = p;
  const lean = reduced.value ? 0 : Math.max(-4, Math.min(4, v * -90));
  boatRef.value.style.setProperty('--lean', `${lean}deg`);
  clearTimeout(settleTimer);
  settleTimer = setTimeout(settle, 140);

  const near = Math.round(p);
  if (near !== active.value) active.value = near;
  for (let i = 0; i <= LAST; i += 1) if (Math.abs(i - p) < 0.6) seen.add(i);
}

function settle() {
  const boat = boatRef.value;
  if (!boat) return;
  const docked =
    Math.abs(p - Math.round(p)) < 0.02 && active.value >= 1 && active.value <= LAST - 1;
  boat.style.setProperty('--lean', docked && !reduced.value ? '2deg' : '0deg');
}

function onScroll() {
  if (!frame) frame = requestAnimationFrame(paint);
}

function onResize() {
  measure();
  onScroll();
}

function go(i) {
  const main = mainRef.value;
  if (!main || i < 0 || i > LAST) return;
  const start = scrollY + main.getBoundingClientRect().top - viewTop;
  scrollTo({ top: start + i * step, behavior: reduced.value ? 'auto' : 'smooth' });
}

function onKey(e) {
  if (e.defaultPrevented || e.altKey || e.ctrlKey || e.metaKey || e.shiftKey) return;
  if (e.key !== 'ArrowLeft' && e.key !== 'ArrowRight') return;
  // Leave the arrows alone inside anything that uses them itself.
  if (e.target?.closest?.('input, textarea, select, [contenteditable]')) return;
  e.preventDefault();
  go(active.value + (e.key === 'ArrowLeft' ? -1 : 1));
}

// Wheels and trackpads: one notch, or one swipe however long its glide, moves one stop. Sideways
// swipes count too. Touch keeps native scrolling and lands on the snap markers.
let wheelSum = 0;
let wheelAt = 0;
let lockUntil = 0;
function onWheel(e) {
  if (e.ctrlKey) return;
  const d = Math.abs(e.deltaX) > Math.abs(e.deltaY) ? e.deltaX : e.deltaY;
  const dir = Math.sign(d);
  if ((dir < 0 && p <= 0) || (dir > 0 && p >= LAST)) return;
  e.preventDefault();
  const now = performance.now();
  if (now < lockUntil) {
    lockUntil = Math.max(lockUntil, now + 180);
    return;
  }
  if (now - wheelAt > 200) wheelSum = 0;
  wheelAt = now;
  wheelSum += d * (e.deltaMode === 1 ? 40 : 1);
  if (Math.abs(wheelSum) < 24) return;
  wheelSum = 0;
  lockUntil = now + 650;
  go(Math.round(p) + dir);
}

function onReduce() {
  reduced.value = reduceQuery.matches;
  onScroll();
}

let resizeObs;
onMounted(() => {
  // Touch swipes land on one stop. Only this page snaps, so the setting leaves with it.
  document.documentElement.style.scrollSnapType = 'y mandatory';
  measure();
  paint();
  addEventListener('scroll', onScroll, { passive: true });
  addEventListener('resize', onResize);
  addEventListener('keydown', onKey);
  addEventListener('wheel', onWheel, { passive: false });
  reduceQuery.addEventListener('change', onReduce);
  resizeObs = new ResizeObserver(onResize);
  resizeObs.observe(riverRef.value);
});

onBeforeUnmount(() => {
  document.documentElement.style.scrollSnapType = '';
  cancelAnimationFrame(frame);
  clearTimeout(settleTimer);
  removeEventListener('scroll', onScroll);
  removeEventListener('resize', onResize);
  removeEventListener('keydown', onKey);
  removeEventListener('wheel', onWheel);
  reduceQuery.removeEventListener('change', onReduce);
  resizeObs?.disconnect();
});
</script>

<style scoped>
/* ---- The scroll track: tall enough for one viewport plus a step per stop ---- */
.journey {
  --step: 80vh;
  --p: 0;
  --par: 1;
  --gutter: clamp(24px, 5vw, 88px);
  position: relative;
  height: calc(100dvh - var(--nav-h) + var(--last) * var(--step));
  background: var(--paper);
  color: var(--ink);
}
.journey:focus {
  outline: none;
}
.snap {
  position: absolute;
  left: 0;
  width: 1px;
  height: 1px;
  scroll-snap-align: start;
  scroll-margin-top: var(--nav-h);
  pointer-events: none;
}

.view {
  position: sticky;
  top: var(--nav-h);
  height: calc(100dvh - var(--nav-h));
  display: grid;
  grid-template-rows: auto minmax(0, 1fr) clamp(118px, 18vh, 168px);
  overflow: hidden;
}

/* ---- The bar: where you came from, where you are, how far along ---- */
.bar {
  display: flex;
  align-items: center;
  gap: clamp(12px, 2vw, 24px);
  padding: 14px var(--gutter);
  border-bottom: 1px solid var(--line);
}
.back {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 7px 14px;
  border: 1px solid var(--line-strong);
  border-radius: 999px;
  color: var(--ink);
  font-size: 14px;
  font-weight: 650;
  text-decoration: none;
  white-space: nowrap;
  transition:
    background 0.2s,
    border-color 0.2s;
}
.back:hover {
  border-color: var(--ink);
  background: var(--card);
}
.where {
  display: flex;
  align-items: baseline;
  gap: 10px;
  margin: 0;
  font-size: 15px;
  white-space: nowrap;
}
.where b {
  font-weight: 800;
  font-variant-numeric: tabular-nums;
}
.where span {
  display: inline-block;
  color: var(--ink-2);
  font-weight: 600;
}
.rail {
  position: relative;
  flex: 1;
  min-width: 40px;
  height: 3px;
  border-radius: 3px;
  background: var(--line);
  overflow: hidden;
}
.rail-fill {
  position: absolute;
  inset: 0;
  background: var(--mari);
  transform-origin: 0 50%;
  transform: scaleX(calc(var(--p) / var(--last)));
}
.count {
  margin: 0;
  font-size: 14px;
  font-weight: 700;
  font-variant-numeric: tabular-nums;
}
.count span {
  color: var(--ink-3);
}
.steps {
  display: flex;
  gap: 6px;
}
.step {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  padding: 0 0 3px;
  border: 1px solid var(--line-strong);
  border-radius: 50%;
  background: var(--card);
  color: var(--ink);
  font: inherit;
  font-size: 22px;
  line-height: 1;
  cursor: pointer;
  transition:
    transform 0.2s var(--ease-out),
    border-color 0.2s,
    opacity 0.2s;
}
.step:hover:not(:disabled) {
  border-color: var(--ink);
  transform: translateY(-1px);
}
.step:disabled {
  opacity: 0.35;
  cursor: default;
}

.swap-enter-active,
.swap-leave-active {
  transition:
    opacity 0.2s,
    transform 0.25s var(--ease-out);
}
.swap-enter-from {
  opacity: 0;
  transform: translateY(6px);
}
.swap-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}

/* ---- The stage: one track of panels, moved by --p ---- */
.stage {
  position: relative;
  min-height: 0;
  overflow: hidden;
}
.track {
  display: flex;
  width: calc(var(--n) * 100%);
  height: 100%;
  transform: translate3d(calc(var(--p) * -100% / var(--n)), 0, 0);
  will-change: transform;
}
.panel {
  /* Distance from the reader, in stops: 0 here, ±1 a stop away. */
  --d: calc(var(--i) - var(--p));
  position: relative;
  flex: 0 0 calc(100% / var(--n));
  min-width: 0;
  height: 100%;
  display: grid;
  grid-template-columns: minmax(0, 0.9fr) minmax(0, 1.1fr);
  align-items: center;
  gap: clamp(24px, 4vw, 72px);
  padding: clamp(16px, 3vh, 36px) var(--gutter);
  opacity: clamp(0, calc(1 - var(--d) * var(--d) * 1.1), 1);
}
/* Depth: titles run ahead of their panel, art lags behind it. */
.par-fast {
  transform: translate3d(calc(var(--d) * var(--par) * 14vw), 0, 0);
}
.par-slow {
  transform: translate3d(calc(var(--d) * var(--par) * -7vw), 0, 0);
}

/* First arrival at a stop: its pieces rise in, once. */
.panel:not(.seen) .rise {
  opacity: 0;
}
.panel.seen .rise {
  animation: rise 0.6s var(--ease-out) both;
  animation-delay: calc(var(--r, 0) * 80ms + 60ms);
}
@keyframes rise {
  from {
    opacity: 0;
    translate: 0 18px;
  }
}

.kicker,
.cap,
.num,
.sheet-name {
  margin: 0;
  color: var(--ink-2);
  font-size: 13px;
  font-weight: 750;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

/* ---- Opening ---- */
.open {
  grid-template-columns: minmax(0, 1.15fr) minmax(0, 0.85fr);
}
.open-copy {
  display: grid;
  gap: clamp(14px, 2.2vh, 22px);
  max-width: 680px;
}
.headline {
  margin: 0;
  font-size: clamp(34px, 4.4vw, 48px);
  font-weight: 800;
  line-height: 1.04;
  letter-spacing: -0.025em;
  text-wrap: balance;
}
.vision {
  margin: 0;
  max-width: 54ch;
  color: var(--ink);
  font-size: clamp(16px, 1.25vw, 18px);
  line-height: 1.55;
}
.people {
  display: flex;
  flex-wrap: wrap;
  gap: 10px 28px;
  margin: 0;
  padding: 14px 0 0;
  border-top: 1px solid var(--line);
  list-style: none;
}
.people li {
  display: grid;
  gap: 2px;
}
.people b {
  font-size: 15px;
  font-weight: 750;
}
.people span {
  color: var(--ink-2);
  font-size: 14px;
}
.cue {
  justify-self: start;
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 12px 20px;
  border: 0;
  border-radius: 999px;
  background: var(--ink);
  color: var(--paper);
  font: inherit;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
}
.cue span {
  transition: transform 0.3s var(--ease-spring);
}
.cue:hover span {
  transform: translateX(4px);
}

.why {
  /* Phone aligns the opening panel to its start, so the card needs its own width or the plate
     sizes itself to the art's natural width and runs off the screen. */
  width: 100%;
  min-width: 0;
  overflow: hidden;
  border: 1.5px solid var(--line-strong);
  border-radius: 18px;
  background: var(--card);
  box-shadow: var(--shadow);
}
.why-plate {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  height: clamp(200px, 40vh, 380px);
  padding: 12px;
  background: var(--sunk);
}
.why-art {
  display: block;
  height: 100%;
  max-width: 100%;
  width: auto;
  aspect-ratio: 1;
  object-fit: contain;
}

/* ---- Chapters ---- */
.lead {
  display: grid;
  align-content: center;
  gap: 8px;
  min-width: 0;
}
.num span {
  color: var(--ink-3);
}
.area-name {
  margin: 0;
  font-size: clamp(34px, 4.4vw, 48px);
  font-weight: 850;
  line-height: 0.95;
  letter-spacing: -0.04em;
  text-wrap: balance;
}
.area-line {
  margin: 0;
  color: var(--ink-2);
  font-size: clamp(16px, 1.4vw, 19px);
  font-weight: 600;
}
.art {
  display: block;
  width: auto;
  height: min(34vh, 360px);
  max-width: 100%;
  aspect-ratio: 1;
  object-fit: contain;
  margin-top: clamp(4px, 2vh, 20px);
}

.sheet {
  min-width: 0;
  overflow: hidden;
  border: 1.5px solid var(--line-strong);
  border-radius: 18px;
  background: var(--card);
  box-shadow: var(--shadow);
}
.band {
  height: 14px;
  background: url('../assets/pat/band.webp') repeat-x center / auto 100%;
  border-bottom: 1px solid var(--line);
}
.sheet-body {
  display: grid;
  gap: 14px;
  padding: clamp(18px, 2.6vh, 28px) clamp(20px, 2.2vw, 32px) clamp(20px, 2.8vh, 30px);
}
.sheet-name {
  color: var(--mari-ink);
}
.body-text {
  margin: 0;
  max-width: 62ch;
  font-size: 15px;
  line-height: 1.6;
}
.points {
  display: grid;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.points li {
  position: relative;
  padding-left: 18px;
  font-size: 14.5px;
  line-height: 1.5;
}
.points li::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0.55em;
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--mari);
}
.claim {
  display: grid;
  gap: 4px;
  margin: 2px 0 0;
  padding: 12px 16px;
  border-left: 4px solid var(--mari);
  border-radius: 0 10px 10px 0;
  background: var(--mari-soft);
}
.claim blockquote {
  margin: 0;
  font-size: 16px;
  font-weight: 750;
  line-height: 1.35;
}

/* ---- Looking back ---- */
.floor {
  display: grid;
  gap: 14px;
}
.creed-panel .area-name {
  font-size: clamp(34px, 4.4vw, 48px);
  text-wrap: balance;
}
.floor-text {
  margin: 0;
  max-width: 52ch;
  font-size: clamp(16px, 1.25vw, 18px);
  line-height: 1.6;
}
.home {
  justify-self: start;
  margin-top: 8px;
  padding: 12px 20px;
  border-radius: 999px;
  background: var(--mari);
  color: var(--on-mari);
  font-size: 15px;
  font-weight: 750;
  text-decoration: none;
  transition: transform 0.25s var(--ease-spring);
}
.home:hover {
  transform: translateY(-2px);
}
.creed {
  margin: 0;
  font-size: clamp(28px, 3vw, 40px);
  font-weight: 850;
  line-height: 1.08;
  letter-spacing: -0.03em;
  text-wrap: balance;
}
.creed span {
  color: var(--mari-ink);
}

/* ---- The river: the Legacy Board's water, posts and boat ---- */
.river {
  --boat-w: clamp(96px, 10.5vw, 160px);
  --post-h: clamp(52px, 10vh, 96px);
  --water: 14%;
  position: relative;
  min-height: 0;
  overflow: hidden;
  border-top: 1.5px solid var(--line-strong);
  background: var(--sunk);
}
.plate {
  position: absolute;
  inset: 0 -8% 0 0;
  background-position: center 42%;
  background-size: cover;
  transform: translate3d(calc(var(--p) / var(--last) * var(--par) * -6%), 0, 0);
}
.world {
  position: absolute;
  inset: 0;
  will-change: transform;
}
.post {
  position: absolute;
  bottom: var(--water);
  z-index: 1;
  translate: -50% 0;
  display: flex;
  flex-direction: column-reverse;
  align-items: center;
  gap: 6px;
  padding: 0;
  border: 0;
  background: none;
  color: inherit;
  font: inherit;
  cursor: pointer;
}
.post-img {
  display: block;
  width: auto;
  height: var(--post-h);
}
.post-tag {
  padding: 3px 10px;
  border: 1px solid var(--line-strong);
  border-radius: 999px;
  background: var(--card);
  color: var(--ink);
  font-size: 13px;
  font-weight: 650;
  white-space: nowrap;
  transition:
    background 0.25s,
    color 0.25s,
    transform 0.3s var(--ease-spring);
}
.post:hover .post-tag {
  border-color: var(--ink);
}
.post[aria-current='step'] .post-tag {
  border-color: var(--ink);
  background: var(--ink);
  color: var(--paper);
  transform: translateY(-3px) scale(1.06);
}

.boat {
  --lean: 0deg;
  position: absolute;
  left: 0;
  bottom: calc(var(--water) - 4px);
  z-index: 2;
  width: var(--boat-w);
  aspect-ratio: 1200 / 494;
  will-change: transform;
}
.boat-img {
  display: block;
  width: 100%;
  height: auto;
  transform-origin: 50% 100%;
  /* The art faces left; the boat always sails right, bow to the post. */
  transform: scaleX(-1) rotate(var(--lean));
  transition: transform 0.45s var(--ease-out);
}

@media (prefers-reduced-motion: reduce) {
  .journey {
    --par: 0;
  }
}

/* ---- Laptop heights ---- */
@media (max-width: 1020px) {
  .panel {
    gap: 28px;
  }
}

/* ---- Phone: the panel stacks, the river keeps a boat's length between posts ---- */
@media (max-width: 760px) {
  .journey {
    --gutter: 18px;
  }
  .view {
    grid-template-rows: auto minmax(0, 1fr) 104px;
  }
  .bar {
    gap: 10px;
    padding: 10px var(--gutter);
  }
  .back {
    padding: 6px 12px;
    font-size: 13px;
  }
  .where span,
  .steps {
    display: none;
  }
  .count {
    font-size: 13px;
  }
  .panel,
  .open {
    grid-template-columns: minmax(0, 1fr);
    grid-template-rows: auto minmax(0, 1fr);
    align-items: start;
    align-content: start;
    gap: 12px;
    padding-block: 12px;
    overflow-y: auto;
  }
  .open {
    display: flex;
    flex-direction: column;
  }
  .open-copy {
    gap: 12px;
  }
  .headline {
    font-size: 31px;
  }
  .vision {
    font-size: 16.5px;
  }
  .people {
    gap: 8px 20px;
    padding-top: 10px;
  }
  .people b {
    font-size: 15px;
  }
  .people span {
    font-size: 13px;
  }
  .cue {
    display: none;
  }
  .why-plate {
    height: 180px;
  }

  .lead {
    grid-template-columns: minmax(0, 1fr) 112px;
    grid-template-areas:
      'num art'
      'name art'
      'line art';
    align-items: end;
    gap: 2px 12px;
  }
  .lead > .num {
    grid-area: num;
  }
  .lead > .area-name {
    grid-area: name;
  }
  .area-name {
    font-size: 34px;
  }
  .lead > .area-line {
    grid-area: line;
  }
  .area-line {
    font-size: 15px;
  }
  .art {
    grid-area: art;
    width: 112px;
    height: 112px;
    margin: 0;
  }
  .sheet {
    border-radius: 14px;
  }
  .sheet-body {
    gap: 10px;
    padding: 14px 16px 16px;
  }
  .body-text {
    font-size: 15px;
    line-height: 1.55;
  }
  .points li {
    font-size: 14.5px;
  }
  .claim blockquote {
    font-size: 16px;
  }

  .creed-panel .area-name {
    font-size: 32px;
  }
  .floor-text {
    font-size: 15px;
  }
  .creed {
    font-size: 24px;
  }

  .river {
    --boat-w: 84px;
    --post-h: 48px;
  }
  .post-tag {
    padding: 2px 8px;
    font-size: 12px;
  }
}
</style>
