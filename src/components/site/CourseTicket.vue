<!--
  A pinned course as a small ticket: code on the marigold stub, the name and the two things to open
  this week on the body. Chips match the Delta ticket: papers for the next exam and notes for the
  current week. The notches where the stub tears off are a CSS mask, not an image.
-->
<template>
  <article v-if="c" class="ticket">
    <div class="stub">
      <span class="mono">{{ c.code }}</span>
    </div>
    <div class="main">
      <button
        type="button"
        class="name"
        :aria-label="`Open ${c.short} in the study panel`"
        @click="openCourse(c.code, {}, $event)"
      >
        {{ c.short }}
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
  --notch: 7px;
  --stub: 30px;
  position: relative;
  display: grid;
  grid-template-columns: var(--stub) minmax(0, 1fr);
  min-width: 0;
  border-radius: 12px;
  background: var(--card);
  box-shadow: var(--shadow);
  /* two notches where the stub tears off */
  mask:
    radial-gradient(circle var(--notch) at var(--stub) 0, transparent 98%, black) top / 100% 51%
      no-repeat,
    radial-gradient(circle var(--notch) at var(--stub) 100%, transparent 98%, black) bottom / 100%
      51% no-repeat;
  transition: transform 0.35s var(--ease-out);
}
.ticket:hover {
  transform: translateY(-2px) rotate(-0.3deg);
}
.stub {
  display: grid;
  place-items: center;
  background: var(--mari);
  color: var(--on-mari);
  border-right: 2px dashed color-mix(in srgb, var(--on-mari) 35%, transparent);
}
.stub span {
  writing-mode: vertical-rl;
  transform: rotate(180deg);
  font-size: 10.5px;
  font-weight: 600;
  letter-spacing: 0.08em;
}
.main {
  display: grid;
  align-content: center;
  gap: 4px;
  padding: 7px 24px 7px 9px;
  min-width: 0;
}
.name {
  justify-self: start;
  padding: 0;
  border: 0;
  background: none;
  font-size: 15px;
  font-weight: 750;
  letter-spacing: -0.02em;
  line-height: 1.05;
  text-align: left;
}
.name:hover {
  text-decoration: underline 2px var(--mari);
  text-underline-offset: 3px;
}
.acts {
  display: flex;
  flex-wrap: wrap;
  gap: 3px;
}
.act {
  padding: 1px 5px;
  border: 1px solid var(--line-strong);
  border-radius: 6px;
  background: var(--paper);
  font-size: 10.5px;
  font-weight: 600;
  white-space: nowrap;
  transition:
    border-color 0.2s,
    transform 0.25s var(--ease-spring);
}
.act i {
  font-style: normal;
  font-family: var(--mono);
  font-size: 10px;
  font-weight: 400;
  color: var(--ink-3);
}
.act:hover {
  border-color: var(--ink);
  transform: translateY(-1px);
}
.act.hot {
  border-color: var(--verm);
  color: var(--verm);
}
.act.hot i {
  color: inherit;
}
.x {
  position: absolute;
  top: 5px;
  right: 5px;
  display: grid;
  place-items: center;
  width: 22px;
  height: 22px;
  border: 0;
  border-radius: 7px;
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
  width: 13px;
  height: 13px;
  fill: none;
  stroke: currentColor;
  stroke-width: 2;
  stroke-linecap: round;
}
/* Desktop tickets stand taller so the stub code fits and the body reads as a ticket. Phone keeps the tighter size. */
@media (min-width: 761px) {
  .ticket {
    --stub: 36px;
    min-height: 96px;
  }
  .stub span {
    font-size: 11.5px;
  }
  .main {
    gap: 6px;
    padding: 12px 26px 12px 13px;
  }
  .name {
    font-size: 17px;
  }
  .act {
    padding: 2px 7px;
    font-size: 11.5px;
  }
  .act i {
    font-size: 10.5px;
  }
}
@media (hover: none) {
  .x {
    opacity: 1;
  }
}
</style>
