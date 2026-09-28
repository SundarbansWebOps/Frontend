<!--
  One council member as a two-sided card (portrait front, house back). Hover tilts
  it toward the pointer. The tilt is read off the untilted wrapper and holds still while the
  pointer is on a button or link, so the region chip never slides out from under the cursor.
-->
<template>
  <div class="pc" :class="size" @pointermove="tilt" @pointerleave="untilt">
    <div ref="card" class="tilt">
      <div class="face front">
        <span class="photo">
          <img class="lq" :src="portrait.blur(p.img)" alt="" aria-hidden="true" />
          <img
            class="hi"
            :class="{ on: loaded }"
            :src="size === 'big' ? portrait.big(p.img) : portrait.card(p.img)"
            :alt="p.name"
            loading="lazy"
            decoding="async"
            @load="loaded = true"
          />
          <i class="glare" aria-hidden="true" />
        </span>
        <span class="info">
          <small class="role">{{ p.role }}</small>
          <strong class="name">{{ p.name }}</strong>
          <span class="row">
            <button
              v-if="regionId"
              type="button"
              class="reg"
              :title="`See ${p.region} meetups`"
              @click="$emit('region', regionId)"
            >
              <i />{{ p.region }}<small v-if="meetups" class="mono">{{ meetups }}</small>
            </button>
            <span v-else class="reg flat"><i />{{ p.region }}</span>
            <a
              v-for="l in p.links"
              :key="l.href"
              class="soc"
              :href="l.href"
              target="_blank"
              rel="noopener"
              :title="`${p.name} on ${l.kind}`"
            >
              <LineIcon :name="ICON[l.kind]" />
              <span class="visually-hidden">{{ l.kind }}</span>
            </a>
          </span>
        </span>
      </div>
      <div class="face back" aria-hidden="true">
        <svg viewBox="0 0 100 100">
          <circle v-for="k in 5" :key="k" cx="50" cy="50" :r="k * 11" />
        </svg>
        <b>S</b>
        <small class="mono">2026–27</small>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue';
import LineIcon from './LineIcon.vue';
import { portrait, regionById, regionOfCouncil } from '../../lib/house.js';

const props = defineProps({
  p: { type: Object, required: true },
  size: { type: String, default: 'card' }, // 'big' | 'card'
  showMeetups: Boolean,
});
defineEmits(['region']);

const ICON = { LinkedIn: 'linkedin', X: 'x', Instagram: 'instagram' };
const regionId = computed(() => regionOfCouncil(props.p));
const meetups = computed(() =>
  props.showMeetups && regionId.value ? regionById[regionId.value].items.length : 0
);
const loaded = ref(false);
const card = ref(null);
const still =
  matchMedia('(prefers-reduced-motion: reduce)').matches || !matchMedia('(pointer: fine)').matches;

function tilt(e) {
  if (still || e.target.closest('button, a')) return;
  const r = e.currentTarget.getBoundingClientRect(); // the wrapper: never tilted
  const x = (e.clientX - r.left) / r.width;
  const y = (e.clientY - r.top) / r.height;
  const s = card.value.style;
  s.setProperty('--ry', `${(x - 0.5) * 12}deg`);
  s.setProperty('--rx', `${(0.5 - y) * 10}deg`);
  s.setProperty('--gx', `${x * 100}%`);
  s.setProperty('--gy', `${y * 100}%`);
  card.value.classList.add('lift');
}
function untilt() {
  const s = card.value.style;
  s.removeProperty('--ry');
  s.removeProperty('--rx');
  card.value.classList.remove('lift');
}
</script>

<style scoped>
.pc {
  height: 100%;
  transform-style: preserve-3d;
}
.tilt {
  position: relative;
  height: 100%;
  transform-style: preserve-3d;
  transform: rotateX(var(--rx, 0deg)) rotateY(var(--ry, 0deg));
  transition: transform 0.5s var(--ease-out);
}
.tilt.lift {
  transition: transform 0.12s linear;
}
.face {
  border-radius: 16px;
  backface-visibility: hidden;
  -webkit-backface-visibility: hidden;
}
.front {
  position: relative;
  display: grid;
  grid-template-rows: auto 1fr;
  height: 100%;
  overflow: hidden;
  background: var(--card);
  border: 1px solid var(--line);
  box-shadow: var(--shadow);
}
.back {
  position: absolute;
  inset: 0;
  display: grid;
  place-items: center;
  overflow: hidden;
  background: #1d1915;
  color: #f2a93b;
  transform: rotateY(180deg);
  border: 1px solid #3a3027;
}
.back svg {
  position: absolute;
  width: 170%;
  fill: none;
  stroke: #f2a93b;
  stroke-width: 0.6;
  opacity: 0.4;
}
.back b {
  font-size: 44px;
  font-weight: 800;
  letter-spacing: -0.05em;
}
.big .back b {
  font-size: 64px;
}
.back small {
  position: absolute;
  bottom: 14px;
  font-size: 11px;
  color: #cbb89c;
}

.photo {
  position: relative;
  display: block;
  aspect-ratio: 3 / 4;
  overflow: hidden;
  background: var(--sunk);
}
.photo img {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.lq {
  filter: saturate(0.6);
  transform: scale(1.08);
}
.hi {
  opacity: 0;
  filter: sepia(0.7) blur(6px);
  transition:
    opacity 0.7s var(--ease-out),
    filter 1.1s var(--ease-out);
}
.hi.on {
  opacity: 1;
  filter: none;
}
.glare {
  position: absolute;
  inset: 0;
  background: radial-gradient(
    circle at var(--gx, 50%) var(--gy, 0%),
    rgb(255 255 255 / 0.28),
    transparent 55%
  );
  opacity: 0;
  transition: opacity 0.3s;
}
.lift .glare {
  opacity: 1;
}
.info {
  display: grid;
  grid-template-rows: auto auto 1fr;
  gap: 2px;
  min-width: 0;
  padding: 11px 12px 12px;
}
.role {
  font-size: 11.5px;
  font-weight: 650;
  color: var(--mari-ink);
  text-transform: uppercase;
  letter-spacing: 0.06em;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
/* One line, always; fit.js shrinks a whole row of names together when one is too long. */
.name {
  display: block;
  min-width: 0;
  font-size: 16px;
  font-weight: 700;
  letter-spacing: -0.015em;
  line-height: 1.25;
  white-space: nowrap;
  overflow: hidden;
}
.big .name {
  font-size: 20px;
}
.row {
  display: flex;
  align-items: center;
  align-self: end;
  gap: 4px;
  min-height: 30px;
  margin-top: 6px;
}
.reg {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin-right: auto;
  padding: 4px 9px 4px 7px;
  border: 0;
  border-radius: 99px;
  background: var(--sunk);
  font-size: 12.5px;
  font-weight: 600;
  color: var(--ink-2);
  white-space: nowrap;
  transition:
    background 0.2s,
    color 0.2s;
}
.reg i {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--w-meetups);
}
.reg small {
  margin-left: 2px;
  padding-left: 7px;
  border-left: 1px solid var(--line-strong);
  font-size: 11.5px;
  color: var(--ink-3);
}
button.reg:hover {
  background: var(--mari-soft);
  color: var(--ink);
}
.reg.flat {
  background: none;
  padding-left: 0;
}
.soc {
  display: grid;
  place-items: center;
  flex: none;
  width: 30px;
  height: 30px;
  border-radius: 50%;
  color: var(--ink-2);
  transition:
    background 0.2s,
    color 0.2s;
}
.soc:hover {
  background: var(--sunk);
  color: var(--ink);
}
.soc :deep(svg) {
  width: 16px;
  height: 16px;
}
@media (prefers-reduced-motion: reduce) {
  .tilt,
  .hi {
    transition: none;
  }
}
</style>
