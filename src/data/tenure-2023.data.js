// The 2023–24 council's own account of its tenure, condensed from
// "SUNDARBANS — TENURE 2023–24" (supplied by the council, October 2026). Each
// `claim` is the council's own, with its exact scope (first / first and only / among the
// first): show it attributed and never round it up to a plain "first".
// The Startup Series was planned, never launched: always label it that way.

export const TENURE = {
  year: 2023,
  label: '2023–24',
  tagline: ['Inspire.', 'Innovate.', 'Impact.'],
  headline: 'A Sundarbans that solves the problems students face',
  vision:
    'More than another house. A student-driven ecosystem that finds the real gaps in an online degree and builds the fix.',
  account: 'The council’s own account of its tenure',
  creed: ['Find the problem.', 'Build the solution.', 'Make it accessible.'],
  people: [
    { name: 'Abhishek Ojha', role: 'Secretary' },
    { name: 'Ravi Kant', role: 'Deputy Secretary' },
    { name: 'Ravi Kumawat', role: 'Web Admin' },
  ],
};

// Why the tenure existed: what a student arrives wanting, and what an online degree
// made hard to find.
export const WHY = {
  wants: [
    'friends',
    'good grades',
    'events',
    'placements',
    'GATE or UPSC prep',
    'answers to their questions',
  ],
  gap: 'Thirty thousand students in one degree, but online: the friends, guidance and support of a campus were missing.',
};

// `need` is the student's question; the rest is the answer the tenure built.
export const INITIATIVES = [
  {
    id: 'studybuddy',
    name: 'StudyBuddy',
    area: 'Connect',
    claim: 'First social media platform of IITM BS',
    need: 'Is anyone from the degree in my city?',
    problem:
      'Over 30,000 students across the BS programme, and no way to find the ones living in your own city.',
    built:
      'A platform to discover nearby IITM BS students, see roughly how far they are, and connect on LinkedIn, Instagram or Snapchat.',
    points: ['Students near you', 'Approximate distance', 'Study partners and friends'],
  },
  {
    id: 'meetups',
    name: 'Offline meetups',
    area: 'Connect',
    claim: 'Among the first houses to hold meetups',
    need: 'Can we meet in person?',
    problem:
      'Meetups came to the degree in March 2024, through Kothai Ma’am and UHC. Online friends still had never met.',
    built:
      'The Secretary led a meetup in Prayagraj, then council members held more in their own cities. StudyBuddy found people; meetups put them in one room.',
    points: ['Prayagraj first', 'Council-led in more cities', 'March 2024 onward'],
  },
  {
    id: 'academics',
    name: 'Academic support',
    area: 'Learn',
    claim: 'First and only house with notes and past papers',
    need: 'Where do I find notes, papers and study partners?',
    problem:
      'Studying alone, with resources spread across platforms and a Discourse forum many found hard to use.',
    built:
      'Subject-wise communities for doubts and exam prep, plus notes and previous-term papers through a collaboration with TheOpenNotes.',
    points: ['Subject-wise communities', 'Notes', 'Previous-term papers'],
  },
  {
    id: 'placements',
    name: 'Placement Series',
    area: 'Career',
    claim: 'First structured placement ecosystem',
    need: 'How do I prepare for placements?',
    problem:
      'Occasional sessions, but no end-to-end path from résumé to interview. A gap between what was offered and what students needed.',
    built:
      'A full series with experts from Google, Amazon, IBM and Apple, among others, and a placement community of those preparing and those already placed. SPC later joined it.',
    points: [
      'Résumé, communication',
      'SQL, ML, deep learning',
      'GenAI, cloud, big data',
      'SPC joined later',
    ],
  },
  {
    id: 'gate',
    name: 'GATE Series',
    area: 'Career',
    claim: 'First and only house with structured GATE guidance',
    need: 'Who helps me prepare for GATE alongside the degree?',
    problem:
      'Aspirants prepared alone, with no student-body series and no community of others on the same path.',
    built:
      'Sessions by subject-matter experts across most GATE subjects, and a dedicated community to share resources, strategy and doubts.',
    points: ['Most GATE subjects', 'Expert-led', 'Aspirants’ community'],
  },
  {
    id: 'genai',
    name: 'GenAI Club',
    area: 'Learn',
    claim: 'First GenAI club of IITM BS',
    need: 'Where do I start with Generative AI?',
    problem:
      'GenAI was reshaping the industry, but the degree had no club for it. The diploma GenAI course came later.',
    built:
      'The first Generative AI club and community in IITM BS, to explore the field, share what you learn and learn together.',
    points: ['Before the GenAI course', 'Club and community'],
  },
  {
    id: 'verified',
    name: 'Verified WhatsApp',
    area: 'Safety',
    claim: 'First 100% verified house community',
    need: 'Is the group I’m in safe?',
    problem:
      'Anyone could join the three big groups from any number. If someone misbehaved, nobody could say who it was.',
    built:
      'A semi-automated verification system. The hard call: close all three groups and start a fresh community where every member is verified by name and email.',
    points: ['Three groups closed', '100% verified members', 'Incidents traceable'],
  },
  {
    id: 'assistant',
    name: 'AI Assistant',
    area: 'Platform',
    claim: 'First AI assistant of IITM BS',
    need: 'Who answers my questions about the degree?',
    problem:
      'Freshers asked about courses, fees, Paradox and houses, then waited on support emails or hoped a senior replied.',
    built:
      'The Sundarbans AI Assistant, on the house website, answering the common questions straight away.',
    points: ['Courses, fees, Paradox', 'Houses and clubs', 'On the website'],
  },
  {
    id: 'website',
    name: 'Full-stack website',
    area: 'Platform',
    claim: 'First full-stack website among the houses',
    need: 'Where is everything Sundarbans offers?',
    problem:
      'The other eleven houses had Google Sites landing pages: information, but no services.',
    built:
      'One platform that delivered the services themselves: notes, papers, StudyBuddy, verification, the AI Assistant, placement and GATE communities, the newsletter.',
    points: ['Eleven houses on Google Sites', 'One house with services'],
  },
  {
    id: 'newsletter',
    name: 'Newsletter',
    area: 'Platform',
    claim: 'First newsletter of IITM BS',
    need: 'How do I keep up with all of it?',
    problem: 'With so much running at once, students missed updates or did not know where to look.',
    built:
      'A newsletter, before any other house or society had one, carrying updates, announcements and opportunities in one place.',
    points: ['Before any house or society'],
  },
];

export const OPEN_FLOOR = {
  title: 'Any member could lead',
  text: 'Events had to serve the mission, not fill a calendar. A member with an idea brought its purpose, value and plan to the Secretary; if it held up, they ran it. You did not need a council seat.',
};

export const STARTUP = {
  name: 'Startup Series',
  status: 'Planned',
  summary:
    'The next series: idea to scale, with sessions planned from CXOs of Indian unicorns, in the spirit of Y Combinator.',
  steps: [
    'Idea and validation',
    'Market research',
    'MVP',
    'Product',
    'Marketing and growth',
    'Sales',
    'Fundraising',
    'Company and legal',
    'Incubation',
    'Scaling',
  ],
};

export const AREAS = [
  { id: 'Connect', line: 'Find your people' },
  { id: 'Learn', line: 'Study together' },
  { id: 'Career', line: 'Prepare for what follows' },
  { id: 'Safety', line: 'Keep the community safe' },
  { id: 'Platform', line: 'Put it all in one place' },
];

// Three acts for reading the tenure as one story. `ids` point into INITIATIVES.
export const ACTS = [
  {
    id: 'find',
    title: 'Find each other',
    lead: 'Thirty thousand students in one degree, and you could live next door to a classmate without ever knowing.',
    ids: ['studybuddy', 'meetups'],
  },
  {
    id: 'build',
    title: 'Build the support',
    lead: 'Then the things students came for: help with subjects, a path to placements and GATE, a start in GenAI.',
    ids: ['academics', 'placements', 'gate', 'genai'],
  },
  {
    id: 'trust',
    title: 'Make it safe and reachable',
    lead: 'Support only works if students trust the community and can find what it offers.',
    ids: ['verified', 'assistant', 'website', 'newsletter'],
  },
];

// The tenure's hardest call, told on its own.
export const HARD_CALL = {
  title: 'The difficult decision',
  text: 'The house had three large WhatsApp groups, and nobody could say who was behind half the numbers. The council closed all three and started again with only verified members. Months later, an unknown number posted something inappropriate in another house’s group. All its admins could do was delete the message and remove the number.',
  moral: 'Early preparation is the best protection.',
};

export const byId = Object.fromEntries(INITIATIVES.map((x) => [x.id, x]));
