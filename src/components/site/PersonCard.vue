<!--
  One council member as a two-sided card (portrait front, house back). The parent turns it
  over (CouncilDeck deals and turns it on the Teams page); the card itself does not react to the cursor.
-->
<template>
  <div class="pc" :class="size">
    <div class="card3d">
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
</script>

<style scoped>
.pc {
  height: 100%;
  transform-style: preserve-3d;
}
.card3d {
  position: relative;
  height: 100%;
  transform-style: preserve-3d;
}
.face {
  border-radius: 16px;
  backface-visibility: hidden;
  -webkit-backface-visibility: hidden;
}
.front {
  position: relative;
  display: grid;
  /* minmax(0, …): an auto column grows to the unwrapped name, so fit.js saw no overflow. */
  grid-template-columns: minmax(0, 1fr);
  grid-template-rows: auto minmax(0, 1fr);
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
    filter 1.1s var(--ease-out),
    transform 1s var(--ease-out);
}
.hi.on {
  opacity: 1;
  filter: none;
}
/* Hover eases only the portrait in; the card itself stays still. Mouse-type pointers only, and
   never under reduced motion. */
@media (hover: hover) and (pointer: fine) and (prefers-reduced-motion: no-preference) {
  .pc:hover .hi.on {
    transform: scale(1.035);
  }
}
.info {
  display: grid;
  grid-template-rows: auto auto minmax(0, 1fr);
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
  text-overflow: ellipsis;
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
  position: relative;
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
/* A 42px tap area around the 30px icon; the row is tight on a phone. */
.soc::after {
  content: '';
  position: absolute;
  inset: -6px;
}
.soc :deep(svg) {
  width: 16px;
  height: 16px;
}
@media (prefers-reduced-motion: reduce) {
  .hi {
    transition: none;
  }
}
</style>
