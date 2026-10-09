<!-- Resources — "Delta": the course map is the navigator. -->
<template>
  <BranchPicker v-if="!branch && !launching" @pick="launch" />

  <Transition name="launch">
    <div v-if="launching" class="launch" :style="accStyle" aria-hidden="true">
      <p class="mono launch-txt">TAKEOFF · {{ launchLabel }}</p>

      <!-- paper plane drawn in a full-screen SVG and re-rendered as vectors every frame,
           so it stays razor sharp even when it grows to fill the screen -->
      <svg class="stage" width="100%" height="100%">
        <g ref="planeEl" class="plane" style="opacity: 0">
          <!-- flat sticker look: hard offset shadow, one flat fill, bold outline, one fold line -->
          <path d="M7 38 L63 12 L47 62 L33 46 Z" fill="var(--ink)" opacity="0.2" />
          <path
            d="M4 34 L60 8 L44 58 L30 42 Z"
            fill="var(--acc)"
            stroke="var(--ink)"
            stroke-width="3"
            stroke-linejoin="round"
            vector-effect="non-scaling-stroke"
          />
          <path
            d="M30 42 L60 8"
            fill="none"
            stroke="var(--ink)"
            stroke-width="3"
            stroke-linejoin="round"
            stroke-linecap="round"
            vector-effect="non-scaling-stroke"
          />
        </g>
      </svg>

      <div class="flood" />
    </div>
  </Transition>

  <!-- v-if is just "branch", so the page mounts underneath the overlay -->
  <main v-if="branch" class="wrap" :style="accStyle">
    <button class="branch-chip" type="button" @click="branch = null">
      {{ BRANCHES[branch].short }} · switch branch
    </button>

    <div class="bar">
      <SearchBar v-model="q" class="rise" style="--i: 1" />
      <TideLine class="rise" style="--i: 2" @pick="pick" />
    </div>

    <section class="mine rise" style="--i: 3" aria-labelledby="mine-h">
      <h2 id="mine-h" class="eyebrow">
        My courses <span v-if="store.mine.length" class="mono">{{ store.mine.length }}</span>
      </h2>
      <TransitionGroup name="tix" tag="div" class="tix">
        <CourseTicket v-for="code in store.mine" :key="code" :code="code" />
        <p v-if="!store.mine.length" key="empty" class="hint">
          <span class="dot" /> Tap your courses on the map below and pin them. Next time the site
          opens straight to them.
        </p>
      </TransitionGroup>
    </section>

    <section class="map rise" style="--i: 4" aria-labelledby="map-h">
      <div class="map-head">
        <h2 id="map-h" class="eyebrow">Every course, as the degree flows</h2>
        <p class="legend">
          <span><i class="k-mine" /> yours</span>
          <span class="only-h"><i class="k-trail" /> hover to trace the route</span>
        </p>
      </div>
      <DeltaMap :mine="store.mine" :match="match" :branch="branch" @open="open" />
    </section>

    <section class="rise" style="--i: 5" aria-labelledby="tools-h">
      <h2 id="tools-h" class="eyebrow">Quick links</h2>
      <ToolLinks />
    </section>
  </main>
</template>

<script setup>
import { computed, nextTick, ref } from 'vue';
import SearchBar from '../components/site/SearchBar.vue';
import TideLine from '../components/site/TideLine.vue';
import DeltaMap from '../components/site/DeltaMap.vue';
import CourseTicket from '../components/site/CourseTicket.vue';
import ToolLinks from '../components/site/ToolLinks.vue';
import BranchPicker from '../components/site/BranchPicker.vue';
import { openCourse, search, store } from '../lib/store.js';
import { byCode } from '../lib/courses.js';
import { BRANCHES, courseUrl } from '../data/branches.js';

const q = ref(store.q);
const branch = ref(null);
const launching = ref(false);
const launchLabel = ref('');
const launchId = ref(null);
store.q = '';

// The page's accent: vermilion by default, a wing tint per branch. Set on the
// roots as --acc; every resources component reads var(--acc, var(--mari)).
const ACCENTS = {
  ds: 'var(--verm)',
  es: 'var(--w-tech)',
  ae: 'var(--w-talks)',
  mg: 'var(--w-cultural)',
};
const accStyle = computed(() => ({
  '--acc': ACCENTS[branch.value || launchId.value] || 'var(--verm)',
}));

const planeEl = ref(null);
const FLY_MS = 1900; // keep in sync with the CSS 1.9s on .flood and .launch-txt

// Control points the plane passes through: [x vw, y vh, depth-scale].
// Starts bottom-left, flies away into the distance, U-turns on the right,
// then swoops back toward the viewer from the top-right and swells to fill the screen.
const PATH = [
  [-46, 40, 0.9],
  [-22, 14, 0.5],
  [-2, -6, 0.2],
  [14, -18, 0.13], // farthest point
  [30, -22, 0.25],
  [38, -14, 0.7],
  [26, -2, 3],
  [6, 4, 14],
  [0, 0, 50],
];
function catmull(p0, p1, p2, p3, t) {
  return (
    0.5 *
    (2 * p1 +
      (-p0 + p2) * t +
      (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t +
      (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t)
  );
}
function samplePath(u) {
  const n = PATH.length;
  const seg = u * (n - 1);
  const i = Math.min(Math.floor(seg), n - 2);
  const t = seg - i;
  const P = (k) => PATH[Math.max(0, Math.min(n - 1, k))];
  const out = [0, 1, 2].map((c) => catmull(P(i - 1)[c], P(i)[c], P(i + 1)[c], P(i + 2)[c], t));
  // depth-scale is interpolated in log space so growth feels like real perspective
  const ls = catmull(
    Math.log(P(i - 1)[2]),
    Math.log(P(i)[2]),
    Math.log(P(i + 1)[2]),
    Math.log(P(i + 2)[2]),
    t
  );
  return { x: out[0], y: out[1], s: Math.exp(ls) };
}
function flyPlane(g) {
  const W = window.innerWidth;
  const H = window.innerHeight;
  const t0 = performance.now();
  let prev = 0;
  function frame(now) {
    const u = Math.min(1, (now - t0) / FLY_MS);
    const p = samplePath(u);
    const a = samplePath(Math.max(0, u - 0.01));
    const b = samplePath(Math.min(1, u + 0.01));
    // heading follows the on-screen direction of travel (plane nose points ~25deg above east)
    let r = (Math.atan2((b.y - a.y) * H, (b.x - a.x) * W) * 180) / Math.PI + 25;
    while (r - prev > 180) r -= 360;
    while (r - prev < -180) r += 360;
    prev = r;
    const x = W / 2 + (p.x * W) / 100;
    const y = H / 2 + (p.y * H) / 100;
    g.setAttribute(
      'transform',
      `translate(${x} ${y}) rotate(${r}) scale(${(p.s * 72) / 64}) translate(-32 -32)`
    );
    g.style.opacity = Math.min(1, u / 0.05);
    if (u < 1) requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
}

async function launch(id) {
  launchId.value = id;
  launchLabel.value = BRANCHES[id].short + ' · ' + BRANCHES[id].label.toUpperCase();
  launching.value = true;
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (!reduce) {
    await nextTick();
    if (planeEl.value) flyPlane(planeEl.value);
  }
  setTimeout(
    () => {
      branch.value = id; // page mounts behind the colored screen
      requestAnimationFrame(() => (launching.value = false)); // overlay fades out = reveal
    },
    reduce ? 200 : FLY_MS
  );
}
function open(code, e) {
  if (byCode[code]) openCourse(code, parsed.value, e);
  else window.open(courseUrl(branch.value, code), '_blank');
}
const res = computed(() => search(q.value));
const parsed = computed(() => ({
  tab: res.value.parsed.tab ?? 'pyqs',
  exam: res.value.parsed.exam ?? 'All',
  week: res.value.parsed.week,
}));
const match = computed(() =>
  q.value.trim()
    ? new Set([...res.value.courses.map((c) => c.code), ...res.value.resources.map((r) => r.code)])
    : null
);
function pick(d) {
  if (d.exam) q.value = `${d.exam.toLowerCase()} pyq`;
}
</script>

<style scoped>
.wrap {
  --acc: var(--verm);
  --acc-wash: color-mix(in srgb, var(--acc) 15%, transparent);
  max-width: 1240px;
  margin: 0 auto;
  padding: 20px 24px 60px;
  display: grid;
  gap: 28px;
}
.bar {
  display: grid;
  grid-template-columns: 1fr minmax(360px, 440px);
  gap: 16px;
  align-items: start;
}
.eyebrow {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 12px;
  font-size: 13px;
  font-weight: 650;
  letter-spacing: 0.01em;
  color: var(--ink-2);
}
.eyebrow .mono {
  font-size: 11px;
  padding: 1px 6px;
  border-radius: 5px;
  background: var(--acc-wash);
  color: var(--acc);
}
.tix {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(270px, 1fr));
  gap: 12px;
}
.hint {
  grid-column: 1 / -1;
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 0;
  padding: 16px 18px;
  border: 1.5px dashed var(--line-strong);
  border-radius: 14px;
  color: var(--ink-2);
  font-size: 14.5px;
}
.hint .dot {
  flex: none;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: var(--acc);
  box-shadow: 0 0 0 5px var(--acc-wash);
}
.tix-enter-active {
  animation: print 0.7s var(--ease-out) both;
}
.tix-leave-active {
  transition:
    opacity 0.25s,
    transform 0.3s;
  position: absolute;
}
.tix-leave-to {
  opacity: 0;
  transform: scale(0.9) translateY(10px);
}
.tix-move {
  transition: transform 0.5s var(--ease-out);
}
@keyframes print {
  from {
    clip-path: inset(0 0 100% 0);
    transform: translateY(-14px);
  }
  to {
    clip-path: inset(0 0 0 0);
  }
}

/* ---------- takeoff overlay ---------- */
.launch {
  --acc: var(--verm);
  position: fixed;
  inset: 0;
  z-index: 60;
  display: grid;
  place-items: center;
  overflow: hidden;
  background:
    url('../assets/pat/grain.webp') 0 0 / 512px 512px,
    var(--paper);
  background-blend-mode: multiply, normal;
}
.launch .stage {
  position: absolute;
  inset: 0;
  z-index: 2;
}
.flood {
  position: absolute;
  inset: 0;
  z-index: 3;
  background: var(--acc);
  opacity: 0;
  animation: flood 1.9s ease-in both;
}
.launch-txt {
  position: absolute;
  bottom: 22vh;
  left: 50%;
  transform: translateX(-50%);
  letter-spacing: 0.2em;
  color: var(--ink-2);
  font-size: 12px;
  animation: txt 1.9s ease both;
}

/* as the plane swoops in and swells, its color takes over the page */
@keyframes flood {
  0%,
  78% {
    opacity: 0;
  }
  100% {
    opacity: 1;
  }
}
@keyframes txt {
  0% {
    opacity: 0;
    transform: translate(-50%, 8px);
  }
  10% {
    opacity: 1;
    transform: translate(-50%, 0);
  }
  45% {
    opacity: 1;
  }
  65%,
  100% {
    opacity: 0;
  }
}

/* reveal: the colored screen dissolves and the page is already underneath */
.launch-leave-active {
  transition: opacity 0.6s ease;
}
.launch-leave-to {
  opacity: 0;
}

@media (prefers-reduced-motion: reduce) {
  .flood,
  .launch-txt {
    animation: none;
  }
  .launch .plane {
    opacity: 1 !important;
  }
}

/* ---------- rest of page ---------- */
.branch-chip {
  position: sticky;
  top: 14px;
  justify-self: end;
  z-index: 5;
  padding: 6px 12px;
  border: 1.5px solid var(--acc, var(--line-strong));
  border-radius: 999px;
  background: var(--card);
  color: var(--acc, var(--ink));
  font-size: 12.5px;
  font-weight: 600;
  cursor: pointer;
}
.map {
  margin: 0 -8px;
  padding: 18px 8px 8px;
  border-top: 1px solid var(--line);
  border-bottom: 1px solid var(--line);
}
.map-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 16px;
}
.legend {
  display: flex;
  gap: 16px;
  margin: 0;
  font-size: 12.5px;
  color: var(--ink-2);
}
.legend span {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}
.k-mine {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: var(--acc);
  border: 1.5px solid var(--ink);
}
.k-trail {
  width: 18px;
  height: 4px;
  border-radius: 2px;
  background: var(--acc);
}
@media (max-width: 900px) {
  .bar {
    grid-template-columns: 1fr;
  }
}
@media (max-width: 760px) {
  .wrap {
    padding: 14px 16px 100px;
    gap: 22px;
  }
  .only-h {
    display: none;
  }
  .tix {
    grid-template-columns: none;
    grid-auto-flow: column;
    grid-auto-columns: 82%;
    overflow-x: auto;
    scroll-snap-type: x mandatory;
    padding-bottom: 6px;
    margin: 0 -16px;
    padding-left: 16px;
    padding-right: 16px;
    scrollbar-width: none;
  }
  .tix > * {
    scroll-snap-align: start;
  }
  .tix:has(> .hint) {
    display: block;
    margin: 0;
    padding: 0;
  }
}
</style>
