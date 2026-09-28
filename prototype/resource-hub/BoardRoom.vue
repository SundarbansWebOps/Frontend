<!--
  PROTOTYPE — Lounge room: the monthly leaderboard. SAMPLE points; names stay blurred outside
  the lounge (they're members' names). The podium rises and the points count up on arrival.
-->
<template>
  <div ref="root" class="board" :class="{ in: shown }">
    <ol class="podium" aria-label="Top three this month (sample)">
      <li v-for="p in PODIUM" :key="p.rank" :class="`r${p.rank}`" :style="{ '--h': p.h }">
        <span class="av">{{ p.init }}</span>
        <span class="nm" aria-hidden="true">{{ p.name }}</span>
        <b class="mono">{{ pts(p.pts) }}</b>
        <span class="block"
          ><em>{{ p.rank }}</em></span
        >
      </li>
    </ol>
    <div class="side">
      <ol class="rest" start="4">
        <li v-for="(p, i) in REST" :key="p.rank" :style="{ '--i': i, '--w': p.pts / REST[0].pts }">
          <span class="rk mono">{{ p.rank }}</span>
          <span class="nm" aria-hidden="true">{{ p.name }}</span>
          <span class="bar"><i /></span>
          <b class="mono">{{ pts(p.pts) }}</b>
        </li>
      </ol>
      <p class="how">
        Points for attending sessions, winning challenges and helping the house. Resets on the 1st.
        Names are visible to members.
      </p>
    </div>
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue';

// Placeholder "names" are blocks of letters, blurred — no real or invented people shown.
const blot = (n) => 'x'.repeat(n);
const PODIUM = [
  { rank: 2, init: '•', name: blot(9), pts: 1640, h: 0.72 },
  { rank: 1, init: '•', name: blot(11), pts: 1985, h: 1 },
  { rank: 3, init: '•', name: blot(8), pts: 1410, h: 0.55 },
];
const REST = [
  [4, 1320, 10],
  [5, 1190, 7],
  [6, 1105, 12],
  [7, 960, 9],
  [8, 870, 8],
].map(([rank, pts, n]) => ({ rank, pts, name: blot(n) }));

const root = ref(null);
const shown = ref(false);
const k = ref(0);
const pts = (v) => Math.round(v * k.value).toLocaleString('en-IN');
const io = new IntersectionObserver(
  ([en]) => {
    if (!en.isIntersecting) return;
    io.disconnect();
    shown.value = true;
    if (matchMedia('(prefers-reduced-motion: reduce)').matches) return (k.value = 1);
    const t0 = performance.now();
    const tick = (t) => {
      const x = Math.min(1, (t - t0) / 1400);
      k.value = 1 - Math.pow(1 - x, 3);
      if (x < 1) requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  },
  { threshold: 0.3 }
);
onMounted(() => io.observe(root.value));
onBeforeUnmount(() => io.disconnect());
</script>

<style scoped>
.board {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: 22px;
  align-items: end;
}
.podium {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  align-items: end;
  gap: 10px;
  height: 300px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.podium li {
  display: grid;
  justify-items: center;
  gap: 4px;
}
.av {
  display: grid;
  place-items: center;
  width: 52px;
  height: 52px;
  border-radius: 50%;
  background: var(--sunk);
  border: 2px solid var(--line-strong);
  color: transparent;
}
.r1 .av {
  width: 62px;
  height: 62px;
  border-color: #f2a93b;
  box-shadow: 0 0 22px rgb(242 169 59 / 0.45);
}
.nm {
  font-size: 14px;
  font-weight: 650;
  filter: blur(4px);
  opacity: 0.8;
  user-select: none;
}
.podium b {
  font-size: 17px;
  font-weight: 600;
  color: #f2a93b;
}
.block {
  display: grid;
  place-items: start center;
  width: 100%;
  height: calc(var(--h) * 150px);
  padding-top: 10px;
  border-radius: 12px 12px 4px 4px;
  background: linear-gradient(180deg, var(--card), var(--sunk));
  border: 1px solid var(--line);
  transform-origin: bottom;
  transform: scaleY(0);
  transition: transform 0.9s var(--ease-spring);
}
.r1 .block {
  background: linear-gradient(180deg, rgb(242 169 59 / 0.35), var(--sunk));
  border-color: rgb(242 169 59 / 0.5);
  transition-delay: 0.25s;
}
.r3 .block {
  transition-delay: 0.1s;
}
.in .block {
  transform: none;
}
.block em {
  font-style: normal;
  font-size: 30px;
  font-weight: 800;
  color: var(--ink-3);
}
.r1 .block em {
  color: #f2a93b;
}
.side {
  display: grid;
  gap: 12px;
}
.rest {
  display: grid;
  gap: 2px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.rest li {
  display: grid;
  grid-template-columns: 24px 110px minmax(0, 1fr) 56px;
  align-items: center;
  gap: 10px;
  padding: 9px 4px;
  border-bottom: 1px solid var(--line);
}
.rk {
  font-size: 13px;
  color: var(--ink-3);
}
.bar {
  height: 6px;
  border-radius: 99px;
  background: var(--sunk);
  overflow: hidden;
}
.bar i {
  display: block;
  height: 100%;
  width: calc(var(--w) * 100%);
  border-radius: 99px;
  background: var(--w-meetups);
  transform-origin: left;
  transform: scaleX(0);
  transition: transform 0.9s var(--ease-out);
  transition-delay: calc(0.3s + var(--i) * 80ms);
}
.in .bar i {
  transform: none;
}
.rest b {
  text-align: right;
  font-size: 14px;
  font-weight: 600;
}
.how {
  margin: 0;
  font-size: 13.5px;
  line-height: 1.5;
  color: var(--ink-2);
}
@media (max-width: 760px) {
  .board {
    grid-template-columns: minmax(0, 1fr);
  }
  .podium {
    height: 260px;
  }
  .rest li {
    grid-template-columns: 24px 90px minmax(0, 1fr) 50px;
  }
}
</style>
