// The 2021–22 and 2022–23 councils, told from each Secretary's letter. Quotes are the letter's own
// words. Body text paraphrases the letter and keeps its scope: "my vision", "our team hosted",
// "we planned". Nothing here claims more than the letter does.
// `art` names a plate in src/assets/legacy/council/<key>-<art>.webp.

const LETTER_2021 = "The Secretary's letter, 2021–22";
const LETTER_2022 = "The Secretary's letter, 2022–23";

export const STORIES = {
  '2021-22': {
    key: '2021-22',
    label: '2021–22',
    account: LETTER_2021,
    headline: 'The first year of the house system',
    vision:
      'My vision was to build a strong, self-sufficient team that had the autonomy and freedom to ideate, innovate and execute initiatives throughout the year.',
    chapters: [
      {
        id: 'foundations',
        art: 'foundations',
        label: 'Foundations',
        title: 'Starting from scratch',
        line: 'Branding, channels and a culture of taking part, all built at once.',
        body: 'Since this was the inception of the house system, we were starting almost everything from scratch: house branding, communication channels, and a culture of participation and collaboration among members.',
        points: [
          'First official Google Space for a house',
          'Basic structures so the house could run smoothly',
        ],
        quote:
          'One of our early achievements was establishing the first official Google Space for a house during the first year of the IITM BS Programme, then known as the IITM BSc Programme.',
      },
      {
        id: 'core',
        art: 'core',
        label: 'Core team',
        title: 'A core team that could laugh',
        line: 'Light-hearted in pressure, so the team could act freely.',
        body: 'The team built a strong core through a lot of shenanigans in meetings and across the house. The idea was to keep everything light-hearted, even under pressure, so the team could act freely and members could have fun too.',
        points: ['Team meetings with plenty of shenanigans', 'Freedom to act under pressure'],
        quote:
          'The idea was to keep everything light hearted even in situations of pressure to allow the team to act freely and for the house members to also have fun during these times.',
      },
      {
        id: 'events',
        art: 'events',
        label: 'Events',
        title: 'Something for every interest',
        line: 'Music, technical sessions and social causes, on one calendar.',
        body: 'The aim was events across cultural, technical, professional and social domains, so students with different interests had something to look forward to.',
        points: [
          'Music: SAAZ, Romantic Melodies, YAAD',
          'Sessions: Data Science Fundamentals, Introduction to Blockchain, Value Investing for Beginners',
          'Social: Cyber Bullying Awareness Campaign, A Session on Women Hygiene, Women Then vs Now, Debate on Climate Change',
          'Interactive: Antaakshari, Open Jamming Session, Speak Now: Portrayal of Women in Indian Cinema',
        ],
        quote:
          'These events helped us establish a diverse calendar that balanced technical learning, cultural expression, entertainment and social awareness.',
      },
      {
        id: 'ownership',
        art: 'ownership',
        label: 'Ownership',
        title: 'Members took the lead',
        line: 'Freedom to ideate, and the chance to organise.',
        body: 'A key focus was encouraging participation and giving students the freedom to take ownership of initiatives. Members could contribute ideas, collaborate and lead the organising.',
        points: ['Ideas from members', 'Members leading the organising'],
        quote:
          'This approach helped us lay the groundwork for a more active and engaged house community.',
      },
    ],
    closing: {
      title: 'A foundation for the next team',
      text: 'Overall, the first year was about building the foundations for everything that Sundarbans House would eventually become.',
      quote: 'Most importantly, we established a foundation that future teams could build upon.',
    },
  },
  '2022-23': {
    key: '2022-23',
    label: '2022–23',
    account: LETTER_2022,
    headline: 'Building on the foundation',
    vision:
      "My vision for the house in 2022-23 was to continue fostering a positive, inclusive and united community, building upon the strong foundation established during Anshuman's tenure from 2021-22.",
    chapters: [
      {
        id: 'speakers',
        art: 'speakers',
        label: 'Speakers',
        title: 'Industry voices, in the room',
        line: 'Fireside chats where students could ask the questions.',
        body: 'Our team hosted 15+ top industry professionals and distinguished guests. We planned the sessions to discuss career journeys, challenges and key learnings, with ample room for audience questions, so students could talk directly with industry leaders.',
        points: [
          'R Srinivasan, CIO, SBI Mutual Funds',
          'Pankaj Dubey, Founder, DSPIN Consulting; former Managing Director, Polaris India',
          'Divya Khemani, Director, Strategic Growth Partnerships, Microsoft',
          'Prateek Sethi, Director, Trip Creative Services; former Pogo FAQ host',
          'Jamie Mittelmann, Founder, Flame Bearers Podcast',
        ],
        quote:
          'Our team had the honour of inviting and hosting 15+ top industry professionals and distinguished guests.',
      },
      {
        id: 'workshop',
        art: 'workshop',
        label: 'Workshop',
        title: 'A week of building',
        line: 'A 7-day Node.js workshop, from zero to a working CRUD app.',
        body: 'Near the end of the tenure, the Secretary taught a 7-day Node.js workshop. Members went through building a full-stack CRUD application end to end. The recordings are on the house YouTube channel, along with nearly all the other sessions.',
        points: ['7 days', 'Full-stack CRUD application, end to end'],
        quote:
          'Near the end of my tenure, I undertook the responsibility to conduct/teach in a 7-day Node.js workshop.',
      },
      {
        id: 'culture',
        art: 'culture',
        label: 'Culture and clubs',
        title: 'Cultural stages and student clubs',
        line: 'Collaborations with music, dance and literary societies, and clubs of their own.',
        body: 'We regularly collaborated with the music, dance and literary societies for cultural events, giving members a stage for their talents. We also set up clubs, so students could pursue their interests and take on leadership.',
        points: ['Music Club', 'Chess Club', 'E-Cell', 'and many more'],
        quote: 'Several Sundarbans House members often went on to become stars of the show!',
      },
      {
        id: 'initiatives',
        art: 'initiatives',
        label: 'Initiatives',
        title: 'New initiatives that stayed',
        line: 'Four additions that became part of the house ecosystem.',
        body: 'During this tenure we introduced several initiatives that became an important part of the house ecosystem: a career series, a language exchange, an internal activity body and a data series.',
        points: [
          'Sundarbans Summit: fireside chats with founders, managing directors and C-level executives',
          'Learn a Language: students taught one another their native languages',
          'Sundarbans Gymkhana: an internal activity body of 16 in-house clubs, each with its own executive committee',
          'Data Talks: sessions with industry professionals on Data Science and AI',
        ],
        quote:
          'Together, these initiatives helped us build a diverse ecosystem that catered to different aspects of student life.',
      },
      {
        id: 'reputation',
        art: 'reputation',
        label: 'Reputation',
        title: 'Sought-after, and beyond the house',
        line: 'A reputation carried over from the previous tenure.',
        body: 'Sundarbans was widely regarded as one of the most sought-after houses, continuing the reputation from the previous tenure. Our active members also contributed in other student bodies, Paradox events and POD events.',
        points: ['Other student bodies', 'Paradox events', 'POD events'],
        quote:
          'Our focus was on ensuring that every member, even those from other houses, could find a platform to explore their interests, contribute meaningfully and connect with others.',
      },
    ],
    closing: {
      title: 'An ecosystem, not a list of events',
      text: 'Looking back, the letter names the biggest achievement as building an ecosystem where professional learning could coexist with cultural expression.',
      quote: '…and every member had the opportunity to contribute.',
    },
  },
};
