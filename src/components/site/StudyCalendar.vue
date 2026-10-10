<template>
  <section class="calendar" aria-label="26F3 calendar">
    <CalendarGrid
      :month="month"
      :events-by-date="eventsByDate"
      :today-key="todayKey"
      :selected-date="selectedDate"
      :day-label="dayLabel"
      @shift="shiftMonth"
      @select="selectedDate = $event"
    />

    <p v-if="selectedEvents.length" class="selected-summary" aria-live="polite">
      <b>{{ formatDate(selectedDate) }}</b>
      <span>{{ selectedEvents.map((event) => event.title).join(' · ') }}</span>
    </p>

    <button ref="openButton" type="button" class="open-calendar" @click="openCalendar">
      Open calendar
      <svg viewBox="0 0 20 20" aria-hidden="true"><path d="M4 10h11m-4-4 4 4-4 4" /></svg>
    </button>

    <Teleport to="body">
      <Transition name="calendar-overlay">
        <div v-if="showCalendar" class="calendar-backdrop" @click.self="closeCalendar">
          <section
            ref="dialog"
            class="calendar-dialog"
            role="dialog"
            aria-modal="true"
            aria-labelledby="calendar-title"
            tabindex="-1"
          >
            <header class="dialog-head">
              <div>
                <p class="dialog-kicker mono">{{ TERM.label }}</p>
                <h2 id="calendar-title">Term calendar</h2>
              </div>
              <button
                class="close"
                type="button"
                aria-label="Close calendar"
                @click="closeCalendar"
              >
                <svg viewBox="0 0 20 20" aria-hidden="true"><path d="m5 5 10 10M15 5 5 15" /></svg>
              </button>
            </header>

            <div class="dialog-body">
              <div class="month-panel">
                <CalendarGrid
                  :month="month"
                  :events-by-date="eventsByDate"
                  :today-key="todayKey"
                  :selected-date="selectedDate"
                  :day-label="dayLabel"
                  expanded
                  @shift="shiftMonth"
                  @select="selectedDate = $event"
                />
                <div v-if="selectedEvents.length" class="selected-events" aria-live="polite">
                  <h3>{{ formatDate(selectedDate) }}</h3>
                  <ul>
                    <li v-for="event in selectedEvents" :key="event.id">
                      <b>{{ event.title }}</b>
                      <span v-if="event.detail">{{ event.detail }}</span>
                      <time v-if="event.start" :datetime="event.start">{{
                        formatRange(event)
                      }}</time>
                    </li>
                  </ul>
                </div>
              </div>

              <section class="event-panel" aria-labelledby="dates-title">
                <h3 id="dates-title">Key dates</h3>
                <ul class="key-dates">
                  <li v-for="event in orderedEvents" :key="event.id">
                    <span class="date-label">
                      <b>{{ event.title }}</b>
                      <small v-if="event.detail">{{ event.detail }}</small>
                    </span>
                    <time v-if="event.start" :datetime="event.start">{{ formatRange(event) }}</time>
                    <span v-else class="undated">Date to be decided</span>
                  </li>
                </ul>
              </section>
            </div>
          </section>
        </div>
      </Transition>
    </Teleport>
  </section>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import CalendarGrid from './CalendarGrid.vue';
import { TERM_CALENDAR } from '../../data/term-calendar-26f3.js';
import { TERM, TODAY } from '../../lib/courses.js';

const orderedEvents = [...TERM_CALENDAR].sort((a, b) =>
  (a.start ?? '9999').localeCompare(b.start ?? '9999')
);
const dateFromKey = (key) => {
  const [year, month, day] = key.split('-').map(Number);
  return new Date(year, month - 1, day);
};
const todayKey = `${TODAY.getFullYear()}-${String(TODAY.getMonth() + 1).padStart(2, '0')}-${String(TODAY.getDate()).padStart(2, '0')}`;
const nextEvent = orderedEvents.find((event) => event.start && event.start >= todayKey);
const initialDate = nextEvent ? dateFromKey(nextEvent.start) : TODAY;
const month = ref(new Date(initialDate.getFullYear(), initialDate.getMonth(), 1));
const selectedDate = ref('');
const showCalendar = ref(false);
const dialog = ref(null);
const openButton = ref(null);
const monthLabel = computed(() =>
  new Intl.DateTimeFormat('en', { month: 'long', year: 'numeric' }).format(month.value)
);
const eventsByDate = new Map();
for (const event of TERM_CALENDAR) {
  for (const key of new Set([event.start, event.end].filter(Boolean))) {
    const list = eventsByDate.get(key) ?? [];
    list.push(event);
    eventsByDate.set(key, list);
  }
}
const selectedEvents = computed(() => eventsByDate.get(selectedDate.value) ?? []);

function shiftMonth(amount) {
  month.value = new Date(month.value.getFullYear(), month.value.getMonth() + amount, 1);
  selectedDate.value = '';
}

function formatDate(key) {
  return new Intl.DateTimeFormat('en-IN', { day: 'numeric', month: 'short' }).format(
    dateFromKey(key)
  );
}

function formatRange(event) {
  if (!event.start) return event.detail ?? 'Date to be decided';
  const from = formatDate(event.start);
  return event.end && event.end !== event.start ? `${from} – ${formatDate(event.end)}` : from;
}

function dayLabel(cell) {
  const events = eventsByDate.get(cell.key) ?? [];
  return events.length
    ? `${cell.day}, ${monthLabel.value}: ${events.map((event) => event.title).join(', ')}`
    : `${cell.day}, ${monthLabel.value}`;
}

async function openCalendar() {
  showCalendar.value = true;
  document.body.style.overflow = 'hidden';
  await nextTick();
  dialog.value?.focus();
}

function closeCalendar() {
  showCalendar.value = false;
}

watch(showCalendar, (open) => {
  if (!open) {
    document.body.style.overflow = '';
    nextTick(() => openButton.value?.focus());
  }
});

function onKeydown(event) {
  if (event.key === 'Escape' && showCalendar.value) closeCalendar();
}

onMounted(() => document.addEventListener('keydown', onKeydown));
onBeforeUnmount(() => {
  document.removeEventListener('keydown', onKeydown);
  document.body.style.overflow = '';
});
</script>

<style scoped>
.calendar {
  overflow: hidden;
  border: 1px solid var(--line);
  border-radius: 20px;
  background: var(--card);
  box-shadow: var(--shadow);
}
.selected-summary {
  display: grid;
  gap: 2px;
  margin: 0 18px 10px;
  padding: 8px 10px;
  border-radius: 10px;
  background: var(--sunk);
  color: var(--ink-2);
  font-size: 12px;
}
.selected-summary span {
  color: var(--ink-3);
}
.open-calendar {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  width: calc(100% - 36px);
  min-height: 38px;
  margin: 0 18px 14px;
  border: 0;
  border-radius: 99px;
  background: var(--mari-soft);
  color: var(--mari-ink);
  font: inherit;
  font-size: 13px;
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
  width: 16px;
  height: 16px;
  fill: none;
  stroke: currentColor;
  stroke-width: 1.8;
  stroke-linecap: round;
  stroke-linejoin: round;
}
.calendar-backdrop {
  position: fixed;
  z-index: 1200;
  inset: 0;
  display: grid;
  place-items: center;
  padding: 5vh 5vw;
  background: color-mix(in srgb, var(--ink) 58%, transparent);
  backdrop-filter: blur(7px);
}
.calendar-dialog {
  width: min(1100px, 90vw);
  max-height: 90vh;
  overflow: hidden;
  border: 1px solid var(--line-strong);
  border-radius: 22px;
  background: var(--paper);
  box-shadow: var(--shadow);
  transform-origin: bottom right;
  outline: none;
}
.dialog-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 24px;
  border-bottom: 1px solid var(--line);
}
.dialog-kicker {
  margin: 0 0 2px;
  color: var(--mari-ink);
  font-size: 11px;
  letter-spacing: 0.1em;
}
.dialog-head h2 {
  margin: 0;
  color: var(--ink);
  font-size: 25px;
  font-weight: 750;
  letter-spacing: -0.035em;
}
.close {
  display: grid;
  place-items: center;
  width: 38px;
  height: 38px;
  border: 1px solid var(--line);
  border-radius: 50%;
  background: var(--card);
  color: var(--ink-2);
  cursor: pointer;
}
.close svg {
  width: 17px;
  fill: none;
  stroke: currentColor;
  stroke-width: 1.8;
  stroke-linecap: round;
}
.dialog-body {
  display: grid;
  grid-template-columns: minmax(280px, 0.85fr) minmax(0, 1.5fr);
  gap: 20px;
  max-height: calc(90vh - 78px);
  overflow: auto;
  padding: 20px;
}
.month-panel,
.event-panel {
  min-width: 0;
  border: 1px solid var(--line);
  border-radius: 16px;
  background: var(--card);
}
.event-panel {
  overflow: hidden;
}
.event-panel > h3,
.selected-events > h3 {
  margin: 0;
  padding: 14px 16px;
  border-bottom: 1px solid var(--line);
  color: var(--ink-2);
  font-size: 15px;
  font-weight: 700;
}
.selected-events {
  margin: 0 16px 16px;
  overflow: hidden;
  border: 1px solid var(--line);
  border-radius: 12px;
  background: var(--sunk);
}
.selected-events ul,
.key-dates {
  display: grid;
  gap: 0;
  max-height: 55vh;
  overflow: auto;
  margin: 0;
  padding: 0 16px;
  list-style: none;
}
.selected-events li,
.key-dates li {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 14px;
  padding: 11px 0;
  color: var(--ink-2);
  font-size: 13px;
}
.selected-events li + li,
.key-dates li + li {
  border-top: 1px solid var(--line);
}
.selected-events li > span,
.date-label small {
  color: var(--ink-3);
}
.selected-events time,
.key-dates time,
.undated {
  flex: none;
  color: var(--mari-ink);
  font-variant-numeric: tabular-nums;
}
.date-label {
  display: grid;
  gap: 3px;
  min-width: 0;
}
.date-label small {
  font-size: 11px;
}
.calendar-overlay-enter-active,
.calendar-overlay-leave-active {
  transition: opacity 0.28s var(--ease-out);
}
.calendar-overlay-enter-active .calendar-dialog,
.calendar-overlay-leave-active .calendar-dialog {
  transition:
    transform 0.42s var(--ease-spring),
    opacity 0.24s var(--ease-out);
}
.calendar-overlay-enter-from,
.calendar-overlay-leave-to {
  opacity: 0;
}
.calendar-overlay-enter-from .calendar-dialog,
.calendar-overlay-leave-to .calendar-dialog {
  opacity: 0.4;
  transform: translate(14vw, 10vh) scale(0.35);
}
@media (max-width: 760px) {
  .calendar-backdrop {
    padding: 3vh 4vw;
  }
  .calendar-dialog {
    width: 92vw;
    max-height: 94vh;
  }
  .dialog-body {
    grid-template-columns: minmax(0, 1fr);
    max-height: calc(94vh - 78px);
    padding: 12px;
  }
  .dialog-head {
    padding: 14px 18px;
  }
  .event-panel .key-dates {
    max-height: 38vh;
  }
}
@media (prefers-reduced-motion: reduce) {
  .calendar-overlay-enter-active,
  .calendar-overlay-leave-active,
  .calendar-overlay-enter-active .calendar-dialog,
  .calendar-overlay-leave-active .calendar-dialog {
    transition: none;
  }
}
</style>
