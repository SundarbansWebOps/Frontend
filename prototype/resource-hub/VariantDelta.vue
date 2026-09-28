<!-- PROTOTYPE variant A — "Delta": the course map is the navigator. -->
<template>
  <main class="wrap">
    <div class="bar">
      <SearchBar v-model="q" class="rise" style="--i: 0" />
      <TideLine class="rise" style="--i: 1" @pick="pick" />
    </div>

    <section class="mine rise" style="--i: 2" aria-labelledby="mine-h">
      <h2 id="mine-h" class="eyebrow">
        My courses <span v-if="store.mine.length" class="mono">{{ store.mine.length }}</span>
      </h2>
      <TransitionGroup name="tix" tag="div" class="tix">
        <CourseTicket v-for="code in store.mine" :key="code" :code="code" />
        <p v-if="!store.mine.length" key="empty" class="hint">
          <span class="dot" /> Tap your courses on the map below and pin them. Next time the site
          opens straight to them.
        </p>
      </TransitionGroup>
    </section>

    <section class="map rise" style="--i: 3" aria-labelledby="map-h">
      <div class="map-head">
        <h2 id="map-h" class="eyebrow">Every course, as the degree flows</h2>
        <p class="legend">
          <span><i class="k-mine" /> yours</span>
          <span class="only-h"><i class="k-trail" /> hover to trace the route</span>
        </p>
      </div>
      <DeltaMap :mine="store.mine" :match="match" @open="(c, e) => openCourse(c, parsed, e)" />
    </section>

    <section class="rise" style="--i: 4" aria-labelledby="tools-h">
      <h2 id="tools-h" class="eyebrow">Quick links</h2>
      <ToolLinks />
    </section>
  </main>
</template>

<script setup>
import { computed, ref } from 'vue';
import SearchBar from './SearchBar.vue';
import TideLine from './TideLine.vue';
import DeltaMap from './DeltaMap.vue';
import CourseTicket from './CourseTicket.vue';
import ToolLinks from './ToolLinks.vue';
import { openCourse, search, store } from './store.js';

const q = ref(store.q);
store.q = '';
const res = computed(() => search(q.value));
const parsed = computed(() => ({
  tab: res.value.parsed.tab ?? 'pyqs',
  exam: res.value.parsed.exam ?? 'All',
  week: res.value.parsed.week,
}));
const match = computed(() =>
  q.value.trim()
    ? new Set([...res.value.courses.map((c) => c.code), ...res.value.resources.map((r) => r.code)])
    : null
);
function pick(d) {
  if (d.exam) q.value = `${d.exam.toLowerCase()} pyq`;
}
</script>

<style scoped>
.wrap {
  max-width: 1240px;
  margin: 0 auto;
  padding: 20px 24px 60px;
  display: grid;
  gap: 28px;
}
.bar {
  display: grid;
  grid-template-columns: 1fr minmax(360px, 440px);
  gap: 16px;
  align-items: start;
}
.eyebrow {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 12px;
  font-size: 13px;
  font-weight: 650;
  letter-spacing: 0.01em;
  color: var(--ink-2);
}
.eyebrow .mono {
  font-size: 11px;
  padding: 1px 6px;
  border-radius: 5px;
  background: var(--mari);
  color: var(--on-mari);
}
.tix {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(270px, 1fr));
  gap: 12px;
}
.hint {
  grid-column: 1 / -1;
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 0;
  padding: 16px 18px;
  border: 1.5px dashed var(--line-strong);
  border-radius: 14px;
  color: var(--ink-2);
  font-size: 14.5px;
}
.hint .dot {
  flex: none;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: var(--mari);
  box-shadow: 0 0 0 5px var(--mari-soft);
}
.tix-enter-active {
  animation: print 0.7s var(--ease-out) both;
}
.tix-leave-active {
  transition:
    opacity 0.25s,
    transform 0.3s;
  position: absolute;
}
.tix-leave-to {
  opacity: 0;
  transform: scale(0.9) translateY(10px);
}
.tix-move {
  transition: transform 0.5s var(--ease-out);
}
@keyframes print {
  from {
    clip-path: inset(0 0 100% 0);
    transform: translateY(-14px);
  }
  to {
    clip-path: inset(0 0 0 0);
  }
}
.map {
  margin: 0 -8px;
  padding: 18px 8px 8px;
  border-top: 1px solid var(--line);
  border-bottom: 1px solid var(--line);
}
.map-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 16px;
}
.legend {
  display: flex;
  gap: 16px;
  margin: 0;
  font-size: 12.5px;
  color: var(--ink-2);
}
.legend span {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}
.k-mine {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: var(--mari);
  border: 1.5px solid var(--ink);
}
.k-trail {
  width: 18px;
  height: 4px;
  border-radius: 2px;
  background: var(--mari);
}
@media (max-width: 900px) {
  .bar {
    grid-template-columns: 1fr;
  }
}
@media (max-width: 760px) {
  .wrap {
    padding: 14px 16px 100px;
    gap: 22px;
  }
  .only-h {
    display: none !important;
  }
  .tix {
    grid-template-columns: none;
    grid-auto-flow: column;
    grid-auto-columns: 82%;
    overflow-x: auto;
    scroll-snap-type: x mandatory;
    padding-bottom: 6px;
    margin: 0 -16px;
    padding-left: 16px;
    padding-right: 16px;
    scrollbar-width: none;
  }
  .tix > * {
    scroll-snap-align: start;
  }
  .tix:has(> .hint) {
    display: block;
    margin: 0;
    padding: 0;
  }
}
</style>
