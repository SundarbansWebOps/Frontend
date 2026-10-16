<!-- Decorative marigold fireflies that drift and twinkle over a parent that sets position. -->
<template>
  <div class="fireflies" aria-hidden="true">
    <i
      v-for="(f, n) in dots"
      :key="n"
      :style="{
        left: f.x + '%',
        top: f.y + '%',
        width: f.size + 'px',
        height: f.size + 'px',
        '--d': f.delay + 's',
        '--t': f.dur + 's',
      }"
    />
  </div>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
  count: { type: Number, default: 9 },
});

const MAX = 12;

// Fixed positions and timings so the first render matches on the server and in the browser.
const FIREFLIES = [
  { x: 14, y: 22, delay: 0, dur: 6, size: 5 },
  { x: 82, y: 18, delay: 1.2, dur: 7.5, size: 4 },
  { x: 47, y: 38, delay: 2.4, dur: 5, size: 6 },
  { x: 24, y: 64, delay: 0.6, dur: 4.2, size: 5 },
  { x: 68, y: 56, delay: 3.1, dur: 6.8, size: 7 },
  { x: 88, y: 80, delay: 1.8, dur: 5.5, size: 4 },
  { x: 36, y: 84, delay: 4, dur: 3.6, size: 5 },
  { x: 56, y: 12, delay: 2.9, dur: 8, size: 4 },
  { x: 10, y: 46, delay: 5.2, dur: 4.8, size: 6 },
  { x: 74, y: 36, delay: 0.3, dur: 7.2, size: 5 },
  { x: 52, y: 72, delay: 3.7, dur: 5.9, size: 4 },
  { x: 30, y: 30, delay: 6.1, dur: 3.2, size: 6 },
];

const dots = computed(() =>
  FIREFLIES.slice(0, Math.min(Math.max(Math.floor(props.count), 0), MAX))
);
</script>

<style scoped>
.fireflies {
  position: absolute;
  inset: 0;
  pointer-events: none;
  overflow: hidden;
}

/* No dots at all unless motion is allowed; the animation lives entirely inside this query. */
.fireflies i {
  display: none;
}

@media (prefers-reduced-motion: no-preference) {
  .fireflies i {
    display: block;
    position: absolute;
    border-radius: 50%;
    background: var(--mari);
    box-shadow: 0 0 8px 2px var(--mari-soft);
    opacity: 0.15;
    /* fill-mode both holds the first keyframe through the delay, so dots stay dim until they start. */
    animation:
      drift var(--t) ease-in-out var(--d) infinite both,
      glow var(--t) ease-in-out var(--d) infinite both;
  }
}

@keyframes drift {
  0%,
  100% {
    transform: translate(0, 0);
  }
  50% {
    transform: translate(12px, -14px);
  }
}

@keyframes glow {
  0% {
    opacity: 0.15;
  }
  50% {
    opacity: 0.95;
  }
  100% {
    opacity: 0.2;
  }
}
</style>
