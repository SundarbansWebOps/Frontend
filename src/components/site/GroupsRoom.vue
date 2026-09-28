<!--
  Lounge room: regional WhatsApp groups. Regions, coordinators and meetup counts
  are real; the join link stays sealed until sign-in.
-->
<template>
  <div class="groups">
    <div class="pick" role="radiogroup" aria-label="Your region">
      <button
        v-for="g in list"
        :key="g.id"
        type="button"
        role="radio"
        :aria-checked="sel === g.id"
        :class="{ on: sel === g.id }"
        @click="sel = g.id"
      >
        {{ g.name }}
      </button>
    </div>

    <Transition name="card" mode="out-in">
      <article :key="r.id" class="card">
        <header>
          <span class="wa"><LineIcon name="wa" /></span>
          <span>
            <small>Sundarbans · WhatsApp group</small>
            <h3>{{ r.name }}</h3>
          </span>
        </header>
        <p v-if="r.blurb" class="blurb">{{ r.blurb }}</p>
        <div class="who">
          <span v-for="c in r.coordinators" :key="c.id" class="c">
            <img :src="portrait.face(c.img)" alt="" width="36" height="36" />
            <span
              ><small>Coordinator</small><strong>{{ c.name }}</strong></span
            >
          </span>
          <span v-if="!r.coordinators.length" class="c none">No coordinator listed yet</span>
          <span class="m mono"
            ><b>{{ r.items.length }}</b> meetups</span
          >
        </div>
        <div class="seal">
          <span class="link mono" aria-hidden="true">chat.whatsapp.com/ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒</span>
          <button type="button" @click="toast('The join link unlocks after sign-in')">
            Unlock with sign-in
          </button>
        </div>
      </article>
    </Transition>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue';
import LineIcon from './LineIcon.vue';
import { portrait, regionById, regions } from '../../lib/house.js';
import { toast } from '../../lib/store.js';

const list = [...regions].sort((a, b) => a.name.localeCompare(b.name));
const sel = ref('patna');
const r = computed(() => regionById[sel.value]);
</script>

<style scoped>
.groups {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 14px;
}
.pick {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.pick button {
  padding: 7px 13px;
  border: 1px solid var(--line-strong);
  border-radius: 99px;
  background: none;
  font-size: 13.5px;
  font-weight: 600;
  color: var(--ink-2);
  transition:
    background 0.2s,
    color 0.2s,
    border-color 0.2s;
}
.pick button:hover {
  color: var(--ink);
}
.pick button.on {
  background: #f2a93b;
  border-color: #f2a93b;
  color: #1d1915;
}
.card {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 12px;
  min-width: 0;
  max-width: 720px;
  padding: 20px;
  border-radius: 20px;
  background: var(--card);
  border: 1px solid var(--line);
}
header {
  display: flex;
  align-items: center;
  gap: 12px;
}
.wa {
  display: grid;
  place-items: center;
  width: 44px;
  height: 44px;
  border-radius: 14px;
  background: var(--mari-soft);
  color: #f2a93b;
}
.wa :deep(svg) {
  width: 24px;
  height: 24px;
}
header small {
  font-size: 12px;
  color: var(--ink-2);
}
h3 {
  margin: 0;
  font-size: 24px;
  font-weight: 750;
  letter-spacing: -0.03em;
}
.blurb {
  margin: 0;
  font-size: 14.5px;
  line-height: 1.5;
  color: var(--ink-2);
}
.who {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px 20px;
}
.c {
  display: flex;
  align-items: center;
  gap: 9px;
}
.c img {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  object-fit: cover;
}
.c span {
  display: grid;
}
.c small {
  font-size: 11.5px;
  color: var(--ink-2);
}
.c strong {
  font-size: 14.5px;
}
.c.none {
  font-size: 14px;
  color: var(--ink-2);
}
.m {
  margin-left: auto;
  font-size: 13px;
  color: var(--ink-2);
}
.m b {
  font-size: 18px;
  color: var(--ink);
}
.seal {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 10px 10px 14px;
  border-radius: 14px;
  background: var(--sunk);
  border: 1px dashed var(--line-strong);
}
.link {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  white-space: nowrap;
  font-size: 13px;
  color: var(--ink-3);
  filter: blur(1.5px);
}
.seal button {
  flex: none;
  padding: 8px 14px;
  border: 0;
  border-radius: 99px;
  background: #f2a93b;
  color: #1d1915;
  font-size: 13.5px;
  font-weight: 700;
}
.card-enter-active {
  transition:
    opacity 0.3s var(--ease-out),
    transform 0.45s var(--ease-spring);
}
.card-leave-active {
  transition:
    opacity 0.15s,
    transform 0.2s;
}
.card-enter-from {
  opacity: 0;
  transform: translateY(12px) rotate(-1deg);
}
.card-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}
</style>
