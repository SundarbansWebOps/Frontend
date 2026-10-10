<!-- The roster: students added before their first Google sign-in. RC adds to their own region;
     Super Admins choose the region, or leave it empty. Name is optional. -->
<template>
  <div class="grid">
    <form class="adm-card adm-form" @submit.prevent="addOne">
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
      </label>
      <label class="adm-field wide">
        <span>Full name</span>
        <input v-model.trim="one.full_name" class="adm-input" maxlength="200" />
        <small>Optional.</small>
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
      <p v-else class="adm-note wide">Added to {{ myRegion }}.</p>
      <p v-if="oneMsg" class="adm-msg wide" :class="oneOk ? 'ok' : 'err'" role="status">
        {{ oneMsg }}
      </p>
      <div class="wide">
        <button type="submit" class="adm-btn mari" :disabled="busy">Add to roster</button>
      </div>
    </form>

    <form class="adm-card adm-form" @submit.prevent="addMany">
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
          <span class="mono">{{ r.email || '(no email)' }}</span> — {{ r.error }}
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

    <form class="adm-card adm-form wide-col" @submit.prevent="importCsv">
      <p class="adm-kicker wide">Upload a CSV</p>
      <label class="adm-field wide">
        <span>File</span>
        <input class="adm-input" type="file" accept=".csv,text/csv" @change="onFile" />
        <small>
          Map the header row to email (required) and optional name, region, phone and gender.
          Duplicate emails in the file are kept once. Existing members are not overwritten.
        </small>
      </label>
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
          <span class="mono">{{ r.email || '(no email)' }}</span> — {{ r.error }}
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

    <div class="wide-col">
      <p class="adm-kicker">Waiting for first sign-in</p>
      <p class="adm-note">
        The roster is the approved list of students who can sign in. After their first sign-in, they
        appear on the Students tab.
      </p>
      <form class="adm-toolbar" @submit.prevent="load()">
        <label class="adm-field grow">
          <span>Search roster</span>
          <input
            v-model="query"
            class="adm-input"
            type="search"
            maxlength="100"
            placeholder="Email or name"
          />
        </label>
        <button type="submit" class="adm-btn">Search</button>
      </form>
      <p v-if="error" class="adm-msg err" role="alert">{{ error }}</p>
      <p v-if="!loading && !error" class="adm-note" role="status">
        Showing {{ entries.length }} of {{ total
        }}{{ searchTerm ? ' matching students' : ' students' }}. Search checks the full roster you
        can access.
      </p>
      <ul v-if="entries.length" class="adm-list">
        <li v-for="e in entries" :key="e.email" class="adm-row">
          <div>
            <b>{{ e.full_name || e.email }}</b>
            <div class="adm-meta">
              <span class="mono">{{ e.email }}</span>
              <span v-if="e.phone" class="mono">{{ e.phone }}</span>
              <span>{{ regionOf(e.region_id) }}</span>
            </div>
          </div>
          <button
            type="button"
            class="adm-btn ghost small"
            :disabled="busy"
            @click="remove(e.email)"
          >
            Remove
          </button>
        </li>
      </ul>
      <p v-else-if="!loading && !error" class="adm-empty">
        {{
          searchTerm
            ? 'No student matches that search. Already signed-in students are on the Students tab.'
            : 'Nobody is waiting. Students you add appear here until they sign in.'
        }}
      </p>
      <button
        v-if="entries.length < total"
        type="button"
        class="adm-btn ghost"
        :disabled="loading || busy"
        @click="load(true)"
      >
        Show more ({{ total - entries.length }} left)
      </button>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue';
import { auth, errorText, isSuperAdmin } from '../../lib/auth.js';
import {
  downloadCsv,
  listRoster,
  parseCsv,
  parseRosterPaste,
  rosterAdd,
  rosterAddMany,
  rosterRemove,
  rowsFromRosterCsv,
  suggestRosterMapping,
} from '../../lib/admin.js';

const props = defineProps({ lookups: { type: Object, required: true } });
const emit = defineEmits(['changed']);

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

let loadId = 0;
async function load(more = false) {
  const id = ++loadId;
  const nextPage = more ? page.value + 1 : 0;
  const term = more ? searchTerm.value : query.value.trim();
  loading.value = true;
  error.value = '';
  if (!more) {
    entries.value = [];
    total.value = 0;
  }
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
onBeforeUnmount(() => loadId++);

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
    await rosterAdd(scoped(one));
    oneOk.value = true;
    oneMsg.value = `${one.email} can now sign in with Google.`;
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
  csvResult.value = null;
  csvMsg.value = '';
  csv.headers = [];
  csv.rows = [];
  if (!file) return;
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
.grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 18px;
  align-items: start;
}
.wide-col {
  grid-column: 1 / -1;
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
@media (max-width: 900px) {
  .grid {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
