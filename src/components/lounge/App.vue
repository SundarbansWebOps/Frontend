<!-- Approved Lounge E shell: Home/Events, profile, notices, certificates and the welcome tour.
     Enter or Not now marks the tour seen; Skip only advances to the ghat. -->
<template>
  <LoungeNav
    v-if="showHome"
    :view="view"
    :profile-open="profileOpen"
    @notices="openNotices"
    @profile="profileOpen = true"
  />
  <main v-if="showHome" id="main">
    <LoungeHome
      v-if="view === 'home'"
      :key="homeKey"
      :entry="entry"
      @vue:mounted="entry = 'none'"
    />
    <EventsPage v-else @cert="openCert" />
  </main>

  <WelcomeTour v-if="showTour" :leaving="leaving" @done="onDone" @gone="onGone" />

  <ProfileMenu
    v-if="profileOpen"
    @close="profileOpen = false"
    @edit="editOpen = true"
    @certs="openCert('')"
    @tour="retakeTour"
    @theme="tide.toggleTheme?.()"
  />
  <ProfileEdit v-if="editOpen" @close="editOpen = false" />
  <ProfileEdit v-if="nameCardOpen" variant="ghat" @close="nameCardOpen = false" />
  <CertificatesPopup v-if="certsOpen" :start="certStart" @close="certsOpen = false" />
  <NoticesPanel v-if="noticesOpen" :focus="noticeFocus" @close="noticesOpen = false" />
</template>

<script setup>
import { defineAsyncComponent, onBeforeUnmount, ref, watch } from 'vue';
import CertificatesPopup from './CertificatesPopup.vue';
import EventsPage from './EventsPage.vue';
import LoungeHome from './LoungeHome.vue';
import LoungeNav from './LoungeNav.vue';
import NoticesPanel from './NoticesPanel.vue';
import ProfileEdit from './ProfileEdit.vue';
import ProfileMenu from './ProfileMenu.vue';
import { markTourSeen, nameCardOpen, resetTour, tourSeen } from './state.js';
/* tide.js (theme and page switches) belongs to the motion designer; every call is optional. */
import * as tide from './tide.js';
import { useRoute, useRouter } from 'vue-router';
const route = useRoute();
const router = useRouter();

/* The tour is seen once ever, so returning members never download it. */
const WelcomeTour = defineAsyncComponent(() => import('./WelcomeTour.vue'));

/* ---------- Views: Home and #events ---------- */

const viewOf = () => (route.query.view === 'events' ? 'events' : 'home');
const view = ref(viewOf());
/* Nav links, "Next up", Back and Forward all land here. tide.js runs the shared-scene
   switch (or a plain swap without View Transitions or with reduced motion). */
function onHash() {
  const stale = () => viewOf() !== view.value;
  const apply = () => (view.value = viewOf());
  if (tide.switchPage) tide.switchPage(stale, apply);
  else if (stale()) apply();
}
watch(() => route.query.view, onHash);
/* The build (lounge.css) is over by 4.2s; dropping the class leaves the shell at rest. */
const built = setTimeout(() => document.documentElement.classList.remove('building'), 4200);
onBeforeUnmount(() => {
  clearTimeout(built);
});

/* ---------- Tour gating ---------- */

const showTour = ref(!tourSeen.value);
const showHome = ref(tourSeen.value);
const leaving = ref(false);
const homeKey = ref(0);
/* How Home starts: 'name' plays the load choreography, 'none' shows it finished, or
   { from, boat } flies the name (and the boat) in from the tour's ghat. Reset to 'none'
   once Home has mounted, so coming back from Events doesn't replay it. */
/* Every page load plays the build (Raja, 2026-10-07: a refresh builds the screen from nothing). */
const entry = ref('name');

const profileOpen = ref(false);
const editOpen = ref(false);
const certsOpen = ref(false);
const certStart = ref('');
const noticesOpen = ref(false);
const noticeFocus = ref('');

function retakeTour() {
  resetTour();
  profileOpen.value = editOpen.value = certsOpen.value = noticesOpen.value = false;
  nameCardOpen.value = false;
  leaving.value = false;
  showHome.value = false;
  showTour.value = true;
  window.scrollTo({ top: 0, behavior: 'instant' });
}

/* Enter the Lounge ({ from, boat }: where the name and the boat are now) or "Not now" (null). */
function onDone(handoff) {
  markTourSeen();
  entry.value = handoff?.from ? handoff : 'name';
  if (view.value !== 'home') {
    router.replace({ path: '/lounge' });
    view.value = 'home';
  }
  homeKey.value++;
  leaving.value = true;
  window.scrollTo({ top: 0, behavior: 'instant' });
  showHome.value = true;
}

function onGone() {
  showTour.value = false;
  leaving.value = false;
}

/* ---------- Pop-ups ---------- */

function openCert(id) {
  certStart.value = id || '';
  certsOpen.value = true;
}

function openNotices(id) {
  noticeFocus.value = typeof id === 'string' ? id : '';
  noticesOpen.value = true;
}
</script>
