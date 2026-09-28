# Questions for the council
> Raja's agenda for the next council meeting. Written 2026-09-27. Log each answer in `decisions.md`, then delete the question here.

## 1. Participation certificates, generated in the lounge

**The idea.** Each past event on the public Events page links to "Get your participation certificate in the members' lounge". A member signs in, and the lounge lists the events they took part in. They press one button and get a PDF with their name on it, plus a certificate ID that the existing Verify page can check.

**Can we build it?** Yes. The code is modest: roughly 3–5 days once lounge sign-in exists, and sign-in is planned anyway. The hard part is not the code; it's the three things below that only the council can provide.

**What the generator does, for each event:**
1. A single certificate design, made once in Canva and signed once, with an empty space where the name goes.
2. A list of the people who took part: their IITM student emails.
3. The website checks that the signed-in email is on that list, writes the name onto the design, gives it a unique ID, and records who received it. The Verify page then confirms that ID.

**Questions to answer:**
- **Signature:** will the Cultural, Technical and E-Sports heads sign one template per event, with the website filling in the name? Or does every certificate need a separate signature?
- **Attendance lists:** do we have them, and for which events? Possible sources are registration forms, Meet attendance and Unstop exports. Without a list, that event cannot offer certificates.
- **Name:** use the name on the house roster, or let the student type it? The roster is safer. Typing it lets people fix spellings but also lets them put any name.
- **Scope:** past 2025–26 events, or only new events from now on?
- **Design:** one template per wing (Cultural / Tech / Games & Sports / Talks), or one per event?

**Context:** the 100 certificates on the Verify page today are all *appreciation* certificates (council, teams, city coordinators; issued 01/07/2026). Participation certificates would be new.

**Build notes, for later:**
- Supabase tables for event attendance and issued certificates. A member can only read their own rows.
- The PDF is made in the browser from the template.
- Verify should look up a single ID. Today the site downloads all 100 certificates with names in `public/data/certificates.json`.

## 2. Winners on the public Events page

For now, winners are **removed** from the Events page: no winner names, trophy counts or winner search. The event data still has 17 winner lists (names only; emails were never published).
- Should the site publicly show who won each competition (for example, the Paradox Champions League)?
- If yes, do winners need to agree first?
- The lists have **no ranks**, only names. If we show winners, should they be ranked 1st/2nd/3rd? Someone would need to add the ranks.

## 3. Please confirm or fix (content and data)

- **About copy:** members are writing it. The House page needs three short paragraphs (about 25–35 words each), three one-line values, and a sentence for each region. The current text is a draft from the old About page.
- **"How the house works"** (now on the Teams page): is this structure right?
  - Upper House Council
  - Lower House Council, with a regional coordinator plus city coordinators and volunteers
  - Communities: Cultural, Technical, E-Sports
  - Crew: PR & Outreach, Graphic Design, WebOps
  - Members
- **Member count:** the old About page says 5,170 members. Is that still true? It isn't shown anywhere now.
- **Meetup sheets:** some meetups have no date: Mumbai (all 13), Kolkata (all 5), Chennai (1) and Delhi (2). Chandigarh has no turnout numbers. Some partner-house names are misspelled, e.g. "Namalla".
- **Bengaluru** has meetups but no regional coordinator listed for 2026–27. The **International** region has no meetups. Should it still appear?
- **Team rosters for the Teams page:** names, roles and photos for Cultural, Technical, E-Sports, PR & Outreach, Graphic Design and WebOps (2026–27). Photos in the same style as the council's. Also: is the crew list right, and who runs the Talks events?
- **Meetup photos:** 19 of 70 meetups have photos (76 photos). Only Bengaluru's 4 are on Cloudinary; the other 72 are Google Photos links. 4 of those are already dead (3 across two Kolkata meetups, 1 in Patna's "Explore Bihar"), and Google also refuses bursts of requests, so the page has to retry. Can someone re-upload meetup photos to Cloudinary, and add photos for the meetups that have none?
- **Lounge contents:** the Lounge tab previews live events, Night Owl rooms, regional groups, a monthly leaderboard and certificates. Are those the right rooms? Who keeps the schedule and the points up to date?

## Already decided (for information, not discussion)

- The public Events page shows past events only; live events are in the members' lounge.
- Meetups moved from the Events page to the House page (Raja's call: students don't need them every day).
- The About page is part of the House page.
- "Dark Web Fundamentals Session" is dated 24 Mar 2025 but should be 2026. Raja is fixing the data.
