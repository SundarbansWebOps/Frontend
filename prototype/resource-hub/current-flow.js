// PROTOTYPE — Home variant 3 ("Current"): the streakline engine behind the hero. Particles are
// advected through curl noise plus a tidal drift (like the earth.nullschool wind map); a word
// mask turns the name into an obstacle the current parts around, while a second population
// lives inside the letters and glows. Pure 2D canvas: each frame redraws short ring-buffer
// trails from scratch, so reversing the tide never leaves ghost trails behind.

const K = 16; // trail length, in frames
const CELL = 26; // flow-grid cell, CSS px
const MS = 4; // word mask is sampled at 1/4 of CSS px

// ---- noise: hashed value noise in 3D (x, y, time), smooth enough for a curl potential ----
function hash(x, y, z) {
  let h = (x * 374761393 + y * 668265263 + z * 1274126177) | 0;
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  return ((h ^ (h >>> 16)) >>> 0) / 4294967295;
}
const fade = (t) => t * t * t * (t * (t * 6 - 15) + 10);
function noise3(x, y, z) {
  const xi = Math.floor(x);
  const yi = Math.floor(y);
  const zi = Math.floor(z);
  const u = fade(x - xi);
  const v = fade(y - yi);
  const w = fade(z - zi);
  const lerp = (a, b, t) => a + (b - a) * t;
  const c = (dx, dy, dz) => hash(xi + dx, yi + dy, zi + dz);
  return lerp(
    lerp(lerp(c(0, 0, 0), c(1, 0, 0), u), lerp(c(0, 1, 0), c(1, 1, 0), u), v),
    lerp(lerp(c(0, 0, 1), c(1, 0, 1), u), lerp(c(0, 1, 1), c(1, 1, 1), u), v),
    w
  );
}

export function createFlow(canvas) {
  const ctx = canvas.getContext('2d');
  let W = 0;
  let H = 0;
  let dpr = 1;
  let N = 0; // particles outside the letters
  let M = 0; // particles inside the letters
  let px, py, age, life, trail, head;
  let gw = 0;
  let gh = 0;
  let gridU, gridV;
  // Word mask: blurred coverage m (0..1) and its gradient, which points into the letters.
  let mw = 0;
  let mh = 0;
  let mask = null;
  let mgx = null;
  let mgy = null;
  let inside = []; // [x, y] spawn points inside the letters
  let frame = 0;
  let time = 0;

  const p = {
    dir: Math.PI / 2, // drift direction, radians (screen space)
    speed: 1.8, // drift, px per 60 fps frame
    tide: 1, // -1..1 multiplies the drift: the tide turning
    turb: 0.6, // curl noise amplitude
    obstacle: 0, // 0..1 how hard the letters push the current aside
    glow: 0, // 0..1 opacity of the in-letter population
    alpha: 1, // overall streak opacity (intro fade-in)
    pointer: null, // { x, y, vx, vy, s }
    zoom: 0, // camera dive speed: streaks stretch outward from the centre while it's > 0
    colors: { streak: '#8f4a00', glow: '#f2a93b', glowHead: '#ffd488', lighter: false },
  };

  function resize(w, h, ratio) {
    W = w;
    H = h;
    dpr = ratio;
    canvas.width = Math.round(w * dpr);
    canvas.height = Math.round(h * dpr);
    // Density scales with area: ~1 streak per 640 px², capped for big screens.
    N = Math.min(1800, Math.round((w * h) / 820));
    const total = N + 1100;
    px = new Float32Array(total);
    py = new Float32Array(total);
    age = new Float32Array(total);
    life = new Float32Array(total);
    trail = new Float32Array(total * K * 2);
    head = 0;
    gw = Math.ceil(w / CELL) + 2;
    gh = Math.ceil(h / CELL) + 2;
    gridU = new Float32Array(gw * gh);
    gridV = new Float32Array(gw * gh);
    for (let i = 0; i < total; i++) spawn(i, true);
  }

  function spawn(i, anyAge) {
    const inLetter = i >= N;
    let x = 0;
    let y = 0;
    if (inLetter) {
      if (!inside.length) {
        age[i] = 0;
        life[i] = 0; // dormant until there is a word
        px[i] = -99;
        py[i] = -99;
        fillTrail(i, -99, -99);
        return;
      }
      [x, y] = inside[(Math.random() * inside.length) | 0];
      x += (Math.random() - 0.5) * MS;
      y += (Math.random() - 0.5) * MS;
    } else {
      // Keep fresh streaks out of the letters once the word is solid.
      for (let t = 0; t < 6; t++) {
        x = Math.random() * W;
        y = Math.random() * H;
        if (sampleMask(x, y) < 0.3 || p.obstacle < 0.5) break;
      }
    }
    px[i] = x;
    py[i] = y;
    life[i] = inLetter ? 60 + Math.random() * 90 : 120 + Math.random() * 220;
    age[i] = anyAge ? Math.random() * life[i] : 0;
    fillTrail(i, x, y);
  }

  function fillTrail(i, x, y) {
    const o = i * K * 2;
    for (let k = 0; k < K; k++) {
      trail[o + k * 2] = x;
      trail[o + k * 2 + 1] = y;
    }
  }

  // ---- the word ----
  // spec: { text, font, x, baseline, letterSpacing } in CSS px relative to the canvas.
  function setWord(spec) {
    if (!W) return;
    mw = Math.ceil(W / MS);
    mh = Math.ceil(H / MS);
    const off = new OffscreenCanvas(mw, mh);
    const c = off.getContext('2d', { willReadFrequently: true });
    c.scale(1 / MS, 1 / MS);
    c.font = spec.font;
    c.letterSpacing = spec.letterSpacing || '0px';
    c.fillStyle = '#fff';
    c.fillText(spec.text, spec.x, spec.baseline);
    const sharp = c.getImageData(0, 0, mw, mh).data;
    // Blur a copy for the soft field whose gradient steers the current.
    const off2 = new OffscreenCanvas(mw, mh);
    const c2 = off2.getContext('2d', { willReadFrequently: true });
    c2.filter = `blur(${Math.max(1.5, spec.size / 90)}px)`;
    c2.drawImage(off, 0, 0);
    // Islands: other copy the current should flow around, without a glow of its own.
    c2.fillStyle = '#fff';
    for (const r of spec.islands ?? [])
      c2.fillRect((r.x - 6) / MS, (r.y - 4) / MS, (r.w + 12) / MS, (r.h + 8) / MS);
    const soft = c2.getImageData(0, 0, mw, mh).data;
    mask = new Float32Array(mw * mh);
    mgx = new Float32Array(mw * mh);
    mgy = new Float32Array(mw * mh);
    inside = [];
    for (let j = 0; j < mw * mh; j++) mask[j] = soft[j * 4 + 3] / 255;
    for (let y = 1; y < mh - 1; y++) {
      for (let x = 1; x < mw - 1; x++) {
        const j = y * mw + x;
        mgx[j] = (mask[j + 1] - mask[j - 1]) / 2;
        mgy[j] = (mask[j + mw] - mask[j - mw]) / 2;
        if (sharp[j * 4 + 3] > 200 && soft[j * 4 + 3] > 160) inside.push([x * MS, y * MS]);
      }
    }
    // In-letter population scales with ink area.
    M = Math.min(1100, Math.round(inside.length / 1.8));
    for (let i = N; i < N + 1100; i++) spawn(i, true);
  }

  function sampleMask(x, y) {
    if (!mask) return 0;
    const i = (x / MS) | 0;
    const j = (y / MS) | 0;
    if (i < 0 || j < 0 || i >= mw || j >= mh) return 0;
    return mask[j * mw + i];
  }

  // ---- flow grid: curl of a drifting noise potential, rebuilt every other frame ----
  function buildGrid() {
    const s = 0.0026;
    const z = time * 0.00018;
    const pot = new Float32Array(gw * gh);
    for (let j = 0; j < gh; j++)
      for (let i = 0; i < gw; i++)
        pot[j * gw + i] =
          noise3(i * CELL * s, j * CELL * s, z) +
          0.35 * noise3(i * CELL * s * 2.3, j * CELL * s * 2.3, z * 1.7 + 9);
    const k = (1 / (2 * CELL * s)) * 1.1;
    for (let j = 1; j < gh - 1; j++)
      for (let i = 1; i < gw - 1; i++) {
        const o = j * gw + i;
        gridU[o] = (pot[o + gw] - pot[o - gw]) * k;
        gridV[o] = -(pot[o + 1] - pot[o - 1]) * k;
      }
  }

  function flowAt(x, y) {
    const fx = Math.min(gw - 2.001, Math.max(1, x / CELL + 1));
    const fy = Math.min(gh - 2.001, Math.max(1, y / CELL + 1));
    const i = fx | 0;
    const j = fy | 0;
    const u = fx - i;
    const v = fy - j;
    const o = j * gw + i;
    const a = (A) =>
      (A[o] * (1 - u) + A[o + 1] * u) * (1 - v) + (A[o + gw] * (1 - u) + A[o + gw + 1] * u) * v;
    return [a(gridU), a(gridV)];
  }

  function step(dt) {
    time += dt * 16.7;
    frame++;
    if (frame % 2 === 1 || frame < 3) buildGrid();
    head = (head + 1) % K;
    const bx = Math.cos(p.dir) * p.speed * p.tide;
    const by = Math.sin(p.dir) * p.speed * p.tide;
    const ob = p.obstacle;
    const pt = p.pointer;
    const total = N + M;
    for (let i = 0; i < total; i++) {
      if (i === N && M === 0) break;
      if (life[i] === 0) continue;
      let x = px[i];
      let y = py[i];
      const [cu, cv] = flowAt(x, y);
      const inLetter = i >= N;
      let vx = bx + cu * p.turb * (inLetter ? 0.6 : 1);
      let vy = by + cv * p.turb * (inLetter ? 0.6 : 1);
      if (p.zoom) {
        // Diving: everything streams out from the vanishing point, capped so it never smears.
        const zx = (x - W / 2) * p.zoom;
        const zy = (y - H / 2) * p.zoom;
        const zl = Math.hypot(zx, zy);
        const cap = zl > 7 ? 7 / zl : 1;
        vx += zx * cap;
        vy += zy * cap;
      }
      if (pt && pt.s > 0.01) {
        const dx = x - pt.x;
        const dy = y - pt.y;
        const r2 = dx * dx + dy * dy;
        const f = Math.exp(-r2 / 13000) * pt.s;
        const r = Math.sqrt(r2) + 1;
        vx += (-dy / r) * 3.2 * f + pt.vx * 0.25 * f;
        vy += (dx / r) * 3.2 * f + pt.vy * 0.25 * f;
      }
      if (mask && ob > 0) {
        const mi = (x / MS) | 0;
        const mj = (y / MS) | 0;
        if (mi > 0 && mj > 0 && mi < mw - 1 && mj < mh - 1) {
          const o = mj * mw + mi;
          const m = mask[o];
          if (m > 0.01 && m < 0.99) {
            const gx = mgx[o];
            const gy = mgy[o];
            const gl = Math.hypot(gx, gy) + 1e-6;
            const nx = gx / gl;
            const ny = gy / gl;
            const vn = vx * nx + vy * ny;
            if (!inLetter) {
              // Outside: cancel the part of the velocity heading into the letter, then slide.
              const s = Math.min(1, m * 3) * ob;
              if (vn > 0) {
                vx -= nx * vn * s;
                vy -= ny * vn * s;
                // Conserve a little speed along the edge so streams hug the letterform.
                const tx = -ny;
                const ty = nx;
                const sgn = vx * tx + vy * ty >= 0 ? 1 : -1;
                vx += tx * sgn * vn * 0.6 * s;
                vy += ty * sgn * vn * 0.6 * s;
              }
              if (m > 0.45) {
                vx -= nx * (m - 0.35) * 5 * ob;
                vy -= ny * (m - 0.35) * 5 * ob;
              }
            } else if (vn < 0 && m < 0.97) {
              // Inside: the edge is a bank; the current turns along the stroke instead.
              vx -= nx * vn;
              vy -= ny * vn;
              vx += nx * (0.97 - m) * 3;
              vy += ny * (0.97 - m) * 3;
            }
          }
        }
      }
      x += vx * dt;
      y += vy * dt;
      age[i] += dt;
      // Streams hugging a bank would pile into one dark line; let them thin out there.
      if (!inLetter && ob > 0.5 && mask && sampleMask(x, y) > 0.3) age[i] += 4 * dt;
      const out = x < -20 || y < -20 || x > W + 20 || y > H + 20;
      const here = mask ? sampleMask(x, y) : 0;
      // Letter streaks may not leave the ink; free streaks caught inside a solid letter drop out.
      const lost = inLetter ? here < 0.62 : ob > 0.5 && here > 0.6;
      if (out || age[i] > life[i] || lost) {
        spawn(i, false);
        continue;
      }
      px[i] = x;
      py[i] = y;
      const o = i * K * 2 + head * 2;
      trail[o] = x;
      trail[o + 1] = y;
    }
  }

  // Trails are stroked in batches: 3 life-alpha levels × (older half, newer half).
  function strokeSet(from, to, color, width, alphaScale) {
    if (to <= from || alphaScale <= 0.004) return;
    ctx.strokeStyle = color;
    ctx.lineWidth = width;
    const halves = [
      [0, K / 2 + 1, 0.3],
      [K / 2, K, 1],
    ];
    for (let lvl = 0; lvl < 3; lvl++) {
      for (const [k0, k1, ha] of halves) {
        ctx.globalAlpha = alphaScale * ha * (lvl + 1) * 0.3333;
        ctx.beginPath();
        for (let i = from; i < to; i++) {
          if (life[i] === 0) continue;
          const la = Math.min(1, age[i] / 18, (life[i] - age[i]) / 26);
          const l = la > 0.8 ? 2 : la > 0.45 ? 1 : 0;
          if (l !== lvl) continue;
          const o = i * K * 2;
          for (let k = k0; k < k1; k++) {
            const idx = (head + 1 + k) % K;
            const x = trail[o + idx * 2];
            const y = trail[o + idx * 2 + 1];
            if (k === k0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
          }
        }
        ctx.stroke();
      }
    }
  }

  function draw() {
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, W, H);
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    const c = p.colors;
    ctx.globalCompositeOperation = c.lighter ? 'lighter' : 'source-over';
    strokeSet(0, N, c.streak, 0.9, (c.lighter ? 0.55 : 0.46) * p.alpha);
    if (M && p.glow > 0) {
      ctx.globalCompositeOperation = c.lighter ? 'source-over' : 'source-over';
      strokeSet(N, N + M, c.glow, 2.6, 0.95 * p.glow);
      strokeSet(N, N + M, c.glowHead, 1.1, 0.9 * p.glow);
    }
    ctx.globalAlpha = 1;
    ctx.globalCompositeOperation = 'source-over';
  }

  return {
    params: p,
    resize,
    setWord,
    step,
    draw,
    // Reduced motion: run the field for a moment, then paint one still frame.
    still(n = 40) {
      for (let i = 0; i < n; i++) step(1);
      draw();
    },
    clear() {
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.clearRect(0, 0, canvas.width, canvas.height);
    },
  };
}
