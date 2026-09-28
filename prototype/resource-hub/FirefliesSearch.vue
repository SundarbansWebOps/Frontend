<!--
  PROTOTYPE — Home "Synchrony": the mini search in the Resources brief. Same parser as the
  Resources search bar; a hit opens the course sheet, Enter carries the query to Resources.
  Emits the matching course codes so the swarm can light their columns.
-->
<template>
  <div class="find">
    <form role="search" @submit.prevent="seeAll">
      <label for="ff-q" class="visually-hidden">Search past papers and notes</label>
      <input
        id="ff-q"
        v-model="q"
        aria-describedby="ff-search-status"
        type="search"
        autocomplete="off"
        spellcheck="false"
        enterkeyhint="search"
        placeholder="Try “ma1 pyq” or “dbms week 4”"
      />
      <button type="submit" class="go" aria-label="See all results in Resources">
        <LineIcon name="arrow" />
      </button>
    </form>

    <div v-if="!q.trim()" class="try">
      <span>Try</span>
      <button v-for="s in SUGGEST" :key="s" type="button" class="mono" @click="q = s">
        {{ s }}
      </button>
    </div>

    <ul v-else-if="hits.length" class="hits" aria-label="Courses">
      <li v-for="(h, i) in hits" :key="h.code" :style="{ '--i': i }">
        <button
          type="button"
          @click="openCourse(h.code, { tab: h.tab, exam: h.exam, week: h.week }, $event)"
        >
          <b>{{ h.short }}</b>
          <span class="code mono">{{ h.code }}</span>
          <span class="n"
            ><b class="mono">{{ h.count }}</b> {{ h.noun }}</span
          >
          <LineIcon name="next" />
        </button>
      </li>
    </ul>
    <p v-else class="none">
      No course matches “{{ q.trim() }}”<template v-if="files"
        >, but {{ files }} file titles do</template
      >.
    </p>

    <p id="ff-search-status" class="visually-hidden" role="status" aria-atomic="true">
      {{
        q.trim()
          ? `${hits.length} matching courses, ${files} matching files`
          : 'Search by course, exam or week'
      }}
    </p>

    <button v-if="q.trim()" type="button" class="all" @click="seeAll">
      See every result in Resources <LineIcon name="arrow" />
    </button>
  </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue';
import LineIcon from './LineIcon.vue';
import { byCode, nav, openCourse, search, store } from './store.js';

const emit = defineEmits(['codes']);
const SUGGEST = ['ma1 pyq', 'stats 2 notes', 'dbms week 4'];
const q = ref(store.q);

const result = computed(() => search(q.value));
const files = computed(() => result.value.resources.length);

function noun(h, n) {
  if (h.tab === 'notes')
    return `${n === 1 ? 'set' : 'sets'} of notes${h.week ? ` · week ${h.week}` : ''}`;
  const exam = h.exam && h.exam !== 'All' ? `${h.exam} ` : '';
  return `${exam}${n === 1 ? 'paper' : 'papers'}`;
}

const hits = computed(() =>
  result.value.courses.slice(0, 5).map((h) => ({
    ...h,
    short: byCode[h.code].short,
    noun: noun(h, h.count),
  }))
);

watch(
  hits,
  (v) =>
    emit(
      'codes',
      v.map((h) => h.code)
    ),
  { immediate: true }
);

function seeAll() {
  const v = q.value.trim();
  if (!v) return;
  store.q = v;
  nav.go('resources');
}
</script>

<style scoped>
.find {
  display: grid;
  gap: 12px;
  max-width: 460px;
}
form {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 6px 6px 16px;
  border-radius: 14px;
  border: 1.5px solid var(--line-strong);
  background: var(--card);
  transition:
    border-color 0.2s,
    box-shadow 0.2s;
}
form:focus-within {
  border-color: var(--mari-ink);
  box-shadow: 0 0 0 4px color-mix(in srgb, var(--mari) 22%, transparent);
}
input {
  flex: 1;
  min-width: 0;
  height: 38px;
  border: 0;
  background: none;
  color: var(--ink);
  font: inherit;
  font-size: 16px;
  outline: none;
}
input::placeholder {
  color: var(--ink-3);
}
input::-webkit-search-cancel-button {
  filter: grayscale(1);
}
.go {
  display: grid;
  place-items: center;
  width: 40px;
  height: 40px;
  border: 0;
  border-radius: 10px;
  background: var(--mari);
  color: var(--on-mari);
}
.try {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: var(--ink-2);
}
.try button {
  padding: 5px 10px;
  border-radius: 99px;
  border: 1px solid var(--line-strong);
  background: none;
  font-size: 12.5px;
  color: var(--ink);
  transition: background 0.2s;
}
.try button:hover {
  background: var(--sunk);
}
.hits {
  margin: 0;
  padding: 0;
  list-style: none;
  display: grid;
  border-top: 1px solid var(--line);
}
.hits li {
  border-bottom: 1px solid var(--line);
  animation: rise 0.45s var(--ease-out) both;
  animation-delay: calc(var(--i) * 40ms);
}
.hits button {
  display: grid;
  grid-template-columns: minmax(0, auto) minmax(0, 1fr) minmax(0, auto) 20px;
  align-items: baseline;
  gap: 10px;
  width: 100%;
  padding: 11px 4px;
  border: 0;
  background: none;
  text-align: left;
  border-radius: 8px;
  transition: background 0.2s;
}
.hits button:hover {
  background: var(--sunk);
}
.hits button > b,
.n {
  overflow-wrap: anywhere;
}
.hits b {
  font-weight: 700;
}
.code {
  font-size: 12px;
  color: var(--ink-2);
}
.n {
  font-size: 13.5px;
  color: var(--ink-2);
}
.n b {
  color: var(--mari-ink);
}
.hits .ic {
  width: 16px;
  height: 16px;
  align-self: center;
  color: var(--ink-3);
}
.none {
  margin: 0;
  font-size: 14px;
  color: var(--ink-2);
}
.all {
  justify-self: start;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 0;
  border: 0;
  background: none;
  font-size: 14px;
  font-weight: 600;
  color: var(--mari-ink);
}
.all .ic {
  width: 16px;
  height: 16px;
}
@media (max-width: 420px) {
  .hits button {
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr) 20px;
  }
  .code {
    display: none;
  }
}
@media (prefers-reduced-motion: reduce) {
  .hits li {
    animation: none;
  }
}
</style>
