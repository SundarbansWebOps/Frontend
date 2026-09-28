// PROTOTYPE tooling — the three Home (landing) variants under comparison, switched by ?v= or V.
// Each variant is a self-contained module built by a different model; see README.
import { defineAsyncComponent, watch } from 'vue';
import { store } from './store.js';

export const LANDINGS = [
  { id: 1, name: 'Synchrony', load: () => import('./LandingFireflies.vue') },
  { id: 2, name: 'Pat', load: () => import('./LandingPat.vue') },
  { id: 3, name: 'Current', load: () => import('./LandingCurrent.vue') },
].map((l) => ({ ...l, comp: defineAsyncComponent(l.load) }));

const v = Number(new URL(location.href).searchParams.get('v'));
store.landingV = LANDINGS[v - 1] ? v : 1;

export function nextVariant() {
  store.landingV = (store.landingV % LANDINGS.length) + 1;
}

// Keep ?v= in step with the variant shown; LandingPage calls this on mount too.
export function syncVariantUrl(n = store.landingV) {
  const url = new URL(location.href);
  if (n === 1) url.searchParams.delete('v');
  else url.searchParams.set('v', n);
  history.replaceState(history.state, '', url);
}
watch(() => store.landingV, syncVariantUrl);
