<!--
  PROTOTYPE — Home variant 3 ("Current"): the Teams landing stage. How the house works, drawn
  as one river branching: the Upper House Council feeds the Lower House Council, which splits
  into the communities and the crew. Channel widths narrow downstream; seats are dots.
-->
<template>
  <div ref="wrap" class="cb" :class="{ up: active, tall }">
    <svg
      :viewBox="`0 0 ${L.w} ${L.h}`"
      role="img"
      :aria-label="`Upper House Council, ${upper.length} seats, feeds the Lower House Council, ${lower.length} seats, which runs the ${COMMUNITIES.length} communities and the ${CREW.length} crew teams`"
    >
      <g
        v-for="e in edges"
        :key="e.id"
        class="edge"
        :style="{ '--d': `${e.depth * 260}ms`, '--sw': e.width + 'px' }"
      >
        <path :d="e.d" class="bed" pathLength="1" />
        <path :d="e.d" class="flow" />
      </g>
      <g
        v-for="n in nodes"
        :key="n.id"
        class="node"
        :class="[n.kind, n.wing && `w-${n.wing}`]"
        :transform="`translate(${n.x} ${n.y})`"
        :style="{ '--d': `${n.depth * 260 + 200}ms` }"
      >
        <circle :r="n.r" class="dot" />
        <g :transform="`translate(${n.lx} ${n.ly})`">
          <text :text-anchor="n.anchor" class="name">{{ n.name }}</text>
          <text v-if="n.sub" :text-anchor="n.anchor" y="15" class="sub">{{ n.sub }}</text>
          <g
            v-if="n.seats"
            class="seats"
            :transform="`translate(${n.anchor === 'middle' ? -((n.seats - 1) * 9) / 2 : 0} ${n.sub ? 28 : 14})`"
          >
            <circle v-for="k in n.seats" :key="k" :cx="(k - 1) * 9" r="3" :style="{ '--k': k }" />
          </g>
        </g>
      </g>
    </svg>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import { lower, upper } from './house.js';
import { COMMUNITIES, CREW } from './teams.js';

defineProps({ active: { type: Boolean, default: false } });

const wrap = ref(null);
const tall = ref(false);
let ro;
onMounted(() => {
  ro = new ResizeObserver(([e]) => (tall.value = e.contentRect.width < 520));
  ro.observe(wrap.value);
});
onBeforeUnmount(() => ro?.disconnect());

// Two layouts of the same river: wide (left → right) and tall (top → bottom) for phones.
const L = computed(() => (tall.value ? { w: 340, h: 540 } : { w: 700, h: 340 }));

const nodes = computed(() => {
  const t = tall.value;
  const out = [];
  const add = (n) => out.push(n);
  add({
    id: 'uhc',
    kind: 'trunk',
    depth: 0,
    name: 'Upper House Council',
    sub: `${upper.length} seats`,
    seats: upper.length,
    r: 9,
    ...(t
      ? { x: 170, y: 26, lx: 16, ly: 5, anchor: 'start' }
      : { x: 30, y: 170, lx: 0, ly: -48, anchor: 'start' }),
  });
  add({
    id: 'lhc',
    kind: 'trunk',
    depth: 1,
    name: 'Lower House Council',
    sub: `${lower.length} seats`,
    seats: lower.length,
    r: 8,
    ...(t
      ? { x: 170, y: 130, lx: 16, ly: 5, anchor: 'start' }
      : { x: 230, y: 170, lx: 0, ly: 32, anchor: 'middle' }),
  });
  add({
    id: 'comm',
    kind: 'arm',
    depth: 2,
    name: 'Communities',
    r: 6,
    ...(t
      ? { x: 60, y: 250, lx: -4, ly: -14, anchor: 'start' }
      : { x: 400, y: 92, lx: 0, ly: -16, anchor: 'middle' }),
  });
  add({
    id: 'crew',
    kind: 'arm',
    depth: 2,
    name: 'Crew',
    r: 6,
    ...(t
      ? { x: 214, y: 250, lx: -4, ly: -14, anchor: 'start' }
      : { x: 400, y: 248, lx: 0, ly: 26, anchor: 'middle' }),
  });
  COMMUNITIES.forEach((c, i) =>
    add({
      id: c.id,
      kind: 'leaf',
      parent: 'comm',
      depth: 3,
      wing: c.wing,
      name: c.name,
      sub: `${c.events} events`,
      r: 5,
      ...(t
        ? { x: 60, y: 330 + i * 70, lx: 14, ly: 4, anchor: 'start' }
        : { x: 560, y: 36 + i * 54, lx: 14, ly: -1, anchor: 'start' }),
    })
  );
  CREW.forEach((c, i) =>
    add({
      id: c.id,
      kind: 'leaf',
      parent: 'crew',
      depth: 3,
      name: c.name,
      r: 5,
      ...(t
        ? { x: 214, y: 330 + i * 70, lx: 14, ly: 4, anchor: 'start' }
        : { x: 560, y: 196 + i * 54, lx: 14, ly: 5, anchor: 'start' }),
    })
  );
  return out;
});

const edges = computed(() => {
  const by = Object.fromEntries(nodes.value.map((n) => [n.id, n]));
  const t = tall.value;
  const link = (a, b, width) => {
    const A = by[a];
    const B = by[b];
    const d = t
      ? `M${A.x} ${A.y} C${A.x} ${(A.y + B.y) / 2} ${B.x} ${(A.y + B.y) / 2} ${B.x} ${B.y}`
      : `M${A.x} ${A.y} C${(A.x + B.x) / 2} ${A.y} ${(A.x + B.x) / 2} ${B.y} ${B.x} ${B.y}`;
    return { id: `${a}-${b}`, d, width, depth: B.depth - 1 };
  };
  return [
    link('uhc', 'lhc', 11),
    link('lhc', 'comm', 7),
    link('lhc', 'crew', 7),
    ...nodes.value.filter((n) => n.parent).map((n) => link(n.parent, n.id, 3.5)),
  ];
});
</script>

<style scoped>
.cb {
  width: 100%;
}
svg {
  display: block;
  width: 100%;
  max-height: min(58vh, 440px);
  overflow: visible;
}
.tall svg {
  max-height: none;
}
.bed {
  fill: none;
  stroke: var(--channel);
  stroke-width: var(--sw);
  stroke-linecap: round;
  stroke-dasharray: 1 1;
  stroke-dashoffset: 1;
  transition: stroke-dashoffset 0.9s var(--ease-out) var(--d);
}
.up .bed {
  stroke-dashoffset: 0;
}
.flow {
  fill: none;
  stroke: var(--flow);
  stroke-width: calc(var(--sw) * 0.34);
  stroke-linecap: round;
  stroke-dasharray: 2 9;
  opacity: 0;
  transition: opacity 0.6s calc(var(--d) + 0.8s);
  animation: flow 1.2s linear infinite;
}
.up .flow {
  opacity: 0.9;
}
@keyframes flow {
  to {
    stroke-dashoffset: -11;
  }
}
.node {
  opacity: 0;
  transition: opacity 0.5s var(--d);
}
.up .node {
  opacity: 1;
}
.dot {
  fill: var(--paper);
  stroke: var(--ink);
  stroke-width: 2;
}
.trunk .dot {
  fill: var(--mari);
}
.leaf .dot {
  fill: var(--w, var(--ink-3));
  stroke: var(--paper);
}
.name {
  font-size: 14px;
  font-weight: 700;
  fill: var(--ink);
}
.trunk .name {
  font-size: 15.5px;
}
.arm .name {
  font-family: var(--mono);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  fill: var(--ink-2);
}
.sub {
  font-family: var(--mono);
  font-size: 11.5px;
  fill: var(--ink-2);
}
.seats circle {
  fill: var(--mari);
  stroke: var(--ink);
  stroke-width: 1;
}
@media (prefers-reduced-motion: reduce) {
  .flow {
    animation: none;
  }
}
</style>
