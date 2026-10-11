// Last five councils (2021–2025). Secretary and Deputy Secretary names are the
// landings in src/components/lounge/tour-data.js. Photos stay null until real
// portraits exist: every frame shows the crest placeholder. Team seats are
// anonymous — the only label is "Team member". Do not invent names or titles.

const TEAM_SLOTS = 10;

function team() {
  return Array.from({ length: TEAM_SLOTS }, (_, i) => ({
    id: i + 1,
    name: null,
    role: 'Team member',
    photo: null,
  }));
}

export const FOUNDED = 2021;

export const LEGACY = [
  {
    year: 2021,
    secretary: { name: 'Anshuman Singh', role: 'Secretary', photo: null },
    deputy: { name: 'Kunal Chaturvedi', role: 'Deputy Secretary', photo: null },
    team: team(),
  },
  {
    year: 2022,
    secretary: { name: 'Kunal Chaturvedi', role: 'Secretary', photo: null },
    deputy: { name: 'Abhishek Ojha', role: 'Deputy Secretary', photo: null },
    team: team(),
  },
  {
    year: 2023,
    secretary: { name: 'Abhishek Ojha', role: 'Secretary', photo: null },
    deputy: { name: 'Ravi Kant', role: 'Deputy Secretary', photo: null },
    team: team(),
  },
  {
    year: 2024,
    secretary: { name: 'Shreyansh Mall', role: 'Secretary', photo: null },
    deputy: { name: 'Divya Chinmay', role: 'Deputy Secretary', photo: null },
    team: team(),
  },
  {
    year: 2025,
    secretary: { name: 'Mannu Yadav', role: 'Secretary', photo: null },
    deputy: { name: 'Aditya Vaidhya', role: 'Deputy Secretary', photo: null },
    team: team(),
  },
];
