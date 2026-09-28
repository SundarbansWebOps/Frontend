// House: the council, the regions and their meetups, adapted from data already
// on the live site. Each Lower House coordinator belongs to a region, so regions carry them.
import { reactive } from 'vue';
import { COUNCIL, REGION_BLURB } from '../data/house.data.js';
import { MONTH, parseDate, slug } from './events.js';
import bengaluru from '../views/meetups/region_exports_json_and_csv/json/bengaluru_region.json';
import chandigarh from '../views/meetups/region_exports_json_and_csv/json/chandigarh_region.json';
import chennai from '../views/meetups/region_exports_json_and_csv/json/chennai_region.json';
import delhi from '../views/meetups/region_exports_json_and_csv/json/delhi_region.json';
import hyderabad from '../views/meetups/region_exports_json_and_csv/json/hyderabad_region.json';
import kolkata from '../views/meetups/region_exports_json_and_csv/json/kolkata_region.json';
import lucknow from '../views/meetups/region_exports_json_and_csv/json/lucknow_region.json';
import mumbai from '../views/meetups/region_exports_json_and_csv/json/mumbai_region.json';
import patna from '../views/meetups/region_exports_json_and_csv/json/patna_region.json';

// Cloudinary portraits: face-aware crops sized to where they're shown.
const CLD = 'f_auto,q_auto:good,w_1000,c_limit';
export const portrait = {
  card: (u) => u?.replace(CLD, 'f_auto,q_auto,w_360,h_480,c_fill,g_face'),
  big: (u) => u?.replace(CLD, 'f_auto,q_auto,w_480,h_640,c_fill,g_face'),
  blur: (u) => u?.replace(CLD, 'f_auto,q_30,w_24,h_32,c_fill,g_face,e_blur:300'),
  face: (u) => u?.replace(CLD, 'f_auto,q_auto,w_96,h_96,c_thumb,g_face'),
};

// Meetup photos: use Google delivery URLs as exported. Cloudinary supports sized crops.
const BENGALURU_608 = [1, 2, 3, 4].map(
  (k, i) =>
    `https://res.cloudinary.com/l59gy0g2/image/upload/${CLD}/v178591132${[4, 6, 7, 8][i]}/sundarbans/public/assets/pastevent/bengaluru_meetup_608_${k}.png`
);
export function photo(u, w, h) {
  if (!u) return undefined;
  if (u.includes('res.cloudinary.com'))
    return u.replace(CLD, `f_auto,q_auto,w_${w}${h ? `,h_${h},c_fill` : ',c_limit'}`);
  // Preserve Google's exported delivery flags and query. Rewritten URLs can be
  // rejected when embedded; CSS crops thumbnails from the shared original.
  return u;
}

export const council = COUNCIL.map((p) => ({ ...p, id: slug(p.name) }));
export const upper = council.filter((p) => p.house === 'UHC');
export const lower = council.filter((p) => p.house === 'LHC');

// id, display name, sheet, hub city lat/lon. Only cities are placed — no borders are drawn.
const REGION_DEFS = [
  ['patna', 'Patna', patna, 25.59, 85.14],
  ['delhi', 'Delhi NCR', delhi, 28.61, 77.21],
  ['mumbai', 'Mumbai', mumbai, 19.08, 72.88],
  ['chandigarh', 'Chandigarh', chandigarh, 30.73, 76.78],
  ['kolkata', 'Kolkata', kolkata, 22.57, 88.36],
  ['hyderabad', 'Hyderabad', hyderabad, 17.39, 78.49],
  ['lucknow', 'Lucknow', lucknow, 26.85, 80.95],
  ['bengaluru', 'Bengaluru', bengaluru, 12.97, 77.59],
  ['chennai', 'Chennai', chennai, 13.08, 80.27],
];
// The council and the blurbs spell some regions differently.
const COUNCIL_REGION = { delhi: 'Delhi', bengaluru: 'Bengaluru' };
const BLURB_KEY = { delhi: 'Delhi', bengaluru: 'Bangalore' };
export const IITM = { lat: 12.99, lon: 80.23 };

// Nine sheets, nine column naming schemes.
const pick = (r, re) => {
  const k = Object.keys(r).find((key) => re.test(key));
  return k ? String(r[k] ?? '').trim() : '';
};

export const regions = REGION_DEFS.map(([id, name, file, lat, lon]) => {
  const items = file.records
    .filter((r) => !r.status)
    .map((r, i) => {
      const title = pick(r, /^meetup$|meetup name/i);
      const venue = pick(r, /venue|location|^region$/i);
      const when = parseDate(pick(r, /^date$/i));
      const people = pick(r, /students|attendees|attendes|student attended/i);
      // "Tricolor Trails 2.0 (Sundarbans X Boundless X Nallamala)" → [Boundless, Nallamala]
      const raw = pick(r, /collab|house\/society/i);
      const collab = [
        ...new Set(
          (raw.match(/\(([^)]+)\)/)?.[1] ?? raw)
            .split(/\s+[xX×]\s+|\s*[,&]\s*|\s+and\s+/)
            .map((h) =>
              h
                .trim()
                .toLowerCase()
                .replace(/\b\w/g, (c) => c.toUpperCase())
            )
            .filter((h) => h && !/^sundarbans( house)?$/i.test(h))
        ),
      ];
      return {
        id: `${id}-${i}`,
        region: id,
        no: pick(r, /meet.?up no|meetup_no/i)
          .replace(/[#\s]/g, '')
          .replace(/^na.*/i, ''),
        title: title || venue || `${name} meetup`,
        venue: title && venue !== title ? venue : '',
        ...when,
        at: when.y != null ? new Date(when.y, when.m, when.d ?? 15) : null,
        people: people ? parseInt(people, 10) || null : null,
        approx: /approx|\+|~/i.test(people),
        collab,
        desc: pick(r, /description|summary|details|2-4 line/i).replace(/\s*\n\s*/g, ' '),
        insta: pick(r, /insta|social/i).replace(/\s+/g, ''),
        photos: Array.isArray(r.photos) ? r.photos.filter((u) => /^https:/.test(u)) : [],
      };
    })
    .sort((a, b) => (b.at ?? 0) - (a.at ?? 0));
  if (id === 'bengaluru') for (const m of items) if (m.no === '608') m.photos = BENGALURU_608;
  const cr = COUNCIL_REGION[id] ?? name;
  return {
    id,
    name,
    lat,
    lon,
    items,
    blurb: REGION_BLURB[BLURB_KEY[id] ?? name] ?? '',
    coordinators: lower.filter((p) => p.region === cr),
    people: items.reduce((n, m) => n + (m.people ?? 0), 0),
    last: items.find((m) => m.at) ?? null,
  };
}).sort((a, b) => b.items.length - a.items.length);

export const regionById = Object.fromEntries(regions.map((r) => [r.id, r]));
export const meetups = regions.flatMap((r) => r.items);
export const meetupCount = meetups.length;
// Some Google Photos links are dead at the source; an <img> that fails reports it here and
// that photo quietly drops out everywhere.
export const deadPhotos = reactive(new Set());
export const livePhotos = (m) => m.photos.filter((u) => !deadPhotos.has(u));
// Google also refuses bursts of requests now and then, so a failure is retried once (after a
// pause) before the photo is written off. Pass the <img> error event.
const failedOnce = new WeakSet();
export function markDead(u, e) {
  const img = e?.target;
  if (!u) return;
  if (img && !failedOnce.has(img)) {
    failedOnce.add(img);
    setTimeout(
      () => {
        if (!img.isConnected) return;
        // Each image gets one retry; another thumbnail must not consume its attempt.
        img.removeAttribute('src');
        img.src = u;
      },
      1500 + Math.random() * 1500
    );
    return;
  }
  deadPhotos.add(u);
}
export const withPhotos = meetups.filter((m) => m.photos.length);
export const photoCount = withPhotos.reduce((n, m) => n + m.photos.length, 0);
export const regionOfCouncil = (p) =>
  regions.find((r) => (COUNCIL_REGION[r.id] ?? r.name) === p.region)?.id ?? null;

// Season span, month by month, for the playback scrubber.
const dated = meetups.filter((m) => m.at).map((m) => m.y * 12 + m.m);
export const season = { from: Math.min(...dated), to: Math.max(...dated) };
export const monthLabel = (k) => `${MONTH[k % 12]} ’${String(Math.floor(k / 12)).slice(2)}`;
export const meetupDate = (m) => (m.at ? `${m.d ?? ''} ${MONTH[m.m]} ${m.y}`.trim() : 'No date');

// Cross-section state on the House page: the open region, the picked meetup, and the
// photo viewer ({ m, i } — a meetup and which of its photos).
export const house = reactive({ region: null, meetup: null, photos: null });
