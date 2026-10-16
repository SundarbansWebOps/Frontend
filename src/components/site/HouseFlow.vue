<!--
  "How the house works": a symmetric tree. The Upper House Council, then the Lower House
  Council, then one centre line splits into two equal columns, Communities and Teams. Every chip
  jumps to its section. Portraits and team colour only; no regions. The connectors land on the
  centre of each column because the bar's ends are inset by the same formula as an equal
  two-column grid.
-->
<template>
  <div class="tree">
    <button type="button" class="pill rise" style="--i: 0" @click="$emit('go', 'uhc')">
      <span class="faces" aria-hidden="true">
        <img v-for="p in upper" :key="p.id" :src="portrait.face(p.img)" alt="" />
      </span>
      Upper House Council
    </button>
    <span class="stem s1" aria-hidden="true" />
    <button type="button" class="pill rise" style="--i: 1" @click="$emit('go', 'lhc')">
      <span class="faces" aria-hidden="true">
        <img v-for="p in lower" :key="p.id" :src="portrait.face(p.img)" alt="" />
      </span>
      Lower House Council
    </button>
    <span class="stem s2" aria-hidden="true" />
    <span class="bar" aria-hidden="true" />

    <div v-for="c in COLS" :key="c.id" class="col">
      <h3 class="label rise" style="--i: 2">{{ c.title }}</h3>
      <button
        v-for="(it, n) in c.items"
        :key="it.id"
        type="button"
        class="chip rise"
        :style="{ '--i': 3 + n }"
        @click="$emit('go', c.to, it.id)"
      >
        <span class="dot" :style="{ '--c': it.color }" aria-hidden="true" />
        {{ it.name }}
        <span v-if="it.heads.length" class="heads" aria-hidden="true">
          <img v-for="p in it.heads" :key="p.name" :src="portrait.face(p.img)" alt="" />
        </span>
      </button>
    </div>
  </div>
</template>

<script setup>
import { COMMUNITIES, TEAMS } from '../../data/teams.js';
import { lower, portrait, upper } from '../../lib/house.js';

defineEmits(['go']);

// Each chip carries only its heads and co-heads, as the council rows carry the council.
const item = (t) => ({
  id: t.id,
  name: t.name,
  color: tint(t),
  heads: t.people.filter((p) => p.lead),
});

// Same colour rule as TeamCards: a community takes its wing colour, a team takes marigold.
const tint = (t) => (t.wing ? `var(--w-${t.wing})` : 'var(--mari-ink)');

const COLS = [
  {
    id: 'com',
    to: 'communities',
    title: 'Communities',
    items: COMMUNITIES.map(item),
  },
  {
    id: 'teams',
    to: 'teams',
    title: 'Teams',
    items: TEAMS.map(item),
  },
];
</script>

<style scoped>
.tree {
  --g: 40px;
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  column-gap: var(--g);
  row-gap: 0;
  width: min(720px, 100%);
  margin: 0 auto;
}
@media (max-width: 560px) {
  .tree {
    --g: 12px;
  }
}

.pill {
  grid-column: 1 / -1;
  justify-self: center;
  display: inline-flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  padding: 12px 24px 14px;
  border: 1px solid var(--line);
  border-radius: 22px;
  background: var(--card);
  box-shadow: var(--shadow);
  color: var(--ink);
  font: inherit;
  font-size: 16px;
  font-weight: 700;
  letter-spacing: -0.01em;
  cursor: pointer;
  transition:
    border-color 0.2s,
    translate 0.3s var(--ease-out);
}
.faces {
  display: flex;
}
.faces img {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: 2px solid var(--card);
  object-fit: cover;
  background: var(--sunk);
}
.faces img + img {
  margin-left: -10px;
}

/* Vertical connectors draw down from the top; the bar draws out from the centre. */
.stem,
.bar,
.col::before {
  background: var(--line-strong);
}
.stem {
  position: relative;
  grid-column: 1 / -1;
  justify-self: center;
  width: 1.5px;
  transform-origin: top;
  animation: down 0.45s var(--ease-out) both;
}
.s1 {
  height: 28px;
  animation-delay: 0.07s;
  --len: 22px;
}
.s2 {
  height: 22px;
  animation-delay: 0.14s;
  --len: 16px;
}
/* One marigold drop runs down each stem once it has drawn; it fades out at the bottom. */
.stem::after {
  content: '';
  position: absolute;
  left: 50%;
  top: 0;
  width: 5px;
  height: 5px;
  margin-left: -2.25px;
  border-radius: 50%;
  background: var(--mari);
  opacity: 0;
  animation: drop 0.9s var(--ease-out) both;
  animation-delay: calc(var(--d, 0s) + 0.45s);
}
.s1::after {
  --d: 0.07s;
}
.s2::after {
  --d: 0.14s;
}
@keyframes drop {
  20% {
    opacity: 1;
  }
  to {
    transform: translateY(var(--len));
    opacity: 0;
  }
}
.bar {
  grid-column: 1 / -1;
  height: 1.5px;
  /* Each end sits on the centre of an equal column: (100% - gap) / 4 in from the side. */
  margin-inline: calc((100% - var(--g)) / 4);
  transform-origin: center;
  animation: across 0.45s var(--ease-out) 0.2s both;
}
@keyframes down {
  from {
    transform: scaleY(0);
  }
}
@keyframes across {
  from {
    transform: scaleX(0);
  }
}

.col {
  position: relative;
  display: grid;
  gap: 10px;
  justify-items: center;
  padding-top: 14px;
}
/* The drop from the bar to each column's heading. */
.col::before {
  content: '';
  position: absolute;
  top: -16px;
  left: 50%;
  width: 1.5px;
  height: 16px;
  margin-left: -0.75px;
  transform-origin: top;
  animation: down 0.4s var(--ease-out) 0.5s both;
}

.label {
  margin: 0 0 4px;
  padding: 4px 12px;
  border-radius: 99px;
  background: var(--mari-soft);
  color: var(--mari-ink);
  font-size: 11px;
  font-weight: 650;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

.chip {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  width: min(220px, 100%);
  height: 40px;
  padding: 0 14px;
  border: 1px solid var(--line);
  border-radius: 99px;
  background: var(--card);
  color: var(--ink);
  font: inherit;
  font-size: 14.5px;
  font-weight: 650;
  white-space: nowrap;
  cursor: pointer;
  transition:
    border-color 0.2s,
    translate 0.3s var(--ease-out);
}
.dot {
  flex: none;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--c);
}

.heads {
  display: flex;
  margin-left: 2px;
}
.heads img {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  border: 2px solid var(--card);
  object-fit: cover;
  background: var(--sunk);
}
.heads img + img {
  margin-left: -8px;
}

/* Phone: two chip columns share the width, so tighten the chip around its heads. */
@media (max-width: 560px) {
  .chip {
    gap: 6px;
    padding: 0 8px;
    font-size: 13.5px;
  }
  .heads img {
    width: 20px;
    height: 20px;
  }
}

/* Hover uses `translate`, not `transform`: the rise keyframes own `transform` (fill: both). */
.pill:hover,
.chip:hover {
  border-color: var(--line-strong);
  translate: 0 -2px;
}
</style>
