<!--
  The communities and the teams. Each card opens on its own painted pat plate, which paints
  itself in and then keeps moving while on screen; the three-word motto stamps in as it
  arrives. Filled rosters show a preview and open a dealt panel under their card row; empty
  rosters keep the 2026–27 seats. Communities link to their events on the Events page.
-->
<template>
  <ul ref="root" class="teams" @keydown.esc="close">
    <template v-for="(t, i) in teams" :key="t.id">
      <li
        :id="`team-${t.id}`"
        :ref="(el) => (cards[i] = el)"
        class="team"
        :class="{ in: shown, open: isOpenAt(i), roster: t.people.length > 0 }"
        :style="{ '--i': i, '--c': t.wing ? `var(--w-${t.wing})` : 'var(--mari-ink)' }"
        @click="onCard($event, i)"
      >
        <i class="tide" aria-hidden="true" />
        <PatArt v-if="ART[t.id]" class="art" :fig="ART[t.id]" :name="t.id" />
        <p class="tag" aria-hidden="true">
          <span v-for="(w, k) in t.tag" :key="k" :style="{ '--k': k }">{{ w }}</span>
        </p>
        <h3>{{ t.name }}</h3>
        <p class="desc">{{ t.desc }}</p>

        <button
          v-if="t.people.length"
          :ref="(el) => (buttons[i] = el)"
          type="button"
          class="meet"
          :aria-expanded="String(isOpenAt(i))"
          :aria-controls="openIdx === i ? panelId : undefined"
          @click="toggle(i)"
        >
          <span class="faces" aria-hidden="true">
            <img
              v-for="p in t.people.slice(0, 5)"
              :key="p.name"
              :src="portrait.face(p.img)"
              alt=""
              width="28"
              height="28"
              loading="lazy"
            />
          </span>
          <span class="label">Meet the team · {{ t.people.length }}</span>
          <LineIcon name="arrow" class="chev" />
        </button>
        <div v-else class="seats">
          <span class="row" aria-hidden="true">
            <i v-for="k in 5" :key="k" :style="{ '--k': k }" />
          </span>
          <small>Roster for 2026–27 coming</small>
        </div>

        <a v-if="t.wing" class="go" href="#/events" @click.prevent="toEvents(t.wing)"
          >{{ t.events }} events · see them <LineIcon name="arrow"
        /></a>
      </li>

      <li v-if="openIdx !== null && i === rowEnd" class="slot">
        <TeamPanel
          :id="panelId"
          :team="teams[openIdx]"
          :card-of="() => cards[openIdx]"
          :open="isOpen"
          @close="close"
          @closed="onClosed"
        />
      </li>
    </template>
  </ul>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, useId } from 'vue';
import LineIcon from './LineIcon.vue';
import PatArt from './PatArt.vue';
import TeamPanel from './TeamPanel.vue';
import { ART } from '../../lib/art.js';
import { portrait } from '../../lib/house.js';
import { nav } from '../../lib/store.js';

const props = defineProps({ teams: { type: Array, required: true } });

// useId: Communities and Teams each render this list, so each needs its own panel id.
const panelId = `team-panel-${useId()}`;
const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
const narrow = matchMedia('(max-width: 860px)');
const cols = ref(narrow.matches ? 1 : 3);
const onNarrow = () => (cols.value = narrow.matches ? 1 : 3);

const root = ref(null);
const shown = ref(reduced);
const cards = [];
const buttons = [];

// One team's panel is open at a time; a closing panel remains in its grid slot until collapsed.
const openIdx = ref(null);
const isOpen = ref(false);
const isOpenAt = (i) => openIdx.value === i && isOpen.value;
// The last card of the open team's row: the panel goes after it (after the card itself on a phone).
const rowEnd = computed(() =>
  openIdx.value === null
    ? -1
    : Math.min(
        Math.floor(openIdx.value / cols.value) * cols.value + cols.value - 1,
        props.teams.length - 1
      )
);

// Opening keeps the pressed card where it was: if a panel above it went away, the page scrolls
// by the same amount the card moved.
async function openTeam(i) {
  const card = cards[i];
  const before = card.getBoundingClientRect().top;
  openIdx.value = i;
  isOpen.value = true;
  await nextTick();
  const moved = card.getBoundingClientRect().top - before;
  if (Math.abs(moved) > 0.5) window.scrollBy(0, moved);
}

// A click anywhere on a card with a roster opens it too; the button stays the keyboard and
// screen-reader control. Clicks on the button or the events link do their own thing.
function onCard(e, i) {
  if (!props.teams[i].people.length || e.target.closest('a, button')) return;
  if (getSelection()?.toString()) return;
  toggle(i);
}

function toggle(i) {
  if (isOpenAt(i)) close();
  else openTeam(i);
}

// Focus goes back to the trigger before the panel goes inert, so focus is never lost.
function close() {
  if (openIdx.value === null || !isOpen.value) return;
  buttons[openIdx.value]?.focus({ preventScroll: true });
  isOpen.value = false;
}

function onClosed() {
  if (!isOpen.value) openIdx.value = null;
}

function toEvents(wing) {
  nav.go('events', null, { wing });
}

let io;
onMounted(() => {
  narrow.addEventListener('change', onNarrow);
  io = new IntersectionObserver(
    ([en]) => {
      if (en.isIntersecting) {
        shown.value = true;
        io.disconnect();
      }
    },
    { threshold: 0.25 }
  );
  io.observe(root.value);
});
onBeforeUnmount(() => {
  narrow.removeEventListener('change', onNarrow);
  io?.disconnect();
});
</script>

<style scoped>
.teams {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
  margin: 0;
  padding: 0;
  list-style: none;
  overflow-anchor: none;
}
.slot {
  grid-column: 1 / -1;
  min-width: 0;
}
.team {
  position: relative;
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  grid-template-rows: auto auto minmax(0, 1fr) auto auto;
  gap: 6px;
  padding: 20px 20px 18px;
  overflow: hidden;
  border-radius: 20px;
  background: var(--card);
  border: 1px solid var(--line);
  box-shadow: var(--shadow);
  opacity: 0;
  transform: translateY(18px);
  transition:
    opacity 0.6s var(--ease-out),
    transform 0.8s var(--ease-spring),
    border-color 0.3s var(--ease-out);
  transition-delay: calc(var(--i) * 120ms);
}
.team.roster {
  cursor: pointer;
}
.team.in {
  opacity: 1;
  transform: none;
}
.team.open {
  border-color: var(--c);
}
/* Hover: the card fills from the bottom in its own colour, like water rising. */
.tide {
  position: absolute;
  inset: 0;
  z-index: 0;
  background: linear-gradient(0deg, color-mix(in srgb, var(--c) 14%, transparent), transparent);
  transform: translateY(70%);
  opacity: 0;
  transition:
    transform 0.7s var(--ease-out),
    opacity 0.4s;
}
.team:hover .tide {
  transform: none;
  opacity: 1;
}
.team > :not(.tide) {
  position: relative;
}
/* The plate hangs on a strip of pat paper with a dotted border, in both themes. */
.art {
  display: grid;
  place-items: end center;
  height: clamp(190px, 17vw, 230px);
  overflow: hidden;
  margin: -20px -20px 10px;
  padding: 16px 18px 10px;
  background:
    radial-gradient(
      120% 90% at 50% 100%,
      color-mix(in srgb, var(--c) 16%, transparent),
      transparent 70%
    ),
    #f6ecd8;
  border-bottom: 3px dotted color-mix(in srgb, var(--c) 70%, #1d1915);
}
.art :deep(.fig) {
  width: auto;
  height: 100%;
  transition: transform 0.6s var(--ease-spring);
}
.team:hover .art :deep(.fig) {
  transform: translateY(-4px) scale(1.03);
}
.tag {
  display: flex;
  flex-wrap: wrap;
  gap: 0 0.28em;
  margin: 0 0 6px;
  font-size: clamp(26px, 2.8vw, 34px);
  font-weight: 800;
  line-height: 1.02;
  letter-spacing: -0.045em;
  color: var(--c);
}
.tag span {
  display: inline-block;
  opacity: 0;
  transform: translateY(-0.5em) rotate(-4deg) scale(1.3);
  transition:
    opacity 0.3s,
    transform 0.5s var(--ease-spring);
  transition-delay: calc(var(--i) * 120ms + 300ms + var(--k) * 140ms);
}
.in .tag span {
  opacity: 1;
  transform: none;
}
h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  letter-spacing: -0.015em;
}
.desc {
  margin: 0;
  font-size: 14.5px;
  line-height: 1.5;
  color: var(--ink-2);
}
.meet {
  display: flex;
  align-items: center;
  justify-self: start;
  gap: 9px;
  max-width: 100%;
  margin-top: 8px;
  padding: 5px 10px 5px 5px;
  border: 1px solid var(--line);
  border-radius: 99px;
  background: var(--paper);
  color: var(--ink);
  font: inherit;
  cursor: pointer;
  transition:
    border-color 0.25s var(--ease-out),
    background 0.25s var(--ease-out);
}
.meet:hover,
.team.open .meet {
  border-color: var(--c);
}
.faces {
  display: flex;
  flex: none;
  padding-left: 2px;
}
.faces img {
  width: 28px;
  height: 28px;
  border: 2px solid var(--paper);
  border-radius: 50%;
  object-fit: cover;
}
.faces img + img {
  margin-left: -8px;
}
.label {
  overflow: hidden;
  font-size: 13px;
  font-weight: 650;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.chev {
  flex: none;
  width: 16px;
  height: 16px;
  color: var(--c);
  transition: transform 0.3s var(--ease-spring);
}
.team.open .chev {
  transform: rotate(90deg);
}
.seats {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 8px;
}
.seats .row {
  display: flex;
}
.seats i {
  width: 26px;
  height: 26px;
  border-radius: 50%;
  border: 1.5px dashed var(--line-strong);
  background: var(--paper);
  animation: breathe 3.2s ease-in-out infinite;
  animation-delay: calc(var(--k) * 0.25s);
}
.seats i + i {
  margin-left: -7px;
}
@keyframes breathe {
  50% {
    border-color: var(--c);
  }
}
.seats small {
  font-size: 12.5px;
  color: var(--ink-2);
}
.go {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  justify-self: start;
  margin-top: 8px;
  font-size: 14px;
  font-weight: 650;
  color: var(--c);
  text-decoration: none;
}
.go :deep(svg) {
  width: 17px;
  height: 17px;
  transition: transform 0.3s var(--ease-spring);
}
.go:hover :deep(svg) {
  transform: translateX(3px);
}
/* Narrow columns: three faces and the total, so the preview fits on one line. */
@media (max-width: 1020px) {
  .faces img:nth-child(n + 4) {
    display: none;
  }
}
@media (max-width: 860px) {
  .teams {
    grid-template-columns: minmax(0, 1fr);
  }
}
@media (prefers-reduced-motion: reduce) {
  .team,
  .tag span,
  .meet,
  .chev,
  .go :deep(svg) {
    transition: none;
  }
  .seats i {
    animation: none;
  }
}
</style>
