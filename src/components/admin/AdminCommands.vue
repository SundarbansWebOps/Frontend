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
        placeholder="Jump to, search students or run an action"
        autocomplete="off"
        @input="search"
        @keydown.down.prevent="move(1)"
        @keydown.up.prevent="move(-1)"
        @keydown.enter.prevent="run(items[index])"
      />
    </div>
    <p v-if="error" class="adm-msg err" role="alert">{{ error }}</p>
    <div class="command-list" role="listbox" aria-label="Results">
      <button
        v-for="(item, i) in items"
        :key="item.key"
        role="option"
        :aria-selected="index === i"
        @click="run(item)"
        @pointermove="index = i"
      >
        <LineIcon :name="item.icon || 'people'" /><span
          ><b>{{ item.label }}</b
          ><small>{{ item.sub }}</small></span
        ><small>{{ item.group }}</small>
      </button>
      <p v-if="!items.length" class="adm-note">
        No results. Try a page name or at least three characters of a student's name.
      </p>
    </div>
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
    ...['events', 'forms', ...(props.membersVisible ? ['notices', 'roster'] : [])].map((id) => ({
      key: `create-${id}`,
      label: id === 'roster' ? 'Add students' : `New ${id.slice(0, -1)}`,
      group: 'Create',
      icon: 'book',
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
  border: 1px solid var(--line);
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
  border: 1px solid var(--line);
  border-radius: 9px;
  background: var(--sunk);
  color: var(--ink);
  font: inherit;
  font-size: 16px;
}
.palette-in input:focus-visible {
  outline: 2px solid var(--mari-ink);
  outline-offset: 1px;
}
.palette > .adm-msg {
  margin: 10px 24px 0;
}
.command-list {
  padding: 8px;
  max-height: 60svh;
  overflow: auto;
}
.command-list > button {
  display: flex;
  width: 100%;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  border-radius: 9px;
  color: var(--ink);
  text-align: left;
}
.command-list > button[aria-selected='true'] {
  background: var(--sunk);
  box-shadow: inset 3px 0 0 var(--mari-ink);
}
.command-list span {
  flex: 1;
  min-width: 0;
}
.command-list b {
  display: block;
  font-weight: 700;
}
.command-list small {
  display: block;
  font-size: 13px;
  color: var(--ink-3);
  overflow-wrap: anywhere;
}
.command-list > .adm-note {
  padding: 10px 12px;
}
</style>
