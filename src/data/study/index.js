// Study Corner notes and PYQs: one JSON file per course in ./courses/, grouped and ordered by
// ./levels.js. Contributors edit only the JSON files; `npm run check:study` validates them.
import { STUDY_LEVELS } from './levels.js';

const files = import.meta.glob('./courses/*.json', { eager: true, import: 'default' });
const byCode = Object.fromEntries(Object.values(files).map((c) => [c.code, c]));

export default Object.fromEntries(
  Object.entries(STUDY_LEVELS).map(([level, codes]) => [level, codes.map((code) => byCode[code])])
);
