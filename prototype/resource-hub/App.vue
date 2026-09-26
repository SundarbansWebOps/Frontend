<!-- PROTOTYPE shell — Resources (Delta, chosen 2026-09-27), Events, House, Teams and the Lounge, switched by ?page=. -->
<template>
  <TopNav :page="page" @go="go" />
  <component :is="PAGES[page]" :key="page" />
  <CourseSheet />
  <Transition name="toast">
    <div v-if="store.toast" class="toast" role="status">{{ store.toast }}</div>
  </Transition>
  <PrototypeSwitcher v-model:theme="theme" v-model:font="font" />
</template>

<script setup>
import { ref, watch } from 'vue';
import TopNav from './TopNav.vue';
import CourseSheet from './CourseSheet.vue';
import PrototypeSwitcher from './PrototypeSwitcher.vue';
import VariantDelta from './VariantDelta.vue';
import EventsPage from './EventsPage.vue';
import HousePage from './HousePage.vue';
import TeamsPage from './TeamsPage.vue';
import LoungePage from './LoungePage.vue';
import { fontById, useFont } from './fonts.js';
import { nav, store } from './store.js';

const PAGES = {
  resources: VariantDelta,
  events: EventsPage,
  house: HousePage,
  teams: TeamsPage,
  lounge: LoungePage,
};

const params = new URL(location.href).searchParams;
const page = ref(PAGES[params.get('page')] ? params.get('page') : 'resources');
const theme = ref(params.get('theme') === 'dark' ? 'dark' : 'light');
const font = ref(fontById[params.get('font')] ? params.get('font') : 'anek');

// `anchor` is a section id on the target page; the page scrolls to it once mounted.
// Each page switch is its own history entry, so Back returns to the previous page.
function go(p, anchor = null, push = true) {
  if (p === page.value) {
    if (anchor) document.getElementById(anchor)?.scrollIntoView({ behavior: 'smooth' });
    return;
  }
  store.anchor = anchor;
  if (push) {
    const url = new URL(location.href);
    url.searchParams.delete('event');
    history.pushState(null, '', url); // the watcher below writes ?page= onto this entry
  }
  const swap = () => {
    page.value = p;
    window.scrollTo({ top: 0 });
  };
  // A cross-fade where the browser supports it; an instant swap everywhere else.
  if (document.startViewTransition && !matchMedia('(prefers-reduced-motion: reduce)').matches)
    document.startViewTransition(swap);
  else swap();
}

nav.go = go;

addEventListener('popstate', () => {
  const q = new URL(location.href).searchParams.get('page');
  const want = PAGES[q] ? q : 'resources';
  if (want !== page.value) go(want, null, false);
});

watch(
  [page, theme, font],
  ([p, t, f]) => {
    useFont(f);
    document.documentElement.dataset.theme = t;
    const url = new URL(location.href);
    url.searchParams.delete('variant');
    if (p === 'resources') url.searchParams.delete('page');
    else url.searchParams.set('page', p);
    if (t === 'dark') url.searchParams.set('theme', 'dark');
    else url.searchParams.delete('theme');
    if (f !== 'anek') url.searchParams.set('font', f);
    else url.searchParams.delete('font');
    history.replaceState(history.state, '', url);
  },
  { immediate: true }
);
</script>

<style scoped>
.toast {
  position: fixed;
  left: 50%;
  bottom: 84px;
  z-index: 200;
  transform: translateX(-50%);
  padding: 10px 16px;
  border-radius: 12px;
  background: var(--ink);
  color: var(--paper);
  font-size: 14px;
  font-weight: 550;
  box-shadow: var(--shadow);
}
.toast-enter-active,
.toast-leave-active {
  transition:
    opacity 0.25s,
    transform 0.35s var(--ease-spring);
}
.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translate(-50%, 10px);
}
</style>
