<!-- Admin dialogs use the shared card tokens. Centered for forms,
     `wide` for big forms, `side` for a student's profile. Native <dialog> gives focus trapping,
     Esc and the backdrop. The title and optional footer stay put; only the body scrolls, and the
     page behind is locked while any sheet is open (admin.css: html.adm-sheet-open). -->
<template>
  <dialog
    ref="dlg"
    class="adm-dlg"
    :class="side ? 'adm-side' : wide ? 'adm-wide' : 'adm-center'"
    :aria-labelledby="`${uid}-h`"
    @close="emit('close')"
    @click.self="close"
  >
    <button type="button" class="adm-dialog-close" aria-label="Close" @click="close">
      <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 6l12 12M18 6 6 18" /></svg>
    </button>
    <h2 :id="`${uid}-h`" class="head">{{ title }}</h2>
    <div class="body">
      <slot />
    </div>
    <footer v-if="$slots.footer" class="foot">
      <slot name="footer" />
    </footer>
  </dialog>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref, useId } from 'vue';

defineProps({
  title: { type: String, required: true },
  wide: { type: Boolean, default: false },
  side: { type: Boolean, default: false },
});
const emit = defineEmits(['close']);
const dlg = ref(null);
const uid = useId();

// Sheets can stack (a menu opening a form), so the page stays locked until the last one closes.
let openCount = 0;
function lockPage(on) {
  openCount = Math.max(0, openCount + (on ? 1 : -1));
  document.documentElement.classList.toggle('adm-sheet-open', openCount > 0);
}

onMounted(() => {
  dlg.value?.showModal();
  lockPage(true);
});
onBeforeUnmount(() => lockPage(false));

function close() {
  dlg.value?.close();
}
defineExpose({ close });
</script>

<style scoped>
.adm-dlg {
  position: fixed;
  width: min(540px, calc(100vw - 32px));
  max-height: calc(100dvh - 48px);
  margin: auto;
  padding: 0;
  overflow: hidden;
  border: 1px solid var(--line);
  border-radius: var(--r);
  background: var(--card);
  color: var(--ink);
  box-shadow: var(--shadow);
  font-family: var(--font);
}
.adm-dlg[open] {
  display: flex;
  flex-direction: column;
}
.adm-dlg::backdrop {
  background: color-mix(in srgb, var(--ink) 48%, transparent);
}
.adm-dlg.adm-wide {
  width: min(920px, calc(100vw - 32px));
}
.adm-dlg.adm-side {
  width: min(620px, 100vw);
  height: 100dvh;
  max-height: 100dvh;
  margin: 0 0 0 auto;
  border-radius: 0;
}
.adm-dialog-close {
  position: absolute;
  top: 12px;
  right: 12px;
  z-index: 1;
  display: grid;
  width: 40px;
  height: 40px;
  place-items: center;
  border: 1px solid var(--line);
  border-radius: 50%;
  background: var(--card);
  color: var(--ink-2);
}
.adm-dialog-close:hover {
  background: var(--sunk);
  color: var(--ink);
}
.adm-dialog-close svg {
  width: 18px;
  height: 18px;
  fill: none;
  stroke: currentColor;
  stroke-width: 2;
  stroke-linecap: round;
}
.head {
  flex: none;
  margin: 0;
  padding: 14px 64px 14px 24px;
  border-bottom: 1px solid var(--line);
  font-size: 19px;
  font-weight: 700;
  line-height: 1.2;
}
.body {
  flex: 1 1 auto;
  min-height: 0;
  padding: 18px 24px 24px;
  overflow-y: auto;
  overscroll-behavior: contain;
}
.foot {
  display: flex;
  flex: none;
  flex-wrap: wrap;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
  padding: 14px 24px;
  border-top: 1px solid var(--line);
  background: var(--card);
}
/* A student's profile needs more room than a form dialog. */
@media (min-width: 761px) {
  .adm-dlg.adm-side {
    width: min(620px, 100vw);
  }
}
@media (max-width: 760px) {
  .adm-dlg,
  .adm-dlg.adm-wide {
    width: min(540px, calc(100vw - 24px));
    max-height: calc(100dvh - 24px);
  }
  .adm-dlg.adm-side {
    width: 100vw;
    max-height: 100dvh;
  }
  .head {
    padding: 14px 56px 14px 16px;
  }
  .body {
    padding: 16px 16px 20px;
  }
  .foot {
    padding: 12px 16px calc(12px + env(safe-area-inset-bottom));
  }
}
</style>
