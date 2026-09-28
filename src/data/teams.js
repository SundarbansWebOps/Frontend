// The teams below the council. Community copy is from the live Community page;
// crew copy is a draft. Rosters are empty until the 2026–27 names and photos are in: add
// people as { name, role, img } (img: a Cloudinary URL like the council's) and the seats fill.
import { events } from '../lib/events.js';

const eventsIn = (wing) => events.filter((e) => e.wing === wing).length;

export const COMMUNITIES = [
  {
    id: 'cultural',
    name: 'Cultural',
    tag: ['Art.', 'Music.', 'Culture.'],
    desc: 'Arts, music, literature and cultural exchange — bridging regions into one Sundarbans identity.',
    wing: 'cultural',
    events: eventsIn('cultural'),
    people: [],
  },
  {
    id: 'technical',
    name: 'Technical',
    tag: ['Build.', 'Code.', 'Innovate.'],
    desc: 'Builders, analysts and innovators — frontend, AI/ML, blockchain and more. There is a space for you.',
    wing: 'tech',
    events: eventsIn('tech'),
    people: [],
  },
  {
    id: 'esports',
    name: 'E-Sports',
    tag: ['Play.', 'Compete.', 'Win.'],
    desc: 'From casual games to tournaments. Every game has a team — find yours.',
    wing: 'games',
    events: eventsIn('games'),
    people: [],
  },
];

export const CREW = [
  {
    id: 'pr',
    name: 'PR & Outreach',
    tag: ['Tell', 'the', 'story.'],
    desc: 'Instagram, announcements and partner houses — how the rest of the degree hears about us.',
    people: [],
  },
  {
    id: 'design',
    name: 'Graphic Design',
    tag: ['Make', 'it', 'ours.'],
    desc: 'Posters, certificates and the way the house looks everywhere it shows up.',
    people: [],
  },
  {
    id: 'webops',
    name: 'WebOps',
    tag: ['Ship', 'and', 'run.'],
    desc: 'Builds and runs this website and the members’ lounge.',
    people: [],
  },
];
