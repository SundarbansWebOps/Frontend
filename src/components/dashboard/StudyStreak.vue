<template>
  <div class="widget w-5" id="widget-streak">
    <div class="widget-glow"
         style="width:300px;height:300px;
                background:radial-gradient(circle,rgba(255,140,0,.28),transparent);
                top:-120px;left:-100px">
    </div>

    <div class="widget-label">Daily Habit</div>
    <div class="widget-title">Study Streak</div>

    <!-- Flame + counter -->
    <div class="streak-flame-wrap">
      <div class="streak-flame" :style="{ fontSize: flameSize + 'px' }">🔥</div>
      <div>
        <div class="streak-number">{{ streak }}</div>
        <div class="streak-label">Day Streak</div>
      </div>
    </div>

    <!-- 7-day history grid -->
    <div class="streak-days-grid">
      <div
        v-for="(day, i) in weekDays"
        :key="i"
        class="streak-day"
        :class="{ done: day.done, empty: !day.done, 'today-slot': day.isToday }"
      >
        <span class="streak-day-name">{{ day.name }}</span>
        <span class="streak-day-icon">{{ day.done ? '🔥' : '·' }}</span>
      </div>
    </div>

    <!-- Check-in action -->
    <div class="streak-checkin-row">
      <button
        class="btn btn-gold"
        ref="streakBtnRef"
        :disabled="checkedToday"
        @click="doCheckin"
      >
        {{ checkedToday ? 'Checked In ✓' : 'Check In Today' }}
      </button>
      <span class="streak-checked-msg" :class="{ show: checkedToday }">✓ Checked in!</span>
    </div>

    <!-- Best streak badge -->
    <div class="streak-best">Best streak: <span>{{ best }}</span> days</div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { save, load } from '../../composables/useLocalStorage.js';

const emit = defineEmits(['confetti']);

const TODAY = new Date().toDateString();
const DAYS = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

const streak = ref(load('sb_streak', 0));
const best = ref(load('sb_best', 0));
const hist = ref(load('sb_hist', []));
const last = ref(load('sb_last', null));
const streakBtnRef = ref(null);

const checkedToday = computed(() => last.value === TODAY);

const flameSize = computed(() => {
  const n = streak.value;
  if (n === 0) return 64;
  if (n < 3)   return 78;
  if (n < 7)   return 94;
  if (n < 14)  return 112;
  return 130;
});

const weekDays = computed(() => {
  const days = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const ds = d.toDateString();
    days.push({
      name: DAYS[d.getDay()],
      done: hist.value.indexOf(ds) > -1,
      isToday: ds === TODAY
    });
  }
  return days;
});

function doCheckin() {
  if (last.value === TODAY) return;

  let s = streak.value;
  let b = best.value;
  let h = [...hist.value];

  const yest = new Date();
  yest.setDate(yest.getDate() - 1);
  s = (last.value === yest.toDateString()) ? s + 1 : 1;
  b = Math.max(b, s);

  if (h.indexOf(TODAY) === -1) h.push(TODAY);
  if (h.length > 60) h = h.slice(-60);

  streak.value = s;
  best.value = b;
  hist.value = h;
  last.value = TODAY;

  save('sb_streak', s);
  save('sb_best', b);
  save('sb_hist', h);
  save('sb_last', TODAY);

  // Fire confetti from button position
  if (streakBtnRef.value) {
    const r = streakBtnRef.value.getBoundingClientRect();
    emit('confetti', r.left + r.width / 2, r.top);
  }
}
</script>
