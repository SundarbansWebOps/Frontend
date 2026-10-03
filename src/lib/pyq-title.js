// Reads the exam and term out of a PYQ title, e.g. "Quiz 1 (Jan 2025) QP1".
// Shared by the course adapter and scripts/check-study-data.mjs, so a title the checker
// accepts is a title the site can place on the term strip.
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

export function parseTerm(title) {
  const m = title.match(
    /\b(jan(?:uary)?|feb|march|mar|apr|may|jun|jul|aug|sept(?:ember)?|sep|oct|nov|dec)[a-z]*\.?\s*[-']?\s*(20\d{2}|\d{2})\b/i
  );
  if (!m) return null;
  const month = MONTHS[m[1].toLowerCase()] ?? MONTHS[m[1].slice(0, 3).toLowerCase()];
  let year = Number(m[2]);
  if (year < 100) year += 2000;
  return { month, year, label: `${MONTH_NAME[month]} ${year}`, sort: year * 100 + month };
}

export function parseExam(title) {
  const t = title.toLowerCase();
  if (/oppe/.test(t)) return 'OPPE';
  if (/quiz\s*-?\s*2|qz\s*2|\bq2\b/.test(t)) return 'Quiz 2';
  if (/quiz\s*-?\s*1|qz\s*1|\bq1\b/.test(t)) return 'Quiz 1';
  if (/qualifier/.test(t)) return 'Qualifier';
  if (/end\s*-?\s*term|endterm|\bet\b/.test(t)) return 'End term';
  return 'Other';
}
