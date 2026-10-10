<!-- Monthly view for the sample quiz dates shown on the Resources page. -->
<template>
  <section class="calendar" aria-labelledby="calendar-h">
    <header class="calendar-head">
      <span class="calendar-mark" aria-hidden="true" />
      <h2 id="calendar-h">Schedule</h2>
    </header>

    <div class="month-nav">
      <button type="button" aria-label="Previous month" @click="shiftMonth(-1)">
        <svg viewBox="0 0 20 20" aria-hidden="true"><path d="m12.5 4.5-5 5 5 5" /></svg>
      </button>
      <h3>{{ monthLabel }}</h3>
      <button type="button" aria-label="Next month" @click="shiftMonth(1)">
        <svg viewBox="0 0 20 20" aria-hidden="true"><path d="m7.5 4.5 5 5-5 5" /></svg>
      </button>
    </div>

    <div class="weekdays" aria-hidden="true">
      <span v-for="day in weekdays" :key="day">{{ day }}</span>
    </div>
    <div class="days" aria-label="Days in the selected month">
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
          @click="selectedDate = cell.key"
        >
          {{ cell.day }}
          <i v-if="eventsByDate.has(cell.key)" aria-hidden="true" />
        </button>
      </template>
    </div>

    <p v-if="selectedEvent" class="date-detail" aria-live="polite">
      <b>{{ selectedEvent.label }}</b>
      <span>{{ formatDate(selectedEvent.date) }}</span>
    </p>

    <button
      type="button"
      class="open-calendar"
      :aria-expanded="showDates"
      @click="showDates = !showDates"
    >
      {{ showDates ? 'Hide key dates' : 'Open calendar' }}
      <svg viewBox="0 0 20 20" aria-hidden="true"><path d="M4 10h11m-4-4 4 4-4 4" /></svg>
    </button>

    <ul v-if="showDates" class="key-dates">
      <li v-for="date in DATES" :key="date.id">
        <span>{{ date.label }}</span>
        <time :datetime="date.date">{{ formatDate(date.date) }}</time>
      </li>
    </ul>

    <p class="sample mono">SAMPLE DATES · {{ TERM.label.toUpperCase() }}</p>
  </section>
</template>

<script setup>
import { computed, ref } from 'vue';
import { DATES, TERM, TODAY, nextDate } from '../../lib/courses.js';

const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const dateFromKey = (key) => {
  const [year, month, day] = key.split('-').map(Number);
  return new Date(year, month - 1, day);
};
const initialDate = nextDate?.date ? dateFromKey(nextDate.date) : TODAY;
const month = ref(new Date(initialDate.getFullYear(), initialDate.getMonth(), 1));
const selectedDate = ref('');
const showDates = ref(false);
const monthLabel = computed(() =>
  new Intl.DateTimeFormat('en', { month: 'long', year: 'numeric' }).format(month.value)
);
const todayKey = `${TODAY.getFullYear()}-${String(TODAY.getMonth() + 1).padStart(2, '0')}-${String(TODAY.getDate()).padStart(2, '0')}`;
const eventsByDate = new Map(DATES.map((date) => [date.date, date]));
const selectedEvent = computed(() => eventsByDate.get(selectedDate.value));
const calendarDays = computed(() => {
  const year = month.value.getFullYear();
  const monthIndex = month.value.getMonth();
  const offset = new Date(year, monthIndex, 1).getDay();
  const count = new Date(year, monthIndex + 1, 0).getDate();
  const cells = Array.from({ length: Math.ceil((offset + count) / 7) * 7 }, (_, index) => {
    const day = index - offset + 1;
    if (day < 1 || day > count) return { key: `blank-${index}`, day: 0 };
    const key = `${year}-${String(monthIndex + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    return { key, day, weekend: index % 7 === 0 || index % 7 === 6 };
  });
  return cells;
});

function shiftMonth(amount) {
  month.value = new Date(month.value.getFullYear(), month.value.getMonth() + amount, 1);
  selectedDate.value = '';
}

function formatDate(key) {
  return new Intl.DateTimeFormat('en-IN', { day: 'numeric', month: 'short' }).format(
    dateFromKey(key)
  );
}

function dayLabel(cell) {
  const date = eventsByDate.get(cell.key);
  return date
    ? `${cell.day}, ${monthLabel.value}: ${date.label}`
    : `${cell.day}, ${monthLabel.value}`;
}
</script>

<style scoped>
.calendar {
  overflow: hidden;
  border: 1px solid var(--line);
  border-radius: 20px;
  background: var(--card);
  box-shadow: var(--shadow);
}
.calendar-head {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 16px 20px;
  border-bottom: 1px solid var(--line);
}
.calendar-head h2 {
  margin: 0;
  color: var(--ink-2);
  font-size: 16px;
  font-weight: 650;
}
.calendar-mark {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--mari);
  box-shadow: 0 0 0 4px var(--mari-soft);
}
.month-nav {
  display: grid;
  grid-template-columns: 36px minmax(0, 1fr) 36px;
  align-items: center;
  gap: 8px;
  padding: 16px 16px 8px;
}
.month-nav h3 {
  margin: 0;
  text-align: center;
  color: var(--mari-ink);
  font-size: 18px;
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
  padding: 0 18px;
  text-align: center;
}
.weekdays {
  padding-top: 7px;
  color: var(--ink-3);
  font-size: 11.5px;
  font-weight: 650;
}
.days {
  padding-top: 7px;
  padding-bottom: 12px;
}
.day,
.blank {
  position: relative;
  display: grid;
  place-items: center;
  justify-self: center;
  width: 36px;
  height: 36px;
  border: 0;
  border-radius: 50%;
}
.day {
  background: transparent;
  color: var(--ink-2);
  font: inherit;
  font-size: 14px;
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
  bottom: 3px;
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
.date-detail {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  margin: 0 20px 12px;
  padding: 10px 12px;
  border-radius: 10px;
  background: var(--sunk);
  color: var(--ink-2);
  font-size: 13px;
}
.date-detail span {
  color: var(--ink-3);
}
.open-calendar {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  width: calc(100% - 40px);
  min-height: 42px;
  margin: 0 20px 14px;
  border: 0;
  border-radius: 99px;
  background: var(--mari-soft);
  color: var(--mari-ink);
  font: inherit;
  font-size: 14px;
  font-weight: 650;
  cursor: pointer;
  transition:
    transform 0.2s var(--ease-out),
    background 0.2s;
}
.open-calendar:hover {
  transform: translateY(-1px);
  background: var(--mari);
}
.open-calendar svg {
  width: 17px;
  height: 17px;
  fill: none;
  stroke: currentColor;
  stroke-width: 1.8;
  stroke-linecap: round;
  stroke-linejoin: round;
}
.key-dates {
  display: grid;
  gap: 8px;
  margin: 0 20px 14px;
  padding: 12px;
  border-radius: 12px;
  background: var(--sunk);
  list-style: none;
}
.key-dates li {
  display: flex;
  justify-content: space-between;
  gap: 10px;
  color: var(--ink-2);
  font-size: 13px;
}
.key-dates time {
  color: var(--ink-3);
  font-variant-numeric: tabular-nums;
}
.sample {
  margin: 0;
  padding: 0 20px 16px;
  color: var(--ink-3);
  font-size: 9.5px;
  letter-spacing: 0.13em;
}
</style>
