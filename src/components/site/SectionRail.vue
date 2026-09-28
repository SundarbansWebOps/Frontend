<!--
  The sticky section rail shared by House, Teams and the Lounge: scroll-spy plus a
  sliding ink pill. Sections are found by id. Arriving at #section is handled by the router's scrollBehavior.
-->
<template>
  <nav class="rail" :class="{ night }" :aria-label="label">
    <div class="chips">
      <i class="pill" :style="pill" />
      <a
        v-for="s in sections"
        :key="s.id"
        :ref="(el) => (chipEls[s.id] = el)"
        class="chip"
        :class="{ on: here === s.id }"
        :href="`#${s.id}`"
        :aria-current="here === s.id ? 'true' : undefined"
        @click.prevent="goTo(s.id)"
        >{{ s.label }}</a
      >
    </div>
  </nav>
</template>

<script setup>
import { nextTick, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue';

const props = defineProps({
  sections: { type: Array, required: true },
  label: { type: String, default: 'Sections' },
  night: Boolean,
});

const here = ref(props.sections[0].id);
const chipEls = reactive({});
const pill = ref({});
async function placePill() {
  await nextTick();
  const el = chipEls[here.value];
  if (el)
    pill.value = { width: `${el.offsetWidth}px`, transform: `translateX(${el.offsetLeft}px)` };
}
watch(here, placePill);

function spy() {
  const line = innerHeight * 0.35;
  let cur = props.sections[0].id;
  for (const s of props.sections)
    if (document.getElementById(s.id)?.getBoundingClientRect().top <= line) cur = s.id;
  // The last section can be too short to reach the line; the page bottom counts as it.
  if (innerHeight + scrollY >= document.documentElement.scrollHeight - 4)
    cur = props.sections.at(-1).id;
  here.value = cur;
}
function goTo(id, behavior = 'smooth') {
  const el = document.getElementById(id);
  if (!el) return;
  scrollTo({
    top: el.getBoundingClientRect().top + scrollY - 120,
    behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : behavior,
  });
}
defineExpose({ goTo });

onMounted(() => {
  placePill();
  spy();
  addEventListener('scroll', spy, { passive: true });
  addEventListener('resize', placePill);
  document.fonts?.ready.then(placePill);
  document.fonts?.addEventListener('loadingdone', placePill);
});
onBeforeUnmount(() => {
  removeEventListener('scroll', spy);
  removeEventListener('resize', placePill);
  document.fonts?.removeEventListener('loadingdone', placePill);
});
</script>

<style scoped>
.rail {
  position: sticky;
  top: calc(var(--nav-h) + 8px);
  z-index: 20;
  justify-self: start;
  max-width: 100%;
}
.chips {
  position: relative;
  display: flex;
  gap: 4px;
  padding: 4px;
  border-radius: 99px;
  background: color-mix(in srgb, var(--sunk) 88%, transparent);
  backdrop-filter: blur(10px);
  box-shadow: var(--shadow);
  overflow-x: auto;
  scrollbar-width: none;
}
.pill {
  position: absolute;
  left: 0;
  top: 4px;
  bottom: 4px;
  border-radius: 99px;
  background: var(--ink);
  transition:
    transform 0.5s var(--ease-spring),
    width 0.5s var(--ease-spring);
}
.chip {
  position: relative;
  padding: 8px 15px;
  border-radius: 99px;
  font-size: 14px;
  font-weight: 600;
  color: var(--ink-2);
  text-decoration: none;
  white-space: nowrap;
  transition: color 0.25s;
}
.chip:hover {
  color: var(--ink);
}
.chip.on {
  color: var(--paper);
}
.night .chips {
  background: color-mix(in srgb, #15120e 86%, transparent);
  box-shadow: 0 10px 30px -12px rgb(0 0 0 / 0.6);
}
.night .pill {
  background: #f2a93b;
}
.night .chip {
  color: #b9ac9a;
}
.night .chip:hover {
  color: #f3ebdd;
}
.night .chip.on {
  color: #1d1915;
}
@media (max-width: 560px) {
  .chip {
    padding: 8px 12px;
    font-size: 13.5px;
  }
}
</style>
