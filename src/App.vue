<!-- Site shell: nav, the routed page, the course sheet any page can open, and toasts. -->
<template>
  <TopNav />
  <RouterView />
  <SiteFooter />
  <CourseSheet />
  <Transition name="toast">
    <div v-if="store.toast" class="toast" role="status">{{ store.toast }}</div>
  </Transition>
</template>

<script setup>
import { useRoute } from 'vue-router';
import TopNav from './components/site/TopNav.vue';
import SiteFooter from './components/site/SiteFooter.vue';
import CourseSheet from './components/site/CourseSheet.vue';
import { store } from './lib/store.js';

const route = useRoute();
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
