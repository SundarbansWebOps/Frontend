<!--
  A mangrove at sunrise, grown procedurally (seeded, so it's the same tree every
  visit). Prop roots arch into the water first, then the trunk, then branches, then the
  canopy. `p` (0–1) is how far it has grown; the parent ties it to scroll. Pure SVG, no image.
-->
<template>
  <svg
    class="mangrove"
    viewBox="0 36 400 434"
    role="img"
    aria-label="A mangrove tree at sunrise, its roots arching into the water"
    :style="{ '--p': p }"
  >
    <defs>
      <clipPath id="mg-sky"><rect x="0" y="0" width="400" :height="WATER" /></clipPath>
      <clipPath id="mg-water"><rect x="0" :y="WATER" width="400" :height="470 - WATER" /></clipPath>
      <linearGradient id="mg-fade" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#fff" stop-opacity="0.5" />
        <stop offset="1" stop-color="#fff" stop-opacity="0" />
      </linearGradient>
      <!-- Thin dark gaps break the reflection into ripples. -->
      <pattern id="mg-gaps" width="400" height="6" patternUnits="userSpaceOnUse">
        <rect y="3.6" width="400" height="2.4" fill="#000" />
      </pattern>
      <mask id="mg-refl" maskContentUnits="userSpaceOnUse">
        <rect x="0" :y="WATER" width="400" :height="470 - WATER" fill="url(#mg-fade)" />
        <rect x="0" :y="WATER" width="400" :height="470 - WATER" fill="url(#mg-gaps)" />
      </mask>
    </defs>

    <g clip-path="url(#mg-sky)">
      <circle class="sun" cx="262" :cy="WATER - 18" r="62" />
      <path
        v-for="(b, i) in roots"
        :key="`r${i}`"
        class="stroke"
        :d="b.d"
        pathLength="1"
        :style="{ strokeWidth: b.w, '--t0': b.t0, '--dur': b.dur }"
      />
      <g class="tree">
        <path
          v-for="(b, i) in tree"
          :key="i"
          class="stroke"
          :d="b.d"
          pathLength="1"
          :style="{ strokeWidth: b.w, '--t0': b.t0, '--dur': b.dur }"
        />
        <circle
          v-for="(l, i) in leaves"
          :key="`l${i}`"
          class="leaf"
          :cx="l.x"
          :cy="l.y"
          :r="l.r"
          :style="{ fill: l.c, '--t0': l.t0, opacity: l.o }"
        />
      </g>
    </g>

    <line class="waterline" x1="0" :y1="WATER" x2="400" :y2="WATER" />
    <g clip-path="url(#mg-water)">
      <g class="sun-refl">
        <rect
          v-for="(s, i) in sunStripes"
          :key="i"
          :x="262 - s.w / 2"
          :y="s.y"
          :width="s.w"
          height="2.6"
          rx="1.3"
          :style="{ '--i': i }"
        />
      </g>
      <g mask="url(#mg-refl)">
        <g class="reflect" :transform="`translate(0 ${2 * WATER}) scale(1 -1)`">
          <path
            v-for="(b, i) in all"
            :key="i"
            class="stroke"
            :d="b.d"
            pathLength="1"
            :style="{ strokeWidth: b.w, '--t0': b.t0, '--dur': b.dur }"
          />
        </g>
      </g>
      <path
        v-for="(s, i) in spikes"
        :key="`s${i}`"
        class="spike"
        :d="s"
        :style="{ '--t0': 0.02 + i * 0.012 }"
      />
    </g>
  </svg>
</template>

<script setup>
defineProps({ p: { type: Number, default: 1 } });

const WATER = 352;

// mulberry32 — a tiny seeded RNG so the tree never changes between visits.
function rng(seed) {
  return () => {
    seed |= 0;
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const r = rng(27092026);
const rand = (a, b) => a + r() * (b - a);
const f = (n) => Math.round(n * 10) / 10;

const roots = [];
const tree = [];
const leaves = [];
const LEAF = ['var(--mari)', 'var(--flow)', 'var(--verm)', 'var(--mari)', 'var(--mari-ink)'];

// Prop roots: arches from the lower trunk out and down into the water. They grow first.
const TX = 196;
const BASE = WATER - 46;
for (let i = 0; i < 11; i++) {
  const dir = i % 2 ? 1 : -1;
  const sy = BASE - rand(0, 62);
  const sx = TX + dir * rand(0, 5);
  const ex = TX + dir * rand(26, 150);
  const ey = WATER + rand(3, 16);
  roots.push({
    d: `M${f(sx)} ${f(sy)} C${f(sx + dir * rand(18, 40))} ${f(sy - rand(12, 34))} ${f(ex - dir * rand(4, 16))} ${f(ey - rand(70, 120))} ${f(ex)} ${f(ey)}`,
    w: f(rand(2.2, 4)),
    t0: f(i * 0.022),
    dur: 0.22,
  });
}

// Trunk and branches: recursive, thinning and shortening with depth.
function branch(x, y, ang, len, depth, t0) {
  const ex = x + Math.cos(ang) * len;
  const ey = y + Math.sin(ang) * len;
  const bend = rand(-0.25, 0.25);
  const cx = x + Math.cos(ang + bend) * len * 0.55;
  const cy = y + Math.sin(ang + bend) * len * 0.55;
  // Keep the prop-root junction raised, but carry the trunk down to the mud line.
  const start =
    depth === 0 ? `M${TX} ${WATER} Q${TX - 3} ${WATER - 23} ${f(x)} ${f(y)}` : `M${f(x)} ${f(y)}`;
  tree.push({
    d: `${start} Q${f(cx)} ${f(cy)} ${f(ex)} ${f(ey)}`,
    w: f(Math.max(1, 10 * Math.pow(0.62, depth))),
    t0: f(t0),
    dur: 0.14,
  });
  if (depth >= 3) {
    const n = depth >= 5 ? 7 : 4;
    for (let i = 0; i < n; i++) {
      const a = rand(0, Math.PI * 2);
      const d = rand(2, depth >= 5 ? 17 : 11);
      leaves.push({
        x: f(ex + Math.cos(a) * d),
        y: f(ey + Math.sin(a) * d * 0.8),
        r: f(rand(2, 4.6)),
        c: LEAF[Math.floor(r() * LEAF.length)],
        o: f(rand(0.7, 0.95)),
        t0: f(Math.min(0.94, t0 + 0.1 + rand(0, 0.12))),
      });
    }
  }
  if (depth === 5) return;
  // Mangrove crowns are low and wide: early forks splay hard, and no limb climbs past
  // ~65° from vertical, so the canopy spreads instead of towering.
  const kids = depth < 2 ? 3 : 2;
  for (let k = 0; k < kids; k++) {
    const spread = (k - (kids - 1) / 2) * (depth < 2 ? rand(0.7, 0.95) : rand(0.4, 0.6));
    const a = Math.max(-Math.PI / 2 - 1.15, Math.min(-Math.PI / 2 + 1.15, ang + spread));
    branch(ex, ey, a + rand(-0.1, 0.1), len * rand(0.7, 0.84), depth + 1, t0 + 0.09);
  }
}
branch(TX, BASE, -Math.PI / 2 + 0.04, 66, 0, 0.2);

const all = [...roots, ...tree];

// Pneumatophores: the breathing roots that poke up through the mud.
const spikes = Array.from({ length: 26 }, () => {
  const x = rand(18, 382);
  return `M${f(x)} ${WATER + 1} l${f(rand(-1, 1))} ${f(-rand(4, 12))}`;
});
// The sun's broken reflection, narrowing with depth.
const sunStripes = Array.from({ length: 12 }, (_, i) => ({
  y: WATER + 6 + i * 9,
  w: f(118 - i * 8.5 + rand(-8, 8)),
}));
</script>

<style scoped>
.mangrove {
  display: block;
  width: 100%;
  height: auto;
  overflow: visible;
}
.sun {
  fill: var(--mari);
  opacity: 0.9;
  transform: translateY(calc((1 - var(--p)) * 70px));
}
.stroke {
  fill: none;
  stroke: var(--ink);
  stroke-linecap: round;
  stroke-dasharray: 1;
  stroke-dashoffset: calc(1 - clamp(0, (var(--p) - var(--t0)) / var(--dur), 1));
}
.leaf {
  transform-box: fill-box;
  transform-origin: center;
  transform: scale(clamp(0, (var(--p) - var(--t0)) * 9, 1));
}
.tree {
  transform-origin: 196px 352px;
  animation: sway 7s ease-in-out infinite alternate;
}
@keyframes sway {
  from {
    transform: rotate(-0.7deg);
  }
  to {
    transform: rotate(0.7deg);
  }
}
.waterline {
  stroke: var(--line-strong);
  stroke-width: 1;
}
.reflect {
  opacity: 0.22;
}
.sun-refl rect {
  fill: var(--mari);
  opacity: calc(0.75 * var(--p));
  animation: shimmer 3.2s ease-in-out infinite alternate;
  animation-delay: calc(var(--i) * -0.37s);
  transform-box: fill-box;
  transform-origin: center;
}
@keyframes shimmer {
  from {
    transform: translateX(-5px) scaleX(0.9);
  }
  to {
    transform: translateX(5px) scaleX(1.06);
  }
}
.spike {
  stroke: var(--ink);
  stroke-width: 1.6;
  stroke-linecap: round;
  opacity: clamp(0, (var(--p) - var(--t0)) * 6, 0.7);
}

@media (prefers-reduced-motion: reduce) {
  .tree,
  .sun-refl rect {
    animation: none;
  }
}
</style>
