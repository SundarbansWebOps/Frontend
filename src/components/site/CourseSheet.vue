<!--
  One course, everything a student opens it for: past papers by exam, notes by week.
  Drawn like the Delta map: hairlines draw in, the course node pops, rows flow in.
  Opens with a tide-like reveal that starts wherever the student tapped.
-->
<template>
  <Teleport to="body">
    <Transition :css="false" @enter="enter" @leave="leave">
      <div v-if="course" class="root" @keydown.esc="closeCourse">
        <div class="backdrop" @click="closeCourse" />
        <aside
          ref="panel"
          class="panel"
          :class="{ settled }"
          role="dialog"
          aria-modal="true"
          :aria-label="`${course.short} resources`"
          tabindex="-1"
          @keydown="trapTab"
        >
          <span class="edge" aria-hidden="true" />
          <header class="head">
            <div class="top">
              <p class="cap">
                <i class="node" :class="{ mine: pinned }" aria-hidden="true" />
                <span class="mono">{{ course.code }}</span>
                <span class="lvl">{{ LEVEL[course.track] }}</span>
              </p>
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
              :aria-pressed="pinned"
              @click="togglePin(course.code)"
            >
              <span class="stub">
                <svg viewBox="0 0 24 24" aria-hidden="true">
                  <path v-if="pinned" class="tick" pathLength="1" d="m5 12.5 4.5 4.5L19 7.5" />
                  <path v-else d="M12 5v14M5 12h14" />
                </svg>
              </span>
              <span class="lab">{{ pinned ? 'In my courses' : 'Add to my courses' }}</span>
            </button>

            <nav ref="nav" class="tabs" role="tablist" aria-label="Course materials">
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
              <i class="ink" :style="{ '--x': ind.x + 'px', '--w': ind.w + 'px' }" />
            </nav>
          </header>

          <div class="filters">
            <template v-if="tab === 'pyqs'">
              <button
                v-for="(e, k) in examOptions"
                :key="e.id"
                type="button"
                class="f"
                :class="{ on: exam === e.id, soon: e.id === nextExam?.exam }"
                :aria-pressed="exam === e.id"
                :style="{ '--k': k }"
                @click="exam = e.id"
              >
                <span class="lbl">{{ e.id }}</span> <small>{{ e.n }}</small>
              </button>
            </template>
            <template v-else>
              <button
                type="button"
                class="f"
                :class="{ on: week === null }"
                :aria-pressed="week === null"
                style="--k: 0"
                @click="week = null"
              >
                <span class="lbl">All</span> <small>{{ course.notes.length }}</small>
              </button>
              <button
                v-for="(w, k) in weekOptions"
                :key="w.id"
                type="button"
                class="f"
                :class="{ on: week === w.id, soon: w.id === currentWeek }"
                :aria-pressed="week === w.id"
                :title="w.id === currentWeek ? 'This week' : ''"
                :style="{ '--k': k + 1 }"
                @click="week = w.id"
              >
                <span class="lbl">{{ w.id === 0 ? 'General' : 'W' + w.id }}</span>
                <small>{{ w.n }}</small>
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
                <section v-for="g in groups" :key="g.label" class="group">
                  <h3 :style="{ '--i': Math.min(g.start, 12) }">
                    <span>{{ g.label }}</span>
                  </h3>
                  <a
                    v-for="(r, i) in g.items"
                    :key="r.link + i"
                    class="row"
                    :href="r.link"
                    target="_blank"
                    rel="noopener"
                    :style="{ '--i': Math.min(g.start + i + 1, 12) }"
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
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import {
  closeCourse,
  courseFor,
  getCourseOpener,
  isMine,
  store,
  togglePin,
} from '../../lib/store.js';
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
const nav = ref(null);
const copied = ref(false);
// The first second is the opening sequence; after that, swapping a tab or filter replays only the
// rows, without the opening delay.
const settled = ref(false);
const ind = ref({ x: 0, w: 0 });
let settleTimer = 0;
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
    settled.value = false;
    clearTimeout(settleTimer);
    settleTimer = setTimeout(() => (settled.value = true), 1100);
    nextTick(() => {
      panel.value?.focus({ preventScroll: true });
      measureTab();
    });
    document.fonts?.ready.then(measureTab);
  },
  { immediate: true }
);
// The tab underline is as wide as its label and travels to the active tab.
function measureTab() {
  const el = nav.value?.querySelector('[aria-selected="true"]');
  if (el) ind.value = { x: el.offsetLeft, w: el.offsetWidth };
}
watch(tab, () => nextTick(measureTab));
onMounted(() => window.addEventListener('resize', measureTab));
onBeforeUnmount(() => {
  window.removeEventListener('resize', measureTab);
  clearTimeout(settleTimer);
  restoreModalState();
});

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
    return indexed([...map.entries()].sort(([a], [b]) => weekNum(a) - weekNum(b)));
  }
  return indexed([...map.entries()]);
});
// `start` is the running row number before each group, so the entrance stagger flows across groups.
function indexed(entries) {
  let start = 0;
  return entries.map(([label, items]) => {
    const g = { label, items, start };
    start += items.length + 1;
    return g;
  });
}
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

// Open: the backdrop settles while a circle grows from the tap point across the panel (the tide).
// It stops exactly at the farthest corner, and its easing is still moving there: a strong
// ease-out (and a radius past the corner) left the corners filling in a slow tail that read as a
// stall. The content then lands in CSS, in order: edge hairline, course node, title, action, tabs,
// filters, rows.
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
// Close: quicker than open. The sheet slides back toward the edge it came from and fades while the
// backdrop lifts, so the page is readable again by the time it is gone.
function leave(el, done) {
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) return done();
  const p = el.querySelector('.panel');
  const b = el.querySelector('.backdrop');
  const easing = getComputedStyle(el).getPropertyValue('--ease-out').trim() || 'ease-out';
  b.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 260, easing, fill: 'forwards' });
  p.animate(
    [
      { transform: 'none', opacity: 1 },
      { transform: 'translateX(36px)', opacity: 0 },
    ],
    { duration: 260, easing, fill: 'forwards' }
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
  /* where the opening sequence starts; set to 0 once the first second has passed */
  --base: 0.34s;
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  width: min(660px, 100%);
  display: flex;
  flex-direction: column;
  background: var(--card);
  outline: none;
}
.panel.settled {
  --base: 0s;
}
/* the sheet's left edge: one hairline that draws top to bottom, like a channel on the map */
.edge {
  position: absolute;
  top: 0;
  bottom: 0;
  left: 0;
  width: 1px;
  background: var(--line-strong);
  transform-origin: top;
  animation: draw 0.7s var(--ease-out) 0.08s both;
}
.head {
  padding: 18px 28px 0;
}
.top {
  display: flex;
  align-items: center;
  gap: 4px;
}
.cap {
  flex: 1;
  min-width: 0;
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 0;
  font-size: 11.5px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--ink-3);
  animation: fade-up 0.5s var(--ease-out) 0.12s both;
}
.cap .mono {
  color: var(--ink-2);
}
.lvl::before {
  content: '·';
  margin-right: 10px;
}
/* the course as a node on the map: open until it is in My courses, then marigold */
.node {
  flex: none;
  width: 11px;
  height: 11px;
  border: 2px solid var(--ink);
  border-radius: 50%;
  background: var(--paper);
  animation: pop 0.6s var(--ease-spring) 0.14s both;
  transition: background-color 0.3s;
}
.node.mine {
  background: var(--mari);
}
.icon {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  border: 0;
  border-radius: 8px;
  background: none;
  color: var(--ink-2);
  transition:
    background-color 0.2s,
    color 0.2s,
    transform 0.2s var(--ease-spring);
}
.icon:hover {
  background: var(--sunk);
  color: var(--ink);
}
.icon:active {
  transform: scale(0.92);
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
  margin: 16px 0 14px;
  display: grid;
  gap: 4px;
  line-height: 1;
}
.short {
  font-size: clamp(34px, 6vw, 52px);
  font-weight: 750;
  letter-spacing: -0.035em;
  animation: rise 0.6s var(--ease-out) 0.16s both;
}
.full {
  font-size: 16px;
  font-weight: 450;
  color: var(--ink-2);
  letter-spacing: 0;
  line-height: 1.4;
  animation: rise 0.6s var(--ease-out) 0.22s both;
}
/* Add to my courses: a small ticket. The stub fills marigold when the course is pinned. */
.pin {
  display: inline-grid;
  grid-template-columns: 36px auto;
  align-items: stretch;
  height: 38px;
  padding: 0;
  border: 1px solid var(--line-strong);
  border-radius: 9px;
  background: transparent;
  font-size: 13.5px;
  font-weight: 600;
  overflow: hidden;
  transition:
    border-color 0.2s,
    transform 0.2s var(--ease-spring);
  animation: rise 0.6s var(--ease-out) 0.28s both;
}
.pin:hover {
  border-color: var(--ink);
}
.pin:active {
  transform: scale(0.97);
}
.pin .stub {
  display: grid;
  place-items: center;
  border-right: 2px dashed var(--line-strong);
  transition:
    background-color 0.25s,
    border-color 0.25s;
}
.pin.on .stub {
  background: var(--mari);
  color: var(--on-mari);
  border-right-color: color-mix(in srgb, var(--on-mari) 35%, transparent);
  animation: pop 0.5s var(--ease-spring) both;
}
.pin svg {
  width: 17px;
  height: 17px;
  fill: none;
  stroke: currentColor;
  stroke-width: 2;
  stroke-linecap: round;
  stroke-linejoin: round;
}
.pin .tick {
  stroke-dasharray: 1;
  animation: draw-line 0.4s var(--ease-out) 0.12s both;
}
.pin .lab {
  display: grid;
  align-items: center;
  padding: 0 14px 0 12px;
}

.tabs {
  position: relative;
  display: flex;
  gap: 28px;
  margin-top: 20px;
  border-bottom: 1px solid var(--line);
  animation: fade-up 0.5s var(--ease-out) 0.32s both;
}
.tabs button {
  padding: 12px 0 13px;
  border: 0;
  background: none;
  font-size: 15px;
  font-weight: 600;
  color: var(--ink-3);
  transition: color 0.2s;
}
.tabs button:hover,
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
/* the underline is as wide as the active label; it springs across and resizes to the next one */
.ink {
  position: absolute;
  bottom: -1px;
  left: 0;
  width: var(--w, 0);
  height: 2px;
  background: var(--ink);
  translate: var(--x, 0) 0;
  transform-origin: left;
  transition:
    translate 0.45s var(--ease-spring),
    width 0.35s var(--ease-out);
  animation: draw-x 0.6s var(--ease-out) 0.4s both;
}

.filters {
  display: flex;
  gap: 22px;
  padding: 0 28px;
  overflow-x: auto;
  scrollbar-width: none;
  border-bottom: 1px solid var(--line);
}
.f {
  position: relative;
  flex: none;
  padding: 11px 0 12px;
  border: 0;
  background: none;
  font-size: 13px;
  font-weight: 550;
  color: var(--ink-3);
  white-space: nowrap;
  transition: color 0.2s;
  animation: fade-up 0.45s var(--ease-out) calc(var(--base) + var(--k, 0) * 35ms) both;
}
.f small {
  font-family: var(--mono);
  font-size: 10.5px;
  color: var(--ink-3);
  margin-left: 4px;
}
.f:hover,
.f.on {
  color: var(--ink);
}
/* the active filter is underlined in marigold; the line draws in from the left */
.f::after {
  content: '';
  position: absolute;
  right: 0;
  bottom: 0;
  left: 0;
  height: 2px;
  background: var(--mari);
  transform: scaleX(0);
  transform-origin: right;
  transition: transform 0.35s var(--ease-out);
}
.f.on::after {
  transform: scaleX(1);
  transform-origin: left;
}
/* the next exam, or this week, carries a small vermilion mark */
.f.soon .lbl::after {
  content: '';
  display: inline-block;
  width: 5px;
  height: 5px;
  margin-left: 4px;
  vertical-align: 0.45em;
  border-radius: 50%;
  background: var(--verm);
}

.body {
  flex: 1;
  overflow: auto;
  padding: 0 28px 40px;
  overscroll-behavior: contain;
}
.group h3 {
  position: sticky;
  top: 0;
  z-index: 1;
  display: flex;
  align-items: center;
  gap: 14px;
  margin: 0;
  padding: 20px 0 8px;
  background: var(--card);
  font-family: var(--mono);
  font-size: 11px;
  font-weight: 500;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: var(--ink-3);
  animation: fade-up 0.45s var(--ease-out) calc(var(--base) + 0.06s + var(--i, 0) * 30ms) both;
}
/* the term's rule draws out from its label */
.group h3::after {
  content: '';
  flex: 1;
  height: 1px;
  background: var(--line-strong);
  transform-origin: left;
  animation: draw-x 0.7s var(--ease-out) calc(var(--base) + 0.1s + var(--i, 0) * 30ms) both;
}
.row {
  position: relative;
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  grid-template-areas: 't arr' 'm arr';
  column-gap: 16px;
  padding: 13px 0 14px;
  text-decoration: none;
  transform-origin: left center;
  transition:
    translate 0.35s var(--ease-out),
    scale 0.35s var(--ease-out);
  animation: fade-up 0.5s var(--ease-out) calc(var(--base) + 0.1s + var(--i, 0) * 30ms) both;
}
/* A quiet slide and grow on the hovered row; no underline or fill. Individual translate/scale
   keep clear of the entrance animation, which animates transform. */
.row:hover {
  translate: 6px 0;
  scale: 1.01;
}
.row::after {
  content: '';
  position: absolute;
  right: 0;
  bottom: 0;
  left: 0;
  height: 1px;
  background: var(--line);
  transform-origin: left;
  animation: draw-x 0.7s var(--ease-out) calc(var(--base) + 0.14s + var(--i, 0) * 30ms) both;
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
  transition:
    transform 0.3s var(--ease-spring),
    color 0.2s;
}
.row:hover .arr {
  transform: translate(3px, -3px);
  color: var(--mari-ink);
}
.none {
  color: var(--ink-2);
  padding: 30px 0;
}
.swap-enter-active,
.swap-leave-active {
  transition: opacity 0.12s;
}
.swap-leave-to {
  opacity: 0;
}

@keyframes fade-up {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
}
@keyframes draw {
  from {
    transform: scaleY(0);
  }
}
@keyframes draw-x {
  from {
    transform: scaleX(0);
  }
}
@keyframes draw-line {
  from {
    stroke-dashoffset: 1;
  }
}
@keyframes pop {
  from {
    transform: scale(0);
  }
}

@media (max-width: 640px) {
  .head {
    padding: 14px 18px 0;
  }
  .filters {
    padding: 0 18px;
  }
  .body {
    padding-left: 18px;
    padding-right: 18px;
  }
}
/* tokens.css shortens every duration; entrance delays would still hold content back */
@media (prefers-reduced-motion: reduce) {
  .edge,
  .cap,
  .node,
  .short,
  .full,
  .pin,
  .tabs,
  .ink,
  .f,
  .group h3,
  .group h3::after,
  .row,
  .row::after,
  .pin .tick,
  .pin.on .stub {
    animation: none;
  }
}
</style>
