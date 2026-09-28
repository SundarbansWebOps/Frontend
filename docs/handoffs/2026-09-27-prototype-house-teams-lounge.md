# Handoff — 2026-09-27: prototype site (Resources · Events · House · Teams · Lounge)
> For the next agent. Read `docs/STATE.md` first, then this. The prototype and today's new docs are
> committed on branch `feat/prototype-site-delta`; `docs/STATE.md`, `INDEX.md` and `decisions.md` also carry
> older sessions' uncommitted edits, so they were left uncommitted.

## Where we are
Raja and the agent spent 2026-09-27 building a **throwaway, motion-heavy prototype** of the student-first
Sundarbans site in `prototype/resource-hub/` (Vue 3 SFCs served by the repo's Vite). Raja reviewed each
round and is happy with the direction ("gradually improving our web page"). Round 3 (House fixes, new
Teams page, new Lounge tab, font trial) is built and verified; **Raja has not given feedback on round 3
yet — that is the first thing to get tomorrow.**

Open it: `npx vite --port 5190` from the repo root (node:
`~/.local/share/mise/installs/node/26.8.1/bin` — the mise shim is broken), then
`http://localhost:5190/prototype/resource-hub/?page=house` (pages: default Resources, `events`, `house`,
`teams`, `lounge`). `t` toggles dark, `f` cycles the typeface (`?font=anek|familjen|schibsted`).
A dev server was left running on 5190 (PID 2545324, started by the agent) — it may be gone after a reboot.

## What each page is (round by round)
1. **Resources** — direction "Delta" chosen (variant A; B/C deleted). Degree drawn as a river delta that is
   also the course navigator; search, pinned "My courses", term strip. Data from `src/data/scData_generated.js`.
2. **Events** — past-events archive only (live events live in the Lounge). Season "swell" chart +
   month log. **Winners removed** (council to decide). Meetups moved out to House. Each event links to the
   Lounge certificate demo.
3. **House** — About story (procedural mangrove; draft copy, members will write the real text) →
   **Upper House Council only** (3 cards fan out + flip on scroll; "Meet the teams" strip) → Where we meet
   (region constellation + season playback; meetups with photos pop polaroids that fly into a photo roll;
   region panel with photo stacks; full-screen `PhotoViewer`) → lounge door teaser ("Take the tour").
   Magazine card removed (Raja: not live right now).
4. **Teams** (new) — "How the house works" as a river delta that draws on scroll (`HouseFlow.vue`), UHC,
   Lower House Council (9 coordinators, dealt cards), Communities (Cultural/Technical/E-Sports → Events
   filtered by wing), Crew (PR & Outreach, Graphic Design, WebOps). Rosters empty ("Roster coming"
   seats) until Raja supplies names/photos → `teams.js`.
5. **Lounge** (new tab, lit pill in nav, no lock icons — Raja dislikes them) — always-dark tour of the
   members-only rooms as demos on labelled SAMPLE data: Live events, Night Owl (real IST clock),
   Regional groups (real regions/coordinators), Leaderboard (blurred names), Certificates (type a name →
   written onto a SAMPLE certificate). Sign-in is a toast; not wired.

## Fixes made in round 3 (don't regress)
- Card tilt flicker on the region chip: tilt reads the untilted wrapper and freezes over buttons/links
  (`PersonCard.vue`).
- Names on one line, one size per row (`fit.js`, `useFitNames`).
- Scoped-style leak: a parent's class on a child component's root gets the parent's scoped styles
  (LoungePage `.night` stretched `SectionRail`) — page class renamed `.lp`.
- Google Photos meetup links: 4 dead at source, and Google blocks request bursts (`ERR_BLOCKED_BY_ORB`) →
  preloads staggered, failures retried once, then the photo is dropped (`markDead` in `house.js`).

## Waiting on Raja / the council
- **Feedback on round 3** (House trio motion, Teams delta, Lounge tour, photo roll).
- **Pick the typeface** (Anek Latin default vs Familjen Grotesk vs Schibsted Grotesk), then remove the
  switcher and hard-code it.
- Council agenda in `docs/council-questions.md`: certificate generator inputs (signatures, attendance
  lists), whether winners are public, About copy, the house structure, team rosters, meetup photos to
  Cloudinary, lounge room list, Bengaluru coordinator, International region.
- Raja is fixing data himself: Dark Web event dated 2025 (should be 2026), undated Mumbai/Kolkata/Chennai
  meetups, misspelled partner houses.

## Likely next steps
1. Walk Raja through round 3, apply feedback.
2. Remaining nav destination not yet prototyped: Verify (removed from nav; belongs in footer / cert link).
3. When the direction is settled: capture the prototype on a throwaway branch (prototype skill rule),
   then plan the real build in `src/` — but **don't edit `src/` until the teammate's frontend work lands**.

## Guardrails (unchanged)
- No commits/pushes unless Raja asks; never on `main`; no AI attribution in commits/PRs.
- Don't touch `src/`; don't stop containers on ports 5432x; stop only processes you started.
- No stock/AI/placeholder images; warm palette, no green; light + dark; reduced-motion fallbacks.
- Verify UI with Playwright (`executablePath: '/usr/bin/chromium'`, import from
  `node_modules/playwright/index.mjs`) at 1366 and 390 wide, light + dark; `npx prettier --write prototype/`
  and `npx eslint prototype/` must exit 0.
