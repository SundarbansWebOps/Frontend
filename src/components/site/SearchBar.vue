<!-- One box that understands how students talk: "ma1 pyq", "dbms w4", "q1 stats". -->
<template>
  <div class="search" :class="[size, { open: showDrop, focused }]">
    <label class="field">
      <svg class="glass" viewBox="0 0 24 24" aria-hidden="true">
        <circle cx="10.5" cy="10.5" r="6.5" />
        <path d="M15.5 15.5 20 20" />
      </svg>
      <span class="visually-hidden">Search courses, notes and past papers</span>
      <input
        ref="input"
        :value="modelValue"
        type="search"
        role="combobox"
        aria-autocomplete="list"
        aria-haspopup="listbox"
        :aria-expanded="showDrop"
        :aria-controls="showDrop ? 'course-search-results' : undefined"
        :aria-activedescendant="
          showDrop && items[active] ? `course-result-${items[active].key}` : undefined
        "
        autocomplete="off"
        spellcheck="false"
        enterkeyhint="go"
        @input="onInput"
        @focus="focused = true"
        @blur="onBlur"
        @keydown.down.prevent="move(1)"
        @keydown.up.prevent="move(-1)"
        @keydown.enter.prevent="choose(active, $event)"
        @keydown.esc="clear"
      />
      <Transition name="ph" mode="out-in">
        <span v-if="!modelValue" :key="phIndex" class="ph" aria-hidden="true">
          <span v-if="size === 'lg'" class="wide-only">Find anything — </span>Try
          <b>{{ EXAMPLES[phIndex] }}</b>
        </span>
      </Transition>
      <span class="parsed" aria-hidden="true">
        <TransitionGroup name="chip">
          <em v-for="c in chips" :key="c">{{ c }}</em>
        </TransitionGroup>
      </span>
      <kbd v-if="!focused && !modelValue">/</kbd>
    </label>

    <Transition name="drop">
      <div
        v-if="showDrop"
        id="course-search-results"
        class="drop"
        role="listbox"
        tabindex="-1"
        aria-label="Search results"
      >
        <p v-if="!items.length" class="empty">
          Nothing matched “{{ modelValue }}”. Try a course code like <b>BSMA1001</b> or a short name
          like <b>PDSA</b>.
        </p>
        <button
          v-for="(it, i) in items"
          :key="it.key"
          :id="`course-result-${it.key}`"
          type="button"
          role="option"
          tabindex="-1"
          class="item"
          :class="{ active: i === active }"
          :aria-selected="i === active"
          :style="{ '--i': i }"
          @mousedown.prevent
          @mouseenter="active = i"
          @click="choose(i, $event)"
        >
          <span class="code mono">{{ it.code }}</span>
          <span class="what">
            <strong>{{ it.title }}</strong>
            <small>{{ it.sub }}</small>
          </span>
          <span class="go" aria-hidden="true">{{ it.external ? '↗' : '→' }}</span>
        </button>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import { byCode, openCourse, search } from '../../lib/store.js';

const props = defineProps({
  modelValue: { type: String, default: '' },
  size: { type: String, default: 'md' },
  dropdown: { type: Boolean, default: true },
});
const emit = defineEmits(['update:modelValue', 'enter']);

const EXAMPLES = ['ma1 pyq', 'dbms week 4', 'q1 stats', 'python oppe', 'mlt end term', 'BSCS2002'];
const input = ref(null);
const focused = ref(false);
const active = ref(0);
const phIndex = ref(0);
let phTimer;

onMounted(() => {
  phTimer = setInterval(() => (phIndex.value = (phIndex.value + 1) % EXAMPLES.length), 2600);
  window.addEventListener('keydown', slash);
});
onBeforeUnmount(() => {
  clearInterval(phTimer);
  window.removeEventListener('keydown', slash);
});

function slash(e) {
  const t = e.target;
  if (e.key !== '/' || t.matches?.('input, textarea, [contenteditable]')) return;
  e.preventDefault();
  input.value?.focus();
}

const result = computed(() => search(props.modelValue));

const chips = computed(() => {
  const p = result.value.parsed;
  const out = [];
  if (p.tab) out.push(p.tab === 'pyqs' ? 'Past papers' : 'Notes');
  if (p.exam) out.push(p.exam);
  if (p.week) out.push(`Week ${p.week}`);
  return out;
});

const items = computed(() => {
  const r = result.value;
  const p = r.parsed;
  const list = r.courses.map((h) => {
    const c = byCode[h.code];
    const what =
      h.tab === 'notes'
        ? p.week
          ? `Week ${p.week} notes`
          : 'Notes'
        : p.exam
          ? `${p.exam} papers`
          : 'Past papers';
    return {
      key: 'c' + h.code,
      code: c.code,
      title: c.short === c.name ? c.name : `${c.short} — ${c.name}`,
      sub: `${what} · ${h.count} ${h.count === 1 ? 'file' : 'files'}`,
      open: h,
    };
  });
  for (const [i, x] of r.resources.entries())
    list.push({
      key: 'r' + i,
      code: x.code,
      title: x.title,
      sub: `${x.kind}${x.sub ? ' · ' + x.sub : ''}`,
      link: x.link,
      external: true,
    });
  return list.slice(0, 8);
});

const showDrop = computed(
  () => props.dropdown && focused.value && props.modelValue.trim().length > 0
);

function onInput(e) {
  active.value = 0;
  emit('update:modelValue', e.target.value);
}
function move(d) {
  const n = items.value.length;
  if (n) active.value = (active.value + d + n) % n;
}
function choose(i, event) {
  const it = items.value[i];
  if (!props.dropdown) {
    emit('enter', event);
    return;
  }
  if (!it) return;
  if (it.link) window.open(it.link, '_blank', 'noopener');
  else
    openCourse(
      it.open.code,
      it.open,
      event?.type === 'click' ? event : { currentTarget: input.value }
    );
  input.value?.blur();
}
function clear() {
  emit('update:modelValue', '');
}
function onBlur() {
  focused.value = false;
}

defineExpose({ focus: () => input.value?.focus() });
</script>

<style scoped>
.search {
  position: relative;
  z-index: 20;
}
.field {
  position: relative;
  display: flex;
  align-items: center;
  gap: 10px;
  height: 52px;
  padding: 0 14px 0 16px;
  border: 1.5px solid var(--ink-3);
  border-radius: 14px;
  background: var(--card);
  cursor: text;
  transition:
    border-color 0.2s,
    box-shadow 0.3s var(--ease-out),
    border-radius 0.25s;
}
.focused .field {
  border-color: var(--ink);
  box-shadow:
    0 0 0 4px color-mix(in srgb, var(--acc, var(--mari)) 35%, transparent),
    var(--shadow);
}
.open .field {
  border-radius: 14px 14px 0 0;
}
.glass {
  flex: none;
  width: 20px;
  height: 20px;
  fill: none;
  stroke: var(--ink-2);
  stroke-width: 2;
  stroke-linecap: round;
  transition: transform 0.4s var(--ease-spring);
}
.focused .glass {
  transform: rotate(-12deg) scale(1.08);
  stroke: var(--ink);
}
input {
  flex: 1;
  min-width: 0;
  height: 100%;
  border: 0;
  outline: 0;
  background: transparent;
  font: inherit;
  font-size: 16px;
  color: var(--ink);
}
input::-webkit-search-cancel-button {
  display: none;
}
.ph {
  position: absolute;
  left: 46px;
  pointer-events: none;
  color: var(--ink-3);
  font-size: 16px;
  white-space: nowrap;
  overflow: hidden;
  max-width: calc(100% - 90px);
  text-overflow: ellipsis;
}
.ph b {
  font-family: var(--mono);
  font-weight: 500;
  color: var(--ink-2);
  background: var(--sunk);
  padding: 1px 6px;
  border-radius: 5px;
}
.ph-enter-active,
.ph-leave-active {
  transition:
    opacity 0.25s,
    transform 0.35s var(--ease-out);
}
.ph-enter-from {
  opacity: 0;
  transform: translateY(8px);
}
.ph-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

.parsed {
  display: flex;
  gap: 6px;
}
.parsed em {
  font-style: normal;
  font-size: 12px;
  font-weight: 600;
  padding: 3px 8px;
  border-radius: 99px;
  background: var(--acc-wash, var(--mari-soft));
  color: var(--acc, var(--mari-ink));
  white-space: nowrap;
}
.chip-enter-active {
  transition: all 0.4s var(--ease-spring);
}
.chip-leave-active {
  transition: all 0.2s;
  position: absolute;
}
.chip-enter-from,
.chip-leave-to {
  opacity: 0;
  transform: scale(0.6);
}
kbd {
  font-family: var(--mono);
  font-size: 12px;
  color: var(--ink-3);
  border: 1px solid var(--line-strong);
  border-bottom-width: 2px;
  border-radius: 6px;
  padding: 1px 7px;
}

.drop {
  position: absolute;
  inset: 100% 0 auto;
  display: grid;
  padding: 6px;
  border: 1.5px solid var(--ink);
  border-top: 1px dashed var(--line-strong);
  border-radius: 0 0 14px 14px;
  background: var(--card);
  box-shadow: var(--shadow);
  max-height: min(60vh, 460px);
  overflow: auto;
  transform-origin: top;
}
.drop-enter-active {
  transition:
    opacity 0.2s,
    transform 0.35s var(--ease-out);
}
.drop-leave-active {
  transition: opacity 0.12s;
}
.drop-enter-from {
  opacity: 0;
  transform: scaleY(0.92);
}
.drop-leave-to {
  opacity: 0;
}
.item {
  display: grid;
  grid-template-columns: 84px minmax(0, 1fr) auto;
  align-items: center;
  gap: 12px;
  padding: 10px 10px;
  border: 0;
  border-radius: 10px;
  background: transparent;
  text-align: left;
  animation: rise 0.4s var(--ease-out) both;
  animation-delay: calc(var(--i) * 30ms);
}
.item.active {
  background: var(--sunk);
}
.item .code {
  font-size: 12px;
  color: var(--acc, var(--mari-ink));
}
.what {
  display: grid;
  min-width: 0;
}
.what strong {
  font-weight: 600;
  font-size: 15px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.what small {
  font-size: 12.5px;
  color: var(--ink-2);
}
.go {
  color: var(--ink-3);
  transition: transform 0.3s var(--ease-out);
}
.item.active .go {
  transform: translateX(3px);
  color: var(--ink);
}
.empty {
  margin: 0;
  padding: 14px 12px;
  color: var(--ink-2);
  font-size: 14px;
}

/* Large variant: the input IS the page's first element, not a banner. */
.lg .field {
  height: 76px;
  border-width: 2px;
  border-radius: 18px;
  padding: 0 20px 0 22px;
}
.lg input,
.lg .ph {
  font-size: clamp(19px, 2.4vw, 26px);
  font-weight: 500;
  letter-spacing: -0.015em;
}
.lg .ph {
  left: 58px;
}
.lg .glass {
  width: 26px;
  height: 26px;
}

@media (max-width: 640px) {
  .wide-only,
  kbd {
    display: none;
  }
  .ph {
    font-size: 15px;
  }
  .parsed em:not(:first-child) {
    display: none;
  }
  .item {
    grid-template-columns: 72px minmax(0, 1fr) auto;
  }
}
</style>
