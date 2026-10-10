<!-- The approved painted Lounge, isolated from the public site's shell and palette. -->
<template>
  <p v-if="bootError" class="lounge-boot" role="alert">{{ bootError }}</p>
  <p v-else-if="!ready" class="lounge-boot" role="status">Opening the Lounge…</p>
  <LoungeApp v-else />
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue';
import LoungeApp from '../components/lounge/App.vue';
import { loungeArrived, nameCardOpen, theme, tourSeen } from '../components/lounge/state.js';
import { theme as siteTheme } from '../lib/theme.js';
import { fillMember, hydrateLounge, lounge } from '../components/lounge/session.js';
import { auth, errorText } from '../lib/auth.js';
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

const ready = ref(false);
const bootError = ref('');

if (auth.profile) fillMember(auth.profile);

const arrival = !loungeArrived.value;
const root = document.documentElement;
root.classList.add('lounge-active');
let arrivalTimer;
if (arrival && history.state?.signIn) {
  root.classList.add('sign-in-arrival');
  arrivalTimer = setTimeout(() => root.classList.remove('sign-in-arrival'), 900);
}
root.dataset.theme = theme.value;
activate();
activateMotion();
startClock();

onMounted(async () => {
  try {
    await hydrateLounge();
  } catch (err) {
    bootError.value = errorText(err) || 'The Lounge could not load. Try again.';
    lounge.ready = true;
  }
  ready.value = true;
  window.dispatchEvent(new Event('lounge-ready'));
  if (arrival && !matchMedia('(prefers-reduced-motion: reduce)').matches && tourSeen.value) {
    root.classList.add('building');
  }
});

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
.lounge-boot {
  margin: 0;
  padding: 48px 24px;
  color: var(--t-1);
  font: 600 18px/1.4 var(--font);
  text-align: center;
}
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
