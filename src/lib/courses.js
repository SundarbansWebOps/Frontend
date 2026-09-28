// Adapts the real Study Corner dump into course-shaped data.
// Notes and PYQs are the real Drive links. Lecture entries are dropped: every one is a
// "#" placeholder. Term dates below are SAMPLE data until the Supabase
// important_dates table is wired in.
import raw from '../data/scData_generated.js';

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

const MONTHS = {
  jan: 1,
  feb: 2,
  mar: 3,
  march: 3,
  apr: 4,
  may: 5,
  jun: 6,
  jul: 7,
  aug: 8,
  sep: 9,
  sept: 9,
  september: 9,
  oct: 10,
  nov: 11,
  dec: 12,
  january: 1,
};
const MONTH_NAME = [
  '',
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

function parseTerm(title) {
  const m = title.match(
    /\b(jan(?:uary)?|feb|march|mar|apr|may|jun|jul|aug|sept(?:ember)?|sep|oct|nov|dec)[a-z]*\.?\s*[-']?\s*(20\d{2}|\d{2})\b/i
  );
  if (!m) return null;
  const month = MONTHS[m[1].toLowerCase()] ?? MONTHS[m[1].slice(0, 3).toLowerCase()];
  let year = Number(m[2]);
  if (year < 100) year += 2000;
  return { month, year, label: `${MONTH_NAME[month]} ${year}`, sort: year * 100 + month };
}

function parseExam(title) {
  const t = title.toLowerCase();
  if (/oppe/.test(t)) return 'OPPE';
  if (/quiz\s*-?\s*2|qz\s*2|\bq2\b/.test(t)) return 'Quiz 2';
  if (/quiz\s*-?\s*1|qz\s*1|\bq1\b/.test(t)) return 'Quiz 1';
  if (/qualifier/.test(t)) return 'Qualifier';
  if (/end\s*-?\s*term|endterm|\bet\b/.test(t)) return 'End term';
  return 'Other';
}

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
    const notes = (s.resources.notes ?? []).filter((n) => n.link && n.link !== '#').map(parseNote);
    const pyqs = (s.resources.pyq ?? [])
      .filter((p) => p.link && p.link !== '#')
      .map(parsePyq)
      .sort((a, b) => (b.term?.sort ?? 0) - (a.term?.sort ?? 0));
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

// ---- SAMPLE term calendar (Sep 2026 term). Replace with Supabase important_dates. ----
export const TODAY = new Date('2026-09-27T10:00:00+05:30');
export const TERM = {
  label: 'Sep 2026 term',
  start: new Date('2026-09-07T00:00:00+05:30'),
  end: new Date('2026-12-20T00:00:00+05:30'),
  weeks: 12,
};
export const DATES = [
  { id: 'a3', label: 'Week 3 assignments due', short: 'W3 due', date: '2026-10-01', kind: 'due' },
  { id: 'q1', label: 'Quiz 1', short: 'Quiz 1', date: '2026-10-18', kind: 'exam', exam: 'Quiz 1' },
  { id: 'o1', label: 'OPPE 1', short: 'OPPE 1', date: '2026-10-25', kind: 'exam', exam: 'OPPE' },
  { id: 'q2', label: 'Quiz 2', short: 'Quiz 2', date: '2026-11-22', kind: 'exam', exam: 'Quiz 2' },
  {
    id: 'et',
    label: 'End term',
    short: 'End term',
    date: '2026-12-20',
    kind: 'exam',
    exam: 'End term',
  },
].map((d) => ({ ...d, at: new Date(`${d.date}T09:00:00+05:30`) }));

export const DAY = 86400000;
export const daysUntil = (d) => Math.ceil((d - TODAY) / DAY);
export const currentWeek = Math.min(TERM.weeks, Math.floor((TODAY - TERM.start) / (7 * DAY)) + 1);
export const nextDate = DATES.find((d) => d.at > TODAY);
export const nextExam = DATES.find((d) => d.at > TODAY && d.kind === 'exam');

export const fmtDate = (d) =>
  d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', timeZone: 'Asia/Kolkata' });

// Important links. External ones are real IITM portals; `soon` ones are not built yet.
export const TOOLS = [
  {
    id: 'portal',
    label: 'Student portal',
    hint: 'Dashboard, marks',
    href: 'https://app.onlinedegree.iitm.ac.in/',
    icon: 'portal',
  },
  {
    id: 'discourse',
    label: 'Discourse',
    hint: 'Course forums',
    href: 'https://discourse.onlinedegree.iitm.ac.in/',
    icon: 'chat',
  },
  {
    id: 'grade',
    label: 'Grade calculator',
    hint: 'What you need in the end term',
    href: '#grade',
    icon: 'calc',
    internal: true,
    soon: true,
  },
  {
    id: 'handbook',
    label: 'Student handbook',
    hint: 'Rules, grading, policies',
    href: 'https://study.iitm.ac.in/ds/academics.html',
    icon: 'book',
  },
  {
    id: 'cities',
    label: 'Exam cities',
    hint: 'Centres near you',
    href: '#cities',
    icon: 'pin',
    internal: true,
    soon: true,
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
