<!--
  PROTOTYPE — Home variant 3 ("Current"): the House landing stage. The cities where the house
  meets, placed by latitude and longitude on a small engraved plate (no borders drawn), sized by
  meetups; every city's current runs home to the delta. Beside it, the Upper House Council.
-->
<template>
  <div class="cc" :class="{ up: active }">
    <svg
      class="plate"
      viewBox="0 0 348 400"
      role="img"
      :aria-label="`Regions where the house meets: ${regionList}`"
    >
      <defs>
        <pattern
          :id="`${uid}-h`"
          width="5"
          height="5"
          patternUnits="userSpaceOnUse"
          patternTransform="rotate(-30)"
        >
          <path d="M0 0v5" class="hatch" />
        </pattern>
        <clipPath :id="`${uid}-c`"><rect x="8" y="8" width="332" height="384" /></clipPath>
      </defs>
      <rect class="paper" x="0.75" y="0.75" width="346.5" height="398.5" rx="3" />
      <rect class="rule" x="6" y="6" width="336" height="388" />
      <g :clip-path="`url(#${uid}-c)`">
        <rect x="0" y="0" width="348" height="400" :fill="`url(#${uid}-h)`" class="tex" />
        <g class="grat">
          <line v-for="lo in LONS" :key="'lo' + lo" :x1="X(lo)" :x2="X(lo)" y1="0" y2="400" />
          <line v-for="la in LATS" :key="'la' + la" x1="0" x2="348" :y1="Y(la)" :y2="Y(la)" />
        </g>
        <g class="seas">
          <path v-for="(d, i) in WAVES" :key="i" :d="d" />
          <text :x="X(86.4)" :y="Y(15.2)" text-anchor="middle">Bay of Bengal</text>
          <text :x="X(70.6)" :y="Y(15.6)" text-anchor="middle">Arabian Sea</text>
        </g>
        <path
          v-for="(c, i) in cities"
          :key="'run' + c.id"
          class="run"
          :d="c.run"
          :style="{ '--d': `${400 + i * 90}ms` }"
        />
      </g>
      <g class="ticks">
        <text v-for="lo in LONS" :key="'tl' + lo" :x="X(lo)" y="19" text-anchor="middle">
          {{ lo }}°E
        </text>
        <text v-for="la in LATS" :key="'tt' + la" x="13" :y="Y(la) - 3">{{ la }}°N</text>
      </g>
      <g class="delta" :transform="`translate(${X(DELTA.lon)} ${Y(DELTA.lat)})`">
        <circle r="9" class="halo" />
        <path d="M0 -7L1.6 -1.6 7 0 1.6 1.6 0 7 -1.6 1.6 -7 0 -1.6 -1.6Z" />
        <text x="4" y="21">Sundarbans</text>
      </g>
      <g
        v-for="(c, i) in cities"
        :key="c.id"
        class="city"
        :transform="`translate(${c.x} ${c.y})`"
        :style="{ '--d': `${i * 90}ms` }"
      >
        <circle class="ring" :r="c.r" />
        <circle class="dot" :r="c.r" />
        <text :x="c.left ? -c.r - 5 : c.r + 5" y="4" :text-anchor="c.left ? 'end' : 'start'">
          {{ c.name }}
          <tspan class="n">{{ c.n }}</tspan>
        </text>
      </g>
    </svg>

    <div class="uhc">
      <p class="label">Upper House Council</p>
      <ul>
        <li v-for="(p, i) in upper" :key="p.id" :style="{ '--i': i }">
          <img :src="face(p.img)" alt="" width="64" height="64" loading="lazy" decoding="async" />
          <span
            ><b>{{ p.name }}</b
            ><small>{{ p.role }}</small></span
          >
        </li>
      </ul>
      <p class="hint">Circles grow with meetups held there.</p>
    </div>
  </div>
</template>

<script setup>
import { portrait, regions, upper } from './house.js';

defineProps({ active: { type: Boolean, default: false } });

const uid = `cc${Math.random().toString(36).slice(2, 7)}`;
// Equirectangular with the x scale shrunk by cos(20°), so India isn't stretched wide.
const LON0 = 68;
const LAT1 = 34;
const KX = 348 / 25;
const KY = KX / Math.cos((20 * Math.PI) / 180);
const X = (lon) => (lon - LON0) * KX;
const Y = (lat) => (LAT1 - lat) * KY;
const LONS = [70, 75, 80, 85, 90];
const LATS = [10, 15, 20, 25, 30];
const DELTA = { lat: 21.95, lon: 89.2 };
// Labels that would collide go to the left of their dot.
const LEFT = new Set(['bengaluru', 'kolkata']);

const face = (u) => portrait.face(u)?.replace('w_96,h_96', 'w_160,h_160');

const cities = regions
  .map((r) => {
    const x = X(r.lon);
    const y = Y(r.lat);
    const dx = X(DELTA.lon) - x;
    const dy = Y(DELTA.lat) - y;
    // A gentle bow toward the south, like water finding its way downhill to the delta.
    const cx = x + dx * 0.5 - dy * 0.18;
    const cy = y + dy * 0.5 + Math.abs(dx) * 0.18;
    return {
      id: r.id,
      name: r.name,
      n: r.items.length,
      x,
      y,
      r: 3 + Math.sqrt(r.items.length) * 1.7,
      left: LEFT.has(r.id),
      run: `M${x} ${y} Q${cx} ${cy} ${X(DELTA.lon)} ${Y(DELTA.lat)}`,
    };
  })
  .sort((a, b) => b.n - a.n);
const regionList = cities.map((c) => `${c.name} ${c.n} meetups`).join(', ');

// A few engraved swells in the two seas.
const WAVES = [];
for (const [lon, lat] of [
  [84.5, 17.2],
  [88, 17.8],
  [86, 13.2],
  [89.5, 14.2],
  [71, 17.8],
  [69.8, 13.6],
  [72.6, 12.4],
]) {
  const x = X(lon);
  const y = Y(lat);
  WAVES.push(`M${x} ${y} q5 -4 10 0 t10 0 t10 0`);
}
</script>

<style scoped>
.cc {
  display: grid;
  grid-template-columns: minmax(0, 1.25fr) minmax(200px, 1fr);
  gap: clamp(16px, 3vw, 36px);
  align-items: center;
}
.plate {
  display: block;
  width: 100%;
  max-height: min(56vh, 440px);
  overflow: visible;
}
.paper {
  fill: var(--card);
  stroke: var(--line-strong);
  stroke-width: 1.5;
}
.rule {
  fill: none;
  stroke: var(--ink-3);
  stroke-width: 0.75;
}
.tex {
  opacity: 0.35;
}
.hatch {
  stroke: var(--line);
  stroke-width: 1;
}
.grat line {
  stroke: var(--line-strong);
  stroke-width: 0.6;
  stroke-dasharray: 1 3;
}
.ticks text {
  font-family: var(--mono);
  font-size: 7.5px;
  fill: var(--ink-3);
}
.seas path {
  fill: none;
  stroke: var(--channel);
  stroke-width: 1;
}
.seas text {
  font-size: 9.5px;
  font-style: italic;
  fill: var(--ink-3);
  letter-spacing: 0.04em;
}
.run {
  fill: none;
  stroke: var(--flow);
  stroke-width: 1.2;
  stroke-linecap: round;
  stroke-dasharray: 1.5 5;
  opacity: 0;
  transition: opacity 0.8s var(--d);
  animation: run 1.8s linear infinite;
}
.up .run {
  opacity: 0.7;
}
@keyframes run {
  to {
    stroke-dashoffset: -13;
  }
}
.delta path {
  fill: var(--verm);
}
.delta .halo {
  fill: var(--verm-soft);
  stroke: var(--verm);
  stroke-width: 0.8;
}
.delta text {
  font-size: 10px;
  font-weight: 700;
  font-style: italic;
  fill: var(--verm);
}
.city {
  opacity: 0;
  transition: opacity 0.5s var(--d);
}
.up .city {
  opacity: 1;
}
.dot,
.ring {
  transform-box: fill-box;
  transform-origin: center;
}
.dot {
  fill: var(--mari);
  stroke: var(--ink);
  stroke-width: 1;
  transform: scale(0);
  transition: transform 0.7s var(--ease-spring) var(--d);
}
.up .dot {
  transform: none;
}
.ring {
  fill: none;
  stroke: var(--mari-ink);
  stroke-width: 1;
  opacity: 0;
}
.up .ring {
  animation: ping 3.2s var(--ease-out) calc(var(--d) + 0.6s) infinite;
}
@keyframes ping {
  0% {
    opacity: 0.8;
    transform: scale(1);
  }
  60%,
  100% {
    opacity: 0;
    transform: scale(2.6);
  }
}
.city text {
  font-size: 10.5px;
  font-weight: 650;
  fill: var(--ink);
  paint-order: stroke;
  stroke: var(--card);
  stroke-width: 3px;
  stroke-linejoin: round;
}
.city .n {
  font-family: var(--mono);
  font-weight: 600;
  fill: var(--mari-ink);
}

.label {
  margin: 0 0 12px;
  font-family: var(--mono);
  font-size: 11.5px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--ink-2);
}
.uhc ul {
  display: grid;
  gap: 12px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.uhc li {
  display: flex;
  align-items: center;
  gap: 14px;
  opacity: 0;
  transform: translateX(-16px);
  transition:
    opacity 0.6s var(--ease-out),
    transform 0.7s var(--ease-out);
  transition-delay: calc(0.5s + var(--i) * 0.12s);
}
.up .uhc li {
  opacity: 1;
  transform: none;
}
.uhc img {
  flex: none;
  width: 60px;
  height: 60px;
  border-radius: 50%;
  object-fit: cover;
  background: var(--sunk);
  box-shadow:
    0 0 0 2px var(--paper),
    0 0 0 3.5px var(--mari);
}
.uhc span {
  display: grid;
  line-height: 1.25;
}
.uhc b {
  font-size: 16px;
  font-weight: 700;
}
.uhc small {
  font-size: 13.5px;
  color: var(--ink-2);
}
.hint {
  margin: 16px 0 0;
  font-size: 13px;
  color: var(--ink-3);
}
@media (max-width: 640px) {
  .cc {
    grid-template-columns: 1fr;
  }
  .uhc ul {
    grid-template-columns: repeat(3, 1fr);
  }
  .uhc li {
    flex-direction: column;
    text-align: center;
    gap: 8px;
  }
  .uhc b {
    font-size: 14px;
  }
  .uhc small {
    font-size: 12px;
  }
}
@media (prefers-reduced-motion: reduce) {
  .run,
  .up .ring {
    animation: none;
  }
}
</style>
