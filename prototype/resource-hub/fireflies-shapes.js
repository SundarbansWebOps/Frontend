// PROTOTYPE — Home "Synchrony": the data shapes the swarm forms on the sticky stage. Every light
// is one real thing (a paper, a set of notes, an event, a meetup, a seat), laid out in
// stage-local px. Each layout also returns the DOM labels that name it.
import { courses, LEVELS } from './data.js';
import { chartColumns, events, WINGS } from './events.js';
import { lower, regions, upper } from './house.js';
import { COMMUNITIES, CREW } from './teams.js';
import { COL } from './fireflies-swarm.js';

const WING_COL = {
  cultural: COL.CULTURAL,
  games: COL.GAMES,
  tech: COL.TECH,
  talks: COL.TALKS,
};
const LEVEL_SHORT = {
  foundation: 'Foundation',
  programming: 'Programming',
  datascience: 'Data science',
  degree: 'Degree',
};
const fmt = (v) => v.toLocaleString('en-IN');

// Resources: one light per past paper and set of notes, stacked into a column per course,
// columns grouped by level. Papers sit at the foot of each column, notes on top.
export function layoutResources(W, H, narrow) {
  const groups = LEVELS.map((l) => courses.filter((c) => c.track === l.id))
    .map((list, i) => ({ id: LEVELS[i].id, list }))
    .filter((g) => g.list.length);
  const gap = 0.9;
  const units = courses.length + gap * (groups.length - 1);
  const slot = W / units;
  const maxN = Math.max(...courses.map((c) => c.pyqs.length + c.notes.length));
  const base = H - (narrow ? 20 : 30);
  const room = base - (narrow ? 30 : 56);
  let s = 12;
  let k = 1;
  for (; s > 1.6; s -= 0.1) {
    k = Math.max(1, Math.floor((slot * 0.74) / s));
    if (Math.ceil(maxN / k) * s <= room) break;
  }
  const pts = [];
  const labels = [];
  const cols = {};
  let u = 0;
  for (const g of groups) {
    const u0 = u;
    for (const c of g.list) {
      const cx = (u + 0.5) * slot;
      const gi = courses.indexOf(c);
      const kinds = [...c.pyqs.map(() => COL.PYQ), ...c.notes.map(() => COL.NOTE)];
      kinds.forEach((kind, j) => {
        const row = Math.floor(j / k);
        pts.push({
          x: cx + ((j % k) - (k - 1) / 2) * s,
          y: base - row * s - s / 2,
          c: kind,
          s: s * 0.36,
          g: gi,
        });
      });
      cols[c.code] = { x: cx, y: base - Math.ceil(kinds.length / k) * s - 6, text: c.short };
      u++;
    }
    labels.push({
      id: `lv-${g.id}`,
      x: ((u0 + u) / 2) * slot,
      y: base + 10,
      text: LEVEL_SHORT[g.id],
      cls: 'axis',
    });
    u += gap;
  }
  return { W, H, pts, labels, cols, pitch: s };
}

// Events: one light per past event, in the month it happened, coloured by wing. Quiet runs of
// months collapse into a gap (as on the Events page); undated events wait at the end.
export function layoutEvents(W, H, narrow) {
  const dated = events.filter((e) => e.at);
  const undated = events.filter((e) => !e.at);
  const cols = chartColumns(dated);
  const GAP = 0.6;
  const units = cols.reduce((v, c) => v + (c.gap ? GAP : 1), 0) + (undated.length ? 1 + GAP : 0);
  const slot = W / units;
  const order = Object.keys(WINGS);
  const byMonth = new Map();
  for (const e of dated) {
    const key = e.y * 12 + e.m;
    if (!byMonth.has(key)) byMonth.set(key, []);
    byMonth.get(key).push(e);
  }
  const maxStack = Math.max(undated.length, ...[...byMonth.values()].map((l) => l.length));
  const base = H - (narrow ? 22 : 34);
  const room = base - (narrow ? 30 : 64);
  // Lights are sized by the column width; stacks rise taller than they are wide, like a swell.
  const s = Math.min(slot * 0.9, narrow ? 15 : 26);
  const sy = Math.min(room / maxStack, s * 2.1);
  const pts = [];
  const labels = [];
  const stack = (list, cx) =>
    list
      .sort((p, q) => order.indexOf(p.wing) - order.indexOf(q.wing))
      .forEach((e, j) =>
        pts.push({
          x: cx,
          y: base - s / 2 - j * sy,
          c: WING_COL[e.wing] ?? COL.FLY,
          s: s * 0.34,
          w: 1.4,
        })
      );
  let u = 0;
  let year = null;
  for (const c of cols) {
    if (c.gap) {
      u += GAP;
      continue;
    }
    const cx = (u + 0.5) * slot;
    stack(byMonth.get(c.key) ?? [], cx);
    if (c.y !== year) {
      year = c.y;
      labels.push({ id: `y-${c.y}`, x: cx, y: base + 12, text: String(c.y), cls: 'axis start' });
    }
    u += 1;
  }
  if (undated.length) {
    u += GAP;
    const cx = (u + 0.5) * slot;
    stack(undated, cx);
    labels.push({ id: 'undated', x: cx, y: base + 12, text: 'no date', cls: 'axis' });
  }
  return { W, H, pts, labels, pitch: s };
}

// House: one light per meetup, gathered at its region's hub city. Cities are projected from
// lat/lon; no borders are drawn.
const LABEL_SIDE = { bengaluru: 'l', kolkata: 'b', chandigarh: 'l' };
export function layoutHouse(W, H, narrow) {
  const k = Math.cos((22 * Math.PI) / 180);
  const lons = regions.map((r) => r.lon);
  const lats = regions.map((r) => r.lat);
  const lon0 = Math.min(...lons) - 1.4;
  const lon1 = Math.max(...lons) + 1.4;
  const lat0 = Math.min(...lats) - 1.4;
  const lat1 = Math.max(...lats) + 1.4;
  const top = narrow ? 6 : 24;
  const sc = Math.min((W * 0.92) / ((lon1 - lon0) * k), (H - top - 8) / (lat1 - lat0));
  const ox = (W - (lon1 - lon0) * k * sc) / 2;
  const oy = top + (H - top - 8 - (lat1 - lat0) * sc) / 2;
  const pitch = narrow ? 4.6 : 10;
  const pts = [];
  const labels = [];
  for (const r of regions) {
    const cx = ox + (r.lon - lon0) * k * sc;
    const cy = oy + (lat1 - r.lat) * sc;
    r.items.forEach((_, j) => {
      const rad = pitch * 0.62 * Math.sqrt(j + 0.4);
      const ang = j * 2.39996;
      pts.push({
        x: cx + Math.cos(ang) * rad,
        y: cy + Math.sin(ang) * rad,
        c: COL.UHC,
        s: pitch * 0.34,
      });
    });
    const R = pitch * 0.62 * Math.sqrt(r.items.length) + (narrow ? 5 : 9);
    const side = LABEL_SIDE[r.id] ?? 'r';
    labels.push({
      id: `r-${r.id}`,
      x: side === 'r' ? cx + R : side === 'l' ? cx - R : cx,
      y: side === 'b' ? cy + R + 6 : cy,
      text: r.name,
      n: r.items.length,
      cls: `city ${side}`,
    });
  }
  return { W, H, pts, labels, pitch };
}

// Teams: the seats of the house as a tree — the Upper House Council, the regional
// coordinators of the Lower House, the communities and the crew.
export function layoutTeams(W, H, narrow) {
  const tiers = [
    { id: 'uhc', label: 'Upper House Council', items: upper.map(() => ({ c: COL.UHC })) },
    { id: 'lhc', label: 'Lower House Council', items: lower.map(() => ({ c: COL.SEAT })) },
    {
      id: 'com',
      label: 'Communities',
      items: COMMUNITIES.map((c) => ({ c: WING_COL[c.wing] ?? COL.FLY, name: c.name })),
    },
    { id: 'crew', label: 'Crew', items: CREW.map((c) => ({ c: COL.PYQ, name: c.name })) },
  ];
  const left = W * (narrow ? 0.37 : 0.3);
  const span = W - left;
  const y0 = narrow ? 30 : 60;
  const y1 = H - (narrow ? 26 : 56);
  const size = narrow ? 3.2 : 5.2;
  const pts = [];
  const labels = [];
  const lines = [];
  let prevRow = null;
  tiers.forEach((tier, ti) => {
    const y = y0 + ((y1 - y0) * ti) / (tiers.length - 1);
    const m = tier.items.length;
    const gapX = Math.min(span / (m + 0.5), narrow ? 44 : 88);
    const x0 = left + span / 2 - (gapX * (m - 1)) / 2;
    const row = tier.items.map((it, j) => ({ x: x0 + j * gapX, y, ...it }));
    for (const p of row) {
      pts.push({ x: p.x, y: p.y, c: p.c, s: size * (ti === 0 ? 1.35 : 1) });
      if (prevRow) {
        const par = prevRow.reduce((b, q) => (Math.abs(q.x - p.x) < Math.abs(b.x - p.x) ? q : b));
        lines.push([par.x, par.y + 8, p.x, p.y - 8]);
      }
      if (p.name && !narrow)
        labels.push({
          id: `t-${tier.id}-${p.name}`,
          x: p.x,
          y: p.y + 16,
          text: p.name,
          cls: 'node',
        });
    }
    labels.push({
      id: `t-${tier.id}`,
      x: 0,
      y,
      text: tier.label,
      n: m,
      cls: 'tier',
    });
    prevRow = row;
  });
  return { W, H, pts, labels, lines, pitch: size };
}

export const totals = {
  pyqs: courses.reduce((v, c) => v + c.pyqs.length, 0),
  notes: courses.reduce((v, c) => v + c.notes.length, 0),
};
export const biggestShape = totals.pyqs + totals.notes;
export { fmt };
