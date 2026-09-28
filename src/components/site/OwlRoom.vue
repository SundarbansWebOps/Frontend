<!--
  Lounge room: Night Owl, the reading lounge (9:30 PM every night, English and
  Hindi rooms). The clock is real (IST); the reader counts are SAMPLE. Each reader is a firefly,
  circling the room's painted pat (an owl with its book, a reader in a lamplit boat).
-->
<template>
  <div class="owl">
    <p class="clock">
      <LineIcon name="moon" />
      <span v-if="open"><b>Open now</b> · until 11:30 PM</span>
      <span v-else
        >Opens at <b>9:30 PM</b> · <span class="mono">{{ untilOpen }}</span></span
      >
    </p>
    <div class="rooms">
      <article v-for="r in rooms" :key="r.id" class="room">
        <div class="sky" aria-hidden="true">
          <i v-for="s in STARS" :key="s.k" class="star" :style="s.style" />
          <PatArt class="art" :fig="ART[r.art]" :name="r.art" />
          <i v-for="f in r.n" :key="f" class="fly" :style="FLIES[(f + r.seed) % FLIES.length]" />
        </div>
        <div class="body">
          <h3>{{ r.name }}</h3>
          <p>{{ r.desc }}</p>
          <p class="n">
            <b class="mono">{{ r.n }}</b> {{ open ? 'reading now' : 'reading last night' }}
          </p>
          <button type="button" class="enter" @click="toast('Rooms open to members after sign-in')">
            {{ open ? 'Join the room' : 'Set a reminder' }}
          </button>
        </div>
      </article>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue';
import LineIcon from './LineIcon.vue';
import PatArt from './PatArt.vue';
import { ART } from '../../lib/art.js';
import { toast } from '../../lib/store.js';

const rooms = reactive([
  {
    id: 'en',
    name: 'English room',
    desc: 'Bring your book. Camera off, mic off, reading together.',
    n: 23,
    seed: 0,
    art: 'owl-en',
  },
  {
    id: 'hi',
    name: 'Hindi room',
    desc: 'हिंदी में पढ़ने वालों के लिए — same quiet hour.',
    n: 14,
    seed: 7,
    art: 'owl-hi',
  },
]);

// Minutes past midnight in IST, whatever the viewer's timezone.
const now = ref(Date.now());
const ist = computed(() => {
  const d = new Date(now.value + (330 + new Date().getTimezoneOffset()) * 60e3);
  return d.getHours() * 60 + d.getMinutes() + d.getSeconds() / 60;
});
const open = computed(() => ist.value >= 21.5 * 60 && ist.value < 23.5 * 60);
const untilOpen = computed(() => {
  let m = 21.5 * 60 - ist.value;
  if (m < 0) m += 24 * 60;
  const h = Math.floor(m / 60);
  return `in ${h}h ${String(Math.floor(m % 60)).padStart(2, '0')}m`;
});

// A scatter that doesn't line up: the classic sine hash, fixed per star and firefly.
const r = (k, n) => {
  const x = Math.sin(k * 12.9898 + n * 78.233) * 43758.5453;
  return x - Math.floor(x);
};
const STARS = Array.from({ length: 22 }, (_, k) => ({
  k,
  style: {
    left: `${r(k, 1) * 100}%`,
    top: `${r(k, 2) * 70}%`,
    animationDelay: `${-r(k, 3) * 4}s`,
    opacity: 0.3 + r(k, 4) * 0.6,
  },
}));
const FLIES = Array.from({ length: 40 }, (_, k) => ({
  left: `${6 + r(k, 5) * 88}%`,
  top: `${40 + r(k, 6) * 52}%`,
  animationDuration: `${5 + r(k, 7) * 6}s`,
  animationDelay: `${-r(k, 8) * 8}s`,
  '--dx': `${(r(k, 9) - 0.5) * 40}px`,
  '--dy': `${-10 - r(k, 10) * 30}px`,
}));

let timer;
onMounted(() => {
  timer = setInterval(() => {
    now.value = Date.now();
    for (const rm of rooms)
      if (Math.random() < 0.18)
        rm.n = Math.min(38, Math.max(6, rm.n + (Math.random() < 0.55 ? 1 : -1)));
  }, 1500);
});
onBeforeUnmount(() => clearInterval(timer));
</script>

<style scoped>
.owl {
  display: grid;
  gap: 14px;
}
.clock {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0;
  font-size: 14.5px;
  color: var(--ink-2);
}
.clock :deep(svg) {
  width: 18px;
  height: 18px;
  color: #f2a93b;
}
.clock b {
  color: var(--ink);
}
.rooms {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}
.room {
  overflow: hidden;
  border-radius: 20px;
  background: var(--card);
  border: 1px solid var(--line);
}
.sky {
  position: relative;
  height: 250px;
  overflow: hidden;
  background: linear-gradient(180deg, #0b0a14, #1d1622 60%, #2a1d17);
}
.star {
  position: absolute;
  width: 2px;
  height: 2px;
  border-radius: 50%;
  background: #fff4dc;
  animation: twinkle 4s ease-in-out infinite;
}
@keyframes twinkle {
  50% {
    opacity: 0.1;
  }
}
/* The plate sits low on the right; a faint warm rim keeps its figures reading on the night sky. */
.art {
  position: absolute;
  right: 5%;
  bottom: 6px;
  width: min(58%, 226px);
  filter: drop-shadow(0 0 1px rgb(255 222 170 / 0.45)) drop-shadow(0 0 18px rgb(255 190 110 / 0.12));
}
.fly {
  position: absolute;
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: #ffd488;
  box-shadow: 0 0 8px 2px rgb(255 212 136 / 0.7);
  animation: drift 7s ease-in-out infinite alternate;
}
@keyframes drift {
  0% {
    transform: translate(0, 0);
    opacity: 0.2;
  }
  50% {
    opacity: 1;
  }
  100% {
    transform: translate(var(--dx), var(--dy));
    opacity: 0.35;
  }
}
.body {
  display: grid;
  gap: 4px;
  padding: 16px 18px 18px;
}
h3 {
  margin: 0;
  font-size: 19px;
  font-weight: 700;
}
.body p {
  margin: 0;
  font-size: 14px;
  color: var(--ink-2);
}
.body .n {
  margin-top: 6px;
  color: var(--ink);
}
.n b {
  font-size: 18px;
  color: #f2a93b;
}
.enter {
  justify-self: start;
  margin-top: 10px;
  padding: 9px 16px;
  border: 1.5px solid var(--line-strong);
  border-radius: 99px;
  background: none;
  font-size: 14px;
  font-weight: 650;
  transition: border-color 0.2s;
}
.enter:hover {
  border-color: #f2a93b;
}
@media (max-width: 640px) {
  .rooms {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
