// Painted pat plates beyond Home: the Teams communities and crew, the event posters' figures,
// the Night Owl rooms, the 404 and the sign-in door. Same shape as pat.js FIGS (PatFigure):
// one generated patachitra plate split into a base and moving parts; part boxes and pivots are
// % of the trimmed plate. Generated with Codex imagegen, keyed and cut by scratchpad tooling.
const u = (f) => new URL(`../assets/art/${f}`, import.meta.url).href;
const fig = ({ file, w, h, view, parts = [] }) => ({
  src: u(file),
  w,
  h,
  view,
  parts: parts.map(({ file: pf, ...pt }) => ({ src: u(pf), ...pt })),
});

const PLATES = {
  cultural: {
    file: 'cultural.webp',
    w: 1276,
    h: 897,
    parts: [
      {
        file: 'cultural-ektara.webp',
        cls: 'ektara',
        x: 57.37,
        y: 0.89,
        w: 18.03,
        h: 30.66,
        ox: 36.96,
        oy: 59.27,
      },
    ],
  },
  tech: {
    file: 'tech.webp',
    w: 1337,
    h: 879,
    parts: [
      {
        file: 'tech-gear.webp',
        cls: 'gear',
        x: 60.06,
        y: 9.44,
        w: 19.52,
        h: 29.01,
        ox: 49.43,
        oy: 49.41,
      },
    ],
  },
  games: {
    file: 'games.webp',
    w: 1309,
    h: 843,
    parts: [
      {
        file: 'games-knight.webp',
        cls: 'knight',
        x: 39.65,
        y: 0.95,
        w: 6.95,
        h: 19.1,
        ox: 24.18,
        oy: 95.65,
      },
    ],
  },
  talks: {
    file: 'talks.webp',
    w: 1308,
    h: 874,
    parts: [
      {
        file: 'talks-gesture.webp',
        cls: 'gesture',
        x: 28.9,
        y: 22.65,
        w: 6.35,
        h: 10.76,
        ox: 13.25,
        oy: 89.36,
      },
    ],
  },
  meetups: {
    file: 'meetups.webp',
    w: 1324,
    h: 880,
    parts: [
      {
        file: 'meetups-kettle.webp',
        cls: 'kettle',
        x: 41.92,
        y: 3.86,
        w: 10.73,
        h: 19.66,
        ox: 83.1,
        oy: 16.18,
      },
    ],
  },
  pr: {
    file: 'pr.webp',
    w: 1325,
    h: 897,
    parts: [
      {
        file: 'pr-scroll1.webp',
        cls: 'scroll',
        x: 20.38,
        y: 13.49,
        w: 17.58,
        h: 23.08,
        ox: 51.93,
        oy: 48.79,
        i: 0,
      },
      {
        file: 'pr-scroll2.webp',
        cls: 'scroll',
        x: 10.94,
        y: 28.76,
        w: 18.87,
        h: 27.2,
        ox: 48.4,
        oy: 48.77,
        i: 1,
      },
      {
        file: 'pr-scroll3.webp',
        cls: 'scroll',
        x: 5.58,
        y: 50.61,
        w: 20.6,
        h: 15.16,
        ox: 50.18,
        oy: 50.0,
        i: 2,
      },
    ],
  },
  design: {
    file: 'design.webp',
    w: 1266,
    h: 854,
    parts: [
      {
        file: 'design-brush.webp',
        cls: 'brush',
        x: 57.19,
        y: 4.33,
        w: 16.27,
        h: 18.85,
        ox: 25.73,
        oy: 94.41,
      },
    ],
  },
  webops: {
    file: 'webops.webp',
    w: 1283,
    h: 831,
    parts: [
      {
        file: 'webops-lantern.webp',
        cls: 'lantern',
        x: 40.45,
        y: 7.1,
        w: 11.69,
        h: 33.57,
        ox: 48.0,
        oy: 0.0,
      },
    ],
  },
  'owl-en': {
    file: 'owl-en.webp',
    w: 876,
    h: 834,
    parts: [
      {
        file: 'owl-en-moon.webp',
        cls: 'moon',
        x: 74.09,
        y: 4.92,
        w: 21.12,
        h: 22.18,
        ox: 49.73,
        oy: 50.27,
      },
    ],
  },
  'owl-hi': {
    file: 'owl-hi.webp',
    w: 844,
    h: 851,
    parts: [
      {
        file: 'owl-hi-moon.webp',
        cls: 'moon',
        x: 32.11,
        y: 0.94,
        w: 24.17,
        h: 23.5,
        ox: 50.0,
        oy: 50.5,
      },
      {
        file: 'owl-hi-lantern.webp',
        cls: 'lantern',
        x: 66.71,
        y: 16.33,
        w: 17.54,
        h: 41.13,
        ox: 50.68,
        oy: 0.57,
      },
    ],
  },
  lost: {
    file: 'lost.webp',
    w: 1325,
    h: 868,
    parts: [
      {
        file: 'lost-lantern.webp',
        cls: 'lantern',
        x: 29.96,
        y: 0.92,
        w: 8.3,
        h: 30.99,
        ox: 71.82,
        oy: 18.59,
      },
      {
        file: 'lost-oar-float.webp',
        cls: 'oar-float',
        x: 60.53,
        y: 72.35,
        w: 30.34,
        h: 21.2,
        ox: 49.5,
        oy: 48.91,
      },
    ],
  },
  login: {
    file: 'login.webp',
    w: 1337,
    h: 885,
    parts: [
      {
        file: 'login-lamp.webp',
        cls: 'lamp',
        x: 78.09,
        y: 19.55,
        w: 2.77,
        h: 8.02,
        ox: 51.35,
        oy: 98.59,
      },
    ],
  },
};

export const ART = Object.fromEntries(Object.entries(PLATES).map(([k, v]) => [k, fig(v)]));
// Teams ids for the community plates.
ART.technical = ART.tech;
ART.esports = ART.games;

// Event posters use the finished plate (base with its parts in place) as one still image.
export const POSTER_ART = Object.fromEntries(
  ['cultural', 'tech', 'games', 'talks', 'meetups'].map((w) => [w, u(`${w}-still.webp`)])
);
