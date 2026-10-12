import { execFileSync } from 'node:child_process';
import { check, getFileInfo, resolveConfig } from 'prettier';

const args = process.argv.slice(2);
const rangeIndex = args.indexOf('--range');
const range = rangeIndex >= 0 ? args[rangeIndex + 1] : null;

let files;

try {
  const changedFiles = range
    ? execFileSync('git', ['diff', '--name-only', '--diff-filter=ACMR', range], {
        encoding: 'utf8',
      })
    : execFileSync('git', ['diff', '--name-only', '--diff-filter=ACMR', 'HEAD'], {
        encoding: 'utf8',
      });

  files = changedFiles
    .split(/\r?\n/)
    .filter(Boolean)
    .filter((file) => !file.startsWith('node_modules/'));
} catch {
  console.error('Could not detect changed files.');
  process.exit(1);
}

if (files.length === 0) {
  console.log('No changed files to check.');
  process.exit(0);
}

let failed = false;

for (const file of files) {
  try {
    const info = await getFileInfo(file);

    if (info.ignored || !info.inferredParser) {
      continue;
    }

    const options = (await resolveConfig(file)) ?? {};
    const source = await (await import('node:fs/promises')).readFile(file, 'utf8');
    const formatted = await check(source, {
      ...options,
      filepath: file,
    });

    if (!formatted) {
      console.error(`Formatting issue: ${file}`);
      failed = true;
    } else {
      console.log(`OK: ${file}`);
    }
  } catch (error) {
    console.error(`Could not check ${file}: ${error.message}`);
    failed = true;
  }
}

if (failed) {
  process.exit(1);
}

console.log('All changed files pass Prettier.');
