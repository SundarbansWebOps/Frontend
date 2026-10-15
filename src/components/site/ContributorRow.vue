<!--
  One person on the Contributors leaderboard: rank, colour-ringed avatar, name, lines and share,
  the added/removed bar, the per-person line and the 16-week strip. The row links to their GitHub.
  phase "dash" is the first-screen list and rises in with the page. phase "late" is the full list,
  which rises in when it scrolls into view (the page observes it through data-late).
  Focus (hover or keyboard) goes up through the "focus" event so the whole board can highlight one person.
-->
<template>
  <li
    class="cr"
    :class="{ in: phase === 'dash', late: phase === 'late', ready, seen, settled }"
    :style="{ '--d': delay + 's' }"
  >
    <a
      class="row"
      :class="{ top, on, dim }"
      :style="{ '--c': p.color }"
      :href="p.profile"
      target="_blank"
      rel="noopener"
      @pointerenter="emit('focus', p.login)"
      @pointerleave="emit('focus', null)"
      @focus="emit('focus', p.login)"
      @blur="emit('focus', null)"
    >
      <span class="rank mono">{{ String(rank + 1).padStart(2, '0') }}</span>
      <span class="av">
        <img v-if="p.avatar && !failed" :src="p.avatar" alt="" @error="failed = true" />
        <template v-else>{{ initials }}</template>
      </span>
      <span class="who"
        ><b>{{ p.name }}</b></span
      >
      <span class="num">
        <b>{{ fmt(value) }}</b>
        <small>{{ p.shareText }}%</small>
      </span>
      <span class="bar-wrap">
        <span class="bar" :style="{ width: p.barWidth + '%' }">
          <b
            class="a"
            :class="{ grow: phase === 'dash' }"
            :style="{ flex: String(p.additions), '--gd': delay + 0.25 + 's' }"
          ></b>
          <b
            class="d"
            :class="{ grow: phase === 'dash' }"
            :style="{ flex: String(p.deletions), '--gd': delay + 0.45 + 's' }"
          ></b>
        </span>
        <span class="foot">
          <span>
            +{{ fmt(p.additions) }} −{{ fmt(p.deletions) }} · {{ p.commits }} commits ·
            {{ p.mergedPRs }} PRs
          </span>
          <span class="cells" title="Active weeks">
            <span v-for="(c, i) in p.cells" :key="i" :style="c.style"></span>
          </span>
        </span>
      </span>
    </a>
  </li>
</template>

<script setup>
import { computed, ref } from 'vue';

const props = defineProps({
  p: { type: Object, required: true },
  rank: { type: Number, required: true },
  top: { type: Boolean, default: false },
  phase: { type: String, required: true },
  ready: { type: Boolean, default: false },
  seen: { type: Boolean, default: false },
  settled: { type: Boolean, default: false },
  delay: { type: Number, default: 0 },
  value: { type: Number, default: 0 },
  on: { type: Boolean, default: false },
  dim: { type: Boolean, default: false },
});
const emit = defineEmits(['focus']);

const failed = ref(false);
const fmt = (n) => Math.round(n).toLocaleString('en-IN');
const initials = computed(() =>
  props.p.name
    .split(/[\s_-]+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0].toUpperCase())
    .join('')
);
</script>

<style scoped>
.cr {
  list-style: none;
  flex: none;
}
/* Entrance on the item, hover and focus dimming on the link, so they never share a transition. */
.cr.in {
  opacity: 0;
  transform: translateY(14px);
}
.cr.in.ready {
  opacity: 1;
  transform: none;
  transition:
    opacity 0.6s ease,
    transform 0.7s cubic-bezier(0.2, 0.9, 0.25, 1);
  transition-delay: var(--d, 0s);
}
/* After the entrance the item stops using the delayed entrance transition, so the next change is quick. */
.cr.in.ready.settled {
  transition:
    opacity 0.25s,
    transform 0.2s,
    border-color 0.2s;
  transition-delay: 0s;
}
.cr.late {
  opacity: 0;
  transform: translateY(18px);
}
.cr.late.seen {
  opacity: 1;
  transform: none;
  transition:
    opacity 0.6s ease,
    transform 0.7s cubic-bezier(0.2, 0.9, 0.25, 1);
  transition-delay: var(--d, 0s);
}

.row {
  --c: var(--s0);
  display: grid;
  grid-template-columns: 22px 40px minmax(0, 1fr) auto;
  gap: 6px 12px;
  align-items: center;
  padding: 10px 14px;
  border-radius: 16px;
  background: var(--card);
  border: 1px solid var(--line);
  color: inherit;
  text-decoration: none;
  transition:
    border-color 0.2s,
    transform 0.2s,
    opacity 0.25s;
}
.row:hover,
.row:focus-visible {
  border-color: var(--c);
  transform: translateX(3px);
}
.row.dim {
  opacity: 0.28;
}
.rank {
  grid-row: span 2;
  font-size: 12.5px;
  font-weight: 500;
  color: var(--ink-3);
}
.av {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  position: relative;
  grid-row: span 2;
  align-self: center;
  box-shadow:
    0 0 0 2px var(--card),
    0 0 0 4px var(--c);
  background: var(--paper);
  display: grid;
  place-items: center;
  font-weight: 750;
  font-size: 16px;
  color: var(--ink-2);
  overflow: hidden;
}
.av img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}
.who {
  min-width: 0;
}
.who b {
  display: block;
  font-size: 16.5px;
  font-weight: 650;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.num {
  display: flex;
  align-items: baseline;
  text-align: right;
}
.num b {
  display: block;
  font-size: 22px;
  font-weight: 750;
  letter-spacing: -0.035em;
  line-height: 1;
}
.num small {
  color: var(--ink-3);
  font-size: 12.5px;
  margin-left: 6px;
}
.bar-wrap {
  grid-column: 3 / 5;
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-width: 0;
}
.bar {
  display: flex;
  gap: 2px;
  height: 8px;
}
.bar b {
  display: block;
  height: 100%;
  transform-origin: left;
  min-width: 3px;
}
.bar .a {
  background: var(--c);
  border-radius: 4px 0 0 4px;
}
.bar .d {
  background: repeating-linear-gradient(135deg, var(--c) 0 2px, transparent 2px 4.5px);
  border-radius: 0 4px 4px 0;
}
/* Bars start at zero and grow once the dashboard has risen in. Late-list bars are already full. */
.grow {
  transform: scaleX(0);
}
.cr.ready .grow {
  transform: scaleX(1);
  transition: transform 1.1s cubic-bezier(0.2, 0.9, 0.25, 1);
  transition-delay: var(--gd, 0s);
}
.foot {
  display: flex;
  justify-content: space-between;
  gap: 10px;
  color: var(--ink-2);
  font-size: 12.5px;
}
.foot > span:first-child {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  min-width: 0;
}
.cells {
  display: flex;
  gap: 2px;
  align-items: center;
  flex: none;
}
.cells span {
  width: 7px;
  height: 7px;
  border-radius: 2px;
  background: var(--line);
}

/* The leader: a larger row with a marigold glow. */
.row.top {
  grid-template-columns: 22px 52px minmax(0, 1fr) auto;
  padding: 14px;
  background:
    linear-gradient(120deg, color-mix(in srgb, var(--mari) 16%, transparent), transparent 60%),
    var(--card);
}
:root[data-theme='dark'] .row.top {
  background:
    linear-gradient(120deg, color-mix(in srgb, var(--mari) 12%, transparent), transparent 60%),
    var(--card);
}
.row.top .av {
  width: 52px;
  height: 52px;
}
.row.top .num b {
  font-size: 30px;
}
.row.top .who b {
  font-size: 18px;
}

@media (max-width: 560px) {
  .row,
  .row.top {
    grid-template-columns: 18px 40px minmax(0, 1fr) auto;
    padding: 12px;
    gap: 4px 10px;
  }
  .row.top .av,
  .av {
    width: 40px;
    height: 40px;
  }
  .row.top .num b {
    font-size: 24px;
  }
  .num b {
    font-size: 19px;
  }
  .foot .cells {
    display: none;
  }
}
</style>
