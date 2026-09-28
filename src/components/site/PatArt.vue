<!--
  A painted plate outside Home. Paints itself in (ink, then colour) the first time it scrolls
  into view, then runs its part loops only while on screen. Reduced motion shows it finished and
  still. The plate fills the wrapper's width; size it from outside.
-->
<template>
  <div ref="el" class="pa" :style="{ '--brush': `url(${ASSET.brush})` }">
    <PatFigure :fig="fig" :name="name" :paint="seen" :instant="RM" :live="live" />
    <slot />
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue';
import PatFigure from './PatFigure.vue';
import { ASSET } from '../../lib/pat.js';

defineProps({
  fig: { type: Object, required: true },
  name: { type: String, default: '' },
});

const RM = matchMedia('(prefers-reduced-motion: reduce)').matches;
const el = ref(null);
const seen = ref(RM);
const live = ref(false);
let io;
let inView = false;
const vis = () => (live.value = !RM && !document.hidden && inView);

onMounted(() => {
  io = new IntersectionObserver(
    ([en]) => {
      inView = en.isIntersecting;
      if (en.intersectionRatio > 0.3) seen.value = true;
      vis();
    },
    { threshold: [0, 0.3] }
  );
  io.observe(el.value);
  document.addEventListener('visibilitychange', vis);
});
onBeforeUnmount(() => {
  io?.disconnect();
  document.removeEventListener('visibilitychange', vis);
});
</script>

<style scoped>
.pa {
  position: relative;
}
</style>
