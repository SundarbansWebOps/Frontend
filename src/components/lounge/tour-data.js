// Welcome tour content. Names and years are exact (from Raja); every line marked
// PLACEHOLDER is draft copy for Raja to edit.
import { EVENTS } from '../../data/events.data.js';

// One-line change once confirmed elsewhere.
export const DEPUTY_SECRETARY = 'Ansh Kumar';

// The house note, from the welcome copy. Body is the two intro paragraphs; pride is the closing line.
export const HOUSE_NOTE = {
  title: 'Welcome to Sundarbans House.',
  body: "From exciting events and creative collaborations to shared achievements and lifelong memories, Sundarbans House is where every student gets the opportunity to connect, contribute, and shine. We believe that the best experiences are created when people come together, ideas turn into action, and every voice finds a place. So, whether you're here to learn, lead, collaborate, or simply make incredible memories, you're not just joining a house, you're becoming part of a legacy.",
  pride: "Welcome to the Sundarbans House, let's make this journey unforgettable!",
};

export const FOUNDED = 2021;

/* Cloudinary face-aware crop for the thought-bubble photo (same idea as src/lib/house.js
   portrait.big). */
const face = (u) =>
  u.replace('f_auto,q_auto:good,w_1000,c_limit', 'f_auto,q_auto,w_240,h_300,c_fill,g_face');
const CLD = 'https://res.cloudinary.com/l59gy0g2/image/upload/f_auto,q_auto:good,w_1000,c_limit';
const KUNAL_PHOTO = face(`${CLD}/v1792177588/sundarbans/legacy-council/kunal-2021-tiger.webp`);
const ANSHUMAN_PHOTO = face(`${CLD}/v1792223335/sundarbans/legacy-council/anshuman-2021-tiger.jpg`);
const UTKARSH_PHOTO = face(`${CLD}/v1792177589/sundarbans/legacy-council/utkarsh-2021-tiger.webp`);
const MANNU_PHOTO = face(`${CLD}/v1792177357/sundarbans/legacy-council/mannu-yadav.webp`);
const ADITYA_2025_PHOTO = face(
  `${CLD}/v1792177324/sundarbans/legacy-council/aditya-vaidhya-2025.webp`
);

/* A past council member. Until a real photo exists the frame shows the house crest. To add
   a photo, pass its URL as the third argument; it replaces the crest:
   p('Ravi Kant', 'Deputy Secretary', 'https://…/ravi.jpg') */
const p = (name, role, photo = null) => ({ name, role, photo });
const SEC = 'Secretary';
const DEP = 'Deputy Secretary';

/* Those who rowed before you: one landing per year, Secretary first, Deputy Secretary second. */
export const LANDINGS = [
  {
    year: 2021,
    people: [p('Anshuman Bhasin', SEC, ANSHUMAN_PHOTO), p('Utkarsh Gaurav', DEP, UTKARSH_PHOTO)],
  },
  {
    year: 2022,
    people: [
      p('Kunal Chaturvedi', SEC, KUNAL_PHOTO),
      p('Abhishek Ojha', DEP, face(`${CLD}/v1792094947/sundarbans/teams/Abhishek_ojha.png`)),
    ],
  },
  {
    year: 2023,
    people: [
      p('Abhishek Ojha', SEC, face(`${CLD}/v1792094947/sundarbans/teams/Abhishek_ojha.png`)),
      p('Ravi Kant', DEP, face(`${CLD}/v1792095019/sundarbans/teams/ravikant.png`)),
    ],
  },
  {
    year: 2024,
    people: [
      p('Shreyansh Mall', SEC, face(`${CLD}/v1792095027/sundarbans/teams/shreyansh.png`)),
      p('Divya Chinmay', DEP, face(`${CLD}/v1792094976/sundarbans/teams/divya.png`)),
    ],
  },
  {
    year: 2025,
    people: [p('Mannu Yadav', SEC, MANNU_PHOTO), p('Aditya Vaidhya', DEP, ADITYA_2025_PHOTO)],
  },
];

/* Its own moment after the 2023 landing: the lighthouse lights up. Copy from Raja. */
export const MILESTONE = {
  year: 2023,
  after: 2023,
  text: 'We moved from a Google Sites page to our own website — the first house to do it.',
  by: 'Built by Ravi Kumavat, Web Admin.',
};

export const COUNCIL_YEAR = 2026;

// Photos are the council's real ones from src/data/house.data.js. Notes are PLACEHOLDER drafts.
// `pose` picks the painted character on the bank (art/r5/council-{pose}-{day|night}.webp):
// generic figures, not likenesses; the photo shows in the thought bubble.
export const COUNCIL = [
  {
    name: 'Divya Prakash',
    role: 'Secretary',
    pose: 'wave',
    photo: face(`${CLD}/v1791953706/sundarbans/teams/Divya_Prakash.png`),
    note: "Welcome to the house. Come to one event this month, even just to listen. That's how all of us started.",
  },
  {
    name: DEPUTY_SECRETARY,
    role: 'Deputy Secretary',
    pose: 'namaste',
    photo: face(`${CLD}/v1791994850/sundarbans/teams/ansh_kumar.png`),
    note: "Whatever city you're in, there's a Sundarbans member near you. Say hi in your region group. I'm in there too.",
  },
  {
    name: 'Anuraj Jit Saikia',
    role: 'Web Admin',
    pose: 'laptop',
    photo: face(`${CLD}/v1791954015/sundarbans/teams/anuraj.png`),
    note: "I built this Lounge for you. If something breaks or feels off, tell me and I'll fix it.",
  },
];

const pick = (titles) =>
  titles.map((t) => {
    const e = EVENTS.find((x) => x.title === t);
    if (!e) throw new Error(`tour-data: event not found: ${t}`);
    return { title: e.title, type: e.type, date: e.date.split('|')[0].trim() };
  });

// PLACEHOLDER: community one-liners. Events are real, from src/data/events.data.js.
export const COMMUNITIES = [
  {
    id: 'cultural',
    name: 'Cultural',
    about: 'Music, dance, poetry and open mics. Get on stage, or come and cheer.',
    sound: 'cultural',
    events: pick([
      'Dance Workshop with Aditri Bordoloi',
      'Open Mic Night',
      'Shiv–Shakti: The Eternal Union',
    ]),
  },
  {
    id: 'technical',
    name: 'Technical',
    about: 'Workshops, coding challenges and build nights. Bring a project or start one here.',
    sound: 'technical',
    events: pick([
      'Vibe Coding a SaaS Application Workshop',
      'Coding Aptitude Challenge',
      'Ubuntu Mastery Quiz',
    ]),
  },
  {
    id: 'esports',
    name: 'Esports',
    about: 'BGMI, Free Fire, chess and game nights. Squad up for the house.',
    sound: 'esports',
    events: pick(['Sundarbans House BGMI Showdown 2025', 'Among Us Night', 'Chess Showdown']),
  },
];
