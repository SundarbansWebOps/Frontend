<!-- Resources — branch list beside every subject of that branch, quiz timeline in the side column. -->
<template>
  <main id="main-content" class="wrap" tabindex="-1">
    <!-- ============ the resources column ============ -->
    <div class="content">
      <SearchBar v-model="q" class="rise" style="--i: 1" />

      <!-- Always mounted so the last ticket can leave and the row can close behind it. -->
      <section
        class="mine-sec rise"
        :class="{ empty: !store.mine.length }"
        style="--i: 2"
        :inert="!store.mine.length"
        aria-labelledby="mine-h"
      >
        <div class="mine-in">
          <h2 id="mine-h" class="eyebrow">
            My courses <span class="mono">{{ store.mine.length }}</span>
          </h2>
          <TransitionGroup
            name="tix"
            tag="div"
            class="tix"
            @enter="printIn"
            @before-leave="lockSize"
          >
            <CourseTicket v-for="code in store.mine" :key="code" :code="code" />
          </TransitionGroup>
        </div>
      </section>

      <section class="study rise" style="--i: 3" aria-labelledby="study-h">
        <h2 id="study-h" class="visually-hidden">Courses</h2>
        <nav class="branches" aria-label="Branch">
          <button
            v-for="(b, id) in BRANCHES"
            :key="id"
            type="button"
            class="branch"
            :class="{ on: branch === id }"
            :aria-current="branch === id ? 'true' : undefined"
            @click="branch = id"
          >
            <span class="branch-top">
              <span class="mono">{{ b.short }}</span>
              <span class="mono count">{{ readyCount(id) }}/{{ subjectCount(id) }}</span>
            </span>
            <span class="branch-name">{{ b.label }}</span>
            <span class="meter" aria-hidden="true"><span :style="{ '--p': ratio(id) }" /></span>
          </button>
        </nav>

        <div v-if="branch" :key="branch" class="board">
          <section
            v-for="band in bands"
            :key="band.key"
            class="band"
            :aria-labelledby="`band-${band.key}`"
          >
            <h3 :id="`band-${band.key}`" class="band-h">{{ band.label }}</h3>
            <div v-for="list in band.lists" :key="list.key" class="list">
              <p v-if="list.label" class="track">{{ list.label }}</p>
              <ul class="tiles" :class="{ dense: list.items.length > 9 }">
                <li v-for="(c, i) in list.items" :key="c.code">
                  <button
                    type="button"
                    class="tile"
                    :class="{ has: hasFiles(c), mine: isMine(c.code), miss: !matches(c) }"
                    :style="{ '--i': list.offset + i }"
                    :title="c.name"
                    :aria-label="`${c.name}, ${hasFiles(c) ? 'notes available' : 'no notes yet'}`"
                    @click="open(c.code, $event)"
                  >
                    <span class="tcode mono">{{ c.code }}</span>
                    <span class="tname">{{ c.short }}</span>
                  </button>
                </li>
              </ul>
            </div>
          </section>
        </div>

        <p class="legend" aria-hidden="true">
          <span class="key has" /> Notes <span class="key" /> Not yet
        </p>
      </section>

      <!-- The map itself is hidden, but DeltaMap stays mounted because it hosts the course
           overlay (drawer) that opens when you click a course. -->
      <div v-if="branch" class="map-host">
        <DeltaMap :mine="store.mine" :match="match" :branch="branch" @open="open" />
      </div>
    </div>

    <!-- ============ RED: the quiz timeline column ============ -->
    <aside class="side rise" style="--i: 2">
      <TideLine @pick="pick" />
      <StudyCalendar />
    </aside>

    <!-- Quick links: full-width row under both columns, centred -->
    <section class="tools rise" style="--i: 5" aria-labelledby="tools-h">
      <h2 id="tools-h" class="eyebrow">Quick links</h2>
      <ToolLinks />
    </section>
  </main>
</template>

<script setup>
import { computed, ref, watch } from 'vue';
import SearchBar from '../components/site/SearchBar.vue';
import TideLine from '../components/site/TideLine.vue';
import StudyCalendar from '../components/site/StudyCalendar.vue';
import DeltaMap from '../components/site/DeltaMap.vue';
import ToolLinks from '../components/site/ToolLinks.vue';
import CourseTicket from '../components/site/CourseTicket.vue';
import { courseFor, isMine, openCourse, search, store } from '../lib/store.js';
import { BRANCHES } from '../data/branches.js';

const q = ref(store.q);
store.q = '';

// The last branch a student opened is the one shown, so the board is there on arrival.
const BRANCH_KEY = 'proto-resource-branch';
function savedBranch() {
  try {
    return localStorage.getItem(BRANCH_KEY);
  } catch {
    return null;
  }
}
const saved = savedBranch();
const branch = ref(saved && BRANCHES[saved] ? saved : 'ds');
watch(branch, (id) => {
  try {
    localStorage.setItem(BRANCH_KEY, id);
  } catch {
    // Storage can be blocked; the board still works without remembering.
  }
});

// A subject has files when its Study Corner entry has notes or past papers. Catalogue subjects
// outside Data Science resolve through courseFor, so a same-named course counts too.
function hasFiles(c) {
  const r = courseFor(c.code);
  return !!r && (r.notes.length > 0 || r.pyqs.length > 0);
}
function subjectsOf(id) {
  const b = BRANCHES[id];
  return [...b.foundation, ...b.channels.flatMap((ch) => ch.courses), ...b.degree];
}
const subjectCount = (id) => subjectsOf(id).length;
const readyCount = (id) => subjectsOf(id).filter(hasFiles).length;
const ratio = (id) => readyCount(id) / subjectCount(id);

// A ticket prints in from the top edge (clip + drop). When it was pinned from the course drawer it
// waits for the drawer to close, so the print is seen rather than played behind the backdrop.
const reduceMotion = () => matchMedia('(prefers-reduced-motion: reduce)').matches;
function printIn(el, done) {
  if (reduceMotion()) return done();
  const run = () => {
    el.style.visibility = '';
    el.animate(
      [
        { clipPath: 'inset(0 0 100% 0)', transform: 'translateY(-14px)' },
        { clipPath: 'inset(0 0 0 0)', transform: 'none' },
      ],
      {
        duration: 700,
        easing: getComputedStyle(el).getPropertyValue('--ease-out').trim() || 'ease-out',
        fill: 'backwards',
      }
    );
  };
  if (!store.sheet) return run();
  el.style.visibility = 'hidden';
  const stop = watch(
    () => store.sheet,
    (s) => {
      if (s) return;
      stop();
      setTimeout(() => el.isConnected && run(), 260);
    }
  );
}
// A leaving ticket is taken out of the flow at its own size so its neighbours slide into the gap.
function lockSize(el) {
  Object.assign(el.style, {
    width: `${el.offsetWidth}px`,
    height: `${el.offsetHeight}px`,
    left: `${el.offsetLeft}px`,
    top: `${el.offsetTop}px`,
  });
}

const res = computed(() => search(q.value));
const match = computed(() =>
  q.value.trim()
    ? new Set([...res.value.courses.map((c) => c.code), ...res.value.resources.map((r) => r.code)])
    : null
);

// The Study Corner index only holds Data Science courses, so a search inside another branch also
// scores that branch's own catalogue by code and name — otherwise "aerodynamics" in AE finds nothing.
function matchesName(c, text) {
  const t = text.trim().toLowerCase();
  if (!t) return false;
  const tight = t.replace(/\s+/g, '');
  if (tight.length >= 2 && c.code.toLowerCase().includes(tight)) return true;
  return c.name.toLowerCase().includes(t);
}
function matches(c) {
  return !match.value || match.value.has(c.code) || matchesName(c, res.value.parsed.text);
}

// The whole branch on one board: Foundation, Diploma tracks and Degree, so no level step is needed.
const bands = computed(() => {
  const b = BRANCHES[branch.value];
  if (!b) return [];
  const bandsRaw = [
    {
      key: 'foundation',
      label: 'Foundation',
      lists: [{ key: 'f', label: null, items: b.foundation ?? [] }],
    },
    {
      key: 'diploma',
      label: 'Diploma',
      lists: (b.channels ?? []).map((ch, i) => ({
        key: `d${i}`,
        label: ch.label.replace(/^DIPLOMA · /, ''),
        items: ch.courses ?? [],
      })),
    },
    { key: 'degree', label: 'Degree', lists: [{ key: 'g', label: null, items: b.degree ?? [] }] },
  ];
  let offset = 0;
  return bandsRaw.map((band) => ({
    ...band,
    lists: band.lists.map((l) => {
      const out = { ...l, offset };
      offset += l.items.length;
      return out;
    }),
  }));
});

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
const parsed = computed(() => ({
  tab: res.value.parsed.tab ?? 'pyqs',
  exam: res.value.parsed.exam ?? 'All',
  week: res.value.parsed.week,
}));
function pick(d) {
  if (d.exam) q.value = `${d.exam.toLowerCase()} pyq`;
}
</script>

<style scoped>
.wrap {
  width: 100%;
  max-width: 1720px;
  margin: 0 auto;
  padding: 20px 32px 60px;
  display: grid;
  grid-template-columns: minmax(0, 1fr) 400px;
  gap: 28px;
  align-items: start;
  background-image:
    linear-gradient(
      color-mix(in srgb, var(--paper) 92%, transparent),
      color-mix(in srgb, var(--paper) 92%, transparent)
    ),
    url('../assets/resources-study-bg-light.webp');
  background-position: center;
  background-repeat: no-repeat;
  background-size: cover;
  background-attachment: scroll;
}
:global(:root[data-theme='dark']) .wrap {
  background-image:
    linear-gradient(
      color-mix(in srgb, var(--paper) 86%, transparent),
      color-mix(in srgb, var(--paper) 86%, transparent)
    ),
    url('../assets/resources-study-bg-dark.webp');
}
.content {
  display: grid;
  width: 100%;
  min-width: 0;
}
/* Section spacing is margin, not grid gap, so the folded-away My courses row takes no space. */
.mine-sec,
.study {
  min-width: 0;
  margin-top: 28px;
}
.side {
  display: grid;
  gap: 14px;
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
  color: var(--ink-3);
}

/* ---------- My courses: tickets ---------- */
/* The row folds shut when empty (grid rows 1fr to 0fr) so the last ticket can leave first and the
 * page below slides up instead of jumping. */
.mine-sec {
  display: grid;
  grid-template-rows: 1fr;
  transition:
    grid-template-rows 0.5s var(--ease-out),
    margin-top 0.5s var(--ease-out);
}
.mine-sec.empty {
  grid-template-rows: 0fr;
  margin-top: 0;
  visibility: hidden;
  transition:
    grid-template-rows 0.5s var(--ease-out) 0.2s,
    margin-top 0.5s var(--ease-out) 0.2s,
    visibility 0s 0.7s;
}
.mine-in {
  min-height: 0;
  overflow: hidden;
}
.tix {
  position: relative;
  /* room inside the clip for the ticket's hover lift and tilt */
  padding-bottom: 6px;
  margin-bottom: -6px;
  display: grid;
  /* at most four courses, so four fixed columns; the phone block below wraps to two */
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 10px;
}
.tix-leave-active {
  position: absolute;
  transition:
    opacity 0.25s,
    transform 0.3s;
}
.tix-leave-to {
  opacity: 0;
  transform: scale(0.9) translateY(10px);
}
.tix-move {
  transition: transform 0.5s var(--ease-out);
}

/* ---------- branch list + subjects ---------- */
.branches {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 10px;
}
.branch {
  display: grid;
  gap: 9px;
  padding: 12px 14px 14px;
  border: 1px solid var(--line);
  border-radius: 12px;
  background: var(--card);
  color: var(--ink-2);
  font: inherit;
  text-align: left;
  cursor: pointer;
  transition:
    border-color 0.2s,
    color 0.2s,
    background-color 0.2s;
}
.branch:hover {
  border-color: var(--line-strong);
  color: var(--ink);
}
.branch.on {
  border-color: var(--ink);
  background: var(--sunk);
  color: var(--ink);
}
.branch-top {
  display: flex;
  justify-content: space-between;
  font-size: 11.5px;
  color: var(--ink-3);
}
.branch-name {
  font-size: 13.5px;
  line-height: 1.25;
}
.branch.on .branch-name {
  font-weight: 650;
}
.count {
  font-variant-numeric: tabular-nums;
}
.meter {
  display: block;
  height: 3px;
  border-radius: 2px;
  background: var(--line);
  overflow: hidden;
}
.meter span {
  display: block;
  height: 100%;
  width: calc(var(--p) * 100%);
  background: var(--mari);
  transition: width 0.6s var(--ease-out);
}

.board {
  margin-top: 16px;
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1.1fr) minmax(0, 1fr);
  gap: 22px;
  align-items: start;
}
.band-h {
  margin: 0 0 8px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--ink-3);
}
.list + .list {
  margin-top: 14px;
}
.track {
  margin: 0 0 6px;
  font-size: 10.5px;
  font-weight: 650;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--ink-3);
}
.tiles {
  margin: 0;
  padding: 0;
  list-style: none;
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 6px;
}
/* Long lists (AE and DS diploma tracks) go three across so the whole board stays in one screen. */
.tiles.dense {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}
.tile {
  position: relative;
  width: 100%;
  min-height: 46px;
  display: grid;
  align-content: center;
  gap: 2px;
  padding: 6px 8px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: var(--card);
  color: var(--ink);
  font: inherit;
  text-align: left;
  cursor: pointer;
  animation: tile-in 0.45s var(--ease-out) backwards;
  animation-delay: calc(var(--i, 0) * 16ms);
  transition:
    border-color 0.2s,
    transform 0.2s var(--ease-out),
    opacity 0.3s;
}
.tile.has::after {
  content: '';
  position: absolute;
  top: 9px;
  right: 9px;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--mari);
}
.tile:not(.has) {
  background: transparent;
  border-style: dashed;
  border-color: var(--line-strong);
  color: var(--ink-3);
}
.tile:hover {
  transform: translateY(-1px);
  border-color: var(--ink-2);
}
.tile.mine {
  box-shadow: inset 0 0 0 1.5px var(--mari);
}
.tile.miss {
  opacity: 0.3;
}
.tcode {
  font-size: 10.5px;
  color: var(--ink-3);
}
.tname {
  font-size: 13.5px;
  font-weight: 600;
  line-height: 1.2;
}
.tile:not(.has) .tname {
  font-weight: 500;
}
@keyframes tile-in {
  from {
    opacity: 0;
    transform: translateY(6px);
  }
}

.legend {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px 18px;
  margin: 14px 0 0;
  font-size: 12px;
  color: var(--ink-3);
}
.key {
  position: relative;
  display: inline-block;
  width: 14px;
  height: 14px;
  margin-right: 6px;
  vertical-align: -3px;
  border: 1px dashed var(--line-strong);
  border-radius: 4px;
}
.key.has {
  border: 1px solid var(--line);
  background: var(--card);
}
.key.has::after {
  content: '';
  position: absolute;
  top: 3px;
  right: 3px;
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: var(--mari);
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
    background-position: right center;
    background-size: cover;
  }
  .board {
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  }
}
@media (max-width: 560px) {
  .tix {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .branches {
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 6px;
  }
  .branch {
    padding: 9px 8px 10px;
  }
  /* Phone: the four codes and counts carry the choice; the full name stays in aria-label. */
  .branch-name {
    display: none;
  }
  .board {
    grid-template-columns: minmax(0, 1fr);
    margin-top: 12px;
    gap: 14px;
  }
  /* Phone: the whole branch has to read in one screen. The code (also in the drawer and the
   * aria-label) gives way to the name, and tiles drop to one or two lines of it. */
  .tiles,
  .tiles.dense {
    grid-template-columns: repeat(5, minmax(0, 1fr));
    gap: 4px;
  }
  .tile {
    min-height: 40px;
    padding: 5px 6px;
    align-content: center;
  }
  .tile.has::after {
    top: 6px;
    right: 6px;
  }
  .tcode {
    display: none;
  }
  .tname {
    font-size: 11.5px;
    line-height: 1.15;
    overflow-wrap: anywhere;
    hyphens: auto;
  }
  .band-h {
    margin-bottom: 6px;
  }
  .list + .list {
    margin-top: 10px;
  }
  .legend {
    margin-top: 10px;
  }
}
</style>
