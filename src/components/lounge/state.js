// Shared prototype state: theme, the member's name, storage flags. All storage access is
// wrapped, so blocked storage only means nothing is remembered. Contract: _notes/shell.md.
import { computed, ref } from 'vue';
import { member } from './fixtures.js';

import { boot } from './boot.js';
export { boot };

export const theme = ref(boot.theme);
/* Member name contract (shared by the tour, Home, profile):
   - rosterName: what the council roster holds (backend members.full_name). Blank in this
     prototype so a new member types their own.
   - preferredName: what the member confirmed at the ghat or edited in the profile
     (backend members.preferred_name). Persisted; savePreferredName() is the only writer.
   The roll number is never a name: with no name, views show their empty state. */
export const NAME_KEY = 'lounge-e-preferred-name';
export const rosterName = member.full_name ?? '';
export const preferredName = ref(read(NAME_KEY) ?? '');
/* Certificate name: certificates print the first name the member confirmed and stay that
   way; later edits change the Lounge name only. A change goes through a request to the
   council (spec 002, Open). Prototype: remembered locally. */
export const CERT_NAME_KEY = 'lounge-e-cert-name';
export const certName = ref(read(CERT_NAME_KEY) ?? preferredName.value);
// Preserve the first confirmed name for older saves that predate the separate key.
if (certName.value && read(CERT_NAME_KEY) === null) store(CERT_NAME_KEY, certName.value);
export const cleanName = (v) => (v ?? '').trim().replace(/\s+/g, ' ');
export function savePreferredName(v) {
  preferredName.value = cleanName(v);
  store(NAME_KEY, preferredName.value || null);
  if (!certName.value && preferredName.value) {
    certName.value = preferredName.value;
    store(CERT_NAME_KEY, certName.value);
  }
}
/* Test-panel toggles: Name off shows the no-name state without losing the saved name;
   Live off hides the live event everywhere (Home card, Events). */
export const nameOn = ref(true);
export const liveOn = ref(true);
/* Back-compat alias for the old name state; prefer preferredName/savePreferredName. */
export const customName = preferredName;
export const shownName = computed(() => (nameOn.value ? preferredName.value || rosterName : ''));
export const hasName = computed(() => !!shownName.value);
export const firstName = computed(() => shownName.value.split(' ')[0] || '');
/* What the house calls this member. '' when there is no name: never the roll number. */
export const callName = computed(() => shownName.value);
/* "Riya Venkataraman" -> "RV"; '' for no name. */
export const initialsOf = (name) =>
  cleanName(name)
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0].toUpperCase())
    .join('');

/* The ghat name card as a dialog over the Lounge (App renders it). Anyone may open it:
   the lantern's empty-state chip, the crest face, the full-name tag's Edit. */
export const nameCardOpen = ref(false);
export function openNameCard() {
  nameCardOpen.value = true;
}
/* Set when the name card saves a name: { name, from: DOMRect of the input, at }. Home
   watches it to fly the name onto the lantern / kite face. */
export const nameFlight = ref(null);

export function store(key, value) {
  try {
    if (value === null) localStorage.removeItem(key);
    else localStorage.setItem(key, value);
  } catch {
    /* storage blocked */
  }
}

export function read(key) {
  try {
    return localStorage.getItem(key);
  } catch {
    return null;
  }
}

/* Welcome tour is seen once per member ever (backend: a per-member seen flag). Enter the
   Lounge or "Not now" at the ghat marks it seen; closing mid-tour does not. Only the
   profile's "Retake the tour" (resetTour) shows it again. */
export const TOUR_KEY = 'lounge-e-tour-seen';
export const tourSeen = ref(read(TOUR_KEY) === '1');
export function markTourSeen() {
  tourSeen.value = true;
  store(TOUR_KEY, '1');
}
export function resetTour() {
  tourSeen.value = false;
  store(TOUR_KEY, null);
}

/* Day or night art for the current theme. */
export const mode = computed(() => (theme.value === 'dark' ? 'night' : 'day'));

export const wait = (ms) => new Promise((r) => setTimeout(r, ms));
