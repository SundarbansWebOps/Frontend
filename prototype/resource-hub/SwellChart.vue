<!--
  PROTOTYPE — the house's history as a swell. Every past event is a poster bubble that rises
  out of the waterline into its month; the swell behind them is how busy the house was.
  Filtering sinks the other bubbles and the swell re-settles. Quiet stretches collapse into ≈.
-->
<template>
  <div ref="scroller" class="scroller">
    <div
      ref="root"
      class="swell"
      :class="{ ready, settled }"
      :style="{ width: `${geo.innerW}px`, height: `${geo.H}px` }"
    >
      <svg class="sea" :width="geo.innerW" :height="geo.H" aria-hidden="true">
        <defs>
          <linearGradient id="swell-fill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stop-color="var(--mari)" stop-opacity="0.34" />
            <stop offset="1" stop-color="var(--mari)" stop-opacity="0.06" />
          </linearGradient>
          <linearGradient id="deep" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stop-color="var(--ink)" stop-opacity="0.07" />
            <stop offset="1" stop-color="var(--ink)" stop-opacity="0" />
          </linearGradient>
        </defs>
        <rect
          v-for="c in geo.cols.filter((c) => c.key === hotKey)"
          :key="'hot' + c.key"
          class="band"
          :x="c.x - geo.unit / 2"
          :y="0"
          :width="geo.unit"
          :height="geo.waterY"
          rx="10"
        />
        <path class="swell-area" :d="paths.area" />
        <path class="swell-line" :d="paths.line" />
        <rect class="deep" x="0" :y="geo.waterY" :width="geo.innerW" :height="geo.reflH" />
        <path class="water" :d="paths.water" pathLength="1" />
        <path class="water flow" :d="paths.water" />
        <g class="gaps">
          <g v-for="c in geo.cols.filter((c) => c.gap)" :key="c.key">
            <path
              class="gap-wave"
              :d="`M${c.x - 9} ${geo.waterY + 18} q4.5 -5 9 0 t9 0 M${c.x - 9} ${geo.waterY + 25} q4.5 -5 9 0 t9 0`"
            />
          </g>
        </g>
      </svg>

      <!-- Reflections: the same bubbles, mirrored and fading into the water. -->
      <div class="reflect" :style="{ top: `${geo.waterY}px`, height: `${geo.reflH}px` }">
        <span
          v-for="b in bubbles.filter((b) => b.on && b.i < 2)"
          :key="'r' + b.e.id"
          class="rb"
          :class="`w-${b.e.wing}`"
          :style="{
            width: `${geo.D}px`,
            height: `${geo.D}px`,
            transform: `translate(${b.x - geo.D / 2}px, ${geo.waterY - b.y - geo.D / 2 + 2}px)`,
          }"
        >
          <img v-if="b.e.image" :src="img.thumb(b.e.image)" alt="" />
        </span>
      </div>

      <button
        v-for="b in bubbles"
        :key="b.e.id"
        type="button"
        class="bub"
        :class="[`w-${b.e.wing}`, { off: !b.on, hot: ev.hover === b.e.id, noimg: !b.e.image }]"
        :style="{
          width: `${geo.D}px`,
          height: `${geo.D}px`,
          '--x': `${b.x - geo.D / 2}px`,
          '--y': `${b.y - geo.D / 2}px`,
          '--y0': `${geo.waterY - geo.D / 2}px`,
          '--d': `${b.delay}ms`,
          '--bob': `${-(b.k % 7) * 0.45}s`,
          zIndex: ev.hover === b.e.id ? 30 : 10 + b.i,
        }"
        :tabindex="b.on ? 0 : -1"
        :aria-label="`${b.e.title}, ${fullDate(b.e)}`"
        @mouseenter="ev.hover = b.e.id"
        @mouseleave="ev.hover = null"
        @focus="ev.hover = b.e.id"
        @blur="ev.hover = null"
        @click="$emit('open', b.e.id, $event)"
      >
        <span class="bob">
          <img v-if="b.e.image" :src="img.thumb(b.e.image)" alt="" decoding="async" />
          <b v-else>{{ initials(b.e.title) }}</b>
        </span>
      </button>

      <Transition name="tip">
        <div
          v-if="tip"
          :key="tip.e.id"
          class="tip"
          :class="[`w-${tip.e.wing}`, tip.side]"
          :style="{ left: `${tip.x}px`, top: `${tip.y}px` }"
          role="presentation"
        >
          <small><i />{{ WINGS[tip.e.wing].label }} · {{ fullDate(tip.e) }}</small>
          <strong>{{ tip.e.title }}</strong>
        </div>
      </Transition>

      <div class="axis" :style="{ top: `${geo.waterY + geo.reflH}px` }">
        <template v-for="c in geo.cols" :key="'a' + c.key">
          <span
            v-if="c.gap"
            class="gap-lbl"
            :style="{ left: `${c.x}px` }"
            :title="`${c.months} quiet ${c.months === 1 ? 'month' : 'months'}`"
            >{{ c.months }}mo</span
          >
          <button
            v-else
            type="button"
            class="mon"
            :class="{ yr: c.showYear, empty: !c.n }"
            :style="{ left: `${c.x}px` }"
            :aria-label="`Jump to ${monthLong(c.m)} ${c.y}`"
            @click="$emit('jump', c.key)"
          >
            <span>{{ MONTH[c.m] }}</span>
            <small v-if="c.showYear">{{ c.y }}</small>
          </button>
        </template>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import { MONTH, WINGS, chartColumns, ev, fullDate, img, monthKey, monthLong } from './events.js';

const props = defineProps({
  list: { type: Array, required: true }, // every dated event (positions stay stable)
  active: { type: Object, default: null }, // Set of ids that match the filter, or null
});
defineEmits(['open', 'jump']);

const scroller = ref(null);
const root = ref(null);
const width = ref(1100);
const ready = ref(false);
const settled = ref(false);
const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;

const baseCols = computed(() => chartColumns(props.list));
const isOn = (e) => !props.active || props.active.has(e.id);

const geo = computed(() => {
  const cols = baseCols.value;
  const units = cols.reduce((n, c) => n + (c.gap ? 0.7 : 1), 0);
  const pad = 22;
  const unit = Math.max(44, Math.min(78, (width.value - pad * 2) / units));
  const innerW = Math.max(width.value, units * unit + pad * 2);
  const D = Math.round(Math.min(unit * 0.74, 40));
  const gapY = D + 4;
  const maxStack = Math.max(
    1,
    ...cols.filter((c) => !c.gap).map((c) => props.list.filter((e) => monthKey(e) === c.key).length)
  );
  const waterY = 18 + maxStack * gapY + 14;
  const reflH = 30;
  const H = waterY + reflH + 40;
  let x = (innerW - units * unit) / 2;
  let lastYear = null;
  const out = cols.map((c) => {
    const w = c.gap ? 0.7 : 1;
    const cx = x + (w * unit) / 2;
    x += w * unit;
    if (c.gap) return { ...c, x: cx };
    const n = props.list.filter((e) => monthKey(e) === c.key && isOn(e)).length;
    const showYear = c.y !== lastYear;
    lastYear = c.y;
    return { ...c, x: cx, n, showYear };
  });
  return { cols: out, unit, innerW, D, gapY, waterY, reflH, H };
});

const hotKey = computed(() => {
  const e = ev.hover && props.list.find((x) => x.id === ev.hover);
  return e ? monthKey(e) : null;
});

// Bubble targets. Matching events stack from the waterline up (oldest at the bottom);
// the rest sink below the surface.
const bubbles = computed(() => {
  const g = geo.value;
  const out = [];
  let k = 0;
  g.cols.forEach((c, ci) => {
    if (c.gap) return;
    const items = props.list
      .filter((e) => monthKey(e) === c.key)
      .sort((a, b) => a.at - b.at || a.title.localeCompare(b.title));
    let i = 0;
    for (const e of items) {
      const on = isOn(e);
      const y = on ? g.waterY - 8 - g.D / 2 - i * g.gapY : g.waterY + g.D * 0.2;
      out.push({
        e,
        x: c.x,
        y,
        on,
        i: on ? i : 9,
        k: k++,
        delay: settled.value ? ci * 14 : ci * 55 + i * 80,
      });
      if (on) i++;
    }
  });
  return out;
});

// The swell: a smooth envelope over the stacks, tweened when the filter changes.
const levels = ref([]);
const target = computed(() =>
  geo.value.cols.map((c) => (c.gap ? 0 : c.n ? c.n * geo.value.gapY + 10 : 0))
);
let tween = null;
// `stagger` delays each column so, on first load, the swell rises with its own bubbles.
function animateLevels(to, dur = 700, delay = 0, stagger = 0) {
  cancelAnimationFrame(tween);
  const from = levels.value.length === to.length ? [...levels.value] : to.map(() => 0);
  if (reduce) {
    levels.value = to;
    return;
  }
  const t0 = performance.now() + delay;
  const step = (t) => {
    let done = true;
    levels.value = to.map((v, i) => {
      const k = Math.max(0, Math.min(1, (t - t0 - i * stagger) / dur));
      if (k < 1) done = false;
      return from[i] + (v - from[i]) * (1 - Math.pow(1 - k, 3));
    });
    if (!done) tween = requestAnimationFrame(step);
  };
  tween = requestAnimationFrame(step);
}
watch(target, (to) => ready.value && animateLevels(to));

// A slow ripple on the surface. Paused off-screen and under reduced motion.
const phase = ref(0);
let raf = null;
let visible = true;
function loop(t) {
  phase.value = t / 1400;
  raf = visible ? requestAnimationFrame(loop) : null;
}

function smooth(pts, maxY = Infinity) {
  if (pts.length < 2) return '';
  let d = `M${pts[0][0].toFixed(1)} ${pts[0][1].toFixed(1)}`;
  for (let i = 0; i < pts.length - 1; i++) {
    const p0 = pts[i - 1] ?? pts[i];
    const p1 = pts[i];
    const p2 = pts[i + 1];
    const p3 = pts[i + 2] ?? p2;
    // Clamping the control points keeps the curve inside their hull: no dips below water.
    const c1 = [p1[0] + (p2[0] - p0[0]) / 6, Math.min(maxY, p1[1] + (p2[1] - p0[1]) / 6)];
    const c2 = [p2[0] - (p3[0] - p1[0]) / 6, Math.min(maxY, p2[1] - (p3[1] - p1[1]) / 6)];
    d += ` C${c1[0].toFixed(1)} ${c1[1].toFixed(1)} ${c2[0].toFixed(1)} ${c2[1].toFixed(1)} ${p2[0].toFixed(1)} ${p2[1].toFixed(1)}`;
  }
  return d;
}

const paths = computed(() => {
  const g = geo.value;
  const lv = levels.value.length === g.cols.length ? levels.value : g.cols.map(() => 0);
  const ph = phase.value;
  const ripple = (x, a) => Math.sin(x / 38 + ph) * a + Math.sin(x / 17 - ph * 1.3) * a * 0.4;
  const pts = [[0, g.waterY]];
  g.cols.forEach((c, i) => pts.push([c.x, g.waterY - lv[i] + (lv[i] ? ripple(c.x, 1.6) : 0)]));
  pts.push([g.innerW, g.waterY]);
  const line = smooth(pts, g.waterY);
  const water = [];
  for (let x = 0; x <= g.innerW; x += 24) water.push([x, g.waterY + ripple(x, 1.8)]);
  if (water.at(-1)[0] !== g.innerW) water.push([g.innerW, g.waterY + ripple(g.innerW, 1.8)]);
  return {
    line,
    area: `${line} L${g.innerW} ${g.waterY} L0 ${g.waterY} Z`,
    water: smooth(water),
  };
});

const tip = computed(() => {
  const b = bubbles.value.find((x) => x.e.id === ev.hover && x.on);
  if (!b) return null;
  const g = geo.value;
  const side = b.x < 170 ? 'l' : b.x > g.innerW - 170 ? 'r' : '';
  return { e: b.e, x: b.x, y: b.y - g.D / 2 - 14, side };
});

const initials = (t) =>
  t
    .replace(/[^A-Za-z0-9 ]/g, ' ')
    .split(/\s+/)
    .filter((w) => w.length > 2)
    .slice(0, 2)
    .map((w) => w[0].toUpperCase())
    .join('');

let ro;
let io;
onMounted(async () => {
  ro = new ResizeObserver(([e]) => (width.value = e.contentRect.width));
  ro.observe(scroller.value);
  width.value = scroller.value.clientWidth;
  await nextTick();
  requestAnimationFrame(() => {
    // Phones scroll the chart sideways; start at the newest season.
    scroller.value.scrollLeft = scroller.value.scrollWidth;
    ready.value = true;
    animateLevels(target.value, 1100, 120, 55);
    setTimeout(() => (settled.value = true), reduce ? 0 : 2200);
  });
  if (!reduce) {
    io = new IntersectionObserver(([e]) => {
      visible = e.isIntersecting;
      if (visible && !raf) raf = requestAnimationFrame(loop);
    });
    io.observe(root.value);
  }
});
onBeforeUnmount(() => {
  ro?.disconnect();
  io?.disconnect();
  cancelAnimationFrame(raf);
  cancelAnimationFrame(tween);
});

// Keep the hovered bubble in view on phones when a card elsewhere is hovered/focused.
defineExpose({
  reveal(id) {
    const b = bubbles.value.find((x) => x.e.id === id);
    const s = scroller.value;
    if (b && s && s.scrollWidth > s.clientWidth)
      s.scrollTo({ left: b.x - s.clientWidth / 2, behavior: 'smooth' });
  },
});
</script>

<style scoped>
.scroller {
  overflow-x: auto;
  overflow-y: hidden;
  scrollbar-width: none;
  margin: 0 -8px;
  padding: 0 8px;
}
.scroller::-webkit-scrollbar {
  display: none;
}
.swell {
  position: relative;
}
.sea {
  position: absolute;
  inset: 0;
  overflow: visible;
}
.band {
  fill: var(--mari-soft);
  opacity: 0.55;
}
.swell-area {
  fill: url(#swell-fill);
}
.swell-line {
  fill: none;
  stroke: var(--flow);
  stroke-width: 1.5;
  stroke-opacity: 0.55;
}
.deep {
  fill: url(#deep);
}
.water {
  fill: none;
  stroke: var(--ink);
  stroke-width: 1.6;
  stroke-linecap: round;
  stroke-dasharray: 1;
  stroke-dashoffset: 1;
  transition: stroke-dashoffset 1.1s var(--ease-out);
}
.ready .water {
  stroke-dashoffset: 0;
}
.water.flow {
  stroke: var(--mari);
  stroke-width: 2.2;
  stroke-dasharray: 3 26;
  stroke-dashoffset: 0;
  opacity: 0;
  transition: opacity 0.6s 1.2s;
  animation: current 3.5s linear infinite;
}
.ready .water.flow {
  opacity: 0.9;
}
@keyframes current {
  to {
    stroke-dashoffset: -58;
  }
}
.gap-wave {
  fill: none;
  stroke: var(--ink-3);
  stroke-width: 1.4;
  stroke-linecap: round;
}

.bub {
  position: absolute;
  left: 0;
  top: 0;
  padding: 0;
  border: 0;
  border-radius: 50%;
  background: none;
  transform: translate(var(--x), var(--y0)) scale(0.2);
  opacity: 0;
  transition:
    transform 0.9s var(--ease-spring),
    opacity 0.5s,
    filter 0.4s;
  transition-delay: var(--d);
}
.ready .bub {
  transform: translate(var(--x), var(--y)) scale(1);
  opacity: 1;
}
.ready .bub.off {
  transform: translate(var(--x), var(--y)) scale(0.4);
  opacity: 0;
  filter: grayscale(1);
  pointer-events: none;
}
.settled .bub {
  transition-duration: 0.7s, 0.4s, 0.4s;
}
.settled .bub.hot {
  transform: translate(var(--x), var(--y)) scale(1.75);
  transition-delay: 0s;
}
.bob {
  display: grid;
  place-items: center;
  width: 100%;
  height: 100%;
  border-radius: 50%;
  overflow: hidden;
  background: var(--w);
  box-shadow:
    0 0 0 2px var(--paper),
    0 0 0 4px var(--w);
  animation: bob 3.2s ease-in-out infinite var(--bob);
}
@keyframes bob {
  50% {
    transform: translateY(-2px);
  }
}
.bob img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.bob b {
  font-size: 12px;
  font-weight: 750;
  letter-spacing: 0.02em;
  color: var(--paper);
}
.bub:focus-visible {
  outline-offset: 5px;
  border-radius: 50%;
}

.reflect {
  position: absolute;
  left: 0;
  right: 0;
  overflow: hidden;
  pointer-events: none;
  -webkit-mask-image:
    linear-gradient(#000 0%, transparent 85%),
    repeating-linear-gradient(#000 0 2px, transparent 2px 4px);
  -webkit-mask-composite: source-in;
  mask-image:
    linear-gradient(#000 0%, transparent 85%),
    repeating-linear-gradient(#000 0 2px, transparent 2px 4px);
  mask-composite: intersect;
  opacity: 0;
  transition: opacity 0.8s 1.4s;
}
.ready .reflect {
  opacity: 0.35;
}
.rb {
  position: absolute;
  left: 0;
  top: 0;
  border-radius: 50%;
  overflow: hidden;
  background: var(--w);
  transition: transform 0.7s var(--ease-out);
}
.rb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transform: scaleY(-1);
  filter: blur(1px);
  animation: waver 2.6s ease-in-out infinite;
}
@keyframes waver {
  50% {
    transform: scaleY(-1) scaleX(1.06) translateX(1px);
  }
}

.tip {
  position: absolute;
  z-index: 40;
  width: max-content;
  max-width: 250px;
  transform: translate(-50%, -100%);
  display: grid;
  gap: 2px;
  padding: 8px 11px 9px;
  border-radius: 10px;
  background: var(--ink);
  color: var(--paper);
  pointer-events: none;
  box-shadow: var(--shadow);
  margin-top: -14px;
}
.tip.l {
  transform: translate(-24px, -100%);
}
.tip.r {
  transform: translate(calc(-100% + 24px), -100%);
}
.tip small {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  opacity: 0.8;
}
.tip small i {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--w);
  box-shadow: 0 0 0 1.5px var(--paper);
}
.tip strong {
  font-size: 14px;
  font-weight: 650;
  line-height: 1.25;
}
.tip-enter-active {
  transition:
    opacity 0.18s,
    margin 0.3s var(--ease-out);
}
.tip-leave-active {
  transition: opacity 0.1s;
}
.tip-enter-from {
  opacity: 0;
  margin-top: -6px;
}
.tip-leave-to {
  opacity: 0;
}

.axis {
  position: absolute;
  left: 0;
  right: 0;
  height: 40px;
}
.mon,
.gap-lbl {
  position: absolute;
  top: 2px;
  transform: translateX(-50%);
  display: grid;
  justify-items: center;
  gap: 1px;
  border: 0;
  background: none;
  padding: 2px 4px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  color: var(--ink-2);
  opacity: 0;
  transition: opacity 0.5s 0.4s;
}
.ready .mon,
.ready .gap-lbl {
  opacity: 1;
}
.mon:hover {
  color: var(--ink);
  background: var(--sunk);
}
.mon.empty {
  color: var(--ink-3);
}
.mon small {
  font-family: var(--mono);
  font-size: 10px;
  font-weight: 500;
  color: var(--ink-3);
}
.gap-lbl {
  top: 6px;
  font-family: var(--mono);
  font-size: 10px;
  font-weight: 500;
  color: var(--ink-3);
}

@media (prefers-reduced-motion: reduce) {
  .bob,
  .rb img,
  .water.flow {
    animation: none;
  }
}
</style>
