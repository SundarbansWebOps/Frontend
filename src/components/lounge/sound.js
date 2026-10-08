// Tour sounds. Played only from a tap handler, so nothing ever autoplays.
// Each sound prefers a recorded file in ./sfx/ ({name}.ogg, or .mp3 where Ogg can't play).
// The file is fetched and decoded on the first tap that needs it; until it is ready, or
// if it is missing, a small Web Audio synth plays instead. Every voice stops itself
// within about two seconds.
let ctx = null;
let master = null;

const SFX = import.meta.glob('./sfx/*.{ogg,mp3}', {
  eager: true,
  query: '?url',
  import: 'default',
});
/* name -> AudioBuffer once decoded, null if the file is missing, a Promise while loading. */
const files = new Map();
/* How long a first tap waits for its file before falling back to the synth. */
const FIRST_TAP_WAIT = 350;

function audio() {
  if (!ctx) {
    const C = window.AudioContext || window.webkitAudioContext;
    if (!C) return null;
    ctx = new C();
    master = ctx.createGain();
    master.gain.value = 0.55;
    master.connect(ctx.destination);
  }
  if (ctx.state === 'suspended') ctx.resume().catch(() => {});
  return ctx;
}

function ext() {
  const a = document.createElement('audio');
  return a.canPlayType?.('audio/ogg; codecs="opus"') ? 'ogg' : 'mp3';
}

async function fetchDecode(c, url) {
  if (!url) return null;
  const res = await fetch(url);
  if (!res.ok) return null;
  const type = res.headers.get('content-type') || '';
  /* A dev server can answer a missing file with index.html; anything not audio is missing. */
  if (type && !type.startsWith('audio/') && !type.includes('octet-stream')) return null;
  const data = await res.arrayBuffer();
  return await new Promise((ok) => {
    try {
      const p = c.decodeAudioData(data, ok, () => ok(null));
      p?.catch?.(() => ok(null));
    } catch {
      ok(null);
    }
  });
}

function load(c, name) {
  if (files.has(name)) return files.get(name);
  const first = ext();
  const p = fetchDecode(c, SFX[`./sfx/${name}.${first}`])
    .then((b) => b || (first === 'ogg' ? fetchDecode(c, SFX[`./sfx/${name}.mp3`]) : null))
    .catch(() => null)
    .then((b) => {
      files.set(name, b);
      return b;
    });
  files.set(name, p);
  return p;
}

function playBuffer(c, b) {
  const src = c.createBufferSource();
  src.buffer = b;
  src.connect(master);
  src.start(c.currentTime + 0.01);
}

let noiseBuf = null;
function noise(c) {
  if (!noiseBuf) {
    noiseBuf = c.createBuffer(1, c.sampleRate * 0.5, c.sampleRate);
    const d = noiseBuf.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
  }
  return noiseBuf;
}

function env(g, t, peak, attack, decay) {
  g.gain.setValueAtTime(0.0001, t);
  g.gain.exponentialRampToValueAtTime(peak, t + attack);
  g.gain.exponentialRampToValueAtTime(0.0001, t + attack + decay);
}

/* A burst of filtered noise. */
function hiss(
  c,
  t,
  { type = 'bandpass', f = 3000, q = 1, vol = 0.2, attack = 0.002, decay = 0.08, to = null } = {}
) {
  const n = c.createBufferSource();
  n.buffer = noise(c);
  const bq = c.createBiquadFilter();
  bq.type = type;
  bq.frequency.setValueAtTime(f, t);
  if (to) bq.frequency.exponentialRampToValueAtTime(to, t + attack + decay);
  bq.Q.value = q;
  const g = c.createGain();
  env(g, t, vol, attack, decay);
  n.connect(bq).connect(g).connect(master);
  n.start(t);
  n.stop(t + attack + decay + 0.05);
}

/* A drum skin: a sine that drops in pitch, plus a short slap of filtered noise. */
function skin(c, t, f, vol = 0.9, decay = 0.45, slap = 0.25) {
  const o = c.createOscillator();
  const g = c.createGain();
  o.type = 'sine';
  o.frequency.setValueAtTime(f * 1.9, t);
  o.frequency.exponentialRampToValueAtTime(f, t + 0.04);
  o.frequency.exponentialRampToValueAtTime(f * 0.82, t + decay);
  env(g, t, vol, 0.004, decay);
  o.connect(g).connect(master);
  o.start(t);
  o.stop(t + decay + 0.05);
  if (slap) hiss(c, t, { f: f * 9, q: 1.2, vol: slap, decay: 0.07 });
}

function tone(
  c,
  t,
  f,
  { type = 'sine', vol = 0.3, attack = 0.005, decay = 0.3, to = null, out = master } = {}
) {
  const o = c.createOscillator();
  const g = c.createGain();
  o.type = type;
  o.frequency.setValueAtTime(f, t);
  if (to) o.frequency.exponentialRampToValueAtTime(to, t + attack + decay);
  env(g, t, vol, attack, decay);
  o.connect(g).connect(out);
  o.start(t);
  o.stop(t + attack + decay + 0.05);
}

/* Bell: inharmonic partials that ring out. */
function bell(c, t, f, vol = 0.22) {
  [
    [1, 1, 1.6],
    [2.76, 0.45, 0.9],
    [5.4, 0.22, 0.5],
    [8.93, 0.1, 0.3],
  ].forEach(([m, v, d]) => tone(c, t, f * m, { vol: vol * v, attack: 0.003, decay: d }));
}

/* Fallback synths. The three community sounds use different material on purpose:
   skins and ghungroo (cultural), dry key clicks and a sine chime (technical), a
   detuned sawtooth sweep into a bass hit (esports). */
const SYNTH = {
  /* Dhak: dha . dha-ka dha, with ghungroo on the off beats. */
  cultural(c, t) {
    [
      [0, 92, 1],
      [0.28, 92, 0.8],
      [0.42, 180, 0.5],
      [0.56, 92, 1],
      [0.84, 150, 0.6],
    ].forEach(([dt, f, v]) => skin(c, t + dt, f, v));
    [0.14, 0.49, 0.7].forEach((dt) =>
      hiss(c, t + dt, { type: 'highpass', f: 7000, vol: 0.18, decay: 0.12 })
    );
  },
  /* Keys typing in an uneven run, then a soft two-note "done" chime. */
  technical(c, t) {
    [0, 0.07, 0.12, 0.21, 0.26, 0.33, 0.37, 0.46].forEach((dt, i) => {
      hiss(c, t + dt, { f: 2400 + (i % 3) * 700, q: 6, vol: 0.32, attack: 0.001, decay: 0.025 });
      tone(c, t + dt, 180 + (i % 2) * 40, { vol: 0.08, attack: 0.001, decay: 0.03 });
    });
    tone(c, t + 0.62, 880, { vol: 0.2, attack: 0.004, decay: 0.35 });
    tone(c, t + 0.74, 1318.5, { vol: 0.2, attack: 0.004, decay: 0.7 });
  },
  /* Laser sweep down into a bass hit, then a three-note power stab. */
  esports(c, t) {
    const lp = c.createBiquadFilter();
    lp.type = 'lowpass';
    lp.frequency.value = 2600;
    lp.connect(master);
    [0, 7].forEach((det) => {
      const o = c.createOscillator();
      const g = c.createGain();
      o.type = 'sawtooth';
      o.detune.value = det;
      o.frequency.setValueAtTime(1900, t);
      o.frequency.exponentialRampToValueAtTime(90, t + 0.28);
      env(g, t, 0.12, 0.004, 0.28);
      o.connect(g).connect(lp);
      o.start(t);
      o.stop(t + 0.34);
    });
    tone(c, t + 0.28, 120, { vol: 0.9, attack: 0.003, decay: 0.45, to: 42 });
    hiss(c, t + 0.28, { type: 'lowpass', f: 1800, vol: 0.35, decay: 0.3, to: 300 });
    [
      [0.52, 196, 0.09],
      [0.64, 196, 0.09],
      [0.76, 293.66, 0.5],
    ].forEach(([dt, f, d]) => {
      tone(c, t + dt, f, { type: 'sawtooth', vol: 0.08, attack: 0.003, decay: d, out: lp });
      tone(c, t + dt, f * 1.5, { type: 'sawtooth', vol: 0.06, attack: 0.003, decay: d, out: lp });
    });
  },
  /* Council thought bubble: a soft rising "hel-lo" on two wooden notes. */
  hi(c, t) {
    tone(c, t, 587.33, { type: 'triangle', vol: 0.16, attack: 0.004, decay: 0.16 });
    tone(c, t + 0.11, 880, { type: 'triangle', vol: 0.14, attack: 0.004, decay: 0.3 });
  },
  /* Arrival: a dhak roll under two bells and a shower of high plinks. */
  celebrate(c, t) {
    [0, 0.12, 0.24, 0.36, 0.6].forEach((dt, i) => skin(c, t + dt, i === 4 ? 80 : 110, 0.7));
    bell(c, t + 0.05, 659.25);
    bell(c, t + 0.6, 987.77, 0.18);
    for (let i = 0; i < 10; i++) {
      tone(c, t + 0.7 + i * 0.07, 1800 + Math.random() * 1600, { vol: 0.05, decay: 0.25 });
    }
  },
};

const SYNTH_ONLY = new Set(['hi']);

export async function play(name) {
  try {
    const c = audio();
    if (!c || !SYNTH[name]) return;
    /* Small UI sounds have no file: play the synth straight away. */
    if (SYNTH_ONLY.has(name)) return SYNTH[name](c, c.currentTime + 0.01);
    let b = files.get(name);
    if (b === undefined || b instanceof Promise) {
      const t0 = performance.now();
      b = await Promise.race([
        load(c, name),
        new Promise((ok) => setTimeout(() => ok(undefined), FIRST_TAP_WAIT)),
      ]);
      /* Too slow: play the synth now; the file is used from the next tap on. */
      if (b === undefined || performance.now() - t0 > FIRST_TAP_WAIT) b = null;
    }
    if (b) playBuffer(c, b);
    else SYNTH[name](c, c.currentTime + 0.02);
  } catch {
    /* audio unavailable: the tour works silently */
  }
}
