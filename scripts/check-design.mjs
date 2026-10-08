// Design guard (`npm run check:design`). Catches the ways a change drifts from the site's
// design system: raw colours instead of tokens, a new typeface, unscoped styles, invented
// breakpoints, `!important`. Existing hand-painted art (Pat plates on Home, the Lounge) keeps its
// own colours, recorded per file in scripts/design-baseline.json; a file may only go down.
// `--update` lowers the baseline after colours are moved onto tokens; it never raises it.
import { readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';

const ROOT = 'src';
const TOKENS = 'src/assets/tokens.css';
const BASELINE = 'scripts/design-baseline.json';
// Every max/min-width used on the site. A new layout reuses one of these.
const BREAKPOINTS = new Set([560, 640, 760, 761, 860, 900, 1020]);
const FONT_OK = /^(var\(--font\)|var\(--mono\)|inherit)$/;

const RAW_COLOR =
  /#(?:[0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3,4})\b|\b(?:rgba?|hsla?|hwb|lab|lch|oklab|oklch)\(/g;
const NAMED_COLOR =
  /\b(?:color|background(?:-color)?|border(?:-[a-z]+)*|fill|stroke|outline(?:-color)?|(?:box|text)-shadow)\s*:[^;{}]*?\b(?:white|black|red|green|blue|yellow|orange|purple|pink|gr[ae]y|silver|navy|teal|lime|olive|maroon|aqua|cyan|magenta|fuchsia|gold|brown|violet|indigo)\b/g;

function walk(dir) {
  return readdirSync(dir).flatMap((name) => {
    const p = `${dir}/${name}`; // forward slashes on every OS, to match the baseline keys
    return statSync(p).isDirectory() ? walk(p) : /\.(vue|js|css)$/.test(p) ? [p] : [];
  });
}

// The Members Lounge is its own painted world: its own palette, self-hosted Anek Latin (the name
// fitter needs the width axis), global theme styles and breakpoints. The guard covers the public site.
const isLounge = (file) =>
  file.startsWith('src/components/lounge/') ||
  file === 'src/pages/LoungePage.vue' ||
  file === 'src/pages/LoginPage.vue';

const errors = [];
const counts = {};
for (const file of walk(ROOT)) {
  if (file === TOKENS || isLounge(file)) continue;
  const src = readFileSync(file, 'utf8');
  const lineOf = (i) => src.slice(0, i).split('\n').length;
  const c = {
    colors: (src.match(RAW_COLOR) ?? []).length + (src.match(NAMED_COLOR) ?? []).length,
    important: (src.match(/!important/g) ?? []).length,
  };
  if (c.colors || c.important) counts[file] = c;

  for (const m of src.matchAll(/font-family:\s*([^;}]+)/g)) {
    if (!FONT_OK.test(m[1].trim())) {
      errors.push(
        `${file}:${lineOf(m.index)}: font-family "${m[1].trim()}". Use var(--font) (Anek Latin) or var(--mono).`
      );
    }
  }
  for (const m of src.matchAll(/@import|@font-face|fonts\.googleapis/g)) {
    errors.push(
      `${file}:${lineOf(m.index)}: "${m[0]}". The site loads one typeface, in index.html; add no fonts or stylesheets.`
    );
  }
  for (const m of src.matchAll(/@media[^{]*?(?:max|min)-width:\s*(\d+)px/g)) {
    if (!BREAKPOINTS.has(Number(m[1]))) {
      errors.push(
        `${file}:${lineOf(m.index)}: breakpoint ${m[1]}px. Reuse one of ${[...BREAKPOINTS].join(', ')}px.`
      );
    }
  }
  if (file.endsWith('.vue')) {
    for (const m of src.matchAll(/<style(?![^>]*\bscoped\b)[^>]*>/g)) {
      errors.push(
        `${file}:${lineOf(m.index)}: <style> must be <style scoped>; shared styles live in ${TOKENS}.`
      );
    }
  }
}

const baseline = JSON.parse(readFileSync(BASELINE, 'utf8'));
const over = [];
for (const [file, c] of Object.entries(counts)) {
  const b = baseline[file] ?? { colors: 0, important: 0 };
  if (c.colors > b.colors) {
    over.push(
      `${file}: ${c.colors} raw colour value(s), allowed ${b.colors}. Use the tokens in ${TOKENS} (var(--ink), var(--mari), …) instead of hex/rgb/hsl.`
    );
  }
  if (c.important > b.important) {
    over.push(
      `${file}: ${c.important} !important, allowed ${b.important}. Raise the selector's specificity instead.`
    );
  }
}
errors.push(...over);

if (process.argv.includes('--update')) {
  if (over.length) {
    console.error('✘ --update only lowers the baseline. Fix these first:\n');
    for (const e of over) console.error(`  - ${e}`);
    process.exit(1);
  }
  const next = Object.fromEntries(Object.entries(counts).sort(([a], [b]) => a.localeCompare(b)));
  writeFileSync(BASELINE, JSON.stringify(next, null, 2) + '\n');
  console.log(`Baseline updated: ${Object.keys(next).length} file(s).`);
}

if (errors.length) {
  console.error(`✘ Design check found ${errors.length} problem(s):\n`);
  for (const e of errors) console.error(`  - ${e}`);
  console.error(
    '\nFix every line above (see .agents/skills/sundarbans-design/SKILL.md), then run `npm run check:design` again.'
  );
  process.exit(1);
}
console.log('✔ Design check OK.');
