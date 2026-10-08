// Home ("Pat"): the painted cut-outs and their moving parts.
// Each figure is one generated patachitra plate (landing-assets/v2) split into a base and parts
// (tail, flame, oars…) by scratchpad tooling. Part boxes and pivots are % of the full plate, so
// the same numbers place a part at any size. `under` parts sit beneath the base (a drumstick
// behind the fist that holds it). `view` trims empty paper off the top/bottom of a plate.
const u = (f) => new URL(`../assets/pat/${f}`, import.meta.url).href;

export const ASSET = {
  forest: u('forest-core.webp'),
  forest800: u('forest-core-800.webp'),
  band: u('band.webp'),
  edge: u('edge.webp'),
  grain: u('grain.webp'),
  brush: u('brush.webp'),
  brushV: u('brush-v.webp'),
};

// Forest plate geometry (source px) for the water canvas: the river band and the fishing boat.
export const FOREST = {
  w: 1536,
  h: 918,
  river: 716,
  boat: { x: 300, y: 555, w: 460, h: 260 },
};

const p = (file, box, cls, extra = {}) => ({ src: u(file), cls, ...box, ...extra });

export const FIGS = {
  tiger: {
    src: u('tiger-body.webp'),
    w: 1536,
    h: 1024,
    parts: [
      p('tiger-tail.webp', { x: 73.63, y: 0.49, w: 26.37, h: 42.48, ox: 30.62, oy: 82.76 }, 'tail'),
      p('tiger-head.webp', { x: 0.26, y: 2.54, w: 26.56, h: 45.41, ox: 79.9, oy: 61.08 }, 'head'),
    ],
  },
  reader: {
    src: u('reader-base.webp'),
    w: 1254,
    h: 1254,
    view: [0.02, 0.98],
    parts: [
      p('reader-rays.webp', { x: 76.32, y: 65.37, w: 12.28, h: 12.36, ox: 48.7, oy: 60 }, 'rays'),
      p(
        'reader-flame.webp',
        { x: 79.35, y: 66.72, w: 6.22, h: 11.64, ox: 47.44, oy: 98.63 },
        'flame'
      ),
      p(
        'reader-paper-a.webp',
        { x: 69.86, y: 50.64, w: 17.22, h: 10.13, ox: 57.41, oy: 51.18 },
        'leaf-a'
      ),
      p(
        'reader-paper-b.webp',
        { x: 89.63, y: 75.18, w: 8.61, h: 7.34, ox: 0.93, oy: 54.35 },
        'leaf-b'
      ),
      p(
        'reader-paper-c.webp',
        { x: 59.97, y: 87.56, w: 18.58, h: 9.73, ox: 89.27, oy: 50.82 },
        'leaf-c'
      ),
    ],
  },
  drummers: {
    src: u('drummers-base.webp'),
    w: 1536,
    h: 1024,
    parts: [
      p(
        'drummers-stick.webp',
        { x: 37.43, y: 23.93, w: 4.56, h: 22.56, ox: 72.86, oy: 66.23 },
        'dhak-stick',
        { under: true }
      ),
      p(
        'drummers-feathers.webp',
        { x: 3.32, y: 6.45, w: 15.82, h: 38.18, ox: 65.43, oy: 59.85 },
        'plume'
      ),
    ],
  },
  gathering: {
    src: u('gathering-base.webp'),
    w: 1536,
    h: 1024,
    parts: [
      p(
        'gathering-boat-l.webp',
        { x: 0.2, y: 77.54, w: 30.92, h: 16.41, ox: 49.89, oy: 51.19 },
        'boat-l'
      ),
      p(
        'gathering-boat-r.webp',
        { x: 75.52, y: 73.44, w: 24.48, h: 21.88, ox: 47.87, oy: 57.14 },
        'boat-r'
      ),
    ],
  },
  rowers: {
    src: u('rowers-base.webp'),
    w: 1536,
    h: 1024,
    view: [0.17, 0.8],
    parts: [
      p(
        'rowers-stick.webp',
        { x: 7.29, y: 38.28, w: 5.27, h: 7.03, ox: 38.27, oy: 62.5 },
        'drum-stick',
        { under: true }
      ),
      ...[
        [11.59, 9.24, 18.55, 95.42, -5.26],
        [19.08, 10.16, 20.7, 95.44, -4.72],
        [27.8, 9.38, 20.51, 95.44, -4.76],
        [34.9, 9.11, 20.41, 95.16, -4.78],
        [42.64, 9.31, 20.51, 95.55, -4.76],
        [50.59, 8.53, 20.7, 94.6, -4.72],
        [58.66, 8.2, 20.7, 93.66, -4.72],
        [67.12, 7.03, 20.61, 91.56, -4.74],
      ].map(([x, w, h, ox, oy], i) =>
        p(`rowers-oar-${i + 1}.webp`, { x, y: 54.88, w, h, ox, oy }, 'oar', { i })
      ),
    ],
  },
};
