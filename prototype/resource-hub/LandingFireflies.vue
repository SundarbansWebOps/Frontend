<!--
  PROTOTYPE — Home, variant 1 "Synchrony". Sundarbans fireflies gather in the mangroves and
  flash in unison: students scattered across India, blinking out of step, fall into one rhythm.
  A painted night scene (five generated plates, parallaxed plane by plane) holds a canvas swarm
  that wakes, syncs (Kuramoto coupling) and flies into the house's name. Scrolling out of the
  hero turns night to dawn, and the same swarm re-forms into the site's real data, one light per
  paper, event, meetup or seat. Engine: fireflies-swarm.js; shapes: fireflies-shapes.js.
-->
<template>
  <main class="ff" :class="{ lit, fast, reduced }">
    <canvas ref="cv" class="swarm" aria-hidden="true" />

    <section ref="heroEl" class="hero" aria-labelledby="ff-title">
      <div class="scene" aria-hidden="true">
        <img
          v-for="l in LAYERS"
          :key="l.id"
          :ref="(el) => (layerEls[l.id] = el)"
          class="layer"
          :class="[l.id, { ok: loaded[l.id] }]"
          :src="l.id === 'dawn' && !dawnReady ? undefined : l.src"
          :fetchpriority="l.id === 'sky' || l.id === 'mid' ? 'high' : undefined"
          alt=""
          decoding="async"
          @load="onLayer(l.id)"
        />
        <div ref="veilEl" class="veil" />
        <div ref="flashEl" class="flash" />
        <div ref="fadeEl" class="fade" />
      </div>

      <div ref="copyEl" class="copy">
        <img class="crest" :src="CREST" alt="" width="64" height="64" />
        <p class="eyebrow">IIT Madras BS degree <i aria-hidden="true" /> since 2021</p>
        <h1 id="ff-title">
          <span ref="wordEl" class="word">Sundarbans</span>
          <span class="house">House</span>
        </h1>
        <p class="line">Notes, past papers, events and people, all in one place.</p>
      </div>

      <nav class="jump" aria-label="What’s here">
        <button
          v-for="(f, i) in FEATURES"
          :key="f.id"
          type="button"
          :style="{ '--i': i }"
          @click="jump(f.id)"
        >
          <span class="k">{{ f.title }}</span>
          <b class="mono">{{ fmt(f.jump[0]) }}</b>
          <small>{{ f.jump[1] }}</small>
        </button>
      </nav>
    </section>

    <section class="brief" aria-label="What the site has">
      <div class="stage-col">
        <div class="stage-back" aria-hidden="true" />
        <div class="stage" aria-hidden="true">
          <div ref="planeEl" class="plane">
            <p class="legend" :class="{ on: legend.length }">
              <span v-for="g in legend" :key="g.t"><i :class="g.c" />{{ g.t }}</span>
            </p>
            <TransitionGroup name="lbl">
              <span
                v-for="l in labels"
                :key="l.id"
                class="lbl"
                :class="l.cls"
                :style="{ left: `${l.x}px`, top: `${l.y}px` }"
                >{{ l.text }}<b v-if="l.n" class="mono">{{ l.n }}</b></span
              >
            </TransitionGroup>
          </div>
        </div>
      </div>

      <div class="copycol">
        <p class="bridge">
          <span class="dot" aria-hidden="true" />
          Every light from here on is something real — a paper, an event, a meetup, a seat.
        </p>
        <article
          v-for="(f, i) in FEATURES"
          :id="`ff-${f.id}`"
          :key="f.id"
          :ref="(el) => (featEls[i] = el)"
          class="feat"
          :class="{ on: active === f.id }"
          :data-id="f.id"
        >
          <p class="idx mono">0{{ i + 1 }}</p>
          <h2>{{ f.title }}</h2>
          <p class="lead">{{ f.line }}</p>
          <dl class="stats">
            <div v-for="s in f.stats" :key="s[1]">
              <dd class="mono">{{ fmt(s[0]) }}</dd>
              <dt>{{ s[1] }}</dt>
            </div>
          </dl>
          <p class="lights">{{ f.lights }}</p>

          <FirefliesSearch v-if="f.id === 'resources'" @codes="(c) => (codes = c)" />

          <ul v-else-if="f.id === 'events'" class="recent" aria-label="Most recent events">
            <li v-for="e in recent" :key="e.id" :class="`w-${e.wing}`">
              <i aria-hidden="true" />
              <b>{{ e.title }}</b>
              <span>{{ WINGS[e.wing]?.label }} · {{ MONTH[e.m] }} {{ e.y }}</span>
            </li>
          </ul>

          <ul v-else-if="f.id === 'house'" class="uhc" aria-label="Upper House Council">
            <li v-for="p in upper" :key="p.id">
              <img :src="portrait.face(p.img)" alt="" width="56" height="56" loading="lazy" />
              <b>{{ p.name }}</b>
              <span>{{ p.role }}</span>
            </li>
          </ul>

          <ul v-else class="tiers">
            <li v-for="t in TIERS" :key="t.label">
              <b class="mono">{{ t.n }}</b>
              <span
                ><strong>{{ t.label }}</strong> {{ t.note }}</span
              >
            </li>
          </ul>

          <button type="button" class="cta" @click="f.go">
            {{ f.cta }} <LineIcon name="arrow" />
          </button>
        </article>
      </div>
    </section>

    <section class="close" aria-labelledby="ff-join">
      <div class="join">
        <p class="idx mono">Stay in step</p>
        <h2 id="ff-join">News, events and meetups, the moment they’re out.</h2>
        <a class="wa" :href="WHATSAPP" target="_blank" rel="noopener">
          <LineIcon name="wa" /> Join the WhatsApp channel
        </a>
      </div>
      <footer class="foot">
        <span>Sundarbans House · IIT Madras BS degree</span>
        <button type="button" @click="toast('Verify isn’t part of this prototype')">
          <LineIcon name="seal" /> Verify a certificate
        </button>
        <a :href="TOOLS[0].href" target="_blank" rel="noopener">
          <LineIcon name="portal" /> IITM student portal
        </a>
      </footer>
    </section>
  </main>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref, shallowRef, watch } from 'vue';
import LineIcon from './LineIcon.vue';
import FirefliesSearch from './FirefliesSearch.vue';
import { nav, store, toast } from './store.js';
import { courses, TOOLS, WHATSAPP } from './data.js';
import { events, MONTH, WINGS } from './events.js';
import { lower, meetupCount, photoCount, portrait, regions, upper } from './house.js';
import { COMMUNITIES, CREW } from './teams.js';
import { createSwarm, END, FLASH } from './fireflies-swarm.js';
import {
  biggestShape,
  fmt,
  layoutEvents,
  layoutHouse,
  layoutResources,
  layoutTeams,
  totals,
} from './fireflies-shapes.js';

const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
const CREST =
  'https://res.cloudinary.com/l59gy0g2/image/upload/f_auto,q_auto,w_320,c_limit/v1785911356/sundarbans/src/assets/LOGO.jpg';

// Five plates sharing one camera and horizon; depth sets how far each moves.
const LAYERS = [
  { id: 'sky', depth: 0.1, src: new URL('./landing-assets/v1/sky.webp', import.meta.url).href },
  { id: 'dawn', depth: 0.1, src: new URL('./landing-assets/v1/dawn.webp', import.meta.url).href },
  { id: 'far', depth: 0.28, src: new URL('./landing-assets/v1/far.webp', import.meta.url).href },
  { id: 'mid', depth: 0.6, src: new URL('./landing-assets/v1/mid.webp', import.meta.url).href },
  { id: 'near', depth: 1, src: new URL('./landing-assets/v1/near.webp', import.meta.url).href },
];
const DEPTH = Object.fromEntries(LAYERS.map((l) => [l.id, l.depth]));
const HORIZON = 0.615; // of the plate's height
const MUD = 0.8;

// ---- Copy and real numbers -----------------------------------------------------------------
const seasons = new Set(events.filter((e) => e.y != null).map((e) => e.y)).size;
const seats = upper.length + lower.length;
const recent = events.filter((e) => e.at).slice(0, 3);
const FEATURES = [
  {
    id: 'resources',
    title: 'Resources',
    line: 'Every past paper and set of notes, sorted by course and exam.',
    stats: [
      [courses.length, 'courses'],
      [totals.pyqs, 'past papers'],
      [totals.notes, 'sets of notes'],
    ],
    lights: `Each light is one real file — ${fmt(totals.pyqs)} papers at the foot of each course, ${fmt(totals.notes)} sets of notes above, courses grouped by level.`,
    jump: [totals.pyqs + totals.notes, 'papers & notes'],
    cta: 'Open Resources',
    go: () => nav.go('resources'),
  },
  {
    id: 'events',
    title: 'Events',
    line: 'Every event the house has run, from talks to tournaments, month by month.',
    stats: [
      [events.length, 'events'],
      [Object.keys(WINGS).length, 'wings'],
      [seasons, 'seasons'],
    ],
    lights: 'Each light is one event, stacked in the month it happened and coloured by its wing.',
    jump: [events.length, 'events'],
    cta: 'See the archive',
    go: () => nav.go('events'),
  },
  {
    id: 'house',
    title: 'House',
    line: 'Who we are, who runs the house, and the cities where we meet in person.',
    stats: [
      [regions.length, 'regions'],
      [meetupCount, 'meetups'],
      [photoCount, 'photos'],
    ],
    lights: 'Each light is one meetup, gathered at the city it happened in.',
    jump: [meetupCount, 'meetups'],
    cta: 'Meet the house',
    go: () => nav.go('house'),
  },
  {
    id: 'teams',
    title: 'Teams',
    line: 'How the house works: the councils, the communities and the crew behind it.',
    stats: [
      [seats, 'council seats'],
      [COMMUNITIES.length, 'communities'],
      [CREW.length, 'crew teams'],
    ],
    lights: 'Each light is one seat or team, from the Upper House Council down to the crew.',
    jump: [seats, 'council seats'],
    cta: 'See how it works',
    go: () => nav.go('teams', 'how'),
  },
];
const TIERS = [
  { n: upper.length, label: 'Upper House Council', note: 'runs the house' },
  { n: lower.length, label: 'regional coordinators', note: `across ${regions.length} regions` },
  { n: COMMUNITIES.length, label: 'communities', note: COMMUNITIES.map((c) => c.name).join(' · ') },
  { n: CREW.length, label: 'crew teams', note: CREW.map((c) => c.name).join(' · ') },
];

// ---- Refs and state ------------------------------------------------------------------------
const cv = ref(null);
const heroEl = ref(null);
const wordEl = ref(null);
const planeEl = ref(null);
const veilEl = ref(null);
const flashEl = ref(null);
const fadeEl = ref(null);
const copyEl = ref(null);
const layerEls = {};
const featEls = [];
const loaded = reactive({});
const dawnReady = ref(false);
const lit = ref(reduced);
const fast = ref(false);
const active = ref('hero');
const codes = ref([]);
const shapes = shallowRef({});

const LEGENDS = {
  resources: [
    { c: 'sw-pyq', t: 'past paper' },
    { c: 'sw-note', t: 'set of notes' },
  ],
  events: Object.entries(WINGS).map(([id, w]) => ({ c: `sw-w w-${id}`, t: w.label })),
  house: [{ c: 'sw-meet', t: 'one meetup' }],
  teams: [],
};
const legend = computed(() => LEGENDS[active.value] ?? []);
const labels = computed(() => {
  const L = shapes.value[active.value];
  if (!L) return [];
  const out = [...L.labels];
  if (active.value === 'resources')
    for (const code of codes.value) {
      const c = L.cols[code];
      if (c) out.push({ id: `c-${code}`, x: c.x, y: c.y, text: c.text, cls: 'col' });
    }
  return out;
});

// ---- Scene geometry: cover-fit plates, then per-layer push-in, pointer and scroll parallax ----
let geo = { W: 1, H: 1, dw: 1, dh: 1, left: 0, top: 0, ox: 0, oy: 0 };
const LS = Object.fromEntries(LAYERS.map((l) => [l.id, { sc: 1, tx: 0, ty: 0 }]));
const look = { x: 0, y: 0, tx: 0, ty: 0 };
let fine = matchMedia('(pointer: fine)').matches;
let homes = [];
let heroRect = null;
let planeRect = null;

function measureHero() {
  const el = heroEl.value;
  const W = el.clientWidth;
  const H = el.clientHeight;
  const narrow = W / H < 0.9;
  const s = Math.max(W / 1536, H / 1024) * 1.06;
  const dw = 1536 * s;
  const dh = 1024 * s;
  // Phones keep the moon's column and the right-hand trees; the name takes the sky.
  const left = (W - dw) * (narrow ? 0.8 : 0.5);
  const top = (H - dh) * (narrow ? 0.46 : 0.6);
  geo = { W, H, dw, dh, left, top, ox: W / 2, oy: top + dh * HORIZON };
  for (const l of LAYERS) {
    const img = layerEls[l.id];
    if (!img) continue;
    Object.assign(img.style, {
      width: `${dw}px`,
      height: `${dh}px`,
      left: `${left}px`,
      top: `${top}px`,
      transformOrigin: `${geo.ox - left}px ${geo.oy - top}px`,
    });
  }
}

function mapLayer(id, u, v, out) {
  const st = LS[id];
  const bx = geo.left + u * geo.dw;
  const by = geo.top + v * geo.dh;
  out.x = geo.ox + (bx - geo.ox) * st.sc + st.tx;
  out.y = geo.oy + (by - geo.oy) * st.sc + st.ty;
  return out;
}

const easeOut = (t) => 1 - Math.pow(1 - Math.min(1, Math.max(0, t)), 3);
const smooth = (a, b, v) => {
  const t = Math.min(1, Math.max(0, (v - a) / (b - a)));
  return t * t * (3 - 2 * t);
};

function sceneFrame(clock, dt) {
  heroRect = heroEl.value.getBoundingClientRect();
  planeRect = planeEl.value.getBoundingClientRect();
  const H = heroRect.height;
  const sy = Math.min(H, Math.max(0, -heroRect.top));
  const prog = sy / H;
  const cam = reduced ? 0 : 1 - easeOut(clock / END);
  if (!reduced) {
    if (!fine) {
      // No gyro: phones get a slow drift instead.
      look.tx = Math.sin(clock * 0.21) * 0.6;
      look.ty = Math.cos(clock * 0.16) * 0.35;
    }
    const k = Math.min(1, dt * 2.5);
    look.x += (look.tx - look.x) * k;
    look.y += (look.ty - look.y) * k;
  }
  const heroOn = heroRect.bottom > 0;
  for (const l of LAYERS) {
    const d = l.depth;
    const st = LS[l.id];
    st.sc = 1.015 + d * 0.022 + d * 0.2 * cam;
    st.tx = -look.x * d * 18;
    st.ty = -look.y * d * 10 + sy * (0.5 - d * 0.6);
    const img = layerEls[l.id];
    if (heroOn && img)
      img.style.transform = `translate3d(${st.tx.toFixed(2)}px,${st.ty.toFixed(2)}px,0) scale(${st.sc.toFixed(4)})`;
  }
  if (!heroOn) return;
  const light = document.documentElement.dataset.theme !== 'dark';
  layerEls.dawn.style.opacity = (smooth(0.06, 0.62, prog) * (light ? 1 : 0.32)).toFixed(3);
  layerEls.near.style.opacity = (1 - smooth(0.04, 0.4, prog)).toFixed(3);
  copyEl.value.style.opacity = (1 - smooth(0.12, 0.42, prog)).toFixed(3);
  fadeEl.value.style.opacity = smooth(0, 0.45, prog).toFixed(3);
  const t = clock;
  const veil =
    1 -
    0.3 * smooth(0.1, 1.2, t) -
    0.18 * smooth(1.2, 3.1, t) -
    0.52 * smooth(FLASH - 0.1, FLASH + 0.5, t);
  veilEl.value.style.opacity = veil.toFixed(3);
  const flash =
    t >= END || t < FLASH - 0.15
      ? 0
      : Math.exp(-Math.max(0, t - FLASH) / 0.5) * smooth(FLASH - 0.15, FLASH, t);
  flashEl.value.style.opacity = flash.toFixed(3);
  if (!lit.value && t >= FLASH - 0.05) lit.value = true;
}

// ---- Firefly homes: sampled from the lit canopies of the mid plate (and the far treeline) ----
function sampleLayer(img, test) {
  const c = document.createElement('canvas');
  c.width = 192;
  c.height = 128;
  const g = c.getContext('2d', { willReadFrequently: true });
  g.drawImage(img, 0, 0, 192, 128);
  const d = g.getImageData(0, 0, 192, 128).data;
  const out = [];
  for (let j = 0; j < 128; j++)
    for (let i = 0; i < 192; i++) {
      const k = (j * 192 + i) * 4;
      const w = test(d[k], d[k + 1], d[k + 2], d[k + 3], j / 128);
      if (w > 0) out.push({ u: (i + Math.random()) / 192, v: (j + Math.random()) / 128, w });
    }
  return out;
}

function pickWeighted(list, m) {
  const cum = [];
  let tot = 0;
  for (const p of list) cum.push((tot += p.w));
  const out = [];
  for (let k = 0; k < m && list.length; k++) {
    const q = Math.random() * tot;
    let lo = 0;
    let hi = cum.length - 1;
    while (lo < hi) {
      const mid = (lo + hi) >> 1;
      if (cum[mid] < q) lo = mid + 1;
      else hi = mid;
    }
    out.push(list[lo]);
  }
  return out;
}

let midCands = null;
let farCands = null;
const tmp = { x: 0, y: 0 };
function visibleAtRest(p) {
  const bx = geo.left + p.u * geo.dw;
  const by = geo.top + p.v * geo.dh;
  return bx > 8 && bx < geo.W - 8 && by > 12 && by < geo.H * 0.86;
}
function buildHomes() {
  const mids = (
    midCands ??
    // Before the plate decodes: loose canopy regions on either side of the open centre.
    Array.from({ length: 400 }, (_, i) => ({
      u: i % 2 ? 0.02 + Math.random() * 0.4 : 0.78 + Math.random() * 0.2,
      v: 0.08 + Math.random() * 0.5,
      w: 1,
    }))
  ).filter((p) => visibleAtRest(p));
  const fars = (farCands ?? []).filter((p) => visibleAtRest(p));
  const m = swarm.count;
  const pm = pickWeighted(mids, m);
  const pf = fars.length ? pickWeighted(fars, m) : pm;
  homes = Array.from({ length: m }, (_, i) =>
    swarm.isFar(i) && fars.length ? { l: 'far', ...pf[i] } : { l: 'mid', ...pm[i] }
  );
  // The first light, alone in the dark: open sky in the middle of the frame, over the river.
  homes[0] = { l: 'sky', u: (geo.W * 0.56 - geo.left) / geo.dw, v: 0.4 };
}

async function sampleHomes() {
  const mid = layerEls.mid;
  const far = layerEls.far;
  try {
    await Promise.all([mid.decode(), far.decode()]);
  } catch {
    return;
  }
  if (!swarm) return;
  // Rim-lit canopy (bright, opaque, above the mudflat) is where fireflies gather.
  const fresh = !midCands;
  midCands = sampleLayer(mid, (r, g, b, al, v) => {
    if (al < 200 || v > 0.66) return 0;
    const lum = (r * 0.5 + g * 0.4 + b * 0.1) / 255;
    if (lum < 0.1) return 0;
    return (v < 0.48 ? 1 : 0.3) * (0.4 + lum);
  });
  farCands = sampleLayer(far, (r, g, b, al) => (al > 140 ? 0.2 + r / 255 : 0));
  buildHomes();
  if (fresh && swarm.clock < 0.8) swarm.place();
}

// ---- The wordmark: sample the real <h1> glyphs, drawn in the live --font -------------------
function sampleWord() {
  const el = wordEl.value;
  const hr = heroEl.value.getBoundingClientRect();
  const r = el.getBoundingClientRect();
  const cs = getComputedStyle(el);
  const fs = parseFloat(cs.fontSize);
  const pad = 12;
  const c = document.createElement('canvas');
  c.width = Math.ceil(r.width + pad * 2);
  c.height = Math.ceil(r.height + pad * 2);
  const g = c.getContext('2d', { willReadFrequently: true });
  g.font = `${cs.fontWeight} ${fs}px ${cs.fontFamily}`;
  if ('letterSpacing' in g)
    g.letterSpacing = cs.letterSpacing === 'normal' ? '0px' : cs.letterSpacing;
  const text = el.textContent.trim();
  const m = g.measureText(text);
  const lh = parseFloat(cs.lineHeight) || fs;
  const asc = m.fontBoundingBoxAscent ?? fs * 0.8;
  const desc = m.fontBoundingBoxDescent ?? fs * 0.2;
  const base = (lh - (asc + desc)) / 2 + asc;
  g.setTransform(r.width / m.width, 0, 0, 1, pad, pad);
  g.fillStyle = '#fff';
  g.fillText(text, 0, base);
  const d = g.getImageData(0, 0, c.width, c.height).data;
  const W = c.width;
  const H = c.height;
  const inside = (x, y) => x >= 0 && y >= 0 && x < W && y < H && d[(y * W + x) * 4 + 3] > 128;
  // Lights ring the letters from just outside their edges: the crisp <h1> sits on top, the
  // swarm blazes around it.
  const edge = [];
  const R = Math.max(3, Math.round(fs * 0.035));
  for (let y = 1; y < H - 1; y++)
    for (let x = 1; x < W - 1; x++)
      if (
        !inside(x, y) &&
        (inside(x - R, y) || inside(x + R, y) || inside(x, y - R) || inside(x, y + R))
      )
        edge.push([x, y]);
  const want = Math.round(swarm.count * 0.64);
  const gap = Math.max(4, (edge.length / R / want) * 0.95);
  for (let k = edge.length - 1; k > 0; k--) {
    const j = Math.floor(Math.random() * (k + 1));
    [edge[k], edge[j]] = [edge[j], edge[k]];
  }
  // Even spacing along the outline: accept a point only if no accepted point is too close.
  const cell = new Map();
  const key = (x, y) => `${Math.floor(x / gap)},${Math.floor(y / gap)}`;
  const pts = [];
  for (const [x, y] of edge) {
    let near = false;
    const cx = Math.floor(x / gap);
    const cy = Math.floor(y / gap);
    for (let j = -1; j <= 1 && !near; j++)
      for (let i = -1; i <= 1 && !near; i++)
        for (const q of cell.get(`${cx + i},${cy + j}`) ?? [])
          if ((q[0] - x) ** 2 + (q[1] - y) ** 2 < gap * gap * 0.8) {
            near = true;
            break;
          }
    if (near) continue;
    const kk = key(x, y);
    if (!cell.has(kk)) cell.set(kk, []);
    cell.get(kk).push([x, y]);
    pts.push({ x: r.left - hr.left + x - pad, y: r.top - hr.top + y - pad });
    if (pts.length >= want) break;
  }
  swarm.setWord(pts);
}

// ---- Stage shapes and which one is showing ----------------------------------------------------
function layoutStage() {
  const el = planeEl.value;
  const W = el.clientWidth;
  const H = el.clientHeight;
  const narrow = innerWidth <= 760;
  const pad = narrow ? 22 : 40;
  const add = (L) => ({ ...L, spares: { W, H, pad } });
  shapes.value = {
    resources: add(layoutResources(W, H, narrow)),
    events: add(layoutEvents(W, H, narrow)),
    house: add(layoutHouse(W, H, narrow)),
    teams: add(layoutTeams(W, H, narrow)),
  };
}

function pickSection() {
  const vh = innerHeight;
  const hr = heroRect ?? heroEl.value.getBoundingClientRect();
  if (hr.bottom > vh * 0.42) return 'hero';
  let cur = FEATURES[0].id;
  for (const el of featEls)
    if (el && el.getBoundingClientRect().top < vh * 0.62) cur = el.dataset.id;
  return cur;
}

function show(id, instant = false) {
  active.value = id;
  if (id === 'hero') swarm.setHero();
  else swarm.setShape(shapes.value[id], { instant });
}

const courseIndex = Object.fromEntries(courses.map((c, i) => [c.code, i]));
watch(codes, (v) => {
  swarm?.setHighlight(new Set(v.map((c) => courseIndex[c])));
  redraw();
});
watch(() => store.sheet, runOrPause);

function jump(id) {
  document
    .getElementById(`ff-${id}`)
    ?.scrollIntoView({ behavior: reduced ? 'auto' : 'smooth', block: 'start' });
}

// ---- Lifecycle -------------------------------------------------------------------------------
let swarm = null;
let io = null;
let mo = null;
const seen = new Set();
let still = 0;
let idleId = 0;
let idleIsTimeout = false;

function origins() {
  const hr = heroRect ?? heroEl.value.getBoundingClientRect();
  const pr = planeRect ?? planeEl.value.getBoundingClientRect();
  return [
    { x: hr.left, y: hr.top },
    { x: pr.left, y: pr.top },
  ];
}

function onFrame(clock, dt) {
  sceneFrame(clock, dt);
  const id = pickSection();
  if (id !== active.value) show(id);
}

function runOrPause() {
  if (!swarm || reduced) return;
  if (seen.size && !document.hidden && !store.sheet) swarm.start();
  else {
    swarm.stop();
    if (!seen.size) cv.value.getContext('2d').clearRect(0, 0, cv.value.width, cv.value.height);
  }
}

// Reduced motion: the final state, redrawn only when the page moves.
function redraw() {
  if (!swarm || !reduced || still) return;
  still = requestAnimationFrame(() => {
    still = 0;
    heroRect = null;
    planeRect = null;
    heroRect = heroEl.value.getBoundingClientRect();
    planeRect = planeEl.value.getBoundingClientRect();
    const id = pickSection();
    if (id !== active.value) show(id, true);
    swarm.still();
  });
}

function relayout() {
  if (!swarm) return;
  swarm.resize();
  measureHero();
  heroRect = heroEl.value.getBoundingClientRect();
  planeRect = planeEl.value.getBoundingClientRect();
  sceneFrame(swarm.clock, 0);
  buildHomes();
  sampleWord();
  layoutStage();
  if (active.value !== 'hero') swarm.setShape(shapes.value[active.value], { instant: reduced });
  if (reduced) redraw();
}
let resizeT = 0;
function onResize() {
  clearTimeout(resizeT);
  resizeT = setTimeout(relayout, 120);
}

// Any input fast-forwards the intro to its final state.
function fastForward() {
  if (!swarm || swarm.clock >= END) return;
  fast.value = true;
  lit.value = true;
  swarm.skip();
  swarm.still();
}
const FF_EVENTS = ['pointerdown', 'keydown', 'wheel', 'touchmove'];

function onPointer(e) {
  const p = swarm?.pointer;
  if (!p) return;
  p.x = e.clientX;
  p.y = e.clientY;
  p.on = true;
  if (fine && e.pointerType === 'mouse') {
    look.tx = (e.clientX / innerWidth - 0.5) * 2;
    look.ty = (e.clientY / innerHeight - 0.5) * 2;
  }
}
function offPointer(e) {
  if (!swarm) return;
  if (e.type === 'pointerout' && e.relatedTarget) return;
  swarm.pointer.on = false;
}

function onLayer(id) {
  loaded[id] = true;
}

onMounted(() => {
  const area = innerWidth * innerHeight;
  const count = Math.round(Math.min(640, Math.max(220, 260 + ((area - 330000) * 340) / 700000)));
  swarm = createSwarm(cv.value, {
    count,
    pool: biggestShape,
    reduced,
    origins,
    home(i, out) {
      const h = homes[i];
      if (!h) return mapLayer('mid', 0.5, 0.3, out);
      return mapLayer(h.l, h.u, h.v, out);
    },
    river() {
      return {
        hz: mapLayer('sky', 0, HORIZON, tmp).y,
        mud: mapLayer('mid', 0, MUD, tmp).y,
      };
    },
    day() {
      if (document.documentElement.dataset.theme === 'dark') return 0;
      const hr = heroRect ?? heroEl.value.getBoundingClientRect();
      return smooth(0.3, 0.8, Math.max(0, -hr.top) / hr.height);
    },
    onFrame,
  });
  measureHero();
  heroRect = heroEl.value.getBoundingClientRect();
  planeRect = planeEl.value.getBoundingClientRect();
  sceneFrame(swarm.clock, 0);
  buildHomes();
  sampleWord();
  layoutStage();
  swarm.place();
  swarm.setHighlight(new Set(codes.value.map((c) => courseIndex[c])));
  sampleHomes();
  document.fonts?.ready.then(() => swarm && relayout());

  // The dawn plate isn't needed until the reader scrolls; fetch it once the night is up.
  idleIsTimeout = !window.requestIdleCallback;
  idleId = idleIsTimeout
    ? setTimeout(() => (dawnReady.value = true), 1200)
    : window.requestIdleCallback(() => (dawnReady.value = true));
  document.fonts?.addEventListener('loadingdone', relayout);

  io = new IntersectionObserver((entries) => {
    for (const e of entries) e.isIntersecting ? seen.add(e.target) : seen.delete(e.target);
    runOrPause();
  });
  io.observe(heroEl.value);
  io.observe(heroEl.value.nextElementSibling);

  // Typeface (F) and theme (T) switches: re-sample the glyphs, re-read the colour tokens.
  mo = new MutationObserver((list) => {
    if (list.some((m) => m.attributeName === 'data-theme')) {
      swarm.theme();
      sceneFrame(swarm.clock, 0);
      redraw();
    }
    if (list.some((m) => m.attributeName === 'data-font'))
      document.fonts.ready.then(() => swarm && relayout());
  });
  mo.observe(document.documentElement, {
    attributes: true,
    attributeFilter: ['data-theme', 'data-font'],
  });

  addEventListener('resize', onResize);
  document.addEventListener('visibilitychange', runOrPause);
  if (reduced) {
    addEventListener('scroll', redraw, { passive: true });
    swarm.still();
  } else {
    for (const ev of FF_EVENTS) addEventListener(ev, fastForward, { passive: true });
    addEventListener('pointermove', onPointer, { passive: true });
    addEventListener('pointerdown', onPointer, { passive: true });
    document.addEventListener('pointerout', offPointer);
    addEventListener('pointerup', offPointer);
    addEventListener('pointercancel', offPointer);
  }
});

onBeforeUnmount(() => {
  io?.disconnect();
  mo?.disconnect();
  clearTimeout(resizeT);
  if (idleIsTimeout) clearTimeout(idleId);
  else window.cancelIdleCallback?.(idleId);
  document.fonts?.removeEventListener('loadingdone', relayout);
  cancelAnimationFrame(still);
  removeEventListener('resize', onResize);
  document.removeEventListener('visibilitychange', runOrPause);
  removeEventListener('scroll', redraw);
  for (const ev of FF_EVENTS) removeEventListener(ev, fastForward);
  removeEventListener('pointermove', onPointer);
  removeEventListener('pointerdown', onPointer);
  document.removeEventListener('pointerout', offPointer);
  removeEventListener('pointerup', offPointer);
  removeEventListener('pointercancel', offPointer);
  swarm?.destroy();
  swarm = null;
});
</script>

<style scoped>
.ff {
  position: relative;
  isolation: isolate;
  overflow-x: clip;
  --night: #0f0d0a;
  --moon: #f4b04a;
  --cream: #fff2da;
}
.swarm {
  position: fixed;
  inset: 0;
  width: 100%;
  height: 100%;
  z-index: 4;
  pointer-events: none;
}

/* ---- Hero: always night, painted plates + the swarm ---------------------------------------- */
.hero {
  position: relative;
  min-height: calc(100svh - var(--nav-h));
  background: var(--night);
  color: var(--cream);
}
.scene {
  position: absolute;
  inset: 0;
  overflow: hidden;
}
.layer {
  position: absolute;
  max-width: none;
  opacity: 0;
  transition: opacity 0.9s ease;
  will-change: transform;
  user-select: none;
}
.layer.ok {
  opacity: 1;
}
.layer.dawn {
  opacity: 0;
  transition: none;
}
.layer.near {
  z-index: 5;
  filter: blur(1.5px) brightness(0.8);
}
.veil {
  position: absolute;
  inset: 0;
  z-index: 1;
  background: #080604;
}
.flash {
  position: absolute;
  inset: 0;
  z-index: 3;
  opacity: 0;
  background: radial-gradient(
    60% 42% at 50% 32%,
    rgb(255 200 110 / 0.45),
    rgb(242 169 59 / 0.12) 55%,
    transparent 80%
  );
  mix-blend-mode: screen;
}
.fade {
  position: absolute;
  inset: auto 0 0;
  height: 42%;
  z-index: 5;
  opacity: 0;
  background: linear-gradient(to bottom, transparent, var(--paper) 88%);
}

.copy {
  position: absolute;
  z-index: 6;
  inset: clamp(20px, 6.5vh, 80px) 16px auto;
  display: grid;
  justify-items: center;
  text-align: center;
  pointer-events: none;
}
.copy > * {
  pointer-events: auto;
}
.crest {
  width: 52px;
  height: 52px;
  border-radius: 50%;
  background: #111;
  box-shadow:
    0 0 0 1px rgb(244 176 74 / 0.5),
    0 0 28px rgb(244 176 74 / 0.35);
}
.eyebrow {
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 14px 0 0;
  font-size: 12.5px;
  font-weight: 600;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: #efcf9c;
}
.eyebrow i {
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: var(--moon);
  box-shadow: 0 0 8px var(--moon);
}
h1 {
  margin: 6px 0 0;
  display: grid;
  justify-items: center;
  font-weight: inherit;
}
.word {
  display: block;
  font-size: clamp(58px, 12.4vw, 196px);
  font-weight: 760;
  line-height: 1;
  letter-spacing: -0.045em;
  color: var(--cream);
  text-shadow: 0 0 60px rgb(242 169 59 / 0.35);
}
.house {
  margin-top: 0.3em;
  padding-left: 0.6em;
  font-size: clamp(13px, 1.4vw, 19px);
  font-weight: 650;
  letter-spacing: 0.6em;
  text-transform: uppercase;
  color: var(--moon);
}
.line {
  margin: 20px 0 0;
  max-width: 40ch;
  font-size: clamp(16px, 1.45vw, 20px);
  line-height: 1.45;
  text-wrap: balance;
  color: #eadbc3;
  text-shadow: 0 1px 14px rgb(15 13 10 / 0.9);
}

/* Intro: the copy stays in the DOM from frame one; it resolves with the great flash. */
.crest,
.eyebrow,
.house,
.line,
.jump button {
  opacity: 0;
  transition:
    opacity 0.55s var(--ease-out),
    transform 0.55s var(--ease-out);
  transform: translateY(8px);
}
.word {
  opacity: 0;
  filter: blur(16px);
  transition:
    opacity 0.8s ease 0.08s,
    filter 0.8s var(--ease-out) 0.08s;
}
.lit .word {
  opacity: 1;
  filter: blur(0);
}
.jump {
  opacity: 0;
  transition: opacity 0.55s var(--ease-out) 0.2s;
}
.lit .jump {
  opacity: 1;
}
.fast .jump {
  transition-duration: 0.35s;
  transition-delay: 0s;
}
.lit .crest,
.lit .eyebrow,
.lit .house,
.lit .line,
.lit .jump button {
  opacity: 1;
  transform: none;
}
.lit .crest {
  transition-delay: 0.15s;
}
.lit .eyebrow {
  transition-delay: 0.15s;
}
.lit .house {
  transition-delay: 0.15s;
}
.lit .line {
  transition-delay: 0.2s;
}
.lit .jump button {
  transition-delay: calc(0.2s + var(--i) * 40ms);
}
.fast .word,
.fast .crest,
.fast .eyebrow,
.fast .house,
.fast .line,
.fast .jump button {
  transition-duration: 0.35s;
  transition-delay: 0s;
}

.jump {
  position: absolute;
  z-index: 6;
  left: 50%;
  bottom: clamp(20px, 8vh, 72px);
  transform: translateX(-50%);
  display: grid;
  grid-template-columns: repeat(4, auto);
  gap: 6px;
  padding: 6px;
  border-radius: 18px;
  background: rgb(15 13 10 / 0.55);
  border: 1px solid rgb(244 176 74 / 0.22);
  backdrop-filter: blur(8px);
}
.jump button {
  display: grid;
  grid-template-columns: auto auto;
  grid-template-areas: 'k n' 's s';
  align-items: baseline;
  column-gap: 10px;
  padding: 10px 16px;
  border: 0;
  border-radius: 13px;
  background: none;
  color: var(--cream);
  text-align: left;
}
.jump button:hover {
  background: rgb(244 176 74 / 0.12);
}
.jump button:focus-visible {
  outline-color: var(--moon);
}
.jump .k {
  grid-area: k;
  font-weight: 650;
  font-size: 15px;
}
.jump b {
  grid-area: n;
  font-size: 13px;
  font-weight: 500;
  color: var(--moon);
}
.jump small {
  grid-area: s;
  font-size: 12px;
  color: #bfae95;
}

/* ---- The brief: a sticky stage the swarm draws on, copy scrolling beside it ------------------ */
.brief {
  position: relative;
  display: grid;
  grid-template-columns: minmax(0, 1.18fr) minmax(0, 1fr);
  gap: 40px;
  max-width: 1320px;
  margin: 0 auto;
  padding: 0 24px;
}
.stage-col {
  display: grid;
}
.stage-back,
.stage {
  grid-area: 1 / 1;
  align-self: start;
  position: sticky;
  top: var(--nav-h);
  height: calc(100svh - var(--nav-h));
}
.stage-back {
  z-index: 3;
}
.stage {
  z-index: 5;
  pointer-events: none;
}
.plane {
  position: absolute;
  inset: 72px 12px 48px 0;
}
.legend {
  position: absolute;
  top: -40px;
  left: 0;
  display: flex;
  flex-wrap: wrap;
  gap: 4px 16px;
  margin: 0;
  font-size: 12.5px;
  color: var(--ink-2);
  opacity: 0;
  transition: opacity 0.5s;
}
.legend.on {
  opacity: 1;
  transition-delay: 0.5s;
}
.legend span {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}
.legend i {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}
.sw-pyq {
  background: var(--mari-ink);
}
.sw-note {
  background: var(--mari);
}
.sw-meet {
  background: var(--verm);
}
.sw-w {
  background: var(--w);
}
:global(:root[data-theme='dark']) .sw-pyq {
  background: var(--mari);
  box-shadow: 0 0 6px var(--mari);
}
:global(:root[data-theme='dark']) .sw-note {
  background: #fff0d2;
  box-shadow: 0 0 6px #fff0d2;
}
:global(:root[data-theme='dark']) .sw-meet {
  background: #ffc861;
  box-shadow: 0 0 6px #ffc861;
}
.lbl {
  position: absolute;
  white-space: nowrap;
  font-size: 12.5px;
  line-height: 1.2;
  color: var(--ink-2);
  transform: translate(-50%, 0);
}
.lbl b {
  margin-left: 6px;
  font-weight: 500;
  color: var(--mari-ink);
}
.lbl.start {
  transform: translate(-6px, 0);
}
.lbl.city {
  font-weight: 600;
  color: var(--ink);
}
.lbl.city.r {
  transform: translate(0, -50%);
}
.lbl.city.l {
  transform: translate(-100%, -50%);
}
.lbl.city.b {
  transform: translate(-50%, 0);
}
.lbl.tier {
  transform: translate(0, -50%);
  font-weight: 600;
  color: var(--ink);
}
.lbl.node {
  font-size: 11.5px;
}
.lbl.col {
  transform: translate(-50%, -100%);
  font-weight: 700;
  color: var(--mari-ink);
}
.lbl-enter-active {
  transition: opacity 0.5s 0.55s;
}
.lbl-leave-active {
  transition: opacity 0.2s;
}
.lbl-enter-from,
.lbl-leave-to {
  opacity: 0;
}

/* Above the swarm on desktop, so lights in flight pass under the words. */
.copycol {
  position: relative;
  z-index: 6;
  padding: 10vh 0 6vh;
}
.bridge {
  display: flex;
  gap: 12px;
  align-items: baseline;
  max-width: 34ch;
  margin: 0;
  font-size: 18px;
  line-height: 1.45;
  color: var(--ink-2);
}
.bridge .dot {
  flex: none;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--mari);
  box-shadow: 0 0 0 4px var(--mari-soft);
}
.feat {
  display: grid;
  align-content: center;
  gap: 14px;
  min-height: calc(100svh - var(--nav-h));
  padding: 56px 0;
  scroll-margin-top: var(--nav-h);
}
.idx {
  margin: 0;
  font-size: 13px;
  color: var(--mari-ink);
  letter-spacing: 0.04em;
}
.feat h2 {
  margin: 0;
  font-size: clamp(40px, 5vw, 68px);
  font-weight: 760;
  line-height: 0.95;
  letter-spacing: -0.035em;
}
.lead {
  margin: 0;
  max-width: 32ch;
  font-size: clamp(18px, 1.6vw, 22px);
  line-height: 1.4;
  color: var(--ink);
}
.stats {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 32px;
  margin: 6px 0 0;
}
.stats div {
  display: grid;
}
.stats dd {
  margin: 0;
  font-size: clamp(26px, 2.6vw, 36px);
  line-height: 1.1;
  color: var(--ink);
  letter-spacing: -0.03em;
}
.stats dt {
  font-size: 13px;
  color: var(--ink-2);
}
.lights {
  margin: 0;
  max-width: 44ch;
  padding-left: 12px;
  border-left: 2px solid var(--mari);
  font-size: 14.5px;
  line-height: 1.5;
  color: var(--ink-2);
}
.cta {
  justify-self: start;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  margin-top: 6px;
  padding: 12px 20px;
  border: 0;
  border-radius: 99px;
  background: var(--ink);
  color: var(--paper);
  font-size: 15px;
  font-weight: 650;
  transition:
    transform 0.25s var(--ease-spring),
    background 0.2s;
}
.cta:hover {
  transform: translateX(3px);
}
.cta .ic {
  width: 18px;
  height: 18px;
}
.recent,
.uhc,
.tiers {
  display: grid;
  margin: 0;
  padding: 0;
  list-style: none;
}
.recent li {
  display: grid;
  grid-template-columns: 10px 1fr;
  column-gap: 12px;
  padding: 9px 0;
  border-bottom: 1px solid var(--line);
}
.recent i {
  grid-row: span 2;
  width: 8px;
  height: 8px;
  margin-top: 7px;
  border-radius: 50%;
  background: var(--w);
}
.recent b {
  font-weight: 650;
}
.recent span {
  font-size: 13px;
  color: var(--ink-2);
}
.uhc {
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}
.uhc li {
  display: grid;
  justify-items: start;
  gap: 2px;
}
.uhc img {
  width: 56px;
  height: 56px;
  margin-bottom: 6px;
  border-radius: 50%;
  object-fit: cover;
  background: var(--sunk);
  box-shadow:
    0 0 0 2px var(--paper),
    0 0 0 3.5px var(--mari);
}
.uhc b {
  font-size: 14.5px;
  font-weight: 650;
  line-height: 1.2;
}
.uhc span {
  font-size: 12.5px;
  color: var(--ink-2);
}
.tiers li {
  display: grid;
  grid-template-columns: 34px 1fr;
  align-items: baseline;
  padding: 7px 0;
  border-bottom: 1px solid var(--line);
  font-size: 14px;
  color: var(--ink-2);
}
.tiers b {
  font-size: 18px;
  color: var(--mari-ink);
}
.tiers strong {
  color: var(--ink);
  font-weight: 650;
}

/* ---- Close ------------------------------------------------------------------------------------ */
.close {
  position: relative;
  z-index: 2;
  max-width: 1320px;
  margin: 0 auto;
  padding: 40px 24px 40px;
}
.join {
  display: grid;
  justify-items: start;
  gap: 16px;
  padding-top: 56px;
  border-top: 1px solid var(--line);
}
.join h2 {
  margin: 0;
  max-width: 22ch;
  font-size: clamp(28px, 3.6vw, 46px);
  font-weight: 720;
  line-height: 1.05;
  letter-spacing: -0.03em;
}
.wa {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 14px 22px 14px 18px;
  border-radius: 99px;
  background: var(--mari);
  color: var(--on-mari);
  font-weight: 700;
  text-decoration: none;
  box-shadow: 0 10px 30px -12px var(--mari);
  transition: transform 0.25s var(--ease-spring);
}
.wa:hover {
  transform: translateY(-2px);
}
.foot {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px 24px;
  margin-top: 72px;
  padding-top: 20px;
  border-top: 1px solid var(--line);
  font-size: 14px;
  color: var(--ink-2);
}
.foot span {
  margin-right: auto;
}
.foot button,
.foot a {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 0;
  border: 0;
  background: none;
  color: var(--ink);
  font-size: 14px;
  font-weight: 600;
  text-decoration: none;
}
.foot .ic {
  width: 18px;
  height: 18px;
  color: var(--mari-ink);
}

/* ---- Phone: the stage becomes a band under the top bar ---------------------------------------- */
@media (max-width: 760px) {
  .copy {
    inset: clamp(18px, 5vh, 48px) 16px auto;
  }
  .crest {
    width: 44px;
    height: 44px;
  }
  .eyebrow {
    font-size: 11px;
    letter-spacing: 0.14em;
  }
  .word {
    font-size: min(17.2vw, 84px);
  }
  /* Clear of the tab bar (and the prototype switcher above it). */
  .jump {
    left: 16px;
    right: 16px;
    bottom: 124px;
    transform: none;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 2px;
    padding: 4px;
  }
  .jump button {
    grid-template-columns: 1fr;
    grid-template-areas: 'n' 'k';
    justify-items: center;
    padding: 8px 2px;
    text-align: center;
  }
  .jump .k {
    font-size: 12.5px;
  }
  .jump b {
    font-size: 15px;
  }
  .jump small {
    display: none;
  }
  .brief {
    grid-template-columns: minmax(0, 1fr);
    gap: 0;
    padding: 0 16px;
  }
  .stage-col,
  .copycol {
    grid-area: 1 / 1;
  }
  .stage-back,
  .stage {
    height: 44svh;
  }
  .stage-back {
    margin: 0 -16px;
    background: var(--paper);
    border-bottom: 1px solid var(--line);
    box-shadow: 0 14px 20px -18px rgb(29 25 21 / 0.5);
  }
  .plane {
    inset: 40px 0 22px 0;
  }
  .legend {
    top: -30px;
    font-size: 11.5px;
    gap: 2px 12px;
  }
  .lbl {
    font-size: 11px;
  }
  /* Phones: under the band (z 3) that hides it as it scrolls up. */
  .copycol {
    z-index: 2;
    padding: calc(44svh + 28px) 0 24px;
  }
  .feat {
    min-height: 0;
    padding: 36px 0 64px;
    scroll-margin-top: calc(var(--nav-h) + 44svh);
  }
  .feat h2 {
    font-size: 40px;
  }
  .uhc {
    grid-template-columns: minmax(0, 1fr);
  }
  .uhc li {
    grid-template-columns: 56px 1fr;
    column-gap: 12px;
    align-items: center;
  }
  .uhc img {
    grid-row: span 2;
    margin: 0;
  }
  .close {
    padding: 24px 16px 110px;
  }
  .foot span {
    width: 100%;
  }
}

@media (prefers-reduced-motion: reduce) {
  .layer {
    transition: none;
  }
}
</style>
