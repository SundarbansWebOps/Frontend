<!--
  The 2023–24 council's tenure story, opened from the Legacy Board. One sideways voyage: the page
  scrolls down, the story travels right. Eight stops (the opening, five areas, the planned Startup
  Series, how the council worked) ride one track; the Legacy Board's boat sails the river below
  and docks at each area's post, always bow-first on the post's left. It stops short of the
  Startup post, because that series never launched.

  Scroll drives one number, `--p` (0 … 7, fractional while moving), set straight on the DOM each
  frame: the track, the panel parallax, the progress rail and the boat all read it. Snap markers
  turn each wheel step or swipe into one stop.
-->
<template>
  <main
    id="main-content"
    ref="mainRef"
    class="journey"
    tabindex="-1"
    :style="{ '--n': STOPS.length, '--last': LAST, '--brush': `url(${ASSET.brush})` }"
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
        <RouterLink class="back" to="/teams/legacy?year=2023">
          <span aria-hidden="true">←</span> Legacy Board
        </RouterLink>
        <p class="where">
          <b>{{ TENURE.label }}</b>
          <Transition name="swap" mode="out-in">
            <span :key="STOPS[active].key">{{ STOPS[active].label }}</span>
          </Transition>
        </p>
        <div class="rail" aria-hidden="true"><span class="rail-fill" /></div>
        <p class="count mono" aria-hidden="true">
          {{ String(active + 1).padStart(2, '0') }}<span> / {{ STOPS.length }}</span>
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
          <!-- 0 · The opening -->
          <section
            class="panel open"
            :class="panelClass(0)"
            style="--i: 0"
            :inert="active !== 0"
            aria-labelledby="open-h"
          >
            <div class="open-copy">
              <p class="kicker rise" style="--r: 0">{{ TENURE.account }}</p>
              <h1 id="open-h" class="headline rise" style="--r: 1">{{ TENURE.headline }}</h1>
              <p class="vision rise" style="--r: 2">{{ TENURE.vision }}</p>
              <ul class="people rise" style="--r: 3" aria-label="The council">
                <li v-for="person in TENURE.people" :key="person.name">
                  <b>{{ person.name }}</b>
                  <span>{{ person.role }}</span>
                </li>
              </ul>
              <button type="button" class="cue rise" style="--r: 4" @click="go(1)">
                Scroll to set sail <span aria-hidden="true">→</span>
              </button>
            </div>
            <figure class="why rise par-slow" style="--r: 2">
              <div class="why-plate">
                <img
                  class="why-forest"
                  :src="ASSET.forest800"
                  alt=""
                  width="800"
                  height="478"
                  decoding="async"
                />
                <!-- The house crest, held in the open sky between the two mangrove banks. -->
                <img class="why-crest" :src="crest" alt="" width="256" height="256" />
              </div>
              <figcaption class="why-body">
                <p class="tagline">
                  <span v-for="word in TENURE.tagline" :key="word">{{ word }}</span>
                </p>
                <p class="cap">A student arrives wanting</p>
                <ul class="wants">
                  <li v-for="want in WHY.wants" :key="want">{{ want }}</li>
                </ul>
                <p class="gap">{{ WHY.gap }}</p>
              </figcaption>
            </figure>
          </section>

          <!-- 1–5 · The five areas -->
          <section
            v-for="(stop, s) in AREA_STOPS"
            :key="stop.key"
            class="panel area"
            :class="panelClass(s + 1)"
            :style="{ '--i': s + 1 }"
            :inert="active !== s + 1"
            :aria-labelledby="`area-${stop.key}`"
          >
            <div class="lead">
              <p class="num mono rise" style="--r: 0">
                {{ String(stop.n).padStart(2, '0') }} <span>/ 05</span>
              </p>
              <h2 :id="`area-${stop.key}`" class="area-name rise par-fast" style="--r: 1">
                {{ stop.key }}
              </h2>
              <p class="area-line rise" style="--r: 2">{{ stop.line }}</p>
              <div class="art par-slow">
                <PatFigure
                  :fig="stop.fig"
                  :name="stop.figName"
                  :paint="seen.has(s + 1)"
                  :instant="reduced"
                  :live="active === s + 1"
                />
              </div>
            </div>

            <div class="sheet-col rise" style="--r: 2">
              <div v-if="stop.tabs.length > 1" class="tabs" :aria-label="`${stop.key} initiatives`">
                <button
                  v-for="tab in stop.tabs"
                  :key="tab.key"
                  type="button"
                  class="tab"
                  :class="{ hard: tab.hard }"
                  :aria-pressed="picked[stop.key] === tab.key ? 'true' : 'false'"
                  @click="picked[stop.key] = tab.key"
                >
                  {{ tab.name }}
                </button>
              </div>
              <Transition name="sheet" mode="out-in">
                <article
                  :key="picked[stop.key]"
                  class="sheet"
                  :class="{ 'is-hard': pickedTab(stop).hard }"
                  :aria-labelledby="`sheet-${stop.key}`"
                >
                  <div class="band" aria-hidden="true" />
                  <div v-if="pickedTab(stop).init" class="sheet-body">
                    <p class="sheet-name">{{ pickedTab(stop).init.name }}</p>
                    <h3 :id="`sheet-${stop.key}`" class="need">
                      {{ pickedTab(stop).init.need }}
                    </h3>
                    <div class="pair">
                      <div>
                        <h4 class="cap">The problem</h4>
                        <p>{{ pickedTab(stop).init.problem }}</p>
                      </div>
                      <div>
                        <h4 class="cap">What they built</h4>
                        <p>{{ pickedTab(stop).init.built }}</p>
                      </div>
                    </div>
                    <ul class="chips" aria-label="Highlights">
                      <li v-for="point in pickedTab(stop).init.points" :key="point">
                        {{ point }}
                      </li>
                    </ul>
                    <figure class="claim">
                      <figcaption class="cap">In the council’s words</figcaption>
                      <blockquote>{{ pickedTab(stop).init.claim }}</blockquote>
                    </figure>
                  </div>
                  <div v-else class="sheet-body">
                    <p class="sheet-name">Why it mattered</p>
                    <h3 :id="`sheet-${stop.key}`" class="need">{{ HARD_CALL.title }}</h3>
                    <p class="hard-text">{{ HARD_CALL.text }}</p>
                    <p class="moral">{{ HARD_CALL.moral }}</p>
                  </div>
                </article>
              </Transition>
            </div>
          </section>

          <!-- 6 · The Startup Series, planned -->
          <section
            class="panel startup"
            :class="panelClass(6)"
            style="--i: 6"
            :inert="active !== 6"
            aria-labelledby="startup-h"
          >
            <div class="lead">
              <p class="status rise" style="--r: 0">{{ STARTUP.status }}</p>
              <h2 id="startup-h" class="area-name rise par-fast" style="--r: 1">
                {{ STARTUP.name }}
              </h2>
              <p class="summary rise" style="--r: 2">{{ STARTUP.summary }}</p>
              <img
                class="skiff rise par-slow"
                style="--r: 3"
                :src="skiffArt"
                alt=""
                width="340"
                height="120"
                decoding="async"
              />
            </div>
            <ol class="route" aria-label="The planned route, idea to scale">
              <li
                v-for="(step, n) in STARTUP.steps"
                :key="step"
                class="rise"
                :style="{ '--r': 2 + n * 0.5 }"
              >
                <span class="route-n mono">{{ String(n + 1).padStart(2, '0') }}</span>
                {{ step }}
              </li>
            </ol>
          </section>

          <!-- 7 · How it worked -->
          <section
            class="panel creed-panel"
            :class="panelClass(7)"
            style="--i: 7"
            :inert="active !== 7"
            aria-labelledby="floor-h"
          >
            <div class="floor">
              <p class="kicker rise" style="--r: 0">How it worked</p>
              <h2 id="floor-h" class="area-name rise par-fast" style="--r: 1">
                {{ OPEN_FLOOR.title }}
              </h2>
              <p class="floor-text rise" style="--r: 2">{{ OPEN_FLOOR.text }}</p>
              <RouterLink class="home rise" style="--r: 4" to="/teams/legacy?year=2023">
                <span aria-hidden="true">←</span> Back to the Legacy Board
              </RouterLink>
            </div>
            <p class="creed par-slow">
              <span
                v-for="(line, n) in TENURE.creed"
                :key="line"
                class="rise"
                :style="{ '--r': 2 + n }"
                >{{ line }}</span
              >
            </p>
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
            :class="{ planned: post.planned }"
            :style="{ left: `${postX[k] ?? 0}px` }"
            :aria-current="active === post.stop ? 'step' : undefined"
            @click="go(post.stop)"
          >
            <img class="post-img" :src="mooringArt" alt="" width="493" height="1200" />
            <span class="post-tag">
              {{ post.label }}<span v-if="post.planned" class="visually-hidden">, planned</span>
            </span>
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
import PatFigure from '../components/site/PatFigure.vue';
import crest from '../assets/crest.webp';
import boatArt from '../assets/legacy/a-boat.webp';
import mooringArt from '../assets/legacy/a-mooring.webp';
import skiffArt from '../assets/pat/gathering-boat-l.webp';
import plateDay from '../components/lounge/home/art/plate-day-1536.webp';
import plateNight from '../components/lounge/home/art/plate-night-1536.webp';
import {
  AREAS,
  HARD_CALL,
  INITIATIVES,
  OPEN_FLOOR,
  STARTUP,
  TENURE,
  WHY,
} from '../data/tenure-2023.data.js';
import { ASSET, FIGS } from '../lib/pat.js';
import { theme as themeRef } from '../lib/theme.js';

const theme = computed(() => themeRef.value);

// Each area's painted plate: the gathering finds its people, the reader studies, the crew pulls
// together, the tiger guards, the drummers announce.
const ART = {
  Connect: 'gathering',
  Learn: 'reader',
  Career: 'rowers',
  Safety: 'tiger',
  Platform: 'drummers',
};

const AREA_STOPS = AREAS.map((a, n) => ({
  key: a.id,
  n: n + 1,
  line: a.line,
  label: a.id,
  figName: ART[a.id],
  fig: FIGS[ART[a.id]],
  tabs: [
    ...INITIATIVES.filter((x) => x.area === a.id).map((x) => ({
      key: x.id,
      name: x.name,
      init: x,
    })),
    // The tenure's hardest call belongs to Safety, told beside the system it led to.
    ...(a.id === 'Safety' ? [{ key: 'hard', name: HARD_CALL.title, hard: true }] : []),
  ],
}));

const STOPS = [
  { key: 'open', label: 'The story' },
  ...AREA_STOPS,
  { key: 'startup', label: 'What came next' },
  { key: 'floor', label: 'How it worked' },
];
const LAST = STOPS.length - 1;

// Posts on the river: one per area, then the Startup Series, apart and faint.
const POSTS = [
  ...AREA_STOPS.map((a, k) => ({ key: a.key, label: a.key, stop: k + 1 })),
  { key: 'startup', label: 'Startup', stop: 6, planned: true },
];

const picked = reactive(Object.fromEntries(AREA_STOPS.map((a) => [a.key, a.tabs[0].key])));
const pickedTab = (stop) => stop.tabs.find((t) => t.key === picked[stop.key]);

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
  const xs = Array.from({ length: 5 }, (_, k) => first + k * space);
  xs.push(xs[4] + space * 1.3);
  postX.value = xs;
  const dock = (x) => x - bw - DOCK_GAP;
  // Where the boat rests at each stop: waiting upstream, docked at an area, then halfway to the
  // Startup post and no further.
  const short = (xs[4] + xs[5]) / 2 - bw / 2;
  geo = {
    w,
    bw,
    world: xs[5] + Math.max(56, w * 0.07),
    rest: [Math.max(16, first - bw - space * 0.9), ...xs.slice(0, 5).map(dock), short, short],
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

  // The hull leans into the travel, then settles; at an area post it rests against the post.
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
  const docked = Math.abs(p - Math.round(p)) < 0.02 && active.value >= 1 && active.value <= 5;
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
  --tab-h: 0px;
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
  height: calc(100dvh - var(--nav-h) - var(--tab-h));
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

/* ---- 0 · Opening ---- */
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
  font-size: clamp(34px, 4.4vw, 64px);
  font-weight: 800;
  line-height: 1.04;
  letter-spacing: -0.025em;
  text-wrap: balance;
}
.vision {
  margin: 0;
  max-width: 54ch;
  color: var(--ink);
  font-size: clamp(17px, 1.35vw, 20px);
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
  font-size: 16px;
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
  margin: 0;
  overflow: hidden;
  border: 1.5px solid var(--line-strong);
  border-radius: 18px;
  background: var(--card);
  box-shadow: var(--shadow);
}
.why-plate {
  position: relative;
  height: clamp(120px, 22vh, 220px);
}
.why-forest {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: center 70%;
}
.why-crest {
  position: absolute;
  top: 46%;
  left: 50%;
  width: auto;
  height: clamp(56px, 52%, 108px);
  aspect-ratio: 1;
  border-radius: 50%;
  box-shadow: var(--shadow);
  translate: -50% -50%;
}
.why-body {
  display: grid;
  gap: 12px;
  padding: clamp(16px, 2.4vh, 24px) clamp(18px, 2vw, 28px) clamp(18px, 2.6vh, 28px);
}
.tagline {
  display: flex;
  gap: 0.45em;
  margin: 0 0 4px;
  font-size: clamp(20px, 1.8vw, 26px);
  font-weight: 800;
  letter-spacing: -0.01em;
}
.tagline span:nth-child(2) {
  color: var(--mari-ink);
}
.wants {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.wants li {
  padding: 5px 12px;
  border-radius: 999px;
  background: var(--sunk);
  font-size: 14.5px;
  font-weight: 600;
}
.gap {
  margin: 4px 0 0;
  font-size: 16.5px;
  line-height: 1.55;
}

/* ---- 1–5 · Areas ---- */
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
  font-size: clamp(48px, 7.4vw, 112px);
  font-weight: 850;
  line-height: 0.95;
  letter-spacing: -0.04em;
}
.area-line {
  margin: 0;
  color: var(--ink-2);
  font-size: clamp(20px, 1.8vw, 26px);
  font-weight: 600;
}
.art {
  width: min(100%, 440px);
  max-height: 34vh;
  margin-top: clamp(4px, 2vh, 20px);
}
.area:has(.rowers) .art {
  width: min(100%, 560px);
}
.art :deep(.fig) {
  max-height: 34vh;
  width: auto;
  max-width: 100%;
}

.sheet-col {
  display: grid;
  align-content: center;
  gap: 12px;
  min-width: 0;
}
.tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.tab {
  padding: 8px 16px;
  border: 1px solid var(--line-strong);
  border-radius: 999px;
  background: transparent;
  color: var(--ink);
  font: inherit;
  font-size: 15px;
  font-weight: 650;
  cursor: pointer;
  transition:
    background 0.2s,
    color 0.2s,
    border-color 0.2s,
    transform 0.2s var(--ease-out);
}
.tab:hover {
  border-color: var(--ink);
  transform: translateY(-1px);
}
.tab[aria-pressed='true'] {
  border-color: var(--ink);
  background: var(--ink);
  color: var(--paper);
}
.tab.hard[aria-pressed='false'] {
  border-style: dashed;
  border-color: var(--verm);
}

.sheet {
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
.need {
  margin: 0;
  font-size: clamp(22px, 2vw, 30px);
  font-weight: 800;
  line-height: 1.2;
  letter-spacing: -0.015em;
  text-wrap: balance;
}
.pair {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: clamp(16px, 2vw, 28px);
}
.pair p,
.hard-text {
  margin: 6px 0 0;
  font-size: 16.5px;
  line-height: 1.6;
}
.hard-text {
  margin: 0;
  max-width: 62ch;
}
.chips {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.chips li {
  padding: 4px 11px;
  border-radius: 999px;
  background: var(--sunk);
  font-size: 14px;
  font-weight: 600;
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
  font-size: 18px;
  font-weight: 750;
  line-height: 1.35;
}
.moral {
  margin: 0;
  padding: 12px 16px;
  border-left: 4px solid var(--verm);
  border-radius: 0 10px 10px 0;
  background: var(--sunk);
  font-size: 18px;
  font-weight: 750;
}

.sheet-enter-active {
  transition:
    opacity 0.3s var(--ease-out),
    transform 0.4s var(--ease-out);
}
.sheet-leave-active {
  transition:
    opacity 0.16s,
    transform 0.16s;
}
.sheet-enter-from {
  opacity: 0;
  transform: translateY(10px) rotate(0.4deg);
}
.sheet-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}

/* ---- 6 · Startup Series, planned ---- */
.status {
  justify-self: start;
  margin: 0;
  padding: 5px 12px;
  border: 1.5px dashed var(--ink-2);
  border-radius: 999px;
  color: var(--ink-2);
  font-size: 13px;
  font-weight: 750;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}
.startup .area-name {
  font-size: clamp(42px, 5.6vw, 88px);
}
.summary {
  margin: 4px 0 0;
  max-width: 44ch;
  font-size: clamp(17px, 1.35vw, 20px);
  line-height: 1.55;
}
.skiff {
  /* The cut-out faces left; it sets out the same way the boat sails. */
  scale: -1 1;
  width: clamp(150px, 16vw, 240px);
  height: auto;
  margin-top: 12px;
}
.route {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  grid-auto-flow: column;
  grid-template-rows: repeat(5, auto);
  gap: 10px clamp(14px, 2vw, 28px);
  margin: 0;
  padding: 0;
  list-style: none;
  counter-reset: none;
}
.route li {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border: 1.5px dashed var(--line-strong);
  border-radius: 14px;
  background: var(--card);
  font-size: 16.5px;
  font-weight: 650;
}
.route-n {
  color: var(--mari-ink);
  font-size: 13px;
  font-weight: 800;
}

/* ---- 7 · How it worked ---- */
.floor {
  display: grid;
  gap: 14px;
}
.creed-panel .area-name {
  font-size: clamp(40px, 5.2vw, 80px);
  text-wrap: balance;
}
.floor-text {
  margin: 0;
  max-width: 52ch;
  font-size: clamp(17px, 1.35vw, 20px);
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
  display: grid;
  gap: 6px;
  margin: 0;
  font-size: clamp(30px, 3.6vw, 56px);
  font-weight: 850;
  line-height: 1.08;
  letter-spacing: -0.03em;
}
.creed span:nth-child(2) {
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
.post.planned .post-img {
  opacity: 0.45;
}
.post.planned .post-tag {
  border-style: dashed;
  background: color-mix(in srgb, var(--card) 70%, transparent);
  color: var(--ink-2);
}
.post.planned[aria-current='step'] .post-tag {
  border-color: var(--ink-2);
  background: var(--card);
  color: var(--ink);
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
  .pair {
    grid-template-columns: minmax(0, 1fr);
    gap: 10px;
  }
}

/* ---- Phone: the panel stacks, the river keeps a boat's length between posts ---- */
@media (max-width: 760px) {
  .journey {
    --tab-h: calc(64px + env(safe-area-inset-bottom));
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
    display: none;
  }
  .why {
    border-radius: 14px;
  }
  .why-body {
    gap: 8px;
    padding: 14px 16px;
  }
  .tagline {
    font-size: 19px;
  }
  .wants li {
    font-size: 13.5px;
  }
  .gap {
    font-size: 15.5px;
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
  .lead > .num,
  .lead > .status {
    grid-area: num;
  }
  .lead > .area-name {
    grid-area: name;
  }
  .area-name {
    font-size: 42px;
  }
  .lead > .area-line,
  .lead > .summary {
    grid-area: line;
  }
  .area-line {
    font-size: 17px;
  }
  .art {
    grid-area: art;
    width: 112px;
    max-height: 84px;
    margin: 0;
  }
  .art :deep(.fig) {
    max-height: 84px;
  }
  .tab {
    padding: 7px 13px;
    font-size: 14px;
  }
  .sheet {
    border-radius: 14px;
  }
  .sheet-body {
    gap: 10px;
    padding: 14px 16px 16px;
  }
  .need {
    font-size: 19px;
  }
  .pair p,
  .hard-text {
    font-size: 15.5px;
    line-height: 1.55;
  }
  .chips {
    display: none;
  }
  .claim blockquote,
  .moral {
    font-size: 16px;
  }

  .startup .lead {
    grid-template-areas:
      'num num'
      'name name'
      'line line';
  }
  .startup .area-name {
    font-size: 38px;
  }
  .summary {
    font-size: 16px;
  }
  .skiff {
    display: none;
  }
  .route {
    gap: 6px 8px;
  }
  .route li {
    gap: 8px;
    padding: 8px 10px;
    font-size: 14px;
  }
  .creed-panel .area-name {
    font-size: 36px;
  }
  .floor-text {
    font-size: 16px;
  }
  .creed {
    font-size: 28px;
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
