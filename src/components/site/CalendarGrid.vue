<template>
  <div class="calendar-grid" :class="{ expanded }">
    <div class="month-nav">
      <button type="button" aria-label="Previous month" @click="$emit('shift', -1)">
        <svg viewBox="0 0 20 20" aria-hidden="true"><path d="m12.5 4.5-5 5 5 5" /></svg>
      </button>
      <h3>{{ monthLabel }}</h3>
      <button type="button" aria-label="Next month" @click="$emit('shift', 1)">
        <svg viewBox="0 0 20 20" aria-hidden="true"><path d="m7.5 4.5 5 5-5 5" /></svg>
      </button>
    </div>

    <div class="weekdays" aria-hidden="true">
      <span v-for="day in weekdays" :key="day">{{ day }}</span>
    </div>
    <div class="days" :aria-label="`Days in ${monthLabel}`">
      <template v-for="cell in calendarDays" :key="cell.key">
        <span v-if="!cell.day" class="blank" />
        <button
          v-else
          type="button"
          class="day"
          :class="{
            event: eventsByDate.has(cell.key),
            selected: selectedDate === cell.key,
            today: todayKey === cell.key,
            weekend: cell.weekend,
          }"
          :aria-label="dayLabel(cell)"
          :aria-current="todayKey === cell.key ? 'date' : undefined"
          :aria-pressed="selectedDate === cell.key"
          @click="$emit('select', cell.key)"
        >
          {{ cell.day }}
          <i v-if="eventsByDate.has(cell.key)" aria-hidden="true" />
        </button>
      </template>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
  month: { type: Date, required: true },
  eventsByDate: { type: Map, required: true },
  todayKey: { type: String, required: true },
  selectedDate: { type: String, default: '' },
  dayLabel: { type: Function, required: true },
  expanded: { type: Boolean, default: false },
});
defineEmits(['shift', 'select']);

const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const monthLabel = computed(() =>
  new Intl.DateTimeFormat('en', { month: 'long', year: 'numeric' }).format(props.month)
);
const calendarDays = computed(() => {
  const year = props.month.getFullYear();
  const monthIndex = props.month.getMonth();
  const offset = new Date(year, monthIndex, 1).getDay();
  const count = new Date(year, monthIndex + 1, 0).getDate();
  return Array.from({ length: Math.ceil((offset + count) / 7) * 7 }, (_, index) => {
    const day = index - offset + 1;
    if (day < 1 || day > count) return { key: `blank-${index}`, day: 0 };
    const key = `${year}-${String(monthIndex + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    return { key, day, weekend: index % 7 === 0 || index % 7 === 6 };
  });
});
</script>

<style scoped>
.calendar-grid {
  min-width: 0;
}
.month-nav {
  display: grid;
  grid-template-columns: 36px minmax(0, 1fr) 36px;
  align-items: center;
  gap: 8px;
  padding: 12px 16px 5px;
}
.month-nav h3 {
  margin: 0;
  text-align: center;
  color: var(--mari-ink);
  font-size: 17px;
  font-weight: 700;
  letter-spacing: -0.025em;
}
.month-nav button {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  padding: 0;
  border: 0;
  border-radius: 50%;
  background: transparent;
  color: var(--ink-2);
  cursor: pointer;
  transition:
    background 0.2s,
    color 0.2s;
}
.month-nav button:hover {
  background: var(--mari-soft);
  color: var(--mari-ink);
}
.month-nav svg {
  width: 18px;
  height: 18px;
  fill: none;
  stroke: currentColor;
  stroke-width: 1.8;
  stroke-linecap: round;
  stroke-linejoin: round;
}
.weekdays,
.days {
  display: grid;
  grid-template-columns: repeat(7, minmax(0, 1fr));
  padding: 0 16px;
  text-align: center;
}
.weekdays {
  padding-top: 4px;
  color: var(--ink-3);
  font-size: 11px;
  font-weight: 650;
}
.days {
  padding-top: 3px;
  padding-bottom: 10px;
}
.day,
.blank {
  position: relative;
  display: grid;
  place-items: center;
  justify-self: center;
  width: 34px;
  height: 34px;
  border: 0;
  border-radius: 50%;
}
.day {
  background: transparent;
  color: var(--ink-2);
  font: inherit;
  font-size: 13px;
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  cursor: pointer;
  transition:
    background 0.18s,
    color 0.18s,
    transform 0.18s var(--ease-out);
}
.day.weekend {
  color: var(--mari-ink);
}
.day:hover {
  background: var(--sunk);
}
.day.event::after {
  content: '';
  position: absolute;
  bottom: 2px;
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: var(--verm);
}
.day.selected {
  background: var(--mari-soft);
  color: var(--mari-ink);
}
.day.today {
  box-shadow: inset 0 0 0 1px var(--line-strong);
}
.expanded .month-nav {
  padding-top: 18px;
  padding-bottom: 12px;
}
.expanded .month-nav h3 {
  font-size: 20px;
}
.expanded .weekdays,
.expanded .days {
  padding-right: 24px;
  padding-left: 24px;
}
.expanded .weekdays {
  font-size: 12px;
}
.expanded .day,
.expanded .blank {
  width: 48px;
  height: 48px;
}
.expanded .day {
  font-size: 15px;
}
.expanded .day.event::after {
  bottom: 5px;
  width: 5px;
  height: 5px;
}
@media (max-width: 560px) {
  .expanded .day,
  .expanded .blank {
    width: 38px;
    height: 40px;
  }
}
</style>
