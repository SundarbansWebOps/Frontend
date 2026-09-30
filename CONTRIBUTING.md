# Contributing to Sundarbans House

Thanks for contributing. This file is the whole onboarding path — clone, run, change, PR — read it
top to bottom and you should be able to open a green PR without asking anyone anything.

## Adding notes and past papers (no coding needed)

Study Corner data lives in `src/data/study/courses/`, one JSON file per course. To add notes or
PYQs:

1. Do **1. Prerequisites** and **2. Setup** below once.
2. Upload the PDFs to Google Drive and share them as "Anyone with the link can view".
3. Open the repo in your AI coding tool (Claude Code, Codex, Gemini CLI, OpenCode, Cursor, …) and
   say: _"Use the add-study-resources skill to add these to <course>:"_, then paste each title and
   link. Tools that don't load skills still find it through `AGENTS.md`; you can also point them at
   `.agents/skills/add-study-resources/SKILL.md`.
4. The tool edits the course file, runs `npm run check:study`, and opens a pull request.

A pull request from a team member may change only files in `src/data/study/courses/`; CI fails
anything else, and every pull request needs a maintainer's approval before it merges.

## 0. Read this first

Before writing any code, read **`docs/STATE.md`** in this repo. It has the current status,
architecture map, and known gotchas (e.g. large committed assets, no lazy-loaded routes). Skipping
it is the #1 way to duplicate work or reintroduce a problem someone already fixed.

## 1. Prerequisites

- [Git](https://git-scm.com/)
- [Node.js](https://nodejs.org/) — this project is developed against **Node v22**. Use
  [nvm](https://github.com/nvm-sh/nvm) or similar if you need to manage versions.
- No backend and no database — the app is fully client-side. Optional env: copy
  `.env.example` to `.env` if you need Google OAuth login. Variables (see
  `.env.example`):
  - `VITE_GOOGLE_CLIENT_ID` — Google OAuth client ID.
  - `VITE_MEMBERSHIP_CHECK_URL` — Apps Script `/exec` URL that validates member
    emails against the Sheet. **Required for login** (build-time Vite env; set on
    Vercel Production and in local `.env` for lounge testing). If missing, login
    fails with a clear config error. There is no local members roster file.
    Without OAuth/membership env the rest of the site still runs; lounge login will not.

## 2. Setup

1. Fork the repo on GitHub.
2. Clone your fork:
   ```bash
   git clone https://github.com/<your-username>/Frontend.git
   cd Frontend
   ```
3. Install dependencies:
   ```bash
   npm install
   ```
4. (Optional) Set up OAuth env if you need login:
   ```bash
   cp .env.example .env
   ```
   Edit `.env` only if you have your own Google client ID; the example value is
   fine for local exploration of non-OAuth pages. Set `VITE_MEMBERSHIP_CHECK_URL`
   for lounge login (Sheet membership check).
5. Start the dev server:
   ```bash
   npm run dev
   ```
   Vite will print a local URL (default `http://localhost:5173`) — open it in a browser.

## 3. The real npm scripts

These are the only scripts that exist in `package.json`. Do not invent or reference others —
`npm run serve` in particular does **not** exist here.

| Command                | What it does                                                      |
| ---------------------- | ----------------------------------------------------------------- |
| `npm run dev`          | Start the Vite dev server with hot reload                         |
| `npm run build`        | Production build (output to `dist/`)                              |
| `npm run preview`      | Serve the built `dist/` output locally, to sanity-check a build   |
| `npm run lint`         | ESLint over the repo                                              |
| `npm run format`       | Prettier write                                                    |
| `npm run format:check` | Prettier check (no write)                                         |
| `npm run test:smoke`   | Playwright route smoke (needs a prior `npm run build` + Chromium) |

## 4. Making a change

1. Create a branch off `main` in your fork (never commit directly to `main`):
   ```bash
   git checkout -b your-feature-branch
   ```
2. Make your change. See **SFC convention** below before touching `.vue` files.
3. Run the local gates (same checks CI runs):
   ```bash
   npm run format:check
   npm run lint
   npm run build
   # first time only: npx playwright install chromium
   npm run test:smoke
   ```
4. Stage and commit with a clear, descriptive message:
   ```bash
   git add .
   git commit -m "Describe your change clearly"
   ```
5. Push the branch to your fork (first push sets upstream):
   ```bash
   git push -u origin your-feature-branch
   ```
6. Open a pull request from your fork/branch against `Anuraj-dev/Frontend`'s `main`. Describe what
   changed and why.
7. A repo owner reviews and approves. Contributors do not merge their own PRs and never push
   directly to `main` — everything goes through fork -> branch -> PR -> owner approval.
8. **Merges require green CI.** Do not merge around a red status — fix format, lint, build, or
   route smoke failures first. Locally, the commands in step 3 match what GitHub Actions runs.

## 5. SFC convention

- **New components: use `<script setup>`.** It's the standard for anything you add from now on.
- **Existing Options API components stay as-is.** Do not rewrite an existing component's script
  block to `<script setup>` just because you're touching that file for an unrelated change —
  that turns a small diff into a large one and makes review harder. Only convert a component when
  the ticket you're working on is specifically about that component.

## 6. Asset policy

This repo has previously accumulated tens of megabytes of committed binary assets, which is why
it's being actively slimmed down. Follow this policy for anything new:

- **PDFs (certificates, documents, etc.) go to Google Drive**, not into the repo. Link to them
  instead of committing them.
- **Images go to Cloudinary** (or another external asset host), not into `public/` or
  `src/assets/`. Reference the hosted URL in code.
- **Nothing heavy gets committed to git.** If you're unsure whether an asset counts as "heavy",
  ask before committing it rather than after.

## Issues & bug reports

- Check the [issue tracker](https://github.com/Anuraj-dev/Frontend/issues) before starting work,
  and check whether an issue is already assigned before picking it up.
- Bug reports should include a clear description and steps to reproduce.
- Feature ideas should be opened as an issue for discussion before a large PR.
