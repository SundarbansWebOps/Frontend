<!--
  Lounge room: live events this week. SAMPLE schedule, placed relative to now so
  there is always something live and something counting down.
-->
<template>
  <div class="live">
    <ol class="week" aria-label="This week">
      <li v-for="d in WEEK" :key="d.k" :class="{ today: d.today }">
        <small>{{ d.dow }}</small>
        <b class="mono">{{ d.date }}</b>
        <span class="pips"><i v-for="n in d.n" :key="n" /></span>
      </li>
    </ol>

    <article class="now">
      <span class="on-air"><i /> Live now</span>
      <h3>{{ SESSIONS[0].title }}</h3>
      <p>{{ SESSIONS[0].what }}</p>
      <div class="bar">
        <span class="mono"
          ><b>{{ inRoom }}</b> in the room</span
        >
        <button type="button" class="join" @click="toast('Join links open after sign-in')">
          Join on Meet <LineIcon name="arrow" />
        </button>
      </div>
    </article>

    <ol class="next">
      <li v-for="(s, i) in SESSIONS.slice(1)" :key="s.title" :style="{ '--i': i }">
        <span class="when">
          <small>{{ s.day }}</small>
          <b class="mono">{{ s.time }}</b>
        </span>
        <span class="what">
          <strong>{{ s.title }}</strong>
          <small>{{ s.what }}</small>
        </span>
        <span class="count mono">{{ countdown(s.at) }}</span>
      </li>
    </ol>
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue';
import LineIcon from './LineIcon.vue';
import { toast } from '../../lib/store.js';

const now = ref(Date.now());
const H = 3600e3;
const base = Date.now();
// The live one started a few minutes ago; the next is on the next quarter hour an hour or so
// out (a countdown you can watch tick); the rest sit at usual evening/morning slots.
const soon = Math.ceil((base + 1.25 * H) / 9e5) * 9e5;
const slot = (day, hh, mm = 0) => new Date(base + day * 864e5).setHours(hh, mm, 0, 0);
const fmt = (t) => new Date(t).toLocaleTimeString('en-IN', { hour: 'numeric', minute: '2-digit' });
const dayOf = (t) => {
  const d = Math.round(
    (new Date(t).setHours(0, 0, 0, 0) - new Date(base).setHours(0, 0, 0, 0)) / 864e5
  );
  return d === 0
    ? 'Today'
    : d === 1
      ? 'Tomorrow'
      : new Date(t).toLocaleDateString('en-IN', { weekday: 'long' });
};
const SESSIONS = [
  {
    title: 'Doubt session · Maths 2',
    what: 'Week 7 graded assignment, worked through',
    t: base - 0.3 * H,
  },
  { title: 'Talk with a senior', what: 'Choosing a diploma: DS or Programming', t: soon },
  { title: 'Technical session', what: 'Git from zero, for the Python OPPE', t: slot(1, 19, 30) },
  { title: 'Cultural night', what: 'Open mic — poetry, songs, stand-up', t: slot(2, 20) },
  { title: 'Sports & fitness', what: 'Morning 5K — run it from your city', t: slot(3, 6, 30) },
].map((s) => ({ ...s, at: s.t, time: fmt(s.t), day: dayOf(s.t) }));

const WEEK = Array.from({ length: 7 }, (_, i) => {
  const d = new Date(base + i * 864e5);
  return {
    k: i,
    dow: d.toLocaleDateString('en-IN', { weekday: 'short' }),
    date: d.getDate(),
    today: i === 0,
    n: SESSIONS.filter((s) => new Date(s.at).toDateString() === d.toDateString()).length,
  };
});

function countdown(t) {
  const s = Math.max(0, Math.round((t - now.value) / 1000));
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const x = s % 60;
  if (h >= 24) return `in ${Math.floor(h / 24)}d ${h % 24}h`;
  return `in ${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(x).padStart(2, '0')}`;
}

// People drift in and out of the live room.
const inRoom = ref(34);
let timer;
onMounted(() => {
  timer = setInterval(() => {
    now.value = Date.now();
    if (Math.random() < 0.35)
      inRoom.value = Math.max(20, inRoom.value + (Math.random() < 0.62 ? 1 : -1));
  }, 1000);
});
onBeforeUnmount(() => clearInterval(timer));
</script>

<style scoped>
.live {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: 16px;
}
.week {
  grid-column: 1 / -1;
  display: grid;
  grid-template-columns: repeat(7, minmax(0, 1fr));
  gap: 6px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.week li {
  display: grid;
  justify-items: center;
  gap: 2px;
  padding: 8px 0 9px;
  border-radius: 12px;
  background: var(--card);
  border: 1px solid var(--line);
}
.week li.today {
  border-color: var(--mari);
  box-shadow: 0 0 0 3px var(--mari-soft);
}
.week small {
  font-size: 11.5px;
  color: var(--ink-2);
}
.week b {
  font-size: 17px;
  font-weight: 600;
}
.pips {
  display: flex;
  gap: 3px;
  height: 5px;
}
.pips i {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: var(--mari);
}
.now {
  position: relative;
  display: grid;
  gap: 6px;
  align-content: start;
  padding: 20px;
  overflow: hidden;
  border-radius: 20px;
  background:
    radial-gradient(120% 140% at 0% 0%, rgb(242 169 59 / 0.22), transparent 60%), var(--card);
  border: 1px solid rgb(242 169 59 / 0.45);
}
.on-air {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  justify-self: start;
  padding: 4px 10px;
  border-radius: 99px;
  background: #b8341b;
  color: #fff4ec;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}
.on-air i {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #fff4ec;
  animation: blink 1.2s ease-in-out infinite;
}
@keyframes blink {
  50% {
    opacity: 0.25;
  }
}
.now h3 {
  margin: 6px 0 0;
  font-size: 24px;
  font-weight: 750;
  letter-spacing: -0.03em;
}
.now p {
  margin: 0;
  color: var(--ink-2);
  font-size: 14.5px;
}
.bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-top: 14px;
}
.bar span {
  font-size: 13px;
  color: var(--ink-2);
}
.bar b {
  display: inline-block;
  min-width: 2ch;
  color: var(--ink);
  font-size: 16px;
}
.join {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  border: 0;
  border-radius: 99px;
  background: #f2a93b;
  color: #1d1915;
  font-weight: 700;
  font-size: 14px;
}
.join :deep(svg) {
  width: 17px;
  height: 17px;
}
.next {
  display: grid;
  gap: 2px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.next li {
  display: grid;
  grid-template-columns: 84px minmax(0, 1fr) auto;
  align-items: center;
  gap: 12px;
  padding: 11px 4px;
  border-bottom: 1px solid var(--line);
}
.when {
  display: grid;
}
.when small {
  font-size: 11.5px;
  color: var(--ink-2);
}
.when b {
  font-size: 14px;
  font-weight: 600;
}
.what {
  display: grid;
  min-width: 0;
}
.what strong {
  font-size: 15px;
  font-weight: 650;
}
.what small {
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
  font-size: 13px;
  color: var(--ink-2);
}
.count {
  font-size: 12.5px;
  color: var(--mari-ink);
  font-variant-numeric: tabular-nums;
}
@media (max-width: 760px) {
  .live {
    grid-template-columns: minmax(0, 1fr);
  }
  .next li {
    grid-template-columns: 70px minmax(0, 1fr);
  }
  .count {
    grid-column: 2;
  }
}
</style>
