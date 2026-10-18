<!-- The admin lounge's pop-up: a centred native <dialog> for forms and menus, or a right-hand
     sheet (`side`) for a student's profile. Native <dialog> gives focus trapping, Esc and the
     backdrop. The header and optional footer stay put; only the body scrolls, and the page behind
     is locked while any sheet is open (admin.css: html.adm-sheet-open). -->
<template>
  <dialog
    ref="dlg"
    class="sheet"
    :class="{ wide, side }"
    :aria-labelledby="`${uid}-h`"
    @close="emit('close')"
    @click.self="close"
  >
    <div class="in">
      <header class="head">
        <h2 :id="`${uid}-h`">{{ title }}</h2>
        <button type="button" class="x" @click="close">
          <LineIcon name="close" />
          <span class="visually-hidden">Close</span>
        </button>
      </header>
      <div class="body">
        <slot />
      </div>
      <footer v-if="$slots.footer" class="foot">
        <slot name="footer" />
      </footer>
    </div>
  </dialog>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref, useId } from 'vue';
import LineIcon from '../site/LineIcon.vue';

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
.sheet {
  display: flex;
  flex-direction: column;
  width: min(520px, calc(100vw - 32px));
  max-width: none;
  max-height: min(90svh, 860px);
  padding: 0;
  border: 1px solid var(--line);
  border-radius: 18px;
  background: var(--card);
  color: var(--ink);
  box-shadow: var(--shadow);
  overflow: hidden;
}
.sheet.wide {
  width: min(880px, calc(100vw - 32px));
}
.sheet.side {
  width: min(620px, 100vw);
  height: 100svh;
  max-height: 100svh;
  margin: 0 0 0 auto;
  border: 0;
  border-left: 1px solid var(--line);
  border-radius: 0;
}
.sheet[open] {
  animation: rise 0.3s var(--ease-out);
}
.sheet.side[open] {
  animation: slide 0.35s var(--ease-out);
}
.sheet::backdrop {
  background: color-mix(in srgb, var(--ink) 38%, transparent);
}
.in {
  display: flex;
  flex-direction: column;
  flex: 1 1 auto;
  min-height: 0;
}
.head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex: none;
  padding: 18px 16px 16px 24px;
  border-bottom: 1px solid var(--line);
}
h2 {
  margin: 0;
  font-size: 20px;
  font-weight: 750;
  letter-spacing: -0.03em;
}
.body {
  flex: 1 1 auto;
  min-height: 0;
  padding: 22px 24px 24px;
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
.x {
  display: grid;
  place-items: center;
  flex: none;
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
@keyframes rise {
  from {
    opacity: 0;
    transform: translateY(12px);
  }
}
@keyframes slide {
  from {
    opacity: 0;
    transform: translateX(24px);
  }
}
@media (max-width: 560px) {
  .sheet,
  .sheet.wide,
  .sheet.side {
    width: 100vw;
    height: 100svh;
    max-height: 100svh;
    margin: 0;
    border: 0;
    border-radius: 0;
  }
  .head {
    padding: 14px 14px 12px 16px;
  }
  .body {
    padding: 18px 16px 20px;
  }
  .foot {
    padding: 12px 16px calc(12px + env(safe-area-inset-bottom));
  }
}
</style>
