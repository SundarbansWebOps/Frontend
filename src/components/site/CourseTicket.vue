<!--
  A pinned course as a ticket stub: code on the stub, tap anywhere on the ticket
  to open the course in the study panel. Perforation is a CSS mask, not an image.
-->
<template>
  <article
    v-if="c"
    class="ticket"
    role="button"
    tabindex="0"
    :aria-label="`Open ${c.short} in the study panel`"
    @click="openCourse(c.code, {}, $event)"
    @keydown.enter="openCourse(c.code, {}, $event)"
  >
    <div class="stub">
      <span class="mono">{{ c.code }}</span>
    </div>
    <div class="main">
      <span class="name">
        <b>{{ c.short }}</b>
        <small v-if="c.name !== c.short">{{ c.name }}</small>
      </span>
    </div>
    <button
      type="button"
      class="x"
      :title="`Remove ${c.short}`"
      @click.stop="togglePin(c.code)"
    >
      <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 7l10 10M17 7 7 17" /></svg>
      <span class="visually-hidden">Remove {{ c.short }} from my courses</span>
    </button>
  </article>
</template>

<script setup>
import { computed } from 'vue';
import { courseFor, openCourse, togglePin } from '../../lib/store.js';

const props = defineProps({ code: String });
const c = computed(() => courseFor(props.code));
</script>

<style scoped>
.ticket {
  --notch: 9px;
  --stub: 44px;
  position: relative;
  display: grid;
  grid-template-columns: var(--stub) minmax(0, 1fr);
  min-width: 0;
  border: 1px solid color-mix(in srgb, var(--acc, var(--mari)) 22%, var(--line-strong));
  border-radius: 14px;
  background: linear-gradient(
    145deg,
    color-mix(in srgb, var(--mari-soft) 28%, var(--card)),
    var(--card) 58%
  );
  box-shadow: var(--shadow);
  cursor: pointer;
  /* two notches where the stub tears off */
  mask:
    radial-gradient(circle var(--notch) at var(--stub) 0, #0000 98%, #000) top / 100% 51% no-repeat,
    radial-gradient(circle var(--notch) at var(--stub) 100%, #0000 98%, #000) bottom / 100% 51%
      no-repeat;
  transition: transform 0.35s var(--ease-out);
}
.ticket::before {
  content: '';
  position: absolute;
  z-index: 1;
  top: 1px;
  right: 12px;
  left: 12px;
  height: 1px;
  background: linear-gradient(
    90deg,
    transparent,
    color-mix(in srgb, var(--mari) 58%, var(--card)),
    transparent
  );
  pointer-events: none;
}
.ticket.completed {
  border-color: var(--line-strong);
  background: var(--sunk);
}
.ticket:hover {
  transform: translateY(-2px);
}
.ticket:focus-visible {
  outline: 2px solid var(--acc, var(--mari-ink));
  outline-offset: 2px;
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
  align-content: center;
  gap: 7px;
  padding: 8px 36px 8px 12px;
  min-width: 0;
}
.name {
  display: grid;
  gap: 2px;
  justify-items: start;
  text-align: left;
}
.name b {
  font-size: 19px;
  font-weight: 750;
  letter-spacing: -0.03em;
  line-height: 1.05;
}
.name small {
  font-size: 12px;
  line-height: 1.3;
  color: var(--ink-2);
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
