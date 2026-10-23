<!-- A themed stand-in for <select> in the admin, styled like .adm-input. Options are
     { value, label, disabled? }, or any rows with value-key/label-key (e.g. lookups' id/name). The list opens in the top layer (Popover API), so a dialog or
     drawer never clips it and it sits above modal dialogs. Inside a <label class="adm-field"> the
     label's own <span> names it; elsewhere pass `label`. Keyboard follows the ARIA select-only
     combobox: arrows, Home/End, Enter/Space, Escape and type-to-find. -->
<template>
  <div ref="root" class="adm-select" :class="{ open }">
    <button
      ref="trigger"
      type="button"
      role="combobox"
      class="adm-input trigger"
      :aria-labelledby="labelId || undefined"
      :aria-label="labelId ? undefined : label"
      aria-haspopup="listbox"
      :aria-expanded="open"
      :aria-controls="`${uid}-list`"
      :aria-activedescendant="open && active >= 0 ? `${uid}-${active}` : undefined"
      :disabled="disabled"
      @click="onClick"
      @keydown="onKey"
    >
      <span class="value" :class="{ empty: !selected }">{{ selected?.label ?? placeholder }}</span>
      <LineIcon name="chevron" class="chev" />
    </button>
    <!-- Clicks are cancelled here so the surrounding <label> does not hand them back to the
         button and reopen the list; pointerdown is cancelled to keep focus on the button. -->
    <ul
      v-show="open"
      :id="`${uid}-list`"
      ref="list"
      popover="manual"
      role="listbox"
      class="list"
      :class="{ up }"
      :aria-labelledby="labelId || undefined"
      :aria-label="labelId ? undefined : label"
      @click.prevent
      @pointerdown.prevent
    >
      <li
        v-for="(o, i) in items"
        :id="`${uid}-${i}`"
        :key="i"
        role="option"
        :aria-selected="i === selectedIndex"
        :aria-disabled="o.disabled || undefined"
        :class="{ active: i === active }"
        @click="choose(i)"
        @pointermove="o.disabled || (active = i)"
      >
        <LineIcon v-if="i === selectedIndex" name="check" class="tick" />
        {{ o.label }}
      </li>
    </ul>
  </div>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, useId, watch } from 'vue';
import LineIcon from '../site/LineIcon.vue';

const props = defineProps({
  modelValue: { type: null, default: null },
  options: { type: Array, required: true },
  valueKey: { type: String, default: 'value' },
  labelKey: { type: String, default: 'label' },
  disabled: { type: Boolean, default: false },
  label: { type: String, default: undefined },
  placeholder: { type: String, default: 'Choose…' },
});
const emit = defineEmits(['update:modelValue', 'change']);

const uid = `sel-${useId()}`;
const root = ref(null);
const trigger = ref(null);
const list = ref(null);
const labelId = ref('');
const open = ref(false);
const up = ref(false);
const active = ref(-1);

const items = computed(() =>
  props.options.map((o) => ({
    value: o[props.valueKey],
    label: String(o[props.labelKey] ?? ''),
    disabled: !!o.disabled,
  }))
);
const selectedIndex = computed(() => items.value.findIndex((o) => o.value === props.modelValue));
const selected = computed(() => items.value[selectedIndex.value]);

onMounted(() => {
  const span = root.value.closest('label')?.querySelector(':scope > span');
  if (!span) return;
  span.id ||= `${uid}-label`;
  labelId.value = span.id;
});

async function show() {
  if (open.value || props.disabled) return;
  active.value = selectedIndex.value >= 0 ? selectedIndex.value : next(-1, 1);
  open.value = true;
  await nextTick();
  list.value.showPopover?.();
  place();
  reveal();
  document.addEventListener('pointerdown', onOutside, true);
  window.addEventListener('scroll', onScroll, true);
  window.addEventListener('resize', place);
}

function hide() {
  if (!open.value) return;
  open.value = false;
  if (list.value?.matches(':popover-open')) list.value.hidePopover();
  document.removeEventListener('pointerdown', onOutside, true);
  window.removeEventListener('scroll', onScroll, true);
  window.removeEventListener('resize', place);
}
onBeforeUnmount(hide);
watch(
  () => props.disabled,
  (d) => d && hide()
);

function choose(i) {
  const o = items.value[i];
  if (!o || o.disabled) return;
  hide();
  trigger.value.focus();
  if (o.value === props.modelValue) return;
  emit('update:modelValue', o.value);
  emit('change', o.value);
}

// Below the button, or above it when there is clearly more room there; never off-screen.
function place() {
  const el = list.value;
  if (!el || !trigger.value) return;
  const r = trigger.value.getBoundingClientRect();
  const gap = 6;
  const edge = 8;
  const below = innerHeight - r.bottom - gap - edge;
  const above = r.top - gap - edge;
  up.value = below < 200 && above > below;
  el.style.minWidth = `${r.width}px`;
  el.style.maxWidth = `${innerWidth - edge * 2}px`;
  el.style.maxHeight = `${Math.min(320, up.value ? above : below)}px`;
  el.style.top = up.value ? 'auto' : `${r.bottom + gap}px`;
  el.style.bottom = up.value ? `${innerHeight - r.top + gap}px` : 'auto';
  el.style.left = `${Math.max(edge, Math.min(r.left, innerWidth - edge - el.offsetWidth))}px`;
}

function onScroll(e) {
  if (e.target !== list.value) place();
}

function onOutside(e) {
  if (!root.value.contains(e.target)) hide();
}

function reveal() {
  list.value?.children[active.value]?.scrollIntoView({ block: 'nearest' });
}

// The next enabled option from `from` in direction `dir`, or `from` when there is none.
function next(from, dir) {
  for (let i = from + dir; i >= 0 && i < items.value.length; i += dir) {
    if (!items.value[i].disabled) return i;
  }
  return from;
}

function move(i) {
  active.value = i;
  reveal();
}

let typed = '';
let typedTimer;
function find(ch) {
  clearTimeout(typedTimer);
  typedTimer = setTimeout(() => (typed = ''), 600);
  typed += ch.toLowerCase();
  const n = items.value.length;
  // A fresh letter starts after the current option, so pressing it again cycles.
  const start = typed.length === 1 ? active.value + 1 : Math.max(active.value, 0);
  for (let k = 0; k < n; k++) {
    const i = (start + k) % n;
    const o = items.value[i];
    if (!o.disabled && o.label.toLowerCase().startsWith(typed)) return move(i);
  }
}

// Keyboard opens and closes the list on keydown, so the click a key would synthesise is ignored.
function onClick(e) {
  if (e.detail === 0) return;
  open.value ? hide() : show();
}

async function onKey(e) {
  const k = e.key;
  const printable = k.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey;
  if (!open.value) {
    if (['ArrowDown', 'ArrowUp', 'Enter', ' ', 'Home', 'End'].includes(k) || printable) {
      e.preventDefault();
      await show();
      if (k === 'Home') move(next(-1, 1));
      else if (k === 'End') move(next(items.value.length, -1));
      else if (printable && k !== ' ') find(k);
    }
    return;
  }
  if (k === 'Tab') return hide();
  if (k === 'Escape') {
    // Close only the list, not the dialog around it.
    e.preventDefault();
    e.stopPropagation();
    return hide();
  }
  const step = { ArrowDown: 1, ArrowUp: -1, PageDown: 10, PageUp: -10 }[k];
  if (step) {
    e.preventDefault();
    let i = active.value;
    for (let s = 0; s < Math.abs(step); s++) i = next(i, Math.sign(step));
    return move(i);
  }
  if (k === 'Home' || k === 'End') {
    e.preventDefault();
    return move(k === 'Home' ? next(-1, 1) : next(items.value.length, -1));
  }
  if (k === 'Enter' || (k === ' ' && !typed)) {
    e.preventDefault();
    return choose(active.value);
  }
  if (printable) {
    e.preventDefault();
    find(k);
  }
}
</script>

<style scoped>
.adm-select {
  min-width: 0;
}
.trigger {
  display: flex;
  align-items: center;
  gap: 8px;
  padding-right: 10px;
  text-align: left;
  cursor: pointer;
}
.value {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.value.empty {
  color: var(--ink-3);
}
.chev {
  flex: none;
  width: 16px;
  height: 16px;
  color: var(--ink-3);
  transition: transform 0.2s var(--ease-out);
}
.open .trigger {
  border-color: var(--mari);
  box-shadow: 0 0 0 3px var(--mari-soft);
}
.open .chev {
  color: var(--mari-ink);
  transform: rotate(180deg);
}
.trigger:disabled .chev {
  opacity: 0.5;
}

/* Undo the popover's centred UA box; place() sets top/bottom/left and the size limits. */
.list {
  position: fixed;
  inset: auto;
  z-index: 80;
  box-sizing: border-box;
  margin: 0;
  padding: 6px;
  overflow-y: auto;
  overscroll-behavior: contain;
  list-style: none;
  border: 1px solid var(--line);
  border-radius: 12px;
  background: var(--card);
  color: var(--ink);
  box-shadow: var(--shadow);
  font-family: var(--font);
  font-size: 14px;
  font-weight: 400;
  transform-origin: top;
  animation: list-in 0.16s var(--ease-out);
}
.list.up {
  transform-origin: bottom;
}
@keyframes list-in {
  from {
    opacity: 0;
    transform: scale(0.97);
  }
}
.list li {
  position: relative;
  display: flex;
  align-items: center;
  min-height: 36px;
  padding: 7px 12px 7px 32px;
  border-radius: 8px;
  line-height: 1.3;
  cursor: pointer;
}
.list li.active {
  background: var(--sunk);
}
.list li[aria-selected='true'] {
  background: var(--mari-soft);
  color: var(--mari-ink);
  font-weight: 600;
}
.list li[aria-disabled='true'] {
  color: var(--ink-3);
  cursor: not-allowed;
}
.tick {
  position: absolute;
  left: 9px;
  width: 16px;
  height: 16px;
}

@media (max-width: 760px) {
  .list {
    font-size: 16px;
  }
  .list li {
    min-height: 44px;
  }
}
@media (prefers-reduced-motion: reduce) {
  .list {
    animation: none;
  }
}
</style>
