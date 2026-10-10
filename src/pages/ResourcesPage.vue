<!-- Resources — "Delta": branch → level → courses, quiz timeline in the side column. -->
<template>
  <main id="main-content" class="wrap" tabindex="-1">
    <!-- ============ the resources column ============ -->
    <div class="content">
      <SearchBar v-model="q" class="rise" style="--i: 1" />

      <section class="mine rise" style="--i: 2" aria-labelledby="mine-h">
        <h2 id="mine-h" class="eyebrow">
          My courses <span v-if="store.mine.length" class="mono">{{ store.mine.length }}</span>
        </h2>
        <TransitionGroup name="tix" tag="div" class="tix">
          <CourseTicket v-for="code in store.mine" :key="code" :code="code" />
          <p v-if="!store.mine.length" key="empty" class="hint">
            <span class="dot" /> Pick your branch and level, then pin your courses. Next time the
            site opens straight to them.
          </p>
        </TransitionGroup>
      </section>

      <section class="flow rise" style="--i: 3" aria-labelledby="flow-h">
        <!-- breadcrumb -->
        <nav class="crumbs" aria-label="Where you are">
          <button
            type="button"
            :class="{ on: !branch }"
            :aria-current="!branch ? 'step' : undefined"
            @click="resetBranch"
          >
            Branch
          </button>
          <template v-if="branch">
            <span class="sep" aria-hidden="true">›</span>
            <button
              type="button"
              :class="{ on: !level }"
              :aria-current="!level ? 'step' : undefined"
              @click="level = null"
            >
              {{ BRANCHES[branch].short }}
            </button>
          </template>
          <template v-if="level">
            <span class="sep" aria-hidden="true">›</span>
            <button type="button" class="on" aria-current="step">{{ levelMeta.label }}</button>
          </template>
        </nav>

        <Transition name="step" mode="out-in">
          <!-- STEP 1 · branch -->
          <div v-if="!branch" key="branch">
            <h2 id="flow-h" class="flow-h">Choose your branch</h2>
            <p class="flow-sub">
              Everything here — the course map, calendar, notes — follows your branch.
            </p>
            <div class="branches">
              <button
                v-for="(b, id, i) in BRANCHES"
                :key="id"
                type="button"
                class="branch"
                :style="{ '--d': i * 70 + 'ms' }"
                @click="launch(id)"
              >
                <span class="mono branch-s">{{ b.short }}</span>
                <strong>{{ b.label }}</strong>
                <small>{{ b.blurb || b.desc || b.description || b.tagline || '' }}</small>
              </button>
            </div>
          </div>

          <!-- STEP 2 · level -->
          <div v-else-if="!level && !searching" key="level">
            <h2 id="flow-h" class="flow-h">Pick your level</h2>
            <p class="flow-sub">
              Every branch runs the same three levels — foundation, diploma, degree.
            </p>
            <div class="levels">
              <button
                v-for="(l, i) in LEVELS"
                :key="l.id"
                type="button"
                class="level"
                :style="{ '--d': i * 90 + 'ms' }"
                @click="level = l.id"
              >
                <span class="mono level-n">0{{ l.n }}</span>
                <strong>{{ l.label }}</strong>
                <small>{{ l.hint }}</small>
                <span class="mono level-c">{{ countFor(l.id) }} courses</span>
              </button>
            </div>
          </div>

          <!-- STEP 3 · courses (or search results across every level) -->
          <div v-else :key="searching ? 'search' : level">
            <h2 id="flow-h" class="flow-h">
              {{ searching ? 'Search results' : levelMeta.label + ' courses' }}
              <span v-if="!noResources" class="mono count">{{ shown.length }}</span>
            </h2>

            <!-- Degree level of AE and MG has no curated resources yet — invite contributions. -->
            <div v-if="noResources" class="empty">
              <span class="empty-mark" aria-hidden="true" />
              <h3>No resources available right now</h3>
              <p>Be the first to contribute — share your notes and past papers for this level.</p>
              <RouterLink class="empty-cta" to="/contribute-resources">
                Open the contribution form
              </RouterLink>
            </div>

            <div v-else class="courses">
              <div
                v-for="(c, i) in shown"
                :key="c.code"
                class="course"
                :class="{ mine: store.mine.includes(c.code) }"
                :style="{ '--d': Math.min(i, 14) * 45 + 'ms' }"
              >
                <button type="button" class="course-main" @click="open(c.code, $event)">
                  <span class="mono code">{{ c.code }}</span>
                  <strong>{{ c.name || c.title || c.code }}</strong>
                </button>
                <button
                  type="button"
                  class="pin"
                  :aria-pressed="store.mine.includes(c.code)"
                  @click="togglePin(c.code)"
                >
                  {{ store.mine.includes(c.code) ? 'Pinned' : 'Pin' }}
                </button>
              </div>
              <p v-if="!shown.length" class="hint">
                <span class="dot" />
                {{
                  searching ? 'Nothing in this branch matches that yet.' : 'No courses here yet.'
                }}
              </p>
            </div>
          </div>
        </Transition>
      </section>

      <!-- The map itself is hidden, but DeltaMap stays mounted because it hosts the course
           overlay (drawer) that opens when you click a course or a ticket. -->
      <div v-if="branch" class="map-host">
        <DeltaMap :mine="store.mine" :match="match" :branch="branch" @open="open" />
      </div>
    </div>

    <!-- ============ RED: the quiz timeline column ============ -->
    <aside class="side rise" style="--i: 2">
      <TideLine @pick="pick" />
    </aside>

    <!-- Quick links: full-width row under both columns, centred -->
    <section class="tools rise" style="--i: 5" aria-labelledby="tools-h">
      <h2 id="tools-h" class="eyebrow">Quick links</h2>
      <ToolLinks />
    </section>
  </main>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import SearchBar from '../components/site/SearchBar.vue';
import TideLine from '../components/site/TideLine.vue';
import DeltaMap from '../components/site/DeltaMap.vue';
import CourseTicket from '../components/site/CourseTicket.vue';
import ToolLinks from '../components/site/ToolLinks.vue';
import { openCourse, search, store } from '../lib/store.js';
import { byCode } from '../lib/courses.js';
import { BRANCHES } from '../data/branches.js';
import { theme } from '../lib/theme.js';

const q = ref(store.q);
const branch = ref(null);
const level = ref(null);
store.q = '';

// The Resources page is pure black in dark mode; in light mode it uses the normal paper tokens.
// The token block lives in tokens.css under :root.resources-dark.
const syncDark = () =>
  document.documentElement.classList.toggle('resources-dark', theme.value === 'dark');
onMounted(syncDark);
onBeforeUnmount(() => document.documentElement.classList.remove('resources-dark'));
watch(theme, syncDark);

// ---------- levels ----------
const LEVELS = [
  { id: 'foundation', n: 1, label: 'Foundation', hint: 'Maths, Stats, CT, English' },
  { id: 'diploma', n: 2, label: 'Diploma', hint: 'Programming & Data Science tracks' },
  { id: 'degree', n: 3, label: 'Degree', hint: 'Advanced and elective courses' },
];
const levelMeta = computed(() => LEVELS.find((l) => l.id === level.value) || LEVELS[0]);

// The branch catalogue (BRANCHES) is the source of truth for which courses belong to a branch.
// byCode only holds courses that already have notes/PYQs (Data Science today), so it is used
// purely to enrich matching entries — never to decide membership.
function branchLevels(id) {
  const b = BRANCHES[id];
  if (!b) return { foundation: [], diploma: [], degree: [] };
  return {
    foundation: b.foundation ?? [],
    diploma: (b.channels ?? []).flatMap((ch) => ch.courses ?? []),
    degree: b.degree ?? [],
  };
}
const branchCourses = computed(() => {
  if (!branch.value) return [];
  const levels = branchLevels(branch.value);
  return Object.entries(levels).flatMap(([lvl, list]) =>
    list.map((c) => {
      const study = byCode[c.code];
      return {
        ...c,
        level: lvl,
        notes: study?.notes ?? c.notes ?? [],
        pyqs: study?.pyqs ?? c.pyqs ?? [],
      };
    })
  );
});
const countFor = (id) => branchCourses.value.filter((c) => c.level === id).length;

const searching = computed(() => !!q.value.trim());
const res = computed(() => search(q.value));
const match = computed(() =>
  searching.value
    ? new Set([...res.value.courses.map((c) => c.code), ...res.value.resources.map((r) => r.code)])
    : null
);
const shown = computed(() => {
  if (!match.value) return branchCourses.value.filter((c) => c.level === level.value);
  return branchCourses.value.filter(
    (c) => match.value.has(c.code) || matchesName(c, res.value.parsed.text)
  );
});

// The Study Corner index only holds Data Science courses, so a search inside another branch also
// scores that branch's own catalogue by code and name — otherwise "aerodynamics" in AE finds nothing.
function matchesName(c, text) {
  const t = text.trim().toLowerCase();
  if (!t) return false;
  const tight = t.replace(/\s+/g, '');
  if (tight.length >= 2 && c.code.toLowerCase().includes(tight)) return true;
  return c.name.toLowerCase().includes(t);
}

// Degree level of AE and MG has no curated notes/PYQs yet, so instead of empty cards we invite
// the first contribution. The form itself lives behind the /contribute-resources doorway.
const NO_RESOURCE_DEGREE = new Set(['ae', 'mg']);
const noResources = computed(
  () => !searching.value && level.value === 'degree' && NO_RESOURCE_DEGREE.has(branch.value)
);
const parsed = computed(() => ({
  tab: res.value.parsed.tab ?? 'pyqs',
  exam: res.value.parsed.exam ?? 'All',
  week: res.value.parsed.week,
}));

function resetBranch() {
  branch.value = null;
  level.value = null;
}
function open(code, e) {
  try {
    openCourse(code, parsed.value, e);
  } catch (err) {
    console.error('openCourse failed', err);
  }
  // Fallback: the drawer is driven by ?course=CODE in the hash route, so make sure it is set.
  if (!/[?&]course=/.test(window.location.hash)) {
    const [path, qs = ''] = window.location.hash.slice(1).split('?');
    const p = new URLSearchParams(qs);
    p.set('course', code);
    window.location.hash = `${path || '/resources'}?${p.toString()}`;
  }
}
function togglePin(code) {
  const i = store.mine.indexOf(code);
  if (i === -1) store.mine.push(code);
  else store.mine.splice(i, 1);
}
function pick(d) {
  if (d.exam) q.value = `${d.exam.toLowerCase()} pyq`;
}

function launch(id) {
  branch.value = id;
  level.value = null; // next step: choose a level
}
</script>

<style scoped>
.wrap {
  --acc: var(--ink-3);
  --acc-wash: color-mix(in srgb, var(--acc) 15%, transparent);
  width: 100%;
  max-width: 1720px;
  margin: 0 auto;
  padding: 20px 32px 60px;
  display: grid;
  grid-template-columns: minmax(0, 1fr) 400px;
  gap: 28px;
  align-items: start;
}
.content {
  display: grid;
  gap: 28px;
  width: 100%;
  min-width: 0;
}
.flow {
  width: 100%;
  min-height: 420px; /* keeps the box the same size across branch / level / course steps */
}
.levels,
.courses {
  width: 100%;
}
.side {
  position: sticky;
  top: 20px;
}

/* ---------- flow: crumbs, levels, courses ---------- */
.crumbs {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 14px;
  font-size: 12.5px;
}
.crumbs button {
  padding: 4px 10px;
  border: 1.5px solid var(--line-strong);
  border-radius: 999px;
  background: transparent;
  color: var(--ink-2);
  font-weight: 600;
  cursor: pointer;
}
.crumbs button.on {
  border-color: var(--acc);
  color: var(--acc);
}
.crumbs .sep {
  color: var(--ink-2);
}
.flow-h {
  display: flex;
  align-items: baseline;
  gap: 8px;
  margin: 0 0 6px;
  font-size: clamp(24px, 2.6vw, 30px);
  font-weight: 750;
  letter-spacing: -0.035em;
  color: var(--ink);
}
.flow-h .count {
  align-self: center;
  padding: 2px 8px;
  border-radius: 99px;
  background: var(--acc-wash);
  color: var(--acc);
  font-size: 12px;
  font-weight: 600;
}
.flow-sub {
  margin: 0 0 22px;
  max-width: 62ch;
  font-size: 15px;
  line-height: 1.5;
  color: var(--ink-2);
}
.branches {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 14px;
  width: 100%;
}
.branch {
  display: grid;
  align-content: start;
  gap: 8px;
  min-height: 190px;
  padding: 20px;
  text-align: left;
  border: 1.5px solid var(--line-strong);
  border-radius: var(--r);
  background: var(--card);
  color: var(--ink);
  cursor: pointer;
  transition:
    transform 0.2s var(--ease-out),
    border-color 0.2s,
    box-shadow 0.3s var(--ease-out);
}
.branch:hover {
  transform: translateY(-3px);
  border-color: var(--acc);
  box-shadow: var(--shadow);
}
.branch-s {
  font-size: 12px;
  color: var(--acc);
}
.branch strong {
  font-size: 20px;
  line-height: 1.2;
}
.branch small {
  color: var(--ink-2);
  font-size: 13.5px;
  line-height: 1.4;
}
.levels {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 12px;
}
.level {
  display: grid;
  gap: 6px;
  padding: 18px;
  text-align: left;
  border: 1.5px solid var(--line-strong);
  border-radius: var(--r);
  background: var(--card);
  color: var(--ink);
  cursor: pointer;
  transition:
    transform 0.2s var(--ease-out),
    border-color 0.2s,
    box-shadow 0.3s var(--ease-out);
}
.level:hover {
  transform: translateY(-3px);
  border-color: var(--acc);
  box-shadow: var(--shadow);
}
.level strong {
  font-size: 18px;
}
.level small {
  color: var(--ink-2);
  font-size: 13px;
}
.level-n,
.level-c {
  font-size: 11px;
  color: var(--acc);
}
.courses {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(230px, 1fr));
  gap: 12px;
}
.course {
  display: flex;
  align-items: stretch;
  gap: 8px;
  border: 1.5px solid var(--line-strong);
  border-radius: 12px;
  background: var(--card);
  color: var(--ink);
  transition:
    border-color 0.2s,
    box-shadow 0.3s var(--ease-out);
}
.course:hover {
  border-color: var(--acc);
  box-shadow: var(--shadow);
}
.course.mine {
  border-color: var(--acc);
  background: var(--acc-wash);
}
.course-main {
  flex: 1;
  display: grid;
  gap: 4px;
  padding: 14px 0 14px 16px;
  text-align: left;
  border: 0;
  background: transparent;
  color: inherit;
  cursor: pointer;
}
.pin {
  align-self: center;
  margin-right: 12px;
  padding: 4px 10px;
  border: 1.5px solid var(--acc);
  border-radius: 999px;
  background: transparent;
  color: var(--acc);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
}
.pin[aria-pressed='true'] {
  background: var(--acc);
  color: var(--paper);
}
.course .code {
  font-size: 11px;
  color: var(--ink-2);
}

.eyebrow {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 12px;
  font-size: 13px;
  font-weight: 650;
  letter-spacing: 0.01em;
  color: var(--ink-2);
}
.eyebrow .mono {
  font-size: 11px;
  padding: 1px 6px;
  border-radius: 5px;
  background: var(--acc-wash);
  color: var(--acc);
}
.tix {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(min(270px, 100%), 1fr));
  gap: 12px;
}
.hint {
  grid-column: 1 / -1;
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 0;
  padding: 16px 18px;
  border: 1.5px dashed var(--line-strong);
  border-radius: 14px;
  color: var(--ink-2);
  font-size: 14.5px;
}
.hint .dot {
  flex: none;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: var(--acc);
  box-shadow: 0 0 0 5px var(--acc-wash);
}
.empty {
  display: grid;
  justify-items: center;
  gap: 8px;
  padding: 44px 24px;
  text-align: center;
  border: 1.5px dashed color-mix(in srgb, var(--acc) 42%, var(--line-strong));
  border-radius: 14px;
  background: color-mix(in srgb, var(--acc) 5%, var(--card));
}
.empty-mark {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: var(--acc);
  box-shadow: 0 0 0 6px var(--acc-wash);
}
.empty h3 {
  margin: 8px 0 0;
  font-size: 20px;
  font-weight: 720;
  letter-spacing: -0.03em;
  color: var(--ink);
}
.empty p {
  margin: 0;
  max-width: 52ch;
  font-size: 14.5px;
  line-height: 1.5;
  color: var(--ink-2);
}
.empty-cta {
  margin-top: 12px;
  padding: 9px 18px;
  border: 1.5px solid var(--acc);
  border-radius: 99px;
  background: var(--acc);
  color: var(--paper);
  font-size: 13.5px;
  font-weight: 620;
  text-decoration: none;
  transition:
    transform 0.2s var(--ease-out),
    box-shadow 0.3s var(--ease-out);
}
.empty-cta:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow);
}
.tix-enter-active {
  animation: print 0.7s var(--ease-out) both;
}
.tix-leave-active {
  transition:
    opacity 0.25s,
    transform 0.3s;
  position: absolute;
}
.tix-leave-to {
  opacity: 0;
  transform: scale(0.9) translateY(10px);
}
.tix-move {
  transition: transform 0.5s var(--ease-out);
}
@keyframes print {
  from {
    clip-path: inset(0 0 100% 0);
    transform: translateY(-14px);
  }
  to {
    clip-path: inset(0 0 0 0);
  }
}

/* ---------- course map ---------- */
.tools {
  grid-column: 1 / -1;
  width: 100%;
  padding-top: 26px;
  border-top: 1px solid var(--line);
}
.map-host {
  position: absolute;
  width: 0;
  height: 0;
  overflow: hidden; /* does not clip position:fixed children, so the overlay still shows */
}

/* ---------- colour: tinted panels so light mode isn't flat white ---------- */
.flow {
  padding: 24px;
  border: 1.5px solid color-mix(in srgb, var(--acc) 28%, var(--line-strong));
  border-radius: 20px;
  background: color-mix(in srgb, var(--acc) 4%, var(--card));
}
.branch,
.level,
.course {
  border-color: color-mix(in srgb, var(--acc) 32%, var(--line-strong));
  border-top: 4px solid var(--acc);
  background: color-mix(in srgb, var(--acc) 9%, var(--card));
}
.branch:hover,
.level:hover,
.course:hover {
  background: color-mix(in srgb, var(--acc) 16%, var(--card));
}
.course.mine {
  background: color-mix(in srgb, var(--acc) 22%, var(--card));
}
.crumbs button.on {
  background: color-mix(in srgb, var(--acc) 14%, transparent);
}

/* ---------- motion ---------- */
.step-enter-active,
.step-leave-active {
  transition:
    opacity 0.25s ease,
    transform 0.3s var(--ease-out);
}
.step-enter-from {
  opacity: 0;
  transform: translateX(28px);
}
.step-leave-to {
  opacity: 0;
  transform: translateX(-28px);
}
.crumbs {
  animation: fade-up 0.5s var(--ease-out) backwards;
}
.branch,
.level,
.course {
  animation: pop-in 0.55s var(--ease-out) backwards;
  animation-delay: var(--d, 0ms);
}
.branch:active,
.level:active,
.course:active {
  transform: scale(0.97);
}
.pin {
  transition:
    background 0.2s,
    color 0.2s,
    transform 0.2s var(--ease-out);
}
.pin:active {
  transform: scale(0.88);
}
.pin[aria-pressed='true'] {
  animation: pinned 0.4s var(--ease-out);
}
@keyframes pop-in {
  from {
    opacity: 0;
    transform: translateY(20px) scale(0.95);
  }
}
@keyframes fade-up {
  from {
    opacity: 0;
    transform: translateY(12px);
  }
}
@keyframes pinned {
  50% {
    transform: scale(1.18);
  }
}
@media (prefers-reduced-motion: reduce) {
  .branch,
  .level,
  .course,
  .crumbs,
  .pin {
    animation: none;
  }
  .step-enter-active,
  .step-leave-active {
    transition: none;
  }
}

/* ---------- responsive ---------- */
@media (max-width: 1020px) {
  .wrap {
    grid-template-columns: minmax(0, 1fr);
  }
  .side {
    position: static;
  }
}
@media (max-width: 760px) {
  .wrap {
    padding: 14px 16px 100px;
    gap: 22px;
  }
  .tix {
    grid-template-columns: none;
    grid-auto-flow: column;
    grid-auto-columns: 82%;
    overflow-x: auto;
    scroll-snap-type: x mandatory;
    padding-bottom: 6px;
    margin: 0 -16px;
    padding-left: 16px;
    padding-right: 16px;
    scrollbar-width: none;
  }
  .tix > * {
    scroll-snap-align: start;
  }
}
</style>
