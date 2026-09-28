<!--
  The Upper House Council on the House page. The three cards start as a hand
  held face down; scrolling spreads them to their seats and turns each one over. It is tied
  to scroll, so it plays back if you scroll up. A strip underneath leads to the Teams page.
-->
<template>
  <div ref="root" class="trio" :class="{ landed }">
    <ol class="seats">
      <li
        v-for="(p, i) in upper"
        :key="p.id"
        :ref="(el) => (seatEls[i] = el)"
        class="seat"
        :style="seatStyle(i)"
      >
        <PersonCard :p="p" size="big" @region="$emit('region', $event)" />
      </li>
    </ol>

    <a class="more" href="#/teams" @click.prevent="nav.go('teams')">
      <span class="faces" aria-hidden="true">
        <img
          v-for="(c, i) in lower"
          :key="c.id"
          :src="portrait.face(c.img)"
          alt=""
          width="34"
          height="34"
          loading="lazy"
          :style="{ '--i': i }"
        />
      </span>
      <span class="t">
        <strong>Meet the teams</strong>
        <small
          >{{ lower.length }} regional coordinators, the communities and the crew, and how the house
          works</small
        >
      </span>
      <LineIcon name="arrow" />
    </a>
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted, reactive, ref } from 'vue';
import PersonCard from './PersonCard.vue';
import LineIcon from './LineIcon.vue';
import { useFitNames } from '../../lib/fit.js';
import { lower, portrait, upper } from '../../lib/house.js';
import { nav } from '../../lib/store.js';

defineEmits(['region']);

const root = ref(null);
const seatEls = [];
const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
const p = ref(reduced ? 1 : 0);
const landed = ref(reduced);
const home = reactive([]); // each seat's offset from the middle of the row, in px
useFitNames(root);

const ease = (t) => 1 - Math.pow(1 - t, 3);
const clamp = (v) => Math.min(1, Math.max(0, v));

// Seat i: its own slice of the scroll, so the three turn over one after another.
function seatStyle(i) {
  const n = upper.length;
  const q = ease(clamp((p.value - i * 0.12) / 0.64));
  const mid = (n - 1) / 2;
  const off = i - mid;
  return {
    '--dx': `${(home[i] ?? 0) * (1 - q)}px`,
    '--dy': `${Math.abs(off) * 18 * (1 - q) + 40 * (1 - q)}px`,
    '--rot': `${off * 9 * (1 - q)}deg`,
    '--flip': `${180 * (1 - clamp((p.value - 0.25 - i * 0.12) / 0.5))}deg`,
    '--s': 0.86 + 0.14 * q,
    zIndex: n - Math.abs(Math.round(off)),
  };
}

// Layout offsets (not bounding boxes), so the cards' own transforms don't skew the result.
function measure() {
  const row = seatEls[0]?.offsetParent;
  if (!row) return;
  const mid = row.scrollLeft + row.clientWidth / 2;
  seatEls.forEach((el, i) => (home[i] = mid - (el.offsetLeft + el.offsetWidth / 2)));
}
function onScroll() {
  if (reduced) return;
  const r = root.value.getBoundingClientRect();
  p.value = clamp((innerHeight * 0.8 - r.top) / (innerHeight * 0.5));
  if (p.value >= 1 && !landed.value) landed.value = true;
}

onMounted(() => {
  measure();
  onScroll();
  addEventListener('scroll', onScroll, { passive: true });
  addEventListener('resize', measure);
});
onBeforeUnmount(() => {
  removeEventListener('scroll', onScroll);
  removeEventListener('resize', measure);
});
</script>

<style scoped>
.trio {
  display: grid;
  gap: 22px;
}
.seats {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: clamp(14px, 2.4vw, 28px);
  max-width: 820px;
  margin: 0;
  padding: 0;
  list-style: none;
  position: relative;
  perspective: 1400px;
}
.seat {
  position: relative;
  transform-style: preserve-3d;
  transform: translate(var(--dx), var(--dy)) rotate(var(--rot)) rotateY(var(--flip)) scale(var(--s));
  will-change: transform;
}
/* Once all three are seated, a single band of light passes over them, left to right. */
.seat::after {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: 16px;
  pointer-events: none;
  background: linear-gradient(
    105deg,
    transparent 35%,
    rgb(255 244 220 / 0.55) 50%,
    transparent 65%
  );
  background-size: 300% 100%;
  background-position: 100% 0;
  opacity: 0;
}
.landed .seat::after {
  animation: sweep 1.3s var(--ease-out) both;
}
.landed .seat:nth-child(2)::after {
  animation-delay: 0.12s;
}
.landed .seat:nth-child(3)::after {
  animation-delay: 0.24s;
}
@keyframes sweep {
  0% {
    opacity: 1;
    background-position: 100% 0;
  }
  100% {
    opacity: 1;
    background-position: -50% 0;
  }
}

.more {
  display: flex;
  align-items: center;
  gap: 16px;
  max-width: 820px;
  padding: 14px 18px 14px 14px;
  border-radius: 18px;
  background: var(--card);
  border: 1px solid var(--line);
  box-shadow: var(--shadow);
  text-decoration: none;
  transition:
    transform 0.3s var(--ease-spring),
    border-color 0.2s;
}
.more:hover {
  transform: translateY(-2px);
  border-color: var(--line-strong);
}
.faces {
  display: flex;
  flex: none;
}
.faces img {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  border: 2px solid var(--card);
  object-fit: cover;
  background: var(--sunk);
  transition: margin 0.45s var(--ease-spring);
  transition-delay: calc(var(--i) * 25ms);
}
.faces img + img {
  margin-left: -14px;
}
.more:hover .faces img + img {
  margin-left: -6px;
}
.t {
  display: grid;
  gap: 1px;
  min-width: 0;
  margin-right: auto;
}
.t strong {
  font-size: 17px;
  font-weight: 700;
  letter-spacing: -0.015em;
}
.t small {
  font-size: 13.5px;
  color: var(--ink-2);
}
.more > :deep(svg) {
  flex: none;
  width: 22px;
  height: 22px;
  transition: transform 0.3s var(--ease-spring);
}
.more:hover > :deep(svg) {
  transform: translateX(4px);
}

/* Phones: the three sit in a swipeable row, one and a bit on screen. */
@media (max-width: 640px) {
  .seats {
    grid-template-columns: repeat(3, 72%);
    overflow-x: auto;
    scroll-snap-type: x mandatory;
    margin: 0 -16px;
    padding: 6px 16px 14px;
    scrollbar-width: none;
  }
  .seat {
    scroll-snap-align: center;
  }
  .faces img:nth-child(n + 6) {
    display: none;
  }
}
@media (prefers-reduced-motion: reduce) {
  .seat {
    transform: none;
  }
  .landed .seat::after {
    animation: none;
  }
}
</style>
