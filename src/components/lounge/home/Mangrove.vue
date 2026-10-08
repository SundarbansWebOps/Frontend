<!--
  The firefly mangrove (verdict section 5): a young sundari, the tree the Sundarbans is named
  after, at the water's edge. By night fireflies blink in the gaps between its leaves (a
  flash and a quick decay, never a constant glow) and a few drift over the water. Once per
  visit, a while after Home is calm, the tree's fireflies flash in unison three times, as
  mangrove fireflies really do. Spec: _notes/motion.md, "Home".
-->
<template>
  <div class="mg" :class="{ sync }">
    <picture>
      <source type="image/avif" :srcset="MANGROVE.avif[mode]" />
      <img :src="MANGROVE[mode]" data-art alt="" draggable="false" decoding="async" />
    </picture>
    <!-- The mud bank the tree stands in: it runs in from the right edge of the screen, the
         stilt roots sink into it and breathing roots poke up through it. Drawn over the
         sprite's root ends, in the roots' own colours (day browns, night plums). -->
    <svg class="bank" viewBox="0 0 900 200" aria-hidden="true">
      <defs>
        <linearGradient :id="`${uid}-mud`" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0.25" class="s-hi" />
          <stop offset="0.6" class="s-mid" />
          <stop offset="0.9" class="s-dk" />
        </linearGradient>
        <linearGradient :id="`${uid}-refl`" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" class="s-dk" stop-opacity="0.5" />
          <stop offset="1" class="s-dk" stop-opacity="0" />
        </linearGradient>
        <clipPath :id="`${uid}-clip`"><path :d="BANK" /></clipPath>
      </defs>
      <path :d="REFL" :fill="`url(#${uid}-refl)`" />
      <path :d="BANK" :fill="`url(#${uid}-mud)`" />
      <g :clip-path="`url(#${uid}-clip)`">
        <path class="dots" :d="TOP" transform="translate(0 12)" />
        <path class="grain" :d="GRAIN" />
        <ellipse v-for="(e, i) in PEBBLES" :key="i" class="pebble" v-bind="e" />
      </g>
      <path class="rim" :d="TOP" />
      <path v-for="(p, i) in SPIKES" :key="i" class="spike" :d="p" />
      <path class="lap" :d="LAPS" />
    </svg>
    <div class="ff" aria-hidden="true">
      <i
        v-for="(f, i) in dots"
        :key="i"
        :style="{
          left: `${f[0]}%`,
          top: `${f[1]}%`,
          '--d': `${PERIODS[i % 4]}s`,
          '--o': `${-((i * 0.73) % 3).toFixed(2)}s`,
        }"
      ></i>
      <template v-if="!lite">
        <b
          v-for="(f, i) in FLIERS"
          :key="`f${i}`"
          :style="{
            left: `${f[0]}%`,
            top: `${f[1]}%`,
            '--t': `${f[2]}s`,
            '--d': `${PERIODS[(i + 1) % 4]}s`,
          }"
          ><i></i
        ></b>
      </template>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, ref, useId, watch } from 'vue';
import { mode } from '../state.js';
import { MANGROVE } from './art.js';
import { lite, rare, reduced } from './motion.js';

defineOptions({ name: 'LoungeMangrove' });

const props = defineProps({
  phone: { type: Boolean, default: false },
  /* true once Home is calm; the sync waits for it. */
  calm: { type: Boolean, default: false },
  visible: { type: Function, default: () => true },
});

/* The bank, in a 900 x 200 viewBox (the tree spans x 142-616 and its sprite ends at y 124).
   TOP is the mud's skyline, from the water at the left tip up to the screen's right edge. */
const TOP =
  'M30 152C70 140 110 100 180 84C250 70 330 66 420 66C520 66 600 72 690 62C780 52 850 46 900 44';
const BANK = `${TOP}L900 168C800 172 700 164 600 170S400 166 300 170S120 164 30 152Z`;
const REFL = 'M40 158C200 170 600 166 900 168L900 196C600 190 220 194 40 158Z';
const GRAIN =
  'M262 108q40-8 80 0M470 98q50-6 100 2M700 90q40-6 80 0M560 130q30-4 60 0M330 140q40-5 80 0M150 128q26-6 52 0M780 124q36-5 72 0';
const LAPS =
  'M8 160q14-6 28 0t28 0M150 178q16-6 32 0t32 0t32 0M390 179q16-6 32 0t32 0M640 177q16-6 32 0t32 0t32 0M840 175q14-5 28 0t28 0';
/* Breathing roots on the open mud either side of the tree: x, the skyline's y there, height. */
const SPIKES = [
  [98, 117, 22],
  [112, 109, 16],
  [624, 67, 22],
  [652, 65, 30],
  [676, 63, 18],
  [712, 60, 26],
  [744, 56, 20],
  [808, 50, 28],
  [846, 47, 18],
].map(
  ([x, y, h]) =>
    `M${x - 5} ${y + 4}Q${x - 1} ${y - h * 0.6} ${x} ${y - h}Q${x + 1} ${y - h * 0.6} ${x + 5} ${y + 4}Z`
);
const PEBBLES = [
  [236, 122, 7, 3],
  [404, 118, 9, 3.5],
  [618, 108, 6, 2.5],
  [748, 104, 8, 3],
  [866, 96, 6, 2.5],
  [520, 150, 7, 3],
].map(([cx, cy, rx, ry]) => ({ cx, cy, rx, ry }));
const uid = useId();

/* Gaps between leaf clusters on art/r6 mangrove (x %, y % of the sprite). */
const DOTS = [
  [22, 13],
  [37, 16],
  [46, 30],
  [59, 22],
  [71, 30],
  [64, 8],
  [30, 42],
  [52, 44],
  [86, 26],
  [10, 8],
];
/* Free fliers over the water by the roots: x, y, drift period. */
const FLIERS = [
  [18, 72, 11],
  [52, 84, 13.5],
  [82, 68, 9.5],
];
const PERIODS = [3.2, 3.75, 4.3, 4.85];
const dots = computed(() => DOTS.slice(0, lite ? (props.phone ? 3 : 4) : props.phone ? 6 : 10));

/* The sync: once per visit, 6s after calm, for three 1.2s flashes. Night only. */
const sync = ref(false);
let synced = false;
let t = 0;
let stop = () => {};
watch(
  () => props.calm && mode.value === 'night',
  (go) => {
    stop();
    clearTimeout(t);
    sync.value = false;
    if (!go || synced || reduced()) return;
    stop = rare(
      () => {
        stop();
        synced = true;
        sync.value = true;
        t = setTimeout(() => (sync.value = false), 3700);
      },
      { first: 6000, min: 6000, max: 9000, when: () => props.visible() }
    );
  },
  { immediate: true }
);
onBeforeUnmount(() => {
  stop();
  clearTimeout(t);
});
</script>

<style scoped>
.mg {
  position: relative;
  width: 100%;
  aspect-ratio: 640 / 1047;
}
.mg img {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}
/* The bank's box: 190% of the tree's width from 30% left of it, its top 84% down the tree. */
.bank {
  position: absolute;
  left: -30%;
  top: 84%;
  width: 190%;
  height: auto;
  aspect-ratio: 900 / 200;
  overflow: visible;
  --mud-hi: #8a5530;
  --mud: #5e3613;
  --mud-dk: #441f13;
  --mud-ink: #260b00;
  --mud-dot: rgb(255 236 172 / 0.85);
  --lap: rgb(255 245 220 / 0.75);
}
:root[data-theme='dark'] .bank {
  --mud-hi: #452538;
  --mud: #2f1323;
  --mud-dk: #230919;
  --mud-ink: #0c040b;
  --mud-dot: rgb(212 183 195 / 0.6);
  --lap: rgb(255 214 150 / 0.4);
}
.s-hi {
  stop-color: var(--mud-hi);
}
.s-mid {
  stop-color: var(--mud);
}
.s-dk {
  stop-color: var(--mud-dk);
}
.bank path {
  stroke-linecap: round;
  stroke-linejoin: round;
}
.bank .rim,
.bank .dots,
.bank .grain,
.bank .lap {
  fill: none;
}
.bank .rim {
  stroke: var(--mud-ink);
  stroke-width: 3.5;
}
.bank .dots {
  stroke: var(--mud-dot);
  stroke-width: 4;
  stroke-dasharray: 0 13;
}
.bank .grain {
  stroke: var(--mud-dk);
  stroke-width: 3;
}
.bank .pebble {
  fill: var(--mud-dk);
  stroke: var(--mud-dot);
  stroke-width: 1.5;
  stroke-opacity: 0.5;
}
.bank .spike {
  fill: var(--mud);
  stroke: var(--mud-ink);
  stroke-width: 2;
}
.bank .lap {
  stroke: var(--lap);
  stroke-width: 2.5;
}
.ff {
  position: absolute;
  inset: 0;
  pointer-events: none;
  opacity: 1;
  transition: opacity 600ms linear 800ms;
}
:root[data-theme='light'] .ff {
  opacity: 0;
  transition-duration: 300ms;
  transition-delay: 0s;
}
:root[data-theme='light'] .ff * {
  animation-play-state: paused;
}
/* A firefly: a static yellow-green dot (no box-shadow), blinking. */
.ff i {
  position: absolute;
  width: 8px;
  height: 8px;
  margin: -4px;
  border-radius: 50%;
  background: radial-gradient(
    circle,
    #f3ffb0 0 1.6px,
    rgb(214 255 120 / 0.55) 2.2px,
    rgb(214 255 120 / 0.12) 3px,
    transparent 4px
  );
  opacity: 0;
  animation: m-blink var(--d) linear var(--o) infinite;
}
.sync .ff > i {
  animation-duration: 1.2s;
  animation-delay: 0s;
  animation-iteration-count: 3;
}
.ff b {
  position: absolute;
  animation: ff-drift var(--t) ease-in-out infinite alternate;
}
.ff b i {
  position: static;
  display: block;
}
@keyframes ff-drift {
  33% {
    transform: translate3d(14px, -10px, 0);
  }
  66% {
    transform: translate3d(-8px, -22px, 0);
  }
  100% {
    transform: translate3d(10px, -6px, 0);
  }
}

@media (prefers-reduced-motion: reduce) {
  .ff i,
  .ff b {
    animation: none;
  }
  .ff i {
    opacity: 0.35;
  }
}
</style>
