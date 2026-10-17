<!--
  Legacy Board (concept A, Five Landings). A tall scroll track holds one viewport that sticks
  under the nav, with two arched leaders, a two-row member deck and a river of five years. Scrolling
  moves through the years, 2021 at the top. Scroll drives one number, the year position, and
  the boat slides between the docks either side of it, turning to face the way it sails, leaning
  into the travel and settling at a post. The council and the year on the water ride with the boat: as it leaves a post they
  slide back against its course and fade, and the next year's slide in from ahead of it as it
  docks (a plain swap under reduced motion or in a hidden tab). When the scroll settles the URL
  follows with `?year=N` (2021 has no query).
  Wheel notches, arrow and page keys, a stage swipe and a post click each step one year; touch
  keeps native scrolling and lands on the snap markers. Water never animates.
  The public TopNav and theme stay; this page adds no second theme system.
-->
<template>
  <main id="main-content" ref="mainRef" class="board" tabindex="-1" :style="boardStyle">
    <i
      v-for="(year, i) in YEARS"
      :key="`snap-${year}`"
      class="snap"
      :style="{ top: `calc(${i} * var(--stride))` }"
      aria-hidden="true"
    />

    <div ref="viewRef" class="view">
      <header class="top rise" style="--i: 0">
        <div class="title">
          <p class="kicker">Since {{ FOUNDED }}</p>
          <h1>Legacy Board</h1>
        </div>
        <div class="actions">
          <Transition name="story">
            <RouterLink v-if="readMore" :key="readMore.to" class="story-link" :to="readMore.to">
              Read more about {{ readMore.label }}
              <span aria-hidden="true">→</span>
            </RouterLink>
          </Transition>
          <RouterLink class="back" :to="{ path: '/house', hash: '#legacy' }"
            >Back to House</RouterLink
          >
        </div>
      </header>

      <nav ref="riverRef" class="river" :style="riverStyle" aria-label="Years">
        <p ref="yearRef" class="year-mark" :class="[phase, { hold }]" aria-hidden="true">
          <span
            v-for="(d, k) in String(shownYear)"
            :key="k"
            :class="k === boatGap && (dockRight ? 'dodge-r' : 'dodge-l')"
            :style="{ '--k': k }"
            >{{ d }}</span
          >
        </p>
        <button
          v-for="(year, i) in YEARS"
          :key="year"
          :ref="(el) => bindPost(el, i)"
          type="button"
          class="post"
          :class="{ 'has-art': postArt[i] }"
          :style="{ '--i': i }"
          :aria-pressed="current === year ? 'true' : 'false'"
          :aria-current="current === year ? 'true' : undefined"
          @click="go(i)"
        >
          <span class="stake" aria-hidden="true" />
          <img class="post-img" :src="mooringArt" alt="" decoding="async" @load="markPost(i)" />
          <span class="post-tag">{{ year }}</span>
        </button>
        <div
          ref="boatRef"
          class="boat"
          :class="{ 'sailing-back': sailingBack, ready: boatReady }"
          aria-hidden="true"
        >
          <img class="boat-img" :src="boatArt" alt="" width="1200" height="494" decoding="async" />
        </div>
      </nav>

      <section
        class="stage"
        aria-labelledby="council-h"
        @pointerdown="onPointerDown"
        @pointerup="onPointerUp"
        @pointercancel="onPointerCancel"
      >
        <div ref="councilRef" class="council" :class="[phase, { hold }]">
          <h2 id="council-h" class="visually-hidden">Council {{ shownYear }}</h2>
          <p class="visually-hidden" aria-live="polite">{{ liveText }}</p>
          <div v-if="council" class="leaders">
            <div
              v-for="(person, k) in leaders"
              :key="person.key"
              class="leader arrive"
              :class="k === 0 ? 'is-secretary' : 'is-deputy'"
              :style="{ '--i': k }"
            >
              <div class="arch" :class="{ 'has-art': archReady[person.key] }">
                <div class="slot">
                  <div class="frame">
                    <img v-if="person.photo" :src="person.photo" :alt="person.name" />
                  </div>
                </div>
                <img
                  class="arch-art"
                  :src="archFrame"
                  alt=""
                  decoding="async"
                  @load="markArch(person.key)"
                />
              </div>
              <div class="leader-text">
                <p class="name">{{ person.name }}</p>
                <p class="role">{{ person.role }}</p>
              </div>
            </div>
          </div>
          <div v-if="teamRows.length" class="deck arrive" style="--i: 2">
            <div v-for="(row, ri) in teamRows" :key="ri" class="deck-row">
              <div
                v-for="(member, mi) in row"
                :key="member.id"
                class="member"
                :style="{ '--i': seatDelay(ri, mi) }"
              >
                <div class="frame">
                  <img
                    v-if="member.photo"
                    :src="member.photo"
                    :alt="`Portrait of ${member.name}`"
                  />
                </div>
                <div class="member-cap">
                  <p class="member-name">{{ member.name }}</p>
                  <p class="member-role">{{ member.role }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  </main>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import archFrame from '../assets/legacy/a-arch-frame.webp';
import boatArt from '../assets/legacy/a-boat.webp';
import mooringArt from '../assets/legacy/a-mooring.webp';
import crest from '../assets/crest.webp';
import plateDay from '../components/lounge/home/art/plate-day-1536.webp';
import plateNight from '../components/lounge/home/art/plate-night-1536.webp';
import { FOUNDED, LEGACY } from '../data/legacy.data.js';
import { STORIES } from '../data/council-stories.data.js';
import { TENURE } from '../data/tenure-2023.data.js';
import { theme } from '../lib/theme.js';

const YEARS = LEGACY.map((d) => d.year);
const LAST = YEARS.length - 1;
// Share of a year's travel the boat must go the other way before it turns. Smaller moves are jitter.
const TURN_AT = 0.02;
// The first year is the top of the track, so it is the canonical URL with no query.
const DEFAULT_YEAR = YEARS[0];
// Scroll distance per year, as a share of the viewport height.
const STEP_VH = 0.8;
// Scroll quiet this long means the boat has docked and the URL follows.
const IDLE_MS = 140;
// Share of a year's travel after which the council has faded out entirely. Below one half, so
// the swap at the halfway point is never seen.
const FADE_AT = 0.42;
const KEY_STEP = new Map([
  ['ArrowLeft', -1],
  ['ArrowUp', -1],
  ['PageUp', -1],
  ['ArrowRight', 1],
  ['ArrowDown', 1],
  ['PageDown', 1],
]);

const route = useRoute();
const router = useRouter();

const boardStyle = { '--crest': `url("${crest}")`, '--last': LAST };
const riverStyle = computed(() => ({
  backgroundImage: `url("${theme.value === 'dark' ? plateNight : plateDay}")`,
}));

const reduceQuery = matchMedia('(prefers-reduced-motion: reduce)');
// No smooth scrolling, no lean and no animated swap while the reader cannot see them.
const motionOff = () => reduceQuery.matches || document.hidden;

function queryValue(value) {
  return Array.isArray(value) ? value[0] : value;
}

function parsedYear() {
  const v = queryValue(route.query.year);
  if (v == null || v === '') return DEFAULT_YEAR;
  const n = Number(v);
  return YEARS.includes(n) ? n : DEFAULT_YEAR;
}

// The URL is canonical when it carries exactly what this year needs: no query for the first
// year (the top of the board), `?year=N` for any other.
function queryRepresents(year) {
  const raw = route.query.year;
  return year === DEFAULT_YEAR ? raw === undefined : raw === String(year);
}

const council = computed(() => LEGACY.find((d) => d.year === shownYear.value) ?? null);
const teamMax = computed(() => {
  const max = council.value?.team.length ?? 10;
  const n = Number.parseInt(queryValue(route.query.team) ?? '', 10);
  if (Number.isNaN(n)) return max;
  return Math.min(max, Math.max(0, n));
});

const shownYear = ref(parsedYear());

// Years with a story page get a Read more link on the board.
const STORY_PAGES = new Map([
  [TENURE.year, { to: '/teams/legacy/2023-24', label: TENURE.label }],
  ...Object.values(STORIES).map((s) => [
    Number(s.key.slice(0, 4)),
    { to: `/teams/legacy/${s.key}`, label: s.label },
  ]),
]);
const readMore = computed(() => STORY_PAGES.get(shownYear.value) ?? null);
// Index of the year the scroll position asks for, and the year nearest the boat (which drives
// the post highlight). `goal` is the last year asked for by a click, key or wheel notch, so
// repeated steps stack on it even while a smooth scroll is still arriving.
let wanted = YEARS.indexOf(shownYear.value);
let goal = wanted;
const current = ref(shownYear.value);
let settledYear = shownYear.value;
const phase = ref(motionOff() ? '' : 'pre');
const boatReady = ref(false);
const dockRight = ref(false);
// The boat's facing: bow right while sailing forward (toward later years), bow left while sailing
// back. Set by faceTravel() from the scroll, and once on load for a boat docked right of a post.
const sailingBack = ref(false);
const hold = ref(false);
const postArt = reactive(YEARS.map(() => false));
const archReady = reactive({ secretary: false, deputy: false });

// The gap the docked boat sits in (left of its post, or right of the first one): that gap's
// year digit steps aside into the open water so the boat never hides it.
const boatGap = computed(() => YEARS.indexOf(shownYear.value) - (dockRight.value ? 0 : 1));
const leaders = computed(() => {
  const c = council.value;
  if (!c) return [];
  return [
    { key: 'secretary', ...c.secretary },
    { key: 'deputy', ...c.deputy },
  ];
});
const teamRows = computed(() => {
  const members = council.value?.team.slice(0, teamMax.value) ?? [];
  if (!members.length) return [];
  const cut = Math.ceil(members.length / 2);
  return [members.slice(0, cut), members.slice(cut)].filter((row) => row.length);
});
const liveText = computed(() => {
  const c = council.value;
  if (!c) return '';
  const leaders = [c.secretary, c.deputy]
    .filter((person) => person.name)
    .map((person) => `${person.name}, ${person.role}`);
  return `Council ${c.year}. ${leaders.join('. ')}.`;
});

function seatDelay(rowIndex, index) {
  let seat = index;
  for (let r = 0; r < rowIndex; r++) seat += teamRows.value[r].length;
  return (2 + seat * 0.3).toFixed(2);
}

const mainRef = ref(null);
const viewRef = ref(null);
const riverRef = ref(null);
const boatRef = ref(null);
const councilRef = ref(null);
const yearRef = ref(null);
const postRefs = [];

function bindPost(el, i) {
  postRefs[i] = el ?? null;
}

function markArch(key) {
  archReady[key] = true;
}

function markPost(i) {
  if (postArt[i]) return;
  postArt[i] = true;
  nextTick(() => {
    if (measure()) paint();
  });
}

function adoptLoadedArt() {
  postRefs.forEach((post, i) => {
    const img = post?.querySelector('.post-img');
    if (img?.complete && img.naturalWidth) postArt[i] = true;
  });
  councilRef.value?.querySelectorAll('.arch').forEach((arch) => {
    const img = arch.querySelector('.arch-art');
    const key = arch.closest('.leader')?.classList.contains('is-deputy') ? 'deputy' : 'secretary';
    if (img?.complete && img.naturalWidth) archReady[key] = true;
  });
}

// Geometry in px. `step` is the scroll distance per year; `viewTop` is where the sticky view
// rests (under the nav); `dock[i]` is where the boat sits beside post i, on its left. The first
// post on a narrow screen has no room on the left, so the boat sits on its right instead.
let step = 0;
let viewTop = 0;
let dock = null;

function measure() {
  const main = mainRef.value;
  const river = riverRef.value;
  const boat = boatRef.value;
  const view = viewRef.value;
  if (!main || !river || !boat || !view || river.clientWidth === 0) return false;
  step = Math.round(innerHeight * STEP_VH);
  main.style.setProperty('--stride', `${step}px`);
  viewTop = parseFloat(getComputedStyle(view).top) || 0;

  const rr = river.getBoundingClientRect();
  const bw = boat.offsetWidth;
  const gap = 2;
  dock = postRefs.map((post, i) => {
    const stem = (
      postArt[i] ? post.querySelector('.post-img') : post.querySelector('.stake')
    ).getBoundingClientRect();
    const centre = stem.left - rr.left + stem.width / 2;
    let x = centre - stem.width / 2 - gap - bw;
    const right = x < 4;
    if (right) x = centre + stem.width / 2 + gap;
    return { x, right };
  });
  return true;
}

// Document scroll position at which year i rests: the sticky view stuck under the nav.
function yearTop(i) {
  return scrollY + mainRef.value.getBoundingClientRect().top - viewTop + i * step;
}

// Used when the council should change without motion. The council's transitions are held off
// until the next frame so the end state is not animated, even when a transition was already in
// flight. Two frames pass before the hold lifts, so the snap style is computed first and lifting
// it never starts a transition.
let holdFrame = 0;
function holdStill() {
  hold.value = true;
  cancelAnimationFrame(holdFrame);
  holdFrame = requestAnimationFrame(() => {
    holdFrame = requestAnimationFrame(() => {
      hold.value = false;
    });
  });
}

function swapNow() {
  holdStill();
  shownYear.value = YEARS[wanted];
  phase.value = '';
}

// `d` is the boat's distance from the shown year's post, in years (−0.5…0.5). The council and the
// year on the water slide against the boat's course by it and fade with smoothstep, so they are
// gone well before the swap at the halfway point.
function drift(d) {
  const t = Math.min(1, Math.abs(d) / FADE_AT);
  const seen = (1 - t * t * (3 - 2 * t)).toFixed(3);
  for (const el of [councilRef.value, yearRef.value]) {
    el?.style.setProperty('--drift', d.toFixed(4));
    el?.style.setProperty('--seen', seen);
  }
}

let frame = 0;
let p = 0;
let lastP = 0;
let runP = 0;
let settleTimer = 0;

// The CSS --lean sits inside the boat's facing, and a flipped facing (scaleX(-1)) mirrors a
// rotation. `visual` is the tilt the reader sees, in degrees clockwise: positive tips the top
// toward the right. Sailing forward is the flipped facing, so its CSS value is the negative.
function leanFor(visual) {
  return sailingBack.value ? visual : -visual;
}

// The facing follows the travel. `runP` is the furthest the boat has gone the way it faces; it
// turns only after coming back TURN_AT from that point, so jitter at rest never flips it.
function faceTravel() {
  const back = sailingBack.value;
  if (back ? p < runP : p > runP) runP = p;
  else if (Math.abs(p - runP) >= TURN_AT) {
    sailingBack.value = !back;
    runP = p;
  }
}

function onScroll() {
  if (!frame) frame = requestAnimationFrame(paint);
}

// One frame of scroll: place the boat between the docks, turn it to face its travel, lean it, and
// show the year the boat is nearest, drifted by how far the boat is from its post.
function paint() {
  frame = 0;
  const main = mainRef.value;
  if (!main || !dock) return;
  p = Math.min(LAST, Math.max(0, (viewTop - main.getBoundingClientRect().top) / step));

  const a = Math.floor(p);
  const b = Math.min(LAST, a + 1);
  const x = dock[a].x + (dock[b].x - dock[a].x) * (p - a);
  const boat = boatRef.value;
  boat.style.transform = `translate3d(${x.toFixed(2)}px,0,0)`;

  const v = p - lastP;
  lastP = p;
  faceTravel();
  // Leaning into the travel: the top tips the way the boat is moving, whichever way that is.
  const lean = motionOff() ? 0 : leanFor(Math.max(-4, Math.min(4, v * 90)));
  boat.style.setProperty('--lean', `${lean.toFixed(2)}deg`);

  const near = Math.round(p);
  dockRight.value = dock[near].right;
  current.value = YEARS[near];
  wanted = near;
  if (motionOff()) {
    if (YEARS[near] !== shownYear.value) swapNow();
    drift(0);
  } else {
    // Swapped at the halfway point, where both years have faded right out.
    shownYear.value = YEARS[near];
    drift(p - near);
  }

  clearTimeout(settleTimer);
  settleTimer = setTimeout(settle, IDLE_MS);
}

// The scroll has stopped: the boat is docked at a post (the snap markers see to that), so the URL
// records its year.
function settle() {
  settleTimer = 0;
  const near = Math.round(p);
  const docked = Math.abs(p - near) < 0.02 && !motionOff();
  boatRef.value?.style.setProperty('--lean', docked ? `${leanFor(-2)}deg` : '0deg');
  goal = near;
  settledYear = YEARS[near];
  syncUrl(settledYear);
}

function onResize() {
  cancelAnimationFrame(resizeFrame);
  resizeFrame = requestAnimationFrame(() => {
    if (!measure()) return;
    // A new step moves every year's rest point: keep the chosen year in view. Never re-anchor
    // in the middle of a scroll, because mobile toolbars resize the viewport while scrolling.
    if (settleTimer) paint();
    else {
      go(goal, { instant: true });
      paint();
    }
  });
}
let resizeFrame = 0;

// While a replace is in flight the route still shows the old year, so a newer choice must
// always navigate; vue-router cancels the older pending one and the latest choice wins.
let replacing = 0;
function syncUrl(year) {
  if (!replacing && queryRepresents(year)) return;
  const query = { ...route.query };
  if (year === DEFAULT_YEAR) delete query.year;
  else query.year = String(year);
  replacing += 1;
  router
    .replace({ query })
    .catch(() => {})
    .finally(() => {
      replacing -= 1;
    });
}

// Scroll to a year. Smooth unless reduced motion or a hidden tab; `instant` is for deep links.
function go(i, { instant = false } = {}) {
  goal = Math.min(LAST, Math.max(0, i));
  window.scrollTo({ top: yearTop(goal), behavior: instant || motionOff() ? 'auto' : 'smooth' });
}

function stepBy(d) {
  const next = goal + d;
  if (next < 0 || next > LAST) return false;
  go(next);
  return true;
}

function onKey(e) {
  const d = KEY_STEP.get(e.key);
  if (d === undefined || e.defaultPrevented || e.altKey || e.ctrlKey || e.metaKey || e.shiftKey) {
    return;
  }
  // Only when nothing else owns the keys: the page itself, or the board's posts, stage and links.
  const t = e.target;
  const free = t === document.body || t === document.documentElement || !!t?.closest?.('.board');
  if (!free) return;
  if (stepBy(d)) e.preventDefault();
}

let startX = null;
let startY = 0;

function onPointerDown(e) {
  if (e.pointerType === 'mouse') return;
  startX = e.clientX;
  startY = e.clientY;
  e.currentTarget.setPointerCapture?.(e.pointerId);
}

function onPointerUp(e) {
  if (startX === null) return;
  const dx = e.clientX - startX;
  const dy = e.clientY - startY;
  startX = null;
  if (Math.abs(dx) > 48 && Math.abs(dx) > Math.abs(dy) * 1.5) stepBy(dx < 0 ? 1 : -1);
}

function onPointerCancel() {
  startX = null;
}

// Wheels and trackpads: one notch, or one swipe however long its glide, moves one year. Sideways
// swipes count too. Touch keeps native scrolling and lands on the snap markers.
let wheelSum = 0;
let wheelAt = 0;
let lockUntil = 0;
function onWheel(e) {
  if (e.ctrlKey) return;
  // A stage that scrolls itself (short landscape phones) keeps its own wheel.
  const stage = e.target?.closest?.('.stage');
  if (stage && stage.scrollHeight > stage.clientHeight) return;
  const d = Math.abs(e.deltaX) > Math.abs(e.deltaY) ? e.deltaX : e.deltaY;
  const dir = Math.sign(d);
  if (!dir || (dir < 0 && p <= 0) || (dir > 0 && p >= LAST)) return;
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
  stepBy(dir);
}

// Reduced motion or a hidden tab: no animated swap and no lean. Visible again: re-measure.
function onMotionChange() {
  if (motionOff()) {
    if (YEARS[wanted] !== shownYear.value) swapNow();
    boatRef.value?.style.setProperty('--lean', '0deg');
  } else if (measure()) {
    paint();
  }
}

watch(
  () => route.query.year,
  () => {
    const year = parsedYear();
    // Our own replace lands here too. Only an outside change while at rest moves the board.
    if (year === settledYear || settleTimer) return;
    go(YEARS.indexOf(year), { instant: true });
  }
);

function landOn(i) {
  go(i, { instant: true });
  paint();
}

// Retries until the river has a width, then jumps (no animation) to the year in the URL.
let landTimer = 0;
function mountAt(attempt = 0) {
  if (!measure()) {
    if (attempt < 8) requestAnimationFrame(() => mountAt(attempt + 1));
    return;
  }
  const target = wanted;
  boatReady.value = true;
  landOn(target);
  // Docked right of the first post, the boat starts with its bow toward the post.
  if (dockRight.value) sailingBack.value = true;
  if (phase.value === 'pre' && councilRef.value) void councilRef.value.offsetWidth;
  phase.value = '';
  settledYear = YEARS[target];
  syncUrl(settledYear);
  // vue-router scrolls to the top once a page has mounted (its scrollBehavior runs in microtasks
  // after the render), which would undo the jump above. Land on the same year again once that has
  // run; the target is fixed here because a frame may already have read the top as year 2021.
  landTimer = setTimeout(() => {
    landTimer = 0;
    landOn(target);
  }, 0);
}

let resizeObs = null;
onMounted(async () => {
  // Touch swipes land on one year. Only this page snaps, so the setting leaves with it.
  document.documentElement.style.scrollSnapType = 'y mandatory';
  window.addEventListener('scroll', onScroll, { passive: true });
  window.addEventListener('resize', onResize);
  window.addEventListener('wheel', onWheel, { passive: false });
  document.addEventListener('keydown', onKey);
  document.addEventListener('visibilitychange', onMotionChange);
  reduceQuery.addEventListener('change', onMotionChange);
  adoptLoadedArt();
  await nextTick();
  resizeObs = new ResizeObserver(onResize);
  resizeObs.observe(riverRef.value);
  mountAt();
});

onBeforeUnmount(() => {
  document.documentElement.style.scrollSnapType = '';
  clearTimeout(settleTimer);
  clearTimeout(landTimer);
  cancelAnimationFrame(frame);
  cancelAnimationFrame(resizeFrame);
  cancelAnimationFrame(holdFrame);
  window.removeEventListener('scroll', onScroll);
  window.removeEventListener('resize', onResize);
  window.removeEventListener('wheel', onWheel);
  document.removeEventListener('keydown', onKey);
  document.removeEventListener('visibilitychange', onMotionChange);
  reduceQuery.removeEventListener('change', onMotionChange);
  resizeObs?.disconnect();
});
</script>

<style scoped>
/* Tuned slot from the approved board. The webp's clear aperture measures
   13.9% 16.5% 12% 16.5%; 14% 20% 15% 20% is the inset that keeps the
   placeholder inside the arch the way the prototype does. */

/* The scroll track: one viewport plus a stride for each year after the first. Only the sticky
   view inside it is painted; the track is what the scrollbar measures. */
.board {
  --edge: 15%;
  --step: 20%;
  --water: 12%;
  --slot-inset: 14% 20% 15% 20%;
  --arch-h: clamp(230px, 44vh, 440px);
  --m-w: clamp(96px, 7.4vw, 108px);
  --post-h: clamp(48px, 11vh, 100px);
  --boat-w: clamp(104px, 12.2vw, 176px);
  --tab-h: 0px;
  --stride: 80vh;
  /* How far a whole year's travel pans the council, against the boat's course. */
  --pan: calc(-1 * clamp(80px, 14vw, 200px));
  position: relative;
  height: calc(100dvh - var(--nav-h) + var(--last) * var(--stride));
  background: var(--paper);
  color: var(--ink);
}
.board:focus {
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
  grid-template-rows: auto minmax(0, 1fr) minmax(96px, 20vh);
  grid-template-areas: 'top' 'stage' 'river';
  overflow: hidden;
  background: var(--paper);
}

.top {
  grid-area: top;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: clamp(8px, 1.4vh, 16px) clamp(16px, 3vw, 44px) clamp(2px, 0.6vh, 8px);
}
.title {
  display: grid;
  gap: 2px;
  min-width: 0;
}
.kicker {
  margin: 0;
  font-size: 11px;
  font-weight: 650;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--ink-3);
}
h1 {
  margin: 0;
  font-size: clamp(26px, 3.2vw, 40px);
  font-weight: 750;
  letter-spacing: -0.03em;
  line-height: 1;
}
.back {
  flex: none;
  font-size: 13px;
  font-weight: 650;
  color: var(--ink-2);
  text-decoration: none;
}
.back:hover {
  color: var(--ink);
}
.actions {
  display: flex;
  align-items: center;
  gap: clamp(12px, 2vw, 24px);
  min-width: 0;
}
/* Shown only while the 2023 council is on the board. */
.story-link {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  border-radius: 99px;
  background: var(--mari);
  color: var(--on-mari);
  font-size: 13px;
  font-weight: 700;
  text-decoration: none;
  white-space: nowrap;
  box-shadow: var(--shadow);
  transition: transform 0.25s var(--ease-out);
}
.story-link:hover {
  transform: translateY(-1px);
}
.story-link span {
  transition: transform 0.25s var(--ease-out);
}
.story-link:hover span {
  transform: translateX(3px);
}
.story-enter-active {
  transition:
    opacity 0.4s var(--ease-out) 0.5s,
    transform 0.4s var(--ease-out) 0.5s;
}
.story-leave-active {
  transition: opacity 0.18s var(--ease-out);
}
.story-enter-from {
  opacity: 0;
  transform: translateY(6px);
}
.story-leave-to {
  opacity: 0;
}

.river {
  grid-area: river;
  position: relative;
  min-height: 0;
  overflow: hidden;
  background-color: var(--sunk);
  background-position: center 40%;
  background-size: cover;
  background-repeat: no-repeat;
  border-top: 1.5px solid var(--line-strong);
}
/* The year on show, written across the water, one digit between each pair of posts. It fades
   out and back with the council (the same phase classes). */
.year-mark {
  --ym: 0.55;
  position: absolute;
  inset: 0;
  margin: 0;
  container-type: size;
  pointer-events: none;
  user-select: none;
  color: var(--paper);
  opacity: var(--ym);
  transition: opacity 0.5s var(--ease-out);
}
:root[data-theme='dark'] .year-mark {
  --ym: 0.3;
  color: var(--ink);
}
.year-mark.pre {
  opacity: 0;
  transition: none;
}
.year-mark.hold {
  transition: none;
}
.year-mark span {
  position: absolute;
  bottom: 4%;
  left: calc(var(--edge) + (var(--k) + 0.5) * var(--step));
  transform: translateX(-50%);
  font-size: 92cqh;
  font-weight: 750;
  line-height: 0.8;
  font-variant-numeric: tabular-nums;
  /* Rides with the boat (drift() in the script); half the council's pan. */
  translate: calc(var(--drift, 0) * var(--pan) * 0.5) 0;
  opacity: var(--seen, 1);
}
/* Centred in the water the boat leaves open, but never closer to the post than half a digit
   (about 24cqh) plus half a stake, and never past the gap's middle. */
.year-mark .dodge-l,
.year-mark .dodge-r {
  --open: clamp(24.5cqh + 12px, (var(--step) - var(--boat-w)) / 2, var(--step) / 2);
}
.year-mark .dodge-l {
  left: calc(var(--edge) + var(--k) * var(--step) + var(--open));
}
.year-mark .dodge-r {
  left: calc(var(--edge) + (var(--k) + 1) * var(--step) - var(--open));
}
.post {
  position: absolute;
  bottom: var(--water);
  left: calc(var(--edge) + var(--i) * var(--step));
  z-index: 1;
  transform: translateX(-50%);
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
  display: none;
  width: auto;
  height: var(--post-h);
}
.stake {
  display: block;
  width: 8px;
  height: var(--post-h);
  border-radius: 3px 3px 0 0;
  background: linear-gradient(90deg, var(--ink-2), var(--ink));
}
.post.has-art .post-img {
  display: block;
}
.post.has-art .stake {
  display: none;
}
.post-tag {
  padding: 2px 7px;
  border: 1px solid transparent;
  border-radius: 999px;
  background: color-mix(in srgb, var(--card) 55%, transparent);
  color: var(--ink-2);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.04em;
  line-height: 1.5;
  font-variant-numeric: tabular-nums;
}
.post:hover .post-tag {
  color: var(--ink);
  border-color: var(--line-strong);
}
.post[aria-current='true'] .post-tag {
  padding: 4px 12px;
  border-color: var(--ink);
  background: var(--ink);
  color: var(--paper);
  font-size: 14px;
  font-weight: 750;
}

/* The boat's x is set on the scroll frame (no transition: it follows the scroll). Its facing is
   the way it sails: bow right by default, bow left while .sailing-back is set. Its hull leans
   with --lean, a transform on the image only. */
.boat {
  --face: scaleX(-1);
  --lean: 0deg;
  position: absolute;
  left: 0;
  bottom: var(--water);
  z-index: 2;
  width: var(--boat-w);
  aspect-ratio: 1200 / 494;
  opacity: 0;
  will-change: transform;
}
.boat.ready {
  opacity: 1;
}
.boat.sailing-back {
  --face: scaleX(1);
}
.boat-img {
  display: block;
  width: 100%;
  height: auto;
  transform-origin: 50% 100%;
  transform: var(--face) rotate(var(--lean));
  transition: transform 0.32s var(--ease-out);
}

.stage {
  grid-area: stage;
  position: relative;
  min-height: 0;
  overflow: hidden;
}
.council {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: clamp(32px, 4vw, 64px);
  padding: clamp(6px, 1.6vh, 18px) clamp(16px, 3vw, 48px) clamp(10px, 2vh, 24px);
  opacity: var(--seen, 1);
}
.leaders {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: flex-end;
  gap: clamp(28px, 3.4vw, 52px);
  min-width: 0;
}
.leader {
  display: grid;
  justify-items: center;
  gap: clamp(8px, 1.4vh, 14px);
}
.arch {
  position: relative;
  height: var(--arch-h);
  aspect-ratio: 0.75;
  border: 1.5px solid var(--line-strong);
  border-radius: 999px 999px 10px 10px;
  background: var(--sunk);
  box-shadow: var(--shadow);
}
.arch.has-art {
  border-color: transparent;
  background: none;
  box-shadow: none;
  border-radius: 0;
}
.slot {
  position: absolute;
  z-index: 1;
  inset: var(--slot-inset);
  overflow: hidden;
  border-radius: 999px 999px 6px 6px;
}
.slot .frame {
  width: 100%;
  height: 100%;
  border: 0;
  border-radius: inherit;
  box-shadow: none;
  background: var(--sunk);
}
.arch-art {
  position: absolute;
  inset: 0;
  z-index: 2;
  width: 100%;
  height: 100%;
  object-fit: fill;
  pointer-events: none;
}
.leader-text {
  display: grid;
  justify-items: center;
  gap: 4px;
  min-width: 0;
  text-align: center;
}
.name {
  margin: 0;
  max-width: 20ch;
  font-size: clamp(18px, 2.5vh, 26px);
  font-weight: 650;
  letter-spacing: -0.01em;
  line-height: 1.15;
  text-wrap: balance;
}
.role {
  margin: 0;
  font-size: 11px;
  font-weight: 650;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--ink-3);
}
.is-secretary .role {
  color: var(--mari-ink);
}

.deck {
  position: relative;
  z-index: 1;
  align-self: center;
  display: grid;
  gap: clamp(14px, 2.2vh, 22px);
  min-width: 0;
  max-width: 100%;
}
.deck-row {
  position: relative;
  display: flex;
  justify-content: center;
  gap: clamp(12px, 1.4vw, 18px);
}
.member {
  display: grid;
  justify-items: center;
  gap: 6px;
  width: var(--m-w);
  transition: opacity 0.42s var(--ease-out);
  transition-delay: calc(var(--i, 0) * 45ms);
}
.frame {
  position: relative;
  display: grid;
  place-items: center;
  overflow: hidden;
  background: var(--card);
  border: 1.5px solid var(--line-strong);
  border-radius: 8px;
}
/* Each member sits under a small arch, echoing the leaders' painted doors. */
.member .frame {
  width: 100%;
  aspect-ratio: 4 / 5;
  border: 2px solid var(--mari);
  border-radius: 999px 999px 10px 10px;
  box-shadow:
    0 0 0 3px var(--paper),
    0 0 0 4px var(--line-strong),
    var(--shadow);
}
.frame::before {
  content: '';
  position: absolute;
  inset: 22%;
  background: var(--crest) center / contain no-repeat;
  opacity: 0.22;
}
.frame img {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.frame:has(img)::before {
  display: none;
}
.member-cap {
  display: grid;
  justify-items: center;
  gap: 3px;
  margin: 0;
  line-height: 1.2;
  text-align: center;
}
.member-name {
  margin: 0;
  font-size: 12.5px;
  font-weight: 700;
  letter-spacing: 0;
  text-wrap: balance;
}
.member-role {
  margin: 0;
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--ink-2);
}

/* First arrival. `rise` is the site entrance; this stagger is its own class. Year changes ride
   with the boat instead: drift() sets --drift and --seen every scroll frame, so `translate` is
   never transitioned; the deck sits a little deeper and pans a little further. */
.arrive {
  translate: calc(var(--drift, 0) * var(--pan) * var(--z, 1)) 0;
  transition:
    opacity 0.5s var(--ease-out),
    transform 0.6s var(--ease-out);
  transition-delay: calc(var(--i, 0) * 60ms);
}
.leader.is-deputy {
  --z: 1.08;
}
.deck {
  --z: 1.2;
}
.council.pre .arrive {
  opacity: 0;
  transform: translateY(12px);
  transition: none;
}
.council.pre .member {
  opacity: 0;
  transition: none;
}
.council.hold .arrive,
.council.hold .member {
  transition: none;
}

/* No lean and no motion: the boat still turns to face its travel, but at once. */
@media (prefers-reduced-motion: reduce) {
  .boat-img {
    transition: none;
  }
}

@media (min-width: 761px) and (max-width: 1020px) {
  .board {
    --arch-h: min(44vh, 24vw);
    --m-w: 84px;
  }
  .council {
    gap: 32px;
  }
}

@media (max-width: 760px) {
  .board {
    --tab-h: calc(64px + env(safe-area-inset-bottom));
    --edge: 8%;
    --step: 21%;
    --water: 10%;
    --m-w: min(64px, calc((100vw - 88px) / 5), 7.6vh);
    --post-h: clamp(36px, 6vh, 52px);
    --boat-w: min(52px, 13vw);
  }
  .view {
    grid-template-rows: auto minmax(64px, 12vh) minmax(0, 1fr);
    grid-template-areas: 'top' 'river' 'stage';
  }
  .top {
    padding-top: 10px;
  }
  .story-link {
    padding: 6px 12px;
    font-size: 12px;
  }
  .actions:has(.story-link) .back {
    display: none;
  }
  .council {
    flex-direction: column;
    gap: 10px;
    padding: 8px 14px 12px;
  }
  .post-tag {
    padding: 1px 6px;
    font-size: 10px;
  }
  .post[aria-current='true'] .post-tag {
    padding: 2px 9px;
    font-size: 12px;
  }
  .leaders {
    gap: 14px;
  }
  .leader {
    width: min(36vw, 148px, 18vh);
  }
  .arch {
    width: 100%;
    height: auto;
  }
  .deck {
    gap: 10px;
  }
  .deck-row {
    gap: 8px;
  }
  .member-name {
    font-size: 10px;
  }
  .member-role {
    font-size: 8px;
    letter-spacing: 0.04em;
  }
}

@media (max-width: 760px) and (orientation: landscape) {
  .stage {
    overflow-y: auto;
    overscroll-behavior: contain;
  }
  .council {
    inset: 0 auto auto 0;
    width: 100%;
    min-height: 100%;
  }
  /* The stage scrolls here, so cards can be wide enough for their captions (7.6vh is only
     right for the fitted portrait stack). */
  .board {
    --m-w: min(64px, calc((100vw - 88px) / 5));
  }
}
</style>
