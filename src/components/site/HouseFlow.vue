<!--
  "How the house works", drawn as a river delta. The Upper House Council is the
  river; it splits into three channels (regions, communities, crew); each team branches off its
  channel; every channel runs out into the sea — the members. The water draws itself down the
  page as you read, then keeps flowing. Channels are measured off the real boxes, so the same
  code draws the wide layout and the single-trunk phone layout. Every node jumps to its section.
-->
<template>
  <div ref="root" class="flow" :class="{ narrow }">
    <svg class="rivers" :width="W" :height="H" aria-hidden="true">
      <path
        v-for="e in edges"
        :key="e.k"
        class="ch"
        :class="e.kind"
        :d="e.d"
        pathLength="1"
        :style="{ '--l': lit(e) }"
      />
      <path
        v-for="e in edges"
        :key="`m-${e.k}`"
        class="motes"
        :class="{ on: lit(e) >= 1 }"
        :d="e.d"
      />
    </svg>

    <button
      type="button"
      class="node uhc"
      :class="{ in: seen('uhc') }"
      data-k="uhc"
      @click="$emit('go', 'uhc')"
    >
      <span class="faces">
        <img
          v-for="p in upper"
          :key="p.id"
          :src="portrait.face(p.img)"
          alt=""
          width="34"
          height="34"
        />
      </span>
      <span class="tx">
        <strong>Upper House Council</strong>
        <small>Secretary · Deputy Secretary · Web Admin — runs the house</small>
      </span>
    </button>

    <div class="cols">
      <div v-for="c in COLS" :key="c.id" class="col" :class="c.id">
        <button
          type="button"
          class="node head"
          :class="{ in: seen(c.id) }"
          :data-k="c.id"
          @click="$emit('go', c.to)"
        >
          <strong>{{ c.title }}</strong>
          <small>{{ c.sub }}</small>
          <b class="mono">{{ c.items.length }}</b>
        </button>
        <ul class="items">
          <li v-for="it in c.items" :key="it.id">
            <button
              type="button"
              class="node item"
              :class="{ in: seen(`${c.id}:${it.id}`), open: it.open }"
              :data-k="`${c.id}:${it.id}`"
              @click="$emit('go', c.to)"
            >
              <span class="mark" :style="it.color ? { '--c': it.color } : null">
                <img
                  v-for="f in it.faces ?? []"
                  :key="f"
                  :src="f"
                  alt=""
                  width="24"
                  height="24"
                  loading="lazy"
                />
              </span>
              <span class="tx">
                <strong>{{ it.name }}</strong>
                <small v-if="it.note">{{ it.note }}</small>
              </span>
            </button>
          </li>
        </ul>
      </div>
    </div>

    <div class="node sea" :class="{ in: seen('sea') }" data-k="sea">
      <svg class="waves" viewBox="0 0 800 40" preserveAspectRatio="none" aria-hidden="true">
        <path
          d="M0 18 Q50 8 100 18 T200 18 T300 18 T400 18 T500 18 T600 18 T700 18 T800 18 V40 H0Z"
        />
        <path
          d="M0 24 Q50 14 100 24 T200 24 T300 24 T400 24 T500 24 T600 24 T700 24 T800 24 V40 H0Z"
        />
      </svg>
      <span class="tx">
        <strong>Members</strong>
        <small>Every Sundarbans student. Come to an event, a meetup, or join a team.</small>
      </span>
    </div>
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue';
import { lower, portrait, regions, upper } from '../../lib/house.js';
import { COMMUNITIES, CREW } from '../../data/teams.js';

defineEmits(['go']);

const first = (n) => n.split(' ')[0];
const COLS = [
  {
    id: 'lhc',
    to: 'lhc',
    title: 'Lower House Council',
    sub: 'A coordinator for each region',
    items: [...regions]
      .sort((a, b) => a.name.localeCompare(b.name))
      .map((r) => ({
        id: r.id,
        name: r.name,
        note: r.coordinators.length
          ? r.coordinators.map((c) => first(c.name)).join(' & ')
          : 'No coordinator listed',
        faces: r.coordinators.map((c) => portrait.face(c.img)),
        open: !r.coordinators.length,
      })),
  },
  {
    id: 'com',
    to: 'communities',
    title: 'Communities',
    sub: 'Run the house’s events',
    items: COMMUNITIES.map((c) => ({
      id: c.id,
      name: c.name,
      note: `${c.events} events`,
      color: `var(--w-${c.wing})`,
    })),
  },
  {
    id: 'crew',
    to: 'crew',
    title: 'Crew',
    sub: 'Keep the house seen and online',
    items: CREW.map((c) => ({ id: c.id, name: c.name, color: 'var(--mari-ink)' })),
  },
];
// Make sure the LHC count matches the council (Mumbai has two coordinators).
COLS[0].sub = `${lower.length} coordinators across ${regions.length} regions`;

// ---- Geometry: read the real boxes, draw channels between them ---------------------------
const root = ref(null);
const W = ref(0);
const H = ref(0);
const narrow = ref(false);
const edges = ref([]);
const tops = ref({});

function measure() {
  const el = root.value;
  if (!el) return;
  narrow.value = el.clientWidth < 760;
  const o = el.getBoundingClientRect();
  const box = {};
  for (const n of el.querySelectorAll('.node')) {
    const r = n.getBoundingClientRect();
    box[n.dataset.k] = {
      l: r.left - o.left,
      r: r.right - o.left,
      t: r.top - o.top,
      b: r.bottom - o.top,
      cx: r.left - o.left + r.width / 2,
      cy: r.top - o.top + r.height / 2,
    };
  }
  W.value = Math.round(o.width);
  H.value = Math.round(o.height);
  tops.value = Object.fromEntries(Object.entries(box).map(([k, b]) => [k, b.t]));

  const out = [];
  const branch = (k, tx, n) =>
    out.push({
      k,
      kind: 'br',
      d: `M${tx} ${n.cy - 18} C${tx} ${n.cy - 2} ${tx + 4} ${n.cy} ${tx + 16} ${n.cy} L${n.l} ${n.cy}`,
      y0: n.cy - 18,
      y1: n.cy,
    });
  const u = box.uhc;
  const sea = box.sea;

  if (narrow.value) {
    // One trunk down the left edge; every head and team branches off it.
    const tx = 14;
    out.push({ k: 'trunk', kind: 'main', d: `M${tx} ${u.b} L${tx} ${sea.t}`, y0: u.b, y1: sea.t });
    for (const c of COLS) {
      branch(c.id, tx, box[c.id]);
      for (const it of c.items) branch(`${c.id}:${it.id}`, tx, box[`${c.id}:${it.id}`]);
    }
  } else {
    COLS.forEach((c, ci) => {
      const h = box[c.id];
      const tx = h.l + 16;
      const last = box[`${c.id}:${c.items.at(-1).id}`];
      const sx = sea.l + (sea.r - sea.l) * ((ci + 0.5) / COLS.length);
      const my = (u.b + h.t) / 2;
      // The river splits: council → each channel's head.
      out.push({
        k: `split-${c.id}`,
        kind: 'main',
        d: `M${u.cx} ${u.b} C${u.cx} ${my} ${tx} ${my} ${tx} ${h.t}`,
        y0: u.b,
        y1: h.t,
      });
      // The channel runs down past its teams and out to the sea.
      const cb = last.b + 18;
      const sy = (cb + sea.t) / 2;
      out.push({
        k: `run-${c.id}`,
        kind: 'main',
        d: `M${tx} ${h.b} L${tx} ${cb} C${tx} ${sy} ${sx} ${sy} ${sx} ${sea.t}`,
        y0: h.b,
        y1: sea.t,
      });
      for (const it of c.items) branch(`${c.id}:${it.id}`, tx, box[`${c.id}:${it.id}`]);
    });
  }
  edges.value = out;
}

// ---- The water follows the reader ------------------------------------------------------
const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
const front = ref(reduced ? Infinity : -1);
const clamp = (v) => Math.min(1, Math.max(0, v));
const lit = (e) => clamp((front.value - e.y0) / Math.max(50, e.y1 - e.y0));
const seen = (k) => front.value > (tops.value[k] ?? Infinity) + 6;

function onScroll() {
  if (reduced || !root.value) return;
  const f = innerHeight * 0.74 - root.value.getBoundingClientRect().top;
  // The water never recedes past what's been read; it only moves forward.
  if (f > front.value) front.value = f;
}

let ro;
let raf = 0;
const soon = () => {
  cancelAnimationFrame(raf);
  raf = requestAnimationFrame(() => {
    measure();
    onScroll();
  });
};
onMounted(() => {
  ro = new ResizeObserver(soon);
  ro.observe(root.value);
  document.fonts?.ready.then(soon);
  addEventListener('scroll', onScroll, { passive: true });
  soon();
});
onBeforeUnmount(() => {
  ro?.disconnect();
  cancelAnimationFrame(raf);
  removeEventListener('scroll', onScroll);
});
</script>

<style scoped>
.flow {
  position: relative;
  display: grid;
  gap: 34px;
  padding: 6px 0 0;
}
.rivers {
  position: absolute;
  inset: 0;
  overflow: visible;
  pointer-events: none;
}
.ch {
  fill: none;
  stroke: var(--flow);
  stroke-width: 3;
  stroke-linecap: round;
  stroke-dasharray: 1;
  stroke-dashoffset: calc(1 - var(--l));
  opacity: 0.55;
}
.ch.br {
  stroke-width: 2;
  opacity: 0.4;
}
/* Once a channel is full, light moves down it: tiny round dashes sliding along the path. */
.motes {
  fill: none;
  stroke: #ffd488;
  stroke-width: 3.2;
  stroke-linecap: round;
  stroke-dasharray: 0.1 26;
  opacity: 0;
  transition: opacity 0.8s;
  animation: flow 2.2s linear infinite;
}
.motes.on {
  opacity: 0.95;
}
:root[data-theme='dark'] .motes {
  stroke: #ffe2a8;
}
@keyframes flow {
  to {
    stroke-dashoffset: -26.1;
  }
}

.node {
  position: relative;
  z-index: 1;
  border: 1px solid var(--line);
  background: var(--card);
  color: inherit;
  text-align: left;
  /* Reveal without moving: the channels are measured off these boxes. */
  opacity: 0;
  filter: blur(6px);
  transition:
    opacity 0.5s var(--ease-out),
    filter 0.6s var(--ease-out),
    border-color 0.2s,
    box-shadow 0.2s;
}
.node.in {
  opacity: 1;
  filter: none;
}
button.node:hover {
  border-color: var(--line-strong);
  box-shadow: var(--shadow);
}
.tx {
  display: grid;
  gap: 1px;
  min-width: 0;
}
.tx strong {
  font-size: 15px;
  font-weight: 700;
  letter-spacing: -0.01em;
}
.tx small {
  font-size: 12.5px;
  color: var(--ink-2);
}

.uhc {
  justify-self: center;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 18px 10px 10px;
  border-radius: 99px;
  box-shadow: var(--shadow);
}
.uhc .tx strong {
  font-size: 17px;
}
.faces {
  display: flex;
}
.faces img {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  border: 2px solid var(--card);
  object-fit: cover;
  background: var(--sunk);
}
.faces img + img {
  margin-left: -10px;
}

.cols {
  display: grid;
  grid-template-columns: minmax(0, 1.25fr) minmax(0, 1fr) minmax(0, 1fr);
  gap: 22px;
  align-items: start;
}
.col {
  display: grid;
  gap: 10px;
}
.head {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 1px 10px;
  padding: 11px 14px;
  border-radius: 14px;
}
.head strong {
  font-size: 16px;
  font-weight: 700;
}
.head small {
  grid-column: 1;
  font-size: 12.5px;
  color: var(--ink-2);
}
.head b {
  grid-row: 1 / 3;
  grid-column: 2;
  align-self: center;
  font-size: 22px;
  font-weight: 600;
  color: var(--mari-ink);
}
.items {
  display: grid;
  gap: 6px;
  margin: 0;
  padding: 0 0 0 34px;
  list-style: none;
}
.lhc .items {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}
.item {
  display: flex;
  align-items: center;
  gap: 9px;
  width: 100%;
  padding: 6px 10px 6px 6px;
  border-radius: 12px;
}
.item.open {
  border-style: dashed;
  background: var(--paper);
}
.mark {
  display: flex;
  flex: none;
  align-items: center;
  justify-content: center;
  min-width: 24px;
  height: 24px;
  border-radius: 50%;
}
.mark:empty {
  width: 12px;
  min-width: 12px;
  height: 12px;
  margin: 0 6px;
  background: var(--c, var(--w-meetups));
}
.open .mark:empty {
  background: none;
  border: 1.5px dashed var(--line-strong);
  width: 20px;
  height: 20px;
  margin: 0 2px;
}
.mark img {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  border: 1.5px solid var(--card);
  object-fit: cover;
  background: var(--sunk);
}
.mark img + img {
  margin-left: -9px;
}
.item .tx strong {
  font-size: 14px;
  font-weight: 650;
}
.item .tx small {
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
  font-size: 12px;
}

/* The sea: every channel ends here. */
.sea {
  position: relative;
  display: grid;
  padding: 26px 20px 16px;
  overflow: hidden;
  border: 0;
  border-radius: 20px;
  background: var(--mari-soft);
  text-align: center;
}
.sea .tx strong {
  font-size: 20px;
  font-weight: 750;
}
.sea .tx small {
  font-size: 14px;
}
.waves {
  position: absolute;
  inset: 0 0 auto;
  width: 200%;
  height: 22px;
  animation: tide 9s linear infinite;
}
.waves path {
  fill: var(--paper);
  opacity: 0.55;
}
.waves path + path {
  opacity: 1;
}
@keyframes tide {
  to {
    transform: translateX(-50%);
  }
}
.waves {
  transform-origin: center;
  scale: 1 -1;
}

/* Phones: a single trunk on the left; heads and teams hang off it. */
.narrow .uhc {
  justify-self: stretch;
  border-radius: 18px;
}
.narrow .cols {
  grid-template-columns: minmax(0, 1fr);
  gap: 20px;
}
.narrow .head {
  margin-left: 34px;
}
.narrow .items {
  padding-left: 52px;
}
.narrow .lhc .items {
  grid-template-columns: minmax(0, 1fr);
}

@media (prefers-reduced-motion: reduce) {
  .node {
    transition: none;
  }
  .motes,
  .waves {
    animation: none;
  }
}
</style>
