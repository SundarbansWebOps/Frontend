<!--
  For events with no real poster. Never a stock photo: the event's own title,
  set large on its wing colour, with ripple rings drawn in SVG.
-->
<template>
  <div class="tp" :class="`w-${e.wing}`">
    <svg class="rings" viewBox="0 0 200 200" aria-hidden="true">
      <circle v-for="r in [22, 44, 66, 88, 110, 132]" :key="r" cx="200" cy="200" :r="r" />
    </svg>
    <small class="mono">{{ WINGS[e.wing].label.toUpperCase() }}</small>
    <strong :style="{ fontSize: size }">{{ e.title }}</strong>
    <span class="foot mono">{{ e.at ? fullDate(e) : e.type }}</span>
  </div>
</template>

<script setup>
import { computed } from 'vue';
import { WINGS, fullDate } from '../../lib/events.js';

const props = defineProps({ e: { type: Object, required: true }, big: Boolean });
const size = computed(() => {
  const n = props.e.title.length;
  const base = n < 14 ? 30 : n < 26 ? 24 : n < 40 ? 20 : 17;
  return `${props.big ? base * 1.5 : base}px`;
});
</script>

<style scoped>
.tp {
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  width: 100%;
  height: 100%;
  padding: 16px;
  overflow: hidden;
  background: var(--w);
  /* --paper is light on the light theme's deep wing colours and dark on the dark theme's
     pale ones, so it is the readable text colour in both. */
  color: var(--paper);
  text-align: left;
}
.rings {
  position: absolute;
  right: 0;
  bottom: 0;
  width: 75%;
  fill: none;
  stroke: var(--paper);
  stroke-opacity: 0.22;
  stroke-width: 1.2;
}
small {
  position: relative;
  font-size: 10px;
  letter-spacing: 0.16em;
  opacity: 0.85;
}
strong {
  position: relative;
  font-weight: 750;
  letter-spacing: -0.03em;
  line-height: 1.02;
  text-wrap: balance;
}
.foot {
  position: relative;
  font-size: 11px;
  opacity: 0.85;
}
</style>
