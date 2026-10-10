<!-- A pop-up sheet for the admin lounge's forms: native <dialog>, so focus, Esc and the backdrop
     come from the browser. Open it with v-if; it shows itself when mounted. -->
<template>
  <dialog
    ref="dlg"
    class="sheet"
    :class="{ wide }"
    :aria-labelledby="`${uid}-h`"
    @close="emit('close')"
    @click.self="close"
  >
    <div class="in">
      <header>
        <h2 :id="`${uid}-h`">{{ title }}</h2>
        <button type="button" class="x" @click="close">
          <LineIcon name="close" />
          <span class="visually-hidden">Close</span>
        </button>
      </header>
      <slot />
    </div>
  </dialog>
</template>

<script setup>
import { onMounted, ref, useId } from 'vue';
import LineIcon from '../site/LineIcon.vue';

defineProps({
  title: { type: String, required: true },
  wide: { type: Boolean, default: false },
});
const emit = defineEmits(['close']);
const dlg = ref(null);
const uid = useId();

onMounted(() => dlg.value?.showModal());
function close() {
  dlg.value?.close();
}
defineExpose({ close });
</script>

<style scoped>
.sheet {
  width: min(620px, calc(100vw - 32px));
  max-height: calc(100svh - 48px);
  padding: 0;
  border: 1px solid var(--line);
  border-radius: var(--r);
  background: var(--card);
  color: var(--ink);
  box-shadow: var(--shadow);
}
.sheet.wide {
  width: min(860px, calc(100vw - 32px));
}
.sheet[open] {
  animation: up 0.35s var(--ease-out);
}
.sheet::backdrop {
  background: color-mix(in srgb, var(--ink) 38%, transparent);
}
.in {
  padding: 20px 22px 22px;
}
header {
  display: flex;
  align-items: start;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 16px;
}
h2 {
  margin: 0;
  font-size: 22px;
  font-weight: 750;
  letter-spacing: -0.03em;
}
.x {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  border: 0;
  border-radius: 50%;
  background: var(--sunk);
  color: var(--ink);
  cursor: pointer;
}
.x :deep(svg) {
  width: 18px;
  height: 18px;
}
@keyframes up {
  from {
    opacity: 0;
    transform: translateY(12px);
  }
}
@media (max-width: 560px) {
  .in {
    padding: 16px;
  }
}
</style>
