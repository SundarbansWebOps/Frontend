<!--
  PROTOTYPE tooling — not part of the design. T toggles the theme, F cycles the typeface.
  On Home: V cycles the landing variant, R replays its intro.
-->
<template>
  <div class="sw" role="toolbar" aria-label="Prototype controls">
    <span class="lbl"><b>PROTOTYPE</b></span>
    <button type="button" @click="$emit('update:theme', theme === 'light' ? 'dark' : 'light')">
      {{ theme === 'light' ? 'Light' : 'Dark' }}
    </button>
    <button type="button" class="font" title="Next typeface (F)" @click="nextFont">
      Font: <b>{{ fontById[font].name }}</b>
    </button>
    <template v-if="page === 'home'">
      <button type="button" class="font" title="Next landing variant (V)" @click="nextVariant">
        Home: <b>{{ store.landingV }} · {{ LANDINGS[store.landingV - 1].name }}</b>
      </button>
      <button type="button" title="Replay the intro (R)" @click="store.replay++">Replay</button>
    </template>
    <button v-else type="button" title="Clear pinned courses" @click="reset">Reset pins</button>
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted } from 'vue';
import { store } from './store.js';
import { FONTS, fontById } from './fonts.js';
import { LANDINGS, nextVariant } from './landings.js';

const props = defineProps({ theme: String, font: String, page: String });
const emit = defineEmits(['update:theme', 'update:font']);

function nextFont() {
  const i = FONTS.findIndex((f) => f.id === props.font);
  emit('update:font', FONTS[(i + 1) % FONTS.length].id);
}

function reset() {
  store.mine.splice(0);
  location.reload();
}
function onKey(e) {
  if (e.target.matches?.('input, textarea, [contenteditable]') || store.sheet) return;
  if (e.key === 't') emit('update:theme', props.theme === 'light' ? 'dark' : 'light');
  if (e.key === 'f') nextFont();
  if (props.page === 'home' && e.key === 'v') nextVariant();
  if (props.page === 'home' && e.key === 'r') store.replay++;
}
onMounted(() => window.addEventListener('keydown', onKey));
onBeforeUnmount(() => window.removeEventListener('keydown', onKey));
</script>

<style scoped>
.sw {
  position: fixed;
  right: 16px;
  bottom: 16px;
  z-index: 300;
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 5px;
  border-radius: 99px;
  background: #0b0b0b;
  color: #fff;
  font:
    500 12px/1 ui-sans-serif,
    system-ui,
    sans-serif;
  box-shadow: 0 10px 30px rgb(0 0 0 / 0.35);
  white-space: nowrap;
}
button {
  height: 28px;
  padding: 0 10px;
  border: 0;
  border-radius: 99px;
  background: #262626;
  color: #fff;
  font-size: 12px;
}
button:hover {
  background: #3a3a3a;
}
.font b {
  font-weight: 600;
  color: #f2a93b;
}
.lbl {
  padding: 0 6px 0 8px;
  font-size: 10.5px;
  letter-spacing: 0.1em;
}
.lbl b {
  color: #f2a93b;
}
@media (max-width: 760px) {
  .sw button[title^='Clear'] {
    display: none;
  }
  .sw {
    bottom: 76px;
    right: 10px;
    max-width: calc(100vw - 20px);
    flex-wrap: wrap;
    justify-content: center;
    border-radius: 16px;
  }
}
</style>
