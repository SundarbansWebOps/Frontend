<!--
  PROTOTYPE — the communities and the crew. Each card's three-word motto stamps in as it
  arrives. Rosters are empty seats until the 2026–27 names and photos are added in teams.js
  (no stand-in faces); a community links to its events on the Events page.
-->
<template>
  <ul ref="root" class="teams">
    <li
      v-for="(t, i) in teams"
      :key="t.id"
      class="team"
      :class="{ in: shown }"
      :style="{ '--i': i, '--c': t.wing ? `var(--w-${t.wing})` : 'var(--mari-ink)' }"
    >
      <i class="tide" aria-hidden="true" />
      <p class="tag" aria-hidden="true">
        <span v-for="(w, k) in t.tag" :key="k" :style="{ '--k': k }">{{ w }}</span>
      </p>
      <h3>{{ t.name }}</h3>
      <p class="desc">{{ t.desc }}</p>

      <div v-if="t.people.length" class="people">
        <span v-for="p in t.people" :key="p.name" class="who">
          <img :src="portrait.face(p.img)" alt="" width="36" height="36" loading="lazy" />
          <span
            ><strong>{{ p.name }}</strong
            ><small>{{ p.role }}</small></span
          >
        </span>
      </div>
      <div v-else class="seats">
        <span class="row" aria-hidden="true">
          <i v-for="k in 5" :key="k" :style="{ '--k': k }" />
        </span>
        <small>Roster for 2026–27 coming</small>
      </div>

      <a v-if="t.wing" class="go" href="?page=events" @click.prevent="toEvents(t.wing)"
        >{{ t.events }} events · see them <LineIcon name="arrow"
      /></a>
    </li>
  </ul>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue';
import LineIcon from './LineIcon.vue';
import { ev } from './events.js';
import { portrait } from './house.js';
import { nav } from './store.js';

defineProps({ teams: { type: Array, required: true } });

function toEvents(wing) {
  ev.wing = wing;
  nav.go('events');
}

const root = ref(null);
const shown = ref(matchMedia('(prefers-reduced-motion: reduce)').matches);
const io = new IntersectionObserver(
  ([en]) => {
    if (en.isIntersecting) {
      shown.value = true;
      io.disconnect();
    }
  },
  { threshold: 0.25 }
);
onMounted(() => io.observe(root.value));
onBeforeUnmount(() => io.disconnect());
</script>

<style scoped>
.teams {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.team {
  position: relative;
  display: grid;
  grid-template-rows: auto auto 1fr auto auto;
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
    transform 0.8s var(--ease-spring);
  transition-delay: calc(var(--i) * 120ms);
}
.team.in {
  opacity: 1;
  transform: none;
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
.people {
  display: grid;
  gap: 8px;
  margin-top: 8px;
}
.who {
  display: flex;
  align-items: center;
  gap: 10px;
}
.who img {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  object-fit: cover;
}
.who span {
  display: grid;
}
.who strong {
  font-size: 14px;
}
.who small {
  font-size: 12px;
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
@media (max-width: 860px) {
  .teams {
    grid-template-columns: minmax(0, 1fr);
  }
}
@media (prefers-reduced-motion: reduce) {
  .team,
  .tag span {
    transition: none;
  }
  .seats i {
    animation: none;
  }
}
</style>
