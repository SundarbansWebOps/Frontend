# PROTOTYPE — Resources + Events + House + Teams + Lounge (throwaway)

Question: what should the student-first Sundarbans site look and move like?

Run: `npm run dev`, then open `http://localhost:5173/prototype/resource-hub/`.
Pages: Resources (default) · Events (`?page=events`) · House (`?page=house`) · Teams (`?page=teams`)
· Lounge (`?page=lounge`). `?theme=dark` or `t`; typeface `?font=anek|familjen|schibsted` or `f`.

- **Resources** — the chosen "Delta" direction (variant A; B and C were dropped 2026-09-27).
  Real notes/PYQ Drive links from `src/data/scData_generated.js`; term dates are sample data.
- **Events** — past events only (live events live in the members' lounge). No winners until the
  council decides. `events.data.js` is a generated snapshot of `src/views/*View.vue` (stock photos
  dropped). Each event links to the lounge for its participation certificate (planned).
- **House** — About (draft copy) with a procedural mangrove, the Upper House Council (cards fan
  out and turn over on scroll), where we meet (regions + meetups from
  `src/views/meetups/.../json/`, season playback; meetup photos fly into a roll and open in a
  viewer), and the lounge door. `house.data.js` is a generated snapshot of the Teams view and
  region blurbs.
- **Teams** — how the house works (a river delta that draws as you scroll), UHC, Lower House
  Council, communities and crew. Rosters live in `teams.js` (empty until names arrive).
- **Lounge** — the members-only rooms as demos on sample data (live, Night Owl, groups,
  leaderboard, certificate generator). Sign-in is not wired.

Open questions for the council: `docs/council-questions.md`.
Nothing in `src/` is touched. Delete this folder once the real build starts.
