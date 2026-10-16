<!--
  A team's roster: everyone as a portrait card, leads first. It sits in the
  card grid as a full-width row under the pressed card, with a pointer in the team's colour. It
  opens by growing its grid row from 0 to 1fr, and its people are dealt in from the card.
-->
<template>
  <section
    :id="id"
    ref="root"
    class="panel"
    :class="{ shown, settled }"
    :aria-labelledby="`${id}-heading`"
    :inert="!open"
    :style="{ '--c': color, '--px': `${px}px` }"
    @transitionend="onEnd"
  >
    <div class="inner">
      <div class="sheet" :class="{ revealed }">
        <header class="ph">
          <div>
            <h3 :id="`${id}-heading`" ref="head" tabindex="-1">{{ team.name }}</h3>
            <p class="count mono">{{ count }} {{ count === 1 ? 'person' : 'people' }}</p>
          </div>
          <button type="button" class="close" @click="$emit('close')">Close</button>
        </header>

        <template v-if="leads.length">
          <h4 class="grp mono">Leading the team</h4>
          <ul class="people leads" aria-label="Heads and co-heads">
            <li v-for="p in leads" :key="p.name" data-deal>
              <TeamPerson :p="p" lead />
            </li>
          </ul>
        </template>
        <template v-if="members.length">
          <h4 v-if="leads.length" class="grp mono">Members · {{ members.length }}</h4>
          <ul class="people" aria-label="Members">
            <li v-for="p in members" :key="p.name" data-deal>
              <TeamPerson :p="p" />
            </li>
          </ul>
        </template>
      </div>
    </div>
  </section>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import TeamPerson from './TeamPerson.vue';

const props = defineProps({
  team: { type: Object, required: true },
  // Returns the pressed card's element, read at the moment it is needed.
  cardOf: { type: Function, required: true },
  open: Boolean,
  id: { type: String, required: true },
});
const emit = defineEmits(['close', 'closed']);

const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
const root = ref(null);
const head = ref(null);
const shown = ref(false);
const settled = ref(false);
const revealed = ref(false);
const px = ref(0);

const color = computed(() => (props.team.wing ? `var(--w-${props.team.wing})` : 'var(--mari-ink)'));
const count = computed(() => props.team.people.length);
const leads = computed(() => props.team.people.filter((p) => p.lead === true));
const members = computed(() => props.team.people.filter((p) => p.lead !== true));

// The pointer sits over the pressed card's centre, in the panel's own coordinates.
function place() {
  const card = props.cardOf();
  if (!card || !root.value) return;
  const c = card.getBoundingClientRect();
  const r = root.value.getBoundingClientRect();
  px.value = c.left + c.width / 2 - r.left;
}

// The people fly from the pressed card's centre to their seats, face down, turning over.
function revealPeople() {
  if (!reduced) {
    const card = props.cardOf();
    const c = card?.getBoundingClientRect();
    const ox = c ? c.left + c.width / 2 : innerWidth / 2;
    const oy = c ? c.top + c.height / 2 : innerHeight / 2;
    root.value.querySelectorAll('[data-deal]').forEach((el, i) => {
      const r = el.getBoundingClientRect();
      const dx = ox - (r.left + r.width / 2);
      const dy = oy - (r.top + r.height / 2);
      const rot = ((i * 37) % 17) - 8;
      el.animate(
        [
          {
            transform: `translate(${dx}px, ${dy}px) rotate(${rot}deg) rotateY(180deg) scale(0.62)`,
            offset: 0,
          },
          {
            transform: `translate(${dx * 0.2}px, ${dy * 0.35 - 30}px) rotateY(120deg) scale(0.9)`,
            offset: 0.55,
          },
          { transform: 'none' },
        ],
        {
          duration: 900,
          delay: i * 70,
          easing: 'cubic-bezier(.2,.75,.25,1.05)',
          fill: 'backwards',
        }
      );
    });
  }
  revealed.value = true;
}

// Scroll only if the finished panel runs below the screen, and never so far that its top (and
// the sticky header above it) would leave the screen.
function ensureVisible() {
  const r = root.value.getBoundingClientRect();
  const over = r.bottom - (innerHeight - 24);
  const room = r.top - 96;
  if (over > 0 && room > 0) {
    window.scrollBy({ top: Math.min(over, room), behavior: reduced ? 'auto' : 'smooth' });
  }
}

function focusHeading() {
  head.value?.focus({ preventScroll: true });
}

let timer;
function finish() {
  clearTimeout(timer);
  if (props.open) {
    if (!settled.value) {
      settled.value = true;
      ensureVisible();
    }
  } else {
    emit('closed');
  }
}
function onEnd(e) {
  if (e.target === root.value && e.propertyName === 'grid-template-rows') finish();
}

function setShown(v) {
  clearTimeout(timer);
  shown.value = v;
  if (reduced) {
    settled.value = v;
    if (v) nextTick(ensureVisible);
    else emit('closed');
    return;
  }
  settled.value = false;
  // Fallback if the transition never reports its end.
  timer = setTimeout(finish, 800);
}

watch(
  () => props.open,
  (v) => setShown(v)
);

// Switching to another team in the same row keeps this panel and deals its people again.
watch(
  () => props.team.id,
  async () => {
    place();
    revealed.value = false;
    await nextTick();
    requestAnimationFrame(() => {
      revealPeople();
      focusHeading();
    });
  }
);

let onResize;
onMounted(() => {
  onResize = () => place();
  addEventListener('resize', onResize);
  // Measure and deal while the panel is still at 0 height, then open it on the next frame so the
  // grid row has a start state to transition from.
  requestAnimationFrame(() => {
    place();
    revealPeople();
    focusHeading();
    setShown(props.open);
  });
});
onBeforeUnmount(() => {
  clearTimeout(timer);
  removeEventListener('resize', onResize);
});
</script>

<style scoped>
.panel {
  position: relative;
  display: grid;
  grid-template-rows: 0fr;
  min-width: 0;
  transition: grid-template-rows 0.5s var(--ease-out);
}
.panel.shown {
  grid-template-rows: 1fr;
}
/* The pointer: a small triangle in the team's colour, hanging from the card down to the panel. */
.panel::before {
  content: '';
  position: absolute;
  top: -14px;
  left: var(--px);
  z-index: 1;
  width: 22px;
  height: 14px;
  margin-left: -11px;
  background: var(--c);
  clip-path: polygon(0 0, 100% 0, 50% 100%);
  opacity: 0;
  transition: opacity 0.3s var(--ease-out);
}
.panel.shown::before {
  opacity: 1;
}
.inner {
  min-height: 0;
}
/* Clipped while it grows and shrinks; free once open so the deal can fly in from the card. */
.panel:not(.settled) .inner {
  overflow: hidden;
}
.sheet {
  padding: 20px;
  background: var(--card);
  border: 1px solid var(--line);
  border-top: 3px solid var(--c);
  border-radius: 20px;
  box-shadow: var(--shadow);
  perspective: 1400px;
}
.ph {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}
.ph h3 {
  margin: 0;
  font-size: clamp(22px, 2.4vw, 28px);
  font-weight: 750;
  letter-spacing: -0.03em;
  line-height: 1.1;
}
.count {
  margin: 4px 0 0;
  font-size: 13px;
  color: var(--ink-2);
}
.close {
  flex: none;
  padding: 6px 14px;
  border: 1px solid var(--line-strong);
  border-radius: 99px;
  background: var(--paper);
  font: inherit;
  font-size: 13px;
  font-weight: 650;
  color: var(--ink);
  cursor: pointer;
}
.close:hover {
  border-color: var(--c);
}
.people {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(min(150px, 100%), 1fr));
  gap: 12px;
  margin: 16px 0 0;
  padding: 0;
  list-style: none;
}
.people li {
  min-width: 0;
}
.grp {
  margin: 18px 0 0;
  font-size: 12px;
  font-weight: 500;
  color: var(--ink-3);
}
.grp + .people {
  margin-top: 10px;
}
/* Heads and co-heads sit a size up, ringed in the team's colour. */
.leads {
  grid-template-columns: repeat(auto-fill, minmax(min(190px, 100%), 1fr));
  gap: 16px;
  max-width: 640px;
}
.leads :deep(.face) {
  box-shadow:
    0 0 0 2px var(--c),
    var(--shadow);
}
@media (max-width: 560px) {
  .leads {
    max-width: none;
  }
  .people {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 8px;
  }
}
[data-deal] {
  transform-style: preserve-3d;
}
.sheet:not(.revealed) [data-deal] {
  visibility: hidden;
}
@media (prefers-reduced-motion: reduce) {
  .panel,
  .panel::before {
    transition: none;
  }
}
</style>
