<!--
  PROTOTYPE — Home "Pat": the Resources panel's search, painted as a cartouche. Same parser as the
  Resources search bar: a hit opens its course sheet over the page; Enter or "See all" carries
  the query to Resources.
-->
<template>
  <form class="find" role="search" @submit.prevent="seeAll">
    <label class="box">
      <span class="visually-hidden">Search courses, past papers and notes</span>
      <LineIcon name="book" />
      <input
        v-model="q"
        type="search"
        autocomplete="off"
        spellcheck="false"
        enterkeyhint="search"
        placeholder="Try “ma1 pyq” or “dbms week 4”"
      />
      <button v-if="q" type="submit" class="all">See all</button>
    </label>

    <ul v-if="hits.length" class="hits" aria-label="Matching courses">
      <li v-for="h in hits" :key="h.code">
        <button type="button" @click="(e) => openCourse(h.code, h, e)">
          <b>{{ byCode[h.code].short }}</b>
          <span class="mono">{{ h.code }}</span>
          <em>{{ countLabel(h) }}</em>
        </button>
      </li>
    </ul>
    <p v-else-if="q.trim()" class="none" role="status">
      Nothing matches “{{ q.trim() }}” yet. <button type="submit">Search all of Resources</button>
    </p>
    <p v-else class="try">
      <span>Try</span>
      <button v-for="t in TRY" :key="t" type="button" @click="q = t">{{ t }}</button>
    </p>
  </form>
</template>

<script setup>
import { computed, ref } from 'vue';
import LineIcon from './LineIcon.vue';
import { byCode, nav, openCourse, search, store } from './store.js';

const TRY = ['ma1 pyq', 'dbms week 4', 'q1 stats'];
const q = ref('');
const hits = computed(() => (q.value.trim() ? search(q.value).courses.slice(0, 4) : []));

function countLabel(h) {
  const n = h.count;
  if (h.tab === 'notes')
    return `${n} ${n === 1 ? 'set' : 'sets'} of notes${h.week ? ` · week ${h.week}` : ''}`;
  return `${n} past ${n === 1 ? 'paper' : 'papers'}${h.exam !== 'All' ? ` · ${h.exam}` : ''}`;
}

function seeAll() {
  store.q = q.value.trim();
  nav.go('resources');
}
</script>

<style scoped>
.find {
  display: grid;
  gap: 12px;
}
/* A painted cartouche: ink outline, a vermilion inner rule, marigold studs at the ends. */
.box {
  position: relative;
  display: flex;
  align-items: center;
  gap: 10px;
  height: 56px;
  padding: 0 8px 0 22px;
  border: 2px solid var(--pi);
  border-radius: 99px;
  background: var(--pcard);
  box-shadow:
    inset 0 0 0 3px var(--pcard),
    inset 0 0 0 4.5px var(--pv);
  transition: box-shadow 0.25s;
}
.box::before,
.box::after {
  content: '';
  position: absolute;
  top: 50%;
  width: 11px;
  height: 11px;
  margin-top: -5.5px;
  border: 2px solid var(--pi);
  border-radius: 50%;
  background: var(--pmari);
}
.box::before {
  left: -7px;
}
.box::after {
  right: -7px;
}
.box:focus-within {
  box-shadow:
    inset 0 0 0 3px var(--pcard),
    inset 0 0 0 4.5px var(--pv),
    0 0 0 4px color-mix(in srgb, var(--pmari) 55%, transparent);
}
.box .ic {
  flex: none;
  color: var(--pv);
}
input {
  flex: 1;
  min-width: 0;
  height: 100%;
  border: 0;
  background: none;
  color: var(--pi);
  font: 500 17px/1 var(--font);
  outline: none;
}
input::placeholder {
  color: var(--pi2);
}
input::-webkit-search-cancel-button {
  display: none;
}
.all {
  flex: none;
  height: 38px;
  padding: 0 16px;
  border: 1.5px solid var(--pi);
  border-radius: 99px;
  background: var(--pmari);
  color: #1d1915;
  font-size: 14px;
  font-weight: 650;
}
.hits {
  display: grid;
  gap: 6px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.hits button {
  display: grid;
  grid-template-columns: auto auto 1fr;
  align-items: baseline;
  gap: 10px;
  width: 100%;
  padding: 11px 16px;
  border: 1.5px solid var(--pi);
  border-radius: 12px;
  background: var(--pcard);
  color: var(--pi);
  text-align: left;
  animation: drop 0.35s var(--ease-out) both;
  transition:
    transform 0.2s var(--ease-spring),
    background 0.2s;
}
.hits li:nth-child(2) button {
  animation-delay: 40ms;
}
.hits li:nth-child(3) button {
  animation-delay: 80ms;
}
.hits li:nth-child(4) button {
  animation-delay: 120ms;
}
@keyframes drop {
  from {
    opacity: 0;
    transform: translateY(-6px);
  }
}
.hits button:hover {
  background: var(--pmari-soft);
  transform: translateX(3px);
}
.hits b {
  font-size: 16px;
  font-weight: 700;
}
.hits .mono {
  font-size: 12.5px;
  color: var(--pi2);
}
.hits em {
  justify-self: end;
  font-style: normal;
  font-size: 14px;
  font-weight: 600;
  color: var(--pv);
}
.try,
.none {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  margin: 0;
  font-size: 14px;
  color: var(--pi2);
}
.try button,
.none button {
  padding: 6px 12px;
  border: 1.5px dashed var(--pi2);
  border-radius: 99px;
  background: none;
  color: var(--pi);
  font-size: 13.5px;
  font-weight: 600;
}
.try button:hover,
.none button:hover {
  border-style: solid;
  background: var(--pcard);
}
@media (max-width: 760px) {
  .hits button {
    grid-template-columns: auto 1fr;
  }
  input {
    font-size: 16px;
  }
  .all {
    padding-inline: 10px;
  }
  .hits em {
    grid-column: 1 / -1;
    justify-self: start;
  }
}
@media (prefers-reduced-motion: reduce) {
  .hits button {
    animation: none;
    transition: none;
  }
}
</style>
