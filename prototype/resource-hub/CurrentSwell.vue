<!--
  PROTOTYPE — Home variant 3 ("Current"): the Events landing stage. Every past event, month by
  month, as tide gauges: each month's water stands as high as the events it held, layered by
  wing, and the tide comes in left to right when the stage arrives. A swell line joins the
  levels; quiet stretches collapse into a narrow ≈.
-->
<template>
  <div ref="wrap" class="sw" :class="{ up: active }">
    <ul class="legend">
      <li v-for="wg in ORDER.slice().reverse()" :key="wg" :class="`w-${wg}`">
        <i />{{ WINGS[wg].label }} <span>{{ perWing[wg] }}</span>
      </li>
    </ul>
    <svg
      v-if="w"
      :viewBox="`0 0 ${w} ${h}`"
      :width="w"
      :height="h"
      role="img"
      :aria-label="`Past events by month, ${firstYear} to ${lastYear}, coloured by wing. Busiest month ${MONTH[busiest.m]} ${busiest.y} with ${busiest.n} events.`"
    >
      <g class="grid">
        <line v-for="n in maxN" :key="n" x1="0" :x2="w" :y1="yOf(n)" :y2="yOf(n)" />
        <text x="0" :y="yOf(maxN) - 6">{{ maxN }} in a month</text>
      </g>
      <g
        v-for="c in months"
        :key="c.key"
        class="gauge"
        :class="{ on: hot === c.key, dim: hot != null && hot !== c.key }"
        :style="{ '--d': `${c.order * 45}ms` }"
      >
        <rect
          class="glass"
          :x="c.x - c.bw / 2"
          :y="yOf(maxN) - 4"
          :width="c.bw"
          :height="base - yOf(maxN) + 4"
          :rx="Math.min(6, c.bw / 2)"
        />
        <g class="water">
          <rect
            v-for="s in c.stack"
            :key="s.wing"
            :class="`w-${s.wing}`"
            :x="c.x - c.bw / 2"
            :y="s.y"
            :width="c.bw"
            :height="s.h"
          />
        </g>
        <text class="n" :x="c.x" :y="c.top - 7" text-anchor="middle">{{ c.n }}</text>
        <rect
          class="hit"
          :x="c.x - c.uw / 2"
          y="0"
          :width="c.uw"
          :height="h"
          @pointerenter="hot = c.key"
          @pointerleave="hot = null"
        />
      </g>
      <path :d="swell" class="swell" />
      <line class="bed" x1="0" :x2="w" :y1="base" :y2="base" />
      <g class="gaps">
        <text v-for="c in gaps" :key="c.key" :x="c.x" :y="base - 6" text-anchor="middle">≈</text>
      </g>
      <g class="years">
        <g v-for="y in years" :key="y.y" :transform="`translate(${y.x} ${base})`">
          <line y1="4" y2="12" />
          <text x="4" y="22">{{ y.y }}</text>
        </g>
      </g>
    </svg>
    <p class="readout" aria-hidden="true">
      <template v-if="hotCol">
        <b>{{ MONTH[hotCol.m] }} {{ hotCol.y }}</b> · {{ hotCol.n }}
        {{ hotCol.n === 1 ? 'event' : 'events' }}: <span>{{ hotCol.titles }}</span>
      </template>
      <template v-else>
        Busiest: <b>{{ MONTH[busiest.m] }} {{ busiest.y }}</b
        >, {{ busiest.n }} events. Point at a month to see what ran.
      </template>
    </p>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import { chartColumns, events, MONTH, monthKey, WINGS } from './events.js';

defineProps({ active: { type: Boolean, default: false } });

const ORDER = ['talks', 'tech', 'games', 'cultural'];
const wrap = ref(null);
const w = ref(0);
const h = ref(0);
const hot = ref(null);
let ro;

onMounted(() => {
  ro = new ResizeObserver(([e]) => {
    w.value = Math.round(e.contentRect.width);
    h.value = Math.round(Math.max(190, Math.min(320, innerHeight * 0.36)));
  });
  ro.observe(wrap.value);
});
onBeforeUnmount(() => ro?.disconnect());

const dated = events.filter((e) => e.at);
const perWing = Object.fromEntries(
  Object.keys(WINGS).map((wg) => [wg, events.filter((e) => e.wing === wg).length])
);
const raw = chartColumns(dated);
const byKey = new Map();
for (const e of dated) {
  const k = monthKey(e);
  if (!byKey.has(k)) byKey.set(k, []);
  byKey.get(k).push(e);
}
const maxN = Math.max(...raw.filter((c) => !c.gap).map((c) => byKey.get(c.key).length));
const firstYear = raw[0].y;
const lastYear = raw.at(-1).y;
const busiest = (() => {
  const c = raw
    .filter((c) => !c.gap)
    .sort((a, b) => byKey.get(b.key).length - byKey.get(a.key).length)[0];
  return { ...c, n: byKey.get(c.key).length };
})();

const PAD_T = 22;
const base = computed(() => h.value - 28);
const yOf = (n) => base.value - (n / maxN) * (base.value - PAD_T);

// Month columns get one unit; a quiet gap gets half, whatever its length.
const cols = computed(() => {
  const units = raw.reduce((s, c) => s + (c.gap ? 0.5 : 1), 0);
  const u = w.value / units;
  let x = 0;
  let order = 0;
  return raw.map((c) => {
    const uw = c.gap ? u / 2 : u;
    const col = { ...c, x: x + uw / 2, uw, bw: Math.max(6, Math.min(26, u * 0.56)), order };
    if (!c.gap) order++;
    x += uw;
    return col;
  });
});
const gaps = computed(() => cols.value.filter((c) => c.gap));
const months = computed(() =>
  cols.value
    .filter((c) => !c.gap)
    .map((c) => {
      const list = byKey.get(c.key);
      let n = 0;
      const stack = [];
      for (const wing of ORDER) {
        const k = list.filter((e) => e.wing === wing).length;
        if (!k) continue;
        stack.push({ wing, y: yOf(n + k), h: yOf(n) - yOf(n + k) });
        n += k;
      }
      return { ...c, n, stack, top: yOf(n) };
    })
);

// The swell: a soft line through every level, dropping to the bed across quiet gaps.
const swell = computed(() => {
  const pts = cols.value.map((c) => {
    if (c.gap) return [c.x, base.value - 2];
    return [c.x, months.value.find((m) => m.key === c.key).top];
  });
  if (!pts.length) return '';
  let d = `M${pts[0][0]} ${pts[0][1]}`;
  for (let i = 0; i < pts.length - 1; i++) {
    const [x0, y0] = pts[i];
    const [x1, y1] = pts[i + 1];
    const mx = (x0 + x1) / 2;
    d += ` C${mx} ${y0} ${mx} ${y1} ${x1} ${y1}`;
  }
  return d;
});

const years = computed(() => {
  const seen = new Set();
  return cols.value
    .filter((c) => !c.gap && !seen.has(c.y) && seen.add(c.y))
    .map((c) => ({ y: c.y, x: c.x - c.bw / 2 }));
});

const hotCol = computed(() => {
  const c = months.value.find((c) => c.key === hot.value);
  if (!c) return null;
  const list = byKey.get(c.key);
  const titles = list
    .slice(0, 2)
    .map((e) => e.title)
    .join(', ');
  return { ...c, titles: list.length > 2 ? `${titles} and ${list.length - 2} more` : titles };
});
</script>

<style scoped>
.sw {
  position: relative;
  display: grid;
  align-content: center;
  gap: 12px;
  height: 100%;
}
svg {
  display: block;
  overflow: visible;
}
.legend {
  display: flex;
  flex-wrap: wrap;
  gap: 6px 16px;
  margin: 0;
  padding: 0;
  list-style: none;
  font-size: 13.5px;
  font-weight: 600;
  color: var(--ink);
}
.legend li {
  display: inline-flex;
  align-items: center;
  gap: 7px;
}
.legend i {
  width: 12px;
  height: 12px;
  border-radius: 3px;
  background: var(--w);
}
.legend span {
  font-family: var(--mono);
  font-size: 12.5px;
  color: var(--ink-2);
}
.grid line {
  stroke: var(--line-strong);
  stroke-dasharray: 1 5;
}
.grid text {
  font-family: var(--mono);
  font-size: 10.5px;
  fill: var(--ink-3);
}
.glass {
  fill: color-mix(in srgb, var(--ink) 4%, transparent);
  stroke: var(--line);
}
.water {
  transform-box: fill-box;
  transform-origin: 50% 100%;
  transform: scaleY(0);
  transition: transform 1.1s var(--ease-spring) var(--d);
}
.up .water {
  transform: none;
}
.water rect {
  fill: var(--w);
  stroke: var(--card);
  stroke-width: 1;
}
.n {
  font-family: var(--mono);
  font-size: 10.5px;
  font-weight: 600;
  fill: var(--ink-2);
  opacity: 0;
  transition: opacity 0.4s calc(var(--d) + 0.7s);
}
.up .n {
  opacity: 1;
}
.gauge {
  transition: opacity 0.2s;
}
.gauge.dim {
  opacity: 0.4;
}
.gauge.on .glass {
  stroke: var(--ink-2);
}
.hit {
  fill: transparent;
}
.swell {
  fill: none;
  stroke: var(--flow);
  stroke-width: 1.5;
  stroke-dasharray: 2 6;
  stroke-linecap: round;
  opacity: 0;
  transition: opacity 0.8s 1.3s;
  animation: drift 1.6s linear infinite;
  pointer-events: none;
}
.up .swell {
  opacity: 0.9;
}
@keyframes drift {
  to {
    stroke-dashoffset: -16;
  }
}
.bed {
  stroke: var(--ink-3);
  stroke-width: 1;
}
.gaps text {
  font-family: var(--mono);
  font-size: 13px;
  fill: var(--ink-3);
}
.years line {
  stroke: var(--ink-3);
}
.years text {
  font-family: var(--mono);
  font-size: 11.5px;
  fill: var(--ink-2);
}
.readout {
  min-height: 2.8em;
  margin: 0;
  font-size: 14px;
  line-height: 1.4;
  color: var(--ink-2);
}
.readout b,
.readout span {
  color: var(--ink);
}
@media (prefers-reduced-motion: reduce) {
  .water {
    transform: none;
    transition: none;
  }
  .swell {
    animation: none;
  }
}
</style>
