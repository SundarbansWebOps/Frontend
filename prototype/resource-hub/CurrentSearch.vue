<!--
  PROTOTYPE — Home variant 3 ("Current"): the Resources landing stage. A working mini search
  over the same parser as the Resources page; hits drift in like boats to a ghat. A hit opens
  the course sheet over Home; Enter carries the query to Resources.
-->
<template>
  <div class="cs">
    <form class="field" role="search" @submit.prevent="seeAll">
      <label :for="id" class="visually-hidden">Search past papers and notes</label>
      <svg class="lens" viewBox="0 0 24 24" aria-hidden="true">
        <circle cx="10.5" cy="10.5" r="6" />
        <path d="M15 15l5 5" />
      </svg>
      <input
        :id="id"
        ref="input"
        v-model="q"
        type="search"
        autocomplete="off"
        spellcheck="false"
        placeholder="Try “ma1 pyq” or “dbms week 4”"
        aria-describedby="current-search-hint"
      />
      <button type="submit" class="all">
        See all <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" /></svg>
      </button>
      <svg class="ripple" viewBox="0 0 400 8" preserveAspectRatio="none" aria-hidden="true">
        <path
          d="M0 4 Q 12.5 0 25 4 T 50 4 T 75 4 T 100 4 T 125 4 T 150 4 T 175 4 T 200 4 T 225 4 T 250 4 T 275 4 T 300 4 T 325 4 T 350 4 T 375 4 T 400 4 T 425 4"
        />
      </svg>
    </form>
    <p id="current-search-hint" class="visually-hidden">
      Results update as you type. Press Enter to search every resource.
    </p>

    <div v-if="!q.trim()" class="idle">
      <p class="label">Try</p>
      <div class="chips">
        <button v-for="c in CHIPS" :key="c" type="button" @click="try_(c)">{{ c }}</button>
      </div>
      <p class="label">Deepest channels</p>
      <ul class="hits">
        <li v-for="(c, i) in deepest" :key="c.code" :style="{ '--i': i }">
          <button type="button" @click="openCourse(c.code, { tab: 'pyqs' }, $event)">
            <b>{{ c.short }}</b>
            <span class="code">{{ c.code }}</span>
            <span class="n">{{ c.pyqs.length }} papers<i> · </i>{{ c.notes.length }} notes</span>
          </button>
        </li>
      </ul>
    </div>

    <div v-else class="found" aria-live="polite">
      <p class="label">
        <template v-if="hits.length"
          >{{ hits.length }} {{ hits.length === 1 ? 'course' : 'courses' }}</template
        >
        <template v-else-if="res.resources.length">In titles and authors</template>
        <template v-else>Nothing yet. Try a course code like BSMA1001</template>
      </p>
      <TransitionGroup tag="ul" name="boat" class="hits">
        <li v-for="(h, i) in hits" :key="h.code" :style="{ '--i': i }">
          <button
            type="button"
            @click="openCourse(h.code, { tab: h.tab, exam: h.exam, week: h.week }, $event)"
          >
            <b>{{ byCode[h.code].short }}</b>
            <span class="code">{{ h.code }}</span>
            <span class="n">{{ h.count }} {{ unit(h) }}</span>
          </button>
        </li>
        <li
          v-for="(r, i) in hits.length ? [] : res.resources.slice(0, 4)"
          :key="r.link"
          :style="{ '--i': i }"
        >
          <button
            type="button"
            @click="openCourse(r.code, { tab: r.kind === 'Notes' ? 'notes' : 'pyqs' }, $event)"
          >
            <b class="t">{{ r.title }}</b>
            <span class="code">{{ byCode[r.code].short }}</span>
            <span class="n">{{ r.kind }}</span>
          </button>
        </li>
      </TransitionGroup>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue';
import { byCode, courses, nav, openCourse, search, store } from './store.js';

const id = 'current-q';
const input = ref(null);
const q = ref('');
const CHIPS = ['ma1 pyq', 'dbms week 4', 'q1 stats', 'python notes'];

const res = computed(() => search(q.value));
const hits = computed(() => res.value.courses);
const deepest = [...courses]
  .sort((a, b) => b.pyqs.length + b.notes.length - (a.pyqs.length + a.notes.length))
  .slice(0, 4);

function unit(h) {
  if (h.tab === 'notes') return h.week ? `week ${h.week} notes` : 'notes';
  return h.exam && h.exam !== 'All' ? `${h.exam} papers` : 'past papers';
}

function try_(c) {
  q.value = c;
  input.value?.focus();
}

function seeAll() {
  store.q = q.value.trim();
  nav.go('resources');
}

defineExpose({ focus: () => input.value?.focus({ preventScroll: true }) });
</script>

<style scoped>
.cs {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 14px;
  align-content: start;
}
.field {
  position: relative;
  display: flex;
  align-items: center;
  gap: 10px;
  height: 58px;
  padding: 0 8px 0 18px;
  border-radius: 16px;
  background: var(--card);
  border: 1.5px solid var(--line-strong);
  box-shadow: var(--shadow);
  transition: border-color 0.2s;
}
.field:focus-within {
  border-color: var(--mari-ink);
}
.lens {
  flex: none;
  width: 20px;
  height: 20px;
  fill: none;
  stroke: var(--ink-2);
  stroke-width: 2;
  stroke-linecap: round;
}
input {
  flex: 1;
  width: 0;
  min-width: 0;
  height: 100%;
  border: 0;
  background: none;
  font: inherit;
  font-size: 17px;
  font-weight: 550;
  color: var(--ink);
  outline: none;
}
input::placeholder {
  color: var(--ink-3);
  font-weight: 450;
}
input::-webkit-search-cancel-button {
  display: none;
}
.all {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 42px;
  padding: 0 14px;
  border: 0;
  border-radius: 11px;
  background: var(--mari);
  color: var(--on-mari);
  font-size: 14.5px;
  font-weight: 700;
  white-space: nowrap;
}
.all svg {
  width: 16px;
  height: 16px;
  fill: none;
  stroke: currentColor;
  stroke-width: 2.2;
  stroke-linecap: round;
  stroke-linejoin: round;
  transition: transform 0.25s var(--ease-spring);
}
.all:hover svg {
  transform: translateX(3px);
}
/* A ripple of current runs under the field while it has focus. */
.ripple {
  position: absolute;
  left: 18px;
  right: 18px;
  bottom: -11px;
  width: calc(100% - 36px);
  height: 8px;
  fill: none;
  stroke: var(--flow);
  stroke-width: 1.5;
  opacity: 0;
  transition: opacity 0.3s;
}
.ripple path {
  animation: ripple 1.6s linear infinite;
}
.field:focus-within .ripple {
  opacity: 0.8;
}
@keyframes ripple {
  to {
    transform: translateX(-50px);
  }
}
.label {
  margin: 6px 0 0;
  font-family: var(--mono);
  font-size: 11.5px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--ink-2);
}
.idle,
.found {
  display: grid;
  gap: 10px;
}
.chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
.chips button {
  height: 36px;
  padding: 0 14px;
  border-radius: 99px;
  border: 1.5px dashed var(--line-strong);
  background: none;
  font-family: var(--mono);
  font-size: 13.5px;
  color: var(--ink);
  transition:
    background 0.2s,
    border-color 0.2s;
}
.chips button:hover {
  border-style: solid;
  border-color: var(--mari-ink);
  background: var(--mari-soft);
}
.hits {
  display: grid;
  gap: 6px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.hits button {
  width: 100%;
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: baseline;
  gap: 12px;
  padding: 12px 16px;
  border: 0;
  border-radius: 12px;
  background: color-mix(in srgb, var(--card) 80%, transparent);
  text-align: left;
  box-shadow: inset 0 0 0 1px var(--line);
  transition:
    transform 0.3s var(--ease-spring),
    box-shadow 0.2s,
    background 0.2s;
}
.hits button:hover {
  transform: translateX(6px);
  background: var(--card);
  box-shadow:
    inset 0 0 0 1.5px var(--mari),
    var(--shadow);
}
.hits b {
  font-size: 16px;
  font-weight: 700;
}
.hits b.t {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 14.5px;
  font-weight: 600;
}
.code {
  font-family: var(--mono);
  font-size: 12.5px;
  color: var(--ink-2);
}
.n {
  font-family: var(--mono);
  font-size: 13px;
  font-weight: 600;
  color: var(--mari-ink);
  white-space: nowrap;
}
.n i {
  font-style: normal;
  color: var(--ink-3);
}
.idle .hits li {
  animation: boat 0.6s var(--ease-out) both;
  animation-delay: calc(var(--i) * 60ms);
}
.boat-enter-active {
  transition:
    opacity 0.45s var(--ease-out),
    transform 0.55s var(--ease-out);
  transition-delay: calc(var(--i) * 45ms);
}
.boat-leave-active {
  display: none;
}
.boat-enter-from {
  opacity: 0;
  transform: translateX(-28px);
}
@keyframes boat {
  from {
    opacity: 0;
    transform: translateX(-28px);
  }
}
@media (max-width: 520px) {
  .hits button {
    grid-template-columns: 1fr auto;
  }
  .hits .code {
    display: none;
  }
  .all {
    padding: 0 12px;
  }
}
@media (prefers-reduced-motion: reduce) {
  .ripple path {
    animation: none;
  }
}
</style>
