// Builds src/data/contributors.json for the Contributors page from the GitHub REST API.
// Run by hand when the page should show fresh numbers; the page only reads the JSON.
// Usage: GITHUB_TOKEN=$(gh auth token) npm run contributors:snapshot
// It writes src/data/contributors.json and prints nothing else. Never print the token.
import { writeFileSync } from 'node:fs';

const REPO = 'SundarbansWebOps/SundarbansWeb';
const BRANCH = 'main';
const SINCE = '2026-07-01T00:00:00+05:30'; // current web-admin tenure
const FOLD = { 'sundarbans-webad': 'Anuraj-dev' }; // web-admin account belongs to Raja
const EXCLUDE = new Set(['Code-Samar']); // previous tenure (handover commits)
// Generated files would swamp the line counts.
const SKIP_FILE = /(^|\/)(package-lock\.json|pnpm-lock\.yaml|yarn\.lock|bun\.lockb?)$/;

const token = process.env.GITHUB_TOKEN;
if (!token) throw new Error('GITHUB_TOKEN is required');

async function gh(path) {
  const res = await fetch(path.startsWith('http') ? path : `https://api.github.com${path}`, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    },
  });
  if (!res.ok) throw new Error(`${res.status} ${path}: ${await res.text()}`);
  const next = /<([^>]+)>;\s*rel="next"/.exec(res.headers.get('link') || '')?.[1];
  return { body: await res.json(), next };
}
async function all(path) {
  const out = [];
  for (let url = path; url;) {
    const { body, next } = await gh(url);
    out.push(...(Array.isArray(body) ? body : body.items));
    url = next;
  }
  return out;
}
async function pool(items, n, fn) {
  const out = new Array(items.length);
  let i = 0;
  await Promise.all(
    Array.from({ length: n }, async () => {
      while (i < items.length) {
        const k = i++;
        out[k] = await fn(items[k]);
      }
    })
  );
  return out;
}

const who = (login) => FOLD[login] ?? login;
const credited = (u) =>
  u && u.type !== 'Bot' && !u.login.endsWith('[bot]') && !EXCLUDE.has(who(u.login));

const since = new Date(SINCE);
const now = new Date();
const WEEK = 7 * 864e5;
const weekCount = Math.floor((now - since) / WEEK) + 1;
const weekOf = (iso) => Math.min(weekCount - 1, Math.floor((new Date(iso) - since) / WEEK));
const weekStarts = Array.from({ length: weekCount }, (_, w) =>
  new Date(+since + w * WEEK + 5.5 * 36e5).toISOString().slice(0, 10)
);

const people = new Map();
const person = (login) => {
  if (!people.has(login))
    people.set(login, {
      login,
      commits: 0,
      mergedPRs: 0,
      additions: 0,
      deletions: 0,
      weeks: Array.from({ length: weekCount }, () => ({ c: 0, a: 0, d: 0 })),
      first: null,
      last: null,
    });
  return people.get(login);
};

// Non-merge commits on main since the tenure began, credited to the GitHub author.
const list = (
  await all(`/repos/${REPO}/commits?sha=${BRANCH}&since=${encodeURIComponent(SINCE)}&per_page=100`)
).filter((c) => c.parents.length === 1 && credited(c.author));
const details = await pool(list, 8, (c) =>
  gh(`/repos/${REPO}/commits/${c.sha}`).then((r) => r.body)
);
for (const c of details) {
  const p = person(who(c.author.login));
  const at = c.commit.author.date;
  let a = 0,
    d = 0;
  for (const f of c.files ?? [])
    if (!SKIP_FILE.test(f.filename)) {
      a += f.additions;
      d += f.deletions;
    }
  const w = p.weeks[weekOf(at)];
  w.c++;
  w.a += a;
  w.d += d;
  p.commits++;
  p.additions += a;
  p.deletions += d;
  const day = at.slice(0, 10);
  if (!p.first || day < p.first) p.first = day;
  if (!p.last || day > p.last) p.last = day;
}

// Merged PRs, counted separately from commits.
const prs = await all(
  `/search/issues?q=${encodeURIComponent(`repo:${REPO} is:pr is:merged merged:>=${SINCE.slice(0, 10)}`)}&per_page=100`
);
for (const pr of prs) if (credited(pr.user)) person(who(pr.user.login)).mergedPRs++;

const users = await pool([...people.keys()], 8, (l) => gh(`/users/${l}`).then((r) => r.body));
const contributors = users
  .map((u) => ({
    ...people.get(u.login),
    name: u.name || u.login,
    avatar: `https://avatars.githubusercontent.com/u/${u.id}?s=160`,
    profile: u.html_url,
  }))
  .sort((x, y) => y.additions + y.deletions - (x.additions + x.deletions));

const out = new URL('../src/data/contributors.json', import.meta.url);
writeFileSync(
  out,
  JSON.stringify(
    {
      repo: REPO,
      since: SINCE.slice(0, 10),
      generatedAt: now.toISOString(),
      weekStarts,
      contributors,
    },
    null,
    1
  ) + '\n'
);
console.log(`Wrote ${contributors.length} contributor(s) to src/data/contributors.json`);
