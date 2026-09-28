// PROTOTYPE — shared state for all variants: pinned courses, the open course sheet,
// and query parsing for the search bar.
import { reactive, watch } from 'vue';
import { courses, byCode } from './data.js';

const MINE_KEY = 'proto-resource-hub-mine';

function loadMine() {
  try {
    return JSON.parse(localStorage.getItem(MINE_KEY)) ?? [];
  } catch {
    return [];
  }
}

export const store = reactive({
  mine: loadMine(),
  // { code, tab: 'pyqs' | 'notes', exam, week, origin: {x, y} }
  sheet: null,
  toast: '',
  // Section to scroll to after a page switch (see App.go).
  anchor: null,
  // A search typed on Home, carried into the Resources search bar.
  q: '',
  // Home prototype: which landing variant (1-3), and a counter that replays its intro.
  landingV: 1,
  replay: 0,
});

watch(
  () => [...store.mine],
  (v) => {
    try {
      localStorage.setItem(MINE_KEY, JSON.stringify(v));
    } catch {
      /* storage blocked: pins last for this visit only */
    }
  }
);

// Page navigation, set by App — lets a panel send the reader to another page's section.
export const nav = { go: () => {} };

export const isMine = (code) => store.mine.includes(code);

export function togglePin(code) {
  const i = store.mine.indexOf(code);
  if (i === -1) store.mine.push(code);
  else store.mine.splice(i, 1);
}

let toastTimer;
export function toast(msg) {
  store.toast = msg;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => (store.toast = ''), 2200);
}

// Opening a course pushes a history entry so the phone back button closes the sheet
// instead of leaving the site. The ?course= URL is shareable on WhatsApp.
export function openCourse(code, opts = {}, event) {
  const origin = event
    ? originFrom(event)
    : { x: window.innerWidth / 2, y: window.innerHeight / 2 };
  store.sheet = {
    code,
    tab: opts.tab ?? 'pyqs',
    exam: opts.exam ?? 'All',
    week: opts.week ?? null,
    origin,
  };
  const url = new URL(location.href);
  url.searchParams.set('course', code);
  history.pushState({ sheet: true }, '', url);
}

function originFrom(event) {
  if (event?.clientX || event?.clientY) return { x: event.clientX, y: event.clientY };
  const r = event?.currentTarget?.getBoundingClientRect?.();
  return r
    ? { x: r.left + r.width / 2, y: r.top + r.height / 2 }
    : { x: innerWidth / 2, y: innerHeight / 2 };
}

export function closeCourse() {
  if (history.state?.sheet) history.back();
  else dropSheet();
}

function dropSheet() {
  store.sheet = null;
  const url = new URL(location.href);
  url.searchParams.delete('course');
  history.replaceState(null, '', url);
}

window.addEventListener('popstate', () => {
  if (store.sheet) dropSheet();
});

const initial = new URL(location.href).searchParams.get('course');
if (initial && byCode[initial]) {
  store.sheet = {
    code: initial,
    tab: 'pyqs',
    exam: 'All',
    week: null,
    origin: { x: innerWidth / 2, y: 80 },
  };
}

// ---- Search ----------------------------------------------------------------
// "ma1 pyq", "dbms week 4", "q1 stats", "sejal" all resolve to something useful.
const TYPE_WORDS = {
  pyq: 'pyqs',
  pyqs: 'pyqs',
  paper: 'pyqs',
  papers: 'pyqs',
  qp: 'pyqs',
  notes: 'notes',
  note: 'notes',
};
const EXAM_WORDS = [
  [/\b(q1|quiz\s?1|qz1)\b/, 'Quiz 1'],
  [/\b(q2|quiz\s?2|qz2)\b/, 'Quiz 2'],
  [/\b(et|end\s?-?term|endterm|finals?)\b/, 'End term'],
  [/\boppe\b/, 'OPPE'],
];

export function parseQuery(q) {
  let text = q.toLowerCase().trim();
  let tab = null;
  let exam = null;
  let week = null;
  for (const [re, ex] of EXAM_WORDS) {
    if (re.test(text)) {
      exam = ex;
      tab = 'pyqs';
      text = text.replace(re, ' ');
    }
  }
  const wk = text.match(/\b(?:w|week)\s?(\d{1,2})\b/);
  if (wk) {
    week = Number(wk[1]);
    tab = 'notes';
    text = text.replace(wk[0], ' ');
  }
  text = text
    .split(/\s+/)
    .filter((w) => {
      if (TYPE_WORDS[w]) {
        tab = TYPE_WORDS[w];
        return false;
      }
      return true;
    })
    .join(' ')
    .trim();
  return { text, tab, exam, week };
}

function scoreCourse(c, text) {
  if (!text) return 0;
  const t = text.replace(/\s+/g, ' ');
  const tight = t.replace(/\s/g, '');
  if (c.code.toLowerCase() === tight) return 100;
  if (c.aliases.some((a) => a.replace(/\s/g, '') === tight)) return 90;
  if (c.short.toLowerCase() === t) return 90;
  if (c.code.toLowerCase().includes(tight)) return 60;
  if (c.short.toLowerCase().startsWith(t)) return 55;
  if (c.aliases.some((a) => a.startsWith(t))) return 50;
  if (c.name.toLowerCase().includes(t)) return 40;
  if (c.desc?.toLowerCase().includes(t)) return 15;
  return 0;
}

export function search(q) {
  const p = parseQuery(q);
  if (!p.text && !p.tab) return { parsed: p, courses: [], resources: [] };
  const scored = courses
    .map((c) => ({ c, s: p.text ? scoreCourse(c, p.text) : isMine(c.code) ? 30 : 0 }))
    .filter((x) => x.s > 0)
    .sort((a, b) => b.s - a.s || Number(isMine(b.c.code)) - Number(isMine(a.c.code)));
  // "ma1" is an exact alias for Maths 1; don't also list every code containing "ma1".
  const strong = scored[0]?.s >= 90 ? scored.filter((x) => x.s >= 90) : scored;
  const hits = strong.slice(0, 6).map(({ c }) => ({
    code: c.code,
    count: countFor(c, p),
    tab: p.tab ?? 'pyqs',
    exam: p.exam ?? 'All',
    week: p.week,
  }));
  // Free-text across resource titles/authors when no course matched strongly.
  let resources = [];
  if (p.text.length >= 3 && (!scored.length || scored[0].s < 50)) {
    for (const c of courses) {
      for (const n of c.notes) {
        if (n.title.toLowerCase().includes(p.text) || n.author.toLowerCase().includes(p.text))
          resources.push({
            code: c.code,
            kind: 'Notes',
            title: n.title,
            sub: n.author,
            link: n.link,
          });
      }
      for (const y of c.pyqs) {
        if (y.title.toLowerCase().includes(p.text))
          resources.push({
            code: c.code,
            kind: 'PYQ',
            title: y.title,
            sub: y.term?.label ?? '',
            link: y.link,
          });
      }
    }
    resources = resources.slice(0, 6);
  }
  return { parsed: p, courses: hits, resources };
}

export function countFor(c, p) {
  if (p.tab === 'notes') return c.notes.filter((n) => !p.week || n.week === p.week).length;
  return c.pyqs.filter((y) => !p.exam || y.exam === p.exam).length;
}

export { courses, byCode };
