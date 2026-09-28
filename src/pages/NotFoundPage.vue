<!-- A path that goes nowhere: say so, and offer the five places that exist. -->
<template>
  <main class="wrap">
    <p class="code mono rise" style="--i: 0" aria-hidden="true">404</p>
    <h1 class="rise" style="--i: 1">This channel runs dry</h1>
    <p class="sub rise" style="--i: 2">
      There’s no page at <span class="mono">{{ route.path }}</span
      >. It may have moved when the site was rebuilt.
    </p>
    <nav class="ways rise" style="--i: 3" aria-label="Where to go instead">
      <RouterLink v-for="w in WAYS" :key="w.to" :to="w.to">
        <LineIcon :name="w.icon" /> {{ w.label }}
      </RouterLink>
    </nav>
  </main>
</template>

<script setup>
import { useRoute } from 'vue-router';
import LineIcon from '../components/site/LineIcon.vue';

const route = useRoute();
const WAYS = [
  { to: '/', label: 'Home', icon: 'home' },
  { to: '/resources', label: 'Resources', icon: 'book' },
  { to: '/events', label: 'Events', icon: 'cal' },
  { to: '/house', label: 'House', icon: 'house' },
  { to: '/teams', label: 'Teams', icon: 'people' },
];
</script>

<style scoped>
.wrap {
  display: grid;
  justify-items: center;
  align-content: center;
  gap: 10px;
  min-height: calc(100svh - var(--nav-h) - 180px);
  padding: 40px 24px;
  text-align: center;
}
.code {
  margin: 0;
  font-size: clamp(64px, 12vw, 120px);
  font-weight: 700;
  line-height: 1;
  color: var(--mari);
  letter-spacing: -0.04em;
}
h1 {
  margin: 0;
  font-size: clamp(28px, 4vw, 40px);
  font-weight: 750;
  letter-spacing: -0.04em;
}
.sub {
  margin: 4px 0 0;
  max-width: 46ch;
  color: var(--ink-2);
  font-size: 17px;
  line-height: 1.45;
  overflow-wrap: anywhere;
}
.ways {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 8px;
  margin-top: 18px;
}
.ways a {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 9px 16px 9px 12px;
  border-radius: 99px;
  border: 1.5px solid var(--line-strong);
  color: var(--ink);
  font-size: 14.5px;
  font-weight: 600;
  text-decoration: none;
  transition:
    background 0.2s,
    transform 0.25s var(--ease-spring);
}
.ways a:hover {
  background: var(--sunk);
  transform: translateY(-1px);
}
.ways .ic {
  width: 18px;
  height: 18px;
  color: var(--mari-ink);
}
</style>
