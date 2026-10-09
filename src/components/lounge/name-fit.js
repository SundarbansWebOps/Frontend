// Fitting the member's preferred name onto their lantern (night) and kite (day).
// Port of the verdict's reference implementation (_design/sketches/name-fit.html, decision 7):
// - WORDS are chosen once, on the tightest panels the member will ever see (their lantern and
//   their kite at phone size), so the lantern and the kite carry the same words everywhere.
//   Ladder: full name -> first + last (3+ words) -> first word -> first word hyphenated.
// - LINES and SIZE are chosen per object and size: one line or a balanced two-line split,
//   the largest size that fits the panel's real shape (oval or diamond), condensing the
//   width axis (100 -> 87.5 -> 75) only when that buys 8% or more.
// Never an ellipsis, never the roll number. Measures real glyphs, so call after fontsReady().

/* Writable panels, measured by flood-filling each sprite's cream panel. All in units of the
   sprite's WIDTH W; cy is a fraction of the sprite's height. */
export const FACE = {
  /* b/assets/lantern.webp 480x621: oval x 25.6-74.2%, y 21.9-70.7% */
  lantern: { cy: 0.463, halfW: 0.243, halfH: 0.316, shape: 'oval', pad: 0.08, sMax: 0.17 },
  /* art/r6/kite-mine.webp 520x650: diamond x 17.5-82.3%, y 17.8-70.8% (flood-filled). */
  kiteMine: { cy: 0.443, halfW: 0.324, halfH: 0.331, shape: 'diamond', pad: 0.07, sMax: 0.17 },
  /* b/assets/kite*.webp 300x373: diamond x 25.5-74.5%, y 26.5-66.5% */
  kite: { cy: 0.46, halfW: 0.245, halfH: 0.249, shape: 'diamond', pad: 0.07, sMax: 0.15 },
};
const WDTH = [100, 87.5, 75];

/* Width available to a line whose ink reaches `dy` px from the panel centre. */
function room(f, W, dy) {
  const a = f.halfW * W;
  const b = f.halfH * W;
  const k = Math.min(1, Math.abs(dy) / b);
  const w = f.shape === 'oval' ? 2 * a * Math.sqrt(1 - k * k) : 2 * a * (1 - k);
  return w - f.pad * W;
}

/* Initials ride with the next word: "K. R. Arjun" -> ["K. R. Arjun"]. */
export function units(name) {
  const t = (name || '').trim().replace(/\s+/g, ' ').split(' ').filter(Boolean);
  const out = [];
  let carry = '';
  for (const w of t) {
    if (/^(\p{L}\.?){1,2}$/u.test(w) && w.length <= 3) {
      carry += (carry ? ' ' : '') + w;
      continue;
    }
    out.push(carry ? `${carry} ${w}` : w);
    carry = '';
  }
  if (carry) {
    if (out.length) out[out.length - 1] += ` ${carry}`;
    else out.push(carry);
  }
  return out;
}

/* Break one long word near its middle at a syllable edge: before a consonant between two
   vowels (Rama-lingeswaran, Lakshmi-narayanan), else between two consonants that are not
   an aspirate pair. */
export function hyphenate(w) {
  const V = (c) => /[aeiouy]/i.test(c || '');
  const mid = w.length / 2;
  const pick = (ok) => {
    let b = -1;
    for (let i = 3; i <= w.length - 3; i++)
      if (ok(i) && (b < 0 || Math.abs(i - mid) < Math.abs(b - mid))) b = i;
    return b;
  };
  let at = pick((i) => V(w[i - 1]) && !V(w[i]) && V(w[i + 1]));
  if (at < 0) at = pick((i) => !V(w[i - 1]) && !V(w[i]) && w[i].toLowerCase() !== 'h');
  if (at < 0) at = Math.round(mid);
  return [w.slice(0, at) + '-', w.slice(at)];
}

let probe = null;
const cache = new Map();
function widthAt100(text, wdth) {
  const k = `${wdth}|${text}`;
  if (!cache.has(k)) {
    if (!probe) {
      probe = document.createElement('span');
      probe.setAttribute('aria-hidden', 'true');
      probe.style.cssText =
        'position:absolute;left:-9999px;top:0;visibility:hidden;white-space:nowrap;' +
        'font-family:"Anek Latin Lounge",system-ui,sans-serif;font-weight:700;letter-spacing:-0.01em;font-size:100px;' +
        // Even a 0.01ms global reduced-motion transition yields the previous axis's
        // metrics during this synchronous search. The probe must change instantly.
        'contain:layout style;transition:none!important;animation:none!important';
      document.body.appendChild(probe);
    }
    probe.style.fontStretch = `${wdth}%`;
    probe.textContent = text;
    cache.set(k, probe.getBoundingClientRect().width / 100);
  }
  return cache.get(k);
}

/* Largest font size (px) at which `lines` fit the panel, for one width-axis value. */
function fitSize(lines, f, W, wdth) {
  let hi = f.sMax * W;
  let lo = 0;
  for (let i = 0; i < 18; i++) {
    const s = (hi + lo) / 2;
    const reach = lines.length === 1 ? 0.43 * s : 0.9 * s; // ink extent from the centre
    const ok = lines.every((l) => widthAt100(l, wdth) * s <= room(f, W, reach));
    if (ok) lo = s;
    else hi = s;
  }
  return lo;
}

function best(lines, f, W) {
  let pick = null;
  for (const wdth of WDTH) {
    const s = fitSize(lines, f, W, wdth);
    if (!pick || s > pick.size * 1.08) pick = { lines, size: s, wdth };
  }
  return pick;
}

function balanced(u) {
  let pick = null;
  for (let i = 1; i < u.length; i++) {
    const l = [u.slice(0, i).join(' '), u.slice(i).join(' ')];
    const d = Math.abs(l[0].length - l[1].length);
    if (!pick || d < pick.d) pick = { d, l };
  }
  return pick.l;
}

/* LINES for one object: { lines, size (px), wdth (%) }. `face` is a FACE entry, W the
   sprite's rendered width in px. */
export function layout(words, face, W) {
  const one = words.units.length === 1 ? words.units[0] : '';
  const cands = [[words.units.join(' ')]];
  if (words.units.length >= 2) cands.push(balanced(words.units));
  else if (one.includes(' ')) {
    const i = one.lastIndexOf(' ');
    cands.push([one.slice(0, i), one.slice(i + 1)]);
  }
  const hy = words.hyphen || (!one.includes(' ') && one.length >= 11 ? hyphenate(one) : null);
  let pick = null;
  for (const lines of cands) {
    const r = best(lines, face, W);
    if (!pick || r.size > pick.size) pick = r;
  }
  if (hy) {
    const r = best(hy, face, W);
    if (words.hyphen || r.size > pick.size * 1.25) pick = r;
  }
  // Word selection has its readability floor at phone size. Tiny previews keep those
  // same words, but must use the solved size rather than overflowing their paper.
  return pick;
}

/* WORDS, chosen once against the tightest panels: [[face, W], ...] (default: the lantern at
   176px and the member's kite at 168px). { units, hyphen?, dropped } or null when empty. */
export function lanternWords(name, panels, floor = 12) {
  const u = units(name);
  if (!u.length) return null;
  const fits = (set) => panels.every(([f, w]) => layout(set, f, w).size >= floor);
  const sets = [{ units: u }];
  if (u.length >= 3) sets.push({ units: [u[0], u[u.length - 1]] });
  if (u.length >= 2) sets.push({ units: [u[0]] });
  for (const set of sets) if (fits(set)) return { ...set, dropped: set.units.length < u.length };
  return { units: [u[0]], hyphen: hyphenate(u[0]), dropped: u.length > 1 };
}

/* Resolves when Anek Latin Lounge 700 is ready (capped, so a blocked font never hangs the page). */
let ready = null;
export function fontsReady() {
  ready ??= Promise.race([
    document.fonts
      .load('700 100px "Anek Latin Lounge"')
      .then(() => document.fonts.ready)
      .catch(() => {}),
    new Promise((r) => setTimeout(r, 2500)),
  ]).then(() => cache.clear());
  return ready;
}
