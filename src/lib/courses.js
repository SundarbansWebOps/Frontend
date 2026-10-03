// Adapts the Study Corner data (src/data/study/) into course-shaped data.
// Notes and PYQs are real links, checked by `npm run check:study`. Term dates below are
// SAMPLE data until Supabase has a table for them.
import raw from '../data/study/index.js';
import { parseExam, parseTerm } from './pyq-title.js';

const META = {
  BSMA1001: { short: 'Maths 1', aliases: ['m1', 'ma1', 'maths1', 'math1', 'math 1'] },
  BSMA1002: { short: 'Stats 1', aliases: ['s1', 'st1', 'stats1', 'stat1', 'statistics 1'] },
  BSCS1001: { short: 'CT', aliases: ['ct', 'computational'] },
  BSHS1001: { short: 'English 1', aliases: ['e1', 'eng1', 'english1'] },
  BSMA1003: { short: 'Maths 2', aliases: ['m2', 'ma2', 'maths2', 'math2', 'math 2'] },
  BSMA1004: { short: 'Stats 2', aliases: ['s2', 'st2', 'stats2', 'stat2', 'statistics 2'] },
  BSCS1002: { short: 'Python', aliases: ['py', 'python', 'pip'] },
  BSHS1002: { short: 'English 2', aliases: ['e2', 'eng2', 'english2'] },
  BSCS2001: { short: 'DBMS', aliases: ['dbms', 'sql', 'database'] },
  BSCS2002: { short: 'PDSA', aliases: ['pdsa', 'dsa'] },
  BSCS2003: { short: 'MAD 1', aliases: ['mad1', 'mad 1', 'app dev 1'] },
  BSCS2005: { short: 'Java', aliases: ['java', 'pcj'] },
  BSCS2006: { short: 'MAD 2', aliases: ['mad2', 'mad 2', 'app dev 2'] },
  BSSE2001: { short: 'Sys Cmds', aliases: ['sc', 'syscmd', 'system commands', 'linux'] },
  BSCS2004: { short: 'MLF', aliases: ['mlf', 'ml foundations'] },
  BSMS2001: { short: 'BDM', aliases: ['bdm', 'business'] },
  BSCS2007: { short: 'MLT', aliases: ['mlt', 'ml techniques'] },
  BSCS2008: { short: 'MLP', aliases: ['mlp', 'ml practice'] },
  BSSE2002: { short: 'TDS', aliases: ['tds', 'tools'] },
  BSCS3001: { short: 'SE', aliases: ['se', 'software engineering'] },
  BSCS3002: { short: 'ST', aliases: ['st', 'testing'] },
  BSCS3003: { short: 'AI', aliases: ['ai', 'search methods'] },
  BSCS3004: { short: 'DL', aliases: ['dl', 'deep learning'] },
};

// Diploma splits into two real programmes; the delta map draws them as two channels.
const PROGRAMMING = ['BSCS2001', 'BSCS2002', 'BSCS2003', 'BSCS2005', 'BSCS2006', 'BSSE2001'];

function parseSet(title) {
  const m = title.match(/\b(QP\s?[A-Z]?\d?|AN\d|Set \d|Paper \d)\b/i);
  return m ? m[1].toUpperCase().replace(/\s+/g, ' ') : '';
}

function parseNote(n) {
  const w = n.title.match(/week\s*-?\s*(\d{1,2})/i);
  const by = n.title.match(/\(by ([^)]+)\)/i);
  const clean = n.title.replace(/\s*\(by [^)]+\)/i, '').trim();
  return { title: clean, link: n.link, week: w ? Number(w[1]) : null, author: by ? by[1] : '' };
}

function parsePyq(p) {
  const term = parseTerm(p.title);
  return {
    title: p.title,
    link: p.link,
    exam: parseExam(p.title),
    term,
    set: parseSet(p.title),
  };
}

export const LEVELS = [
  { id: 'foundation', label: 'Foundation' },
  { id: 'programming', label: 'Diploma · Programming' },
  { id: 'datascience', label: 'Diploma · Data Science' },
  { id: 'degree', label: 'BS Degree' },
];

export const courses = [];
for (const [level, list] of Object.entries(raw)) {
  for (const s of list) {
    const meta = META[s.code] ?? { short: s.code, aliases: [] };
    const track =
      level === 'foundation'
        ? 'foundation'
        : level === 'bs'
          ? 'degree'
          : PROGRAMMING.includes(s.code)
            ? 'programming'
            : 'datascience';
    const notes = s.notes.map(parseNote);
    const pyqs = s.pyqs.map(parsePyq).sort((a, b) => (b.term?.sort ?? 0) - (a.term?.sort ?? 0));
    courses.push({
      code: s.code,
      name: s.subject,
      short: meta.short,
      aliases: meta.aliases,
      desc: s.description,
      track,
      notes,
      pyqs,
    });
  }
}

export const byCode = Object.fromEntries(courses.map((c) => [c.code, c]));

<<<<<<< HEAD
// ---- Sep 2026 Term Calendar from Official Student Grading Document ----
export const TODAY = new Date('2026-09-30T10:00:00+05:30');
=======
// ---- SAMPLE term calendar (Sep 2026 term). Replace with Supabase data (no table for term dates yet). ----
export const TODAY = new Date('2026-09-27T10:00:00+05:30');
>>>>>>> 65cf33b98a9bba33876df45acfc2c677b5806e70
export const TERM = {
  label: 'Sep 2026 term',
  start: new Date('2026-09-28T00:00:00+05:30'),
  end: new Date('2027-01-10T23:59:59+05:30'),
  weeks: 12,
};
export const DATES = [
  { id: 'w1', label: 'Week 1 assignment due', short: 'W1 due', date: '2026-10-11', kind: 'due' },
  {
    id: 'w4',
    label: 'OPPE 1 eligibility closes (W4)',
    short: 'OPPE 1 cutoff',
    date: '2026-11-01',
    kind: 'cutoff',
  },
  {
    id: 'q1',
    label: 'Quiz 1 (In person centres)',
    short: 'Quiz 1',
    date: '2026-11-15',
    kind: 'exam',
    exam: 'Quiz 1',
  },
  {
    id: 'o1',
    label: 'OPPE 1 (Online proctored)',
    short: 'OPPE 1',
    date: '2026-11-22',
    kind: 'exam',
    exam: 'OPPE',
  },
  {
    id: 'w7',
    label: 'End term eligibility closes (W7)',
    short: 'ET cutoff',
    date: '2026-11-25',
    kind: 'cutoff',
  },
  {
    id: 'w8',
    label: 'OPPE 2 eligibility closes (W8)',
    short: 'OPPE 2 cutoff',
    date: '2026-11-29',
    kind: 'cutoff',
  },
  {
    id: 'q2',
    label: 'Quiz 2 (In person centres)',
    short: 'Quiz 2',
    date: '2026-12-05',
    kind: 'exam',
    exam: 'Quiz 2',
  },
  {
    id: 'w10',
    label: 'GAA calculation closes (W10)',
    short: 'GAA cutoff',
    date: '2026-12-13',
    kind: 'cutoff',
  },
  {
    id: 'o2_d1',
    label: 'OPPE 2 Day 1',
    short: 'OPPE 2 (D1)',
    date: '2026-12-20',
    kind: 'exam',
    exam: 'OPPE',
  },
  {
    id: 'w12',
    label: 'Week 11 & 12 assignments due',
    short: 'W12 due',
    date: '2026-12-23',
    kind: 'due',
  },
  {
    id: 'o2_d2',
    label: 'OPPE 2 Day 2',
    short: 'OPPE 2 (D2)',
    date: '2027-01-03',
    kind: 'exam',
    exam: 'OPPE',
  },
  {
    id: 'et',
    label: 'End term exam (In person)',
    short: 'End term',
    date: '2027-01-10',
    kind: 'exam',
    exam: 'End term',
  },
].map((d) => ({ ...d, at: new Date(`${d.date}T09:00:00+05:30`) }));

export const DAY = 86400000;
export const daysUntil = (d) => Math.ceil((d - TODAY) / DAY);
export const currentWeek = Math.max(
  1,
  Math.min(TERM.weeks, Math.floor((TODAY - TERM.start) / (7 * DAY)) + 1)
);
export const nextDate = DATES.find((d) => d.at > TODAY);
export const nextExam = DATES.find((d) => d.at > TODAY && d.kind === 'exam');

export const fmtDate = (d) =>
  d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', timeZone: 'Asia/Kolkata' });

// Official links from IITM & the official Sep 2026 Student Grading Document.
export const TOOLS = [
  {
    id: 'portal',
    label: 'Student portal',
    hint: 'Dashboard, marks & registration',
    href: 'https://app.onlinedegree.iitm.ac.in/',
    icon: 'portal',
  },
  {
    id: 'grading_doc',
    label: 'Sep 2026 Grading Doc',
    hint: 'Official exam schedule & formulas',
    href: 'https://docs.google.com/document/d/e/2PACX-1vT_FeqnTq0Br4sUaN7OYAmj1B9MwjchyTEed1Bh5FkZvi5NyIMeAvvkuttostVsJBPjZcs3SjjEfiho/pub',
    icon: 'book',
  },
  {
    id: 'oppe_sop',
    label: 'OPPE SCT SoP',
    hint: 'System compatibility test guide',
    href: 'https://docs.google.com/document/d/e/2PACX-1vS4Hhh4MsKD2WL8_D26Vw2WJKw0CBtPihZyKrnEM_kefRXm_O75GqTcJA6lR0X_xCiVL5gUi5y6_bjw/pub',
    icon: 'cert',
  },
  {
    id: 'discourse',
    label: 'Discourse',
    hint: 'Course forums & badges',
    href: 'https://discourse.onlinedegree.iitm.ac.in/',
    icon: 'chat',
  },
  {
    id: 'handbook',
    label: 'Student handbook',
    hint: 'Rules, grading, policies',
    href: 'https://study.iitm.ac.in/ds/academics.html',
    icon: 'book',
  },
  {
    id: 'verify',
    label: 'Verify certificate',
    hint: 'House event certificates',
    href: '#/verify-certificate',
    icon: 'seal',
    internal: true,
  },
];

export const WHATSAPP = 'https://www.whatsapp.com/channel/0029Vb83wumAzNc2qMQOQX0b';
