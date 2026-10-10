<!-- Site shell: nav, the routed page, the course sheet any page can open, and toasts. -->
<template>
  <!-- #pat-ink, for every painted plate (PatFigure): keylines only — dark pixels stay as warm
       ink, everything lighter drops to transparent. -->
  <svg class="defs" width="0" height="0" aria-hidden="true" focusable="false">
    <filter id="pat-ink" color-interpolation-filters="sRGB">
      <feColorMatrix
        type="matrix"
        values="0 0 0 0 .114  0 0 0 0 .098  0 0 0 0 .082  -2.691 -5.283 -1.026 12 -9.3"
      />
    </filter>
  </svg>
  <a
    v-if="!isLounge && route.name !== 'NotFound'"
    class="skip"
    href="#main-content"
    @click.prevent="skipToMain"
  >
    Skip to main content
  </a>
  <TopNav v-if="!isLounge" />
  <RouterView />
  <SiteFooter v-if="route.path !== '/' && !isStandalone" />
  <CourseSheet />
  <LoungeDoor v-if="door.rect" overlay entry :rect="door.rect" @done="endDoor" />
  <Transition name="toast">
    <div v-if="store.toast" class="toast" role="status">{{ store.toast }}</div>
  </Transition>
</template>

<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import TopNav from './components/site/TopNav.vue';
import SiteFooter from './components/site/SiteFooter.vue';
import CourseSheet from './components/site/CourseSheet.vue';
import LoungeDoor from './components/site/LoungeDoor.vue';
import { store } from './lib/store.js';
import { door, endDoor } from './lib/door.js';

const route = useRoute();
const router = useRouter();
// The sign-in door covers the page until it has opened onto the Lounge. Going anywhere else during
// it ends the door, so nothing is left covering a page.
router.afterEach((to) => {
  if (door.rect && to.path !== door.target) endDoor();
});
const isLounge = computed(
  () =>
    route.name === 'Lounge' ||
    route.name === 'LoungeForm' ||
    (!route.matched.length && document.documentElement.classList.contains('lounge-active'))
);
const isStandalone = computed(
  () =>
    route.name === 'Lounge' ||
    route.name === 'LoungeForm' ||
    route.name === 'Login' ||
    (!route.matched.length &&
      (document.documentElement.classList.contains('lounge-active') ||
        document.documentElement.classList.contains('sign-in-active')))
);
function skipToMain() {
  const main = document.getElementById('main-content');
  main?.focus({ preventScroll: true });
  main?.scrollIntoView({ block: 'start' });
}
</script>

<style scoped>
.defs {
  position: absolute;
  width: 0;
  height: 0;
}
.skip {
  position: fixed;
  top: 8px;
  left: 8px;
  z-index: 300;
  padding: 10px 14px;
  border-radius: 10px;
  background: var(--ink);
  color: var(--paper);
  transform: translateY(-160%);
}
.skip:focus {
  transform: translateY(0);
}
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
