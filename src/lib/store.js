// Shared site state: pinned courses, the open course sheet, toasts, page navigation,
// and query parsing for the resource search.
import { reactive, watch } from 'vue';
import { router } from '../router/index.js';
import { catalogByCode } from '../data/branches.js';
import { courses, byCode, byName } from './courses.js';

// A course the site knows about. Data Science courses come with notes and past papers; every
// other branch resolves through the catalogue, which says the course exists but has no files
// attached yet. Null only for a code no branch has ever heard of.
// A catalogue course that shares its subject name with a Data Science course (e.g. AE/ES
// "English I") borrows that course's notes and past papers — same subject, different code.
const CATALOG = Object.fromEntries(
  Object.entries(catalogByCode).map(([code, c]) => {
    const twin = byName[c.name.toLowerCase()];
    return [
      code,
      {
        ...c,
        short: twin?.short ?? c.short,
        aliases: twin?.aliases ?? [],
        desc: twin?.desc ?? '',
        notes: twin?.notes ?? [],
        pyqs: twin?.pyqs ?? [],
      },
    ];
  })
);
export const courseFor = (code) => byCode[code] ?? CATALOG[code] ?? null;

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
  // A search typed on Home, carried into the Resources search bar.
  q: '',
});
let courseOpener = null;
export const getCourseOpener = () => courseOpener;

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

// Page navigation — lets a panel send the reader to another page, or to one of its sections.
const PATHS = {
  home: '/',
  resources: '/resources',
  events: '/events',
  house: '/house',
  teams: '/teams',
  lounge: '/login',
  login: '/login',
};
export const nav = {
  go(page, anchor = null, query = {}) {
    const path = PATHS[page] ?? '/';
    const loungeRoom = page === 'lounge' && anchor ? anchor : null;
    const hash = anchor && !loungeRoom ? `#${anchor}` : '';
    const nextQuery = { ...query, ...(loungeRoom ? { room: loungeRoom } : {}) };
    const here = router.currentRoute.value;
    // Same place again: vue-router drops duplicate navigations, so scroll directly.
    if (
      here.path === path &&
      here.hash === hash &&
      JSON.stringify(here.query) === JSON.stringify(nextQuery)
    ) {
      if (anchor) document.getElementById(anchor)?.scrollIntoView({ behavior: 'smooth' });
      return;
    }
    router.push({ path, hash, query: nextQuery });
  },
};

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
  courseOpener = document.activeElement instanceof HTMLElement ? document.activeElement : null;
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
  const route = router.currentRoute.value;
  router.push({
    query: { ...route.query, course: code },
    hash: route.hash,
    state: { sheet: true },
  });
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
  else {
    store.sheet = null;
    const route = router.currentRoute.value;
    const query = { ...route.query };
    delete query.course;
    router.replace({ query, hash: route.hash });
  }
}

// The URL is the source of truth: Back drops ?course= and the sheet closes; a shared
// ?course= link (or Forward) opens it.
watch(
  () => router.currentRoute.value.query.course,
  (code) => {
    if (!courseFor(code)) store.sheet = null;
    else if (store.sheet?.code !== code)
      store.sheet = {
        code,
        tab: 'pyqs',
        exam: 'All',
        week: null,
        origin: { x: innerWidth / 2, y: 80 },
      };
  },
  { immediate: true }
);

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
