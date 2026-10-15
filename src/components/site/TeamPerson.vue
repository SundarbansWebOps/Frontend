<!--
  One person in a team's roster: a portrait card (as the council's PersonCard, without the region
  chip). Everyone gets the same size; a lead's role is set in the team accent. Each has a card
  back, so the deal can turn it over on the way in.
-->
<template>
  <div class="person" :class="{ lead }">
    <div class="face front">
      <span class="photo">
        <img :src="portrait.card(p.img)" :alt="p.name" decoding="async" />
      </span>
      <span class="info">
        <small class="role">{{ p.role }}</small>
        <strong class="name">{{ p.name }}</strong>
      </span>
    </div>
    <div class="face back" aria-hidden="true">
      <svg viewBox="0 0 100 100">
        <circle v-for="k in 5" :key="k" cx="50" cy="50" :r="k * 11" />
      </svg>
      <b>S</b>
    </div>
  </div>
</template>

<script setup>
import { portrait } from '../../lib/house.js';

defineProps({
  p: { type: Object, required: true },
  lead: Boolean,
});
</script>

<style scoped>
.person {
  position: relative;
  height: 100%;
  transform-style: preserve-3d;
}
.face {
  border-radius: 14px;
  backface-visibility: hidden;
  -webkit-backface-visibility: hidden;
}
.front {
  position: relative;
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
  background: var(--ink);
  color: var(--mari);
  transform: rotateY(180deg);
}
:root[data-theme='dark'] .back {
  background: var(--sunk);
}
.back svg {
  position: absolute;
  width: 170%;
  fill: none;
  stroke: var(--mari);
  stroke-width: 0.6;
  opacity: 0.4;
}
.back b {
  font-size: 44px;
  font-weight: 800;
  letter-spacing: -0.05em;
}
/* The portrait on top, name and role under it. */
.front {
  display: grid;
  grid-template-rows: auto auto;
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
.info {
  display: grid;
  gap: 2px;
  min-width: 0;
  padding: 10px 12px 12px;
}
.role {
  font-size: 11.5px;
  font-weight: 650;
  color: var(--ink-2);
  text-transform: uppercase;
  letter-spacing: 0.06em;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
/* Names wrap to a second line rather than truncate: a cut-off name is the wrong name. */
.name {
  min-width: 0;
  font-size: 16px;
  font-weight: 700;
  letter-spacing: -0.015em;
  line-height: 1.25;
  overflow-wrap: break-word;
}
.lead .role {
  color: var(--mari-ink);
}
</style>
