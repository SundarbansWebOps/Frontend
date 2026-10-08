// THROWAWAY sample data for prototype D, copied from ../lounge-shared/fixtures.js and
// reshaped (live event labels, group purposes, round 4 events/records/notices). Links are
// fake. Times are relative to page load so "live now" always demos. Real past events from
// src/data/events.data.js are merged in by events.js.
const now = Date.now();
const min = 60_000;
const hour = 60 * min;
const day = 24 * hour;
const iso = (ms) => new Date(ms).toISOString();
/* A day offset at a fixed local clock time, so upcoming events land on sensible hours. */
const at = (days, h, m = 0) => {
  const d = new Date(now + days * day);
  d.setHours(h, m, 0, 0);
  return d.getTime();
};

export const member = {
  full_name: '', // roster name; blank so the prototype asks the member
  email: '26f1002254@ds.study.iitm.ac.in',
  roll: '26F1002254',
  region: { code: 'mumbai', name: 'Mumbai' },
  coordinator: { name: 'Dhanashree Kulkarni', role: 'Regional Coordinator' },
  communities: ['technical', 'esports'],
};

/* Lounge events (backend: public.events). community null = house-wide. */
export const liveEvent = {
  id: 'e-live',
  /* One name everywhere: the Home card, the toast, Events and the pop-up all read `name`. */
  name: 'Maths 1 doubt clearing',
  why: 'For Quiz 1 on 26 Oct',
  type: 'Doubt session',
  community: null,
  description:
    'Seniors go through the week 1 to 4 graded questions, then take whatever you bring. Type your doubt in the chat so nobody gets skipped.',
  platform: 'Google Meet',
  starts_at: iso(now - 25 * min),
  ends_at: iso(now + 65 * min),
  meet_link: 'https://meet.google.com/ykf-fwtm-mbb',
};

export const nextEvent = {
  id: 'e-next',
  name: 'Build night: your first portfolio site',
  type: 'Workshop',
  community: 'technical',
  description:
    'A live build from an empty folder to a deployed site in 90 minutes. Bring a laptop with VS Code and a GitHub account. Everyone leaves with a link they can share.',
  platform: 'Google Meet',
  starts_at: iso(at(2, 20, 30)),
  ends_at: iso(at(2, 22)),
  meet_link: 'https://meet.google.com/abc-defg-hij',
};

export const events = [
  liveEvent,
  nextEvent,
  {
    id: 'e-scrims',
    name: 'BGMI squad scrims',
    type: 'Scrims',
    community: 'esports',
    description:
      'Practice matches before the house cup. Come as a squad of four, or come alone and we will find you one. Room details go out in the call.',
    platform: 'Google Meet and BGMI',
    starts_at: iso(at(4, 21)),
    ends_at: iso(at(4, 23)),
    meet_link: 'https://meet.google.com/bgm-isqd-scr',
  },
  {
    id: 'e-openmic',
    name: 'Open mic: festival edition',
    type: 'Open mic',
    community: 'cultural',
    description:
      'Songs, poetry, stand-up, a story from home. Five minutes each. Put your name down in the call to perform, or keep your camera off and listen.',
    platform: 'Google Meet',
    starts_at: iso(at(9, 20)),
    ends_at: iso(at(9, 22)),
    meet_link: 'https://meet.google.com/xyz-abcd-efg',
  },
  {
    id: 'e-quiztalk',
    name: 'Quiz 1: how seniors plan the last ten days',
    type: 'Talk',
    community: null,
    description:
      'Three seniors who cleared foundation in one go show the plans they actually used in the ten days before Quiz 1, then take questions.',
    platform: 'Google Meet',
    starts_at: iso(at(12, 19)),
    ends_at: iso(at(12, 20, 15)),
    meet_link: 'https://meet.google.com/qz1-plan-ten',
  },
  {
    id: 'e-blitz',
    name: 'Blitz chess night',
    type: 'Tournament',
    community: 'esports',
    description:
      '3+2 blitz on Lichess, Swiss format, six rounds. The top three get a shout-out in the house group.',
    platform: 'Google Meet and Lichess',
    starts_at: iso(at(16, 21)),
    ends_at: iso(at(16, 23)),
    meet_link: 'https://meet.google.com/blz-chss-nyt',
  },
  {
    id: 'e-valorant',
    name: 'Valorant house cup',
    type: 'Tournament',
    community: 'esports',
    description: 'Five-a-side, single elimination. Eight teams, one long evening.',
    platform: 'Google Meet and Valorant',
    starts_at: iso(at(-12, 19)),
    ends_at: iso(at(-12, 22)),
  },
  {
    id: 'e-senior',
    name: 'Talk with a senior: surviving the foundation level',
    type: 'Talk',
    community: null,
    description: 'A diploma-level senior on what she would do differently in her first two terms.',
    platform: 'Google Meet',
    starts_at: iso(at(-26, 19)),
    ends_at: iso(at(-26, 20, 30)),
  },
  {
    id: 'e-oppe',
    name: 'Python OPPE mock',
    type: 'Mock exam',
    community: 'technical',
    description:
      'A timed mock of the Python OPPE under the same portal rules, then a walkthrough of every question.',
    platform: 'Google Meet',
    starts_at: iso(at(-40, 18)),
    ends_at: iso(at(-40, 20)),
  },
];

/* This member's rows (backend: registrations + Meet attendance + certificates). Keys are
   event ids; real past events use 'p-' + a slug of their title. minutes = time in the Meet;
   20 or more counts as attended. */
export const records = {
  'e-live': { registered: true },
  'e-scrims': { registered: true },
  'e-valorant': {
    registered: true,
    minutes: 168,
    certificate: { id: 'SB-7Q2K-9XHD', issued_at: iso(at(-11, 10)) },
  },
  'e-senior': {
    registered: true,
    minutes: 74,
    certificate: { id: 'SB-3MPA-4TRW', issued_at: iso(at(-25, 10)) },
  },
  'e-oppe': { registered: true, minutes: 9 },
  'p-career-in-research': {
    registered: true,
    minutes: 81,
    certificate: { id: 'SB-26R1-9PDX', issued_at: '2026-05-20T10:00:00+05:30' },
  },
  'p-ubuntu-mastery-quiz': {
    registered: true,
    minutes: 41,
    certificate: { id: 'SB-26U5-3HTW', issued_at: '2026-03-07T10:00:00+05:30' },
  },
  'p-open-mic-night': { registered: true, minutes: 12 },
  'p-chess-showdown': {
    registered: true,
    minutes: 64,
    certificate: { id: 'SB-26C4-7KQM', issued_at: '2026-03-01T10:00:00+05:30' },
  },
  'p-photography-workshop-with-manish-kumar': { registered: true, minutes: 0 },
};

/* Notices (backend: announcements + per-member read/dismissed). `read` is the starting
   state; the prototype remembers what the member reads or dismisses. */
export const notices = [
  {
    id: 'n-quiz1',
    title: 'Quiz 1 is on 26 Oct',
    body: 'Hall tickets open on the portal from 20 Oct. Check your exam city before 22 Oct, when changes close.',
    by: 'Upper House Council',
    posted_at: iso(now - 20 * hour),
    read: false,
  },
  {
    id: 'n-meetup',
    title: 'Mumbai meetup on 19 Oct',
    body: 'Carter Road promenade, 5 pm. Say yes in the Mumbai group so we know how much chai to order.',
    by: 'Dhanashree Kulkarni, Mumbai RC',
    posted_at: iso(now - 2 * day - 3 * hour),
    read: false,
  },
  {
    id: 'n-certs',
    title: 'September certificates are out',
    body: 'Stayed 20 minutes or more at a September event? Your certificate is under My certificates in your profile.',
    by: 'Web team',
    posted_at: iso(now - 6 * day),
    read: true,
  },
  {
    id: 'n-esports',
    title: 'Esports tryouts this month',
    body: "BGMI and Valorant rosters for the inter-house cup are picked from this month's scrims.",
    by: 'Esports community',
    posted_at: iso(now - 11 * day),
    read: true,
  },
  {
    id: 'n-welcome',
    title: 'The Lounge is open',
    body: 'Live events, your WhatsApp groups and your certificates are in one place now. Tell us what is missing.',
    by: 'Upper House Council',
    posted_at: iso(now - 31 * day),
    read: true,
  },
];

export const groups = [
  {
    id: 'house',
    label: 'Sundarbans House',
    why: 'Official announcements for every member.',
    href: 'https://chat.whatsapp.com/SAMPLE-HOUSE',
  },
  {
    id: 'region',
    label: 'Mumbai region',
    why: 'Meetups and study groups near you.',
    href: 'https://chat.whatsapp.com/SAMPLE-MUMBAI',
  },
  {
    id: 'technical',
    label: 'Technical',
    why: 'Coding, projects, hackathons.',
    href: 'https://chat.whatsapp.com/SAMPLE-TECH',
  },
  {
    id: 'cultural',
    label: 'Cultural',
    why: 'Music, art, fests.',
    href: 'https://chat.whatsapp.com/SAMPLE-CULT',
  },
  {
    id: 'esports',
    label: 'Esports',
    why: 'Gaming tournaments.',
    href: 'https://chat.whatsapp.com/SAMPLE-ESPORTS',
  },
];
