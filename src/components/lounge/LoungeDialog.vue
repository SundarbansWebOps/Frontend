<!--
  Every Lounge pop-up: a native modal <dialog> (focus stays inside, the page behind is inert,
  Esc closes), plus Back closes it (layers.js) and a tap on the dim closes it. The sheet is
  ghat paper with the lotus band on its top edge (cards.css .gp-band-top; styles in
  panels.css, .ld).
  variant: 'center' (a sheet; bottom sheet on phones), 'side' (a panel from the right;
  bottom sheet on phones), 'drop' (unrolls from under the header's bottom rule, aligned to
  the header's actions; full width under the header on phones). Motion (_notes/motion.md, paper): one short entrance in CSS,
  one short exit here; nothing moves at rest.
-->
<template>
  <dialog
    ref="dlg"
    class="ld"
    :class="`ld-${variant}`"
    :aria-labelledby="labelledby || undefined"
    :aria-label="label || undefined"
    @cancel.prevent="close"
    @close="onClosed"
    @click.self="close"
    @keydown.tab="trap"
  >
    <div class="ld-panel">
      <button type="button" class="ld-x" aria-label="Close" @click="close">
        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 6l12 12M18 6 6 18" /></svg>
      </button>
      <slot :close="close" :swap="swap" />
    </div>
  </dialog>
</template>

<script>
/* Set by swap() until the next pop-up mounts (module scope: shared by every pop-up). */
let passing = false;
</script>

<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue';
import { enter, handOver, leave } from './layers.js';
import { animate } from './home/motion.js';
import { boot } from './state.js';

const props = defineProps({
  variant: { type: String, default: 'center' },
  labelledby: { type: String, default: '' },
  label: { type: String, default: '' },
});
const emit = defineEmits(['close']);

const dlg = ref(null);
let closing = false;
let closed = false;

/* Back button: close at once, history is already handled. */
const closeNow = () => {
  if (dlg.value?.open) dlg.value.close();
};

/* Exits: paper lifts away (centre), slides back (side), fades (drop), drops (phone sheet). */
const EASE_IN = 'cubic-bezier(0.55, 0, 1, 0.45)';
const OUT = {
  center: [{ opacity: 0, transform: 'translate3d(0, 4px, 0)' }, 180],
  side: [{ opacity: 0, transform: 'translate3d(24px, 0, 0)' }, 180],
  drop: [{ opacity: 0 }, 140],
  sheet: [{ transform: 'translate3d(0, 100%, 0)' }, 240],
};
const phone = () => matchMedia('(max-width: 759px)').matches;
const reduced = () => boot.reduce || matchMedia('(prefers-reduced-motion: reduce)').matches;

async function close() {
  if (closing || closed || !dlg.value?.open) return;
  closing = true;
  let a = null;
  /* The dim leaves with the paper (a handed-over dim is already clear, see swap). */
  dlg.value.classList.add('ld-out');
  if (!reduced()) {
    const [to, ms] = OUT[phone() && props.variant !== 'drop' ? 'sheet' : props.variant];
    a = animate(dlg.value, [{ opacity: 1, transform: 'none' }, to], {
      duration: ms,
      easing: EASE_IN,
      fill: 'forwards',
    });
    await a.finished.catch(() => {});
  }
  dlg.value?.close();
  a?.cancel();
}

/* Tab and Shift+Tab wrap inside the pop-up instead of leaving for the browser's chrome. */
const FOCUSABLE =
  'a[href], button:not([disabled]), input:not([disabled]), textarea, select, [tabindex]:not([tabindex="-1"])';
function trap(ev) {
  const els = [...dlg.value.querySelectorAll(FOCUSABLE)].filter((el) => el.offsetParent !== null);
  if (!els.length) return;
  const first = els[0];
  const last = els.at(-1);
  if (ev.shiftKey && document.activeElement === first) {
    ev.preventDefault();
    last.focus();
  } else if (!ev.shiftKey && document.activeElement === last) {
    ev.preventDefault();
    first.focus();
  }
}

/* Close this one and let the next pop-up take over its history entry. */
/* One dim at a time: the next pop-up mounts on top of this one before it has closed, so this
   one's dim clears at once and the next one's dim shows at full strength, with no fade. Two
   stacked dims, or a fade from clear, read as the page flickering darker and back. */
function swap() {
  handOver();
  passing = true;
  dlg.value?.classList.add('ld-passed');
  close();
}

function onClosed() {
  closed = true;
  leave(closeNow);
  emit('close');
}

onMounted(() => {
  if (passing) dlg.value.classList.add('ld-taken');
  passing = false;
  dlg.value.showModal();
  enter(closeNow);
});

onBeforeUnmount(() => {
  if (!closed && dlg.value?.open) {
    closed = true;
    dlg.value.close();
    leave(closeNow);
  }
});

defineExpose({ close, swap });
</script>
