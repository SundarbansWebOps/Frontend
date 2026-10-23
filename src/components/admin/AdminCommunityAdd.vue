<!-- Super Admin: tag many students with a community at once, pasted or from a CSV with an Email
     Address column. Only emails already in the house (signed in or on the roster) are tagged. -->
<template>
  <AdminDialog title="Add to a community" wide @close="emit('close')">
    <label class="adm-field community-pick">
      <span>Community</span>
      <AdminSelect
        v-model="communityId"
        :options="lookups.communities"
        value-key="id"
        label-key="name"
      />
    </label>
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
          One per line, or separated by commas or spaces. Copy a column straight from Sheets; words
          without an @ are skipped.
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
        {{ result.added ?? 0 }} tagged, {{ result.already ?? 0 }} already in this community.
      </p>
      <div v-if="result.not_in_house?.length" class="summary-list">
        <p>
          <b>{{ result.not_in_house.length }} skipped: not in the house</b> (no account and not on
          the roster; add them as students first)
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
</template>

<script setup>
import { computed, ref } from 'vue';
import LineIcon from '../site/LineIcon.vue';
import AdminDialog from './AdminDialog.vue';
import AdminSelect from './AdminSelect.vue';
import { errorText } from '../../lib/auth.js';
import {
  COMMUNITY_ADD_MAX,
  addCommunityMembers,
  emailsFromCsv,
  emailsFromText,
  parseCsv,
} from '../../lib/admin.js';

const props = defineProps({ lookups: { type: Object, required: true } });
const emit = defineEmits(['changed', 'close']);

const addModes = [
  { id: 'paste', label: 'Paste emails' },
  { id: 'csv', label: 'Upload CSV' },
];

const communityId = ref(props.lookups.communities[0]?.id ?? null);
const busy = ref(false);
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
    emit('changed');
  } catch (e) {
    addError.value = errorText(e);
  } finally {
    busy.value = false;
  }
}
</script>

<style scoped>
.community-pick {
  max-width: 320px;
  margin-bottom: 16px;
}
.add-modes {
  margin-bottom: 20px;
}
.tall {
  min-height: 150px;
  font-family: var(--mono);
  font-size: 13px;
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
</style>
