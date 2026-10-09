// Events, this member's registrations/attendance/certificates, and notices for the Lounge
// prototype. Fixture events plus the real past events from src/data/events.data.js.
// Registration is one-way (spec 002 §3): register() adds, nothing removes.
import { computed, reactive, ref } from 'vue';
import { EVENTS as SITE_EVENTS } from '../../data/events.data.js';
import { events as FIX, notices as NOTICE_ROWS, records } from './fixtures.js';
import CREST from '../../assets/crest.webp';
import { liveOn, read, store } from './state.js';

/* ---------- The minute clock ----------
   Countdowns read in minutes ("ends in 1 h 04 min"), so the page re-renders once a minute,
   on the minute, not every second. A hidden tab doesn't tick; it catches up when shown. */

export const clock = ref(Date.now());
let tick = 0;
function schedule() {
  clearTimeout(tick);
  if (document.hidden) return;
  clock.value = Date.now();
  tick = setTimeout(schedule, 60_000 - (Date.now() % 60_000) + 50);
}
export function startClock() {
  document.addEventListener('visibilitychange', schedule);
  schedule();
}
export function stopClock() {
  document.removeEventListener('visibilitychange', schedule);
  clearTimeout(tick);
}

/* ---------- Communities ---------- */

/* `art` is the community's painted figure (the event pop-up's header). House-wide events are
   the house's own, so they carry the crest. */
export const COMMUNITIES = {
  cultural: {
    label: 'Cultural',
    cls: 'w-cultural',
    art: new URL('./art/r3/fig-cultural.webp', import.meta.url).href,
  },
  technical: {
    label: 'Technical',
    cls: 'w-tech',
    art: new URL('./art/r3/fig-technical.webp', import.meta.url).href,
  },
  esports: {
    label: 'Esports',
    cls: 'w-games',
    art: new URL('./art/r3/fig-esports.webp', import.meta.url).href,
  },
  house: { label: 'House-wide', cls: 'w-talks', art: CREST },
};
export const commKey = (e) => e.community ?? 'house';
export const commOf = (e) => COMMUNITIES[commKey(e)];

/* ---------- Real past events from the house site ---------- */

const MONTHS = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
const slug = (s) =>
  s
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');

/* '15 Feb 2026 | 8:00 PM' -> a day and time; 'May 2026' / 'October 2025' -> a month only.
   Anything else ('Online Submission', ranges) is left out. */
function parseSiteDate(s) {
  const d = /^(\d{1,2}) ([A-Za-z]{3})\w* (\d{4})(?: \| (\d{1,2}):(\d{2}) ?([AP]M))?/.exec(s);
  if (d) {
    const m = MONTHS.indexOf(d[2].toLowerCase());
    let h = d[4] ? Number(d[4]) % 12 : 19;
    if (d[6] === 'PM') h += 12;
    return {
      at: new Date(Number(d[3]), m, Number(d[1]), h, d[5] ? Number(d[5]) : 0),
      precision: 'day',
    };
  }
  const mo = /^([A-Za-z]+) (\d{4})$/.exec(s);
  if (mo) {
    const m = MONTHS.indexOf(mo[1].slice(0, 3).toLowerCase());
    if (m >= 0) return { at: new Date(Number(mo[2]), m, 1, 19), precision: 'month' };
  }
  return null;
}

const WING = { cultural: 'cultural', esports: 'esports', tech: 'technical' };
const siteEvents = SITE_EVENTS.flatMap((e) => {
  const when = parseSiteDate(e.date || '');
  if (!when) return [];
  const t = when.at.getTime();
  return [
    {
      id: `p-${slug(e.title)}`,
      name: e.title,
      type: e.type,
      community: WING[e.wing] ?? null,
      description: e.desc,
      platform: e.location || 'Google Meet',
      starts_at: new Date(t).toISOString(),
      ends_at: new Date(t + 90 * 60_000).toISOString(),
      precision: when.precision,
      attendees: e.attendees || '',
      site: true,
    },
  ];
});

/* Fixture events win on id clashes; real events are de-duplicated by id. */
const byId = new Map();
for (const e of [...siteEvents, ...FIX]) byId.set(e.id, e);
export const ALL = [...byId.values()];
export const eventById = (id) => byId.get(id);

/* ---------- Status ---------- */

/* Reads the minute clock, so lists move an event from Upcoming to Live to Past by themselves. */
export function status(e, now = clock.value) {
  if (now >= Date.parse(e.ends_at)) return 'past';
  if (now >= Date.parse(e.starts_at)) return 'live';
  return 'upcoming';
}

/* Live toggle in the test panel: off hides live events everywhere. */
export const visible = computed(() => ALL.filter((e) => liveOn.value || status(e) !== 'live'));

/* Home reads the same list as Events: the event on air now (or null), and the next one. */
export const liveNow = computed(() => visible.value.find((e) => status(e) === 'live') ?? null);
export const nextUp = computed(
  () =>
    visible.value
      .filter((e) => status(e) === 'upcoming')
      .sort((a, b) => a.starts_at.localeCompare(b.starts_at))[0] ?? null
);

/* ---------- This member: registrations (one-way), attendance, certificates ---------- */

const REG_KEY = 'lounge-e-registered';
const savedRegs = (() => {
  try {
    const ids = JSON.parse(read(REG_KEY) || '[]');
    return Array.isArray(ids) ? ids.filter((id) => typeof id === 'string') : [];
  } catch {
    return [];
  }
})();
const regs = reactive(
  new Set([...Object.keys(records).filter((id) => records[id].registered), ...savedRegs])
);

export const isRegistered = (e) => regs.has(e.id);
export function register(e) {
  if (regs.has(e.id) || status(e) !== 'upcoming') return;
  regs.add(e.id);
  const extra = [...regs].filter((id) => !records[id]?.registered);
  store(REG_KEY, JSON.stringify(extra));
}

/* Attendance mark for an event the member registered for or joined.
   attended = 20 minutes or more in the Meet (spec 002 §3). */
export const ATTEND_MIN = 20;
export function markOf(e) {
  const r = records[e.id];
  const s = status(e);
  if (s === 'live') return regs.has(e.id) ? { kind: 'live', text: 'Live now' } : null;
  if (s === 'upcoming') return regs.has(e.id) ? { kind: 'registered', text: 'Registered' } : null;
  if (!r) return null;
  const m = r.minutes ?? 0;
  if (m >= ATTEND_MIN) return { kind: 'attended', text: 'Attended', minutes: m };
  if (m > 0) return { kind: 'early', text: 'Left early', minutes: m };
  if (r.registered) return { kind: 'missed', text: 'Missed' };
  return null;
}

export const certOf = (e) => records[e.id]?.certificate ?? null;
export const minutesOf = (e) => records[e.id]?.minutes ?? 0;

/* Mine: registered or attended, soonest/live first, then most recent past. */
export const mine = computed(() => {
  const list = visible.value.filter((e) => regs.has(e.id) || minutesOf(e) > 0);
  const rank = { live: 0, upcoming: 1, past: 2 };
  return list.sort((a, b) => {
    const sa = status(a);
    const sb = status(b);
    if (sa !== sb) return rank[sa] - rank[sb];
    return sa === 'past'
      ? b.starts_at.localeCompare(a.starts_at)
      : a.starts_at.localeCompare(b.starts_at);
  });
});

/* Certificates: newest first, each with its event. */
export const certificates = ALL.filter((e) => certOf(e))
  .map((e) => ({ ...certOf(e), event: e, minutes: minutesOf(e) }))
  .sort((a, b) => b.event.starts_at.localeCompare(a.event.starts_at));
export const verifyHref = (id) => `/#/verify-certificate?id=${encodeURIComponent(id)}`;

/* ---------- Notices: read and dismissed state, banner for the newest under 72 h ---------- */

const READ_KEY = 'lounge-e-notices-read';
const DISMISS_KEY = 'lounge-e-banner-dismissed';
const loadSet = (key) => {
  try {
    return new Set(JSON.parse(read(key) || '[]'));
  } catch {
    return new Set();
  }
};
const readSet = reactive(loadSet(READ_KEY));
const dismissed = reactive(loadSet(DISMISS_KEY));

export const notices = [...NOTICE_ROWS].sort((a, b) => b.posted_at.localeCompare(a.posted_at));
export const isRead = (n) => n.read || readSet.has(n.id);
export const unreadCount = computed(() => notices.filter((n) => !isRead(n)).length);
export function markRead(n) {
  if (isRead(n)) return;
  readSet.add(n.id);
  store(READ_KEY, JSON.stringify([...readSet]));
}
export function markAllRead() {
  notices.forEach((n) => readSet.add(n.id));
  store(READ_KEY, JSON.stringify([...readSet]));
}
const BANNER_MS = 72 * 3_600_000;
export const bannerNotice = computed(
  () =>
    notices.find(
      (n) => clock.value - Date.parse(n.posted_at) < BANNER_MS && !dismissed.has(n.id)
    ) ?? null
);
export function dismissBanner(n) {
  dismissed.add(n.id);
  store(DISMISS_KEY, JSON.stringify([...dismissed]));
  markRead(n);
}

/* Test panel: forget registrations made here, reads and dismissals. */
export function resetDemo() {
  for (const id of [...regs]) if (!records[id]?.registered) regs.delete(id);
  readSet.clear();
  dismissed.clear();
  [REG_KEY, READ_KEY, DISMISS_KEY].forEach((k) => store(k, null));
}

/* ---------- Words for dates ---------- */

const fmtDay = new Intl.DateTimeFormat('en-IN', {
  weekday: 'short',
  day: 'numeric',
  month: 'short',
});
const fmtDate = new Intl.DateTimeFormat('en-IN', {
  day: 'numeric',
  month: 'short',
  year: 'numeric',
});
const fmtLong = new Intl.DateTimeFormat('en-IN', {
  day: 'numeric',
  month: 'long',
  year: 'numeric',
});
const fmtMonth = new Intl.DateTimeFormat('en-IN', { month: 'long', year: 'numeric' });
const fmtTime = new Intl.DateTimeFormat('en-IN', { hour: 'numeric', minute: '2-digit' });

export const timeOf = (iso) => fmtTime.format(new Date(iso)).toLowerCase().replace(' ', ' ');
export const thisYear = (iso) => new Date(iso).getFullYear() === new Date().getFullYear();

/* "Thu, 8 Oct · 8:30 pm" for this year, "15 Feb 2025" for older, "May 2026" for month-only. */
export function whenOf(e) {
  if (e.precision === 'month') return fmtMonth.format(new Date(e.starts_at));
  if (status(e) === 'past' && !thisYear(e.starts_at)) return fmtDate.format(new Date(e.starts_at));
  return `${fmtDay.format(new Date(e.starts_at))} · ${timeOf(e.starts_at)}`;
}
export function spanOf(e) {
  if (e.precision === 'month') return fmtMonth.format(new Date(e.starts_at));
  const d = new Date(e.starts_at);
  const day = thisYear(e.starts_at) ? fmtDay.format(d) : fmtLong.format(d);
  return e.site
    ? `${day}, ${timeOf(e.starts_at)}`
    : `${day}, ${timeOf(e.starts_at)} to ${timeOf(e.ends_at)}`;
}
export const longDate = (e) =>
  e.precision === 'month'
    ? fmtMonth.format(new Date(e.starts_at))
    : fmtLong.format(new Date(e.starts_at));
export const tile = (e) => {
  const d = new Date(e.starts_at);
  return {
    day: e.precision === 'month' ? '' : String(d.getDate()),
    mon: d.toLocaleString('en-IN', { month: 'short' }),
    yr: thisYear(e.starts_at) ? '' : String(d.getFullYear()).slice(2),
  };
};

const DAY = 86_400_000;
/* A span in minutes: "45 min", "1 h 04 min", "3 h". Never seconds. */
export function span(ms) {
  const m = Math.max(1, Math.ceil(ms / 60_000));
  if (m < 60) return `${m} min`;
  const h = Math.floor(m / 60);
  const r = m % 60;
  return r ? `${h} h ${String(r).padStart(2, '0')} min` : `${h} h`;
}
/* "ends in 1 h 04 min" for an event on air. */
export const endsIn = (e, now = clock.value) => `ends in ${span(Date.parse(e.ends_at) - now)}`;

/* Calendar days, not 24-hour blocks: 8 pm the day after tomorrow is "in 2 days". */
const midnight = (t) => new Date(t).setHours(0, 0, 0, 0);
export function until(iso, now = clock.value) {
  const t = Date.parse(iso);
  const days = Math.round((midnight(t) - midnight(now)) / DAY);
  if (days >= 2) return `in ${days} days`;
  if (days === 1) return `tomorrow, ${timeOf(iso)}`;
  if (t - now >= 3_600_000) return `today, in ${span(t - now)}`;
  return `in ${span(t - now)}`;
}
/* Rows already show the time: "tomorrow", "in 4 days", "today". */
export const soon = (iso) => until(iso).split(',')[0];
export function ago(iso, now = clock.value) {
  const ms = now - Date.parse(iso);
  const d = Math.floor(ms / DAY);
  if (d >= 1) return d === 1 ? 'yesterday' : `${d} days ago`;
  const m = Math.round(ms / 60_000);
  return m >= 60 ? `${Math.floor(m / 60)} h ago` : `${Math.max(1, m)} min ago`;
}

/* A ref the Events page and Home share: which tab Events opens on. */
export const eventsTab = ref('upcoming');
