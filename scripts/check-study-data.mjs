// Validates the Study Corner data in src/data/study/courses/ (`npm run check:study`).
// Contributors, often with weak AI tools, edit these files by hand; this check is what keeps a bad
// edit from reaching the site. Every error names the file, the entry and the fix.
import { readdirSync, readFileSync } from 'node:fs';
import { STUDY_LEVELS } from '../src/data/study/levels.js';
import { parseTerm } from '../src/lib/pyq-title.js';

const DIR = 'src/data/study/courses';
const COURSE_KEYS = ['code', 'subject', 'description', 'notes', 'pyqs'];
const ENTRY_KEYS = ['title', 'link'];
const known = new Set(Object.values(STUDY_LEVELS).flat());
const errors = [];
const totals = { courses: 0, notes: 0, pyqs: 0 };

const sameKeys = (obj, keys) =>
  obj && typeof obj === 'object' && !Array.isArray(obj) && Object.keys(obj).join() === keys.join();
const text = (v) => typeof v === 'string' && v.trim() === v && v.length > 0;

function checkEntry(file, list, i, entry, seen) {
  const at = `${file} → ${list}[${i}]`;
  if (!sameKeys(entry, ENTRY_KEYS)) {
    errors.push(
      `${at}: each entry must be exactly { "title": "...", "link": "..." }, in that order.`
    );
    return;
  }
  const { title, link } = entry;
  if (!text(title) || title.length > 200) {
    errors.push(`${at}: "title" must be 1–200 characters with no spaces at either end.`);
  }
  let url = null;
  try {
    url = new URL(link);
  } catch {
    // reported below
  }
  if (!url || url.protocol !== 'https:' || /\s/.test(link)) {
    errors.push(`${at}: "link" must be a full https:// share link (got ${JSON.stringify(link)}).`);
  }
  if (list === 'pyqs' && text(title) && !parseTerm(title)) {
    errors.push(
      `${at}: PYQ title "${title}" needs the term's month and year, e.g. "Quiz 1 (Jan 2025) QP1".`
    );
  }
  const key = `${title}\n${link}`;
  if (seen.has(key))
    errors.push(`${at}: exact duplicate of ${list}[${seen.get(key)}]; remove one.`);
  else seen.set(key, i);
}

const files = readdirSync(DIR);
for (const file of files) {
  const code = file.replace(/\.json$/, '');
  if (!file.endsWith('.json') || !known.has(code)) {
    errors.push(
      `${DIR}/${file}: unexpected file. Only existing course files belong here; new courses are added by a maintainer.`
    );
    continue;
  }
  let course;
  try {
    course = JSON.parse(readFileSync(`${DIR}/${file}`, 'utf8'));
  } catch (e) {
    errors.push(
      `${file}: not valid JSON (${e.message}). Check for a missing comma, quote or bracket.`
    );
    continue;
  }
  if (!sameKeys(course, COURSE_KEYS)) {
    errors.push(
      `${file}: top level must have exactly the keys ${COURSE_KEYS.join(', ')}, in that order.`
    );
    continue;
  }
  if (course.code !== code)
    errors.push(`${file}: "code" must be "${code}" to match the file name.`);
  for (const k of ['subject', 'description']) {
    if (!text(course[k])) errors.push(`${file}: "${k}" must be non-empty text.`);
  }
  for (const list of ['notes', 'pyqs']) {
    if (!Array.isArray(course[list])) {
      errors.push(`${file}: "${list}" must be a list [ ... ].`);
      continue;
    }
    const seen = new Map();
    course[list].forEach((entry, i) => checkEntry(file, list, i, entry, seen));
    totals[list] += course[list].length;
  }
  totals.courses++;
}
for (const code of known) {
  if (!files.includes(`${code}.json`)) errors.push(`${DIR}/${code}.json is missing.`);
}

if (errors.length) {
  console.error(`✘ Study data has ${errors.length} problem(s):\n`);
  for (const e of errors) console.error(`  - ${e}`);
  console.error('\nFix every line above, then run `npm run check:study` again.');
  process.exit(1);
}
console.log(
  `✔ Study data OK: ${totals.courses} courses, ${totals.notes} notes, ${totals.pyqs} PYQs.`
);
