<!--
  Contributors: lines changed since 1 July, from GitHub (see scripts/contributors-snapshot.mjs).
  The first screen is the dashboard: total, KPIs, the leaderboard and the weekly chart. Helpers sit
  below. Motion is one-shot: numbers count up, bars grow, columns rise from the zero line.
-->
<template>
  <main id="main-content" ref="page" class="page" :class="{ ready, settled }" tabindex="-1">
    <div class="first">
      <header class="head pop" style="--d: 0s">
        <h1>Contributors</h1>
        <p class="meta mono"><span class="live" aria-hidden="true"></span>{{ updated }}</p>
      </header>

      <section class="dash" :data-focus="focusKey || null" aria-label="Contribution analytics">
        <div class="hero">
          <div class="label pop" style="--d: 0s">Lines changed · {{ since }}</div>
          <strong class="total pop" style="--d: 0.05s">{{ fmt(shown('total', allLines)) }}</strong>
          <div class="split pop" style="--d: 0.15s">
            <span class="add">+{{ fmt(totals.a) }}<i>added</i></span>
            <span class="del">−{{ fmt(totals.d) }}<i>removed</i></span>
          </div>
          <div class="ratio" aria-hidden="true">
            <b class="a grow" :style="{ flex: totals.a, '--d': '0.4s' }"></b>
            <b class="d grow" :style="{ flex: totals.d, '--d': '0.55s' }"></b>
          </div>
        </div>

        <ul class="kpis">
          <li
            v-for="(k, i) in KPIS"
            :key="k.label"
            class="pop"
            :style="{ '--d': 0.25 + i * 0.08 + 's' }"
          >
            <span class="label">{{ k.label }}</span>
            <strong>{{ fmt(shown('kpi' + i, k.value)) }}</strong>
          </li>
        </ul>

        <section class="board" aria-labelledby="board-h">
          <div class="board-head">
            <span id="board-h" class="label pop" style="--d: 0.1s">Top contributors</span>
          </div>
          <ol ref="rowsEl" class="rows">
            <ContributorRow
              v-for="(p, i) in dashPeople"
              :key="p.login"
              :p="p"
              :rank="i"
              :top="i === 0"
              phase="dash"
              :ready="ready"
              :settled="settled"
              :delay="0.3 + i * 0.09"
              :value="shown('row:' + p.login, p.lines)"
              :on="focusKey === p.login"
              :dim="!!focusKey && focusKey !== p.login"
              @focus="(k) => (focusKey = k)"
            />
            <li v-if="people.length > fit">
              <a class="more pop" :style="{ '--d': 0.3 + fit * 0.09 + 's' }" href="#everyone"
                >+{{ people.length - fit }} more →</a
              >
            </li>
          </ol>
        </section>

        <section class="tide pop" style="--d: 0.2s" aria-labelledby="tide-h">
          <div class="tide-head">
            <span id="tide-h" class="label">Every week since 1 July</span>
            <ul class="legend">
              <li
                v-for="s in series"
                :key="s.key"
                :class="{ on: focusKey === s.key }"
                :style="{ '--c': s.color }"
                @pointerenter="focusKey = s.key"
                @pointerleave="focusKey = null"
              >
                <i></i>{{ s.name }}
              </li>
            </ul>
            <span class="key" aria-hidden="true"
              ><i></i><span>added</span><i class="kd"></i><span>removed</span></span
            >
          </div>
          <div
            ref="boxEl"
            class="tide-box"
            @pointermove="onBoxMove"
            @pointerleave="hoverWeek = null"
          >
            <svg
              v-if="chart"
              role="img"
              aria-label="Lines added and removed per week, stacked by person"
              :viewBox="`0 0 ${chart.W} ${chart.H}`"
            >
              <defs>
                <pattern
                  v-for="(s, i) in series"
                  :id="'hz' + i"
                  :key="s.key"
                  width="4.5"
                  height="4.5"
                  patternUnits="userSpaceOnUse"
                  patternTransform="rotate(45)"
                >
                  <rect width="4.5" height="4.5" :style="{ fill: s.color }" opacity=".3" />
                  <rect width="2" height="4.5" :style="{ fill: s.color }" />
                </pattern>
              </defs>
              <g class="grid">
                <line
                  v-for="g in chart.grid"
                  :key="g.key"
                  :x1="chart.padL"
                  :x2="chart.W - chart.padR"
                  :y1="g.y"
                  :y2="g.y"
                />
              </g>
              <rect
                class="hot"
                :x="hotX"
                :y="chart.top - 8"
                :width="chart.step"
                :height="chart.plotH + 12"
                rx="8"
                :style="{ opacity: hoverWeek === null ? 0 : 0.05 }"
              />
              <g
                v-for="c in chart.cols"
                :key="c.w"
                class="col"
                :style="{ '--d': c.delay, transformOrigin: `0 ${chart.zeroY}px` }"
              >
                <g
                  v-for="l in c.layers"
                  :key="l.key"
                  class="layer"
                  :class="{ on: focusKey === l.key }"
                  @pointerenter="focusKey = l.key"
                  @pointerleave="focusKey = null"
                >
                  <path v-for="(d, j) in l.paths" :key="j" :d="d.d" :style="{ fill: d.fill }" />
                </g>
              </g>
              <line
                class="zero"
                :x1="chart.padL"
                :x2="chart.W - chart.padR"
                :y1="chart.zeroY"
                :y2="chart.zeroY"
              />
              <g class="axis">
                <text
                  v-for="t in chart.ticks"
                  :key="t.key"
                  :x="chart.padL - 8"
                  :y="t.y + 4"
                  text-anchor="end"
                >
                  {{ t.label }}
                </text>
                <text
                  v-for="m in chart.months"
                  :key="m.key"
                  :x="m.x"
                  :y="chart.H - 5"
                  text-anchor="middle"
                >
                  {{ m.label }}
                </text>
              </g>
              <g class="peak">
                <line
                  :x1="chart.peak.x"
                  :x2="chart.peak.x"
                  :y1="chart.peak.y"
                  :y2="chart.peak.y - 5"
                />
                <text :x="chart.peak.x" :y="chart.peak.y - 10" :text-anchor="chart.peak.anchor">
                  {{ chart.peak.text }}
                </text>
              </g>
            </svg>
            <div ref="tipEl" class="tip" :style="{ left: tipLeft + 'px', opacity: tip ? 1 : 0 }">
              <template v-if="tip">
                <h4>{{ tip.title }}</h4>
                <ul v-if="tip.rows.length">
                  <li v-for="s in tip.rows" :key="s.key" :style="{ '--c': s.color }">
                    <i></i>
                    <span>{{ s.name }}</span>
                    <span>+{{ fmt(s.adds[tip.w]) }}</span>
                    <span>−{{ fmt(s.dels[tip.w]) }}</span>
                  </li>
                </ul>
                <ul v-else>
                  <li><span></span><span>Quiet week</span></li>
                </ul>
                <div v-if="tip.rows.length > 1" class="sum">
                  <span>Total</span>
                  <span>+{{ fmt(weekAdd[tip.w]) }}</span>
                  <span>−{{ fmt(weekDel[tip.w]) }}</span>
                </div>
              </template>
            </div>
          </div>
        </section>

        <a class="cue pop" style="--d: 1.4s" href="#helpers"
          >Helpers
          <svg
            viewBox="0 0 24 24"
            aria-hidden="true"
            fill="none"
            stroke="currentColor"
            stroke-width="2.2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path d="M6 9l6 6 6-6" />
          </svg>
        </a>
      </section>
    </div>

    <section v-show="people.length > fit" id="everyone" class="block" aria-labelledby="everyone-h">
      <div
        class="label reveal"
        data-reveal="everyone:label"
        :class="{ seen: seen['everyone:label'] }"
      >
        Everyone
      </div>
      <h2
        id="everyone-h"
        class="reveal"
        data-reveal="everyone:h2"
        :class="{ seen: seen['everyone:h2'] }"
      >
        All {{ people.length }}
      </h2>
      <ol class="grid-all">
        <ContributorRow
          v-for="(p, i) in people"
          :key="p.login"
          :data-reveal="'all:' + p.login"
          :p="p"
          :rank="i"
          :top="false"
          phase="late"
          :seen="!!seen['all:' + p.login]"
          :value="shown('all:' + p.login, p.lines)"
          :on="focusKey === p.login"
          :dim="!!focusKey && focusKey !== p.login"
          @focus="(k) => (focusKey = k)"
        />
      </ol>
    </section>

    <section id="helpers" class="block" aria-labelledby="helpers-h">
      <div
        class="label reveal"
        data-reveal="helpers:label"
        :class="{ seen: seen['helpers:label'] }"
      >
        Helpers
      </div>
      <h2
        id="helpers-h"
        class="reveal"
        data-reveal="helpers:h2"
        :class="{ seen: seen['helpers:h2'] }"
      >
        No commits.<br /><em>Still built it.</em>
      </h2>
      <ul class="helpers">
        <li
          v-for="h in helperCards"
          :key="h.key"
          class="helper reveal"
          :class="{ seen: seen[h.key] }"
          :data-reveal="h.key"
          :style="{ '--c': h.color, '--d': h.delay }"
        >
          <span v-if="h.placeholder" class="placeholder-tag">placeholder</span>
          <div class="mg">{{ h.initials }}</div>
          <h3>{{ h.name }}</h3>
          <span class="role">{{ h.role }}</span>
          <p v-if="h.note">{{ h.note }}</p>
        </li>
      </ul>
    </section>

    <footer class="site-note">
      Counted from GitHub ·
      <a :href="`https://github.com/${D.repo}`">{{ D.repo }}</a>
    </footer>
  </main>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref } from 'vue';
import ContributorRow from '../components/site/ContributorRow.vue';
import D from '../data/contributors.json';
import { HELPERS } from '../data/helpers.js';

const SLOTS = 6;
const NICE_STEPS = [1000, 2000, 5000, 10000, 20000, 25000, 50000, 100000];
const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;

const fmt = (n) => Math.round(n).toLocaleString('en-IN');
const short = (n) => (n >= 1000 ? (n / 1000).toFixed(n >= 10000 ? 0 : 1) + 'k' : String(n));
const day = (iso, opt = { day: 'numeric', month: 'short' }) =>
  new Date(iso + 'T00:00:00+05:30').toLocaleDateString('en-IN', {
    timeZone: 'Asia/Kolkata',
    ...opt,
  });
const initials = (name) =>
  name
    .split(/[\s_-]+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0].toUpperCase())
    .join('');
const niceStep = (max) => NICE_STEPS.find((n) => max / n <= 2.5) || 100000;

// ---------- data ----------
const sorted = D.contributors
  .map((c) => ({ ...c, lines: c.additions + c.deletions }))
  .sort((a, b) => b.lines - a.lines);
const totals = sorted.reduce(
  (t, p) => ({
    a: t.a + p.additions,
    d: t.d + p.deletions,
    c: t.c + p.commits,
    pr: t.pr + p.mergedPRs,
  }),
  { a: 0, d: 0, c: 0, pr: 0 }
);
const allLines = totals.a + totals.d;
const nWeeks = D.weekStarts.length;
const maxLines = sorted[0]?.lines || 1;

// Top SLOTS people get a colour each; everyone else is the neutral Others.
const people = sorted.map((p, i) => {
  const color = i < SLOTS ? `var(--s${i + 1})` : 'var(--s0)';
  const share = (p.lines / allLines) * 100;
  const peak = Math.max(...p.weeks.map((w) => w.a + w.d)) || 1;
  return {
    ...p,
    color,
    shareText: share < 1 ? share.toFixed(1) : String(Math.round(share)),
    barWidth: Math.max(2, (p.lines / maxLines) * 100),
    cells: p.weeks.map((w) => {
      const v = w.a + w.d;
      return {
        style: v
          ? { background: color, opacity: (0.25 + 0.75 * Math.sqrt(v / peak)).toFixed(2) }
          : {},
      };
    }),
  };
});

const series = people.slice(0, SLOTS).map((p) => ({
  key: p.login,
  name: p.name.split(' ')[0],
  color: p.color,
  adds: p.weeks.map((w) => w.a),
  dels: p.weeks.map((w) => w.d),
}));
if (people.length > SLOTS) {
  const rest = people.slice(SLOTS);
  const sumWeeks = (k) => D.weekStarts.map((_, w) => rest.reduce((s, p) => s + p.weeks[w][k], 0));
  series.push({
    key: '__others',
    name: 'Others',
    color: 'var(--s0)',
    adds: sumWeeks('a'),
    dels: sumWeeks('d'),
  });
}
const weekAdd = D.weekStarts.map((_, w) => series.reduce((t, s) => t + s.adds[w], 0));
const weekDel = D.weekStarts.map((_, w) => series.reduce((t, s) => t + s.dels[w], 0));
const weekTotal = weekAdd.map((a, w) => a + weekDel[w]);
const peakW = weekTotal.indexOf(Math.max(...weekTotal));

const KPIS = [
  { label: 'Commits', value: totals.c },
  { label: 'Merged PRs', value: totals.pr },
  { label: 'People', value: people.length },
  { label: 'Weeks', value: nWeeks },
];
const helperCards = HELPERS.map((h, i) => ({
  ...h,
  key: 'helper:' + i,
  initials: initials(h.name),
  color: `var(--s${(i % SLOTS) + 1})`,
  delay: `${i * 0.08}s`,
}));

const since = 'since ' + day(D.since, { day: 'numeric', month: 'short', year: 'numeric' });
const updated =
  'Updated ' +
  new Date(D.generatedAt).toLocaleString('en-IN', {
    day: 'numeric',
    month: 'short',
    hour: 'numeric',
    minute: '2-digit',
    timeZone: 'Asia/Kolkata',
  });

// ---------- state ----------
const page = ref(null);
const rowsEl = ref(null);
const boxEl = ref(null);
const tipEl = ref(null);
const focusKey = ref(null);
const hoverWeek = ref(null);
const tipLeft = ref(0);
const size = reactive({ w: 0, h: 0 });
const ready = ref(reduce);
const settled = ref(reduce);
const fit = ref(Math.min(people.length, window.innerWidth > 900 ? 8 : 5));
const counts = reactive({});
const seen = reactive({});
const revealTo = new Map(people.map((p) => ['all:' + p.login, p.lines]));

// A number shows its final value unless a count-up is running for it.
const shown = (key, final) => (key in counts ? counts[key] : final);
if (!reduce) {
  counts.total = 0;
  KPIS.forEach((_, i) => (counts['kpi' + i] = 0));
  people.forEach((p) => (counts['row:' + p.login] = 0));
}

const dashPeople = computed(() => people.slice(0, fit.value));
const tip = computed(() => {
  const w = hoverWeek.value;
  if (w === null) return null;
  const endMs = Date.parse(D.weekStarts[w] + 'T00:00:00+05:30') + 6 * 86400000;
  const rows = series
    .filter((s) => s.adds[w] + s.dels[w])
    .sort((a, b) => b.adds[w] + b.dels[w] - (a.adds[w] + a.dels[w]));
  const end = new Date(endMs).toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
    timeZone: 'Asia/Kolkata',
  });
  return { w, rows, title: `${day(D.weekStarts[w])} – ${end}` };
});

// ---------- chart geometry ----------
const chart = computed(() => {
  const W = size.w;
  const H = size.h;
  if (!W || !H) return null;
  const padL = 40;
  const padR = 4;
  const axisH = 22;
  const top = 26;
  const plotH = H - axisH - top - 4;
  const maxA = Math.max(...weekAdd, 1);
  const maxD = Math.max(...weekDel, 1);
  const k = plotH / (maxA + maxD);
  const zeroY = top + maxA * k;
  const step = (W - padL - padR) / nWeeks;
  const colW = Math.min(step * 0.64, 36);
  const X = (w) => padL + step * (w + 0.5);
  const tick = niceStep(Math.max(maxA, maxD));

  const grid = [];
  const ticks = [{ key: 'zero', y: zeroY, label: '0' }];
  for (let v = tick; v <= maxA; v += tick) {
    grid.push({ key: `u${v}`, y: zeroY - v * k });
    ticks.push({ key: `u${v}`, y: zeroY - v * k, label: `+${short(v)}` });
  }
  for (let v = tick; v <= maxD; v += tick) {
    grid.push({ key: `d${v}`, y: zeroY + v * k });
    ticks.push({ key: `d${v}`, y: zeroY + v * k, label: `−${short(v)}` });
  }

  const months = [];
  let lastMonth = '';
  D.weekStarts.forEach((ws, w) => {
    const mo = day(ws, { month: 'short' });
    if (mo !== lastMonth) {
      lastMonth = mo;
      months.push({ key: ws, x: X(w), label: mo });
    }
  });

  // Each segment is rounded only at the column's outer end. Tiny weeks keep a 1.5px sliver.
  const seg = (x, y, w, h, roundTop, roundBot) => {
    const r = Math.min(3, w / 2, h);
    const rt = roundTop ? r : 0;
    const rb = roundBot ? r : 0;
    return [
      `M${x},${y + rt}`,
      rt ? `Q${x},${y} ${x + rt},${y}` : '',
      `H${x + w - rt}`,
      rt ? `Q${x + w},${y} ${x + w},${y + rt}` : '',
      `V${y + h - rb}`,
      rb ? `Q${x + w},${y + h} ${x + w - rb},${y + h}` : '',
      `H${x + rb}`,
      rb ? `Q${x},${y + h} ${x},${y + h - rb}` : '',
      'Z',
    ].join('');
  };
  const cols = D.weekStarts.map((_, w) => {
    const lastA = series.findLastIndex((s) => s.adds[w] > 0);
    const lastD = series.findLastIndex((s) => s.dels[w] > 0);
    let up = zeroY;
    let dn = zeroY;
    const layers = [];
    series.forEach((s, i) => {
      const paths = [];
      if (s.adds[w] > 0) {
        const h = Math.max(1.5, s.adds[w] * k);
        up -= h;
        paths.push({ d: seg(X(w) - colW / 2, up, colW, h, i === lastA, false), fill: s.color });
      }
      if (s.dels[w] > 0) {
        const h = Math.max(1.5, s.dels[w] * k);
        paths.push({
          d: seg(X(w) - colW / 2, dn, colW, h, false, i === lastD),
          fill: `url(#hz${i})`,
        });
        dn += h;
      }
      if (paths.length) layers.push({ key: s.key, paths });
    });
    return { w, delay: (0.45 + w * 0.05).toFixed(2) + 's', layers };
  });

  const px = X(peakW);
  const py = zeroY - weekAdd[peakW] * k - 6;
  const anchor = px > W - 120 ? 'end' : px < padL + 80 ? 'start' : 'middle';
  return {
    W,
    H,
    padL,
    padR,
    top,
    plotH,
    zeroY,
    step,
    X,
    grid,
    ticks,
    months,
    cols,
    peak: {
      x: px,
      y: py,
      anchor,
      text: `${short(weekTotal[peakW])} · week of ${day(D.weekStarts[peakW])}`,
    },
  };
});
const hotX = computed(() =>
  chart.value && hoverWeek.value !== null
    ? chart.value.X(hoverWeek.value) - chart.value.step / 2
    : 0
);

function onBoxMove(e) {
  const c = chart.value;
  if (!c) return;
  const r = boxEl.value.getBoundingClientRect();
  const w = Math.floor((e.clientX - r.left - c.padL) / c.step);
  if (w < 0 || w >= nWeeks) {
    hoverWeek.value = null;
    return;
  }
  hoverWeek.value = w;
  nextTick(() => {
    const tw = tipEl.value?.offsetWidth ?? 0;
    const x = c.X(w);
    const half = c.step / 2;
    tipLeft.value = x + half + 8 + tw > c.W ? x - half - 8 - tw : x + half + 8;
  });
}

// ---------- rows: the first screen fits the board on desktop; the rest sit under "All N" ----------
const initialFit = () => Math.min(people.length, window.innerWidth > 900 ? 8 : 5);
async function fitRows() {
  fit.value = initialFit();
  await nextTick();
  const list = rowsEl.value;
  if (!list || window.innerWidth <= 900) return;
  while (fit.value > 1 && list.scrollHeight > list.clientHeight + 2) {
    fit.value--;
    await nextTick();
  }
}
let resizeTimer = 0;
function onResize() {
  clearTimeout(resizeTimer);
  resizeTimer = setTimeout(fitRows, 150);
}

// ---------- one-shot motion ----------
const frames = new Map();
const timers = new Set();
let startFrame = 0;
let io = null;
let ro = null;

function later(fn, ms) {
  const id = setTimeout(() => {
    timers.delete(id);
    fn();
  }, ms);
  timers.add(id);
}

function countUp(key, to, dur) {
  cancelAnimationFrame(frames.get(key));
  const t0 = performance.now();
  counts[key] = 0;
  const frame = (t) => {
    const p = Math.min(1, (t - t0) / dur);
    if (p < 1) {
      counts[key] = to * (1 - 2 ** (-10 * p));
      frames.set(key, requestAnimationFrame(frame));
    } else {
      delete counts[key];
      frames.delete(key);
    }
  };
  frames.set(key, requestAnimationFrame(frame));
}

function start() {
  ready.value = true;
  countUp('total', allLines, 1800);
  later(() => (settled.value = true), 1600);
  later(() => {
    KPIS.forEach((k, i) => countUp('kpi' + i, k.value, 1300));
    people.forEach((p) => countUp('row:' + p.login, p.lines, 1300));
  }, 250);
}

function onReveal(entries) {
  for (const e of entries) {
    if (!e.isIntersecting) continue;
    const key = e.target.dataset.reveal;
    io.unobserve(e.target);
    seen[key] = true;
    if (revealTo.has(key)) countUp(key, revealTo.get(key), 900);
  }
}

onMounted(() => {
  fitRows();
  ro = new ResizeObserver(([entry]) => {
    size.w = entry.contentRect.width;
    size.h = entry.contentRect.height;
  });
  ro.observe(boxEl.value);
  window.addEventListener('resize', onResize);

  const revealNodes = page.value.querySelectorAll('[data-reveal]');
  if (reduce) {
    revealNodes.forEach((n) => (seen[n.dataset.reveal] = true));
    return;
  }
  // Two frames so the first paint shows the hidden state before the entrance starts.
  startFrame = requestAnimationFrame(() => {
    startFrame = requestAnimationFrame(start);
  });
  io = new IntersectionObserver(onReveal, { threshold: 0.15 });
  revealNodes.forEach((n) => io.observe(n));
});

onBeforeUnmount(() => {
  cancelAnimationFrame(startFrame);
  frames.forEach((id) => cancelAnimationFrame(id));
  frames.clear();
  timers.forEach((id) => clearTimeout(id));
  timers.clear();
  clearTimeout(resizeTimer);
  window.removeEventListener('resize', onResize);
  io?.disconnect();
  ro?.disconnect();
});
</script>

<style scoped>
.page {
  max-width: 1240px;
  margin: 0 auto;
  padding: 18px 24px 80px;
  font-variant-numeric: tabular-nums;
}
.label {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--ink-3);
}
.mono {
  font-family: var(--mono);
  letter-spacing: -0.01em;
}

/* Entrance: hidden until .ready, then rises in with its --d delay. */
.pop {
  opacity: 0;
  transform: translateY(14px);
}
.ready .pop {
  opacity: 1;
  transform: none;
  transition:
    opacity 0.6s ease,
    transform 0.7s cubic-bezier(0.2, 0.9, 0.25, 1);
  transition-delay: var(--d, 0s);
}
/* After the entrance, hover dimming must be quick and in unison. */
.settled .pop {
  transition:
    border-color 0.2s,
    transform 0.2s,
    opacity 0.25s;
  transition-delay: 0s;
}
.reveal {
  opacity: 0;
  transform: translateY(18px);
}
.reveal.seen {
  opacity: 1;
  transform: none;
  transition:
    opacity 0.6s ease,
    transform 0.7s cubic-bezier(0.2, 0.9, 0.25, 1);
  transition-delay: var(--d, 0s);
}
.grow {
  transform: scaleX(0);
}
.ready .grow {
  transform: scaleX(1);
  transition: transform 1.1s cubic-bezier(0.2, 0.9, 0.25, 1);
  transition-delay: var(--d, 0s);
}

/* ---------- header ---------- */
.first {
  display: flex;
  flex-direction: column;
  gap: 14px;
  height: calc(100svh - var(--nav-h) - 18px);
  min-height: 600px;
}
.head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 8px 16px;
  flex-wrap: wrap;
}
h1 {
  margin: 0;
  font-size: clamp(34px, 4.4vw, 48px);
  font-weight: 750;
  letter-spacing: -0.04em;
  line-height: 0.95;
}
.meta {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0;
  color: var(--ink-2);
  font-size: 13.5px;
}
.live {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--s1);
  position: relative;
}
.live::after {
  content: '';
  position: absolute;
  inset: -4px;
  border-radius: 50%;
  border: 1.5px solid var(--s1);
  opacity: 0;
  animation: ping 1.6s ease-out 1.2s 3;
}
@keyframes ping {
  from {
    transform: scale(0.5);
    opacity: 0.9;
  }
  to {
    transform: scale(1.8);
    opacity: 0;
  }
}

/* ---------- dashboard: the first screen ---------- */
.dash {
  position: relative;
  flex: 1;
  min-height: 0;
  display: grid;
  grid-template-columns: minmax(360px, 5fr) minmax(0, 7fr);
  grid-template-rows: auto minmax(0, 1fr);
  gap: 22px clamp(24px, 3vw, 48px);
  padding-bottom: 56px;
}
.hero {
  align-self: end;
}
.total {
  display: block;
  font-size: clamp(56px, min(8.4vw, 12.5vh), 132px);
  line-height: 0.95;
  font-weight: 750;
  letter-spacing: -0.04em;
  margin: 10px 0 14px;
}
.split {
  display: flex;
  gap: 18px;
  align-items: baseline;
  font-size: 17px;
  font-weight: 600;
}
.split .add {
  color: var(--ink);
}
.split .del {
  color: var(--ink-2);
}
.split i {
  font-style: normal;
  font-weight: 400;
  color: var(--ink-3);
  font-size: 14px;
  margin-left: 4px;
}
.ratio {
  display: flex;
  height: 6px;
  margin-top: 12px;
  border-radius: 4px;
  overflow: hidden;
  gap: 2px;
  max-width: 420px;
}
.ratio b {
  display: block;
  height: 100%;
  transform-origin: left;
}
.ratio .a {
  background: var(--ink);
  border-radius: 4px 0 0 4px;
}
.ratio .d {
  background: repeating-linear-gradient(135deg, var(--ink-3) 0 2px, transparent 2px 5px);
  border-radius: 0 4px 4px 0;
}

.kpis {
  align-self: end;
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 2px;
  background: var(--line);
  border-radius: 18px;
  overflow: hidden;
  border: 1px solid var(--line);
  box-shadow: var(--shadow);
}
.kpis li {
  background: var(--card);
  padding: 16px 18px 14px;
}
.kpis strong {
  display: block;
  font-size: clamp(28px, 2.8vw, 40px);
  font-weight: 750;
  line-height: 1;
  letter-spacing: -0.035em;
  margin-top: 8px;
}

/* ---------- leaderboard ---------- */
.board {
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-height: 0;
}
.board-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
}
.rows {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
  list-style: none;
  margin: -2px -4px 0 0;
  padding: 2px 4px 2px 0;
  overflow: hidden;
}
.more {
  font-size: 14px;
  font-weight: 600;
  color: var(--ink-2);
  padding: 6px 4px;
  text-decoration: none;
}
.more:hover {
  color: var(--ink);
}

/* ---------- weekly columns: added above the line, removed below ---------- */
.tide {
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-height: 0;
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 22px;
  padding: 18px 20px 14px;
  box-shadow: var(--shadow);
}
.tide-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}
.legend {
  display: flex;
  gap: 6px 14px;
  flex-wrap: wrap;
  list-style: none;
  margin: 0;
  padding: 0;
  font-size: 13px;
  color: var(--ink-2);
}
.legend li {
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: default;
  transition: opacity 0.25s;
}
.legend i {
  width: 10px;
  height: 10px;
  border-radius: 3px;
  background: var(--c);
}
.tide-box {
  position: relative;
  flex: 1;
  min-height: 240px;
  container-type: inline-size;
}
.tide-box svg {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  overflow: visible;
}
.layer {
  transition: opacity 0.25s;
}
.layer path {
  stroke: var(--card);
  stroke-width: 1;
}
.col {
  transform: scaleY(0);
  transform-box: view-box;
}
.ready .col {
  transform: none;
  transition: transform 0.75s cubic-bezier(0.2, 0.9, 0.25, 1) var(--d, 0s);
}
.zero {
  stroke: var(--ink-3);
  stroke-width: 1;
}
.grid line {
  stroke: var(--line-strong);
  stroke-dasharray: 2 4;
}
.axis text {
  fill: var(--ink-3);
  font-size: 11.5px;
  font-family: var(--mono);
  letter-spacing: -0.01em;
}
.peak text {
  fill: var(--ink);
  font-size: 13px;
  font-weight: 600;
}
.peak line {
  stroke: var(--ink);
  stroke-width: 1.5;
}
.peak {
  opacity: 0;
  transition: opacity 0.5s 1.9s;
}
.ready .peak {
  opacity: 1;
}
.hot {
  fill: var(--ink);
  opacity: 0;
  transition: opacity 0.15s;
  pointer-events: none;
}
.key {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: var(--ink-2);
}
.key i {
  width: 14px;
  height: 10px;
  border-radius: 3px;
  background: var(--ink-2);
}
.key i + i,
.key span + i {
  margin-left: 8px;
}
.key .kd {
  background: repeating-linear-gradient(-45deg, var(--ink-2) 0 2px, transparent 2px 4.5px);
}
.tip {
  position: absolute;
  top: 8px;
  pointer-events: none;
  transition: opacity 0.15s;
  background: var(--paper);
  border: 1px solid var(--line-strong);
  border-radius: 12px;
  padding: 10px 12px;
  min-width: 190px;
  box-shadow: var(--shadow);
  font-size: 13px;
  z-index: 2;
}
.tip h4 {
  margin: 0 0 6px;
  font-family: var(--mono);
  font-size: 12px;
  font-weight: 600;
  color: var(--ink-3);
  letter-spacing: 0.08em;
  text-transform: uppercase;
}
.tip ul {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 3px;
}
.tip li {
  display: grid;
  grid-template-columns: 10px 1fr auto auto;
  gap: 10px;
  align-items: center;
}
.tip li i {
  width: 10px;
  height: 10px;
  border-radius: 3px;
  background: var(--c);
}
.tip li span + span {
  color: var(--ink-2);
  text-align: right;
}
.tip .sum {
  border-top: 1px solid var(--line);
  margin-top: 6px;
  padding-top: 6px;
  display: grid;
  grid-template-columns: 1fr auto auto;
  gap: 10px;
  font-weight: 600;
}

/* Hover focus: one person lights up across the board, legend and chart. */
[data-focus] .layer:not(.on),
[data-focus] .legend li:not(.on) {
  opacity: 0.28;
}

.cue {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 16px;
  margin-inline: auto;
  width: max-content;
  display: flex;
  align-items: center;
  gap: 8px;
  text-decoration: none;
  color: var(--ink-2);
  font-weight: 600;
  font-size: 14px;
}
.cue svg {
  width: 16px;
  height: 16px;
  animation: nudge 1.4s ease-in-out 2.4s 3;
}
@keyframes nudge {
  50% {
    transform: translateY(4px);
  }
}

/* ---------- everyone (only when the board overflows) + helpers ---------- */
.block {
  padding-top: 72px;
}
.block h2 {
  margin: 10px 0 28px;
  font-family: var(--display);
  font-weight: 400;
  font-size: clamp(42px, 5.4vw, 68px);
  line-height: 1;
  letter-spacing: -0.01em;
}
.block h2 em {
  color: var(--mari-ink);
}
.grid-all {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(min(300px, 100%), 1fr));
  gap: 8px;
}
.helpers {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(min(240px, 100%), 1fr));
  gap: 14px;
}
.helper {
  position: relative;
  overflow: hidden;
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 22px;
  padding: 22px 20px 20px;
  box-shadow: var(--shadow);
}
.helper .mg {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-size: 22px;
  font-weight: 750;
  color: var(--ink);
  background: radial-gradient(circle at 30% 30%, var(--card), var(--paper));
  box-shadow:
    0 0 0 2px var(--card),
    0 0 0 4px var(--c);
}
.helper h3 {
  margin: 18px 0 4px;
  font-size: 20px;
  font-weight: 700;
}
.helper .role {
  display: inline-block;
  font-size: 12px;
  font-weight: 650;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--ink);
  padding: 4px 10px;
  border-radius: 99px;
  border: 1px solid var(--c);
}
.helper p {
  margin: 12px 0 0;
  color: var(--ink-2);
  font-size: 14.5px;
}
.helper::after {
  content: '';
  position: absolute;
  right: -40px;
  top: -40px;
  width: 140px;
  height: 140px;
  border-radius: 50%;
  background: var(--c);
  opacity: 0.1;
}
.placeholder-tag {
  position: absolute;
  top: 14px;
  right: 16px;
  font-size: 11px;
  color: var(--ink-3);
  z-index: 1;
}
.site-note {
  padding: 40px 24px 48px;
  color: var(--ink-3);
  font-size: 13px;
  text-align: center;
}

/* ---------- phone / narrow ---------- */
@media (max-width: 900px) {
  .first {
    height: auto;
    min-height: 0;
  }
  .dash {
    grid-template-columns: minmax(0, 1fr);
    grid-template-rows: none;
    gap: 18px;
    padding-bottom: 72px;
  }
  .hero {
    order: 1;
  }
  .kpis {
    order: 2;
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .tide {
    order: 3;
  }
  .board {
    order: 4;
  }
  .tide-box {
    min-height: 220px;
  }
  .rows {
    overflow: visible;
  }
}
@media (max-width: 560px) {
  .page {
    padding: 14px 16px 90px;
  }
  .kpis li {
    padding: 12px 14px;
  }
  .tide {
    padding: 14px 12px 10px;
    border-radius: 18px;
  }
  .meta {
    font-size: 12.5px;
  }
  .helper {
    display: grid;
    grid-template-columns: 56px minmax(0, 1fr);
    gap: 2px 14px;
    padding: 16px;
    align-items: center;
  }
  .helper .mg {
    width: 52px;
    height: 52px;
    font-size: 18px;
    grid-row: span 2;
  }
  .helper h3 {
    margin: 0;
    font-size: 18px;
  }
  .helper .role {
    justify-self: start;
  }
  .helper p {
    grid-column: 1 / -1;
    margin-top: 10px;
  }
}
</style>
