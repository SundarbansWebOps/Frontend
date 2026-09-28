<!--
  PROTOTYPE — Home variant 3, "Current". The Sundarbans is where three rivers meet the sea and
  the tide turns twice a day, so the river writes our name (CurrentHero), then splits into four
  distributaries, each running to a landing stage (a ghat) for one part of the site. On a wide
  screen the journey downstream is a pinned horizontal run driven by vertical scroll; on phones
  and with reduced motion it is a plain vertical page with the channels down the left edge.
-->
<template>
  <main class="current" :class="{ h: hmode, rm: reduced }">
    <CurrentHero @downstream="jump(-1)" @search="toSearch" />

    <section
      ref="down"
      class="down"
      :class="{ live: downVisible }"
      aria-labelledby="current-down-h"
      :style="hmode ? { height: `${runway}px` } : null"
    >
      <div ref="stage" class="stage">
        <div ref="chartEl" class="chart" aria-hidden="true" :style="CHART_BG" />
        <div ref="track" class="track" @focusin="onFocusIn">
          <svg
            class="river"
            aria-hidden="true"
            :width="geo.w"
            :height="geo.h"
            :viewBox="`0 0 ${geo.w || 1} ${geo.h || 1}`"
          >
            <defs>
              <clipPath :id="`${uid}-reveal`">
                <rect
                  ref="revealEl"
                  x="-20"
                  y="-20"
                  :width="hmode ? 0 : geo.w + 40"
                  :height="geo.h + 40"
                />
              </clipPath>
            </defs>
            <g :clip-path="`url(#${uid}-reveal)`">
              <path class="bank trunk" :d="geo.trunk" />
              <path v-for="l in geo.lanes" :key="'k' + l.id" class="bank" :d="l.d" />
              <path class="bed trunk" :d="geo.trunk" />
              <path v-for="l in geo.lanes" :key="'b' + l.id" class="bed" :d="l.d" />
              <path class="flow trunk" :d="geo.trunk" />
              <path v-for="l in geo.lanes" :key="'f' + l.id" class="flow" :d="l.d" />
              <circle
                v-for="l in geo.lanes"
                :key="'m' + l.id"
                class="mouth"
                :cx="l.end[0]"
                :cy="l.end[1]"
                r="5"
              />
            </g>
            <text
              v-for="l in geo.lanes"
              :key="'t' + l.id"
              class="lane-name"
              :x="l.label[0]"
              :y="l.label[1]"
            >
              {{ l.name }}
            </text>
          </svg>

          <header class="panel split">
            <p class="kicker">Downstream</p>
            <h2 id="current-down-h">One river, four channels.</h2>
            <p class="sub">Follow the current, or jump to where you’re headed.</p>
            <ol class="index">
              <li v-for="(g, i) in GHATS" :key="g.id">
                <button type="button" @click="jump(i)">
                  <span class="no">{{ g.no }}</span>
                  <b>{{ g.name }}</b>
                  <span class="lead"
                    >{{ g.stats[0][0].toLocaleString('en-IN') }} {{ g.stats[0][1] }}</span
                  >
                  <svg viewBox="0 0 24 24" aria-hidden="true">
                    <path d="M5 12h14M13 6l6 6-6 6" />
                  </svg>
                </button>
              </li>
            </ol>
          </header>

          <article
            v-for="(g, i) in GHATS"
            :id="`current-${g.id}`"
            :key="g.id"
            :ref="(el) => (panels[i] = el)"
            class="panel ghat"
            :class="[`g-${g.id}`, { on: entered[i] }]"
            :aria-labelledby="`current-${g.id}-h`"
          >
            <div class="copy">
              <div :ref="(el) => (marks[i] = el)" class="mark" aria-hidden="true">
                <svg viewBox="0 0 40 28">
                  <path d="M2 4h36M6 11h28M10 18h20M14 25h12" />
                </svg>
                <span>{{ g.no }}</span>
              </div>
              <h2 :id="`current-${g.id}-h`">{{ g.name }}</h2>
              <p class="desc">{{ g.desc }}</p>
              <dl class="stats">
                <div v-for="(s, j) in g.stats" :key="s[1]">
                  <dt>{{ s[1] }}</dt>
                  <dd>{{ shown[i][j].toLocaleString('en-IN') }}</dd>
                </div>
              </dl>
              <button type="button" class="cta" @click="g.go()">
                {{ g.cta }}
                <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" /></svg>
              </button>
            </div>
            <div class="taste">
              <CurrentSearch v-if="g.id === 'resources'" ref="searchCmp" />
              <CurrentSwell v-else-if="g.id === 'events'" :active="entered[i]" />
              <CurrentCities v-else-if="g.id === 'house'" :active="entered[i]" />
              <CurrentBranches v-else :active="entered[i]" />
            </div>
          </article>
          <div v-if="hmode" class="panel tail" aria-hidden="true" />
        </div>
      </div>
    </section>

    <footer class="sea">
      <svg class="swell" viewBox="0 0 1200 60" preserveAspectRatio="none" aria-hidden="true">
        <path
          d="M0 30 Q 50 10 100 30 T 200 30 T 300 30 T 400 30 T 500 30 T 600 30 T 700 30 T 800 30 T 900 30 T 1000 30 T 1100 30 T 1200 30 T 1300 30 T 1400 30 V60 H0Z"
        />
      </svg>
      <div class="sea-in">
        <div class="join">
          <p class="kicker">Where every channel meets the sea</p>
          <a class="wa" :href="WHATSAPP" target="_blank" rel="noopener">
            <LineIcon name="wa" />
            <span>Join the WhatsApp channel</span>
            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" /></svg>
          </a>
        </div>
        <div class="foot">
          <button type="button" @click="toast('Verify isn’t part of this prototype')">
            <LineIcon name="seal" /> Verify a certificate
          </button>
          <a :href="PORTAL.href" target="_blank" rel="noopener">
            <LineIcon :name="PORTAL.icon" /> IITM {{ PORTAL.label.toLowerCase() }}
          </a>
          <span class="sign">Sundarbans House · IIT Madras BS degree</span>
        </div>
      </div>
    </footer>
  </main>
</template>

<script setup>
import { nextTick, onBeforeUnmount, onMounted, reactive, ref } from 'vue';
import CurrentHero from './CurrentHero.vue';
import CurrentSearch from './CurrentSearch.vue';
import CurrentSwell from './CurrentSwell.vue';
import CurrentCities from './CurrentCities.vue';
import CurrentBranches from './CurrentBranches.vue';
import LineIcon from './LineIcon.vue';
import { courses, nav, toast } from './store.js';
import { TOOLS, WHATSAPP } from './data.js';
import { events, WINGS } from './events.js';
import { lower, meetupCount, photoCount, regions, upper } from './house.js';
import { COMMUNITIES, CREW } from './teams.js';

const PORTAL = TOOLS[0];
// The journey runs over a faded copy of the delta plate the hero dived through.
const CHART_BG = {
  '--day': `url(${new URL('./landing-assets/v3/delta.webp', import.meta.url).href})`,
  '--night': `url(${new URL('./landing-assets/v3/delta-night.webp', import.meta.url).href})`,
};
const uid = `cur${Math.random().toString(36).slice(2, 7)}`;
const sum = (list, f) => list.reduce((n, x) => n + f(x), 0);

// Every number is computed from the data modules.
const GHATS = [
  {
    id: 'resources',
    no: '01',
    name: 'Resources',
    desc: 'Every past paper and set of notes, sorted by course and exam.',
    stats: [
      [sum(courses, (c) => c.pyqs.length), 'past papers'],
      [sum(courses, (c) => c.notes.length), 'sets of notes'],
      [courses.length, 'courses'],
    ],
    cta: 'Open Resources',
    go: () => nav.go('resources'),
  },
  {
    id: 'events',
    no: '02',
    name: 'Events',
    desc: 'Every event the house has run, from talks to tournaments, month by month.',
    stats: [
      [events.length, 'events'],
      [Object.keys(WINGS).length, 'wings'],
      [new Set(events.filter((e) => e.y != null).map((e) => e.y)).size, 'seasons'],
    ],
    cta: 'See the archive',
    go: () => nav.go('events'),
  },
  {
    id: 'house',
    no: '03',
    name: 'House',
    desc: 'Who we are, who runs the house, and the cities where we meet in person.',
    stats: [
      [meetupCount, 'meetups'],
      [regions.length, 'regions'],
      [photoCount, 'photos'],
    ],
    cta: 'Meet the house',
    go: () => nav.go('house'),
  },
  {
    id: 'teams',
    no: '04',
    name: 'Teams',
    desc: 'How the house works: the councils, the communities and the crew behind it.',
    stats: [
      [upper.length + lower.length, 'council seats'],
      [COMMUNITIES.length, 'communities'],
      [CREW.length, 'crew teams'],
    ],
    cta: 'See how it works',
    go: () => nav.go('teams', 'how'),
  },
];

const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
const wide = matchMedia('(min-width: 1024px) and (min-height: 600px)');
const hmode = ref(!reduced && wide.matches);
const down = ref(null);
const stage = ref(null);
const track = ref(null);
const revealEl = ref(null);
const chartEl = ref(null);
const searchCmp = ref(null);
const panels = [];
const marks = [];
const entered = reactive(GHATS.map(() => false));
const shown = reactive(GHATS.map((g) => g.stats.map((s) => (reduced ? s[0] : 0))));
const runway = ref(0);
const downVisible = ref(false);
const geo = reactive({ w: 0, h: 0, trunk: '', lanes: [] });

let stageW = 0;
let scrollLen = 0;
let sectionTop = 0;
let navH = 60;
let tick = 0;
let x = 0;
const cleanups = [];
const timers = new Set();

// ---- numbers count up as each stage arrives ----
function arrive(i) {
  if (entered[i]) return;
  entered[i] = true;
  if (reduced) return;
  const t0 = performance.now();
  const step = (now) => {
    const k = Math.min(1, (now - t0) / 1100);
    const e = 1 - (1 - k) ** 4;
    GHATS[i].stats.forEach((s, j) => (shown[i][j] = Math.round(s[0] * e)));
    if (k < 1) timers.add(requestAnimationFrame(step));
  };
  timers.add(requestAnimationFrame(step));
}

// ---- layout: panel positions → the river's lanes ----
function measure() {
  if (!track.value) return;
  navH = parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--nav-h')) || 60;
  const tr = track.value.getBoundingClientRect();
  geo.w = Math.round(hmode.value ? track.value.scrollWidth : track.value.clientWidth);
  geo.h = Math.round(track.value.scrollHeight);
  stageW = stage.value.clientWidth;
  if (hmode.value) {
    scrollLen = Math.max(0, geo.w - stageW);
    runway.value = scrollLen + stage.value.clientHeight;
  }
  sectionTop = down.value.getBoundingClientRect().top + scrollY;
  const pts = marks.map((m) => {
    const r = m.getBoundingClientRect();
    return { x: r.left - tr.left, y: r.top - tr.top, w: r.width, h: r.height };
  });
  const lanes = [];
  if (hmode.value) {
    // Lanes run along the top band; Resources is the lowest so it can dive without crossing.
    const splitX = Math.min(260, stageW * 0.2);
    const trunkY = 70;
    geo.trunk = `M-10 ${trunkY} H${splitX - 90}`;
    GHATS.forEach((g, i) => {
      const y = 34 + (3 - i) * 22;
      const m = pts[i];
      const ex = m.x + 20;
      const ey = m.y - 4;
      lanes.push({
        id: g.id,
        name: g.name,
        d: `M${splitX - 90} ${trunkY} C${splitX - 40} ${trunkY} ${splitX - 50} ${y} ${splitX} ${y} H${ex - 70} C${ex - 20} ${y} ${ex} ${y + 10} ${ex} ${Math.min(ey, y + 40)} V${ey}`,
        end: [ex, ey],
        label: [splitX + 18 + i * 0, y - 6],
      });
    });
  } else {
    // Lanes run down the left gutter; Resources is the innermost so it turns off first.
    const splitY = pts[0].y - 70;
    const trunkX = 22;
    geo.trunk = `M${trunkX} -10 V${Math.max(0, splitY - 60)}`;
    GHATS.forEach((g, i) => {
      const lx = 7 + (3 - i) * 9;
      const m = pts[i];
      const ey = m.y + m.h / 2;
      const ex = m.x - 4;
      lanes.push({
        id: g.id,
        name: '',
        d: `M${trunkX} ${Math.max(0, splitY - 60)} C${trunkX} ${splitY - 20} ${lx} ${splitY - 30} ${lx} ${splitY} V${ey - 30} C${lx} ${ey - 6} ${lx + 6} ${ey} ${lx + 24} ${ey} H${ex}`,
        end: [ex, ey],
        label: [0, 0],
      });
    });
  }
  geo.lanes = lanes;
  update();
}

// ---- scroll: camera, reveal, arrivals ----
function update() {
  tick = 0;
  if (!track.value) return;
  if (hmode.value) {
    x = Math.min(scrollLen, Math.max(0, scrollY + navH - sectionTop));
    track.value.style.transform = `translate3d(${-x}px, 0, 0)`;
    if (chartEl.value) chartEl.value.style.transform = `translate3d(${-x * 0.12}px, 0, 0)`;
    revealEl.value?.setAttribute('width', x + stageW * 0.92 + 20);
    panels.forEach((p, i) => {
      if (p && p.offsetLeft < x + stageW * 0.72) arrive(i);
    });
  } else {
    const top = track.value.getBoundingClientRect().top;
    panels.forEach((p, i) => {
      if (p && top + p.offsetTop < innerHeight * 0.78) arrive(i);
    });
  }
}
function onScroll() {
  if (!tick) tick = requestAnimationFrame(update);
}

function panelTarget(i) {
  if (i < 0) return sectionTop - navH;
  const p = panels[i];
  if (!hmode.value) return sectionTop + p.offsetTop - navH - 8;
  const want = Math.min(scrollLen, Math.max(0, p.offsetLeft - (stageW - p.offsetWidth) / 2));
  return sectionTop - navH + want;
}

function jump(i, behavior = reduced ? 'auto' : 'smooth') {
  measureTop();
  scrollTo({ top: panelTarget(i), behavior });
}
function measureTop() {
  sectionTop = down.value.getBoundingClientRect().top + scrollY;
}

function toSearch() {
  jump(0);
  searchCmp.value?.[0]?.focus();
}

// Keyboard focus landing on an off-screen stage scrolls the page to bring it into view.
function onFocusIn(e) {
  if (!hmode.value) return;
  const i = panels.findIndex((p) => p?.contains(e.target));
  if (i < 0) return;
  const p = panels[i];
  if (p.offsetLeft >= x - 1 && p.offsetLeft + p.offsetWidth <= x + stageW + 1) return;
  jump(i, 'auto');
}

function on(target, type, fn, opts) {
  target.addEventListener(type, fn, opts);
  cleanups.push(() => target.removeEventListener(type, fn, opts));
}

async function relayout() {
  await nextTick();
  measure();
  // Fonts and portraits can shift panel widths; measure again once they settle.
  document.fonts.ready.then(() => measure());
}

onMounted(() => {
  relayout();
  on(window, 'scroll', onScroll, { passive: true });
  on(window, 'resize', () => relayout());
  const onWide = () => {
    hmode.value = !reduced && wide.matches;
    if (!hmode.value && track.value) track.value.style.transform = '';
    relayout();
  };
  wide.addEventListener('change', onWide);
  cleanups.push(() => wide.removeEventListener('change', onWide));
  const ro = new ResizeObserver(() => measure());
  ro.observe(track.value);
  cleanups.push(() => ro.disconnect());
  const io = new IntersectionObserver(([e]) => (downVisible.value = e.isIntersecting));
  io.observe(down.value);
  cleanups.push(() => io.disconnect());
  const mo = new MutationObserver(() => relayout());
  mo.observe(document.documentElement, { attributes: true, attributeFilter: ['data-font'] });
  cleanups.push(() => mo.disconnect());
});

onBeforeUnmount(() => {
  cancelAnimationFrame(tick);
  for (const t of timers) cancelAnimationFrame(t);
  for (const c of cleanups) c();
});
</script>

<style scoped>
.current {
  --pad: clamp(18px, 4vw, 56px);
  position: relative;
}
.kicker {
  margin: 0;
  font-family: var(--mono);
  font-size: 12px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--mari-ink);
}

/* ---- downstream ---- */
.down {
  position: relative;
}
.stage {
  position: relative;
}
.h .stage {
  position: sticky;
  top: var(--nav-h);
  height: calc(100svh - var(--nav-h));
  overflow: clip;
}
.track {
  position: relative;
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: clamp(48px, 9vh, 96px);
  padding: 56px var(--pad) 72px calc(var(--pad) + 30px);
}
.h .track {
  display: flex;
  gap: 0;
  height: 100%;
  width: max-content;
  padding: 0;
  will-change: transform;
}
.chart {
  position: absolute;
  inset: 0;
  pointer-events: none;
  background: var(--day) center / cover;
  opacity: 0.1;
  mix-blend-mode: multiply;
  -webkit-mask-image: linear-gradient(to bottom, transparent, #000 20%, #000 70%, transparent);
  mask-image: linear-gradient(to bottom, transparent, #000 20%, #000 70%, transparent);
}
.h .chart {
  right: -30vw;
  background-size: auto 150%;
  background-repeat: repeat-x;
}
:root[data-theme='dark'] .chart {
  background-image: var(--night);
  opacity: 0.22;
  mix-blend-mode: screen;
}
.river {
  position: absolute;
  inset: 0 auto auto 0;
  pointer-events: none;
  overflow: visible;
}
.bank,
.bed {
  fill: none;
  stroke-linecap: round;
  stroke-linejoin: round;
}
/* Engraved channels: an inked bank line either side of amber water. */
.bank {
  stroke: var(--ink-3);
  stroke-width: 10;
  opacity: 0.4;
}
.bank.trunk {
  stroke-width: 19;
}
.bed {
  stroke: color-mix(in srgb, var(--mari) 42%, var(--paper));
  stroke-width: 7.5;
}
.bed.trunk {
  stroke-width: 16;
}
.flow {
  fill: none;
  stroke: var(--flow);
  stroke-width: 1.6;
  stroke-linecap: round;
  stroke-dasharray: 9 19;
  opacity: 0.8;
  animation: flow 1.3s linear infinite;
  animation-play-state: paused;
}
.flow.trunk {
  stroke-width: 2.4;
  stroke-dasharray: 14 22;
  animation-duration: 1.6s;
}
.live .flow {
  animation-play-state: running;
}
@keyframes flow {
  to {
    stroke-dashoffset: -28;
  }
}
.rm .flow {
  animation: none;
}
/* Down the left gutter the channels run finer, so four fit side by side. */
.current:not(.h) .bank {
  stroke-width: 6;
}
.current:not(.h) .bed {
  stroke-width: 3.5;
}
.current:not(.h) .flow {
  stroke-width: 1.2;
  stroke-dasharray: 6 16;
}
.current:not(.h) .bank.trunk {
  stroke-width: 12;
}
.current:not(.h) .bed.trunk {
  stroke-width: 9;
}
.mouth {
  fill: var(--paper);
  stroke: var(--flow);
  stroke-width: 2;
}
.lane-name {
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  fill: var(--ink-3);
}

.panel {
  position: relative;
}
.h .panel {
  flex: none;
  height: 100%;
  padding: 150px 0 clamp(24px, 5vh, 48px);
}
.h .ghat {
  align-content: center;
  align-items: center;
}

/* The split: an index of the four channels. */
.split {
  display: grid;
  align-content: start;
  gap: 12px;
  max-width: 560px;
}
.h .split {
  width: clamp(440px, 40vw, 580px);
  padding-left: var(--pad);
  padding-right: 48px;
  align-content: center;
  padding-top: 110px;
}
.split h2 {
  margin: 0;
  font-size: clamp(34px, 4.4vw, 60px);
  font-weight: 800;
  line-height: 0.98;
  letter-spacing: -0.035em;
  text-wrap: balance;
}
.sub {
  margin: 0 0 8px;
  font-size: 17px;
  color: var(--ink-2);
}
.index {
  display: grid;
  gap: 2px;
  margin: 0;
  padding: 0;
  list-style: none;
  counter-reset: none;
}
.index button {
  width: 100%;
  display: grid;
  grid-template-columns: 34px auto 1fr 20px;
  align-items: baseline;
  gap: 12px;
  padding: 13px 4px;
  border: 0;
  border-bottom: 1px solid var(--line);
  background: none;
  text-align: left;
  transition: padding 0.3s var(--ease-out);
}
.index button:hover {
  padding-left: 12px;
}
.index .no {
  font-family: var(--mono);
  font-size: 12.5px;
  color: var(--mari-ink);
}
.index b {
  font-size: 20px;
  font-weight: 750;
  letter-spacing: -0.01em;
}
.index .lead {
  font-family: var(--mono);
  font-size: 13px;
  color: var(--ink-2);
  text-align: right;
}
.index svg,
.cta svg,
.wa > svg {
  width: 18px;
  height: 18px;
  fill: none;
  stroke: currentColor;
  stroke-width: 2;
  stroke-linecap: round;
  stroke-linejoin: round;
  align-self: center;
  transition: transform 0.3s var(--ease-spring);
}
.index button:hover svg,
.cta:hover svg,
.wa:hover > svg {
  transform: translateX(4px);
}

/* A ghat: copy on the left, a working taste of the page on the right. */
.ghat {
  display: grid;
  grid-template-columns: minmax(250px, 0.72fr) minmax(0, 1.28fr);
  gap: clamp(24px, 4vw, 64px);
  align-items: start;
}
.h .ghat {
  width: min(1180px, 88vw);
  padding-left: 40px;
  padding-right: 40px;
}
.copy {
  display: grid;
  gap: 14px;
  align-content: start;
}
.mark {
  display: flex;
  align-items: center;
  gap: 10px;
  width: fit-content;
  padding: 6px 12px 6px 8px;
  border-radius: 99px;
  background: var(--card);
  box-shadow: inset 0 0 0 1.5px var(--line-strong);
}
.mark svg {
  width: 26px;
  height: 18px;
  fill: none;
  stroke: var(--flow);
  stroke-width: 2.5;
  stroke-linecap: round;
}
.mark span {
  font-family: var(--mono);
  font-size: 12.5px;
  font-weight: 600;
  color: var(--mari-ink);
}
.ghat h2 {
  margin: 0;
  font-size: clamp(40px, 5.2vw, 72px);
  font-weight: 800;
  line-height: 0.95;
  letter-spacing: -0.04em;
}
.desc {
  margin: 0;
  max-width: 30ch;
  font-size: 18px;
  line-height: 1.45;
  color: var(--ink-2);
  text-wrap: pretty;
}
.stats {
  display: flex;
  flex-wrap: wrap;
  gap: 12px 26px;
  margin: 6px 0 4px;
}
.stats div {
  display: flex;
  flex-direction: column-reverse;
}
.stats dt {
  font-size: 13px;
  color: var(--ink-2);
}
.stats dd {
  margin: 0;
  font-size: clamp(28px, 2.7vw, 38px);
  font-weight: 750;
  letter-spacing: -0.03em;
  line-height: 1.05;
  font-variant-numeric: tabular-nums;
}
.stats div:first-child dd {
  color: var(--mari-ink);
}
.cta {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  width: fit-content;
  height: 48px;
  margin-top: 6px;
  padding: 0 20px;
  border: 0;
  border-radius: 99px;
  background: var(--ink);
  color: var(--paper);
  font-size: 15.5px;
  font-weight: 650;
  transition: transform 0.3s var(--ease-spring);
}
.cta:hover {
  transform: translateY(-2px);
}
.taste {
  min-width: 0;
  opacity: 0;
  transform: translateY(18px);
  transition:
    opacity 0.7s var(--ease-out) 0.15s,
    transform 0.9s var(--ease-out) 0.15s;
}
.on .taste {
  opacity: 1;
  transform: none;
}
.h .taste {
  height: 100%;
  max-height: 560px;
}
.g-resources .taste {
  max-width: 560px;
}
.copy > * {
  opacity: 0;
  transform: translateY(14px);
  transition:
    opacity 0.6s var(--ease-out),
    transform 0.7s var(--ease-out);
}
.copy > :nth-child(2) {
  transition-delay: 0.06s;
}
.copy > :nth-child(3) {
  transition-delay: 0.12s;
}
.copy > :nth-child(4) {
  transition-delay: 0.18s;
}
.copy > :nth-child(5) {
  transition-delay: 0.24s;
}
.on .copy > * {
  opacity: 1;
  transform: none;
}
.rm .copy > *,
.rm .taste {
  opacity: 1;
  transform: none;
  transition: none;
}
.tail {
  width: 18vw;
}

/* ---- the sea ---- */
.sea {
  position: relative;
  margin-top: 24px;
  padding: 0 var(--pad) 28px;
  background: var(--mari-soft);
  color: var(--ink);
}
.swell {
  position: absolute;
  left: 0;
  bottom: 100%;
  width: 100%;
  height: 40px;
  fill: var(--mari-soft);
}
.sea-in {
  max-width: 1240px;
  margin: 0 auto;
  display: grid;
  gap: 22px;
  padding-top: 26px;
}
.join {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}
.join .kicker {
  font-size: 12.5px;
}
.wa {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  height: 52px;
  padding: 0 22px 0 18px;
  border-radius: 99px;
  background: var(--ink);
  color: var(--paper);
  font-size: 16px;
  font-weight: 700;
  text-decoration: none;
  transition: transform 0.3s var(--ease-spring);
}
.wa:hover {
  transform: translateY(-2px);
}
.foot {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px 22px;
  padding-top: 16px;
  border-top: 1px solid color-mix(in srgb, var(--mari-ink) 30%, transparent);
  font-size: 14.5px;
}
.foot button,
.foot a {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 6px 0;
  border: 0;
  background: none;
  font-weight: 600;
  color: var(--ink);
  text-decoration: none;
}
.foot button:hover,
.foot a:hover {
  text-decoration: underline;
  text-underline-offset: 4px;
}
.foot .sign {
  margin-left: auto;
  color: var(--ink-2);
  font-size: 13.5px;
}
.foot :deep(.ic) {
  width: 18px;
  height: 18px;
}

/* ---- phones and narrow screens ---- */
@media (max-width: 1023px) {
  .ghat {
    grid-template-columns: minmax(0, 1fr);
  }
  .panel {
    scroll-margin-top: calc(var(--nav-h) + 8px);
  }
}
@media (max-width: 760px) {
  .track {
    padding: 40px 16px 56px 50px;
  }
  .desc {
    font-size: 16.5px;
  }
  .sea {
    padding-bottom: 96px;
  }
  .foot .sign {
    margin-left: 0;
    width: 100%;
  }
  .index button {
    grid-template-columns: 28px auto 1fr 18px;
    gap: 8px;
  }
  .index b {
    font-size: 18px;
  }
}
</style>
