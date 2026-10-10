<!--
  One course, everything a student opens it for: past papers by exam, notes by
  week. Opens with a tide-like reveal that starts wherever the student tapped.
-->
<template>
  <Teleport to="body">
    <Transition :css="false" @enter="enter" @leave="leave">
      <div v-if="course" class="root" @keydown.esc="closeCourse">
        <div class="backdrop" @click="closeCourse" />
        <aside
          ref="panel"
          class="panel"
          role="dialog"
          aria-modal="true"
          :aria-label="`${course.short} resources`"
          tabindex="-1"
          @keydown="trapTab"
        >
          <header class="head">
            <div class="top">
              <span class="code mono">{{ course.code }}</span>
              <span class="lvl">{{ LEVEL[course.track] }}</span>
              <span class="grow" />
              <button
                type="button"
                class="icon"
                :title="copied ? 'Copied' : 'Copy link'"
                @click="copy"
              >
                <svg viewBox="0 0 24 24" aria-hidden="true">
                  <path
                    v-if="!copied"
                    d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"
                  />
                  <path v-else d="m5 12 4.5 4.5L19 7" />
                </svg>
                <span class="visually-hidden">Copy link</span>
              </button>
              <button type="button" class="icon" title="Close (Esc)" @click="closeCourse">
                <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 6l12 12M18 6 6 18" /></svg>
                <span class="visually-hidden">Close</span>
              </button>
            </div>
            <h2>
              <span class="short">{{ course.short }}</span>
              <span v-if="course.short !== course.name" class="full">{{ course.name }}</span>
            </h2>
            <button
              type="button"
              class="pin"
              :class="{ on: pinned }"
              @click="togglePin(course.code)"
            >
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <path
                  d="M12 3.5 14.6 9l5.9.6-4.4 4 1.3 5.9L12 16.4 6.6 19.5 7.9 13.6l-4.4-4 5.9-.6z"
                />
              </svg>
              {{ pinned ? 'In my courses' : 'Add to my courses' }}
            </button>

            <nav class="tabs" role="tablist" aria-label="Course materials">
              <button
                v-for="t in TABS"
                :key="t.id"
                :id="`course-tab-${t.id}`"
                role="tab"
                type="button"
                :aria-selected="tab === t.id"
                aria-controls="course-panel"
                :tabindex="tab === t.id ? 0 : -1"
                :class="{ on: tab === t.id }"
                @click="tab = t.id"
                @keydown="tabKeydown"
              >
                {{ t.label }}
                <small>{{ t.id === 'pyqs' ? course.pyqs.length : course.notes.length }}</small>
              </button>
              <i class="ink" :style="{ '--x': tab === 'pyqs' ? 0 : 1 }" />
            </nav>
          </header>

          <div class="filters">
            <template v-if="tab === 'pyqs'">
              <button
                v-for="e in examOptions"
                :key="e.id"
                type="button"
                class="chip"
                :class="{ on: exam === e.id, soon: e.id === nextExam?.exam }"
                @click="exam = e.id"
              >
                {{ e.id }} <small>{{ e.n }}</small>
              </button>
            </template>
            <template v-else>
              <button
                type="button"
                class="chip"
                :class="{ on: week === null }"
                @click="week = null"
              >
                All <small>{{ course.notes.length }}</small>
              </button>
              <button
                v-for="w in weekOptions"
                :key="w.id"
                type="button"
                class="chip"
                :class="{ on: week === w.id, soon: w.id === currentWeek }"
                :title="w.id === currentWeek ? 'This week' : ''"
                @click="week = w.id"
              >
                {{ w.id === 0 ? 'General' : 'W' + w.id }} <small>{{ w.n }}</small>
              </button>
            </template>
          </div>

          <div
            id="course-panel"
            ref="body"
            class="body"
            role="tabpanel"
            :aria-labelledby="`course-tab-${tab}`"
            tabindex="0"
          >
            <Transition name="swap" mode="out-in">
              <div :key="tab + exam + week">
                <section v-for="(g, gi) in groups" :key="g.label" class="group">
                  <h3 :style="{ '--i': gi }" class="rise">{{ g.label }}</h3>
                  <a
                    v-for="(r, i) in g.items"
                    :key="r.link + i"
                    class="row rise"
                    :href="r.link"
                    target="_blank"
                    rel="noopener"
                    :style="{ '--i': Math.min(gi * 2 + i, 14) }"
                  >
                    <span class="t">{{ r.title }}</span>
                    <span class="m">{{ r.meta }}</span>
                    <span class="arr" aria-hidden="true">↗</span>
                  </a>
                </section>
                <p v-if="!groups.length" class="none">
                  {{
                    tab === 'pyqs'
                      ? 'No past papers match this exam yet.'
                      : 'No notes match this week yet.'
                  }}
                </p>
              </div>
            </Transition>
          </div>
        </aside>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue';
import { closeCourse, courseFor, getCourseOpener, isMine, store, togglePin } from '../../lib/store.js';
import { currentWeek, nextExam } from '../../lib/courses.js';

const LEVEL = {
  foundation: 'Foundation',
  programming: 'Diploma · Programming',
  datascience: 'Diploma · Data Science',
  diploma: 'Diploma',
  degree: 'BS Degree',
};
const TABS = [
  { id: 'pyqs', label: 'Past papers' },
  { id: 'notes', label: 'Notes' },
];
const EXAM_ORDER = ['All', 'Quiz 1', 'Quiz 2', 'End term', 'OPPE', 'Qualifier', 'Other'];

const course = computed(() => (store.sheet ? courseFor(store.sheet.code) : null));
const pinned = computed(() => course.value && isMine(course.value.code));
const tab = ref('pyqs');
const exam = ref('All');
const week = ref(null);
const panel = ref(null);
const body = ref(null);
const copied = ref(false);
let modalOpener = null;
let appWasInert = false;

function restoreModalState() {
  const app = document.getElementById('app');
  if (app) app.inert = appWasInert;
  const opener = modalOpener;
  modalOpener = null;
  if (opener?.isConnected && !opener.closest('[inert]')) nextTick(() => opener.focus());
}

function trapTab(event) {
  if (event.key !== 'Tab') return;
  const controls = [
    ...panel.value.querySelectorAll(
      'a[href], button:not(:disabled), input:not(:disabled), [tabindex]:not([tabindex="-1"])'
    ),
  ].filter((el) => !el.hidden && el.getClientRects().length);
  if (!controls.length) {
    event.preventDefault();
    panel.value.focus();
    return;
  }
  const first = controls[0];
  const last = controls.at(-1);
  if (
    event.shiftKey &&
    (document.activeElement === first ||
      document.activeElement === panel.value ||
      !panel.value.contains(document.activeElement))
  ) {
    event.preventDefault();
    last.focus();
  } else if (!event.shiftKey && document.activeElement === last) {
    event.preventDefault();
    first.focus();
  }
}

function tabKeydown(event) {
  if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
  event.preventDefault();
  const index = TABS.findIndex((item) => item.id === tab.value);
  const next =
    event.key === 'Home'
      ? 0
      : event.key === 'End'
        ? TABS.length - 1
        : (index + (event.key === 'ArrowRight' ? 1 : -1) + TABS.length) % TABS.length;
  tab.value = TABS[next].id;
  nextTick(() => panel.value?.querySelector(`#course-tab-${tab.value}`)?.focus());
}

watch(
  () => store.sheet?.code,
  (code) => {
    if (!code) {
      restoreModalState();
      return;
    }
    const app = document.getElementById('app');
    modalOpener =
      getCourseOpener() ??
      (document.activeElement instanceof HTMLElement ? document.activeElement : null);
    if (app) {
      appWasInert = app.inert;
      app.inert = true;
    }
    tab.value = store.sheet.tab ?? 'pyqs';
    exam.value = store.sheet.exam ?? 'All';
    week.value = store.sheet.week ?? null;
    copied.value = false;
    nextTick(() => panel.value?.focus({ preventScroll: true }));
  },
  { immediate: true }
);
onBeforeUnmount(restoreModalState);

const examOptions = computed(() => {
  const c = course.value;
  const counts = { All: c.pyqs.length };
  for (const p of c.pyqs) counts[p.exam] = (counts[p.exam] ?? 0) + 1;
  return EXAM_ORDER.filter((e) => counts[e]).map((e) => ({ id: e, n: counts[e] }));
});

const weekOptions = computed(() => {
  const counts = {};
  for (const n of course.value.notes) counts[n.week ?? 0] = (counts[n.week ?? 0] ?? 0) + 1;
  return Object.keys(counts)
    .map(Number)
    .sort((a, b) => (a === 0) - (b === 0) || a - b)
    .map((id) => ({ id, n: counts[id] }));
});

const groups = computed(() => {
  const c = course.value;
  if (!c) return [];
  const map = new Map();
  if (tab.value === 'pyqs') {
    for (const p of c.pyqs) {
      if (exam.value !== 'All' && p.exam !== exam.value) continue;
      const key = p.term?.label ?? 'Undated';
      if (!map.has(key)) map.set(key, []);
      map.get(key).push({
        title: p.exam === 'Other' ? p.title : `${p.exam}${p.set ? ' · ' + p.set : ''}`,
        meta: p.exam === 'Other' ? '' : shorten(p.title),
        link: p.link,
      });
    }
  } else {
    for (const n of c.notes) {
      if (week.value !== null && (n.week ?? 0) !== week.value) continue;
      const key = n.week ? `Week ${n.week}` : 'General';
      if (!map.has(key)) map.set(key, []);
      map.get(key).push({ title: n.title, meta: n.author ? `by ${n.author}` : '', link: n.link });
    }
    return [...map.entries()]
      .sort(([a], [b]) => weekNum(a) - weekNum(b))
      .map(([label, items]) => ({ label, items }));
  }
  return [...map.entries()].map(([label, items]) => ({ label, items }));
});
const weekNum = (l) => (l === 'General' ? 99 : Number(l.split(' ')[1]));
const shorten = (t) => (t.length > 64 ? t.slice(0, 62) + '…' : t);

watch([tab, exam, week], () => body.value?.scrollTo({ top: 0 }));

async function copy() {
  try {
    await navigator.clipboard.writeText(location.href);
    copied.value = true;
    setTimeout(() => (copied.value = false), 1600);
  } catch {
    /* clipboard blocked */
  }
}

// Tide reveal: a circle grows from the tap point across the panel. It stops exactly at the
// farthest corner, and its easing is still moving there: a strong ease-out (and a radius past
// the corner) left the corners filling in a slow tail that read as a stall.
function enter(el, done) {
  const p = el.querySelector('.panel');
  const b = el.querySelector('.backdrop');
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (reduce) return done();
  const r = p.getBoundingClientRect();
  const o = store.sheet?.origin ?? { x: r.left, y: r.top };
  const ox = o.x - r.left;
  const oy = o.y - r.top;
  const R = Math.hypot(Math.max(ox, r.width - ox), Math.max(oy, r.height - oy)) + 1;
  b.animate([{ opacity: 0 }, { opacity: 1 }], { duration: 350, easing: 'ease-out' });
  p.animate(
    [
      { clipPath: `circle(0px at ${ox}px ${oy}px)` },
      { clipPath: `circle(${R}px at ${ox}px ${oy}px)` },
    ],
    { duration: 560, easing: 'cubic-bezier(.25,.5,.4,.9)' }
  ).finished.then(done);
}
function leave(el, done) {
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) return done();
  const p = el.querySelector('.panel');
  const b = el.querySelector('.backdrop');
  b.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 260, fill: 'forwards' });
  p.animate(
    [
      { transform: 'none', opacity: 1 },
      { transform: 'translateX(24px)', opacity: 0 },
    ],
    { duration: 240, easing: 'ease-in', fill: 'forwards' }
  ).finished.then(done);
}
</script>

<style scoped>
.root {
  position: fixed;
  inset: 0;
  z-index: 100;
}
.backdrop {
  position: absolute;
  inset: 0;
  background: color-mix(in srgb, var(--ink) 38%, transparent);
  backdrop-filter: blur(2px);
}
.panel {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  width: min(660px, 100%);
  display: flex;
  flex-direction: column;
  background: var(--paper);
  box-shadow: -30px 0 80px -40px rgb(0 0 0 / 0.5);
  outline: none;
}
.head {
  padding: 18px 28px 0;
  border-bottom: 1px solid var(--line);
}
.top {
  display: flex;
  align-items: center;
  gap: 10px;
}
.grow {
  flex: 1;
}
.code {
  font-size: 12.5px;
  padding: 3px 8px;
  border-radius: 6px;
  background: var(--ink);
  color: var(--paper);
}
.lvl {
  font-size: 12.5px;
  color: var(--ink-2);
}
.icon {
  display: grid;
  place-items: center;
  width: 38px;
  height: 38px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: var(--card);
  transition:
    transform 0.2s var(--ease-spring),
    border-color 0.2s;
}
.icon:hover {
  border-color: var(--ink-3);
  transform: scale(1.06);
}
.icon svg {
  width: 18px;
  height: 18px;
  fill: none;
  stroke: currentColor;
  stroke-width: 2;
  stroke-linecap: round;
  stroke-linejoin: round;
}
h2 {
  margin: 18px 0 12px;
  display: grid;
  gap: 2px;
  line-height: 1;
}
.short {
  font-size: clamp(34px, 6vw, 52px);
  font-weight: 750;
  letter-spacing: -0.035em;
  animation: rise 0.6s var(--ease-out) both 0.12s;
}
.full {
  font-size: 16px;
  font-weight: 450;
  color: var(--ink-2);
  letter-spacing: 0;
  line-height: 1.4;
  animation: rise 0.6s var(--ease-out) both 0.18s;
}
.pin {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px 8px 11px;
  border: 1.5px solid var(--ink);
  border-radius: 99px;
  background: transparent;
  font-size: 14px;
  font-weight: 600;
  transition:
    background 0.25s,
    transform 0.2s var(--ease-spring);
  animation: rise 0.6s var(--ease-out) both 0.24s;
}
.pin svg {
  width: 17px;
  height: 17px;
  fill: none;
  stroke: currentColor;
  stroke-width: 1.8;
  stroke-linejoin: round;
  transition: transform 0.5s var(--ease-spring);
}
.pin.on {
  background: var(--mari);
  border-color: var(--mari);
  color: var(--on-mari);
}
.pin.on svg {
  fill: currentColor;
  transform: rotate(144deg) scale(1.1);
}
.pin:active {
  transform: scale(0.95);
}

.tabs {
  position: relative;
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  margin-top: 18px;
}
.tabs button {
  padding: 12px 0 13px;
  border: 0;
  background: none;
  font-size: 15px;
  font-weight: 600;
  color: var(--ink-2);
  transition: color 0.2s;
}
.tabs button.on {
  color: var(--ink);
}
.tabs small {
  font-family: var(--mono);
  font-size: 11.5px;
  font-weight: 400;
  color: var(--ink-3);
  margin-left: 4px;
}
.ink {
  position: absolute;
  bottom: -1px;
  left: 0;
  width: 50%;
  height: 3px;
  border-radius: 3px 3px 0 0;
  background: var(--ink);
  transform: translateX(calc(var(--x) * 100%));
  transition: transform 0.45s var(--ease-spring);
}

.filters {
  display: flex;
  gap: 6px;
  padding: 12px 28px;
  overflow-x: auto;
  scrollbar-width: none;
  border-bottom: 1px solid var(--line);
  background: var(--sunk);
}
.chip {
  flex: none;
  padding: 6px 11px;
  border: 1px solid var(--line-strong);
  border-radius: 99px;
  background: var(--card);
  font-size: 13px;
  font-weight: 550;
  white-space: nowrap;
  transition:
    background 0.2s,
    color 0.2s,
    transform 0.25s var(--ease-spring);
}
.chip small {
  font-family: var(--mono);
  font-size: 10.5px;
  color: var(--ink-3);
  margin-left: 2px;
}
.chip.soon {
  border-color: var(--verm);
}
.chip.on {
  background: var(--ink);
  border-color: var(--ink);
  color: var(--paper);
}
.chip.on small {
  color: inherit;
  opacity: 0.7;
}
.chip:active {
  transform: scale(0.94);
}

.body {
  flex: 1;
  overflow: auto;
  padding: 6px 28px 40px;
  overscroll-behavior: contain;
}
.group h3 {
  position: sticky;
  top: 0;
  z-index: 1;
  margin: 0;
  padding: 16px 0 8px;
  background: var(--paper);
  font-family: var(--mono);
  font-size: 11px;
  font-weight: 500;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: var(--ink-3);
}
.row {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  grid-template-areas: 't arr' 'm arr';
  column-gap: 16px;
  padding: 12px 12px;
  margin: 0 -12px;
  border-radius: 10px;
  text-decoration: none;
  transition: background 0.18s;
}
.row + .row {
  box-shadow: inset 0 1px 0 var(--line);
}
.row:hover {
  background: var(--card);
  box-shadow: none;
}
.row:hover + .row {
  box-shadow: none;
}
.t {
  grid-area: t;
  font-size: 15px;
  font-weight: 560;
}
.m {
  grid-area: m;
  font-size: 12.5px;
  color: var(--ink-2);
}
.arr {
  grid-area: arr;
  align-self: center;
  color: var(--ink-3);
  transition: transform 0.3s var(--ease-out);
}
.row:hover .arr {
  transform: translate(2px, -2px);
  color: var(--mari-ink);
}
.none {
  color: var(--ink-2);
  padding: 30px 0;
}
.swap-enter-active,
.swap-leave-active {
  transition: opacity 0.14s;
}
.swap-enter-from,
.swap-leave-to {
  opacity: 0;
}

@media (max-width: 640px) {
  .head {
    padding: 14px 18px 0;
  }
  .filters,
  .body {
    padding-left: 18px;
    padding-right: 18px;
  }
}
</style>
