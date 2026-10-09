<!-- Events: RCs and Super Admins manage every event (house-wide and community). Removing hides an
     event from members; only Super Admins still see removed events in the database. -->
<template>
  <div>
    <div class="adm-toolbar between">
      <div class="adm-chips" role="group" aria-label="Which events">
        <button type="button" class="adm-chip" :class="{ on: !past }" @click="show(false)">
          Upcoming
        </button>
        <button type="button" class="adm-chip" :class="{ on: past }" @click="show(true)">
          Past
        </button>
      </div>
      <button type="button" class="adm-btn mari" @click="edit()">New event</button>
    </div>

    <p v-if="error" class="adm-msg err" role="alert">{{ error }}</p>

    <ul v-if="events.length" class="adm-list">
      <li v-for="e in events" :key="e.id" class="adm-row">
        <div>
          <b>{{ e.name }}</b>
          <div class="adm-meta">
            <span class="mono">{{ when(e) }}</span>
            <span>{{ communityOf(e.community_id) }}</span>
            <span v-if="e.cancelled_at" class="adm-badge verm">cancelled</span>
            <span v-else-if="isLive(e)" class="adm-badge mari">live now</span>
          </div>
        </div>
        <div class="adm-chips">
          <button type="button" class="adm-btn ghost small" @click="edit(e)">Edit</button>
          <button
            type="button"
            class="adm-btn ghost small"
            :disabled="busy"
            @click="toggleCancel(e)"
          >
            {{ e.cancelled_at ? 'Restore' : 'Cancel' }}
          </button>
          <button type="button" class="adm-btn danger small" :disabled="busy" @click="remove(e)">
            Remove
          </button>
        </div>
      </li>
    </ul>
    <p v-else-if="!loading" class="adm-empty">
      {{ past ? 'No past events yet.' : 'Nothing planned. Add the next event.' }}
    </p>

    <AdminDialog
      v-if="form"
      ref="dlg"
      :title="form.id ? 'Edit event' : 'New event'"
      @close="form = null"
    >
      <form class="adm-form" @submit.prevent="save">
        <label class="adm-field wide">
          <span>Name</span>
          <input v-model.trim="form.name" class="adm-input" required maxlength="200" />
        </label>
        <label class="adm-field">
          <span>Starts</span>
          <input v-model="form.starts" class="adm-input" type="datetime-local" required />
        </label>
        <label class="adm-field">
          <span>Ends</span>
          <input v-model="form.ends" class="adm-input" type="datetime-local" required />
        </label>
        <label class="adm-field wide">
          <span>Who runs it</span>
          <select v-model="form.community_id" class="adm-input">
            <option :value="null">The house (everyone)</option>
            <option v-for="c in lookups.communities" :key="c.id" :value="c.id">
              {{ c.name }} community
            </option>
          </select>
        </label>
        <label class="adm-field wide">
          <span>Description</span>
          <textarea v-model.trim="form.description" class="adm-input" maxlength="4000" />
        </label>
        <label class="adm-field wide">
          <span>Registration link (optional)</span>
          <input
            v-model.trim="form.registration_link"
            class="adm-input"
            type="url"
            placeholder="https://forms.gle/…"
          />
        </label>
        <label class="adm-field wide">
          <span>Members’ link (optional)</span>
          <input
            v-model.trim="form.gmail_link"
            class="adm-input"
            type="url"
            placeholder="https://meet.google.com/…"
          />
          <small>Only signed-in members see this one. Links must start with https://</small>
        </label>
        <p v-if="formError" class="adm-msg err wide" role="alert">{{ formError }}</p>
        <div class="wide row-end">
          <button type="submit" class="adm-btn mari" :disabled="busy">
            {{ form.id ? 'Save' : 'Create event' }}
          </button>
        </div>
      </form>
    </AdminDialog>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue';
import AdminDialog from './AdminDialog.vue';
import { errorText } from '../../lib/auth.js';
import { deleteEvent, listEvents, saveEvent, setEventCancelled } from '../../lib/admin.js';

const props = defineProps({ lookups: { type: Object, required: true } });
const emit = defineEmits(['changed']);

const past = ref(false);
const events = ref([]);
const loading = ref(false);
const busy = ref(false);
const error = ref('');
const form = ref(null);
const formError = ref('');
const dlg = ref(null);

const communityOf = (id) =>
  id ? `${props.lookups.communities.find((c) => c.id === id)?.name ?? ''} community` : 'House-wide';
const isLive = (e) => new Date(e.starts_at) <= new Date() && new Date() < new Date(e.ends_at);
const fmt = (iso) =>
  new Date(iso).toLocaleString('en-IN', {
    day: 'numeric',
    month: 'short',
    hour: 'numeric',
    minute: '2-digit',
  });
const when = (e) => `${fmt(e.starts_at)} – ${fmt(e.ends_at)}`;

// <input type="datetime-local"> works in local time without a zone.
const toLocal = (iso) => {
  const d = new Date(iso);
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
};
const fromLocal = (v) => new Date(v).toISOString();

async function load() {
  loading.value = true;
  error.value = '';
  try {
    events.value = await listEvents({ past: past.value });
  } catch (e) {
    error.value = errorText(e);
  } finally {
    loading.value = false;
  }
}
onMounted(load);

function show(p) {
  past.value = p;
  load();
}

function edit(e) {
  formError.value = '';
  const start = new Date(Date.now() + 864e5);
  start.setMinutes(0, 0, 0);
  form.value = e
    ? {
        ...e,
        starts: toLocal(e.starts_at),
        ends: toLocal(e.ends_at),
        description: e.description ?? '',
      }
    : {
        name: '',
        description: '',
        starts: toLocal(start),
        ends: toLocal(new Date(start.getTime() + 36e5)),
        community_id: null,
        registration_link: '',
        gmail_link: '',
      };
}

function friendly(e) {
  const m = e?.message ?? '';
  if (/events_period/.test(m)) return 'The event has to end after it starts.';
  if (/_https/.test(m)) return 'Links must start with https://';
  if (/events_name_length/.test(m)) return 'Give the event a name (up to 200 characters).';
  if (e?.code === '42501') return 'You can’t change this event.';
  return errorText(e);
}

async function save() {
  busy.value = true;
  formError.value = '';
  try {
    await saveEvent({
      ...form.value,
      starts_at: fromLocal(form.value.starts),
      ends_at: fromLocal(form.value.ends),
    });
    dlg.value?.close();
    await load();
    emit('changed');
  } catch (e) {
    formError.value = friendly(e);
  } finally {
    busy.value = false;
  }
}

async function act(run) {
  busy.value = true;
  error.value = '';
  try {
    await run();
    await load();
    emit('changed');
  } catch (e) {
    error.value = friendly(e);
  } finally {
    busy.value = false;
  }
}
const toggleCancel = (e) => act(() => setEventCancelled(e.id, !e.cancelled_at));
const remove = (e) => {
  if (confirm(`Remove “${e.name}”? Members will no longer see it.`)) act(() => deleteEvent(e.id));
};
</script>

<style scoped>
.between {
  justify-content: space-between;
  align-items: center;
}
.row-end {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}
</style>
