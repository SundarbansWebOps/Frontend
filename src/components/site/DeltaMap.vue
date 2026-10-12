<!--
  The programme drawn as a river delta. Foundation is the trunk, it splits into
  the Programming and Data Science diploma channels, and both reach the degree coast.
  Pure SVG + CSS: the whole motion system costs no network bytes.
-->
<template>
  <div ref="wrap" class="delta" :class="[orient, { searching: !!match, drawn }]">
    <svg
      v-if="width"
      :width="width"
      :height="height"
      :viewBox="`0 0 ${width} ${height}`"
      role="group"
      :aria-label="ariaLabel"
    >
      <!-- sea: layered swells beyond the coast -->
      <g class="sea" v-if="!isSnake">
        <path v-for="(w, i) in waves" :key="'w' + i" :d="w" :style="{ '--i': i }" />
      </g>

      <!-- creeks: thin distributaries that make it read as a delta -->
      <template v-if="!isSnake">
        <path
          v-for="c in creeks"
          :key="c.id"
          class="creek draw"
          :class="{ dim: dimSeg(c.seg) }"
          :d="c.d"
          pathLength="1"
          :style="{ '--delay': c.delay + 'ms', '--dur': '700ms' }"
        />
      </template>

      <!-- main channels -->
      <template v-if="!isSnake">
        <path
          v-for="s in segs"
          :key="s.id"
          :ref="(el) => (segEls[s.id] = el)"
          class="channel draw"
          :class="[s.id, { dim: dimSeg(s.id) }]"
          :d="s.d"
          pathLength="1"
          :style="{ '--delay': s.start + 'ms', '--dur': s.dur + 'ms' }"
        />
        <!-- current: dashes that keep drifting downstream once drawn -->
        <path v-for="s in segs" :key="'f' + s.id" class="flow" :d="s.d" />

        <!-- hover trail: lights the route from the qualifier to the hovered course -->
        <path
          v-for="s in segs"
          :key="'h' + s.id"
          class="trail"
          :d="s.d"
          pathLength="1"
          :style="{ strokeDasharray: `${trail[s.id] ?? 0} 2`, opacity: trail[s.id] ? 1 : 0 }"
        />
      </template>
      <!-- snake channel split into level sections (single-diploma branches) -->
      <template v-if="isSnake">
        <template v-for="g in snakeGroups" :key="g.id">
          <path
            :ref="(el) => (segEls['snake-' + g.id] = el)"
            class="channel draw"
            :d="g.d"
            pathLength="1"
            :style="{ '--delay': '150ms', '--dur': '1200ms' }"
          />
          <path class="flow" :d="g.d" />
          <path
            class="trail"
            :d="g.d"
            pathLength="1"
            :style="{
              strokeDasharray: `${trail['snake-' + g.id] ?? 0} 2`,
              opacity: trail['snake-' + g.id] ? 1 : 0,
            }"
          />
        </template>
        <text
          v-for="g in snakeGroups"
          :key="'g' + g.id"
          class="section region"
          :x="g.lx"
          :y="g.ly"
          text-anchor="start"
        >
          {{ g.label }}
        </text>
      </template>

      <!-- section names ride the channels -->
      <template v-if="orient === 'h'">
        <text
          v-for="s in segLabels"
          :key="'t' + s.id"
          class="section"
          :class="{ dim: dimSeg(s.id) }"
          :dy="s.dy"
        >
          <textPath :href="`#seg-${s.id}-${uid}`" :startOffset="s.offset">{{ s.text }}</textPath>
        </text>
        <path v-for="s in segs" :key="'p' + s.id" :id="`seg-${s.id}-${uid}`" :d="s.d" fill="none" />
        <text
          v-if="regionLabel"
          class="section region"
          :x="regionLabel.x"
          :y="regionLabel.y"
          text-anchor="middle"
        >
          FOUNDATION
        </text>
      </template>
      <template v-else>
        <text
          v-for="s in vLabels"
          :key="'v' + s.text"
          class="section"
          :x="s.x"
          :y="s.y"
          :text-anchor="s.anchor"
        >
          {{ s.text }}
        </text>
      </template>

      <!-- source -->
      <g v-if="source && !isSnake" class="source" :transform="`translate(${source.x} ${source.y})`">
        <circle r="9" class="ring" />
        <circle r="3.5" />
        <text :x="orient === 'h' ? -16 : 16" :y="4" :text-anchor="orient === 'h' ? 'end' : 'start'">
          Qualifier
        </text>
      </g>

      <text
        v-if="seaLabel"
        class="sea-label"
        :x="seaLabel.x"
        :y="seaLabel.y"
        :text-anchor="seaLabel.anchor"
      >
        {{ seaLabel.text }}
      </text>

      <!-- course nodes -->
      <g
        v-for="n in nodes"
        :key="n.code"
        class="node"
        :class="{
          mine: mine.includes(n.code),
          hit: match && match.has(n.code),
          miss: match && !match.has(n.code),
          hover: hovered === n.code,
        }"
        :transform="`translate(${n.x} ${n.y})`"
        :style="{ '--delay': n.delay + 'ms' }"
        role="button"
        tabindex="0"
        :aria-label="`${n.course.short}, ${n.course.name}. ${n.course.pyqs.length} past papers, ${n.course.notes.length} notes`"
        @click="$emit('open', n.code, $event)"
        @keydown.enter.prevent="$emit('open', n.code, $event)"
        @keydown.space.prevent="$emit('open', n.code, $event)"
        @pointerenter="hover(n)"
        @pointerleave="hover(null)"
        @focus="hover(n)"
        @blur="hover(null)"
      >
        <g class="pop">
          <circle class="hitbox" r="20" />
          <circle class="halo" r="13" />
          <circle class="dot" r="6.5" />
          <g :transform="`translate(${n.lx} ${n.ly})`" class="label">
            <text :text-anchor="n.anchor" :y="n.ty1" class="name">{{ n.name }}</text>
            <text :text-anchor="n.anchor" :y="n.ty2" class="code">{{ n.code }}</text>
          </g>
        </g>
      </g>
    </svg>

    <!-- hover card: full course name + counts, desktop only -->
    <Transition name="tip">
      <div
        v-if="tip && orient === 'h'"
        :key="tip.code"
        class="tip"
        :style="{ left: tip.x + 'px', top: tip.y + 'px' }"
        :class="tip.below ? 'below' : 'above'"
      >
        <strong>{{ tip.course.name }}</strong>
        <span
          ><b>{{ tip.course.pyqs.length }}</b> past papers ·
          <b>{{ tip.course.notes.length }}</b> notes</span
        >
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref, nextTick, watch } from 'vue';
import { courses } from '../../lib/courses.js';
import { BRANCHES } from '../../data/branches.js';

const props = defineProps({
  mine: { type: Array, default: () => [] },
  match: { type: Object, default: null }, // Set of codes or null
  tall: { type: Boolean, default: false },
  branch: { type: String, default: 'all' }, // 'all' | 'programming' | 'datascience'
});

const dimSeg = (id) => {
  if (id !== 'programming' && id !== 'datascience') return false;
  const b = props.branch && BRANCHES[props.branch];
  if (!b) return false;
  return id === 'programming' ? !b.channels[0] : !b.channels[1];
};
defineEmits(['open']);

const uid = Math.random().toString(36).slice(2, 7);
const wrap = ref(null);
const width = ref(0);
const drawn = ref(false);
let ro;
onMounted(() => {
  ro = new ResizeObserver(([e]) => (width.value = Math.round(e.contentRect.width)));
  ro.observe(wrap.value);
  setTimeout(() => (drawn.value = true), 2600);
});
onBeforeUnmount(() => ro?.disconnect());

const orient = computed(() => (width.value >= 720 ? 'h' : 'v'));
const isSnake = computed(() => {
  const b = props.branch && BRANCHES[props.branch];
  return !!b;
});
const ariaLabel = computed(() =>
  isSnake.value
    ? `Course map for ${BRANCHES[props.branch].label}, foundation to diploma to degree`
    : 'Course map: Foundation, then Diploma in Programming or Data Science, then BS Degree'
);
const snakeShape = computed(() => {
  if (!isSnake.value) return null;
  const b = BRANCHES[props.branch];
  const cols = orient.value === 'h' ? 8 : 4;
  const groups = [b.foundation, b.channels.flatMap((ch) => ch.courses), b.degree];
  const rowsPer = groups.map((l) => Math.max(1, Math.ceil(l.length / cols)));
  return { cols, total: rowsPer.reduce((a, r) => a + r, 0), rowsPer };
});
const height = computed(() =>
  isSnake.value && snakeShape.value
    ? snakeShape.value.total * 90 + 2 * 74 + 130
    : orient.value === 'h'
      ? Math.round(Math.min(500, Math.max(400, width.value * 0.36)) * (props.tall ? 1.1 : 1))
      : 1080
);

// Abstract space: u = downstream 0..1, v = across -1..1.
function P([u, v]) {
  const W = width.value;
  const H = height.value;
  if (orient.value === 'h') {
    const padL = 120;
    const padR = 110;
    const padY = 56;
    return [padL + u * (W - padL - padR), H / 2 + v * (H / 2 - padY)];
  }
  const padX = 22;
  const padTop = 60;
  const padBottom = 150;
  return [W / 2 + v * (W / 2 - padX) * 0.92, padTop + u * (H - padTop - padBottom)];
}

// Catmull-Rom through the points, emitted as cubic Béziers.
function smooth(pts) {
  const p = pts.map(P);
  let d = `M${p[0][0].toFixed(1)} ${p[0][1].toFixed(1)}`;
  for (let i = 0; i < p.length - 1; i++) {
    const p0 = p[i - 1] ?? p[i];
    const p1 = p[i];
    const p2 = p[i + 1];
    const p3 = p[i + 2] ?? p2;
    const c1 = [p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6];
    const c2 = [p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6];
    d += ` C${c1.map((n) => n.toFixed(1)).join(' ')} ${c2.map((n) => n.toFixed(1)).join(' ')} ${p2.map((n) => n.toFixed(1)).join(' ')}`;
  }
  return d;
}

const GEOM = {
  trunk: [
    [0, 0],
    [0.09, 0.07],
    [0.19, -0.06],
    [0.29, 0.06],
    [0.38, -0.03],
    [0.44, 0],
  ],
  programming: [
    [0.44, 0],
    [0.5, -0.2],
    [0.57, -0.5],
    [0.66, -0.64],
    [0.76, -0.62],
    [0.86, -0.48],
    [0.91, -0.34],
  ],
  datascience: [
    [0.44, 0],
    [0.5, 0.2],
    [0.57, 0.5],
    [0.66, 0.64],
    [0.76, 0.62],
    [0.86, 0.48],
    [0.91, 0.34],
  ],
  coast: [
    [0.935, -0.86],
    [0.955, -0.4],
    [0.945, 0.05],
    [0.955, 0.45],
    [0.935, 0.86],
  ],
};
const TIMING = {
  trunk: { start: 150, dur: 1000 },
  programming: { start: 1000, dur: 1100 },
  datascience: { start: 1080, dur: 1100 },
  coast: { start: 1900, dur: 700 },
};
const TRACK_SEG = {
  foundation: 'trunk',
  programming: 'programming',
  datascience: 'datascience',
  degree: 'coast',
};

const segs = computed(() =>
  width.value
    ? Object.entries(GEOM).map(([id, pts]) => ({ id, d: smooth(pts), ...TIMING[id] }))
    : []
);

const segLabels = computed(() => {
  if (isSnake.value) return [];
  const b = props.branch && BRANCHES[props.branch];
  if (!b)
    return [
      { id: 'programming', text: 'DIPLOMA · PROGRAMMING', offset: '34%', dy: 22 },
      { id: 'datascience', text: 'DIPLOMA · DATA SCIENCE', offset: '34%', dy: -12 },
    ];
  const out = [];
  if (b.channels[0])
    out.push({ id: 'programming', text: b.channels[0].label, offset: '34%', dy: 22 });
  if (b.channels[1])
    out.push({ id: 'datascience', text: b.channels[1].label, offset: '34%', dy: -12 });
  return out;
});

const regionLabel = computed(() => {
  if (!width.value || orient.value !== 'h' || isSnake.value) return null;
  const [x, y] = P([0.2, -0.62]);
  return { x, y };
});

const vLabels = computed(() => {
  if (!width.value || isSnake.value) return [];
  const [xS, yS] = P([0, 0]);
  const [xF, yF] = P([0.06, 0]);
  const [xM, yM] = P([0.64, 0]);
  return [
    { text: 'FOUNDATION', x: xF - 18, y: yF + 4, anchor: 'end' },
    { text: 'DIPLOMA', x: xM, y: yM - 8, anchor: 'middle' },
    { text: '← PROG · DS →', x: xM, y: yM + 8, anchor: 'middle' },
    { text: '', x: xS, y: yS, anchor: 'start' },
  ].filter((l) => l.text);
});

const source = computed(() => {
  if (!width.value) return null;
  const [x, y] = P([0, 0]);
  return { x, y };
});

const seaLabel = computed(() => {
  if (!width.value || isSnake.value) return null;
  if (orient.value === 'h') {
    const [x, y] = P([1.0, -0.9]);
    return { x: x + 30, y: y - 6, text: 'BS DEGREE', anchor: 'end' };
  }
  const [, y] = P([0.99, 0]);
  return { x: width.value / 2, y: y + 92, text: 'BS DEGREE', anchor: 'middle' };
});

const waves = computed(() => {
  if (!width.value) return [];
  const out = [];
  for (let k = 0; k < 4; k++) {
    const u = 0.985 + k * 0.03;
    const pts = [];
    for (let i = 0; i <= 8; i++) {
      const v = -1 + i / 4;
      pts.push([u + (i % 2 ? 0.006 : -0.006) * (orient.value === 'h' ? 1 : 3), v]);
    }
    out.push(smooth(pts));
  }
  return out;
});

// Deterministic creeks peel off the channels at fixed points.
const CREEK_AT = [
  ['trunk', 0.3, -1],
  ['trunk', 0.62, 1],
  ['trunk', 0.85, -1],
  ['programming', 0.25, -1],
  ['programming', 0.55, -1],
  ['programming', 0.82, 1],
  ['datascience', 0.3, 1],
  ['datascience', 0.6, 1],
  ['datascience', 0.84, -1],
];

const segEls = reactive({});
const nodes = ref([]);
const creeks = ref([]);

function shortName(s) {
  return s.length > 26 ? s.slice(0, 25).trimEnd() + '…' : s;
}

function smoothAbs(pts) {
  let d = `M${pts[0][0].toFixed(1)} ${pts[0][1].toFixed(1)}`;
  for (let i = 0; i < pts.length - 1; i++) {
    const p0 = pts[i - 1] ?? pts[i];
    const p1 = pts[i];
    const p2 = pts[i + 1];
    const p3 = pts[i + 2] ?? p2;
    const c1 = [p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6];
    const c2 = [p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6];
    d += ` C${c1.map((n) => n.toFixed(1)).join(' ')} ${c2.map((n) => n.toFixed(1)).join(' ')} ${p2.map((n) => n.toFixed(1)).join(' ')}`;
  }
  return d;
}

const snakeGroups = computed(() => {
  if (!width.value || !isSnake.value) return [];
  const b = BRANCHES[props.branch];
  const groups = [
    { id: 'foundation', label: 'FOUNDATION LEVEL', list: b.foundation },
    {
      id: 'diploma',
      label: 'DIPLOMA LEVEL',
      list: b.channels.flatMap((ch) => ch.courses),
    },
    { id: 'degree', label: 'DEGREE LEVEL', list: b.degree },
  ];
  const W = width.value;
  const cols = snakeShape.value.cols;
  const padX = orient.value === 'h' ? 90 : 60;
  const padR = orient.value === 'h' ? 60 : 40;
  const top = 100;
  const gap = 74;
  const rowH = 90;
  const rowsPer = snakeShape.value.rowsPer;
  let y = top;
  let parity = 0;
  return groups.map((g, gi) => {
    const rows = rowsPer[gi];
    const pts = [];
    for (let r = 0; r < rows; r++) {
      const yy = y + r * rowH;
      const L = padX;
      const R = W - padR;
      const row =
        parity % 2 === 0
          ? [
              [L, yy],
              [(L + R) / 2, yy],
              [R, yy],
            ]
          : [
              [R, yy],
              [(L + R) / 2, yy],
              [L, yy],
            ];
      pts.push(...row);
      parity++;
    }
    const out = { ...g, d: smoothAbs(pts), lx: padX, ly: y - 20 };
    y += rows * rowH + gap;
    return out;
  });
});

function measureSnake() {
  const out = [];
  snakeGroups.value.forEach((g) => {
    const el = segEls['snake-' + g.id];
    if (!el) return;
    const len = el.getTotalLength();
    g.list.forEach((course, i) => {
      const t = (i + 0.5) / g.list.length;
      const pt = el.getPointAtLength(t * len);
      const a = el.getPointAtLength(Math.max(0, t * len - 4));
      const z = el.getPointAtLength(Math.min(len, t * len + 4));
      let nx = -(z.y - a.y);
      let ny = z.x - a.x;
      const m = Math.hypot(nx, ny) || 1;
      nx /= m;
      ny /= m;
      const side = i % 2 ? 1 : -1;
      const off = 16;
      const dx = nx * side;
      const dy = ny * side;
      let anchor = 'middle';
      let ty1 = dy < 0 ? -14 : 13;
      let ty2 = dy < 0 ? -1 : 26;
      if (Math.abs(dx) > Math.abs(dy)) {
        anchor = dx > 0 ? 'start' : 'end';
        ty1 = -1;
        ty2 = 12;
      }
      out.push({
        code: course.code,
        course,
        name: shortName(course.name),
        x: pt.x,
        y: pt.y,
        lx: dx * off,
        ly: dy * off,
        anchor,
        ty1,
        ty2,
        seg: 'snake',
        group: g.id,
        t,
        delay: Math.round(150 + t * 1200),
      });
    });
  });
  nodes.value = out;
  creeks.value = [];
}

function measure() {
  if (isSnake.value) {
    measureSnake();
    return;
  }
  const out = [];
  const b = props.branch && BRANCHES[props.branch];
  const tracks = { foundation: [], programming: [], datascience: [], degree: [] };
  if (b) {
    tracks.foundation = b.foundation;
    tracks.programming = b.channels[0]?.courses ?? [];
    tracks.datascience = b.channels[1]?.courses ?? [];
    tracks.degree = b.degree;
  } else {
    for (const c of courses) tracks[c.track].push(c);
  }

  for (const [track, list] of Object.entries(tracks)) {
    const segId = TRACK_SEG[track];
    const el = segEls[segId];
    if (!el) return;
    const len = el.getTotalLength();
    const { start, dur } = TIMING[segId];
    const [t0, t1] =
      track === 'foundation' ? [0.1, 0.96] : track === 'degree' ? [0.1, 0.9] : [0.12, 0.9];
    list.forEach((course, i) => {
      const t = list.length === 1 ? 0.5 : t0 + ((t1 - t0) * i) / (list.length - 1);
      const pt = el.getPointAtLength(t * len);
      const a = el.getPointAtLength(Math.max(0, t * len - 2));
      const b = el.getPointAtLength(Math.min(len, t * len + 2));
      let nx = -(b.y - a.y);
      let ny = b.x - a.x;
      const m = Math.hypot(nx, ny) || 1;
      nx /= m;
      ny /= m;
      // Which side the label sits on: trunk alternates, channels face outward,
      // the degree coast faces the sea.
      const h = orient.value === 'h';
      let side;
      if (track === 'foundation') side = i % 2 ? 1 : -1;
      else if (track === 'programming') side = (h ? ny : nx) < 0 ? 1 : -1;
      else if (track === 'datascience') side = (h ? ny : nx) > 0 ? 1 : -1;
      else side = (h ? nx : ny) > 0 ? 1 : -1;
      const dx = nx * side;
      const dy = ny * side;
      const off = 18;
      let anchor = 'middle';
      let ty1;
      let ty2;
      if (Math.abs(dx) > Math.abs(dy)) {
        anchor = dx > 0 ? 'start' : 'end';
        ty1 = -1;
        ty2 = 12;
      } else if (dy < 0) {
        ty1 = -14;
        ty2 = -1;
      } else {
        ty1 = 13;
        ty2 = 26;
      }
      out.push({
        code: course.code,
        course,
        name: shortName(course.name),
        x: pt.x,
        y: pt.y,
        lx: dx * off,
        ly: dy * off,
        anchor,
        ty1,
        ty2,
        seg: segId,
        t,
        delay: Math.round(start + t * dur),
      });
    });
  }
  nodes.value = out;

  creeks.value = CREEK_AT.map(([segId, t, dir], i) => {
    const el = segEls[segId];
    const len = el.getTotalLength();
    const p = el.getPointAtLength(t * len);
    const a = el.getPointAtLength(t * len - 2);
    const b = el.getPointAtLength(t * len + 2);
    const tx = (b.x - a.x) / 4;
    const ty = (b.y - a.y) / 4;
    const nx = -ty * dir;
    const ny = tx * dir;
    const L = orient.value === 'h' ? 46 : 30;
    const e = [p.x + (tx * 0.9 + nx) * L, p.y + (ty * 0.9 + ny) * L];
    const c = [p.x + (tx * 0.2 + nx * 0.6) * L, p.y + (ty * 0.2 + ny * 0.6) * L];
    return {
      id: 'c' + i,
      seg: segId,
      d: `M${p.x.toFixed(1)} ${p.y.toFixed(1)} Q${c[0].toFixed(1)} ${c[1].toFixed(1)} ${e[0].toFixed(1)} ${e[1].toFixed(1)}`,
      delay: TIMING[segId].start + t * TIMING[segId].dur,
    };
  });
}

watch([width, orient], () => nextTick(measure), { flush: 'post' });
watch(
  () => props.branch,
  () => nextTick(measure),
  { flush: 'post' }
);

// Hover trail
const hovered = ref(null);
const trail = reactive({});
const tip = ref(null);
function hover(n) {
  for (const k of Object.keys(GEOM)) trail[k] = 0;
  trail['snake-foundation'] = 0;
  trail['snake-diploma'] = 0;
  trail['snake-degree'] = 0;
  hovered.value = n?.code ?? null;
  if (!n) {
    tip.value = null;
    return;
  }
  if (n.seg === 'snake') {
    const order = ['foundation', 'diploma', 'degree'];
    const gi = order.indexOf(n.group);
    order.forEach((g, i) => {
      trail['snake-' + g] = i < gi ? 1 : i === gi ? n.t : 0;
    });
  } else if (n.seg === 'trunk') trail.trunk = n.t;
  else if (n.seg === 'coast') {
    trail.trunk = 1;
    trail.programming = 1;
    trail.datascience = 1;
    trail.coast = n.t;
  } else {
    trail.trunk = 1;
    trail[n.seg] = n.t;
  }
  // Tip goes on the opposite side from the label so it never covers it.
  tip.value = { code: n.code, course: n.course, x: n.x, y: n.y, below: n.ly < 0 };
}
</script>

<style scoped>
.delta {
  position: relative;
  width: 100%;
  user-select: none;
  -webkit-tap-highlight-color: transparent;
}
svg {
  display: block;
  overflow: visible;
}

/* ---- channels ---- */
.channel {
  fill: none;
  stroke: var(--channel);
  stroke-width: 3.5;
  stroke-linecap: round;
}
.channel.trunk {
  stroke-width: 5;
}
.creek {
  fill: none;
  stroke: var(--channel);
  stroke-width: 1.4;
  stroke-linecap: round;
  opacity: 0.8;
}
.channel.dim,
.creek.dim,
.section.dim {
  opacity: 0.08;
  transition: opacity 0.4s;
}
.draw {
  stroke-dasharray: 1 1;
  stroke-dashoffset: 1;
  animation: draw var(--dur) var(--ease-out) var(--delay) forwards;
}
@keyframes draw {
  to {
    stroke-dashoffset: 0;
  }
}

.flow {
  fill: none;
  stroke: var(--flow);
  stroke-width: 1.6;
  stroke-linecap: round;
  stroke-dasharray: 1.5 15;
  opacity: 0;
  animation:
    flow-in 1.2s ease 2.4s forwards,
    flow 7s linear infinite;
}
@keyframes flow-in {
  to {
    opacity: 0.55;
  }
}
@keyframes flow {
  to {
    stroke-dashoffset: -165;
  }
}

.trail {
  fill: none;
  stroke: var(--acc, var(--mari));
  stroke-width: 5;
  stroke-linecap: round;
  transition:
    stroke-dasharray 0.55s var(--ease-out),
    opacity 0.2s;
  pointer-events: none;
}

/* ---- sea ---- */
.sea path {
  fill: none;
  stroke: var(--channel);
  stroke-width: 1.3;
  opacity: 0;
  animation:
    sea-in 1s ease forwards,
    swell 6s ease-in-out infinite alternate;
  animation-delay: calc(2200ms + var(--i) * 140ms), calc(var(--i) * -1.4s);
}
.h .sea path {
  --sx: 6px;
  --sy: 0px;
}
.v .sea path {
  --sx: 0px;
  --sy: 5px;
}
@keyframes sea-in {
  to {
    opacity: calc(0.9 - var(--i) * 0.18);
  }
}
@keyframes swell {
  from {
    transform: translate(calc(var(--sx) * -1), calc(var(--sy) * -1));
  }
  to {
    transform: translate(var(--sx), var(--sy));
  }
}

.section,
.sea-label {
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 0.18em;
  fill: var(--ink-3);
  opacity: 0;
  animation: fade 0.8s ease 1.9s forwards;
}
.region {
  font-size: 11px;
  letter-spacing: 0.3em;
  animation-delay: 1.2s;
}
.sea-label {
  font-size: 11px;
  fill: var(--acc, var(--mari-ink));
  animation-delay: 2.5s;
}
@keyframes fade {
  to {
    opacity: 1;
  }
}

.source circle {
  fill: var(--ink);
}
.source .ring {
  fill: none;
  stroke: var(--ink);
  stroke-width: 1.2;
  transform-origin: center;
  animation: ping 2.6s var(--ease-out) 0.2s infinite;
}
@keyframes ping {
  from {
    transform: scale(0.6);
    opacity: 1;
  }
  to {
    transform: scale(2.2);
    opacity: 0;
  }
}
.source text {
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 0.1em;
  fill: var(--ink-2);
  text-transform: uppercase;
}

/* ---- nodes ---- */
.node {
  cursor: pointer;
  outline: none;
}
.node .pop {
  transform: scale(0);
  /* scale from the dot (local origin), not the centre of dot + label */
  transform-box: view-box;
  transform-origin: 0 0;
  animation: pop 0.6s var(--ease-spring) var(--delay) forwards;
  transition: opacity 0.35s ease;
}
@keyframes pop {
  to {
    transform: scale(1);
  }
}
.hitbox {
  fill: transparent;
}
.dot {
  fill: var(--paper);
  stroke: var(--ink);
  stroke-width: 2;
  transition:
    r 0.35s var(--ease-spring),
    fill 0.25s,
    stroke 0.25s;
}
.halo {
  fill: var(--acc, var(--mari));
  opacity: 0;
  transform: scale(0.4);
  transform-box: fill-box;
  transform-origin: center;
  transition:
    opacity 0.3s,
    transform 0.45s var(--ease-spring);
}
.label text {
  paint-order: stroke;
  stroke: var(--paper);
  stroke-width: 5px;
  stroke-linejoin: round;
}
.name {
  font-size: 11.5px;
  font-weight: 650;
  fill: var(--ink);
  letter-spacing: -0.01em;
}
.code {
  font-family: var(--mono);
  font-size: 9.5px;
  fill: var(--ink-3);
}

.node:hover .dot,
.node.hover .dot,
.node:focus-visible .dot {
  r: 8.5;
  fill: var(--acc, var(--mari));
}
.node:focus-visible .halo,
.node.hover .halo {
  opacity: 0.25;
  transform: scale(1);
}

.node.mine .dot {
  fill: var(--acc, var(--mari));
  stroke: var(--ink);
  r: 8;
}
.node.mine .halo {
  opacity: 0.22;
  transform: scale(1);
  animation: breathe 3.2s ease-in-out infinite;
}
@keyframes breathe {
  50% {
    transform: scale(1.35);
    opacity: 0.08;
  }
}
.node.mine .code {
  fill: var(--acc, var(--mari-ink));
}

.searching .node.miss .pop {
  opacity: 0.16;
}
.searching .node.hit .dot {
  fill: var(--acc, var(--mari));
  r: 9;
}
.searching .node.hit .halo {
  opacity: 0.3;
  transform: scale(1.2);
}
.searching .channel,
.searching .creek {
  transition: opacity 0.3s;
  opacity: 0.55;
}

/* ---- tooltip ---- */
.tip {
  position: absolute;
  z-index: 3;
  pointer-events: none;
  display: grid;
  gap: 2px;
  min-width: 190px;
  max-width: 260px;
  padding: 10px 12px;
  border-radius: 10px;
  background: var(--ink);
  color: var(--paper);
  font-size: 13px;
  line-height: 1.3;
  box-shadow: var(--shadow);
  transform: translate(-50%, calc(-100% - 22px));
}
.tip.below {
  transform: translate(-50%, 22px);
}
.tip span {
  opacity: 0.75;
  font-size: 12px;
}
.tip b {
  font-weight: 700;
  opacity: 1;
}
.tip-enter-active,
.tip-leave-active {
  transition:
    opacity 0.18s,
    translate 0.25s var(--ease-out);
}
.tip-enter-from,
.tip-leave-to {
  opacity: 0;
  translate: 0 4px;
}

@media (prefers-reduced-motion: reduce) {
  .draw {
    stroke-dashoffset: 0;
  }
  .node .pop {
    transform: none;
  }
  .flow {
    opacity: 0.4;
  }
}
</style>
