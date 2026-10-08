<!-- The roster: students added before their first Google sign-in. RC adds to their own region;
     Super Admins choose the region. A row disappears once the student has signed in. -->
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
        <input v-model.trim="one.full_name" class="adm-input" required maxlength="200" />
      </label>
      <label class="adm-field">
        <span>Phone (WhatsApp)</span>
        <input
          v-model.trim="one.phone"
          class="adm-input"
          required
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
        <select v-model="one.region_id" class="adm-input" required>
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
          Columns: email, full name, phone{{ isSuperAdmin ? ', region (name or code)' : '' }},
          gender (optional). Copy straight from Google Sheets; a header row is skipped.
        </small>
      </label>
      <p class="adm-note wide">
        {{ parsed.length }} student{{ parsed.length === 1 ? '' : 's' }} found.
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
          :disabled="busy || !parsed.length || parsed.length > 500"
        >
          Add {{ parsed.length || '' }} to roster
        </button>
      </div>
    </form>

    <div class="wide-col">
      <p class="adm-kicker">Waiting for first sign-in ({{ entries.length }})</p>
      <p v-if="error" class="adm-msg err" role="alert">{{ error }}</p>
      <ul v-if="entries.length" class="adm-list">
        <li v-for="e in entries" :key="e.email" class="adm-row">
          <div>
            <b>{{ e.full_name }}</b>
            <div class="adm-meta">
              <span class="mono">{{ e.email }}</span>
              <span class="mono">{{ e.phone }}</span>
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
      <p v-else class="adm-empty">
        Nobody is waiting. Students you add appear here until they sign in.
      </p>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { auth, errorText, isSuperAdmin } from '../../lib/auth.js';
import {
  listRoster,
  parseRosterPaste,
  rosterAdd,
  rosterAddMany,
  rosterRemove,
} from '../../lib/admin.js';

const props = defineProps({ lookups: { type: Object, required: true } });
const emit = defineEmits(['changed']);

const regionOf = (id) => props.lookups.regions.find((r) => r.id === id)?.name ?? '–';
const myRegion = computed(() => regionOf(auth.dashboard?.region_id));

const entries = ref([]);
const error = ref('');
const busy = ref(false);

const one = reactive({
  email: '',
  full_name: '',
  phone: '',
  gender: '',
  region_id: props.lookups.regions[0]?.id,
});
const oneMsg = ref('');
const oneOk = ref(false);

const paste = ref('');
const parsed = computed(() => parseRosterPaste(paste.value, props.lookups.regions));
const bulkResult = ref(null);
const bulkMsg = ref('');
const bulkOk = ref(false);

async function load() {
  try {
    entries.value = await listRoster();
  } catch (e) {
    error.value = errorText(e);
  }
}
onMounted(load);

async function addOne() {
  busy.value = true;
  oneMsg.value = '';
  try {
    await rosterAdd({ ...one, region_id: isSuperAdmin.value ? one.region_id : null });
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
    const rows = parsed.value.map((r) => ({
      ...r,
      region_id: isSuperAdmin.value ? r.region_id : null,
    }));
    const result = await rosterAddMany(rows);
    const added = result.filter((r) => r.ok).length;
    bulkResult.value = result;
    bulkOk.value = added === result.length;
    bulkMsg.value = `${added} of ${result.length} added.${bulkOk.value ? '' : ' The rest are listed above with the reason.'}`;
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
@media (max-width: 900px) {
  .grid {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
