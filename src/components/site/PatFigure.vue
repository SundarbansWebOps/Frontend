<!--
  Home "Pat": one painted cut-out. It paints itself the way a patua works: the black
  keylines go down first (a dry-brush wipe of an ink-only copy), then the colour follows behind the
  same brush. Once painted, its parts (tail, flame, oars…) move on loops that run only while
  `live`. The ink copy is the same plate put through the page's #pat-ink filter, so it costs no
  extra download.
-->
<template>
  <div
    class="fig"
    :class="[name, phase, { sketch, live: live && phase === 'done' }]"
    :style="{ '--ar': ar }"
    aria-hidden="true"
  >
    <div class="plate" :style="plateStyle">
      <div v-if="phase !== 'done'" class="layer ink">
        <img :src="fig.src" alt="" draggable="false" />
        <img
          v-for="pt in fig.parts"
          :key="`i${pt.src}`"
          class="part"
          :src="pt.src"
          alt=""
          draggable="false"
          :style="box(pt)"
        />
      </div>
      <div class="layer color" @animationend.self="onColorEnd">
        <img
          v-for="pt in under"
          :key="pt.src"
          class="part"
          :class="`pt-${pt.cls}`"
          :src="pt.src"
          alt=""
          draggable="false"
          :style="box(pt)"
        />
        <img ref="baseEl" :src="fig.src" alt="" draggable="false" @load="onLoad" />
        <img
          v-for="pt in over"
          :key="pt.src"
          class="part"
          :class="`pt-${pt.cls}`"
          :src="pt.src"
          alt=""
          draggable="false"
          :style="box(pt)"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue';

const props = defineProps({
  fig: { type: Object, required: true },
  name: { type: String, default: '' },
  // Start painting (the parent sets this when the panel scrolls into view).
  paint: Boolean,
  // Skip the painting and show the finished plate (reduced motion, fast-forward).
  instant: Boolean,
  // Show the ink drawing before painting starts (the hero tiger walks in as a line drawing).
  sketch: Boolean,
  live: Boolean,
});
const emit = defineEmits(['painted']);

const [v0, v1] = props.fig.view ?? [0, 1];
const ar = (props.fig.w / (props.fig.h * (v1 - v0))).toFixed(4);
const plateStyle = { top: `${(-v0 / (v1 - v0)) * 100}%`, height: `${100 / (v1 - v0)}%` };
const under = props.fig.parts.filter((pt) => pt.under);
const over = props.fig.parts.filter((pt) => !pt.under);

const box = (pt) => ({
  left: `${pt.x}%`,
  top: `${pt.y}%`,
  width: `${pt.w}%`,
  height: `${pt.h}%`,
  transformOrigin: `${pt.ox}% ${pt.oy}%`,
  '--i': pt.i ?? 0,
});

// wait → paint → done. The colour wipe's animationend (or a fallback timer) finishes it.
const phase = ref(props.instant ? 'done' : 'wait');
const ready = ref(false);
const baseEl = ref(null);
let timer;
let disposed = false;

function onLoad() {
  // Decode off the critical path; a failed decode still lets the plate show.
  (baseEl.value?.decode?.() ?? Promise.resolve())
    .catch(() => {})
    .finally(() => {
      if (!disposed) ready.value = true;
    });
}

const go = computed(() => props.paint && ready.value);
watch(
  go,
  (v) => {
    if (!v || phase.value !== 'wait') return;
    phase.value = 'paint';
    timer = setTimeout(finish, 2600);
  },
  { immediate: true }
);
watch(
  () => props.instant,
  (v) => v && finish()
);

function onColorEnd(e) {
  if (e.animationName.includes('wipe')) finish();
}
function finish() {
  clearTimeout(timer);
  if (phase.value === 'done') return;
  phase.value = 'done';
  emit('painted');
}
onMounted(() => {
  if (baseEl.value?.complete && baseEl.value.naturalWidth) onLoad();
});
onBeforeUnmount(() => {
  disposed = true;
  clearTimeout(timer);
});
</script>

<style scoped>
.fig {
  position: relative;
  aspect-ratio: var(--ar);
  width: 100%;
  overflow: visible;
  user-select: none;
  -webkit-user-select: none;
  filter: var(--art-filter, none);
}
.plate {
  position: absolute;
  left: 0;
  width: 100%;
}
.layer {
  position: absolute;
  inset: 0;
}
.layer > img {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  display: block;
}
.layer > img.part {
  inset: auto;
  height: auto;
}
.part {
  position: absolute;
  will-change: transform;
}

/* ---- Painting: ink first, colour behind the same dry brush ---- */
.ink {
  filter: url(#pat-ink);
}
.wait .layer {
  visibility: hidden;
}
.wait.sketch .ink {
  visibility: visible;
}
.paint .layer {
  -webkit-mask: var(--brush) no-repeat 100% 0 / 250% 100%;
  mask: var(--brush) no-repeat 100% 0 / 250% 100%;
}
.paint .ink {
  animation: wipe 0.9s cubic-bezier(0.45, 0.05, 0.3, 1) both;
}
.paint.sketch .ink {
  animation: none;
  -webkit-mask: none;
  mask: none;
}
.paint .color {
  animation: wipe 1.1s cubic-bezier(0.45, 0.05, 0.3, 1) 0.6s both;
}
@keyframes wipe {
  from {
    -webkit-mask-position: 100% 0;
    mask-position: 100% 0;
  }
  to {
    -webkit-mask-position: 0 0;
    mask-position: 0 0;
  }
}

/* ---- Loops. Paused unless live; the parent flips `live` with the panel's visibility. ---- */
.fig:not(.live) .part,
.done:not(.live) .color {
  animation-play-state: paused;
}

/* Tiger: breathes, sways its tail, turns its head toward the pointer (--look from the page). */
.tiger.done .color {
  transform-origin: 50% 92%;
  animation: breathe 3.8s ease-in-out infinite;
}
@keyframes breathe {
  50% {
    transform: scale(1.006, 1.014);
  }
}
.pt-tail {
  animation: tail 3.4s ease-in-out infinite alternate;
}
@keyframes tail {
  from {
    transform: rotate(-3deg);
  }
  to {
    transform: rotate(3.5deg);
  }
}
.pt-head {
  transform: rotate(calc(var(--look, 0) * 2.2deg)) translateY(calc(var(--look, 0) * -2px));
  transition: transform 0.9s var(--ease-out);
}

/* Reader: the lamp flickers, its rays breathe, loose pages lift in the draught. */
.pt-flame {
  animation: flicker 1.7s linear infinite;
}
@keyframes flicker {
  0%,
  100% {
    transform: scale(1, 1) skewX(0);
  }
  18% {
    transform: scale(0.94, 1.07) skewX(2.5deg);
  }
  33% {
    transform: scale(1.03, 0.95) skewX(-1.5deg);
  }
  52% {
    transform: scale(0.96, 1.05) skewX(-3deg);
  }
  71% {
    transform: scale(1.02, 0.97) skewX(1.5deg);
  }
  86% {
    transform: scale(0.97, 1.08) skewX(-1deg);
  }
}
.pt-rays {
  animation: rays 2.3s ease-in-out infinite;
}
@keyframes rays {
  50% {
    transform: scale(1.08);
    opacity: 0.75;
  }
}
.pt-leaf-a {
  animation: leaf-a 4.6s ease-in-out infinite;
}
@keyframes leaf-a {
  50% {
    transform: translate(-1.5%, -9%) rotate(-3deg);
  }
}
.pt-leaf-b {
  animation: leaf-b 3.1s ease-in-out infinite;
}
@keyframes leaf-b {
  40% {
    transform: rotate(-9deg) scaleY(0.9);
  }
  60% {
    transform: rotate(-7deg) scaleY(0.93);
  }
}
.pt-leaf-c {
  animation: leaf-c 3.7s ease-in-out 0.8s infinite;
}
@keyframes leaf-c {
  45% {
    transform: rotate(5deg) scaleY(0.92);
  }
}

/* Drummers: the dhak keeps a two-beat bar (--beat), the feather plume sways to it. */
.pt-dhak-stick {
  animation: dhak calc(var(--beat, 0.75s) * 2) cubic-bezier(0.5, 0, 0.5, 1) infinite;
}
@keyframes dhak {
  0%,
  100% {
    transform: rotate(-9deg);
  }
  10% {
    transform: rotate(13deg);
  }
  30% {
    transform: rotate(-4deg);
  }
  50% {
    transform: rotate(-9deg);
  }
  60% {
    transform: rotate(10deg);
  }
  78% {
    transform: rotate(-4deg);
  }
}
.pt-plume {
  animation: plume calc(var(--beat, 0.75s) * 4) ease-in-out infinite;
}
@keyframes plume {
  0%,
  100% {
    transform: rotate(-2deg);
  }
  25% {
    transform: rotate(1.5deg);
  }
  50% {
    transform: rotate(-1deg);
  }
  75% {
    transform: rotate(2.5deg);
  }
}

/* Gathering: the boats glide in with the scroll (--arrive 0→1 from the page), then ride the water. */
.pt-boat-l,
.pt-boat-r {
  opacity: calc(0.15 + var(--arrive, 1) * 0.85);
  animation: ride 3.6s ease-in-out infinite;
}
.pt-boat-l {
  translate: calc((1 - var(--arrive, 1)) * -55%) 0;
}
.pt-boat-r {
  translate: calc((1 - var(--arrive, 1)) * 60%) 0;
  animation-delay: -1.4s;
}
@keyframes ride {
  50% {
    transform: translateY(-2.5%) rotate(-1deg);
  }
}

/* Rowers: eight oars pull as one; the bow drummer strikes twice a stroke; the boat surges. */
.pt-oar {
  animation: stroke var(--stroke, 2.4s) cubic-bezier(0.55, 0, 0.35, 1) infinite;
  animation-delay: calc(var(--i) * 18ms);
}
@keyframes stroke {
  0%,
  100% {
    transform: rotate(6deg);
  }
  48% {
    transform: rotate(-5.5deg);
  }
  58% {
    transform: rotate(-5deg);
  }
}
.pt-drum-stick {
  animation: tap calc(var(--stroke, 2.4s) / 2) ease-in-out infinite;
}
@keyframes tap {
  0%,
  100% {
    transform: rotate(-12deg);
  }
  14% {
    transform: rotate(16deg);
  }
  40% {
    transform: rotate(-4deg);
  }
}
.rowers.done .color {
  animation: surge var(--stroke, 2.4s) ease-in-out infinite;
}
@keyframes surge {
  0%,
  100% {
    transform: translate(0, 0) rotate(0);
  }
  45% {
    transform: translate(-0.6%, 0.4%) rotate(-0.25deg);
  }
}

@media (prefers-reduced-motion: reduce) {
  .part,
  .color {
    animation: none !important;
    transition: none !important;
  }
  .pt-boat-l,
  .pt-boat-r {
    translate: none;
    opacity: 1;
  }
}
</style>
