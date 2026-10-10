<!-- Organizer forms: house, region, community or bound to an event. Field order is stored as
     given. Invite URLs are WhatsApp-only and shown to a student after they submit, not before. -->
<template>
  <div>
    <div class="adm-toolbar between">
      <p class="adm-note">
        {{ forms.length }} form{{ forms.length === 1 ? '' : 's' }} you can manage.
      </p>
      <button type="button" class="adm-btn mari" @click="edit()">New form</button>
    </div>
    <p v-if="error" class="adm-msg err" role="alert">{{ error }}</p>
    <p v-if="notice" class="adm-msg ok" role="status">{{ notice }}</p>

    <ul v-if="mine.length" class="adm-list">
      <li v-for="f in mine" :key="f.id" class="adm-row">
        <div>
          <b>{{ f.title }}</b>
          <div class="adm-meta">
            <span>{{ scopeOf(f) }}</span>
            <span v-if="f.archived_at" class="adm-badge">archived</span>
            <span v-else-if="formStatus(f) === 'draft'" class="adm-badge">draft</span>
            <span v-else-if="formStatus(f) === 'scheduled'" class="adm-badge">scheduled</span>
            <span v-else-if="formStatus(f) === 'open'" class="adm-badge mari">open</span>
            <span v-else class="adm-badge">closed</span>
            <span v-if="f.event_id" class="adm-badge">event registration</span>
          </div>
        </div>
        <div class="adm-chips">
          <button type="button" class="adm-btn ghost small" @click="edit(f)">Edit</button>
          <button type="button" class="adm-btn ghost small" @click="openResponses(f)">
            Responses
          </button>
          <button type="button" class="adm-btn ghost small" @click="archive(f)">
            {{ f.archived_at ? 'Restore' : 'Archive' }}
          </button>
        </div>
      </li>
    </ul>
    <p v-else-if="!loading" class="adm-empty">No forms in your scope yet.</p>

    <AdminDialog
      v-if="form"
      ref="dlg"
      wide
      :title="form.id ? 'Edit form' : 'New form'"
      @close="form = null"
    >
      <form class="adm-form" @submit.prevent="save(false)">
        <label class="adm-field wide">
          <span>Title</span>
          <input v-model.trim="form.title" class="adm-input" required maxlength="200" />
        </label>
        <label class="adm-field wide">
          <span>Description</span>
          <textarea v-model.trim="form.description" class="adm-input" maxlength="4000" />
        </label>
        <label class="adm-field">
          <span>Form kind</span>
          <select v-model="form.form_kind" class="adm-input">
            <option value="general">General form</option>
            <option value="group">Group application</option>
            <option value="recruitment">Recruitment</option>
          </select>
        </label>
        <label v-if="form.form_kind === 'group'" class="adm-field">
          <span>Group label</span>
          <input v-model.trim="form.group_label" class="adm-input" maxlength="80" />
        </label>
        <label v-if="form.form_kind === 'group'" class="adm-field wide">
          <span>Group purpose</span>
          <input v-model.trim="form.group_purpose" class="adm-input" maxlength="300" />
          <small>Use verified source copy; applicants see this beside the group label.</small>
        </label>
        <p v-if="form.archived_at" class="adm-note wide">
          Archived forms stay available to organizers and can be restored.
        </p>
        <label class="adm-field">
          <span>Scope</span>
          <select v-model="form.scope" class="adm-input" @change="onScope">
            <option v-if="isSuperAdmin" value="house">House</option>
            <option v-if="isSuperAdmin || isRc" value="region">Region</option>
            <option v-if="isSuperAdmin || isHead" value="community">Community</option>
            <option value="event">Bound to an event</option>
          </select>
        </label>
        <label v-if="form.scope === 'region'" class="adm-field">
          <span>Region</span>
          <select v-model="form.region_id" class="adm-input" :disabled="isRc">
            <option v-for="r in lookups.regions" :key="r.id" :value="r.id">{{ r.name }}</option>
          </select>
        </label>
        <label v-if="form.scope === 'community'" class="adm-field">
          <span>Community</span>
          <select v-model="form.community_id" class="adm-input" :disabled="isHead">
            <option v-for="c in lookups.communities" :key="c.id" :value="c.id">{{ c.name }}</option>
          </select>
        </label>
        <label v-if="form.scope === 'event'" class="adm-field">
          <span>Event</span>
          <select v-model="form.event_id" class="adm-input">
            <option v-for="e in eventOptions" :key="e.id" :value="e.id">
              {{ e.name }} · {{ eventStatus(e) }}
            </option>
          </select>
        </label>
        <label class="adm-field">
          <span>
            <input v-model="form.is_open" type="checkbox" />
            Accepting responses
          </span>
        </label>
        <label class="adm-field">
          <span>Opens</span>
          <input v-model="form.opens" class="adm-input" type="datetime-local" />
        </label>
        <label class="adm-field">
          <span>Closes</span>
          <input v-model="form.closes" class="adm-input" type="datetime-local" />
        </label>
        <div class="wide">
          <p class="adm-kicker">Audience</p>
          <AdminCohortSelect v-if="cohorts" v-model="form.audience_cohorts" :cohorts="cohorts" />
        </div>
        <label class="adm-field wide">
          <span>WhatsApp invite (optional)</span>
          <input
            v-model.trim="form.invite_url"
            class="adm-input"
            type="url"
            :disabled="form.remove_invite"
            placeholder="https://chat.whatsapp.com/…"
          />
          <small>
            Students see this only after they submit. Use a chat.whatsapp.com or wa.me HTTPS link.
            Saved invites stay private; enter a URL here to set or replace one.
          </small>
        </label>

        <label v-if="form.id" class="adm-field wide">
          <span>
            <input v-model="form.remove_invite" type="checkbox" />
            Remove the saved WhatsApp invite
          </span>
        </label>

        <div class="wide fields">
          <p class="adm-kicker">Fields</p>
          <p class="adm-note">Order is the order students see. Keys must stay unique.</p>
          <div v-for="(field, i) in form.fields" :key="field._id" class="adm-card field">
            <label class="adm-field">
              <span>Label</span>
              <input
                v-model.trim="field.label"
                class="adm-input"
                required
                maxlength="300"
                @change="syncKey(field, i)"
              />
            </label>
            <label class="adm-field">
              <span>Key</span>
              <input v-model.trim="field.key" class="adm-input mono" required maxlength="64" />
            </label>
            <label class="adm-field">
              <span>Type</span>
              <select v-model="field.type" class="adm-input">
                <option v-for="t in FORM_FIELD_TYPES" :key="t" :value="t">{{ t }}</option>
              </select>
            </label>
            <label class="adm-field">
              <span>Prefill</span>
              <select v-model="field.prefill" class="adm-input">
                <option :value="''">None</option>
                <option v-for="p in PREFILL_KEYS" :key="p" :value="p">{{ p }}</option>
              </select>
            </label>
            <label class="adm-field">
              <span>
                <input v-model="field.required" type="checkbox" />
                Required
              </span>
            </label>
            <label v-if="field.type === 'select' || field.type === 'multiselect'" class="adm-field">
              <span>
                <input v-model="field.allow_other" type="checkbox" />
                Allow “Other”
              </span>
            </label>
            <label
              v-if="field.type === 'select' || field.type === 'multiselect'"
              class="adm-field wide"
            >
              <span>Options (one per line)</span>
              <textarea v-model="field.optionsText" class="adm-input" />
            </label>
            <div class="acts">
              <button
                type="button"
                class="adm-btn ghost small"
                :disabled="i === 0"
                @click="move(i, -1)"
              >
                Up
              </button>
              <button
                type="button"
                class="adm-btn ghost small"
                :disabled="i === form.fields.length - 1"
                @click="move(i, 1)"
              >
                Down
              </button>
              <button type="button" class="adm-btn danger small" @click="form.fields.splice(i, 1)">
                Remove
              </button>
            </div>
          </div>
          <button type="button" class="adm-btn ghost" @click="addField">Add field</button>
        </div>

        <p v-if="formError" class="adm-msg err wide" role="alert">{{ formError }}</p>
        <div class="wide row-end">
          <button type="submit" class="adm-btn ghost" :disabled="busy">Save draft</button>
          <button
            v-if="form.published_at"
            type="button"
            class="adm-btn ghost"
            :disabled="busy"
            @click="save('unpublish')"
          >
            Unpublish
          </button>
          <button type="button" class="adm-btn mari" :disabled="busy" @click="save('publish')">
            Publish
          </button>
        </div>
      </form>
    </AdminDialog>

    <AdminDialog
      v-if="responsesFor"
      ref="respDlg"
      wide
      :title="`${responsesFor.title} responses`"
      @close="responsesFor = null"
    >
      <p v-if="respError" class="adm-msg err" role="alert">{{ respError }}</p>
      <p v-else-if="!responses.length" class="adm-empty">No responses yet.</p>
      <div v-else class="adm-table-wrap">
        <table class="adm-table">
          <thead>
            <tr>
              <th>Email</th>
              <th>Submitted</th>
              <th v-for="f in responseFields" :key="f.key">{{ f.label }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="r in responses" :key="r.id">
              <td class="mono">{{ r.email }}</td>
              <td class="mono">{{ day(r.submitted_at) }}</td>
              <td v-for="f in responseFields" :key="f.identity">{{ answerText(r, f) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="row-end">
        <button
          type="button"
          class="adm-btn"
          :disabled="!responses.length"
          @click="downloadResponses"
        >
          Download CSV
        </button>
      </div>
    </AdminDialog>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import AdminDialog from './AdminDialog.vue';
import AdminCohortSelect from './AdminCohortSelect.vue';
import { auth, errorText, isRc, isSuperAdmin } from '../../lib/auth.js';
import {
  FORM_FIELD_TYPES,
  PREFILL_KEYS,
  canManageEvent,
  downloadCsv,
  exportFormResponses,
  fieldKeyFromLabel,
  formResponsesToCsv,
  getAvailableCohorts,
  listEvents,
  listForms,
  saveForm,
} from '../../lib/admin.js';

const props = defineProps({ lookups: { type: Object, required: true } });
const emit = defineEmits(['changed']);

const isHead = computed(
  () => auth.dashboard?.position === 'head' || auth.dashboard?.position === 'co_head'
);
const forms = ref([]);
const events = ref([]);
const cohorts = ref(null);
const loading = ref(false);
const busy = ref(false);
const error = ref('');
const notice = ref('');
const form = ref(null);
const formError = ref('');
const dlg = ref(null);
const responsesFor = ref(null);
const responses = ref([]);
const responseFields = ref([]);
const respError = ref('');
let fieldN = 0;

const mine = computed(() => forms.value.filter((f) => f.can_manage !== false));
const eventOptions = computed(() => {
  const manageable = events.value.filter(canManageEvent);
  const eligible = manageable.filter(
    (event) =>
      !event.archive &&
      !event.cancelled_at &&
      event.published_at &&
      event.ends_at &&
      new Date(event.ends_at) > new Date()
  );
  const selected = manageable.find((event) => event.id === form.value?.event_id);
  return selected && !eligible.some((event) => event.id === selected.id)
    ? [selected, ...eligible]
    : eligible;
});
const eventStatus = (event) => {
  if (!event.published_at) return 'draft';
  if (event.cancelled_at) return 'cancelled';
  if (event.archive) return 'archive';
  if (event.ends_at && new Date(event.ends_at) <= new Date()) return 'past';
  return 'upcoming';
};
const scopeOf = (f) => {
  if (f.event_id) return 'Event form';
  if (f.community_id)
    return `${props.lookups.communities.find((c) => c.id === f.community_id)?.name ?? ''} community`;
  if (f.region_id) return props.lookups.regions.find((r) => r.id === f.region_id)?.name ?? 'Region';
  return 'House-wide';
};
const formStatus = (f) => {
  if (!f.published_at) return 'draft';
  const now = Date.now();
  if (f.opens_at && new Date(f.opens_at).getTime() > now) return 'scheduled';
  if (f.closes_at && new Date(f.closes_at).getTime() <= now) return 'closed';
  if (f.is_open === false) return 'closed';
  return f.accepting_responses === false ? 'closed' : 'open';
};
const day = (iso) =>
  iso
    ? new Date(iso).toLocaleString('en-IN', {
        day: 'numeric',
        month: 'short',
        hour: 'numeric',
        minute: '2-digit',
      })
    : '–';
const toLocal = (iso) => {
  if (!iso) return '';
  const d = new Date(iso);
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
};
const fromLocal = (v) => (v ? new Date(v).toISOString() : null);

async function load() {
  loading.value = true;
  error.value = '';
  try {
    const [all, ev, coh] = await Promise.all([
      listForms(),
      listEvents({ view: 'upcoming' }).catch(() => []),
      getAvailableCohorts(),
    ]);
    const drafts = await listEvents({ view: 'drafts' }).catch(() => []);
    const past = await listEvents({ view: 'past' }).catch(() => []);
    forms.value = all;
    events.value = [...ev, ...drafts, ...past];
    cohorts.value = coh;
  } catch (e) {
    error.value = errorText(e);
  } finally {
    loading.value = false;
  }
}
onMounted(load);

function defaultScope() {
  if (isSuperAdmin.value)
    return { scope: 'house', region_id: null, community_id: null, event_id: null };
  if (isRc.value)
    return {
      scope: 'region',
      region_id: auth.dashboard.region_id,
      community_id: null,
      event_id: null,
    };
  return {
    scope: 'community',
    region_id: null,
    community_id: auth.dashboard.community_id,
    event_id: null,
  };
}

function wrapField(f) {
  fieldN += 1;
  return {
    _id: fieldN,
    key: f.key,
    label: f.label,
    type: f.type,
    required: !!f.required,
    prefill: f.prefill || '',
    allow_other: !!f.allow_other,
    optionsText: (f.options || []).join('\n'),
  };
}

function edit(f) {
  formError.value = '';
  if (f) {
    form.value = {
      ...f,
      description: f.description ?? '',
      invite_url: '',
      remove_invite: false,
      audience_cohorts: f.audience_cohorts ?? [],
      form_kind: f.form_kind || 'general',
      group_label: f.group_label || '',
      group_purpose: f.group_purpose || '',
      is_open: f.is_open !== false,
      opens: toLocal(f.opens_at),
      closes: toLocal(f.closes_at),
      scope: f.event_id ? 'event' : f.community_id ? 'community' : f.region_id ? 'region' : 'house',
      fields: (f.fields || []).map(wrapField),
    };
  } else {
    form.value = {
      title: '',
      description: '',
      form_kind: 'general',
      group_label: '',
      group_purpose: '',
      invite_url: '',
      remove_invite: false,
      is_open: true,
      audience_cohorts: [],
      opens: '',
      closes: '',
      fields: [],
      ...defaultScope(),
    };
  }
}

function onScope() {
  if (form.value.scope === 'house') {
    form.value.region_id = form.value.community_id = form.value.event_id = null;
  } else if (form.value.scope === 'region') {
    form.value.community_id = form.value.event_id = null;
    form.value.region_id = isRc.value
      ? auth.dashboard.region_id
      : (form.value.region_id ?? props.lookups.regions[0]?.id);
  } else if (form.value.scope === 'community') {
    form.value.region_id = form.value.event_id = null;
    form.value.community_id = isHead.value
      ? auth.dashboard.community_id
      : (form.value.community_id ?? props.lookups.communities[0]?.id);
  } else {
    form.value.region_id = form.value.community_id = null;
    form.value.event_id ??= events.value[0]?.id ?? null;
  }
}

function addField() {
  form.value.fields.push(
    wrapField({
      key: fieldKeyFromLabel(
        `field ${form.value.fields.length + 1}`,
        form.value.fields.map((x) => x.key)
      ),
      label: '',
      type: 'text',
      required: false,
    })
  );
}
function syncKey(field, i) {
  if (!field.key || /^field_?\d*$/.test(field.key) || field.key === 'field') {
    field.key = fieldKeyFromLabel(
      field.label,
      form.value.fields.filter((_, j) => j !== i).map((x) => x.key)
    );
  }
}
function move(i, dir) {
  const j = i + dir;
  const fields = form.value.fields;
  const tmp = fields[i];
  fields[i] = fields[j];
  fields[j] = tmp;
}

function fieldPayload(field) {
  const row = {
    key: field.key,
    label: field.label,
    type: field.type,
    required: !!field.required,
  };
  if (field.prefill) row.prefill = field.prefill;
  if (field.type === 'select' || field.type === 'multiselect') {
    row.options = field.optionsText
      .split(/\r?\n/)
      .map((s) => s.trim())
      .filter(Boolean);
    if (field.allow_other) row.allow_other = true;
  }
  return row;
}

async function save(mode) {
  busy.value = true;
  formError.value = '';
  try {
    const published_at =
      mode === 'publish'
        ? new Date().toISOString()
        : mode === 'unpublish'
          ? null
          : form.value.published_at || null;
    const payload = {
      id: form.value.id,
      title: form.value.title,
      description: form.value.description || null,
      fields: form.value.fields.map(fieldPayload),
      region_id: form.value.scope === 'region' ? form.value.region_id : null,
      community_id: form.value.scope === 'community' ? form.value.community_id : null,
      event_id: form.value.scope === 'event' ? form.value.event_id : null,
      is_open: !!form.value.is_open,
      published_at,
      opens_at: fromLocal(form.value.opens),
      closes_at: fromLocal(form.value.closes),
      audience_cohorts: form.value.audience_cohorts ?? [],
      form_kind: form.value.form_kind || 'general',
      group_label: form.value.form_kind === 'group' ? form.value.group_label || null : null,
      group_purpose: form.value.form_kind === 'group' ? form.value.group_purpose || null : null,
      archived_at: form.value.archived_at || null,
      source_url: form.value.source_url || null,
    };
    if (form.value.remove_invite) payload.invite_url = null;
    else if (form.value.invite_url) payload.invite_url = form.value.invite_url;
    await saveForm(payload);
    dlg.value?.close();
    notice.value = mode === 'publish' ? 'Published.' : 'Saved.';
    await load();
    emit('changed');
  } catch (e) {
    formError.value = errorText(e);
  } finally {
    busy.value = false;
  }
}

async function archive(f) {
  const archived_at = f.archived_at ? null : new Date().toISOString();
  busy.value = true;
  error.value = '';
  try {
    await saveForm({ ...f, archived_at });
    notice.value = archived_at ? 'Archived. Existing responses remain available.' : 'Restored.';
    await load();
    emit('changed');
  } catch (e) {
    error.value = errorText(e);
  } finally {
    busy.value = false;
  }
}

function answerText(row, field) {
  const captured = (row.field_schema || []).find(
    (item) => JSON.stringify([item.key, item.label || item.key, item.type || '']) === field.identity
  );
  if (!captured) return '–';
  const value = row.answers?.[captured.key];
  if (Array.isArray(value)) return value.join('; ');
  if (value == null || value === '') return '–';
  return String(value);
}

async function openResponses(f) {
  responsesFor.value = f;
  responses.value = [];
  responseFields.value = [];
  respError.value = '';
  try {
    const rows = await exportFormResponses(f.id);
    responses.value = rows;
    responseFields.value = formResponsesToCsv(rows).fields;
  } catch (e) {
    respError.value = errorText(e);
  }
}

function downloadResponses() {
  const csv = formResponsesToCsv(responses.value);
  downloadCsv(`${responsesFor.value.title}-responses.csv`, csv.rows, csv.columns);
}
</script>

<style scoped>
.between {
  justify-content: space-between;
  align-items: center;
}
.fields {
  display: grid;
  gap: 12px;
}
.field {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
}
.acts,
.row-end {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
.row-end {
  justify-content: flex-end;
}
.mono {
  font-family: var(--mono);
  font-size: 13px;
}
@media (max-width: 640px) {
  .field {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
