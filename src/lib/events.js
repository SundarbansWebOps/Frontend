// Past events, adapted from the data already on the live site.
// Public Events is an archive only: live events belong to the members-only House lounge.
import { reactive, watch } from 'vue';
import { router } from '../router/index.js';
import { EVENTS } from '../data/events.data.js';

export const WINGS = {
  cultural: { label: 'Cultural' },
  games: { label: 'Games & Sports' },
  tech: { label: 'Tech' },
  talks: { label: 'Talks' },
};

const MON = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
export const MONTH = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const MONTH_LONG = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
export const monthLong = (m) => MONTH_LONG[m];

// Handles every shape the sheets use: "15 Feb 2026 | 8:00 PM", "5-7 Dec 2025 | Online",
// "October 2025", "10th Aug. 2025", "28 Sep'25", "17-05-2026", "14 Sept 2025".
export function parseDate(raw = '') {
  const s = raw.toLowerCase();
  const time = raw.match(/\d{1,2}:\d{2}\s?[ap]m/i)?.[0] ?? '';
  const num = s.match(/\b(\d{1,2})-(\d{1,2})-(20\d{2})\b/);
  if (num) return { y: +num[3], m: +num[2] - 1, d: +num[1], time, range: '' };
  const m = s.match(
    /(?:(\d{1,2})(?:\s?-\s?(\d{1,2}))?(?:st|nd|rd|th)?\.?\s+)?([a-z]{3,9})\.?\s*'?\s*(20\d{2}|\d{2})\b/
  );
  if (!m) return { y: null, m: null, d: null, time, range: '' };
  const mi = MON.indexOf(m[3].slice(0, 3));
  if (mi === -1) return { y: null, m: null, d: null, time, range: '' };
  let y = +m[4];
  if (y < 100) y += 2000;
  return { y, m: mi, d: m[1] ? +m[1] : null, time, range: m[2] ? `${m[1]}–${m[2]}` : '' };
}

export const slug = (s) =>
  s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');

const WING_OF_TYPE = {
  'Guest Talk': 'talks',
  Empowerment: 'talks',
  Sports: 'games',
  'E-Sports': 'games',
  Technical: 'tech',
  Hackathon: 'tech',
  Workshop: 'tech',
  Cultural: 'cultural',
};
const wingOf = (e) =>
  e.wing === 'esports' ? 'games' : (e.wing ?? WING_OF_TYPE[e.type] ?? 'cultural');

// Cloudinary: swap the stored delivery transform for one sized to where it is shown.
const CLD = 'f_auto,q_auto:good,w_1000,c_limit';
export const img = {
  thumb: (u) => u?.replace(CLD, 'f_auto,q_auto,w_72,h_72,c_fill,g_auto'),
  blur: (u) => u?.replace(CLD, 'f_auto,q_30,w_24,e_blur:300'),
  card: (u) => u?.replace(CLD, 'f_auto,q_auto:eco,w_420,c_limit'),
  full: (u) => u?.replace(CLD, 'f_auto,q_auto,w_900,c_limit'),
};

// "Offline Meetup" rows duplicate the regional meetup sheets, which live on the House page.
export const events = EVENTS.filter((e) => e.type !== 'Offline Meetup').map((e) => {
  const when = parseDate(e.date);
  const wing = wingOf(e);
  return {
    id: slug(e.title),
    title: e.title,
    type: e.type,
    wing,
    desc: e.desc ?? '',
    attendees: e.attendees ?? '',
    location: e.location ?? '',
    image: e.image ?? null,
    ratio: e.w ? e.w / e.h : null,
    ...when,
    online: /online/i.test(e.date ?? ''),
    at: when.y != null ? new Date(when.y, when.m, when.d ?? 15) : null,
  };
});

events.sort((a, b) => (b.at ?? 0) - (a.at ?? 0));
export const byId = Object.fromEntries(events.map((e) => [e.id, e]));

export const monthKey = (e) => (e.at ? e.y * 12 + e.m : null);

// Month columns for the swell chart. Runs of empty months collapse into one "quiet" gap,
// so three sparse years don't squeeze the busy season into a sliver.
export function chartColumns(list) {
  const keys = list.map(monthKey).filter((k) => k != null);
  const lo = Math.min(...keys);
  const hi = Math.max(...keys);
  const cols = [];
  let quiet = 0;
  for (let k = lo; k <= hi; k++) {
    const n = list.filter((e) => monthKey(e) === k).length;
    if (!n) {
      quiet++;
      continue;
    }
    if (quiet) cols.push({ gap: true, months: quiet, key: `g${k}` });
    quiet = 0;
    cols.push({ key: k, y: Math.floor(k / 12), m: k % 12 });
  }
  return cols;
}

export function groupByMonth(list) {
  const groups = new Map();
  for (const e of list) {
    const k = monthKey(e) ?? 'undated';
    if (!groups.has(k)) groups.set(k, []);
    groups.get(k).push(e);
  }
  return [...groups].map(([k, items]) => ({
    key: k,
    y: k === 'undated' ? null : Math.floor(k / 12),
    m: k === 'undated' ? null : k % 12,
    items,
  }));
}

export const dayLabel = (e) =>
  e.at ? `${e.range || e.d || ''} ${MONTH[e.m]}${e.d ? '' : ` ${e.y}`}`.trim() : '';
export const fullDate = (e) =>
  e.at
    ? [e.range || e.d, e.d ? MONTH[e.m] : monthLong(e.m), e.y].filter(Boolean).join(' ')
    : 'Date not recorded';

export function matches(e, q) {
  if (!q) return true;
  const t = q.toLowerCase().trim();
  return (
    e.title.toLowerCase().includes(t) ||
    e.type?.toLowerCase().includes(t) ||
    e.desc.toLowerCase().includes(t)
  );
}

// ---- Event sheet state; ?event= deep link, phone back closes it. -------------------------
// `wing`: a filter to open the Events page with (set by a Teams community card).
export const ev = reactive({ open: null, origin: null, hover: null, wing: null });

export function openEvent(id, e) {
  ev.origin = e?.clientX
    ? { x: e.clientX, y: e.clientY }
    : (() => {
        const r = e?.currentTarget?.getBoundingClientRect?.();
        return r
          ? { x: r.left + r.width / 2, y: r.top + r.height / 2 }
          : { x: innerWidth / 2, y: innerHeight / 2 };
      })();
  const route = router.currentRoute.value;
  const to = { query: { ...route.query, event: id }, hash: route.hash, state: { event: true } };
  if (ev.open) router.replace(to);
  else router.push(to);
  ev.open = id;
}

// `then` runs once the panel is gone — after the history entry pops, so a follow-up
// page change doesn't race the back navigation. Template handlers must not pass
// their DOM event through (@click="closeEvent()"): only a real callback is kept.
let afterClose = null;
export function closeEvent(then) {
  afterClose = typeof then === 'function' ? then : null;
  if (history.state?.event) history.back();
  else {
    ev.open = null;
    const route = router.currentRoute.value;
    const query = { ...route.query };
    delete query.event;
    router.replace({ query, hash: route.hash }).then(runAfterClose);
  }
}
function runAfterClose() {
  const f = afterClose;
  afterClose = null;
  if (typeof f === 'function') f();
}

// The URL is the source of truth: Back drops ?event= and the sheet closes; a shared
// ?event= link (or Forward) opens it.
watch(
  () => router.currentRoute.value.query.event,
  (id) => {
    if (id && byId[id]) {
      if (ev.open !== id) {
        ev.open = id;
        ev.origin = { x: innerWidth / 2, y: 80 };
      }
      return;
    }
    ev.open = null;
    runAfterClose();
  },
  { immediate: true }
);
