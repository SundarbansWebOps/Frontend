<!--
  PROTOTYPE — Home variant 3 ("Current"), the hero. Three engraved map plates nest (the bay,
  the delta, one channel) and the camera dives through them; over the plates a canvas of
  streaklines flows downstream. The name surfaces as an obstacle the current parts around,
  with a second current glowing inside the letters. Then the tide turns, every so often.
  Scrolling away pulls the camera back out toward the whole delta.
-->
<template>
  <section
    ref="hero"
    class="hero"
    :class="{ ff, rm: reduced, night, ready }"
    aria-labelledby="current-title"
    @pointermove="onPointer"
    @pointerleave="pointer.s = 0"
  >
    <div ref="platesEl" class="plates" aria-hidden="true">
      <img
        v-for="(pl, i) in PLATES"
        :key="pl.id"
        :ref="(el) => (plateEls[i] = el)"
        class="plate"
        :class="pl.id"
        :src="night ? pl.night : pl.day"
        alt=""
        width="1024"
        height="1024"
        :fetchpriority="i === 0 ? 'high' : 'auto'"
        decoding="async"
        @load="onPlate(i, $event)"
      />
      <div ref="bloomEl" class="bloom" />
    </div>
    <div class="wash" aria-hidden="true" />
    <div class="prints" aria-hidden="true">
      <img
        v-for="(pr, i) in PRINTS"
        :key="i"
        :src="PRINT_SRC"
        alt=""
        :style="{
          clipPath: `circle(10% at ${pr[0]}% ${pr[1]}%)`,
          transformOrigin: `${pr[0]}% ${pr[1]}%`,
          '--i': i,
        }"
      />
    </div>

    <div class="content">
      <p class="eyebrow">
        <span>IIT Madras BS degree</span><i aria-hidden="true" /><span>since 2021</span>
      </p>
      <h1 id="current-title">
        <span ref="wordEl" class="word">Sundarbans<i ref="baseEl" class="bl" /></span>
        <span class="house"><i aria-hidden="true" />House</span>
      </h1>
      <p class="line">Notes, past papers, events and people, all in one place.</p>
      <div class="acts">
        <button type="button" class="go" @click="emit('downstream')">
          <span>Follow the current</span>
          <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 4v15M6 13l6 6 6-6" /></svg>
        </button>
        <button type="button" class="find" @click="emit('search')">Find a past paper</button>
      </div>
    </div>

    <canvas ref="cv" class="streaks" aria-hidden="true" />

    <div class="seal" aria-hidden="true">
      <svg viewBox="0 0 200 200">
        <defs>
          <path id="current-ring" d="M100 100m-78 0a78 78 0 1 1 156 0a78 78 0 1 1-156 0" />
        </defs>
        <circle class="disc" cx="100" cy="100" r="96" />
        <circle class="rule" cx="100" cy="100" r="93" pathLength="1" />
        <circle class="rule thin" cx="100" cy="100" r="64" pathLength="1" />
        <g class="spin">
          <text>
            <textPath href="#current-ring" textLength="486">
              SUNDARBANS HOUSE · IIT MADRAS BS DEGREE · SINCE 2021 ·
            </textPath>
          </text>
        </g>
      </svg>
      <img :src="CREST" alt="" width="120" height="120" />
    </div>

    <div class="tide" aria-hidden="true">
      <svg viewBox="0 0 24 24" :style="{ transform: `rotate(${tideAngle}deg)` }">
        <path d="M4 12h15M13 6l6 6-6 6" />
      </svg>
      <span
        ><b>{{ tideLabel }}</b
        ><small>The tide turns twice a day. Here, every half minute.</small></span
      >
    </div>
  </section>
</template>

<script setup>
import { onBeforeUnmount, onMounted, reactive, ref } from 'vue';
import { createFlow } from './current-flow.js';

const emit = defineEmits(['downstream', 'search']);

const asset = (f) => new URL(`./landing-assets/v3/${f}`, import.meta.url).href;
const PLATES = [
  { id: 'orbit', day: asset('orbit.webp'), night: asset('orbit-night.webp') },
  { id: 'delta', day: asset('delta.webp'), night: asset('delta-night.webp') },
  { id: 'channel', day: asset('channel.webp'), night: asset('channel-night.webp') },
];
const PRINT_SRC = asset('prints.webp');
// Centres of the six pugmarks in the print plate, as % of the image.
const PRINTS = [
  [12.2, 87.9],
  [30.8, 75.7],
  [46.9, 61],
  [61.5, 45.4],
  [74.7, 28.8],
  [90.8, 13.2],
];
const CREST =
  'https://res.cloudinary.com/l59gy0g2/image/upload/f_auto,q_auto,w_320,c_limit/v1785911356/sundarbans/src/assets/LOGO.jpg';

// Log-zoom: L = 0 shows the bay; each plate is the centre quarter of the one before, so
// the channel plate fills the frame at ln 16. We end a hair past it.
const L_END = Math.log(16) + 0.06;
const CHANNEL_DIR = Math.atan2(1024, 760); // the channel plate runs upper-left → lower-right
const INTRO = 4.3; // s, everything composed
const TIDE_FIRST = 7;
const TIDE_EVERY = 30;

const hero = ref(null);
const platesEl = ref(null);
const bloomEl = ref(null);
const cv = ref(null);
const wordEl = ref(null);
const baseEl = ref(null);
const plateEls = [];
const ff = ref(false);
const ready = ref(false);
const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
const night = ref(document.documentElement.dataset.theme === 'dark');
const tideLabel = ref('Ebbing');
const tideAngle = ref(90);
const pointer = reactive({ x: 0, y: 0, vx: 0, vy: 0, s: 0 });

let flow;
let W = 0;
let H = 0;
let raf = 0;
let t0 = 0; // intro clock origin (ms); null until the first plate is ready or we give up
let last = 0;
let visible = true;
let lastL = -1;
let scrollL = 0;
let wordQueued = false;
let L0 = 0; // the opening zoom: the whole bay, framed on the paper
const cleanups = [];

const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
const ease = (x) => (x < 0.5 ? 4 * x * x * x : 1 - (-2 * x + 2) ** 3 / 2);
const smooth = (a, b, x) => {
  const t = clamp((x - a) / (b - a));
  return t * t * (3 - 2 * t);
};

// ---- plates ----
function onPlate(i, e) {
  e.target.decode?.().catch(() => {});
  e.target.classList.add('in');
  if (i === 0 && t0 == null) startClock();
}

function applyZoom(L) {
  if (Math.abs(L - lastL) < 1e-4) return;
  lastL = L;
  const S = Math.max(W, H);
  const base = Math.exp(L);
  for (let i = 0; i < 3; i++) {
    const el = plateEls[i];
    if (!el) continue;
    const s = base / 4 ** i;
    const next = i < 2 ? base / 4 ** (i + 1) : 0;
    const gone = next > 1.4;
    el.style.transform = `translate(-50%, -50%) scale(${s.toFixed(4)})`;
    el.style.opacity = gone ? 0 : i === 0 ? 1 : smooth(0.2, 0.45, s).toFixed(3);
    if (i > 0) {
      // The next plate arrives as a soft disc in the centre; as it grows the disc widens to
      // the plate's corners and the feather tightens to nothing, so it takes over seamlessly.
      const k = smooth(0.55, 1.2, s);
      const r = S * (0.5 + 0.21 * k);
      const inner = r * (0.3 + 0.7 * k);
      el.style.maskImage = el.style.webkitMaskImage =
        k >= 1 ? 'none' : `radial-gradient(circle ${r}px, #000 ${inner}px, transparent ${r}px)`;
    }
    // Magnified past ~2.2× of its pixels, a plate goes a touch soft: depth of field.
    const mag = (s * S) / 1024;
    el.style.filter =
      mag > 2.6 && !gone ? `blur(${Math.min(1.2, (mag - 2.6) * 0.8).toFixed(2)}px)` : '';
  }
  // The bay starts as a whole plate lying on the paper; its frame fades as it fills the view.
  platesEl.value?.style.setProperty('--frame', (1 - smooth(0.9, 1, base)).toFixed(3));
  const b = Math.max(
    Math.exp(-(((L - Math.log(4)) / 0.22) ** 2)),
    Math.exp(-(((L - Math.log(16)) / 0.22) ** 2))
  );
  if (bloomEl.value) bloomEl.value.style.opacity = (b * 0.5).toFixed(3);
}

// ---- the word as an obstacle ----
function queueWord() {
  if (wordQueued) return;
  wordQueued = true;
  document.fonts.ready.then(() =>
    requestAnimationFrame(() => {
      wordQueued = false;
      buildWord();
    })
  );
}

function buildWord() {
  if (!flow || !wordEl.value || !cv.value) return;
  const c = cv.value.getBoundingClientRect();
  const r = wordEl.value.getBoundingClientRect();
  const cs = getComputedStyle(wordEl.value);
  const baseline = baseEl.value.getBoundingClientRect().bottom - c.top;
  const size = parseFloat(cs.fontSize);
  // Every other block of text is an island too, so streaks never cross the copy.
  const islands = [...hero.value.querySelectorAll('.eyebrow, .house, .line, .acts, .seal')].map(
    (el) => {
      const b = el.getBoundingClientRect();
      return { x: b.left - c.left, y: b.top - c.top, w: b.width, h: b.height };
    }
  );
  flow.setWord({
    text: 'Sundarbans',
    font: `${cs.fontStyle} ${cs.fontWeight} ${size}px ${cs.fontFamily}`,
    letterSpacing: cs.letterSpacing === 'normal' ? '0px' : cs.letterSpacing,
    x: r.left - c.left,
    baseline,
    size,
    islands,
  });
  if (reduced) flow.still(60);
}

// ---- theme ----
function applyTheme() {
  night.value = document.documentElement.dataset.theme === 'dark';
  if (!flow) return;
  flow.params.colors = night.value
    ? { streak: '#f4b04a', glow: '#fff1cf', glowHead: '#ffffff', lighter: true }
    : { streak: '#5a3004', glow: '#e8901a', glowHead: '#ffd488', lighter: false };
  if (reduced) flow.still(1);
}

// ---- sizing ----
function resize() {
  const r = hero.value.getBoundingClientRect();
  W = r.width;
  H = r.height;
  platesEl.value.style.setProperty('--S', `${Math.max(W, H)}px`);
  L0 = Math.log((Math.min(W, H) * 0.88) / Math.max(W, H));
  lastL = -1;
  const dpr = Math.min(1.5, devicePixelRatio || 1);
  flow.resize(W, H, dpr);
  queueWord();
  if (reduced) applyZoom(L_END);
}

// ---- time ----
function startClock() {
  if (t0 != null) return;
  t0 = performance.now();
  ready.value = true;
}

function fastForward() {
  if (ff.value) return;
  ff.value = true;
  startClock();
  t0 = Math.min(t0, performance.now() - INTRO * 1000);
}

// The tide: ebb (downstream) most of the time; slack, a short flood back upstream, slack.
function tideAt(s) {
  if (s < TIDE_FIRST) return 1;
  const ph = (s - TIDE_FIRST) % TIDE_EVERY;
  if (ph < 1.3) return 1 - smooth(0, 1.3, ph);
  if (ph < 2.4) return -0.75 * smooth(1.3, 2.4, ph);
  if (ph < 3.6) return -0.75;
  if (ph < 4.8) return -0.75 * (1 - smooth(3.6, 4.8, ph));
  if (ph < 6.2) return smooth(4.8, 6.2, ph);
  return 1;
}

function frame(now) {
  raf = requestAnimationFrame(frame);
  const dt = Math.min(3, (now - (last || now)) / 16.67 || 1);
  last = now;
  const s = t0 == null ? 0 : (now - t0) / 1000;
  const p = flow.params;

  // Intro dive, then the scroll scrub takes the camera back out.
  const Lintro = L0 + (L_END - L0) * ease(clamp((s - 0.3) / 2.8));
  const L = s < 3 ? Lintro : L_END - scrollL;
  const prevL = lastL < 0 ? L : lastL;
  applyZoom(L);
  p.zoom = s < 3.1 ? (L - prevL) * 0.55 : 0;
  p.dir = Math.PI / 2 + (CHANNEL_DIR - Math.PI / 2) * smooth(1.6, 2.5, L);
  // Streaks wait until the plate fills the view, so the opening reads as a map on paper.
  p.alpha = smooth(0.7, 1, Math.exp(L));
  // The name surfaces: first as a gap in the current, then lit from inside, then inked.
  p.obstacle = smooth(1.8, 2.6, s);
  p.glow = smooth(2.2, 2.9, s) * (1 - 0.35 * smooth(3.2, 4, s));
  p.tide = tideAt(s);
  pointer.s *= 0.965;
  p.pointer = pointer.s > 0.01 ? pointer : null;

  const label = p.tide > 0.3 ? 'Ebbing' : p.tide < -0.3 ? 'Flooding' : 'Slack water';
  if (label !== tideLabel.value) tideLabel.value = label;
  const ang = Math.round(((p.dir * 180) / Math.PI) * 1) + (p.tide < 0 ? 180 : 0);
  if (ang !== tideAngle.value) tideAngle.value = ang;

  flow.step(dt);
  flow.draw();
}

function run() {
  if (reduced || raf || !visible || document.hidden) return;
  last = 0;
  raf = requestAnimationFrame(frame);
}
function halt() {
  cancelAnimationFrame(raf);
  raf = 0;
}

function onPointer(e) {
  if (reduced || e.pointerType === 'touch') return;
  const r = hero.value.getBoundingClientRect();
  const x = e.clientX - r.left;
  const y = e.clientY - r.top;
  pointer.vx = pointer.s > 0.02 ? (x - pointer.x) * 0.5 : 0;
  pointer.vy = pointer.s > 0.02 ? (y - pointer.y) * 0.5 : 0;
  pointer.x = x;
  pointer.y = y;
  pointer.s = 1;
}

function onScroll() {
  const h = hero.value?.offsetHeight || 1;
  const f = clamp(scrollY / h);
  scrollL = f * (L_END - 1.1);
  platesEl.value?.style.setProperty('--py', `${(scrollY * 0.35).toFixed(1)}px`);
  if (!raf && !reduced && visible) run();
}

function on(target, type, fn, opts) {
  target.addEventListener(type, fn, opts);
  cleanups.push(() => target.removeEventListener(type, fn, opts));
}

onMounted(() => {
  flow = createFlow(cv.value);
  applyTheme();
  resize();

  const ro = new ResizeObserver(() => resize());
  ro.observe(hero.value);
  const wo = new ResizeObserver(() => queueWord());
  wo.observe(wordEl.value);
  cleanups.push(() => wo.disconnect());
  on(document.fonts, 'loadingdone', queueWord);
  cleanups.push(() => ro.disconnect());

  const mo = new MutationObserver((list) => {
    for (const m of list) {
      if (m.attributeName === 'data-theme') applyTheme();
      if (m.attributeName === 'data-font') queueWord();
    }
  });
  mo.observe(document.documentElement, { attributes: true });
  cleanups.push(() => mo.disconnect());

  if (reduced) {
    ff.value = true;
    ready.value = true;
    t0 = performance.now() - 60000;
    flow.params.obstacle = 1;
    flow.params.glow = 1;
    flow.params.dir = CHANNEL_DIR;
    applyZoom(L_END);
    return;
  }

  // Never wait on the plates: if the bay is slow to arrive, the current starts without it.
  t0 = null;
  if (plateEls[0]?.complete && plateEls[0].naturalWidth) startClock();
  const wait = setTimeout(startClock, 650);
  cleanups.push(() => clearTimeout(wait));

  for (const type of ['pointerdown', 'keydown', 'wheel', 'touchmove'])
    on(window, type, fastForward, { passive: true });
  on(window, 'scroll', onScroll, { passive: true });
  on(document, 'visibilitychange', () => (document.hidden ? halt() : run()));
  const io = new IntersectionObserver(([e]) => {
    visible = e.isIntersecting;
    if (visible) run();
    else halt();
  });
  io.observe(hero.value);
  cleanups.push(() => io.disconnect());
  onScroll();
  run();
});

onBeforeUnmount(() => {
  halt();
  for (const c of cleanups) c();
});
</script>

<style scoped>
.hero {
  --pad: clamp(18px, 4vw, 56px);
  position: relative;
  min-height: calc(100svh - var(--nav-h));
  overflow: clip;
  isolation: isolate;
  display: grid;
  align-items: end;
}

/* ---- plates ---- */
.plates {
  position: absolute;
  inset: 0;
  z-index: -3;
  overflow: hidden;
  background: var(--sunk);
  transform: translateY(var(--py, 0));
}
.plate {
  position: absolute;
  left: 50%;
  top: 50%;
  width: var(--S, 100vw);
  height: var(--S, 100vw);
  max-width: none;
  transform-origin: 50% 50%;
  transform: translate(-50%, -50%) scale(1);
  will-change: transform, opacity;
  opacity: 0;
}
/* While the bay is smaller than the view it reads as a plate lying on the paper. */
.plate.orbit {
  box-shadow:
    0 0 0 calc(var(--frame, 0) * 6px) var(--paper),
    0 0 0 calc(var(--frame, 0) * 7px) var(--line-strong),
    0 30px 60px -30px rgb(29 25 21 / calc(var(--frame, 0) * 0.6));
}
.plate:not(.in) {
  visibility: hidden;
}
.bloom {
  position: absolute;
  inset: 0;
  opacity: 0;
  background: radial-gradient(closest-side, #fff6e2, rgb(255 246 226 / 0.4) 55%, transparent);
  mix-blend-mode: screen;
  pointer-events: none;
}
.night .bloom {
  background: radial-gradient(closest-side, #f4b04a, rgb(244 176 74 / 0.25) 55%, transparent);
}

/* ---- the paper rises under the name ---- */
.wash {
  position: absolute;
  inset: 0;
  z-index: -2;
  pointer-events: none;
  background:
    linear-gradient(
      to top,
      var(--paper) 0%,
      color-mix(in srgb, var(--paper) 94%, transparent) 30%,
      color-mix(in srgb, var(--paper) 72%, transparent) 46%,
      color-mix(in srgb, var(--paper) 0%, transparent) 70%
    ),
    radial-gradient(
      120% 70% at 0% 100%,
      color-mix(in srgb, var(--paper) 70%, transparent),
      transparent 70%
    );
  animation: wash 1.3s var(--ease-out) 1.9s both;
}
@keyframes wash {
  from {
    opacity: 0;
    transform: translateY(18%);
  }
}

/* ---- tiger pugmarks stamp across the upper bank ---- */
.prints {
  position: absolute;
  z-index: -1;
  left: clamp(-30px, 1vw, 24px);
  top: clamp(20px, 5vh, 56px);
  width: clamp(150px, 19vw, 280px);
  aspect-ratio: 1;
  pointer-events: none;
  opacity: 0.9;
  mix-blend-mode: multiply;
}
.night .prints {
  mix-blend-mode: screen;
  filter: invert(1) sepia(1) saturate(3) hue-rotate(-8deg) brightness(0.95);
}
.prints img {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  animation: stamp 0.5s var(--ease-spring) calc(3.2s + var(--i) * 0.15s) both;
}
@keyframes stamp {
  0% {
    opacity: 0;
    transform: scale(1.5) rotate(-8deg);
  }
  60% {
    opacity: 1;
  }
}

/* ---- words ---- */
.content {
  position: relative;
  z-index: 1;
  padding: 0 var(--pad) clamp(28px, 7vh, 64px);
  max-width: 1500px;
}
.eyebrow {
  display: flex;
  align-items: center;
  gap: 10px;
  width: fit-content;
  margin: 0 0 10px;
  padding: 5px 12px;
  border-radius: 99px;
  background: color-mix(in srgb, var(--paper) 86%, transparent);
  font-family: var(--mono);
  font-size: 12.5px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--ink-2);
  animation: rise 0.8s var(--ease-out) 2.75s both;
}
.eyebrow i {
  width: 28px;
  height: 1.5px;
  background: var(--mari-ink);
}
h1 {
  margin: 0;
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
  column-gap: 0.14em;
  font-size: clamp(60px, 15.4vw, 250px);
  font-weight: 800;
  line-height: 0.9;
  letter-spacing: -0.045em;
  color: var(--ink);
}
.word {
  position: relative;
  display: block;
  /* The letters fill in along the current, after the glowing streaks have drawn them. */
  -webkit-mask-image: linear-gradient(
    60deg,
    #000 calc(var(--p) - 18%),
    transparent calc(var(--p) + 4%)
  );
  mask-image: linear-gradient(60deg, #000 calc(var(--p) - 18%), transparent calc(var(--p) + 4%));
  --p: 122%;
  animation: fill 1s cubic-bezier(0.5, 0, 0.2, 1) 3.05s both;
}
.house i {
  width: 1.3em;
  height: 0.16em;
  border-radius: 1em;
  background: var(--mari);
}
@property --p {
  syntax: '<percentage>';
  inherits: false;
  initial-value: 122%;
}
@keyframes fill {
  from {
    --p: -10%;
  }
}
.night h1 .word {
  color: var(--mari);
}
.bl {
  display: inline-block;
  width: 0;
  height: 0;
  vertical-align: baseline;
}
.house {
  display: flex;
  align-items: center;
  gap: 0.35em;
  margin-top: 0.2em;
  font-size: 0.21em;
  font-weight: 700;
  letter-spacing: -0.01em;
  line-height: 1;
  color: var(--mari-ink);
  animation: rise 0.8s var(--ease-out) 3s both;
}
.line {
  max-width: 34ch;
  margin: clamp(10px, 2vh, 20px) 0 0;
  font-size: clamp(17px, 1.55vw, 22px);
  line-height: 1.4;
  font-weight: 500;
  color: var(--ink-2);
  text-wrap: balance;
  animation: rise 0.8s var(--ease-out) 3.1s both;
}
.acts {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: clamp(16px, 2.6vh, 26px);
  animation: rise 0.8s var(--ease-out) 3.25s both;
}
.acts button {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  height: 48px;
  padding: 0 20px;
  border-radius: 99px;
  font-size: 15.5px;
  font-weight: 650;
  transition:
    transform 0.3s var(--ease-spring),
    background 0.2s;
}
.go {
  border: 0;
  background: var(--ink);
  color: var(--paper);
}
.go svg {
  width: 18px;
  height: 18px;
  fill: none;
  stroke: currentColor;
  stroke-width: 2;
  stroke-linecap: round;
  stroke-linejoin: round;
  animation: nudge 1.8s var(--ease-out) 4.2s infinite;
}
@keyframes nudge {
  40% {
    transform: translateY(3px);
  }
}
.find {
  border: 1.5px solid var(--line-strong);
  background: color-mix(in srgb, var(--paper) 70%, transparent);
  color: var(--ink);
}
.acts button:hover {
  transform: translateY(-2px);
}
.find:hover {
  background: var(--sunk);
}

.streaks {
  position: absolute;
  inset: 0;
  z-index: 2;
  width: 100%;
  height: 100%;
  pointer-events: none;
}

/* ---- the seal: crest in a turning cartouche ---- */
.seal {
  position: absolute;
  z-index: 3;
  right: var(--pad);
  top: clamp(18px, 4vh, 40px);
  width: clamp(92px, 11vw, 158px);
  aspect-ratio: 1;
  animation: seal 0.9s var(--ease-spring) 2.9s both;
}
@keyframes seal {
  from {
    opacity: 0;
    transform: scale(1.35) rotate(-20deg);
  }
}
.seal svg {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  overflow: visible;
}
.seal .disc {
  fill: var(--paper);
  filter: drop-shadow(0 10px 18px rgb(29 25 21 / 0.28));
}
.seal .rule {
  fill: none;
  stroke: var(--mari-ink);
  stroke-width: 1.5;
  stroke-dasharray: 1 1;
  animation: draw 1.2s var(--ease-out) 3s both;
}
.seal .rule.thin {
  stroke-width: 1;
  stroke: var(--line-strong);
}
@keyframes draw {
  from {
    stroke-dashoffset: 1;
  }
}
.seal text {
  font-family: var(--mono);
  font-size: 13.5px;
  font-weight: 600;
  letter-spacing: 0.04em;
  fill: var(--ink-2);
}
.seal .spin {
  transform-origin: 100px 100px;
  animation: spin 60s linear infinite;
}
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
.seal img {
  position: absolute;
  inset: 19%;
  width: 62%;
  height: 62%;
  border-radius: 50%;
  background: #111;
  object-fit: cover;
}

/* ---- tide gauge ---- */
.tide {
  position: absolute;
  z-index: 3;
  right: var(--pad);
  top: calc(clamp(18px, 4vh, 40px) + clamp(92px, 11vw, 158px) + 18px);
  display: flex;
  flex-direction: row-reverse;
  align-items: center;
  gap: 10px;
  text-align: right;
  padding: 6px 6px 6px 14px;
  border-radius: 99px;
  background: color-mix(in srgb, var(--paper) 88%, transparent);
  backdrop-filter: blur(6px);
  font-family: var(--mono);
  color: var(--ink-2);
  animation: rise 0.8s var(--ease-out) 3.6s both;
}
.tide svg {
  width: 30px;
  height: 30px;
  padding: 6px;
  border-radius: 50%;
  border: 1.5px solid var(--line-strong);
  fill: none;
  stroke: var(--mari-ink);
  stroke-width: 2;
  stroke-linecap: round;
  stroke-linejoin: round;
  transition: transform 1.2s var(--ease-out);
}
.tide span {
  display: grid;
  line-height: 1.25;
}
.tide b {
  font-size: 12.5px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--ink);
}
.tide small {
  font-size: 11px;
  max-width: 21ch;
}

/* Fast-forward and reduced motion: the composed frame, at once. */
.ff .wash,
.ff .prints img,
.ff .eyebrow,
.ff .word,
.ff .house,
.ff .line,
.ff .acts,
.ff .seal,
.ff .seal .rule,
.ff .tide {
  animation: none;
}
.rm .seal .spin,
.rm .go svg {
  animation: none;
}
.plate.in {
  transition: opacity 0.35s;
}

@media (max-width: 1100px) {
  .tide small {
    display: none;
  }
}
@media (max-width: 760px) {
  .hero {
    align-items: end;
  }
  .content {
    padding-bottom: 128px;
  }
  h1 {
    font-size: 21.5vw;
  }
  .house {
    font-size: 0.24em;
  }
  .tide {
    bottom: auto;
    top: 20px;
    right: auto;
    left: var(--pad);
  }
  .prints {
    top: auto;
    bottom: 46%;
    left: auto;
    right: -10px;
    width: 150px;
  }
  .acts button {
    height: 46px;
    padding: 0 16px;
    font-size: 15px;
  }
}
</style>
