<!--
  PROTOTYPE — Home: the landing page. Three variants are compared (V key or ?v=1|2|3); R replays
  the intro by remounting the variant.
-->
<template>
  <component :is="LANDINGS[store.landingV - 1].comp" :key="`${store.landingV}-${store.replay}`" />
</template>

<script setup>
import { onBeforeUnmount, onMounted } from 'vue';
import { LANDINGS, syncVariantUrl } from './landings.js';
import { store } from './store.js';

onMounted(() => syncVariantUrl());
// ?v= belongs to Home only; drop it when leaving.
onBeforeUnmount(() => {
  const url = new URL(location.href);
  url.searchParams.delete('v');
  history.replaceState(history.state, '', url);
});
</script>
