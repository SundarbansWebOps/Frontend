// The teams below the council. Community copy is from the live Community page; team copy is
// a draft. People are { name, role, img, lead? }: leads show as portraits in the team's panel,
// everyone else as a tile. A team with no people shows the 2026–27 seats instead.
import { events } from '../lib/events.js';

// Team photos on Cloudinary (sundarbans/teams/), at the same delivery size as the council's.
const pic = (version, file) =>
  `https://res.cloudinary.com/l59gy0g2/image/upload/f_auto,q_auto:good,w_1000,c_limit/${version}/sundarbans/teams/${file}`;

const eventsIn = (wing) => events.filter((e) => e.wing === wing).length;

export const COMMUNITIES = [
  {
    id: 'cultural',
    name: 'Cultural',
    tag: ['Art.', 'Music.', 'Culture.'],
    desc: 'Arts, music, literature and cultural exchange — bridging regions into one Sundarbans identity.',
    wing: 'cultural',
    events: eventsIn('cultural'),
    people: [
      {
        name: 'Dhanashree Kulkarni',
        role: 'Cultural Lead',
        img: pic('v1791954025', 'Dhanashree_kulkarni.png'),
        lead: true,
      },
      {
        name: 'Abhisekh Chowdhury',
        role: 'Regional Coordinator',
        img: pic('v1791954000', 'Abhisekh_Chowdhury.png'),
      },
      { name: 'Aditi Gupta', role: 'Member', img: pic('v1792082482', 'Aditi_gupta.png') },
      { name: 'Aditi', role: 'Member', img: pic('v1792082487', 'Aditi.png') },
      { name: 'Piyush Kumar', role: 'Member', img: pic('v1792082594', 'Piyush_kumar.png') },
      { name: 'Dev Bhardwaj', role: 'Member', img: pic('v1792082527', 'Dev_bhardwaj.png') },
      { name: 'Sambhavi Verma', role: 'Member', img: pic('v1792082630', 'Sambhavi_Verma.png') },
      { name: 'Snehal Sharma', role: 'Member', img: pic('v1792082665', 'Snehal_sharma.png') },
      {
        name: 'Hirdyansh Aggrwal',
        role: 'Member',
        img: pic('v1792082539', 'Hirdyansh_aggrwal.png'),
      },
    ],
  },
  {
    id: 'technical',
    name: 'Technical',
    tag: ['Build.', 'Code.', 'Innovate.'],
    desc: 'Builders, analysts and innovators — frontend, AI/ML, blockchain and more. There is a space for you.',
    wing: 'tech',
    events: eventsIn('tech'),
    people: [
      {
        name: 'Karlapati Nandu',
        role: 'Co-Head',
        img: pic('v1792082575', 'Naku.png'),
        lead: true,
      },
      {
        name: 'Dhanashree Kulkarni',
        role: 'Advisory',
        img: pic('v1791954025', 'Dhanashree_kulkarni.png'),
        lead: true,
      },
      {
        name: 'Prashansa Uniyal',
        role: 'Core Member',
        img: pic('v1791954073', 'Prashansha_Uniyal.png'),
      },
      { name: 'Bhavana S', role: 'Core Member', img: pic('v1792082518', 'Bhavana.png') },
      { name: 'Prateek Kumar', role: 'Core Member', img: pic('v1792082603', 'Prateek_kumar.png') },
      {
        name: 'Aditya Kr Chaubey',
        role: 'Member',
        img: pic('v1792082493', 'Aditya_kr_chaubey.png'),
      },
      { name: 'Augastya', role: 'Member', img: pic('v1792082511', 'Augastya.png') },
      { name: 'Shubham Singh', role: 'Member', img: pic('v1792082651', 'Shubham_singh.png') },
      { name: 'Rishu', role: 'Member', img: pic('v1792082621', 'Rishu.png') },
      { name: 'Dhairy', role: 'Member', img: pic('v1792082533', 'dhairy.png') },
    ],
  },
  {
    id: 'esports',
    name: 'E-Sports',
    tag: ['Play.', 'Compete.', 'Win.'],
    desc: 'From casual games to tournaments. Every game has a team — find yours.',
    wing: 'games',
    events: eventsIn('games'),
    people: [
      {
        name: 'Maharishi Barman',
        role: 'Co-Head',
        img: pic('v1792082557', 'Maharshi.png'),
        lead: true,
      },
      {
        name: 'Niva Murabia',
        role: 'Regional Coordinator',
        img: pic('v1791954067', 'Niva_Murabia.png'),
      },
      {
        name: 'Abhisekh Chowdhury',
        role: 'Regional Coordinator',
        img: pic('v1791954000', 'Abhisekh_Chowdhury.png'),
      },
      { name: 'Akarsh Patil', role: 'Member', img: pic('v1792082500', 'Akarsh.png') },
      { name: 'Kaustubh More', role: 'Member', img: pic('v1792082544', 'Kaustubh.png') },
    ],
  },
];

export const TEAMS = [
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
    people: [
      {
        name: 'Megha Sharma',
        role: 'Graphic Head',
        img: pic('v1792082564', 'Megha.png'),
        lead: true,
      },
      {
        name: 'Arpit Verma',
        role: 'Graphic Co-Head',
        img: pic('v1792082505', 'Arpit.png'),
        lead: true,
      },
      {
        name: 'Niva Murabia',
        role: 'Regional Coordinator',
        img: pic('v1791954067', 'Niva_Murabia.png'),
      },
      { name: 'Lavanya', role: 'Designer', img: pic('v1791954051', 'Lavanya.png') },
      { name: 'Radhika Sarkar', role: 'Designer', img: pic('v1792082612', 'Radhika_sarkar.png') },
      { name: 'Namita Tamboli', role: 'Designer', img: pic('v1792082585', 'Namita.png') },
      { name: 'Senona Persis Madanu', role: 'Designer', img: pic('v1792082640', 'senona.png') },
      { name: 'Kshitij Pandey', role: 'Designer', img: pic('v1792082552', 'Kshitij.png') },
    ],
  },
  {
    id: 'webops',
    name: 'WebOps',
    tag: ['Ship', 'and', 'run.'],
    desc: 'Builds and runs this website and the members’ lounge.',
    people: [
      {
        name: 'Anuraj Jit Saikia',
        role: 'WebOps Head',
        img: pic('v1791954015', 'anuraj.png'),
        lead: true,
      },
      { name: 'Arpit Verma', role: 'Member', img: pic('v1792082505', 'Arpit.png') },
      { name: 'Subhadeep Das', role: 'Member', img: pic('v1792084870', 'Subhadeep_das.png') },
      { name: 'Garibul Singh', role: 'Member', img: pic('v1792084858', 'Garibul_singh.png') },
      { name: 'Prateek Raj', role: 'Member', img: pic('v1792084865', 'Prateek_raj.png') },
      { name: 'Utkarsh', role: 'Member', img: pic('v1792084876', 'Utkarsh.png') },
    ],
  },
];
