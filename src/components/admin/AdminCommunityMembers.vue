<!-- Members-only communities (today: Girls). Membership is an email list. A Super Admin adds
     emails (pasted or from a CSV with an Email Address column) and removes them; the community's
     Head and Co-Head can only read the list. The database enforces both rules. -->
<template>
  <div>
    <AdminDialog
      v-if="adding"
      :title="`Add ${community?.name ?? ''} members`"
      wide
      @close="adding = false"
    >
      <div class="adm-chips add-modes">
        <button
          v-for="item in addModes"
          :key="item.id"
          type="button"
          class="adm-chip"
          :class="{ on: addMode === item.id }"
          @click="addMode = item.id"
        >
          {{ item.label }}
        </button>
      </div>
      <form v-if="addMode === 'paste'" class="adm-form" @submit.prevent="add(pasted)">
        <label class="adm-field wide">
          <span>Emails</span>
          <textarea
            v-model="paste"
            class="adm-input tall"
            placeholder="21f1000000@ds.study.iitm.ac.in"
          />
          <small>
            One per line, or separated by commas or spaces. Copy a column straight from Sheets;
            words without an @ are skipped.
          </small>
        </label>
        <p class="adm-note wide" role="status">
          {{ pasted.length }} email{{ pasted.length === 1 ? '' : 's' }} found.
        </p>
        <div class="wide adm-actions">
          <button
            type="submit"
            class="adm-btn mari"
            :disabled="busy || !pasted.length || pasted.length > COMMUNITY_ADD_MAX"
          >
            Add {{ pasted.length || '' }}
          </button>
        </div>
      </form>
      <form v-else class="adm-form" @submit.prevent="add(csvEmails)">
        <div class="adm-field wide">
          <span>File</span>
          <label
            class="adm-drop"
            :class="{ over: dragging }"
            @dragenter.prevent="dragging = true"
            @dragover.prevent
            @dragleave="dragging = false"
            @drop.prevent="onDrop"
          >
            <input
              class="adm-pick-input"
              type="file"
              accept=".csv,text/csv"
              aria-label="Upload members CSV"
              @change="onFile"
            />
            <LineIcon name="upload" class="adm-drop-icon" />
            <span class="adm-drop-title">{{ csvFile ? 'Replace CSV' : 'Choose a CSV file' }}</span>
            <span class="adm-drop-sub">{{ csvFile || 'No file chosen' }}</span>
          </label>
          <small>
            Needs an Email Address column, like a Google Form export. Other columns are ignored.
          </small>
        </div>
        <p v-if="csvError" class="adm-msg err wide" role="alert">{{ csvError }}</p>
        <p v-else-if="csvFile" class="adm-note wide" role="status">
          {{ csvEmails.length }} email{{ csvEmails.length === 1 ? '' : 's' }} found.
        </p>
        <div class="wide adm-actions">
          <button
            type="submit"
            class="adm-btn mari"
            :disabled="busy || !csvEmails.length || csvEmails.length > COMMUNITY_ADD_MAX"
          >
            Add {{ csvEmails.length || '' }}
          </button>
        </div>
      </form>
      <p v-if="tooMany" class="adm-msg err" role="alert">
        Add at most {{ COMMUNITY_ADD_MAX }} emails at a time.
      </p>
      <p v-if="addError" class="adm-msg err" role="alert">{{ addError }}</p>
      <section v-if="result" class="summary" aria-labelledby="add-summary-heading">
        <h3 id="add-summary-heading" class="adm-kicker">Result</h3>
        <p class="adm-msg ok" role="status">
          {{ result.added ?? 0 }} added, {{ result.already ?? 0 }} already on the list.
        </p>
        <div v-if="result.not_in_house?.length" class="summary-list">
          <p>
            <b>{{ result.not_in_house.length }} not found in the house</b> (no account and not on
            the roster)
          </p>
          <ul>
            <li v-for="email in result.not_in_house" :key="email" class="mono">{{ email }}</li>
          </ul>
        </div>
        <div v-if="result.invalid?.length" class="summary-list err">
          <p>
            <b>{{ result.invalid.length }} not valid</b>
          </p>
          <ul>
            <li v-for="email in result.invalid" :key="email" class="mono">{{ email }}</li>
          </ul>
        </div>
      </section>
    </AdminDialog>

    <p v-if="!communities.length" class="adm-empty">
      No members-only community exists yet. Mark a community members-only to manage its list here.
    </p>
    <template v-else>
      <div class="adm-toolbar members-toolbar">
        <label v-if="communities.length > 1" class="adm-field">
          <span>Community</span>
          <select v-model="communityId" class="adm-input" @change="load">
            <option v-for="c in communities" :key="c.id" :value="c.id">{{ c.name }}</option>
          </select>
        </label>
        <label class="adm-field grow">
          <span>Search</span>
          <input
            v-model="query"
            class="adm-input"
            type="search"
            maxlength="100"
            placeholder="Email, name or roll number"
          />
        </label>
        <button v-if="isSuperAdmin" type="button" class="adm-btn mari" @click="create">
          Add members
        </button>
      </div>
      <p v-if="!isSuperAdmin" class="adm-note read-only">
        Only a Super Admin can add or remove {{ community?.name }} members.
      </p>
      <div
        v-if="entries.length"
        class="adm-chips status-filter"
        role="group"
        aria-label="Filter by status"
      >
        <button
          v-for="s in STATUSES"
          :key="s.id"
          type="button"
          class="adm-chip"
          :class="{ on: status === s.id }"
          :aria-pressed="status === s.id"
          @click="status = s.id"
        >
          {{ s.label }} <span class="mono">{{ counts[s.id] }}</span>
        </button>
      </div>
      <p v-if="error" class="adm-msg err" role="alert">
        {{ error }} <button type="button" class="retry" @click="load">Try again</button>
      </p>
      <p v-if="!loading && !error && entries.length" class="adm-note members-count" role="status">
        Showing {{ shown.length }} of {{ filtered.length }}
        {{ filtered.length === entries.length ? 'members' : 'matching members' }}.
      </p>
      <div v-if="shown.length" class="adm-card members-table adm-table-wrap">
        <table class="adm-table stack">
          <thead>
            <tr>
              <th scope="col">Member</th>
              <th scope="col">Cohort</th>
              <th scope="col">Region</th>
              <th scope="col">Added</th>
              <th scope="col">Status</th>
              <th v-if="isSuperAdmin" scope="col">
                <span class="visually-hidden">Actions</span>
              </th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="e in shown" :key="e.email">
              <td>
                <div class="member-name">
                  <b>{{ nameOf(e) }}</b>
                  <small>{{ e.email }}</small>
                  <small v-if="e.member?.member_code" class="mono">{{
                    e.member.member_code
                  }}</small>
                </div>
              </td>
              <td data-label="Cohort" class="mono">{{ e.member?.cohort || '–' }}</td>
              <td data-label="Region">{{ regionOf(e.member?.region_id) }}</td>
              <td data-label="Added">{{ dateOf(e.added_at) }}</td>
              <td data-label="Status">
                <span class="badges">
                  <span class="adm-badge" :class="statusOf(e).tone">{{ statusOf(e).label }}</span>
                  <span
                    v-if="e.member && e.member.account_status !== 'active'"
                    class="adm-badge verm"
                    >{{ e.member.account_status }}</span
                  >
                </span>
              </td>
              <td v-if="isSuperAdmin">
                <button
                  type="button"
                  class="adm-btn danger small"
                  :disabled="busy"
                  :aria-label="`Remove ${e.email}`"
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
          entries.length
            ? 'No member matches that search.'
            : isSuperAdmin
              ? `No one is on the ${community?.name} list yet. Add members to start it.`
              : `No one is on the ${community?.name} list yet. A Super Admin adds members.`
        }}
      </p>
      <p v-if="loading" class="adm-note" role="status">Loading members…</p>
      <div v-if="shown.length < filtered.length" class="more">
        <button type="button" class="adm-btn ghost" @click="limit += STEP">
          Show more ({{ filtered.length - shown.length }} left)
        </button>
      </div>
    </template>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import LineIcon from '../site/LineIcon.vue';
import AdminDialog from './AdminDialog.vue';
import { askConfirm } from '../../lib/admin-confirm.js';
import { dateOf } from '../../lib/admin-display.js';
import { auth, errorText, isSuperAdmin } from '../../lib/auth.js';
import {
  COMMUNITY_ADD_MAX,
  addCommunityMembers,
  emailsFromCsv,
  emailsFromText,
  listCommunityMembers,
  parseCsv,
  removeCommunityMember,
} from '../../lib/admin.js';

const props = defineProps({ lookups: { type: Object, required: true } });

const STEP = 100;
const STATUSES = [
  { id: 'all', label: 'All' },
  { id: 'signed_in', label: 'Signed in' },
  { id: 'waiting', label: 'Not signed in yet' },
  { id: 'outside', label: 'Not in house roster' },
];
const addModes = [
  { id: 'paste', label: 'Paste emails' },
  { id: 'csv', label: 'Upload CSV' },
];

// A Super Admin manages every members-only community; a Head or Co-Head reads their own.
const communities = computed(() =>
  props.lookups.communities.filter(
    (c) => c.members_only && (isSuperAdmin.value || c.id === auth.dashboard?.community_id)
  )
);
const communityId = ref(communities.value[0]?.id ?? null);
const community = computed(() => communities.value.find((c) => c.id === communityId.value));

const entries = ref([]);
const loading = ref(false);
const error = ref('');
const busy = ref(false);
const query = ref('');
const status = ref('all');
const limit = ref(STEP);

const regionOf = (id) => props.lookups.regions.find((r) => r.id === id)?.name ?? '–';
const nameOf = (e) => e.member?.preferred_name || e.member?.full_name || 'Name not known';
const statusKey = (e) => (e.member ? 'signed_in' : e.on_roster ? 'waiting' : 'outside');
const STATUS_BADGE = {
  signed_in: { label: 'Signed in', tone: 'mari' },
  waiting: { label: 'Not signed in yet', tone: '' },
  outside: { label: 'Not in house roster', tone: 'verm' },
};
const statusOf = (e) => STATUS_BADGE[statusKey(e)];

const counts = computed(() => {
  const n = { all: entries.value.length, signed_in: 0, waiting: 0, outside: 0 };
  for (const e of entries.value) n[statusKey(e)] += 1;
  return n;
});
const filtered = computed(() => {
  const term = query.value.trim().toLowerCase();
  return entries.value.filter(
    (e) =>
      (status.value === 'all' || statusKey(e) === status.value) &&
      (!term ||
        [e.email, e.member?.full_name, e.member?.preferred_name, e.member?.member_code].some((v) =>
          v?.toLowerCase().includes(term)
        ))
  );
});
const shown = computed(() => filtered.value.slice(0, limit.value));
watch([query, status], () => (limit.value = STEP));

let loadId = 0;
async function load() {
  if (!communityId.value) return;
  const id = ++loadId;
  loading.value = true;
  error.value = '';
  try {
    const rows = await listCommunityMembers(communityId.value);
    if (id !== loadId) return;
    entries.value = rows;
  } catch (e) {
    if (id !== loadId) return;
    entries.value = [];
    error.value = errorText(e);
  } finally {
    if (id === loadId) loading.value = false;
  }
}
onMounted(load);
onBeforeUnmount(() => loadId++);

const adding = ref(false);
const addMode = ref('paste');
const paste = ref('');
const pasted = computed(() => emailsFromText(paste.value));
const csvFile = ref('');
const csvEmails = ref([]);
const csvError = ref('');
const dragging = ref(false);
const addError = ref('');
const result = ref(null);
const tooMany = computed(
  () => (addMode.value === 'paste' ? pasted.value : csvEmails.value).length > COMMUNITY_ADD_MAX
);

function create() {
  if (!isSuperAdmin.value || !community.value) return;
  result.value = null;
  addError.value = '';
  adding.value = true;
}
defineExpose({ create });

function onFile(ev) {
  const file = ev.target.files?.[0];
  ev.target.value = '';
  readCsv(file);
}
function onDrop(ev) {
  dragging.value = false;
  readCsv(ev.dataTransfer?.files?.[0]);
}
function readCsv(file) {
  csvFile.value = '';
  csvEmails.value = [];
  csvError.value = '';
  result.value = null;
  if (!file) return;
  if (!/\.csv$/i.test(file.name) && file.type !== 'text/csv') {
    csvError.value = 'Use a CSV file.';
    return;
  }
  csvFile.value = file.name;
  const reader = new FileReader();
  reader.onload = () => {
    const { emails, error: message } = emailsFromCsv(parseCsv(String(reader.result || '')));
    csvEmails.value = emails;
    csvError.value =
      message || (emails.length ? '' : 'No emails found in the Email Address column.');
  };
  reader.onerror = () => {
    csvError.value = 'The file could not be read.';
  };
  reader.readAsText(file);
}

async function add(emails) {
  if (!emails.length || emails.length > COMMUNITY_ADD_MAX) return;
  busy.value = true;
  addError.value = '';
  result.value = null;
  try {
    result.value = (await addCommunityMembers(communityId.value, emails)) ?? {};
    if (addMode.value === 'paste') paste.value = '';
    else {
      csvFile.value = '';
      csvEmails.value = [];
    }
    await load();
  } catch (e) {
    addError.value = errorText(e);
  } finally {
    busy.value = false;
  }
}

async function remove(email) {
  const name = community.value?.name ?? 'this community';
  const yes = await askConfirm({
    title: `Remove from ${name}?`,
    message: `${email} will no longer see ${name} Community events, notices or forms.`,
    confirmLabel: 'Remove',
    danger: true,
  });
  if (!yes) return;
  busy.value = true;
  error.value = '';
  try {
    await removeCommunityMember(communityId.value, email);
    await load();
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
.members-toolbar .grow {
  flex: 1 1 280px;
  max-width: 480px;
}
.read-only {
  margin: 0 0 12px;
}
.status-filter {
  margin-bottom: 12px;
}
.status-filter .mono {
  margin-left: 4px;
  font-variant-numeric: tabular-nums;
  opacity: 0.75;
}
.members-count {
  margin: 0 0 10px;
}
.members-table {
  padding: 0;
}
.member-name {
  display: grid;
  gap: 2px;
  min-width: 200px;
}
.member-name b {
  font-size: 14px;
}
.member-name small {
  color: var(--ink-3);
  font-size: 12px;
  overflow-wrap: anywhere;
}
.badges {
  display: inline-flex;
  flex-wrap: wrap;
  gap: 4px;
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
.retry {
  margin-left: 6px;
  border: 0;
  background: none;
  color: inherit;
  font: inherit;
  font-weight: 700;
  text-decoration: underline;
  cursor: pointer;
}
.summary {
  display: grid;
  gap: 10px;
  margin-top: 18px;
  padding-top: 16px;
  border-top: 1px solid var(--line);
}
.summary-list p {
  margin: 0 0 4px;
  font-size: 13.5px;
  color: var(--ink-2);
}
.summary-list.err p {
  color: var(--verm);
}
.summary-list ul {
  margin: 0;
  padding-left: 18px;
  max-height: 160px;
  overflow-y: auto;
  font-size: 13px;
  color: var(--ink-2);
  overflow-wrap: anywhere;
}
@media (max-width: 640px) {
  .member-name {
    min-width: 0;
  }
  .members-toolbar .grow {
    max-width: none;
  }
}
</style>
