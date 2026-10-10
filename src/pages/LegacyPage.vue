<!--
  Legacy Board (concept A, Five Landings). One viewport: two arched leaders, a
  ten-seat deck, and a river of five years. The boat glides to the chosen post;
  the council fades, then rises once the boat has docked. Water never animates.
  The public TopNav and theme stay; this page adds no second theme system.
-->
<template>
  <main id="main-content" class="board" tabindex="-1" :style="crestStyle">
    <header class="top rise" style="--i: 0">
      <div class="title">
        <p class="kicker">Since {{ FOUNDED }}</p>
        <h1>Legacy Board</h1>
      </div>
      <RouterLink class="back" to="/teams">Back to Teams</RouterLink>
    </header>

    <nav ref="riverRef" class="river" :style="riverStyle" aria-label="Years">
      <button
        v-for="(year, i) in YEARS"
        :key="year"
        :ref="(el) => bindPost(el, i)"
        type="button"
        class="post"
        :class="{ 'has-art': postArt[i] }"
        :style="{ '--i': i }"
        :aria-pressed="selected === year ? 'true' : 'false'"
        :aria-current="selected === year ? 'true' : undefined"
        @click="go(year)"
      >
        <span class="stake" aria-hidden="true" />
        <img class="post-img" :src="mooringArt" alt="" decoding="async" @load="markPost(i)" />
        <span class="post-tag">{{ year }}</span>
      </button>
      <div
        ref="boatRef"
        class="boat"
        :class="{ 'dock-right': dockRight, still: boatStill, docked, ready: boatReady }"
        aria-hidden="true"
      >
        <img class="boat-img" :src="boatArt" alt="" width="1200" height="494" decoding="async" />
      </div>
    </nav>

    <section
      class="stage"
      aria-labelledby="council-h"
      @pointerdown="onPointerDown"
      @pointerup="onPointerUp"
      @pointercancel="onPointerCancel"
    >
      <div ref="councilRef" class="council" :class="phase">
        <h2 id="council-h" class="visually-hidden">Council {{ shownYear }}</h2>
        <p class="visually-hidden" aria-live="polite">{{ liveText }}</p>
        <p class="year-mark arrive" style="--i: 0" aria-hidden="true">{{ shownYear }}</p>
        <div v-if="council" class="leaders">
          <div
            v-for="(person, k) in leaders"
            :key="person.key"
            class="leader arrive"
            :class="k === 0 ? 'is-secretary' : 'is-deputy'"
            :style="{ '--i': k }"
          >
            <div class="arch" :class="{ 'has-art': archReady[person.key] }">
              <div class="slot">
                <div class="frame">
                  <img v-if="person.photo" :src="person.photo" :alt="person.name" />
                </div>
              </div>
              <img
                class="arch-art"
                :src="archFrame"
                alt=""
                decoding="async"
                @load="markArch(person.key)"
              />
            </div>
            <div class="leader-text">
              <p class="name">{{ person.name }}</p>
              <p class="role">{{ person.role }}</p>
            </div>
          </div>
        </div>
        <div v-if="teamRows.length" class="deck arrive" style="--i: 2">
          <div v-for="(row, ri) in teamRows" :key="ri" class="deck-row">
            <div
              v-for="(member, mi) in row"
              :key="member.id"
              class="member"
              :style="{ '--i': seatDelay(ri, mi) }"
            >
              <div class="frame">
                <img v-if="member.photo" :src="member.photo" alt="Team member" />
              </div>
              <p class="member-cap">Team member</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  </main>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import archFrame from '../assets/legacy/a-arch-frame.webp';
import boatArt from '../assets/legacy/a-boat.webp';
import mooringArt from '../assets/legacy/a-mooring.webp';
import crest from '../assets/crest.webp';
import plateDay from '../components/lounge/home/art/plate-day-1536.webp';
import plateNight from '../components/lounge/home/art/plate-night-1536.webp';
import { FOUNDED, LEGACY } from '../data/legacy.data.js';
import { theme } from '../lib/theme.js';

const YEARS = LEGACY.map((d) => d.year);
const DEFAULT_YEAR = YEARS[YEARS.length - 1];
const DOCK_MS = 600;

const route = useRoute();
const router = useRouter();

const crestStyle = { '--crest': `url("${crest}")` };
const riverStyle = computed(() => ({
  backgroundImage: `url("${theme.value === 'dark' ? plateNight : plateDay}")`,
}));

const reduceQuery = matchMedia('(prefers-reduced-motion: reduce)');
const motionOff = () => reduceQuery.matches || document.hidden;

function queryValue(value) {
  return Array.isArray(value) ? value[0] : value;
}

function parsedYear() {
  const v = queryValue(route.query.year);
  if (v == null || v === '') return DEFAULT_YEAR;
  const n = Number(v);
  return YEARS.includes(n) ? n : DEFAULT_YEAR;
}

// The URL is canonical when it carries exactly what this year needs: no query for the default
// year, `?year=N` for any other.
function queryRepresents(year) {
  const raw = route.query.year;
  return year === DEFAULT_YEAR ? raw === undefined : raw === String(year);
}

const teamMax = computed(() => {
  const n = Number.parseInt(queryValue(route.query.team) ?? '', 10);
  if (Number.isNaN(n)) return 10;
  return Math.min(10, Math.max(0, n));
});

const shownYear = ref(parsedYear());
const selected = ref(null);
const phase = ref(motionOff() ? '' : 'pre');
const docked = ref(true);
const dockRight = ref(false);
const boatStill = ref(true);
const boatReady = ref(false);
const postArt = reactive(YEARS.map(() => false));
const archReady = reactive({ secretary: false, deputy: false });

const council = computed(() => LEGACY.find((d) => d.year === shownYear.value) ?? null);
const leaders = computed(() => {
  const c = council.value;
  if (!c) return [];
  return [
    { key: 'secretary', ...c.secretary },
    { key: 'deputy', ...c.deputy },
  ];
});
const teamRows = computed(() => {
  const members = council.value?.team.slice(0, teamMax.value) ?? [];
  if (!members.length) return [];
  const cut = Math.ceil(members.length / 2);
  return [members.slice(0, cut), members.slice(cut)].filter((row) => row.length);
});
const liveText = computed(() => {
  const c = council.value;
  if (!c) return '';
  return `Council ${c.year}. ${c.secretary.name}, Secretary. ${c.deputy.name}, Deputy Secretary.`;
});

function seatDelay(rowIndex, index) {
  let seat = index;
  for (let r = 0; r < rowIndex; r++) seat += teamRows.value[r].length;
  return (2 + seat * 0.3).toFixed(2);
}

const riverRef = ref(null);
const boatRef = ref(null);
const councilRef = ref(null);
const postRefs = [];

function bindPost(el, i) {
  postRefs[i] = el ?? null;
}

function markArch(key) {
  archReady[key] = true;
}

function markPost(i) {
  if (postArt[i]) return;
  postArt[i] = true;
  nextTick(() => {
    if (selected.value != null) placeBoat(YEARS.indexOf(selected.value), false);
  });
}

function adoptLoadedArt() {
  postRefs.forEach((post, i) => {
    const img = post?.querySelector('.post-img');
    if (img?.complete && img.naturalWidth) postArt[i] = true;
  });
  councilRef.value?.querySelectorAll('.arch').forEach((arch) => {
    const img = arch.querySelector('.arch-art');
    const key = arch.closest('.leader')?.classList.contains('is-deputy') ? 'deputy' : 'secretary';
    if (img?.complete && img.naturalWidth) archReady[key] = true;
  });
}

// Dock beside the selected post, on its left with the bow toward it. The first post on a
// narrow screen has no room on the left, so the boat sits on its right instead.
let placeGen = 0;
function placeBoat(i, animate) {
  const gen = ++placeGen;
  const write = (attempt) => {
    if (gen !== placeGen) return;
    const riverEl = riverRef.value;
    const boatEl = boatRef.value;
    const post = postRefs[i];
    if (!riverEl || !boatEl || !post || riverEl.clientWidth === 0) {
      if (attempt < 8) requestAnimationFrame(() => write(attempt + 1));
      return;
    }
    const rr = riverEl.getBoundingClientRect();
    const stemEl = (
      postArt[i] ? post.querySelector('.post-img') : post.querySelector('.stake')
    ).getBoundingClientRect();
    const gap = 2;
    const centre = stemEl.left - rr.left + stemEl.width / 2;
    const boatW = boatEl.offsetWidth;
    let x = centre - stemEl.width / 2 - gap - boatW;
    const right = x < 4;
    if (right) x = centre + stemEl.width / 2 + gap;
    const transform = `translate3d(${Math.round(x)}px,0,0)`;
    dockRight.value = right;
    // A failed first measure retries as a jump so the boat does not glide in from 0.
    boatStill.value = !animate || attempt > 0;
    nextTick(() => {
      if (gen !== placeGen || !boatRef.value) return;
      boatRef.value.style.transform = transform;
      boatReady.value = true;
    });
  };
  write(0);
}

let token = 0;
let timer = 0;
let resizeFrame = 0;
let startX = null;
let startY = 0;

// While a replace is in flight the route still shows the old year, so a newer choice must
// always navigate; vue-router cancels the older pending one and the latest choice wins.
let replacing = 0;
function syncUrl(year) {
  if (!replacing && queryRepresents(year)) return;
  const query = { ...route.query };
  if (year === DEFAULT_YEAR) delete query.year;
  else query.year = String(year);
  replacing += 1;
  router
    .replace({ query })
    .catch(() => {})
    .finally(() => {
      replacing -= 1;
    });
}

function snap() {
  token += 1;
  clearTimeout(timer);
  timer = 0;
  if (selected.value == null) return;
  shownYear.value = selected.value;
  phase.value = '';
  docked.value = true;
  nextTick(() => placeBoat(YEARS.indexOf(selected.value), false));
}

function go(year, { instant = false } = {}) {
  const i = YEARS.indexOf(year);
  if (i < 0 || year === selected.value) return;
  const first = selected.value == null;
  selected.value = year;
  const my = ++token;
  clearTimeout(timer);
  syncUrl(year);

  const jump = first || instant || motionOff();
  if (jump) {
    shownYear.value = year;
    phase.value = '';
    docked.value = true;
    placeBoat(i, false);
    return;
  }

  docked.value = false;
  placeBoat(i, true);
  phase.value = 'out';
  timer = window.setTimeout(() => {
    if (my !== token) return;
    shownYear.value = year;
    phase.value = 'pre';
    docked.value = true;
    nextTick(() => {
      if (my !== token || !councilRef.value) return;
      void councilRef.value.offsetWidth;
      if (my !== token) return;
      phase.value = '';
    });
  }, DOCK_MS);
}

function step(d) {
  const next = YEARS[YEARS.indexOf(selected.value) + d];
  if (next !== undefined) go(next);
}

function onKey(e) {
  if (e.defaultPrevented || e.altKey || e.ctrlKey || e.metaKey || e.shiftKey) return;
  if (e.key !== 'ArrowLeft' && e.key !== 'ArrowRight') return;
  // Only when nothing else owns the arrows: the page itself, the year posts or the stage.
  const t = e.target;
  const free = t === document.body || t === document.documentElement;
  if (!free && !t?.closest?.('.river, .stage')) return;
  e.preventDefault();
  step(e.key === 'ArrowLeft' ? -1 : 1);
}

function onPointerDown(e) {
  if (e.pointerType === 'mouse') return;
  startX = e.clientX;
  startY = e.clientY;
  e.currentTarget.setPointerCapture?.(e.pointerId);
}

function onPointerUp(e) {
  if (startX === null) return;
  const dx = e.clientX - startX;
  const dy = e.clientY - startY;
  startX = null;
  if (Math.abs(dx) > 48 && Math.abs(dx) > Math.abs(dy) * 1.5) step(dx < 0 ? 1 : -1);
}

function onPointerCancel() {
  startX = null;
}

function onResize() {
  cancelAnimationFrame(resizeFrame);
  resizeFrame = requestAnimationFrame(() => {
    if (selected.value != null) placeBoat(YEARS.indexOf(selected.value), false);
  });
}

function onVisibility() {
  if (document.hidden || reduceQuery.matches) snap();
  else if (selected.value != null) placeBoat(YEARS.indexOf(selected.value), false);
}

watch(
  () => route.query.year,
  () => {
    const year = parsedYear();
    if (year !== selected.value) go(year);
    else syncUrl(year);
  }
);

onMounted(async () => {
  adoptLoadedArt();
  await nextTick();
  const year = shownYear.value;
  selected.value = year;
  docked.value = true;
  placeBoat(YEARS.indexOf(year), false);
  if (phase.value === 'pre' && councilRef.value) void councilRef.value.offsetWidth;
  phase.value = '';
  syncUrl(year);
  document.addEventListener('keydown', onKey);
  document.addEventListener('visibilitychange', onVisibility);
  reduceQuery.addEventListener('change', onVisibility);
  window.addEventListener('resize', onResize);
});

onBeforeUnmount(() => {
  token += 1;
  placeGen += 1;
  clearTimeout(timer);
  cancelAnimationFrame(resizeFrame);
  document.removeEventListener('keydown', onKey);
  document.removeEventListener('visibilitychange', onVisibility);
  reduceQuery.removeEventListener('change', onVisibility);
  window.removeEventListener('resize', onResize);
});
</script>

<style scoped>
/* Tuned slot from the approved board. The webp's clear aperture measures
   13.9% 16.5% 12% 16.5%; 14% 20% 15% 20% is the inset that keeps the
   placeholder inside the arch the way the prototype does. */
.board {
  --edge: 15%;
  --step: 20%;
  --water: 12%;
  --slot-inset: 14% 20% 15% 20%;
  --arch-h: clamp(230px, 44vh, 440px);
  --m-w: clamp(96px, 7.4vw, 108px);
  --post-h: clamp(48px, 11vh, 100px);
  --boat-w: clamp(104px, 12.2vw, 176px);
  --tab-h: 0px;
  height: calc(100dvh - var(--nav-h) - var(--tab-h));
  display: grid;
  grid-template-rows: auto minmax(0, 1fr) minmax(96px, 20vh);
  grid-template-areas: 'top' 'stage' 'river';
  overflow: hidden;
  background: var(--paper);
  color: var(--ink);
}

.top {
  grid-area: top;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: clamp(8px, 1.4vh, 16px) clamp(16px, 3vw, 44px) clamp(2px, 0.6vh, 8px);
}
.title {
  display: grid;
  gap: 2px;
  min-width: 0;
}
.kicker {
  margin: 0;
  font-size: 11px;
  font-weight: 650;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--ink-3);
}
h1 {
  margin: 0;
  font-size: clamp(26px, 3.2vw, 40px);
  font-weight: 750;
  letter-spacing: -0.03em;
  line-height: 1;
}
.back {
  flex: none;
  font-size: 13px;
  font-weight: 650;
  color: var(--ink-2);
  text-decoration: none;
}
.back:hover {
  color: var(--ink);
}

.river {
  grid-area: river;
  position: relative;
  min-height: 0;
  overflow: hidden;
  background-color: var(--sunk);
  background-position: center 40%;
  background-size: cover;
  background-repeat: no-repeat;
  border-top: 1.5px solid var(--line-strong);
}
.post {
  position: absolute;
  bottom: var(--water);
  left: calc(var(--edge) + var(--i) * var(--step));
  z-index: 1;
  transform: translateX(-50%);
  display: flex;
  flex-direction: column-reverse;
  align-items: center;
  gap: 6px;
  padding: 0;
  border: 0;
  background: none;
  color: inherit;
  font: inherit;
  cursor: pointer;
}
.post-img {
  display: none;
  width: auto;
  height: var(--post-h);
}
.stake {
  display: block;
  width: 8px;
  height: var(--post-h);
  border-radius: 3px 3px 0 0;
  background: linear-gradient(90deg, var(--ink-2), var(--ink));
}
.post.has-art .post-img {
  display: block;
}
.post.has-art .stake {
  display: none;
}
.post-tag {
  padding: 2px 7px;
  border: 1px solid transparent;
  border-radius: 999px;
  background: color-mix(in srgb, var(--card) 55%, transparent);
  color: var(--ink-2);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.04em;
  line-height: 1.5;
  font-variant-numeric: tabular-nums;
}
.post:hover .post-tag {
  color: var(--ink);
  border-color: var(--line-strong);
}
.post[aria-current='true'] .post-tag {
  padding: 4px 12px;
  border-color: var(--ink);
  background: var(--ink);
  color: var(--paper);
  font-size: 14px;
  font-weight: 750;
}

.boat {
  --face: scaleX(-1);
  position: absolute;
  left: 0;
  bottom: var(--water);
  z-index: 2;
  width: var(--boat-w);
  aspect-ratio: 1200 / 494;
  opacity: 0;
  transition: transform 0.6s var(--ease-out);
}
.boat.ready {
  opacity: 1;
}
.boat.dock-right {
  --face: scaleX(1);
}
.boat.still {
  transition: none;
}
.boat-img {
  display: block;
  width: 100%;
  height: auto;
  transform-origin: 50% 100%;
  transform: var(--face) rotate(0deg);
  transition: transform 0.32s var(--ease-out);
}
.boat.docked .boat-img {
  transform: var(--face) rotate(2deg);
}
.boat.still .boat-img {
  transition: none;
}

.stage {
  grid-area: stage;
  position: relative;
  min-height: 0;
  overflow: hidden;
}
.council {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: clamp(32px, 4vw, 64px);
  padding: clamp(6px, 1.6vh, 18px) clamp(16px, 3vw, 48px) clamp(10px, 2vh, 24px);
}
.year-mark {
  position: absolute;
  inset: 0;
  z-index: 0;
  display: grid;
  place-content: center;
  margin: 0;
  pointer-events: none;
  user-select: none;
  font-size: clamp(160px, 40vh, 420px);
  font-weight: 500;
  line-height: 1;
  letter-spacing: -0.04em;
  font-variant-numeric: tabular-nums;
  color: var(--ink);
  opacity: 0.08;
}
.leaders {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: flex-end;
  gap: clamp(28px, 3.4vw, 52px);
  min-width: 0;
}
.leader {
  display: grid;
  justify-items: center;
  gap: clamp(8px, 1.4vh, 14px);
}
.arch {
  position: relative;
  height: var(--arch-h);
  aspect-ratio: 0.75;
  border: 1.5px solid var(--line-strong);
  border-radius: 999px 999px 10px 10px;
  background: var(--sunk);
  box-shadow: var(--shadow);
}
.arch.has-art {
  border-color: transparent;
  background: none;
  box-shadow: none;
  border-radius: 0;
}
.slot {
  position: absolute;
  z-index: 1;
  inset: var(--slot-inset);
  overflow: hidden;
  border-radius: 999px 999px 6px 6px;
}
.slot .frame {
  width: 100%;
  height: 100%;
  border: 0;
  border-radius: inherit;
  box-shadow: none;
  background: var(--sunk);
}
.arch-art {
  position: absolute;
  inset: 0;
  z-index: 2;
  width: 100%;
  height: 100%;
  object-fit: fill;
  pointer-events: none;
}
.leader-text {
  display: grid;
  justify-items: center;
  gap: 4px;
  min-width: 0;
  text-align: center;
}
.name {
  margin: 0;
  max-width: 20ch;
  font-size: clamp(18px, 2.5vh, 26px);
  font-weight: 650;
  letter-spacing: -0.01em;
  line-height: 1.15;
  text-wrap: balance;
}
.role {
  margin: 0;
  font-size: 11px;
  font-weight: 650;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--ink-3);
}
.is-secretary .role {
  color: var(--mari-ink);
}

.deck {
  position: relative;
  z-index: 1;
  align-self: center;
  display: grid;
  gap: clamp(10px, 1.6vh, 16px);
  min-width: 0;
  max-width: 100%;
  padding: 18px 22px 20px;
  border: 1.5px solid var(--line-strong);
  border-radius: 12px;
  background-color: var(--mari-soft);
  background-image: repeating-linear-gradient(
    180deg,
    transparent 0 26px,
    color-mix(in srgb, var(--line-strong) 55%, transparent) 26px 28px
  );
  box-shadow: var(--shadow);
}
.deck::before {
  content: '';
  position: absolute;
  inset: 6px;
  border: 2px dotted color-mix(in srgb, var(--line-strong) 70%, transparent);
  border-radius: 8px;
  pointer-events: none;
}
.deck-row {
  position: relative;
  display: flex;
  justify-content: center;
  gap: clamp(10px, 1.1vw, 14px);
}
.member {
  display: grid;
  justify-items: center;
  gap: 6px;
  width: var(--m-w);
  transition: opacity 0.42s var(--ease-out);
  transition-delay: calc(var(--i, 0) * 45ms);
}
.frame {
  position: relative;
  display: grid;
  place-items: center;
  overflow: hidden;
  background: var(--card);
  border: 1.5px solid var(--line-strong);
  border-radius: 8px;
}
.member .frame {
  width: 100%;
  aspect-ratio: 4 / 5;
}
.frame::before {
  content: '';
  position: absolute;
  inset: 22%;
  background: var(--crest) center / contain no-repeat;
  opacity: 0.22;
}
.frame img {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.frame:has(img)::before {
  display: none;
}
.member-cap {
  margin: 0;
  font-size: 11px;
  font-weight: 650;
  letter-spacing: 0.1em;
  line-height: 1.2;
  text-align: center;
  text-transform: uppercase;
  color: var(--ink-2);
}

/* Year change. `rise` is the site entrance; this stagger is its own class. */
.arrive {
  transition:
    opacity 0.5s var(--ease-out),
    transform 0.6s var(--ease-out);
  transition-delay: calc(var(--i, 0) * 60ms);
}
.council.out .arrive {
  opacity: 0;
  transform: translateY(-6px);
  transition: opacity 0.22s var(--ease-out);
  transition-delay: 0s;
}
.council.out .member {
  opacity: 0;
  transition: opacity 0.2s var(--ease-out);
  transition-delay: 0s;
}
.council.pre .arrive {
  opacity: 0;
  transform: translateY(12px);
  transition: none;
}
.council.pre .member {
  opacity: 0;
  transition: none;
}

@media (min-width: 761px) and (max-width: 1020px) {
  .board {
    --arch-h: min(44vh, 24vw);
    --m-w: 84px;
  }
  .council {
    gap: 32px;
  }
}

@media (max-width: 760px) {
  .board {
    --tab-h: calc(64px + env(safe-area-inset-bottom));
    --edge: 8%;
    --step: 21%;
    --water: 10%;
    --m-w: min(64px, calc((100vw - 88px) / 5), 7.6vh);
    --post-h: clamp(36px, 6vh, 52px);
    --boat-w: min(52px, 13vw);
    grid-template-rows: auto minmax(64px, 12vh) minmax(0, 1fr);
    grid-template-areas: 'top' 'river' 'stage';
  }
  .top {
    padding-top: 10px;
  }
  .council {
    flex-direction: column;
    gap: 10px;
    padding: 8px 14px 12px;
  }
  .year-mark {
    font-size: clamp(90px, 20vh, 150px);
  }
  .post-tag {
    padding: 1px 6px;
    font-size: 10px;
  }
  .post[aria-current='true'] .post-tag {
    padding: 2px 9px;
    font-size: 12px;
  }
  .leaders {
    gap: 14px;
  }
  .leader {
    width: min(36vw, 148px, 18vh);
  }
  .arch {
    width: 100%;
    height: auto;
  }
  .deck {
    gap: 8px;
    padding: 10px 12px 12px;
  }
  .deck::before {
    inset: 4px;
  }
  .deck-row {
    gap: 8px;
  }
  .member-cap {
    font-size: 10.5px;
    letter-spacing: 0.04em;
  }
}
</style>
