<template>
  <dialog
    ref="dialog"
    class="adm-command palette"
    aria-label="Search and commands"
    @close="emit('close')"
    @click.self="dialog.close()"
  >
    <div class="palette-in">
      <label class="visually-hidden" for="admin-command">Search pages, actions and students</label
      ><input
        id="admin-command"
        v-model="query"
        placeholder="Search students, pages or actions"
        autocomplete="off"
        @input="search"
        @keydown.down.prevent="move(1)"
        @keydown.up.prevent="move(-1)"
        @keydown.enter.prevent="run(items[index])"
      />
    </div>
    <p v-if="error" class="adm-msg err" role="alert">{{ error }}</p>
    <div class="command-list" role="listbox" aria-label="Results">
      <template v-for="(item, i) in items" :key="item.key">
        <p v-if="i === 0 || items[i - 1].group !== item.group" class="cmd-group" aria-hidden="true">
          {{ item.group }}
        </p>
        <button
          type="button"
          role="option"
          :aria-selected="index === i"
          @click="run(item)"
          @pointermove="index = i"
        >
          <span class="cmd-icon" aria-hidden="true">
            <LineIcon v-if="item.icon" :name="item.icon" />
            <template v-else>+</template>
          </span>
          <span class="cmd-text">
            <b>{{ item.label }}</b>
            <small v-if="item.sub">{{ item.sub }}</small>
          </span>
        </button>
      </template>
      <p v-if="!items.length" class="adm-note">
        Nothing matches that. Try a page name, or at least three letters of a student's name.
      </p>
    </div>
    <p class="cmd-foot" aria-hidden="true">
      <span><kbd>↑</kbd> <kbd>↓</kbd> move</span>
      <span><kbd>Enter</kbd> open</span>
      <span><kbd>Esc</kbd> close</span>
    </p>
  </dialog>
</template>
<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import LineIcon from '../site/LineIcon.vue';
import { searchMembers } from '../../lib/admin.js';
import { errorText } from '../../lib/auth.js';
import { nameOf } from '../../lib/admin-display.js';
const props = defineProps({ tabs: { type: Array, required: true }, membersVisible: Boolean });
const emit = defineEmits(['close', 'navigate', 'student', 'create']);
const dialog = ref(null);
const query = ref('');
const students = ref([]);
const index = ref(0);
const error = ref('');
let timer;
let sequence = 0;
const items = computed(() =>
  [
    ...students.value.map((s) => ({
      key: s.id,
      label: nameOf(s),
      sub: s.email,
      group: 'Students',
      icon: 'people',
      action: 'student',
      id: s.id,
    })),
    ...props.tabs.map((t) => ({
      key: t.id,
      label: t.label,
      group: 'Go to',
      icon: t.icon,
      action: 'navigate',
      id: t.id,
    })),
    ...['events', 'forms', ...(props.membersVisible ? ['notices', 'students'] : [])].map((id) => ({
      key: `create-${id}`,
      label: id === 'students' ? 'Add students' : `New ${id.slice(0, -1)}`,
      group: 'Create',
      action: 'create',
      id,
    })),
  ].filter(
    (item) =>
      item.group === 'Students' || item.label.toLowerCase().includes(query.value.toLowerCase())
  )
);
function search() {
  clearTimeout(timer);
  const token = ++sequence;
  index.value = 0;
  students.value = [];
  error.value = '';
  if (!props.membersVisible || query.value.trim().length < 3) return;
  timer = setTimeout(async () => {
    try {
      const rows = await searchMembers(query.value.trim().slice(0, 100));
      if (token === sequence) students.value = rows.slice(0, 6);
    } catch (e) {
      if (token === sequence) error.value = errorText(e);
    }
  }, 250);
}
function move(by) {
  if (items.value.length)
    index.value = (index.value + by + items.value.length) % items.value.length;
}
function run(item) {
  if (!item) return;
  emit('close');
  emit(item.action, item.id);
}
onMounted(() => dialog.value.showModal());
onBeforeUnmount(() => {
  clearTimeout(timer);
  sequence++;
});
</script>
<style scoped>
/* Keep the command search near the top, where it is easy to reach. */
.adm-command {
  position: fixed;
  width: min(640px, calc(100vw - 32px));
  max-height: calc(100dvh - 48px);
  padding: 0;
  overflow: hidden;
  border: 1px solid var(--line-strong);
  border-radius: var(--r);
  background: var(--card);
  color: var(--ink);
  box-shadow: var(--shadow);
  font-family: var(--font);
}
.adm-command[open] {
  display: flex;
  flex-direction: column;
}
.adm-command::backdrop {
  background: color-mix(in srgb, var(--ink) 48%, transparent);
}
.palette {
  margin: 10svh auto auto;
}
@media (max-width: 760px) {
  .palette {
    margin: auto 0 0;
    width: 100vw;
    max-width: none;
    max-height: calc(100dvh - 48px);
    border-radius: var(--r) var(--r) 0 0;
  }
  .palette-in {
    padding-right: 16px;
    padding-left: 16px;
  }
  .palette > .adm-msg {
    margin-right: 16px;
    margin-left: 16px;
  }
}
.palette-in {
  padding: 14px 24px 12px;
  border-bottom: 1px solid var(--line);
}
.palette-in input {
  width: 100%;
  min-width: 0;
  height: 44px;
  padding: 0 12px;
  border: 1px solid var(--line-strong);
  border-radius: 9px;
  background: var(--sunk);
  color: var(--ink);
  font: inherit;
  font-size: 16px;
}
.palette-in input::placeholder {
  color: var(--ink-3);
}
.palette-in input:focus-visible {
  outline: 2px solid var(--ink-2);
  outline-offset: 1px;
}
.palette > .adm-msg {
  margin: 10px 24px 0;
}
.command-list {
  padding: 4px 8px 8px;
  max-height: 60svh;
  overflow: auto;
}
.cmd-group {
  margin: 12px 10px 4px;
  font-size: 12px;
  font-weight: 600;
  color: var(--ink-3);
}
.command-list > button {
  display: flex;
  width: 100%;
  align-items: center;
  gap: 12px;
  padding: 8px 10px;
  border: 0;
  border-radius: 9px;
  background: transparent;
  color: var(--ink);
  text-align: left;
}
.command-list > button[aria-selected='true'] {
  background: var(--sunk);
}
.cmd-icon {
  display: grid;
  flex: none;
  width: 30px;
  height: 30px;
  place-items: center;
  border-radius: 8px;
  background: var(--paper);
  color: var(--ink-2);
  font-size: 17px;
  line-height: 1;
}
.cmd-icon svg {
  width: 17px;
  height: 17px;
}
.cmd-text {
  flex: 1;
  min-width: 0;
}
.cmd-text b {
  display: block;
  font-size: 14px;
  font-weight: 600;
}
.cmd-text small {
  display: block;
  font-size: 12px;
  color: var(--ink-3);
  overflow-wrap: anywhere;
}
.command-list > .adm-note {
  padding: 10px 12px;
}
.cmd-foot {
  display: flex;
  flex-wrap: wrap;
  gap: 6px 16px;
  margin: 0;
  padding: 10px 16px;
  border-top: 1px solid var(--line);
  font-size: 12px;
  color: var(--ink-3);
}
.cmd-foot kbd {
  color: var(--ink-2);
}
</style>
