# Decisions — Sundarbans House
> Append-only log of load-bearing choices and WHY. Newest at the bottom.
> Format: `## YYYY-MM-DD — <decision>` then a short **Why:** line.

## 2026-07-11 — No backend; fully client-side app (inferred at adoption)
**Why:** Site is served as a static Vite build; "auth" is a localStorage token gate (`sundarbans_auth_token`), not server-verified. Keeps hosting simple and free.

## 2026-07-11 — Hash-based routing via `createWebHashHistory` (inferred at adoption)
**Why:** Works on plain static hosting without server-side rewrite rules for deep links.

## 2026-07-11 — All routes eagerly imported in `src/router/index.js` (inferred at adoption)
**Why:** Not clearly a deliberate performance choice — every view is statically imported, so the whole app ships in the initial bundle. Flagged as a latency lever to revisit during the storage/perf overhaul.
**Superseded:** routes are now lazy-loaded (see PR #5 / decision below).

## ~2026-07 — Lazy route imports in `src/router/index.js` (PR #5)
**Why:** Visitors only download the view chunk they need; homepage no longer pulls the whole app. Vite needs literal static paths in `import()` so each view emits its own chunk.

## 2026-07 — Membership via Apps Script + Google Sheet (T-13); no local roster (PRs #17, #19, #20)
**Why:** Single source of truth in the council Sheet. Client calls `VITE_MEMBERSHIP_CHECK_URL` after Google OAuth. `members.json` removed so prod cannot silently fall back to a stale roster.

## 2026-07 — Certificate PDFs on Google Drive, not in git (T-16; PRs #18, #20)
**Why:** ~89M of PDFs bloated the repo and deploys. Verify flow opens Drive view/export URLs by file id. Do not re-commit certificate binaries.

## 2026-08-05 — Site images on Cloudinary; hero frames stay in-repo
**Why:** Teams/events/regions (~40M) bloated git and page weight. Cloudinary hosts display images. Homepage 240-frame scroll stays on same-origin (`public/assets/frames/`) for predictable fast scrub. No full backend/admin — team dumps into `media/` and runs `npm run media:sync`.

## 2026-08-05 — Delivery URL transforms + incoming upload compression
**Why:** Raw CDN masters still lag (multi‑MB eager loads). Delivery URLs use `f_auto,q_auto:good,w_1000,c_limit` for bandwidth. Future `media:sync` uploads apply incoming max-1600 + `quality:auto:good` so free-tier **storage** is not filled with phone originals. URL-only transforms do not shrink stored bytes; both layers are intentional.

## 2026-08-05 — Drop Spec 001 T-11 (`docs/ownership.md`)
**Why:** Owner stays with the team long-term and will communicate where configs live when needed. No council-backup / handover / break-glass ownership doc.

## 2026-08-05 — Close Spec 001; cancel remaining tickets
**Why:** Product-visible + HEAD-quality goals are done (membership, Drive certs, Cloudinary, tooling/CI/refactors). Leftovers (history purge, screenshot baseline, size guard, modal cert UI, Apps Script source in repo, fork previews, re-audit, etc.) are optional hygiene — cancelled so the board matches reality and does not invent busywork.

## 2026-09-03 — Review council layouts before live Teams replacement
**Why:** The supplied 2026–27 portraits and roster differ from the current Teams page. A standalone review board lets the visual direction be selected before changing live content; the supplied UHC/LHC structure reference stays local and the portraits use the existing Cloudinary pipeline.

## 2026-09-03 — Match council portraits at native 3:4 ratio
**Why:** The processed portrait sources are 1200×1600. The separate command-deck demo uses 3:4 frames and visible card metadata so portraits are not treated as cropped landscape thumbnails; the technical team block remains deferred until requested.

## 2026-09-03 — Curate command deck: logo socials, no badges/pills, UHC+LHC only
**Why:** Owner feedback after reviewing the command-deck demo: text social links become icon-only brand logos, the 01–09 order badges are noise, the "Leadership"/"Regional" tags must not look pill/peeled, section subtitles are removed, and the demo carries only Upper and Lower House Council (no WebOps/technical block) until a later product decision. Rejected keeping demo scaffolding (roster panel, flow strip, rationale notes) so the review shows the actual design.

## 2026-09-05 — Backend v1 is Supabase, built local-first (no cloud project yet)
**Why:** Free tier fits house scale (500 MB DB, 50k auth MAU, 500k edge function calls, Mumbai region available), and Postgres + RLS maps directly onto the CONTEXT.md role/content-lifecycle model — role checks live in database policies, not app code. Local stack runs on ports 5442x because another local Supabase project (the chatbot backend) binds the 5432x defaults. Schema in `supabase/migrations/`, suite in `backend/test/` (51 checks, all green).

## 2026-09-05 — Member roster source of truth stays the council Google Sheet
**Why:** The council keeps its existing workflow; the `members` table is only a synced copy, written exclusively by the `members-sync` Edge Function (Apps Script authenticates with a shared secret) or a web_admin. The Lounge gate (`is_active_member()`) reads that copy. The real roster is never committed — `seed.sql` carries fake fixtures only.

## 2026-09-05 — Members Lounge ships as a gate only; content tables deferred
**Why:** What the Lounge will display is still undecided (2026-08-29's plan had narrowed the Lounge out entirely; the owner re-included the members-only gate on 2026-09-05). The gate primitives are live now so future lounge tables attach one policy each. The RAG chatbot backend is also out of scope — a teammate is building it separately.

## 2026-09-17 — Homepage decisions start with usefulness, then visual polish
**Why:** The homepage must earn its place by helping a student do something they would actually use. The `5174` variant is the better visual base because it is calmer and easier to scan; `5173` contributes useful live-update ideas, but only real, working actions should be retained.

## 2026-09-27 — Resource Hub direction: "Delta" (prototype variant A); B and C dropped
**Why:** After reviewing three layouts in `prototype/resource-hub/`, the owner chose A: search + term strip up top, pinned "My courses" tickets, and the degree drawn as a river delta (Foundation → Programming / Data Science diplomas → BS degree) that doubles as the course navigator. Palette is warm paper + ink + marigold, no green; light and dark tokens are defined together and every text token is checked at ≥ 4.5:1. The "Desk" (B) and "Index" (C) variants were deleted.

## 2026-09-27 — Public Events page is a past-events archive only
**Why:** House events are for Sundarbans members, so upcoming/live events belong in the members-only House lounge, not the public site. The public page shows what the house has done: a season "swell" chart of every past event, a month-by-month log with posters and winners, and regional meetups on one season axis. Stock photos are not used: events without a real poster get a typographic poster.

## 2026-09-27 — Winners hidden on the public Events page, pending the council
**Why:** Owner removed winner names, trophy counts and winner search from Events until the council decides whether winners are shown publicly (and whether ranks/consent are needed). Open question tracked in `council-questions.md`.

## 2026-09-27 — House page = About + council + where we meet + lounge door; meetups leave Events
**Why:** Meetups are not something a student needs daily, so the owner moved them from Events to House. About is folded into the public House page (copy to be written by members). Regions carry their Lower House coordinator, so council and meetups link to each other. Prototype in `prototype/resource-hub/` (`?page=house`).

## 2026-09-27 — Participation certificates: generator planned for the members' lounge
**Why:** No participation certificates exist today. Feasible design: one signed template per event + an attendance list; a signed-in member generates their own certificate, and its ID is checked on Verify. Build cost is small once lounge sign-in exists; the blockers are council inputs (signing authority, attendance lists), tracked in `council-questions.md`. Each past event links to the lounge meanwhile.

## 2026-09-27 — Teams gets its own page; House shows only the Upper House Council
**Why:** The owner wants the people who keep the house running to have a page of their own. House keeps the three Upper House Council cards (Secretary, Deputy Secretary, Web Admin) and links to Teams. Teams holds "How the house works" (drawn as a river delta), the UHC again, the Lower House Council, the communities and the crew. Rosters for communities and crew show empty seats until the 2026–27 names and photos are supplied; no stand-in faces. The House magazine card was removed until the magazine is live again.

## 2026-09-27 — Lounge is its own top-nav tab, set apart as the members-only feature
**Why:** The owner wants members to feel what's inside before signing in. The Lounge tab is a tour of the rooms (live events, Night Owl, regional groups, leaderboard, certificates) as working demos on labelled sample data; it is lit in the nav without a lock icon. House keeps the lounge door as a teaser. The top nav is now Resources · Events · House · Teams · Lounge; Verify is no longer a nav item (it belongs in the footer / on a certificate's link).

## 2026-09-27 — Typeface under review: Bricolage Grotesque retired
**Why:** The owner flagged Bricolage Grotesque as a common AI-generated-site default. The prototype compares Anek Latin (Ek Type, Mumbai; default), Familjen Grotesk and Schibsted Grotesk live (`?font=`, F key) so the choice is made on real pages.

## 2026-09-28 — Home locked to "Pat"; typeface locked to Anek Latin
**Why:** The owner chose Pat (prototype `?v=2`: the unrolling patachitra scroll) as the home page and Anek Latin (Ek Type, Mumbai) as the site typeface. Synchrony and Current stay only in `prototype/resource-hub/`; the font switcher is gone and Anek Latin is loaded in `index.html` and set as `--font` in `src/assets/tokens.css`.

## 2026-09-28 — The prototype becomes the live site in `src/`, mapped one-to-one
**Why:** The owner asked for the prototype to become the real build. Pat home, Resources, Events, House, Teams and the Lounge tour are ported file-for-file into `src/pages/`, `src/components/site/`, `src/lib/` and `src/data/`; only navigation plumbing changed (vue-router hash routes instead of `?page=`, and course/event sheet URLs go through the router). The nav gains a light/dark toggle: a saved choice wins, otherwise the system setting, applied before first paint. Old URLs redirect to the page that now holds their content (`/study`→Resources, `/about`→House story, `/meetups*`→House regions, `/community`→Teams, `/community/*`→Events filtered by wing, `/contact`→footer, `/dashboard`→Lounge). Verify certificate, login and 404 were rebuilt in the new theme; a shared footer carries Verify, portals and socials.

## 2026-09-28 — Lounge is a tour only; members' sign-in is "coming soon"
**Why:** The owner deferred real sign-in. `/lounge` is the public tour on sample data; every sign-in button shows "coming soon", and `/login` is a themed coming-soon page. The previous Google sign-in, members lounge and dashboard are no longer routed.

## 2026-09-28 — Home ignores the light/dark theme
**Why:** The owner wants the Pat scroll to look exactly as in the prototype in both modes. Only the nav (and the thin footer strip under the scroll) follows the theme; the painting keeps its paper palette and brightness. The unused dark scroll palette was removed.

## 2026-09-28 — Theme switch ripples exactly like Raja's portfolio
**Why:** Raja rejected a soft-edged, wavelet ripple and asked for the portfolio's animation: a hard-edged clip-path circle on the new view-transition snapshot, from the toggle's centre to the farthest corner, 700ms ease-in-out. The UA cross-fade is disabled. With reduced motion, or without the View Transitions API, the theme switches instantly.
