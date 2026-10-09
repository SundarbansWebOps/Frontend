<!--
  The boat: the one thing that travels through every view (tour, Home, Events). Day art by
  day; by night the boatman's lamp is lit, with one static halo and three reflection dashes
  on the waterline. Spec: _notes/motion.md, "The boat".
    <RiverBoat />                         idle bob, lamp catches on mount at night
    <RiverBoat :catch-lamp="false" />     lamp already lit
    <RiverBoat tappable />                a tap rocks it (no navigation)
  Size it with its wrapper's width. During the Home <-> Events switch it carries
  view-transition-name: boat (lounge.css), so keep one per view.
  Theme switch: the art swaps inside the dissolve; to night the lamp catches as the night is
  about half in (tide.js fadeDelay), to day it fades.
-->
<template>
  <span
    ref="root"
    class="rb"
    :class="[mode, { lit: lampOn, still: !bob, tap: tappable }]"
    :style="{
      '--lx': `${BOAT.lamp.x * 100}%`,
      '--ly': `${BOAT.lamp.y * 100}%`,
      '--ratio': BOAT.ratio,
    }"
    @click="rock"
  >
    <span class="rb-bob">
      <span ref="rockEl" class="rb-rock">
        <span ref="haloEl" class="rb-halo" aria-hidden="true"></span>
        <picture>
          <source type="image/avif" :srcset="BOAT.avif[mode]" />
          <img :src="BOAT[mode]" data-art alt="" draggable="false" />
        </picture>
      </span>
    </span>
    <span ref="reflEl" class="rb-refl" aria-hidden="true"><i></i><i></i><i></i></span>
  </span>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref, watch } from 'vue';
import { mode } from '../state.js';
import { fadeDelay, fadeReady } from '../tide.js';
import { BOAT } from './art.js';
import { animate, reduced } from './motion.js';

const props = defineProps({
  bob: { type: Boolean, default: true },
  catchLamp: { type: Boolean, default: true },
  /* When the lamp catches after mount, ms (Home: as the boat finishes gliding in). */
  lampDelay: { type: Number, default: 1100 },
  tappable: { type: Boolean, default: false },
});

const root = ref(null);
const rockEl = ref(null);
const haloEl = ref(null);
const reflEl = ref(null);
const lampOn = ref(mode.value === 'night');

/* The flame catches: two quick steps, then steady. A hurricane lamp doesn't flicker after. */
let catches = [];
let rocking = null;
let generation = 0;
function catchFlame(delay) {
  catches.forEach((a) => a.cancel());
  catches = [];
  if (reduced()) return;
  const k = [
    { opacity: 0 },
    { opacity: 0.6, offset: 0.2 },
    { opacity: 0.3, offset: 0.4 },
    { opacity: 1 },
  ];
  const o = { duration: 600, delay, easing: 'linear', fill: 'backwards' };
  for (const el of [haloEl.value, reflEl.value]) {
    if (el) catches.push(animate(el, k, o));
  }
}

onMounted(() => {
  if (lampOn.value && props.catchLamp) catchFlame(props.lampDelay);
});

watch(mode, async (m) => {
  const ticket = ++generation;
  catches.forEach((a) => a.cancel());
  lampOn.value = m === 'night';
  /* To night: catches as the night is about half in. To day: CSS fades it. */
  if (m === 'night') {
    await fadeReady();
    if (ticket === generation && root.value) catchFlame(fadeDelay() + 120);
  }
});

function rock() {
  if (!props.tappable || reduced() || !rockEl.value) return;
  rocking?.cancel();
  rocking = animate(
    rockEl.value,
    [
      { transform: 'none' },
      { transform: 'rotate(2deg)', offset: 0.18 },
      { transform: 'rotate(-1.3deg)', offset: 0.42 },
      { transform: 'rotate(0.6deg)', offset: 0.66 },
      { transform: 'rotate(-0.2deg)', offset: 0.84 },
      { transform: 'none' },
    ],
    { duration: 900, easing: 'ease-out' }
  );
}

onBeforeUnmount(() => {
  generation++;
  catches.forEach((a) => a.cancel());
  rocking?.cancel();
});

defineExpose({ el: root, rock });
</script>

<style scoped>
.rb {
  position: relative;
  display: block;
  width: 100%;
  aspect-ratio: var(--ratio);
}
.rb.tap {
  cursor: pointer;
}
.rb-bob,
.rb-rock {
  position: absolute;
  inset: 0;
}
/* At rest on water: 3px, 0.6deg, 6.5s. */
.rb-bob {
  animation: m-bob-boat 6.5s ease-in-out infinite;
}
.still .rb-bob {
  animation: none;
}
.rb-rock {
  transform-origin: 50% 85%;
}
.rb img {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: contain;
  user-select: none;
  -webkit-user-drag: none;
}

/* The lamp's light: one static gradient centred on the flame, 34% of the boat across. */
.rb-halo {
  position: absolute;
  left: var(--lx);
  top: var(--ly);
  width: 34%;
  aspect-ratio: 1;
  border-radius: 50%;
  transform: translate(-50%, -50%);
  background: radial-gradient(
    closest-side,
    rgb(255 220 150 / 0.4),
    rgb(255 176 74 / 0.15) 42%,
    rgb(255 176 74 / 0.05) 66%,
    transparent
  );
  opacity: 0;
  transition: opacity 300ms linear;
  pointer-events: none;
}
/* Three dashes of lamplight on the water, below the lamp, outside the bob (they stay on
   the waterline while the boat moves). */
.rb-refl {
  position: absolute;
  left: var(--lx);
  top: 100%;
  width: 18%;
  min-width: 34px;
  transform: translate(-50%, -6px);
  opacity: 0;
  transition: opacity 300ms linear;
  pointer-events: none;
}
.rb-refl i {
  display: block;
  height: 2.5px;
  margin: 0 auto 6px;
  border-radius: 2px;
  background: #f5ae4b;
  animation: m-shimmer 3.6s ease-in-out infinite alternate;
}
.rb-refl i:nth-child(1) {
  width: 80%;
  opacity: 0.4;
  --shimmer-lo: 0.18;
}
.rb-refl i:nth-child(2) {
  width: 52%;
  opacity: 0.3;
  --shimmer-lo: 0.13;
  animation-duration: 4.3s;
  animation-delay: -1.2s;
}
.rb-refl i:nth-child(3) {
  width: 30%;
  opacity: 0.22;
  --shimmer-lo: 0.1;
  animation-duration: 5.1s;
  animation-delay: -2.4s;
}
.lit .rb-halo,
.lit .rb-refl {
  opacity: 1;
}

:root.lite .rb-refl i {
  animation: none;
}
@media (prefers-reduced-motion: reduce) {
  .rb-bob,
  .rb-refl i {
    animation: none;
  }
}
</style>
