<!--
  Where the house meets. Each region is a cluster of meetups placed at its hub
  city (only cities — no borders are drawn). Dots spiral out from the first meetup like tree
  rings, sized by turnout. When the section scrolls in, the season plays: every meetup drops
  in on its date with a ripple, and a meetup with photos pops a polaroid that flies down into
  the season's roll. Drag the tide line to scrub; pick a region to open it.
-->
<template>
  <div class="skybox">
    <div ref="box" class="sky" @pointerleave="tip = null">
      <svg
        v-if="geo"
        :width="geo.W"
        :height="geo.H"
        :viewBox="`0 0 ${geo.W} ${geo.H}`"
        role="group"
        aria-label="Meetups by region"
      >
        <g class="home" :transform="`translate(${geo.home.x} ${geo.home.y})`" aria-hidden="true">
          <circle
            v-for="k in 7"
            :key="k"
            class="ring"
            :r="k * geo.ringStep"
            :style="{ '--k': k }"
          />
        </g>
        <g class="tropic" aria-hidden="true">
          <line x1="0" :x2="geo.W" :y1="geo.tropic" :y2="geo.tropic" />
          <text x="4" :y="geo.tropic - 6">Tropic of Cancer</text>
        </g>

        <g
          v-for="n in geo.nodes"
          :key="n.id"
          class="reg"
          :class="{ sel: house.region === n.id, dim: house.region && house.region !== n.id }"
          :transform="`translate(${n.x} ${n.y})`"
          role="button"
          tabindex="0"
          :aria-label="`${n.name}: ${n.dots.length} meetups`"
          :aria-pressed="house.region === n.id"
          @click="pick(n.id)"
          @keydown.enter.prevent="pick(n.id)"
          @keydown.space.prevent="pick(n.id)"
        >
          <circle class="hit" :r="n.R + 8" />
          <circle class="halo" :r="n.R + 5" />
          <template v-for="d in n.dots" :key="d.m.id">
            <g v-if="d.at <= clock" :transform="`translate(${d.x} ${d.y})`">
              <circle v-if="!reduced" class="ripple" :r="d.r" />
              <circle v-if="d.m.photos.length" class="ph" :r="d.r + 2.6" />
              <circle
                class="dot"
                :class="{
                  big: (d.m.people ?? 0) >= 40,
                  nd: !d.m.at,
                  hot: house.meetup === d.m.id || hover === d.m.id,
                }"
                :r="d.r"
                @pointerenter="show(n, d)"
                @click.stop="pickMeetup(n.id, d.m.id)"
              />
            </g>
          </template>
          <text class="lbl" :x="n.lx" :y="n.ly" :text-anchor="n.anchor">
            <tspan class="nm">{{ n.name }}</tspan>
            <tspan class="ct" dx="5">{{ counts[n.id] }}</tspan>
          </text>
          <text
            v-if="n.id === 'chennai'"
            class="iitm"
            :x="n.lx"
            :y="n.ly + 15"
            :text-anchor="n.anchor"
          >
            ✦ IIT Madras
          </text>
        </g>
      </svg>

      <div
        v-if="tip"
        class="tip"
        :class="tip.side"
        :style="{ left: `${tip.x}px`, top: `${tip.y}px` }"
        role="presentation"
      >
        <img
          referrerpolicy="no-referrer"
          v-if="livePhotos(tip.m).length"
          :src="photo(livePhotos(tip.m)[0], 240, 150)"
          alt=""
          width="240"
          height="150"
        />
        <small class="mono">{{ meetupDate(tip.m) }}</small>
        <strong>{{ tip.m.title }}</strong>
        <span v-if="tip.m.people || tip.m.venue"
          >{{ tip.m.venue }}<template v-if="tip.m.people && tip.m.venue"> · </template
          ><template v-if="tip.m.people">{{ tip.m.people }} students</template></span
        >
      </div>
    </div>

    <div class="roll">
      <p class="roll-h">
        <LineIcon name="photo" />
        <span
          ><b>{{ rolled.length }}</b> of {{ rollTotal }} meetups with photos</span
        >
      </p>
      <TransitionGroup tag="ol" class="frames" :css="false" @enter="flyIn">
        <li v-for="m in rolled" :key="m.id" :data-id="m.id">
          <button
            type="button"
            :title="`${m.title} · ${meetupDate(m)}`"
            @click="openPhotos(m)"
            @pointerenter="hover = m.id"
            @pointerleave="hover = null"
          >
            <img
              referrerpolicy="no-referrer"
              :src="photo(livePhotos(m)[0], 112, 112)"
              alt=""
              width="56"
              height="56"
              loading="lazy"
              @load="$event.target.classList.add('ok')"
              @error="markDead(livePhotos(m)[0], $event)"
            />
            <span class="visually-hidden">Photos of {{ m.title }}</span>
          </button>
        </li>
      </TransitionGroup>
    </div>

    <div class="scrub" :style="{ '--f': P }">
      <button
        type="button"
        class="play"
        :aria-label="playing ? 'Pause' : P >= 1 ? 'Replay the season' : 'Play the season'"
        @click="toggle"
      >
        <LineIcon :name="playing ? 'pause' : P >= 1 ? 'replay' : 'play'" />
      </button>
      <div class="track">
        <input
          type="range"
          min="0"
          max="1000"
          :value="Math.round(P * 1000)"
          aria-label="Scrub through the season"
          :aria-valuetext="clockLabel"
          @input="scrub"
        />
        <div class="ticks" aria-hidden="true">
          <span
            v-for="(k, i) in MONTHS"
            :key="k"
            :class="{ yr: k % 12 === 0 }"
            :style="{ left: `${((i + 0.5) / MONTHS.length) * 100}%` }"
            >{{ MONTH[k % 12] }}</span
          >
        </div>
      </div>
      <output class="clock">
        <b class="mono">{{ clockLabel }}</b>
        <small>{{ shownTotal }} of {{ meetupCount }} meetups</small>
      </output>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import LineIcon from './LineIcon.vue';
import { MONTH } from '../../lib/events.js';
import {
  house,
  meetupCount,
  meetupDate,
  monthLabel,
  livePhotos,
  markDead,
  photo,
  regions,
  season,
  withPhotos,
} from '../../lib/house.js';

const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
const SPAN = season.to - season.from + 1;
const MONTHS = Array.from({ length: SPAN }, (_, i) => season.from + i);

// ---- Layout ------------------------------------------------------------------------------
const box = ref(null);
const width = ref(0);
const COS = Math.cos((22 * Math.PI) / 180);
const LON0 = 72.88;
const LAT1 = 30.73;
// Which side of its cluster each label sits, chosen so neighbours don't collide.
const SIDE = {
  chandigarh: 'n',
  delhi: 'w',
  lucknow: 's',
  patna: 'n',
  kolkata: 's',
  mumbai: 's',
  hyderabad: 'e',
  bengaluru: 'w',
  chennai: 'e',
};

function labelBox(n, w) {
  const g = n.R + 9;
  return {
    n: { lx: 0, ly: -g, anchor: 'middle', bx: -w / 2, by: -g - 13, bw: w },
    s: { lx: 0, ly: g + 12, anchor: 'middle', bx: -w / 2, by: g - 1, bw: w },
    e: { lx: g, ly: 4, anchor: 'start', bx: g, by: -9, bw: w },
    w: { lx: -g, ly: 4, anchor: 'end', bx: -g - w, by: -9, bw: w },
  }[n.side];
}

const geo = computed(() => {
  const W = width.value;
  if (!W) return null;
  const s = Math.min(1.1, Math.max(0.62, W / 560));
  const step = 8.6 * s;
  const radius = (m) => (m.people ? Math.min(2.6 + Math.sqrt(m.people) * 0.5, 6.6) : 3) * s;

  const base = regions.map((r) => {
    const order = [...r.items].sort((a, b) => (a.at ?? Infinity) - (b.at ?? Infinity));
    const dots = order.map((m, j) => {
      const a = j * 2.39996; // golden angle: an even sunflower spiral
      const rr = j === 0 ? 0 : step * Math.sqrt(j + 0.2);
      return {
        m,
        x: Math.cos(a) * rr,
        y: Math.sin(a) * rr,
        r: radius(m),
        at: m.at ? m.y * 12 + m.m + ((m.d ?? 15) - 1) / 31 : season.to + 1,
      };
    });
    const R = dots.reduce((mx, d) => Math.max(mx, Math.hypot(d.x, d.y) + d.r), 6 * s);
    return { id: r.id, name: r.name, lat: r.lat, lon: r.lon, dots, R, side: SIDE[r.id] };
  });

  const pad = 10;
  const top = 26;
  const bottom = 12;
  // Tall enough to read, short enough that map + scrubber fit one screen beside the panel.
  const maxH = Math.max(300, Math.min(innerHeight - 250, 580)) - top - bottom;
  let k = (W - 2 * pad - 140) / ((88.36 - LON0) * COS);
  let nodes;
  let bb;
  for (let pass = 0; pass < 8; pass++) {
    nodes = base.map((b) => {
      const x = (b.lon - LON0) * COS * k;
      const y = (LAT1 - b.lat) * k;
      return { ...b, x, y, ax: x, ay: y };
    });
    // Push overlapping clusters apart, with a gentle pull back to their true city.
    for (let it = 0; it < 160; it++) {
      for (let i = 0; i < nodes.length; i++)
        for (let j = i + 1; j < nodes.length; j++) {
          const a = nodes[i];
          const b = nodes[j];
          const dx = b.x - a.x;
          const dy = b.y - a.y;
          const d = Math.hypot(dx, dy) || 0.01;
          const min = a.R + b.R + 16 * s;
          if (d < min) {
            const push = (min - d) / 2;
            a.x -= (dx / d) * push;
            a.y -= (dy / d) * push;
            b.x += (dx / d) * push;
            b.y += (dy / d) * push;
          }
        }
      for (const n of nodes) {
        n.x += (n.ax - n.x) * 0.02;
        n.y += (n.ay - n.y) * 0.02;
      }
    }
    for (const n of nodes) Object.assign(n, labelBox(n, (n.name.length + 3) * 7.3));
    bb = nodes.reduce(
      (o, n) => ({
        x0: Math.min(o.x0, n.x - n.R, n.x + n.bx),
        x1: Math.max(o.x1, n.x + n.R, n.x + n.bx + n.bw),
        y0: Math.min(o.y0, n.y - n.R, n.y + n.by),
        y1: Math.max(o.y1, n.y + n.R, n.y + n.by + 16),
      }),
      { x0: Infinity, x1: -Infinity, y0: Infinity, y1: -Infinity }
    );
    if (bb.x1 - bb.x0 <= W - 2 * pad && bb.y1 - bb.y0 <= maxH) break;
    k *= 0.9;
  }
  const ox = pad - bb.x0 + (W - 2 * pad - (bb.x1 - bb.x0)) / 2;
  const oy = top - bb.y0;
  for (const n of nodes) {
    n.x += ox;
    n.y += oy;
  }
  const H = bb.y1 - bb.y0 + top + bottom;
  const chennai = nodes.find((n) => n.id === 'chennai');
  return {
    W,
    H,
    nodes,
    tropic: (LAT1 - 23.44) * k + oy,
    home: { x: chennai.x, y: chennai.y },
    ringStep: Math.max(W, H) / 7,
  };
});

// ---- Season playback ---------------------------------------------------------------------
const P = ref(reduced ? 1 : 0);
const playing = ref(false);
const clock = computed(() => season.from + P.value * SPAN);
const clockLabel = computed(() =>
  P.value >= 1 ? 'Whole season' : monthLabel(Math.min(season.to, Math.floor(clock.value)))
);
const counts = computed(() =>
  Object.fromEntries(
    (geo.value?.nodes ?? []).map((n) => [n.id, n.dots.filter((d) => d.at <= clock.value).length])
  )
);
const shownTotal = computed(() => Object.values(counts.value).reduce((a, b) => a + b, 0));

let raf = 0;
function play() {
  if (P.value >= 1) P.value = 0;
  playing.value = true;
  const DUR = 7000;
  const from = P.value;
  const t0 = performance.now() - from * DUR;
  cancelAnimationFrame(raf);
  const tick = (t) => {
    P.value = Math.min(1, (t - t0) / DUR);
    if (P.value < 1 && playing.value) raf = requestAnimationFrame(tick);
    else playing.value = false;
  };
  raf = requestAnimationFrame(tick);
}
function toggle() {
  if (playing.value) {
    playing.value = false;
    cancelAnimationFrame(raf);
  } else play();
}
function scrub(e) {
  playing.value = false;
  cancelAnimationFrame(raf);
  P.value = e.target.value / 1000;
}

// ---- The season's roll -------------------------------------------------------------------
// Meetups with photos, oldest first, as the clock reaches them (undated ones at the end).
const atOf = (m) => (m.at ? m.y * 12 + m.m + ((m.d ?? 15) - 1) / 31 : season.to + 1);
const byTime = [...withPhotos].sort((a, b) => atOf(a) - atOf(b));
const rolled = computed(() => byTime.filter((m) => atOf(m) <= clock.value && livePhotos(m).length));
const rollTotal = computed(() => byTime.filter((m) => livePhotos(m).length).length);
const hover = ref(null);

// While the season plays, each new frame pops up as a polaroid over its dot, hangs there a
// beat, then drops into its slot in the roll. Scrubbing just places frames.
function flyIn(el, done) {
  const m = byTime.find((x) => x.id === el.dataset.id);
  const n = geo.value?.nodes.find((x) => x.id === m.region);
  const d = n?.dots.find((x) => x.m.id === m.id);
  if (!playing.value || reduced || !d) return done();
  const svg = box.value.querySelector('svg').getBoundingClientRect();
  const slot = el.getBoundingClientRect();
  const dx = svg.left + n.x + d.x - (slot.left + slot.width / 2);
  const dy = svg.top + n.y + d.y - (slot.top + slot.height / 2);
  const tilt = ((m.id.length * 7) % 9) - 4;
  el.style.zIndex = 5;
  el.animate(
    [
      { transform: `translate(${dx}px, ${dy}px) scale(0.2) rotate(${tilt}deg)`, opacity: 0 },
      {
        transform: `translate(${dx}px, ${dy - 46}px) scale(1.9) rotate(${tilt}deg)`,
        opacity: 1,
        offset: 0.18,
      },
      {
        transform: `translate(${dx}px, ${dy - 50}px) scale(1.9) rotate(${tilt / 2}deg)`,
        offset: 0.5,
      },
      { transform: 'none', opacity: 1 },
    ],
    { duration: 1500, easing: 'cubic-bezier(.3,.7,.2,1)' }
  ).onfinish = () => {
    el.style.zIndex = '';
    done();
  };
}
function openPhotos(m) {
  house.region = m.region;
  house.meetup = m.id;
  house.photos = { m, i: 0 };
}

// ---- Picking + tooltip -------------------------------------------------------------------
const tip = ref(null);
function show(n, d) {
  const x = n.x + d.x;
  tip.value = { m: d.m, x, y: n.y + d.y - d.r - 8, side: x > geo.value.W * 0.6 ? 'l' : 'r' };
}
function pick(id) {
  house.region = house.region === id ? null : id;
  house.meetup = null;
}
function pickMeetup(region, id) {
  house.region = region;
  house.meetup = id;
}

let ro;
const io = new IntersectionObserver(
  ([en]) => {
    if (en.isIntersecting && !reduced) {
      // Warm the cache so polaroids aren't blank on slow connections, a few at a time (Google
      // refuses bursts). Failures are ignored here — only a real <img> decides a photo is gone.
      byTime.forEach((m, i) =>
        setTimeout(() => {
          const img = new Image();
          img.referrerPolicy = 'no-referrer';
          img.src = photo(m.photos[0], 112, 112);
        }, i * 150)
      );
      play();
      io.disconnect();
    }
  },
  { threshold: 0.35 }
);
onMounted(() => {
  ro = new ResizeObserver(([en]) => (width.value = Math.round(en.contentRect.width)));
  ro.observe(box.value);
  io.observe(box.value);
});
onBeforeUnmount(() => {
  ro?.disconnect();
  io.disconnect();
  cancelAnimationFrame(raf);
});
</script>

<style scoped>
.skybox {
  display: grid;
  gap: 12px;
  padding: 14px 14px 12px;
  border-radius: 22px;
  background: var(--sunk);
}
.sky {
  position: relative;
  min-height: 200px;
}
svg {
  display: block;
  overflow: hidden;
}
.ring {
  fill: none;
  stroke: var(--line-strong);
  stroke-width: 1;
  opacity: 0.55;
  transform-box: view-box;
  animation: breathe 9s ease-in-out infinite;
  animation-delay: calc(var(--k) * -1.1s);
}
@keyframes breathe {
  50% {
    opacity: 0.18;
  }
}
.tropic line {
  stroke: var(--line-strong);
  stroke-dasharray: 2 5;
}
.tropic text {
  font-size: 10.5px;
  fill: var(--ink-3);
  font-family: var(--mono);
}
.reg {
  cursor: pointer;
  outline: none;
  transition: opacity 0.4s var(--ease-out);
}
.reg.dim {
  opacity: 0.32;
}
.hit {
  fill: transparent;
}
.halo {
  fill: none;
  stroke: var(--mari-ink);
  stroke-width: 1.5;
  stroke-dasharray: 3 4;
  opacity: 0;
  transform-box: fill-box;
  transform-origin: center;
  transition: opacity 0.3s;
}
.reg:hover .halo,
.reg:focus-visible .halo {
  opacity: 0.5;
}
.reg.sel .halo {
  opacity: 1;
  animation: spin 18s linear infinite;
}
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
.dot {
  fill: var(--w-meetups);
  stroke: var(--sunk);
  stroke-width: 1.2;
  transform-box: fill-box;
  transform-origin: center;
  animation: drop 0.55s var(--ease-spring) both;
  transition: transform 0.2s var(--ease-spring);
}
.dot.big {
  fill: var(--mari);
}
.dot.nd {
  fill: var(--sunk);
  stroke: var(--w-meetups);
  stroke-dasharray: 2 1.6;
}
.dot:hover,
.dot.hot {
  transform: scale(1.45);
}
.dot.hot {
  stroke: var(--ink);
  stroke-width: 1.6;
}
/* A thin outer ring marks a meetup that has photos. */
.ph {
  fill: none;
  stroke: var(--mari-ink);
  stroke-width: 1;
  opacity: 0.8;
  pointer-events: none;
  transform-box: fill-box;
  transform-origin: center;
  animation: drop 0.7s var(--ease-spring) 0.15s both;
}
@keyframes drop {
  from {
    transform: scale(0);
  }
}
.ripple {
  fill: none;
  stroke: var(--mari-ink);
  stroke-width: 1.4;
  transform-box: fill-box;
  transform-origin: center;
  pointer-events: none;
  animation: ripple 1.1s var(--ease-out) forwards;
}
@keyframes ripple {
  from {
    opacity: 0.9;
    transform: scale(1);
  }
  to {
    opacity: 0;
    transform: scale(4.2);
  }
}
.lbl {
  font-size: 13px;
  font-weight: 700;
  fill: var(--ink);
  paint-order: stroke;
  stroke: var(--sunk);
  stroke-width: 4px;
  stroke-linejoin: round;
}
.lbl .ct {
  font-family: var(--mono);
  font-weight: 500;
  fill: var(--ink-2);
}
.iitm {
  font-size: 10.5px;
  font-family: var(--mono);
  fill: var(--mari-ink);
  paint-order: stroke;
  stroke: var(--sunk);
  stroke-width: 4px;
}

.tip {
  position: absolute;
  z-index: 3;
  display: grid;
  gap: 2px;
  max-width: 240px;
  padding: 9px 11px;
  border-radius: 12px;
  background: var(--ink);
  color: var(--paper);
  font-size: 12.5px;
  pointer-events: none;
  transform: translate(-18px, -100%);
  animation: tipin 0.18s var(--ease-out);
}
.tip.l {
  transform: translate(calc(-100% + 18px), -100%);
}
.tip img {
  display: block;
  width: 100%;
  height: auto;
  margin-bottom: 5px;
  border-radius: 7px;
  background: #3a3027;
  aspect-ratio: 8 / 5;
  object-fit: cover;
}
.tip small {
  font-size: 11px;
  opacity: 0.75;
}
.tip strong {
  font-size: 14px;
  line-height: 1.25;
}
.tip span {
  opacity: 0.8;
}
@keyframes tipin {
  from {
    opacity: 0;
  }
}

/* The season's roll: small polaroids, filled in as the season plays. */
.roll {
  display: grid;
  gap: 8px;
  padding-top: 10px;
  border-top: 1px solid var(--line);
}
.roll-h {
  display: flex;
  align-items: center;
  gap: 6px;
  margin: 0;
  font-size: 12.5px;
  color: var(--ink-2);
}
.roll-h :deep(svg) {
  width: 16px;
  height: 16px;
  color: var(--mari-ink);
}
.roll-h b {
  color: var(--ink);
  font-variant-numeric: tabular-nums;
}
.frames {
  display: flex;
  flex-wrap: wrap;
  gap: 7px;
  min-height: 62px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.frames li {
  position: relative;
}
.frames button {
  display: block;
  padding: 3px 3px 7px;
  border: 0;
  border-radius: 4px;
  background: #fffdf8;
  box-shadow:
    0 1px 2px rgb(29 25 21 / 0.18),
    0 6px 14px -8px rgb(29 25 21 / 0.4);
  transform: rotate(var(--rt, -1.5deg));
  transition: transform 0.3s var(--ease-spring);
}
.frames li:nth-child(3n) button {
  --rt: 2deg;
}
.frames li:nth-child(3n + 1) button {
  --rt: -0.5deg;
}
.frames button:hover,
.frames button:focus-visible {
  transform: rotate(0deg) translateY(-3px) scale(1.12);
}
.frames img {
  display: block;
  opacity: 0;
  transition: opacity 0.3s;
  width: 50px;
  height: 50px;
  object-fit: cover;
  border-radius: 1px;
  background: var(--sunk);
}
.frames img.ok {
  opacity: 1;
}

/* The tide line: a range input dressed as the season's water level. */
.scrub {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto;
  align-items: center;
  gap: 12px;
  padding-top: 10px;
  border-top: 1px solid var(--line);
}
.play {
  display: grid;
  place-items: center;
  width: 38px;
  height: 38px;
  border: 0;
  border-radius: 50%;
  background: var(--ink);
  color: var(--paper);
}
.play :deep(svg) {
  width: 17px;
  height: 17px;
}
.track {
  position: relative;
  height: 38px;
}
.track input {
  position: absolute;
  inset: 0 0 auto;
  width: 100%;
  height: 20px;
  margin: 0;
  background: none;
  appearance: none;
  cursor: pointer;
}
.track input::-webkit-slider-runnable-track {
  height: 6px;
  border-radius: 99px;
  background: linear-gradient(
    90deg,
    var(--mari) calc(var(--f) * 100%),
    var(--line-strong) calc(var(--f) * 100%)
  );
}
.track input::-moz-range-track {
  height: 6px;
  border-radius: 99px;
  background: linear-gradient(
    90deg,
    var(--mari) calc(var(--f) * 100%),
    var(--line-strong) calc(var(--f) * 100%)
  );
}
.track input::-webkit-slider-thumb {
  appearance: none;
  width: 18px;
  height: 18px;
  margin-top: -6px;
  border-radius: 50%;
  background: var(--card);
  border: 2px solid var(--ink);
  box-shadow: var(--shadow);
}
.track input::-moz-range-thumb {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: var(--card);
  border: 2px solid var(--ink);
}
.ticks {
  position: absolute;
  inset: 22px 9px 0;
}
.ticks span {
  position: absolute;
  transform: translateX(-50%);
  font-size: 10.5px;
  color: var(--ink-3);
  font-family: var(--mono);
}
.ticks .yr {
  color: var(--ink);
  font-weight: 600;
}
.clock {
  display: grid;
  justify-items: end;
  min-width: 104px;
}
.clock b {
  font-size: 17px;
  font-weight: 600;
  letter-spacing: -0.03em;
}
.clock small {
  font-size: 11.5px;
  color: var(--ink-2);
  font-variant-numeric: tabular-nums;
}

@media (max-width: 560px) {
  .skybox {
    padding: 10px 8px 10px;
    border-radius: 18px;
  }
  .scrub {
    grid-template-columns: auto minmax(0, 1fr);
  }
  .clock {
    grid-column: 1 / -1;
    grid-row: 1;
    grid-template-columns: auto auto;
    justify-content: space-between;
    align-items: baseline;
  }
  .ticks span:nth-child(odd):not(.yr) {
    visibility: hidden;
  }
}
@media (prefers-reduced-motion: reduce) {
  .ring,
  .reg.sel .halo,
  .dot {
    animation: none;
  }
}
</style>
