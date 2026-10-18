<!--
  Notices from the bell: a sheet that hangs from the header (a panel from the top on phones),
  every notice newest first as a hung paper tag tied under the one above. Unread tags carry a
  vermilion mark; opening one marks it read. The notice strip under the header opens this
  panel at its notice. The tags swing once, the first time the panel opens in a visit.
-->
<template>
  <LoungeDialog variant="drop" class="np-dlg" labelledby="np-h" @close="emit('close')">
    <div class="np" :class="{ swing }">
      <div class="np-head">
        <p class="gp-kicker">From the house</p>
        <h2 id="np-h" class="ed-h">Notices</h2>
        <p class="np-sub">
          <span v-if="unread" class="np-unread">{{ unread }} unread</span>
          <span v-else>All read</span>
          <button v-if="unread" type="button" class="gp-link" @click="ev.markAllRead?.()">
            Mark all read
          </button>
        </p>
      </div>
      <p v-if="noticeError" class="np-error" role="alert">{{ noticeError }}</p>

      <template v-for="g in grouped" :key="g.label">
        <h3 class="np-group">{{ g.label }}</h3>
        <ul class="np-list">
          <li
            v-for="(n, i) in g.items"
            :key="n.id"
            class="np-item"
            :style="{ '--i': Math.min(i, 5) }"
          >
            <div
              class="gp gp-tag gp-flat nt"
              :class="{ unread: !isRead(n), open: openId === n.id }"
            >
              <span class="gp-eye" aria-hidden="true"></span>
              <button
                :id="`nt-${n.id}`"
                type="button"
                class="nt-hit"
                :aria-expanded="openId === n.id ? 'true' : 'false'"
                :aria-controls="`ntb-${n.id}`"
                @click="toggle(n)"
              >
                <span class="nt-dot" aria-hidden="true"></span>
                <span class="nt-title">
                  {{ n.title }}<span v-if="!isRead(n)" class="visually-hidden">, unread</span>
                </span>
                <span class="nt-when tnum">{{ ago(n.posted_at) }}</span>
              </button>
              <div v-show="openId === n.id" :id="`ntb-${n.id}`" class="nt-body">
                <p>{{ n.body }}</p>
                <a
                  v-if="n.link"
                  class="nt-link"
                  :href="n.link"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Open notice link <span aria-hidden="true">↗</span>
                </a>
                <p class="nt-by">{{ n.by }}</p>
              </div>
              <p v-show="openId !== n.id" class="nt-peek" aria-hidden="true">{{ n.body }}</p>
            </div>
          </li>
        </ul>
      </template>
      <p v-if="!grouped.length" class="np-empty">No notices yet.</p>
    </div>
  </LoungeDialog>
</template>

<script>
/* The tags swing only the first time the panel opens in a visit. */
let swung = false;
</script>

<script setup>
import { computed, nextTick, onMounted, ref } from 'vue';
import LoungeDialog from './LoungeDialog.vue';
import * as ev from './events.js';
import { lounge } from './session.js';

const props = defineProps({ focus: { type: String, default: '' } });
const emit = defineEmits(['close']);

const swing = !swung;
swung = true;

const list = computed(() => ev.notices?.value ?? []);
const unread = computed(() => ev.unreadCount?.value ?? 0);
const isRead = (n) => ev.isRead?.(n) ?? true;
const ago = (t) => ev.ago?.(t) ?? '';
const noticeError = computed(() => lounge.noticeError);

const openId = ref(props.focus || null);
const WEEK = 7 * 86_400_000;
const grouped = computed(() => {
  const now = ev.clock.value;
  const age = (n) => now - Date.parse(n.posted_at);
  const recent = list.value.filter((n) => age(n) >= 0 && age(n) < WEEK);
  const older = list.value.filter((n) => Number.isFinite(age(n)) && age(n) >= WEEK);
  return [
    { label: 'This week', items: recent },
    { label: 'Earlier', items: older },
  ].filter((g) => g.items.length);
});

function toggle(n) {
  openId.value = openId.value === n.id ? null : n.id;
  ev.markRead?.(n);
}

onMounted(() => {
  if (!props.focus) return;
  const n = list.value.find((x) => x.id === props.focus);
  if (n) ev.markRead?.(n);
  nextTick(() => document.getElementById(`nt-${props.focus}`)?.focus());
});
</script>
