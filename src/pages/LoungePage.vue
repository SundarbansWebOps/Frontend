<!-- The approved painted Lounge, isolated from the public site's shell and palette. -->
<template>
  <LoungeApp />
</template>

<script setup>
import { onBeforeUnmount } from 'vue';
import LoungeApp from '../components/lounge/App.vue';
import { nameCardOpen, theme, tourSeen } from '../components/lounge/state.js';
import { theme as siteTheme } from '../lib/theme.js';
import { member } from '../components/lounge/fixtures.js';
import { auth } from '../lib/auth.js';
import { lower } from '../lib/house.js';
import { activate, dispose } from '../components/lounge/tide.js';
import { activateMotion, stopMotion } from '../components/lounge/home/motion.js';
import { startClock, stopClock } from '../components/lounge/events.js';
import '../components/lounge/motion.css';
import '../components/lounge/lounge.css';
import '../components/lounge/events.css';
import '../components/lounge/tour.css';
import '../components/lounge/tokens.css';
import '../components/lounge/cards.css';
import '../components/lounge/panels.css';

// The signed-in member's own details replace the sample member (the router guard has loaded
// them). The coordinator comes from the public council list for their region.
if (auth.profile) {
  const regionName = auth.profile.region?.name ?? '';
  const rc = lower.find(
    (p) => p.region === regionName || (regionName === 'Delhi NCR' && p.region === 'Delhi')
  );
  Object.assign(member, {
    full_name: auth.profile.full_name,
    email: auth.profile.email,
    roll: auth.profile.member_code.toUpperCase(),
    region: { code: auth.profile.region?.code ?? '', name: regionName },
    coordinator: { name: rc?.name ?? 'Your Regional Coordinator', role: 'Regional Coordinator' },
  });
}

const root = document.documentElement;
root.classList.add('lounge-active');
// The sign-in screen fades out first; the painted tour then fades in.
let arrivalTimer;
if (history.state?.signIn) {
  root.classList.add('sign-in-arrival');
  arrivalTimer = setTimeout(() => root.classList.remove('sign-in-arrival'), 900);
}
root.dataset.theme = theme.value;
activate();
activateMotion();
startClock();
window.dispatchEvent(new Event('lounge-ready'));
if (!matchMedia('(prefers-reduced-motion: reduce)').matches && tourSeen.value) {
  root.classList.add('building');
}
onBeforeUnmount(() => {
  clearTimeout(arrivalTimer);
  root.classList.remove('sign-in-arrival');
  nameCardOpen.value = false;
  dispose();
  stopMotion();
  stopClock();
  root.classList.remove('lounge-active', 'building', 'has-banner', 'lite', 'm-hidden');
  root.dataset.theme = siteTheme.value;
});
</script>

<style>
:where(html.lounge-active.sign-in-arrival) .tour {
  animation: sign-in-arrive 900ms ease-out;
}
@keyframes sign-in-arrive {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}
@media (prefers-reduced-motion: reduce) {
  :where(html.lounge-active.sign-in-arrival) .tour {
    animation: none;
  }
}
</style>
