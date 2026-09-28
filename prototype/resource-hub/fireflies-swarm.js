// PROTOTYPE — Home "Synchrony": the firefly swarm behind LandingFireflies.vue.
// One fixed canvas. Every light has a phase, coupled Kuramoto-style so the swarm falls into one
// rhythm, and a target. Targets ride one of two frames on the page: HERO (tree homes and the
// wordmark, which scroll and parallax with the scene) or STAGE (the sticky data shapes). Lights
// past the hero swarm sleep inside a parent light until a shape needs more of them.
const TAU = Math.PI * 2;
export const HERO = 0;
export const STAGE = 1;
const M_HERO = 0;
const M_STAGE = 1;
const M_SLEEP = 2;

// Colour slots. Glow colours are the dark-theme tokens (tokens.css) — lights only glow at night;
// by day (light theme, out of the hero) they are drawn as ink dots in the live theme tokens.
export const COL = {
  FLY: 0,
  PYQ: 1,
  NOTE: 2,
  CULTURAL: 3,
  GAMES: 4,
  TECH: 5,
  TALKS: 6,
  UHC: 7,
  SPARE: 8,
  SEAT: 9,
};
const GLOW = [
  '#ffb54c',
  '#f4b04a',
  '#fff0d2',
  '#f4b04a',
  '#ff7a5c',
  '#93a9ff',
  '#e394d4',
  '#ffc861',
  '#b98545',
  '#f3ebdd',
];
const DOT_TOKENS = [
  '--mari-ink',
  '--mari-ink',
  '--mari',
  '--w-cultural',
  '--w-games',
  '--w-tech',
  '--w-talks',
  '--verm',
  '--line-strong',
  '--ink-2',
];

// Intro beats, in seconds from mount.
export const FLASH = 3.35;
export const END = 4.5;

const clamp = (v, a, b) => (v < a ? a : v > b ? b : v);
const smooth = (a, b, v) => {
  const t = clamp((v - a) / (b - a), 0, 1);
  return t * t * (3 - 2 * t);
};
const rgba = (hex, a) => {
  const n = parseInt(hex.slice(1), 16);
  return `rgba(${n >> 16},${(n >> 8) & 255},${n & 255},${a})`;
};
function hexOf(css) {
  const c = css.trim();
  if (/^#[0-9a-f]{6}$/i.test(c)) return c;
  if (/^#[0-9a-f]{3}$/i.test(c)) return `#${[...c.slice(1)].map((h) => h + h).join('')}`;
  return '#8f4a00';
}

function sprite(draw) {
  const c = document.createElement('canvas');
  c.width = c.height = 64;
  draw(c.getContext('2d'));
  return c;
}
const glowSprite = (hex) =>
  sprite((g) => {
    const gr = g.createRadialGradient(32, 32, 0, 32, 32, 32);
    gr.addColorStop(0, 'rgba(255,250,236,1)');
    gr.addColorStop(0.07, 'rgba(255,244,214,0.95)');
    gr.addColorStop(0.14, rgba(hex, 0.8));
    gr.addColorStop(0.32, rgba(hex, 0.22));
    gr.addColorStop(0.6, rgba(hex, 0.06));
    gr.addColorStop(1, rgba(hex, 0));
    g.fillStyle = gr;
    g.fillRect(0, 0, 64, 64);
  });
const dotSprite = (hex) =>
  sprite((g) => {
    const gr = g.createRadialGradient(32, 32, 0, 32, 32, 32);
    gr.addColorStop(0, rgba(hex, 1));
    gr.addColorStop(0.62, rgba(hex, 1));
    gr.addColorStop(0.72, rgba(hex, 0.22));
    gr.addColorStop(1, rgba(hex, 0));
    g.fillStyle = gr;
    g.fillRect(0, 0, 64, 64);
  });

/**
 * @param {HTMLCanvasElement} canvas
 * @param {object} o
 *   count   — lights in the hero swarm; pool — all lights (the biggest shape needs)
 *   origins() → [{x,y}, {x,y}|null] viewport origins of the HERO and STAGE frames
 *   home(i, out) — writes hero-local {x, y} of light i's tree home (moves with parallax)
 *   river() → {hz, mud} hero-local y of the horizon and the mudflat, for reflections
 *   day() → 0..1, how far the lights have turned into ink dots
 *   onFrame(clock, dt) — the page's own per-frame work (parallax, veil)
 */
export function createSwarm(canvas, o) {
  const ctx = canvas.getContext('2d');
  const N = o.count;
  const n = Math.max(o.pool, N);
  const f32 = () => new Float32Array(n);
  const x = f32();
  const y = f32();
  const vx = f32();
  const vy = f32();
  const th = f32(); // phase
  const om = f32(); // natural frequency (rad/s)
  const dev = f32(); // small spread kept after the swarm syncs
  const a = f32(); // shown alpha (awake-ness)
  const r = f32(); // shown radius
  const lum = f32(); // shown brightness factor
  const kick = f32(); // seconds left out of sync after a pointer scatter
  const wake = f32();
  const s1 = f32();
  const s2 = f32();
  const md = new Uint8Array(n); // current mode
  const nm = new Uint8Array(n); // next mode, taken at time `sw`
  const sw = f32();
  const col = new Uint8Array(n);
  const pcol = new Uint8Array(n);
  // Stage target (stage-local) with its look.
  const stx = f32();
  const sty = f32();
  const ssz = f32();
  const slum = f32();
  const swan = f32();
  const sg = new Int16Array(n).fill(-1);
  const scol = new Uint8Array(n);
  // Wordmark target (hero-local); NaN when the light stays in the trees.
  const wx = f32().fill(NaN);
  const wy = f32().fill(NaN);
  const wt = f32(); // when it leaves its tree for the word
  const hsz = f32(); // size in the hero
  const far = new Uint8Array(n); // lives on the far treeline (smaller, dimmer)

  let clock = o.reduced ? END : 0;
  let running = false;
  let raf = 0;
  let last = 0;
  let dpr = 1;
  let vw = 0;
  let vh = 0;
  let lines = [];
  let lineA = 0;
  let highlight = null;
  let stageOn = false;
  const pointer = { x: -1e4, y: -1e4, on: false, r: 100 };
  const prev = [
    { x: 0, y: 0 },
    { x: 0, y: 0 },
  ];
  const home = { x: 0, y: 0 };
  let glow = GLOW.map(glowSprite);
  let dots = [];

  const rand = (() => {
    let s = 20211;
    return () => ((s = (s * 16807) % 2147483647) - 1) / 2147483646;
  })();

  for (let i = 0; i < n; i++) {
    s1[i] = rand() * TAU;
    s2[i] = rand() * TAU;
    th[i] = rand() * TAU;
    om[i] = TAU * (0.85 + rand() * 0.75);
    dev[i] = (rand() - 0.5) * 0.06;
    md[i] = nm[i] = i < N ? M_HERO : M_SLEEP;
    // Hundreds wake within ~0.6 s of each other; one wakes first, alone.
    wake[i] = i === 0 ? 0.2 : 0.85 + rand() * 0.6;
    hsz[i] = i === 0 ? 3.2 : 1.5 + rand() * 1.1;
    far[i] = i > 0 && rand() < 0.16 ? 1 : 0;
    if (far[i]) hsz[i] *= 0.6;
    r[i] = hsz[i];
    lum[i] = 1;
  }
  // The first light flashes at 0.5 s and again at 1.3 s: a lone blink in the dark.
  om[0] = TAU * 1.25;
  th[0] = -om[0] * 0.5;
  if (o.reduced) th.fill(0);

  let lineInk = '#c9bba5';
  function themeColors() {
    const cs = getComputedStyle(document.documentElement);
    dots = DOT_TOKENS.map((t) => dotSprite(hexOf(cs.getPropertyValue(t))));
    lineInk = hexOf(cs.getPropertyValue('--line-strong'));
  }
  themeColors();

  function resize() {
    vw = innerWidth;
    vh = innerHeight;
    dpr = Math.min(devicePixelRatio || 1, 1.5);
    canvas.width = Math.round(vw * dpr);
    canvas.height = Math.round(vh * dpr);
    pointer.r = vw < 700 ? 70 : 110;
  }
  resize();

  // ---- targets --------------------------------------------------------------------------
  function setWord(points) {
    // points: hero-local, already fitted to the <h1>. Spread the flight starts left to right.
    wx.fill(NaN);
    wy.fill(NaN);
    const ids = [...Array(N).keys()].filter((i) => !far[i]);
    const m = Math.min(points.length, ids.length);
    // Pair lights with points by x so flights run roughly parallel instead of crossing.
    const cur = ids
      .map((i) => {
        o.home(i, home);
        return { i, x: home.x + (rand() - 0.5) * 200 };
      })
      .sort((p, q) => p.x - q.x);
    const pick = [];
    const step = cur.length / m;
    for (let k = 0; k < m; k++) pick.push(cur[Math.floor(k * step)].i);
    const pts = points.slice(0, m).sort((p, q) => p.x - q.x);
    const x0 = pts[0]?.x ?? 0;
    const span = (pts[m - 1]?.x ?? 1) - x0 || 1;
    pick.forEach((i, k) => {
      wx[i] = pts[k].x;
      wy[i] = pts[k].y;
      wt[i] = 1.65 + ((pts[k].x - x0) / span) * 0.55 + rand() * 0.25;
    });
  }

  function setHero() {
    stageOn = false;
    const t = clock;
    for (let i = 0; i < n; i++) {
      nm[i] = i < N ? M_HERO : M_SLEEP;
      sw[i] = t + rand() * 0.35;
      pcol[i] = col[i];
    }
  }

  // layout: { pts: [{x, y, c, s, g}], lines, spares: {W, H, pad} }, stage-local.
  function setShape(layout, { instant = false } = {}) {
    stageOn = true;
    lines = layout.lines ?? [];
    const t = clock;
    const pts = layout.pts;
    const m = pts.length;
    const O = o.origins();
    const order = pts.map((_, k) => k);
    for (let k = m - 1; k > 0; k--) {
      const j = Math.floor(rand() * (k + 1));
      [order[k], order[j]] = [order[j], order[k]];
    }
    const heroTake = Math.min(m, N);
    // Hero lights pair with their targets by x; extras hatch from a parent light.
    const lights = [...Array(N).keys()].sort((p, q) => x[p] - x[q]);
    const mine = order.slice(0, heroTake).sort((p, q) => pts[p].x - pts[q].x);
    const W = layout.W || 1;
    const assign = (i, p) => {
      pcol[i] = col[i];
      nm[i] = M_STAGE;
      stx[i] = p.x;
      sty[i] = p.y;
      ssz[i] = p.s;
      slum[i] = p.l ?? 1;
      swan[i] = p.w ?? 0.5;
      scol[i] = p.c;
      sg[i] = p.g ?? -1;
      sw[i] = instant ? t : t + (p.x / W) * 0.3 + rand() * 0.2;
    };
    // Spread the pairing over all hero lights so the shape draws from the whole swarm.
    const stride = N / Math.max(1, heroTake);
    const used = new Uint8Array(N);
    for (let k = 0; k < heroTake; k++) {
      const i = lights[Math.min(N - 1, Math.floor(k * stride))];
      used[i] = 1;
      assign(i, pts[mine[k]]);
    }
    for (let k = heroTake; k < m; k++) {
      const i = N + (k - heroTake);
      if (md[i] === M_SLEEP) {
        const p = i % N;
        x[i] = x[p];
        y[i] = y[p];
        vx[i] = vy[i] = 0;
      }
      assign(i, pts[order[k]]);
      sw[i] = instant ? t : t + 0.12 + (pts[order[k]].x / W) * 0.3 + rand() * 0.25;
    }
    for (let i = N + Math.max(0, m - heroTake); i < n; i++) {
      nm[i] = M_SLEEP;
      sw[i] = t + rand() * 0.3;
    }
    // Spare lights dim and drift to the edges of the stage.
    const sp = layout.spares;
    for (let i = 0; i < N; i++) {
      if (used[i]) continue;
      const side = rand();
      let px;
      let py;
      if (side < 0.36) {
        px = rand() * sp.W;
        py = -sp.pad * (0.25 + rand() * 0.7);
      } else if (side < 0.72) {
        px = rand() * sp.W;
        py = sp.H + sp.pad * (0.25 + rand() * 0.7);
      } else {
        px = side < 0.86 ? -sp.pad * (0.2 + rand() * 0.7) : sp.W + sp.pad * (0.2 + rand() * 0.7);
        py = rand() * sp.H;
      }
      assign(i, { x: px, y: py, c: COL.SPARE, s: 1.1, l: 0.09, w: 7 });
      sw[i] = instant ? t : t + rand() * 0.5;
    }
    if (O[STAGE] && instant) snap();
  }

  function setHighlight(groups) {
    highlight = groups && groups.size ? groups : null;
  }

  // ---- simulation -----------------------------------------------------------------------
  const tgt = { x: 0, y: 0 };
  function target(i, O, t) {
    const mode = md[i];
    if (mode === M_STAGE) {
      const w = swan[i];
      tgt.x = O[STAGE].x + stx[i] + Math.sin(t * 0.7 + s1[i]) * w;
      tgt.y = O[STAGE].y + sty[i] + Math.cos(t * 0.6 + s2[i]) * w;
      return;
    }
    if (mode === M_SLEEP) {
      const p = i % N;
      tgt.x = x[p];
      tgt.y = y[p];
      return;
    }
    if (!Number.isNaN(wx[i]) && t >= wt[i]) {
      tgt.x = O[HERO].x + wx[i] + Math.sin(t * 0.9 + s1[i]) * 1.2;
      tgt.y = O[HERO].y + wy[i] + Math.cos(t * 0.8 + s2[i]) * 1.2;
      return;
    }
    o.home(i, home);
    const w = far[i] ? 2 : 6;
    tgt.x = O[HERO].x + home.x + Math.sin(t * 0.31 + s1[i]) * w + Math.sin(t * 0.83 + s2[i]) * 2;
    tgt.y = O[HERO].y + home.y + Math.cos(t * 0.27 + s2[i]) * w * 0.7;
  }

  // Lay every light on its target. `place` only moves them (used before the intro starts, so
  // lights wake where they live instead of flying in from the corner).
  function snap(place = false) {
    const O = o.origins();
    for (let i = 0; i < n; i++) {
      if (place) {
        if (md[i] !== M_HERO) continue;
        target(i, O, clock);
        x[i] = tgt.x;
        y[i] = tgt.y;
        continue;
      }
      md[i] = nm[i];
      col[i] = md[i] === M_STAGE ? scol[i] : COL.FLY;
      if (md[i] === M_SLEEP && i >= N) {
        a[i] = 0;
        continue;
      }
      if (md[i] === M_STAGE && !O[STAGE]) continue;
      target(i, O, clock);
      x[i] = tgt.x;
      y[i] = tgt.y;
      vx[i] = vy[i] = 0;
      a[i] = md[i] === M_SLEEP ? 0 : 1;
      r[i] = md[i] === M_STAGE ? ssz[i] : hsz[i];
      lum[i] = md[i] === M_STAGE ? slum[i] : far[i] ? 0.55 : 1;
      if (md[i] === M_STAGE && highlight && sg[i] >= 0)
        lum[i] *= highlight.has(sg[i]) ? 1.25 : 0.22;
    }
    if (!place) lineA = stageOn && lines.length ? 1 : 0;
    prev[0] = { ...O[0] };
    if (O[1]) prev[1] = { ...O[1] };
  }

  // Everything the intro does is a function of the clock, so skipping just moves the clock.
  function skip() {
    if (clock >= END) return;
    clock = END;
    for (let i = 0; i < n; i++) th[i] = 0;
    snap();
  }

  function step(dt) {
    const t = clock;
    const O = o.origins();
    const d0x = O[0].x - prev[0].x;
    const d0y = O[0].y - prev[0].y;
    const d1x = O[1] ? O[1].x - prev[1].x : 0;
    const d1y = O[1] ? O[1].y - prev[1].y : 0;

    // Mean field of the awake swarm.
    let cs = 0;
    let sn = 0;
    let cnt = 0;
    for (let i = 0; i < n; i++) {
      if (a[i] < 0.3) continue;
      cs += Math.cos(th[i]);
      sn += Math.sin(th[i]);
      cnt++;
    }
    const R = cnt ? Math.hypot(cs, sn) / cnt : 0;
    const psi = Math.atan2(sn, cs);

    const settle = smooth(FLASH, END, t);
    const K = 3.4 * smooth(1.2, 2.6, t) * (1 - settle) + 1.8 * settle;
    const P = 16 * smooth(2.45, 3.1, t) * (1 - smooth(3.6, 4.3, t));
    const phi = TAU * 1.1 * (t - FLASH);
    const ripple = 0.006 * smooth(1.7, 2.2, t) * (1 - smooth(2.7, 3.2, t));
    const breathe = TAU * 0.42;

    for (let i = 0; i < n; i++) {
      if (t >= sw[i] && md[i] !== nm[i]) {
        md[i] = nm[i];
        col[i] = md[i] === M_STAGE ? scol[i] : COL.FLY;
      } else if (t >= sw[i] && md[i] === M_STAGE && col[i] !== scol[i]) col[i] = scol[i];
      const mode = md[i];
      if (mode === M_SLEEP && a[i] < 0.01 && i >= N) {
        const p = i % N;
        x[i] = x[p];
        y[i] = y[p];
        vx[i] = vy[i] = 0;
        a[i] = 0;
        continue;
      }
      // Ride the frame the light belongs to (scroll, sticky).
      if (mode === M_STAGE) {
        x[i] += d1x;
        y[i] += d1y;
      } else if (mode === M_HERO) {
        x[i] += d0x;
        y[i] += d0y;
      }

      // Phase: own rhythm + pull to the swarm + (late in the intro) a pacemaker for the flash.
      const k = kick[i] > 0 ? 0 : 1;
      if (kick[i] > 0) kick[i] = Math.max(0, kick[i] - dt);
      const w = om[i] * (1 - settle) + breathe * (1 + dev[i]) * settle;
      const rip = ripple * x[i];
      th[i] += (w + k * K * R * Math.sin(psi - th[i] - rip) + k * P * Math.sin(phi - th[i])) * dt;
      if (th[i] > TAU) th[i] -= TAU;
      else if (th[i] < 0) th[i] += TAU;

      target(i, O, t);
      const dx = tgt.x - x[i];
      const dy = tgt.y - y[i];
      const dist = Math.hypot(dx, dy);
      const stiff = mode === M_SLEEP ? 16 : mode === M_STAGE ? 24 : 11;
      const damp = 2 * Math.sqrt(stiff) * (mode === M_STAGE ? 0.92 : 0.82);
      let ax = dx * stiff - vx[i] * damp;
      let ay = dy * stiff - vy[i] * damp;
      // A little curl while in flight, so flights are swirls, not rails.
      if (dist > 30) {
        const f = Math.min(dist, 260) * 3.2 * smooth(30, 120, dist);
        const ang = Math.sin(x[i] * 0.009 + t * 0.8) * 2.2 + Math.cos(y[i] * 0.011 - t * 0.6) * 2.2;
        ax += Math.cos(ang) * f;
        ay += Math.sin(ang) * f;
      }
      if (pointer.on) {
        const px = x[i] - pointer.x;
        const py = y[i] - pointer.y;
        const pd = Math.hypot(px, py);
        if (pd < pointer.r && pd > 0.01) {
          const push = (1 - pd / pointer.r) * 9000;
          ax += (px / pd) * push;
          ay += (py / pd) * push;
          if (kick[i] < 0.2) th[i] = rand() * TAU;
          kick[i] = 1.1 + rand() * 0.8;
        }
      }
      vx[i] += ax * dt;
      vy[i] += ay * dt;
      const sp = Math.hypot(vx[i], vy[i]);
      if (sp > 1500) {
        vx[i] *= 1500 / sp;
        vy[i] *= 1500 / sp;
      }
      x[i] += vx[i] * dt;
      y[i] += vy[i] * dt;

      // Looks ease toward the target look.
      const awake = mode === M_SLEEP ? 0 : t >= wake[i] ? 1 : 0;
      a[i] += (awake - a[i]) * Math.min(1, dt * (awake ? 5 : 3));
      const rr = mode === M_STAGE ? ssz[i] : hsz[i];
      r[i] += (rr - r[i]) * Math.min(1, dt * 5);
      let l = mode === M_STAGE ? slum[i] : far[i] ? 0.55 : 1;
      if (mode === M_STAGE && highlight && sg[i] >= 0) l *= highlight.has(sg[i]) ? 1.25 : 0.22;
      lum[i] += (l - lum[i]) * Math.min(1, dt * 5);
    }
    lineA += ((stageOn && lines.length ? 1 : 0) - lineA) * Math.min(1, dt * 3);
    prev[0] = { ...O[0] };
    if (O[1]) prev[1] = { ...O[1] };
  }

  // ---- drawing --------------------------------------------------------------------------
  function brightness(i, t) {
    const pulse = 0.5 + 0.5 * Math.cos(th[i]);
    if (md[i] === M_STAGE) return 0.74 + 0.26 * pulse * pulse;
    const settle = smooth(FLASH, END, t);
    const sharp = 9 - 6.5 * settle;
    // Lights glow a little between flashes once the swarm starts to gather; flying ones glow
    // more, so every flight into the name is a visible streak.
    const floor = 0.05 + 0.12 * smooth(1.6, 2.6, t) + 0.2 * settle;
    const fly = Math.min(1, Math.hypot(vx[i], vy[i]) / 380);
    return Math.max(floor + (1 - floor) * Math.pow(pulse, sharp), 0.7 * fly);
  }

  function draw() {
    const t = clock;
    const O = o.origins();
    const day = o.day();
    const boost =
      1 + 2.2 * Math.exp(-Math.max(0, t - FLASH) / 0.42) * smooth(FLASH - 0.2, FLASH, t);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, vw, vh);

    if (lineA > 0.01 && O[STAGE]) {
      ctx.globalCompositeOperation = 'source-over';
      ctx.lineWidth = 1.2;
      ctx.strokeStyle = day > 0.5 ? lineInk : 'rgba(244,176,74,0.34)';
      ctx.globalAlpha = lineA;
      ctx.beginPath();
      for (const [x1, y1, x2, y2] of lines) {
        const ox = O[STAGE].x;
        const oy = O[STAGE].y;
        const my = (y1 + y2) / 2;
        ctx.moveTo(ox + x1, oy + y1);
        ctx.bezierCurveTo(ox + x1, oy + my, ox + x2, oy + my, ox + x2, oy + y2);
      }
      ctx.stroke();
    }

    const night = 1 - day;
    if (night > 0.01) {
      ctx.globalCompositeOperation = 'lighter';
      const rv = o.river();
      for (let i = 0; i < n; i++) {
        const al = a[i];
        if (al < 0.01) continue;
        const b = brightness(i, t) * (md[i] === M_HERO ? boost : 1);
        const w = al * lum[i] * b * night;
        if (w < 0.008) continue;
        const px = x[i];
        const py = y[i];
        if (px < -40 || py < -40 || px > vw + 40 || py > vh + 40) continue;
        const stage = md[i] === M_STAGE;
        const s = r[i] * (stage ? 7 : 6 + 5 * Math.min(1.4, b));
        ctx.globalAlpha = Math.min(1, w);
        ctx.drawImage(glow[col[i]], px - s / 2, py - s / 2, s, s);
        // The river mirrors the hero's lights, broken up by the water.
        if (md[i] === M_HERO && rv) {
          const ly = py - O[HERO].y;
          if (ly < rv.hz) {
            const ry = 2 * rv.hz - ly;
            if (ry < rv.mud) {
              const fade = 1 - (ry - rv.hz) / (rv.mud - rv.hz);
              ctx.globalAlpha = Math.min(1, w * 0.3 * fade);
              const wob = Math.sin(t * 2.3 + ry * 0.09) * 2.5;
              ctx.drawImage(glow[col[i]], px - s / 2 + wob, O[HERO].y + ry - s * 0.28, s, s * 0.56);
            }
          }
        }
      }
    }
    if (day > 0.01) {
      ctx.globalCompositeOperation = 'source-over';
      for (let i = 0; i < n; i++) {
        const al = a[i];
        if (al < 0.01) continue;
        // Spare lights barely show by day: dust on paper reads as dirt, not fireflies.
        const w = al * lum[i] * day * (col[i] === COL.SPARE ? 0.35 : md[i] === M_STAGE ? 1 : 0.8);
        if (w < 0.01) continue;
        const px = x[i];
        const py = y[i];
        if (px < -20 || py < -20 || px > vw + 20 || py > vh + 20) continue;
        const s = r[i] * 2.6;
        ctx.globalAlpha = Math.min(1, w);
        ctx.drawImage(dots[col[i]], px - s / 2, py - s / 2, s, s);
      }
    }
    ctx.globalAlpha = 1;
    ctx.globalCompositeOperation = 'source-over';
  }

  // ---- loop -----------------------------------------------------------------------------
  function frame(ts) {
    raf = requestAnimationFrame(frame);
    const elapsed = Math.max(0, (ts - last) / 1000);
    const dt = Math.min(1 / 15, elapsed);
    last = ts;
    // Keep the intro on wall time even when the renderer drops frames. Physics stays bounded.
    clock += elapsed;
    o.onFrame?.(clock, dt);
    step(dt);
    draw();
  }

  return {
    count: N,
    isFar: (i) => far[i] === 1,
    get clock() {
      return clock;
    },
    start() {
      if (running || o.reduced) return;
      running = true;
      last = performance.now();
      raf = requestAnimationFrame(frame);
    },
    stop() {
      running = false;
      cancelAnimationFrame(raf);
    },
    // Reduced motion: no loop — lay everything on its target and draw once.
    still() {
      o.onFrame?.(clock, 0);
      snap();
      draw();
    },
    resize,
    setWord,
    setHero,
    setShape,
    setHighlight,
    skip,
    place: () => snap(true),
    theme: themeColors,
    pointer,
    destroy() {
      this.stop();
      glow = [];
      dots = [];
      canvas.width = canvas.height = 0;
    },
  };
}
