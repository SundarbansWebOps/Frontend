<!-- The roster: students added before their first Google sign-in. RC adds to their own region;
     Super Admins choose the region, or leave it empty. Name is optional. -->
<template>
  <div>
    <AdminDialog v-if="adding" title="Add students" wide @close="adding = false">
      <div class="adm-chips add-modes">
        <button
          v-for="item in addModes"
          :key="item.id"
          class="adm-chip"
          :class="{ on: addMode === item.id }"
          @click="addMode = item.id"
        >
          {{ item.label }}
        </button>
      </div>
      <form v-if="addMode === 'one'" class="adm-form" @submit.prevent="addOne">
        <p class="adm-kicker wide">Add a student</p>
        <label class="adm-field wide">
          <span>IITM email</span>
          <input
            v-model.trim="one.email"
            class="adm-input"
            type="email"
            required
            placeholder="21f1000000@ds.study.iitm.ac.in"
          />
          <small>Use an IITM student email from ds, es, mg or ae.study.iitm.ac.in.</small>
        </label>
        <label class="adm-field wide">
          <span>Full name</span>
          <input v-model.trim="one.full_name" class="adm-input" maxlength="200" />
          <small>Leave blank if the full name is unknown.</small>
        </label>
        <label class="adm-field">
          <span>Phone (optional)</span>
          <input
            v-model.trim="one.phone"
            class="adm-input"
            inputmode="tel"
            placeholder="+919876543210"
          />
        </label>
        <label class="adm-field">
          <span>Gender (optional)</span>
          <input v-model.trim="one.gender" class="adm-input" maxlength="50" />
        </label>
        <label v-if="isSuperAdmin" class="adm-field wide">
          <span>Region</span>
          <select v-model="one.region_id" class="adm-input">
            <option :value="null">Not allocated yet</option>
            <option v-for="r in lookups.regions" :key="r.id" :value="r.id">{{ r.name }}</option>
          </select>
        </label>
        <p v-if="isSuperAdmin && !one.region_id" class="adm-note wide">
          Without a region, only Super Admins can see this roster entry.
        </p>
        <p v-if="!isSuperAdmin" class="adm-note wide">Added to {{ myRegion }}.</p>
        <p v-if="oneMsg" class="adm-msg wide" :class="oneOk ? 'ok' : 'err'" role="status">
          {{ oneMsg }}
        </p>
        <div class="wide">
          <button type="submit" class="adm-btn mari" :disabled="busy">Add to roster</button>
        </div>
      </form>

      <form v-if="addMode === 'paste'" class="adm-form" @submit.prevent="addMany">
        <p class="adm-kicker wide">Paste from a sheet</p>
        <label class="adm-field wide">
          <span>One student per line</span>
          <textarea
            v-model="paste"
            class="adm-input tall"
            placeholder="email, full name, phone, region, gender"
          />
          <small>
            Columns: email, full name (optional), phone (optional){{
              isSuperAdmin ? ', region (name or code, optional)' : ''
            }}, gender (optional). Copy straight from Google Sheets; a header row is skipped.
          </small>
        </label>
        <p class="adm-note wide">
          {{ parsed.length }} student{{ parsed.length === 1 ? '' : 's' }} found.
        </p>
        <p v-if="parsed.some((r) => r.region_error)" class="adm-msg err wide" role="alert">
          Fix unknown region labels before adding students.
        </p>
        <ul v-if="bulkResult" class="results wide">
          <li v-for="r in bulkResult.filter((x) => !x.ok)" :key="r.email">
            <span class="mono">{{ r.email || '(no email)' }}</span
            >: {{ r.error }}
          </li>
        </ul>
        <p v-if="bulkMsg" class="adm-msg wide" :class="bulkOk ? 'ok' : 'err'" role="status">
          {{ bulkMsg }}
        </p>
        <div class="wide">
          <button
            type="submit"
            class="adm-btn"
            :disabled="
              busy || !parsed.length || parsed.length > 500 || parsed.some((r) => r.region_error)
            "
          >
            Add {{ parsed.length || '' }} to roster
          </button>
        </div>
      </form>

      <form v-if="addMode === 'csv'" class="adm-form" @submit.prevent="importCsv">
        <p class="adm-kicker wide">Upload a CSV</p>
        <div class="adm-field wide">
          <span>File</span>
          <label
            class="adm-drop"
            :class="{ over: csvDragging }"
            @dragenter.prevent="csvDragging = true"
            @dragover.prevent
            @dragleave="csvDragging = false"
            @drop.prevent="onFileDrop"
          >
            <input
              class="adm-pick-input"
              type="file"
              accept=".csv,text/csv"
              aria-label="Upload roster CSV"
              @change="onFile"
            />
            <LineIcon name="upload" class="adm-drop-icon" />
            <span class="adm-drop-title">{{ csvFile ? 'Replace CSV' : 'Choose a CSV file' }}</span>
            <span class="adm-drop-sub">{{ csvFile || 'No file chosen' }}</span>
          </label>
          <small>
            Map the header row to email (required) and optional name, region, phone and gender.
            Duplicate emails in the file are kept once. Existing members are not overwritten.
          </small>
        </div>
        <template v-if="csv.headers.length">
          <label v-for="field in CSV_FIELDS" :key="field.key" class="adm-field">
            <span>{{ field.label }}</span>
            <select v-model.number="csv.mapping[field.key]" class="adm-input">
              <option :value="-1">Not in this file</option>
              <option v-for="(h, i) in csv.headers" :key="`${h}-${i}`" :value="i">{{ h }}</option>
            </select>
          </label>
          <p class="adm-note wide">
            {{ uniqueCsv.length }} row{{ uniqueCsv.length === 1 ? '' : 's' }} after de-duplicating
            this file. {{ csvRows.filter((r) => r.duplicate).length }} duplicate line{{
              csvRows.filter((r) => r.duplicate).length === 1 ? '' : 's'
            }}
            skipped.
          </p>
          <div v-if="csvPreview.length" class="adm-table-wrap wide">
            <table class="adm-table">
              <thead>
                <tr>
                  <th>Email</th>
                  <th>Name</th>
                  <th>Region</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="r in csvPreview" :key="r.email">
                  <td class="mono">{{ r.email }}</td>
                  <td>{{ r.full_name || '–' }}</td>
                  <td>{{ r.region_error || (r.region_id ? regionOf(r.region_id) : '–') }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </template>
        <p v-if="uniqueCsv.some((r) => r.region_error)" class="adm-msg err wide" role="alert">
          Fix unknown region labels before importing.
        </p>
        <ul v-if="csvResult" class="results wide">
          <li v-for="r in csvResult.filter((x) => !x.ok)" :key="r.email">
            <span class="mono">{{ r.email || '(no email)' }}</span
            >: {{ r.error }}
          </li>
        </ul>
        <p v-if="csvMsg" class="adm-msg wide" :class="csvOk ? 'ok' : 'err'" role="status">
          {{ csvMsg }}
        </p>
        <div class="wide acts">
          <button
            type="submit"
            class="adm-btn mari"
            :disabled="
              busy ||
              !uniqueCsv.length ||
              uniqueCsv.length > 500 ||
              uniqueCsv.some((r) => r.region_error)
            "
          >
            Import {{ uniqueCsv.length || '' }}
          </button>
          <button v-if="csvResult" type="button" class="adm-btn ghost" @click="exportCsvResult">
            Download results
          </button>
        </div>
      </form>
    </AdminDialog>
    <div class="adm-toolbar roster-toolbar">
      <label class="adm-field grow">
        <span>Search</span>
        <input
          v-model="query"
          class="adm-input"
          type="search"
          maxlength="100"
          placeholder="Email or name"
          @input="onSearch"
        />
      </label>
    </div>
    <p v-if="error" class="adm-msg err" role="alert">{{ error }}</p>
    <p v-if="query && query.length < 3" class="adm-note">Type at least 3 characters to search.</p>
    <p
      v-if="!loading && !error && (!query || query.trim().length >= 3)"
      class="adm-note roster-count"
      role="status"
    >
      Showing {{ entries.length }} of {{ total
      }}{{ searchTerm ? ' matching students' : ' students waiting for first sign-in' }}. Search
      checks the full roster you can access.
    </p>
    <div v-if="entries.length" class="adm-card roster-table adm-table-wrap">
      <table class="adm-table">
        <thead>
          <tr>
            <th scope="col">Student</th>
            <th scope="col">Region</th>
            <th scope="col">Added</th>
            <th scope="col">Status</th>
            <th scope="col"><span class="visually-hidden">Actions</span></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="e in entries" :key="e.email">
            <td>
              <div class="roster-name">
                <b>{{ e.full_name || 'Name not set' }}</b>
                <small>{{ e.email }}</small>
                <small v-if="e.phone" class="mono">{{ e.phone }}</small>
              </div>
            </td>
            <td>{{ regionOf(e.region_id) }}</td>
            <td>
              <div class="roster-added">
                <span>{{ dateOf(e.added_at) }}</span>
                <small>by {{ e.added_by === auth.profile?.id ? 'you' : 'an admin' }}</small>
              </div>
            </td>
            <td><span class="adm-badge">Waiting for first sign-in</span></td>
            <td>
              <button
                type="button"
                class="adm-btn danger small"
                :disabled="busy"
                @click="remove(e.email)"
              >
                Remove
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <p v-else-if="!loading && !error" class="adm-empty">
      {{
        searchTerm
          ? 'No student matches that search. Already signed-in students are on the Students tab.'
          : 'Nobody is waiting. Students you add appear here until they sign in.'
      }}
    </p>
    <p v-if="loading" class="adm-note" role="status">Loading roster…</p>
    <div v-if="entries.length < total" class="more">
      <button type="button" class="adm-btn ghost" :disabled="loading || busy" @click="load(true)">
        Show more ({{ total - entries.length }} left)
      </button>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue';
import LineIcon from '../site/LineIcon.vue';
import AdminDialog from './AdminDialog.vue';
import { dateOf } from '../../lib/admin-display.js';
import { auth, errorText, isSuperAdmin } from '../../lib/auth.js';
import {
  downloadCsv,
  listRoster,
  parseCsv,
  parseRosterPaste,
  rosterAddMany,
  rosterRemove,
  rowsFromRosterCsv,
  suggestRosterMapping,
} from '../../lib/admin.js';

const props = defineProps({ lookups: { type: Object, required: true } });
const emit = defineEmits(['changed']);

const adding = ref(false);
const addMode = ref('one');
const addModes = [
  { id: 'one', label: 'One student' },
  { id: 'paste', label: 'Paste from Sheets' },
  { id: 'csv', label: 'Upload CSV' },
];
function create() {
  adding.value = true;
}
defineExpose({ create });
let searchTimer;
function onSearch() {
  clearTimeout(searchTimer);
  const term = query.value.trim();
  if (!term) return load();
  if (term.length < 3) return;
  searchTimer = setTimeout(() => load(), 250);
}

const CSV_FIELDS = [
  { key: 'email', label: 'Email' },
  { key: 'full_name', label: 'Name' },
  { key: 'region', label: 'Region' },
  { key: 'phone', label: 'Phone' },
  { key: 'gender', label: 'Gender' },
];

const regionOf = (id) => props.lookups.regions.find((r) => r.id === id)?.name ?? '–';
const myRegion = computed(() => regionOf(auth.dashboard?.region_id));

const entries = ref([]);
const query = ref('');
const searchTerm = ref('');
const total = ref(0);
const page = ref(0);
const loading = ref(false);
const error = ref('');
const busy = ref(false);

const one = reactive({
  email: '',
  full_name: '',
  phone: '',
  gender: '',
  region_id: null,
});
const oneMsg = ref('');
const oneOk = ref(false);

const paste = ref('');
const parsed = computed(() => parseRosterPaste(paste.value, props.lookups.regions));
const bulkResult = ref(null);
const bulkMsg = ref('');
const bulkOk = ref(false);

const csv = reactive({
  headers: [],
  rows: [],
  mapping: { email: -1, full_name: -1, phone: -1, region: -1, gender: -1 },
});
const csvRows = computed(() => rowsFromRosterCsv(csv.rows, csv.mapping, props.lookups.regions));
const uniqueCsv = computed(() => {
  const seen = new Set();
  return csvRows.value.filter((r) => {
    if (r.duplicate || seen.has(r.email)) return false;
    seen.add(r.email);
    return true;
  });
});
const csvPreview = computed(() => uniqueCsv.value.slice(0, 8));
const csvResult = ref(null);
const csvMsg = ref('');
const csvOk = ref(false);
const csvFile = ref('');
const csvDragging = ref(false);

let loadId = 0;
async function load(more = false) {
  const id = ++loadId;
  const nextPage = more ? page.value + 1 : 0;
  const term = more ? searchTerm.value : query.value.trim();
  loading.value = true;
  error.value = '';
  try {
    const { data, count } = await listRoster({ query: term, page: nextPage });
    if (id !== loadId) return;
    entries.value = more ? entries.value.concat(data) : data;
    total.value = count;
    page.value = nextPage;
    searchTerm.value = term;
  } catch (e) {
    if (id !== loadId) return;
    error.value = errorText(e);
  } finally {
    if (id === loadId) loading.value = false;
  }
}
onMounted(load);
onBeforeUnmount(() => {
  loadId++;
  clearTimeout(searchTimer);
});

function scoped(row) {
  return { ...row, region_id: isSuperAdmin.value ? row.region_id : null };
}

function summarize(result) {
  const rows = Array.isArray(result) ? result : [];
  const n = (cat) =>
    rows.filter((r) => r.category === cat || (cat === 'added' && r.ok && !r.category)).length;
  const added = n('added');
  const processed = n('processed');
  const existing = n('existing');
  const invalid = n('invalid') || rows.filter((r) => !r.ok && r.category !== 'conflict').length;
  const conflict = n('conflict');
  return { rows, added, existing, processed, invalid, conflict };
}

function summaryText(s) {
  if (!isSuperAdmin.value)
    return `${s.processed} processed, ${s.invalid} invalid. Existing identities are preserved.`;
  return `${s.added} added, ${s.existing} already present, ${s.invalid} invalid, ${s.conflict} conflicting.`;
}

async function addOne() {
  busy.value = true;
  oneMsg.value = '';
  try {
    const s = summarize(await rosterAddMany([scoped(one)]));
    oneOk.value = s.invalid + s.conflict === 0;
    oneMsg.value = summaryText(s);
    if (!oneOk.value) return;
    Object.assign(one, { email: '', full_name: '', phone: '', gender: '' });
    await load();
    emit('changed');
  } catch (e) {
    oneOk.value = false;
    oneMsg.value = errorText(e);
  } finally {
    busy.value = false;
  }
}

async function addMany() {
  busy.value = true;
  bulkMsg.value = '';
  bulkResult.value = null;
  try {
    const result = await rosterAddMany(parsed.value.map(scoped));
    const s = summarize(result);
    bulkResult.value = s.rows;
    bulkOk.value = s.invalid + s.conflict === 0;
    bulkMsg.value = summaryText(s);
    if (bulkOk.value) paste.value = '';
    await load();
    emit('changed');
  } catch (e) {
    bulkOk.value = false;
    bulkMsg.value = errorText(e);
  } finally {
    busy.value = false;
  }
}

function onFile(ev) {
  const file = ev.target.files?.[0];
  ev.target.value = '';
  readRoster(file);
}
function onFileDrop(ev) {
  csvDragging.value = false;
  readRoster(ev.dataTransfer?.files?.[0]);
}
function readRoster(file) {
  csvResult.value = null;
  csvMsg.value = '';
  csv.headers = [];
  csv.rows = [];
  csvFile.value = '';
  if (!file) return;
  if (!/\.csv$/i.test(file.name) && file.type !== 'text/csv') {
    csvOk.value = false;
    csvMsg.value = 'Use a CSV file.';
    return;
  }
  csvFile.value = file.name;
  const reader = new FileReader();
  reader.onload = () => {
    const rows = parseCsv(String(reader.result || ''));
    csv.rows = rows;
    csv.headers = rows[0] ?? [];
    Object.assign(csv.mapping, suggestRosterMapping(csv.headers));
  };
  reader.onerror = () => {
    csvMsg.value = 'The file could not be read.';
    csvOk.value = false;
  };
  reader.readAsText(file);
}

async function importCsv() {
  if (csv.mapping.email < 0) {
    csvOk.value = false;
    csvMsg.value = 'Map a column to email before importing.';
    return;
  }
  busy.value = true;
  csvMsg.value = '';
  csvResult.value = null;
  try {
    const result = await rosterAddMany(uniqueCsv.value.map(scoped));
    const s = summarize(result);
    csvResult.value = s.rows;
    csvOk.value = s.invalid + s.conflict === 0;
    csvMsg.value = summaryText(s);
    await load();
    emit('changed');
  } catch (e) {
    csvOk.value = false;
    csvMsg.value = errorText(e);
  } finally {
    busy.value = false;
  }
}

function exportCsvResult() {
  downloadCsv('roster-import-results.csv', csvResult.value || [], [
    'email',
    'ok',
    'category',
    'error',
  ]);
}

async function remove(email) {
  if (
    !confirm(
      `Remove ${email} from the roster? They will no longer be able to sign in for the first time.`
    )
  )
    return;
  busy.value = true;
  try {
    await rosterRemove(email);
    await load();
    emit('changed');
  } catch (e) {
    error.value = errorText(e);
  } finally {
    busy.value = false;
  }
}
</script>

<style scoped>
.add-modes {
  margin-bottom: 20px;
}
.roster-toolbar {
  align-items: end;
  max-width: 640px;
}
.roster-toolbar .adm-field {
  flex: 1 1 280px;
}
.roster-table {
  padding: 0;
}
.roster-name,
.roster-added {
  display: grid;
  gap: 2px;
  min-width: 180px;
}
.roster-name b {
  font-size: 14px;
}
.roster-name small,
.roster-added small {
  color: var(--ink-3);
  font-size: 12px;
  overflow-wrap: anywhere;
}
.roster-count {
  margin: 0 0 10px;
}
.more {
  display: flex;
  justify-content: center;
  margin-top: 14px;
}
.tall {
  min-height: 150px;
  font-family: var(--mono);
  font-size: 13px;
}
.results {
  margin: 0;
  padding-left: 18px;
  font-size: 13px;
  color: var(--verm);
}
.acts {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
</style>
