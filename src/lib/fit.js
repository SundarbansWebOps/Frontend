// Names on one line, one size per group. Every `.name` in the group shrinks by
// the same factor — the one the longest name needs — so a row of cards reads as a set.
import { onBeforeUnmount, onMounted } from 'vue';

export function useFitNames(rootRef, selector = '.name', min = 0.62) {
  let ro;
  let raf = 0;
  const fit = () => {
    const els = [...(rootRef.value?.querySelectorAll(selector) ?? [])];
    for (const el of els) el.style.fontSize = '';
    let k = 1;
    for (const el of els)
      if (el.scrollWidth > el.clientWidth) k = Math.min(k, el.clientWidth / el.scrollWidth);
    k = Math.max(min, Math.floor(k * 100) / 100);
    if (k < 1)
      for (const el of els)
        el.style.fontSize = `${parseFloat(getComputedStyle(el).fontSize) * k}px`;
  };
  const soon = () => {
    cancelAnimationFrame(raf);
    raf = requestAnimationFrame(fit);
  };
  onMounted(() => {
    ro = new ResizeObserver(soon);
    ro.observe(rootRef.value);
    document.fonts?.addEventListener('loadingdone', soon);
    document.fonts?.ready.then(soon);
    soon();
  });
  onBeforeUnmount(() => {
    ro?.disconnect();
    document.fonts?.removeEventListener('loadingdone', soon);
    cancelAnimationFrame(raf);
  });
  return soon;
}
