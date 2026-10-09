# Conventions — Sundarbans House
- Stack: Vue 3 (SFC) · vue-router 4 (hash history) · Vite 6 · Supabase (`@supabase/supabase-js`, pinned) · no TypeScript
- Run the app: `npm run dev`
- Build: `npm run build` · Preview build: `npm run preview`
- Local gates (same idea as CI): `npm run format:check` · `npm run lint` · `npm run build` · `npm run test:smoke` (Playwright route smoke; needs prior build + Chromium)
- Env: copy `.env.example` → `.env` (optional; Supabase defaults to production). Members sign in with Google through Supabase Auth; see `docs/specs/003-admin-lounge-and-sign-in.md`. `VITE_GOOGLE_CLIENT_ID` / `VITE_MEMBERSHIP_CHECK_URL` are retired.
- Supabase calls: only through `src/lib/supabase.js` (lazy) via `src/lib/auth.js` / `src/lib/admin.js`. Browser tests mock Supabase (`e2e/supabase-mock.js`); never point tests at the live project.
- Theme: light/dark via `data-theme` on `<html>` (`src/lib/theme.js` + inline script in `index.html`); colours are tokens in `src/assets/tokens.css`. Typeface: Anek Latin.
- Naming / structure notes:
  - Pages live in `src/pages/` and are named `*Page.vue`; their components in `src/components/site/`; shared state and data adapters in `src/lib/` (`store.js`, `events.js`, `house.js`, `courses.js`, `theme.js`).
  - All routes are declared in one file: `src/router/index.js` (lazy `import()` per page — keep paths as literal strings for Vite chunking).
  - `src/assets/` = assets processed/bundled by Vite (import them); `public/` = served as-is at the root URL.
  - Study Corner notes/PYQs: one JSON per course in `src/data/study/courses/`, order in `src/data/study/levels.js`; `npm run check:study` validates them (CI too). Team members add them via `.agents/skills/add-study-resources/`.
  - Design guard: `npm run check:design` (tokens only, one typeface, scoped styles, known breakpoints; a per-file ratchet in `scripts/design-baseline.json` for the painted art's own colours) and `npm run shots` (every page, light/dark, desktop/phone, fails on sideways scroll). Rules for agents: `.agents/skills/sundarbans-design/`.
  - Static data as JSON/CSV/JS in `src/data/`, `public/data/`, and per-region meetup exports in `src/data/meetups/json/`. No committed members roster.
  - Certificates live on Google Drive (URLs in code/data), not under `public/certificates/`.
  - Display images live on Cloudinary (delivery transforms in URL). Dump new files in `media/` and run `npm run media:sync`; copy URLs from `media/manifest.json`. Hero frames stay in `public/assets/frames/`.
- Workflow: changes land via GitHub PRs (repo `Anuraj-dev/Frontend`, branch `main`). See `CONTRIBUTING.md` for the full onboarding path.

