<!-- Admin dialogs use the shared card tokens. Centered for forms, `wide` for big forms,
     `fullscreen` for response tables, `side` for a student's profile, and `drop` for the account
     menu. Native <dialog> gives focus trapping, Esc and the backdrop. The title and optional footer
     stay put; only the body scrolls, and the page behind is locked while any sheet is open. -->
<template>
  <dialog
    ref="dlg"
    class="adm-dlg"
    :class="
      side
        ? 'adm-side'
        : fullscreen
          ? 'adm-fullscreen'
          : wide
            ? 'adm-wide'
            : drop
              ? 'adm-drop'
              : 'adm-center'
    "
    :aria-labelledby="`${uid}-h`"
    @close="emit('close')"
    @click.self="close"
  >
    <header class="adm-dialog-head">
      <h2 :id="`${uid}-h`" class="head">{{ title }}</h2>
      <button type="button" class="adm-dialog-close" aria-label="Close" @click="close">
        <LineIcon name="close" />
      </button>
    </header>
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
import LineIcon from '../site/LineIcon.vue';

defineProps({
  title: { type: String, required: true },
  wide: { type: Boolean, default: false },
  fullscreen: { type: Boolean, default: false },
  side: { type: Boolean, default: false },
  drop: { type: Boolean, default: false },
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
  outline: none;
}
.adm-dlg[open] {
  display: flex;
  flex-direction: column;
}
.adm-dlg::backdrop {
  background: color-mix(in srgb, var(--ink) 42%, transparent);
}
:global(:root[data-theme='dark']) .adm-dlg::backdrop {
  background: color-mix(in srgb, var(--sunk) 66%, transparent);
}
.adm-dlg.adm-wide {
  width: min(920px, calc(100vw - 32px));
}
.adm-dlg.adm-drop {
  inset: calc(var(--nav-h) + 8px) max(24px, calc((100vw - 1240px) / 2 + 24px)) auto auto;
  width: min(360px, calc(100vw - 32px));
  max-height: calc(100dvh - var(--nav-h) - 24px);
  margin: 0;
  border-color: var(--line-strong);
  border-radius: 16px;
  box-shadow:
    0 3px 0 color-mix(in srgb, var(--line-strong) 35%, transparent),
    var(--shadow);
}
.adm-dlg.adm-drop::before {
  position: absolute;
  inset: 0 0 auto;
  z-index: 1;
  height: 12px;
  border-bottom: 1px solid var(--line);
  background: url('../../assets/pat/band.webp') 0 0 / auto 12px repeat-x;
  content: '';
  opacity: 0.82;
  pointer-events: none;
}
.adm-dlg.adm-drop[open] {
  transform-origin: top right;
  animation: adm-drop-in 180ms var(--ease-out) both;
}
@keyframes adm-drop-in {
  from {
    opacity: 0;
    transform: translateY(-6px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
.adm-dlg.adm-fullscreen {
  width: min(1680px, calc(100vw - 48px));
  height: calc(100dvh - 48px);
  max-height: calc(100dvh - 48px);
}
.adm-dlg.adm-side {
  width: min(620px, 100vw);
  height: 100dvh;
  max-height: 100dvh;
  margin: 0 0 0 auto;
  border-radius: 0;
}
.adm-dialog-head {
  display: flex;
  flex: none;
  min-width: 0;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  border-bottom: 1px solid var(--line);
}
.adm-drop .adm-dialog-head {
  padding-top: 10px;
}
.adm-dialog-close {
  display: grid;
  flex: none;
  width: 40px;
  height: 40px;
  margin: 0 12px 0 0;
  padding: 0;
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
.adm-dialog-close:focus-visible {
  outline: 2px solid var(--mari-ink);
  outline-offset: 2px;
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
  flex: 1 1 auto;
  min-width: 0;
  margin: 0;
  padding: 14px 0 14px 24px;
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
.adm-drop .body {
  padding: 18px 18px 16px;
}
.adm-drop .head {
  font-size: 16px;
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
@media (max-width: 1020px) {
  .adm-dlg.adm-drop {
    right: 16px;
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
  .adm-dlg.adm-drop {
    inset: calc(var(--nav-h) + 8px) 14px auto auto;
    width: min(360px, calc(100vw - 28px));
  }
  .adm-dlg.adm-fullscreen {
    width: 100vw;
    height: 100dvh;
    max-height: 100dvh;
    border-radius: 0;
  }
  .head {
    padding: 14px 0 14px 16px;
  }
  .adm-dialog-close {
    margin-right: 8px;
  }
  .body {
    padding: 16px 16px 20px;
  }
  .foot {
    padding: 12px 16px calc(12px + env(safe-area-inset-bottom));
  }
}
@media (prefers-reduced-motion: reduce) {
  .adm-dlg.adm-drop[open] {
    animation: none;
  }
}
</style>
