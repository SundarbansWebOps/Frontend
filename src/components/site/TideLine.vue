<!-- The term as a tide line: how far in we are, what is next. -->
<template>
  <section class="tide" aria-label="26F3 term timeline">
    <header>
      <p class="week">
        <span class="mono">WEEK</span> <b>{{ currentWeek }}</b
        ><span class="of">/{{ TERM.weeks }}</span>
      </p>
      <p v-if="nextExam" class="next">
        <span class="count"
          ><b>{{ shown }}</b> {{ days === 1 ? 'day' : 'days' }}</span
        >
        <span class="to">to {{ nextExam.label }}</span>
      </p>
    </header>

    <div class="track" :style="{ '--now': nowPct }">
      <div class="rail" />
      <div class="fill" />
      <button
        v-for="(d, i) in DATES"
        :key="d.id"
        type="button"
        class="mark"
        :class="[d.kind, edge(d.at), { past: d.at < TODAY, next: d === nextDate, up: i % 2 }]"
        :style="{ left: pct(d.at) }"
        :title="`${d.label} · ${fmtDate(d.at)}`"
        @click="$emit('pick', d)"
      >
        <i />
        <span>{{ d.short }}</span>
      </button>
      <span class="today" :style="{ left: nowPct }"><i /></span>
    </div>

    <p class="sample mono">{{ TERM.label.toUpperCase() }} TERM</p>
  </section>
</template>

<script setup>
import { onMounted, ref } from 'vue';
import {
  DATES,
  TERM,
  TODAY,
  currentWeek,
  daysUntil,
  fmtDate,
  nextDate,
  nextExam,
} from '../../lib/courses.js';

defineEmits(['pick']);

const span = TERM.end - TERM.start;
const pct = (d) => `${(((d - TERM.start) / span) * 100).toFixed(2)}%`;
const nowPct = pct(TODAY);
const edge = (d) => {
  const f = (d - TERM.start) / span;
  return f > 0.9 ? 'end' : f < 0.08 ? 'start' : '';
};
const days = nextExam ? daysUntil(nextExam.at) : 0;

// Count up to the number of days left — a small moment, not a spinner.
const shown = ref(0);
onMounted(() => {
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
    shown.value = days;
    return;
  }
  const t0 = performance.now();
  const tick = (t) => {
    const k = Math.min(1, (t - t0) / 1100);
    shown.value = Math.round(days * (1 - Math.pow(1 - k, 3)));
    if (k < 1) requestAnimationFrame(tick);
  };
  requestAnimationFrame(tick);
});
</script>

<style scoped>
.tide {
  display: grid;
  gap: 10px;
  padding: 14px 16px 12px;
  border-radius: var(--r);
  background: var(--card);
  border: 1px solid var(--line);
}
header {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 12px;
}
header p {
  margin: 0;
}
.week {
  display: flex;
  align-items: baseline;
  gap: 6px;
  font-size: 13px;
  color: var(--ink-2);
}
.week .mono {
  font-size: 10.5px;
  letter-spacing: 0.14em;
}
.week b {
  font-size: 26px;
  font-weight: 700;
  color: var(--ink);
  letter-spacing: -0.03em;
  line-height: 1;
}
.of {
  color: var(--ink-3);
  margin-left: -4px;
}
.next {
  display: flex;
  align-items: baseline;
  gap: 6px;
  font-size: 13px;
  color: var(--ink-2);
}
.count {
  color: var(--verm);
  font-weight: 600;
}
.count b {
  font-size: 26px;
  font-weight: 700;
  letter-spacing: -0.03em;
  font-variant-numeric: tabular-nums;
}
.to {
  color: var(--ink);
  font-weight: 600;
}

.track {
  position: relative;
  height: 58px;
  margin: 0 6px;
}
.rail,
.fill {
  position: absolute;
  top: 28px;
  left: 0;
  height: 3px;
  border-radius: 3px;
}
.rail {
  right: 0;
  background: repeating-linear-gradient(90deg, var(--line-strong) 0 6px, transparent 6px 10px);
}
.fill {
  width: var(--now);
  background: var(--acc, var(--mari));
  transform-origin: left;
  animation: tide 1.4s var(--ease-out) 0.3s both;
}
@keyframes tide {
  from {
    transform: scaleX(0);
  }
}
.mark {
  position: absolute;
  top: 29px;
  width: 0;
  height: 0;
  padding: 0;
  border: 0;
  background: none;
  animation: fade-in 0.5s ease both 0.9s;
}
@keyframes fade-in {
  from {
    opacity: 0;
  }
}
.mark i {
  position: absolute;
  left: -6px;
  top: -6px;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: var(--card);
  border: 2px solid var(--ink-2);
  transition: transform 0.3s var(--ease-spring);
}
.mark.exam i {
  border-color: var(--ink);
  border-radius: 2px;
  transform: rotate(45deg) scale(0.9);
}
.mark.next i {
  background: var(--verm);
  border-color: var(--verm);
  animation: ping-mark 2s ease-out infinite 2s;
}
@keyframes ping-mark {
  0% {
    box-shadow: 0 0 0 0 color-mix(in srgb, var(--verm) 45%, transparent);
  }
  100% {
    box-shadow: 0 0 0 10px transparent;
  }
}
.mark.past i {
  background: var(--acc, var(--mari));
  border-color: var(--acc, var(--mari));
}
.mark span {
  position: absolute;
  top: 11px;
  left: 0;
  transform: translateX(-50%);
  font-size: 11px;
  font-weight: 600;
  color: var(--ink-2);
  white-space: nowrap;
}
.mark.up span {
  top: auto;
  bottom: 11px;
}
.mark.end span {
  transform: translateX(calc(-100% + 8px));
}
.mark.start span {
  transform: translateX(-8px);
}
.mark.next span {
  color: var(--verm);
}
.mark:hover i {
  transform: scale(1.3) rotate(45deg);
}
.today {
  position: absolute;
  top: 19px;
  transform: translateX(-50%);
  animation: fade-in 0.5s ease both 1.5s;
}
.today i {
  display: block;
  width: 3px;
  height: 21px;
  border-radius: 2px;
  background: var(--ink);
}
.sample {
  margin: 0;
  font-size: 9.5px;
  letter-spacing: 0.14em;
  color: var(--ink-3);
}
</style>
