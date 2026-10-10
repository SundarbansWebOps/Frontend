<!-- Events in the organizer's scope. RCs own their region; Heads/Co-Heads own their community;
     Super Admins manage house, any region, and any community. Save keeps a draft; Publish sets
     published_at. Attendance and certificates are reviewed on a saved event. -->
<template>
  <div>
    <div class="adm-toolbar between">
      <div class="adm-chips" role="group" aria-label="Which events">
        <button
          type="button"
          class="adm-chip"
          :class="{ on: view === 'upcoming' }"
          @click="show('upcoming')"
        >
          Upcoming
        </button>
        <button
          type="button"
          class="adm-chip"
          :class="{ on: view === 'drafts' }"
          @click="show('drafts')"
        >
          Drafts
        </button>
        <button
          type="button"
          class="adm-chip"
          :class="{ on: view === 'past' }"
          @click="show('past')"
        >
          Past
        </button>
      </div>
      <button type="button" class="adm-btn mari" @click="edit()">New event</button>
    </div>

    <p v-if="error" class="adm-msg err" role="alert">{{ error }}</p>
    <p v-if="notice" class="adm-msg ok" role="status">{{ notice }}</p>

    <ul v-if="events.length" class="adm-list">
      <li v-for="e in events" :key="e.id" class="adm-row">
        <div>
          <b>{{ e.name }}</b>
          <div class="adm-meta">
            <span class="mono">{{ when(e) }}</span>
            <span>{{ scopeOf(e) }}</span>
            <span v-if="!e.published_at" class="adm-badge">draft</span>
            <span v-else-if="e.archive" class="adm-badge">archive</span>
            <span v-else-if="e.cancelled_at" class="adm-badge verm">cancelled</span>
            <span v-else-if="isLive(e)" class="adm-badge mari">live now</span>
            <span v-if="e.certificates_released_at" class="adm-badge mari">certificates</span>
          </div>
        </div>
        <div class="adm-chips">
          <template v-if="canManageEvent(e)">
            <button type="button" class="adm-btn ghost small" @click="edit(e)">Edit</button>
            <button type="button" class="adm-btn ghost small" @click="openOps(e)">
              Attendance
            </button>
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
          </template>
        </div>
      </li>
    </ul>
    <p v-else-if="!loading" class="adm-empty">
      {{
        view === 'drafts'
          ? 'No drafts.'
          : view === 'past'
            ? 'No past events yet.'
            : 'Nothing planned. Add the next event.'
      }}
    </p>

    <AdminDialog
      v-if="form"
      ref="dlg"
      wide
      :title="form.id ? 'Edit event' : 'New event'"
      @close="form = null"
    >
      <form class="adm-form" @submit.prevent="save(false)">
        <label class="adm-field wide">
          <span>Name</span>
          <input v-model.trim="form.name" class="adm-input" required maxlength="200" />
        </label>
        <label v-if="isSuperAdmin" class="adm-field">
          <span>Scope</span>
          <select v-model="form.scope" class="adm-input" @change="onScope">
            <option value="house">House (every region)</option>
            <option value="region">A region</option>
            <option value="community">A community</option>
          </select>
        </label>
        <label v-if="isSuperAdmin && form.scope === 'region'" class="adm-field">
          <span>Region</span>
          <select v-model="form.region_id" class="adm-input">
            <option v-for="r in lookups.regions" :key="r.id" :value="r.id">{{ r.name }}</option>
          </select>
        </label>
        <label v-if="isSuperAdmin && form.scope === 'community'" class="adm-field">
          <span>Community</span>
          <select v-model="form.community_id" class="adm-input">
            <option v-for="c in lookups.communities" :key="c.id" :value="c.id">{{ c.name }}</option>
          </select>
        </label>
        <p v-else-if="!isSuperAdmin" class="adm-note wide">{{ lockedScope }}</p>
        <label class="adm-field">
          <span>Starts</span>
          <input
            v-model="form.starts"
            class="adm-input"
            type="datetime-local"
            :required="!form.archive"
          />
        </label>
        <label class="adm-field">
          <span>Ends</span>
          <input
            v-model="form.ends"
            class="adm-input"
            type="datetime-local"
            :required="!form.archive"
          />
        </label>
        <label v-if="isSuperAdmin" class="adm-field wide">
          <span>
            <input v-model="form.archive" type="checkbox" />
            Archive (dateless historical record)
          </span>
        </label>
        <div class="wide">
          <p class="adm-kicker">Audience</p>
          <AdminCohortSelect v-if="cohorts" v-model="form.audience_cohorts" :cohorts="cohorts" />
        </div>
        <label class="adm-field wide">
          <span>Description</span>
          <textarea v-model.trim="form.description" class="adm-input" maxlength="4000" />
        </label>
        <label class="adm-field">
          <span>Attendance</span>
          <select
            v-model="form.attendance_mode"
            class="adm-input"
            :disabled="!!form.certificates_released_at"
          >
            <option value="meet">Google Meet (≥20 minutes)</option>
            <option value="reviewed">Reviewed list</option>
          </select>
        </label>
        <label class="adm-field wide">
          <span>Signed template URL</span>
          <input
            v-model.trim="form.certificate_template_url"
            class="adm-input"
            type="url"
            placeholder="https://…"
            :disabled="!!form.certificates_released_at"
          />
          <small>HTTPS only. A blank signed template, not a filled certificate.</small>
        </label>
        <label v-if="form.id && !form.certificates_released_at" class="adm-field wide">
          <span>Or upload a template (PNG, JPEG or WebP, 10 MB)</span>
          <input
            class="adm-input"
            type="file"
            accept="image/png,image/jpeg,image/webp"
            @change="onTemplate"
          />
        </label>
        <label class="adm-field wide">
          <span>Members’ meeting link (optional)</span>
          <input
            v-model.trim="form.gmail_link"
            class="adm-input"
            type="url"
            placeholder="https://meet.google.com/…"
          />
        </label>
        <template v-if="isSuperAdmin && form.archive">
          <label class="adm-field">
            <span>Display date</span>
            <input v-model.trim="form.display_date" class="adm-input" maxlength="200" />
          </label>
          <label class="adm-field">
            <span>Location</span>
            <input v-model.trim="form.location" class="adm-input" maxlength="500" />
          </label>
        </template>
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
      v-if="ops"
      ref="opsDlg"
      wide
      title="Attendance and certificates"
      @close="ops = null"
    >
      <div class="adm-stack">
        <p class="adm-note">
          {{ ops.name }} · {{ ops.attendance_mode === 'meet' ? 'Google Meet' : 'Reviewed' }}
        </p>
        <label class="adm-field">
          <span>Attendance CSV</span>
          <input class="adm-input" type="file" accept=".csv,text/csv" @change="onAttendFile" />
          <small>
            Google Meet headers: First name, Last name, Email, Duration. Masked emails stay
            unresolved. Save only after you have reviewed the lists.
          </small>
        </label>
        <label class="adm-field">
          <span>Import behavior</span>
          <select v-model="attendanceMode" class="adm-input">
            <option value="merge">Merge; keep omitted rows</option>
            <option value="replace">Replace one named source</option>
          </select>
        </label>
        <label class="adm-field">
          <span>Source name</span>
          <input v-model.trim="attendanceSource" class="adm-input" maxlength="120" />
          <small>Replace affects only rows previously imported under this exact name.</small>
        </label>
        <template v-if="attend.headers.length">
          <label class="adm-field">
            <span>Email column</span>
            <select v-model.number="attend.mapping.email" class="adm-input">
              <option :value="-1">Not in this file</option>
              <option v-for="(h, i) in attend.headers" :key="`${h}-${i}`" :value="i">
                {{ h }}
              </option>
            </select>
          </label>
          <label v-if="ops.attendance_mode === 'meet'" class="adm-field">
            <span>Duration column</span>
            <select v-model.number="attend.mapping.duration" class="adm-input">
              <option :value="-1">Not in this file</option>
              <option v-for="(h, i) in attend.headers" :key="`d-${h}-${i}`" :value="i">
                {{ h }}
              </option>
            </select>
          </label>
        </template>
        <p v-if="preview" class="adm-note">
          {{ preview.registered.length }} registered and attended ·
          {{ preview.unregistered.length }} unregistered · {{ preview.absent.length }} registered
          absent · {{ preview.unresolved.length }} unresolved
        </p>
        <p v-if="preview && attendanceMode === 'replace'" class="adm-note">
          Preview: {{ replaceDelta }} omitted row{{ replaceDelta === 1 ? '' : 's' }} will lose this
          source's ownership. Rows owned by another source remain.
        </p>
        <div v-if="preview" class="adm-table-wrap">
          <table class="adm-table">
            <thead>
              <tr>
                <th>Category</th>
                <th>Email</th>
                <th>Duration</th>
                <th v-if="ops.attendance_mode === 'reviewed'">Eligible</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in previewRows" :key="row.email + row.cat + (row.source_row_id || '')">
                <td>{{ row.cat }}</td>
                <td class="mono">{{ row.email || '–' }}</td>
                <td class="mono">{{ row.duration_seconds ?? '–' }}</td>
                <td v-if="ops.attendance_mode === 'reviewed'">
                  <input
                    type="checkbox"
                    :checked="row.eligible"
                    :disabled="row.cat !== 'registered'"
                    @change="markEligible(row.email, $event.target.checked)"
                  />
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <p v-if="opsError" class="adm-msg err" role="alert">{{ opsError }}</p>
        <p v-if="opsNotice" class="adm-msg ok" role="status">{{ opsNotice }}</p>
        <div class="row-end">
          <button
            type="button"
            class="adm-btn ghost"
            :disabled="busy || !preview"
            @click="saveAttendance"
          >
            Save attendance
          </button>
          <button type="button" class="adm-btn ghost" :disabled="busy" @click="downloadRecords">
            Download records
          </button>
          <button type="button" class="adm-btn mari" :disabled="busy" @click="release">
            Release certificates
          </button>
        </div>
      </div>
    </AdminDialog>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import AdminDialog from './AdminDialog.vue';
import AdminCohortSelect from './AdminCohortSelect.vue';
import { auth, errorText, isRc, isSuperAdmin } from '../../lib/auth.js';
import {
  applyReviewedEligibility,
  canManageEvent,
  deleteEvent,
  downloadCsv,
  exportEventRecords,
  flattenExportRows,
  getAvailableCohorts,
  importAttendance,
  isMaskedEmail,
  listEventRegistrations,
  listAttendance,
  listEvents,
  normalizeEmail,
  parseCsv,
  previewAttendance,
  releaseCertificates,
  saveEvent,
  setEventCancelled,
  suggestMeetMapping,
  uploadCertificateTemplate,
} from '../../lib/admin.js';

const props = defineProps({ lookups: { type: Object, required: true } });
const emit = defineEmits(['changed']);

const view = ref('upcoming');
const events = ref([]);
const loading = ref(false);
const busy = ref(false);
const error = ref('');
const notice = ref('');
const form = ref(null);
const formError = ref('');
const dlg = ref(null);
const opsDlg = ref(null);
const cohorts = ref(null);
const ops = ref(null);
const opsError = ref('');
const opsNotice = ref('');
const preview = ref(null);
const existingAttendance = ref([]);
const attendanceMode = ref('merge');
const attendanceSource = ref('attendance-sheet-1');
const replaceDelta = computed(() => {
  const sourceId = attendanceSource.value.trim();
  const keys = new Set(
    (preview.value?.importRows ?? []).map((row) =>
      row.email && !isMaskedEmail(normalizeEmail(row.email))
        ? normalizeEmail(row.email)
        : `unresolved:${sourceId}:${row.source_row_id}`
    )
  );
  return existingAttendance.value.filter(
    (row) =>
      (row.import_sources ?? [row.import_source]).includes(sourceId) && !keys.has(row.row_key)
  ).length;
});
const attend = reactive({
  headers: [],
  rows: [],
  mapping: { email: -1, duration: -1, first: -1, last: -1 },
});

const lockedScope = computed(() => {
  if (isRc.value) {
    const name = props.lookups.regions.find((r) => r.id === auth.dashboard?.region_id)?.name;
    return `This event belongs to ${name || 'your region'}.`;
  }
  const name = props.lookups.communities.find((c) => c.id === auth.dashboard?.community_id)?.name;
  return `This event belongs to the ${name || 'your'} community.`;
});

const scopeOf = (e) => {
  if (e.community_id)
    return `${props.lookups.communities.find((c) => c.id === e.community_id)?.name ?? ''} community`;
  if (e.region_id) return props.lookups.regions.find((r) => r.id === e.region_id)?.name ?? 'Region';
  return 'House-wide';
};
const isLive = (e) =>
  e.starts_at &&
  e.ends_at &&
  new Date(e.starts_at) <= new Date() &&
  new Date() < new Date(e.ends_at);
const fmt = (iso) =>
  iso
    ? new Date(iso).toLocaleString('en-IN', {
        day: 'numeric',
        month: 'short',
        hour: 'numeric',
        minute: '2-digit',
      })
    : '–';
const when = (e) =>
  e.archive && e.display_date ? e.display_date : `${fmt(e.starts_at)} – ${fmt(e.ends_at)}`;
const toLocal = (iso) => {
  if (!iso) return '';
  const d = new Date(iso);
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
};
const fromLocal = (v) => (v ? new Date(v).toISOString() : null);

const previewRows = computed(() => {
  if (!preview.value) return [];
  return [
    ...preview.value.registered.map((r) => ({ ...r, cat: 'registered' })),
    ...preview.value.unregistered.map((r) => ({ ...r, cat: 'unregistered' })),
    ...preview.value.absent.map((r) => ({ ...r, cat: 'absent' })),
    ...preview.value.unresolved.map((r) => ({ ...r, cat: 'unresolved' })),
  ];
});

async function load() {
  loading.value = true;
  error.value = '';
  try {
    events.value = await listEvents({ view: view.value });
  } catch (e) {
    error.value = errorText(e);
  } finally {
    loading.value = false;
  }
}
onMounted(async () => {
  try {
    cohorts.value = await getAvailableCohorts();
  } catch (e) {
    error.value = errorText(e);
  }
  load();
});

function show(v) {
  view.value = v;
  load();
}

function defaultScope() {
  if (isSuperAdmin.value) return { scope: 'house', region_id: null, community_id: null };
  if (isRc.value)
    return { scope: 'region', region_id: auth.dashboard.region_id, community_id: null };
  return { scope: 'community', region_id: null, community_id: auth.dashboard.community_id };
}

function edit(e) {
  formError.value = '';
  const start = new Date(Date.now() + 864e5);
  start.setMinutes(0, 0, 0);
  if (e) {
    form.value = {
      ...e,
      starts: toLocal(e.starts_at),
      ends: toLocal(e.ends_at),
      description: e.description ?? '',
      audience_cohorts: e.audience_cohorts ?? [],
      attendance_mode: e.attendance_mode || 'meet',
      certificate_template_url: e.certificate_template_url ?? '',
      scope: e.community_id ? 'community' : e.region_id ? 'region' : 'house',
      archive: !!e.archive,
    };
  } else {
    form.value = {
      name: '',
      description: '',
      starts: toLocal(start),
      ends: toLocal(new Date(start.getTime() + 36e5)),
      audience_cohorts: [],
      attendance_mode: 'meet',
      certificate_template_url: '',
      archive: false,
      gmail_link: '',
      registration_link: '',
      ...defaultScope(),
    };
  }
}

function onScope() {
  if (form.value.scope === 'house') {
    form.value.region_id = null;
    form.value.community_id = null;
  } else if (form.value.scope === 'region') {
    form.value.community_id = null;
    form.value.region_id ??= props.lookups.regions[0]?.id;
  } else {
    form.value.region_id = null;
    form.value.community_id ??= props.lookups.communities[0]?.id;
  }
}

function payload() {
  const scope = isSuperAdmin.value ? form.value : { ...form.value, ...defaultScope() };
  return {
    ...scope,
    starts_at: fromLocal(form.value.starts),
    ends_at: fromLocal(form.value.ends),
    region_id: scope.scope === 'region' ? scope.region_id : null,
    community_id: scope.scope === 'community' ? scope.community_id : null,
  };
}

function friendly(e) {
  const m = e?.message ?? '';
  if (/events_period/.test(m)) return 'The event has to end after it starts.';
  if (/_https/.test(m)) return 'Links must start with https://';
  if (/events_name_length/.test(m)) return 'Give the event a name (up to 200 characters).';
  if (/cohort/.test(m))
    return 'Choose only available cohorts, including at most the next future one.';
  if (e?.code === '42501') return 'You can’t change this event.';
  return errorText(e);
}

async function save(mode) {
  busy.value = true;
  formError.value = '';
  try {
    await saveEvent(payload(), {
      publish: mode === 'publish',
      unpublish: mode === 'unpublish',
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

async function onTemplate(ev) {
  const file = ev.target.files?.[0];
  if (!file || !form.value?.id) return;
  formError.value = '';
  busy.value = true;
  try {
    form.value.certificate_template_url = await uploadCertificateTemplate(form.value.id, file);
  } catch (e) {
    formError.value = errorText(e);
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

async function openOps(e) {
  ops.value = e;
  opsError.value = '';
  opsNotice.value = '';
  preview.value = null;
  attend.headers = [];
  attend.rows = [];
  try {
    existingAttendance.value = await listAttendance(e.id);
  } catch (error) {
    existingAttendance.value = [];
    opsError.value = errorText(error);
  }
}

async function onAttendFile(ev) {
  const file = ev.target.files?.[0];
  preview.value = null;
  if (!file || !ops.value) return;
  opsError.value = '';
  const reader = new FileReader();
  reader.onload = async () => {
    try {
      const rows = parseCsv(String(reader.result || ''));
      attend.rows = rows;
      attend.headers = rows[0] ?? [];
      attendanceSource.value =
        file.name.replace(/\.[^.]+$/, '').slice(0, 120) || 'attendance-upload';
      Object.assign(attend.mapping, suggestMeetMapping(attend.headers));
      const registrations = await listEventRegistrations(ops.value.id);
      preview.value = previewAttendance({
        rows,
        mapping: attend.mapping,
        registrations,
        mode: ops.value.attendance_mode,
      });
    } catch (e) {
      opsError.value = errorText(e);
    }
  };
  reader.readAsText(file);
}

function markEligible(email, eligible) {
  if (!preview.value) return;
  applyReviewedEligibility(preview.value, email, eligible);
}

async function saveAttendance() {
  if (!preview.value || !ops.value) return;
  if (!attendanceSource.value.trim()) {
    opsError.value = 'Enter a source name before importing.';
    return;
  }
  if (
    attendanceMode.value === 'replace' &&
    !confirm(
      `Replace “${attendanceSource.value.trim()}” for this event? ${replaceDelta.value} omitted rows will lose this source's ownership. Rows owned by other sources remain.`
    )
  )
    return;
  busy.value = true;
  opsError.value = '';
  opsNotice.value = '';
  try {
    const result = await importAttendance(ops.value.id, preview.value.importRows, {
      mode: attendanceMode.value,
      sourceId: attendanceSource.value.trim(),
    });
    opsNotice.value = `Saved. ${result.matched ?? 0} registered, ${result.unregistered ?? 0} unregistered, ${result.unresolved ?? 0} unresolved.`;
  } catch (e) {
    opsError.value = errorText(e);
  } finally {
    busy.value = false;
  }
}

async function downloadRecords() {
  if (!ops.value) return;
  busy.value = true;
  opsError.value = '';
  try {
    const data = await exportEventRecords(ops.value.id);
    downloadCsv(`${ops.value.name}-records.csv`, flattenExportRows(data));
  } catch (e) {
    opsError.value = errorText(e);
  } finally {
    busy.value = false;
  }
}

async function release() {
  if (!ops.value) return;
  busy.value = true;
  opsError.value = '';
  opsNotice.value = '';
  try {
    const result = await releaseCertificates(ops.value.id);
    opsNotice.value = `Released ${result.issued ?? 0} certificate${result.issued === 1 ? '' : 's'}. ${result.pending_names ?? 0} still need to confirm a certificate name.`;
    emit('changed');
  } catch (e) {
    opsError.value = errorText(e);
  } finally {
    busy.value = false;
  }
}
</script>

<style scoped>
.between {
  justify-content: space-between;
  align-items: center;
}
.row-end {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 8px;
}
</style>
