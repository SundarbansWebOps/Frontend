<!--
  A pinned course as a ticket stub: code on the stub, the two things you
  actually open this week on the body. Perforation is a CSS mask, not an image.
-->
<template>
  <article v-if="c" class="ticket">
    <div class="stub">
      <span class="mono">{{ c.code }}</span>
    </div>
    <div class="main">
      <button type="button" class="name" @click="openCourse(c.code, {}, $event)">
        <b>{{ c.short }}</b>
      </button>
      <div class="acts">
        <button
          v-if="examCount"
          type="button"
          class="act hot"
          @click="openCourse(c.code, { tab: 'pyqs', exam: nextExam.exam }, $event)"
        >
          {{ nextExam.label }} papers <i>{{ examCount }}</i>
        </button>
        <button
          type="button"
          class="act"
          @click="
            openCourse(c.code, { tab: 'notes', week: weekCount ? currentWeek : null }, $event)
          "
        >
          {{ weekCount ? `Week ${currentWeek} notes` : 'Notes' }}
          <i>{{ weekCount || c.notes.length }}</i>
        </button>
      </div>
    </div>
    <button type="button" class="x" :title="`Remove ${c.short}`" @click="togglePin(c.code)">
      <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 7l10 10M17 7 7 17" /></svg>
      <span class="visually-hidden">Remove {{ c.short }} from my courses</span>
    </button>
  </article>
</template>

<script setup>
import { computed } from 'vue';
import { courseFor, openCourse, togglePin } from '../../lib/store.js';
import { currentWeek, nextExam } from '../../lib/courses.js';

const props = defineProps({ code: String });
const c = computed(() => courseFor(props.code));
const examCount = computed(
  () => c.value?.pyqs.filter((p) => p.exam === nextExam?.exam).length ?? 0
);
const weekCount = computed(() => c.value?.notes.filter((n) => n.week === currentWeek).length ?? 0);
</script>

<style scoped>
.ticket {
  --notch: 9px;
  --stub: 44px;
  position: relative;
  display: grid;
  grid-template-columns: var(--stub) 1fr;
  min-width: 0;
  border-radius: 14px;
  background: var(--card);
  box-shadow: var(--shadow);
  /* two notches where the stub tears off */
  mask:
    radial-gradient(circle var(--notch) at var(--stub) 0, #0000 98%, #000) top / 100% 51% no-repeat,
    radial-gradient(circle var(--notch) at var(--stub) 100%, #0000 98%, #000) bottom / 100% 51%
      no-repeat;
  transition: transform 0.35s var(--ease-out);
}
.ticket:hover {
  transform: translateY(-2px) rotate(-0.3deg);
}
.stub {
  display: grid;
  place-items: center;
  background: var(--acc-wash, var(--mari-soft));
  color: var(--acc, var(--mari-ink));
  border-right: 2px dashed color-mix(in srgb, var(--acc, var(--mari)) 45%, transparent);
}
.stub span {
  writing-mode: vertical-rl;
  transform: rotate(180deg);
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.08em;
}
.main {
  display: grid;
  align-content: space-between;
  gap: 10px;
  padding: 12px 36px 12px 14px;
  min-width: 0;
}
.name {
  display: grid;
  gap: 2px;
  justify-items: start;
  padding: 0;
  border: 0;
  background: none;
  text-align: left;
}
.name b {
  font-size: 21px;
  font-weight: 750;
  letter-spacing: -0.03em;
  line-height: 1.05;
}
.name:hover b {
  text-decoration: underline 2px var(--acc, var(--mari));
  text-underline-offset: 4px;
}
.name small {
  font-size: 13px;
  color: var(--ink-2);
}
.acts {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.act {
  padding: 5px 10px;
  border: 1px solid var(--line-strong);
  border-radius: 8px;
  background: var(--paper);
  font-size: 12.5px;
  font-weight: 600;
  white-space: nowrap;
  transition:
    background 0.2s,
    border-color 0.2s,
    transform 0.25s var(--ease-spring);
}
.act i {
  font-style: normal;
  font-family: var(--mono);
  font-size: 11px;
  font-weight: 400;
  color: var(--ink-3);
}
.act:hover {
  border-color: var(--ink);
  transform: translateY(-1px);
}
.act.hot {
  border-color: var(--acc, var(--verm));
  color: var(--acc, var(--verm));
}
.act.hot i {
  color: inherit;
}
.x {
  position: absolute;
  top: 8px;
  right: 8px;
  display: grid;
  place-items: center;
  width: 26px;
  height: 26px;
  border: 0;
  border-radius: 8px;
  background: none;
  color: var(--ink-3);
  opacity: 0;
  transition: opacity 0.2s;
}
.ticket:hover .x,
.x:focus-visible {
  opacity: 1;
}
.x:hover {
  background: var(--sunk);
  color: var(--ink);
}
.x svg {
  width: 15px;
  height: 15px;
  fill: none;
  stroke: currentColor;
  stroke-width: 2;
  stroke-linecap: round;
}
@media (hover: none) {
  .x {
    opacity: 1;
  }
}
</style>
