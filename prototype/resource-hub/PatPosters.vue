<!--
  PROTOTYPE — Home "Pat": real event posters pegged to a line like painted frames. Drag it (mouse)
  or swipe it (touch); each poster sways as the drummers' beat runs down the line. Tapping a
  poster opens that event in the Events archive.
-->
<template>
  <div class="line-wrap" :class="{ live }">
    <div
      ref="track"
      class="track"
      :class="{ dragging }"
      @pointerdown="down"
      @click.capture="swallow"
    >
      <button
        v-for="(e, i) in list"
        :key="e.id"
        type="button"
        class="hang"
        :style="{ '--i': i, '--w': `${width(e)}px` }"
        :aria-label="`${e.title}, ${when(e)}`"
        @click="(x) => open(e, x)"
      >
        <svg class="rope" viewBox="0 0 100 14" preserveAspectRatio="none" aria-hidden="true">
          <path d="M0 3 Q50 13 100 3" />
        </svg>
        <span class="swing">
          <i class="peg" aria-hidden="true" />
          <span class="frame">
            <img
              :src="img.card(e.image)"
              alt=""
              loading="lazy"
              decoding="async"
              draggable="false"
            />
          </span>
          <span class="tag">
            <b>{{ e.title }}</b>
            <small>{{ when(e) }}</small>
          </span>
        </span>
      </button>
    </div>
    <p class="hint" aria-hidden="true">Drag the line <LineIcon name="arrow" /></p>
  </div>
</template>

<script setup>
import { onBeforeUnmount, ref } from 'vue';
import LineIcon from './LineIcon.vue';
import { MONTH, ev, events, img } from './events.js';
import { nav } from './store.js';

defineProps({ live: Boolean });

const list = events.filter((e) => e.image);
const when = (e) => (e.at ? `${MONTH[e.m]} ${e.y}` : 'Date not recorded');
const width = (e) => Math.round(188 * Math.min(1.4, Math.max(0.62, e.ratio ?? 0.8)));

// The Events page mounts with this event open (same path as an ?event= deep link).
function open(e, x) {
  ev.origin = { x: x.clientX || innerWidth / 2, y: x.clientY || innerHeight / 2 };
  ev.open = e.id;
  nav.go('events');
}

// Mouse drag scrolls the line; touch keeps native swiping. A drag never counts as a click.
const track = ref(null);
const dragging = ref(false);
let start = null;
let moved = 0;
let releaseTimer;
function down(e) {
  if (e.pointerType !== 'mouse' || e.button !== 0) return;
  clearTimeout(releaseTimer);
  start = { x: e.clientX, left: track.value.scrollLeft };
  moved = 0;
  addEventListener('pointermove', move);
  addEventListener('pointerup', up, { once: true });
  addEventListener('pointercancel', up, { once: true });
}
function move(e) {
  if (!start || !track.value) return;
  const dx = e.clientX - start.x;
  moved = Math.max(moved, Math.abs(dx));
  if (moved > 4) dragging.value = true;
  track.value.scrollLeft = start.left - dx;
}
function up() {
  removeEventListener('pointermove', move);
  removeEventListener('pointercancel', up);
  removeEventListener('pointerup', up);
  start = null;
  releaseTimer = setTimeout(() => {
    dragging.value = false;
    moved = 0;
  });
}
function swallow(e) {
  if (moved > 4) {
    e.stopPropagation();
    e.preventDefault();
    moved = 0;
  }
}
onBeforeUnmount(() => {
  clearTimeout(releaseTimer);
  removeEventListener('pointercancel', up);
  removeEventListener('pointermove', move);
  removeEventListener('pointerup', up);
});
</script>

<style scoped>
.line-wrap {
  position: relative;
}
.track {
  display: flex;
  align-items: flex-start;
  overflow-x: auto;
  overscroll-behavior-x: contain;
  scrollbar-width: none;
  padding: 0 28px 18px;
  cursor: grab;
  scroll-padding-inline: 28px;
}
.track::-webkit-scrollbar {
  display: none;
}
.track.dragging {
  cursor: grabbing;
}
.track.dragging .hang {
  pointer-events: none;
}
.hang {
  position: relative;
  flex: none;
  width: calc(var(--w) + 34px);
  padding: 18px 17px 0;
  border: 0;
  background: none;
  color: inherit;
  text-align: left;
}
.hang:focus-visible {
  outline: none;
}
.hang:focus-visible .frame {
  outline: 3px solid var(--pv);
  outline-offset: 3px;
}
/* One scalloped length of rope per poster; side by side they read as one line. */
.rope {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 16px;
  overflow: visible;
}
.rope path {
  fill: none;
  stroke: var(--pi);
  stroke-width: 2;
  vector-effect: non-scaling-stroke;
}
.swing {
  display: grid;
  gap: 8px;
  transform-origin: 50% -8px;
  animation: sway calc(var(--beat, 0.7s) * 2) ease-in-out infinite;
  animation-delay: calc(var(--i) * 70ms);
  animation-play-state: paused;
}
.live .swing {
  animation-play-state: running;
}
@keyframes sway {
  0%,
  100% {
    transform: rotate(-1.4deg);
  }
  12% {
    transform: rotate(1.8deg);
  }
  50% {
    transform: rotate(-0.8deg);
  }
  62% {
    transform: rotate(1.2deg);
  }
}
.hang:hover .swing {
  animation-duration: 0.9s;
}
.peg {
  position: absolute;
  top: -12px;
  left: 50%;
  width: 9px;
  height: 20px;
  margin-left: -4.5px;
  border: 2px solid var(--pi);
  border-radius: 3px;
  background: var(--pmari);
  z-index: 1;
}
/* A painted frame: ink rule, marigold mat with vermilion dots, ink rule. */
.frame {
  display: block;
  height: 188px;
  padding: 7px;
  border: 2.5px solid var(--pi);
  background:
    radial-gradient(circle, var(--pv) 1.4px, transparent 1.8px) 0 0 / 9px 9px,
    var(--pmari);
  box-shadow: 0 10px 18px -12px rgb(29 25 21 / 0.55);
}
.frame img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
  border: 2px solid var(--pi);
  background: var(--pcard);
  transition: transform 0.4s var(--ease-out);
}
.hang:hover .frame img {
  transform: scale(1.03);
}
.tag {
  display: grid;
  gap: 2px;
  padding: 0 2px;
}
.tag b {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  font-size: 13.5px;
  font-weight: 650;
  line-height: 1.25;
  color: var(--pi);
}
.tag small {
  font-size: 12px;
  color: var(--pi2);
}
.hint {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 6px;
  margin: 4px 28px 0 0;
  font-size: 13px;
  font-weight: 600;
  color: var(--pi2);
}
.hint .ic {
  width: 16px;
  height: 16px;
}
@media (max-width: 760px) {
  .track {
    padding: 0 14px 14px;
  }
  .frame {
    height: 150px;
  }
  .hang {
    width: calc(var(--w) * 0.8 + 30px);
    padding: 18px 15px 0;
  }
  .hint {
    margin-right: 14px;
  }
}
@media (prefers-reduced-motion: reduce) {
  .swing {
    animation: none;
  }
}
</style>
