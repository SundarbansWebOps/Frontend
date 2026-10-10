<!-- Notices for the house, a region or a community, with optional cohort targeting.
     Starts-at in the future keeps a notice off student banners until that time.
     Group applications belong on Forms (invite after submit). -->
<template>
  <div>
    <div class="adm-toolbar between">
      <p class="adm-note">{{ rows.length }} notice{{ rows.length === 1 ? '' : 's' }}.</p>
      <button type="button" class="adm-btn mari" @click="edit()">New notice</button>
    </div>
    <p v-if="error" class="adm-msg err" role="alert">{{ error }}</p>
    <p v-if="notice" class="adm-msg ok" role="status">{{ notice }}</p>
    <ul v-if="rows.length" class="adm-list">
      <li v-for="n in rows" :key="n.id" class="adm-row">
        <div>
          <b>{{ n.title }}</b>
          <div class="adm-meta">
            <span>{{ scopeOf(n) }}</span>
            <span class="mono">{{ day(n.starts_at) }}</span>
            <span v-if="n.ends_at" class="mono">until {{ day(n.ends_at) }}</span>
            <span v-if="n.audience_cohorts?.length" class="mono">{{
              n.audience_cohorts.join(', ')
            }}</span>
            <span v-if="new Date(n.starts_at) > new Date()" class="adm-badge">scheduled</span>
          </div>
        </div>
        <button type="button" class="adm-btn ghost small" @click="edit(n)">Edit</button>
      </li>
    </ul>
    <p v-else-if="!loading" class="adm-empty">No notices yet.</p>
    <div v-if="hasMore" class="row-end">
      <button type="button" class="adm-btn ghost" :disabled="loading" @click="loadMore">
        {{ loading ? 'Loading…' : 'Load older notices' }}
      </button>
    </div>

    <AdminDialog
      v-if="form"
      ref="dlg"
      wide
      :title="form.id ? 'Edit notice' : 'New notice'"
      @close="form = null"
    >
      <form class="adm-form" @submit.prevent="save">
        <label class="adm-field wide">
          <span>Title</span>
          <input v-model.trim="form.title" class="adm-input" required maxlength="200" />
        </label>
        <label class="adm-field wide">
          <span>Body</span>
          <textarea v-model.trim="form.body" class="adm-input" required maxlength="4000" />
        </label>
        <label class="adm-field">
          <span>Scope</span>
          <select v-model="form.scope" class="adm-input" @change="onScope">
            <option v-if="isSuperAdmin" value="house">Whole house</option>
            <option v-if="isSuperAdmin || isRc" value="region">Region</option>
            <option v-if="isSuperAdmin || isHead" value="community">Community</option>
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
        <div class="wide">
          <p class="adm-kicker">Cohorts</p>
          <AdminCohortSelect v-if="cohorts" v-model="form.audience_cohorts" :cohorts="cohorts" />
        </div>
        <label class="adm-field">
          <span>Starts</span>
          <input v-model="form.starts" class="adm-input" type="datetime-local" required />
        </label>
        <label class="adm-field">
          <span>Ends (optional)</span>
          <input v-model="form.ends" class="adm-input" type="datetime-local" />
        </label>
        <label class="adm-field wide">
          <span>Link (optional)</span>
          <input v-model.trim="form.link" class="adm-input" type="url" placeholder="https://…" />
        </label>
        <p v-if="formError" class="adm-msg err wide" role="alert">{{ formError }}</p>
        <div class="wide row-end">
          <button type="button" class="adm-btn ghost" :disabled="busy" @click="saveFuture">
            Save scheduled
          </button>
          <button type="submit" class="adm-btn mari" :disabled="busy">Publish now</button>
        </div>
      </form>
    </AdminDialog>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import AdminDialog from './AdminDialog.vue';
import AdminCohortSelect from './AdminCohortSelect.vue';
import { auth, errorText, isRc, isSuperAdmin } from '../../lib/auth.js';
import { getAvailableCohorts, listNoticesAdmin, saveNotice } from '../../lib/admin.js';

const props = defineProps({ lookups: { type: Object, required: true } });
const emit = defineEmits(['changed']);

const isHead = computed(
  () => auth.dashboard?.position === 'head' || auth.dashboard?.position === 'co_head'
);
const rows = ref([]);
const page = ref(0);
const hasMore = ref(false);
const cohorts = ref(null);
const loading = ref(false);
const busy = ref(false);
const error = ref('');
const notice = ref('');
const form = ref(null);
const formError = ref('');
const dlg = ref(null);

const regionOf = (id) => props.lookups.regions.find((r) => r.id === id)?.name ?? 'region';
const communityOf = (id) => props.lookups.communities.find((c) => c.id === id)?.name ?? 'community';
const scopeOf = (n) => {
  if (n.community_id)
    return `${communityOf(n.community_id)} publisher · all matching house members`;
  if (n.region_id) return `${regionOf(n.region_id)} members`;
  return 'House-wide';
};
const day = (iso) =>
  new Date(iso).toLocaleString('en-IN', {
    day: 'numeric',
    month: 'short',
    hour: 'numeric',
    minute: '2-digit',
  });
const toLocal = (iso) => {
  if (!iso) return '';
  const d = new Date(iso);
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
};
const fromLocal = (v) => (v ? new Date(v).toISOString() : null);

async function load(more = false) {
  loading.value = true;
  error.value = '';
  try {
    const nextPage = more ? page.value + 1 : 0;
    const [list, coh] = await Promise.all([
      listNoticesAdmin({ page: nextPage }),
      getAvailableCohorts(),
    ]);
    rows.value = more ? [...rows.value, ...list] : list;
    page.value = nextPage;
    hasMore.value = list.length === 50;
    cohorts.value = coh;
  } catch (e) {
    error.value = errorText(e);
  } finally {
    loading.value = false;
  }
}
const loadMore = () => load(true);
onMounted(load);

function defaultScope() {
  if (isSuperAdmin.value) return { scope: 'house', region_id: null, community_id: null };
  if (isRc.value)
    return { scope: 'region', region_id: auth.dashboard.region_id, community_id: null };
  return { scope: 'community', region_id: null, community_id: auth.dashboard.community_id };
}

function edit(n) {
  formError.value = '';
  const start = new Date();
  start.setMinutes(0, 0, 0);
  if (n) {
    form.value = {
      ...n,
      starts: toLocal(n.starts_at),
      ends: toLocal(n.ends_at),
      link: n.link ?? '',
      audience_cohorts: n.audience_cohorts ?? [],
      scope: n.community_id ? 'community' : n.region_id ? 'region' : 'house',
    };
  } else {
    form.value = {
      title: '',
      body: '',
      link: '',
      audience_cohorts: [],
      starts: toLocal(start),
      ends: '',
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
    form.value.region_id = isRc.value
      ? auth.dashboard.region_id
      : (form.value.region_id ?? props.lookups.regions[0]?.id);
  } else {
    form.value.region_id = null;
    form.value.community_id = isHead.value
      ? auth.dashboard.community_id
      : (form.value.community_id ?? props.lookups.communities[0]?.id);
  }
}

async function write(startsAt) {
  busy.value = true;
  formError.value = '';
  try {
    const scope = isSuperAdmin.value ? form.value : { ...form.value, ...defaultScope() };
    await saveNotice({
      id: form.value.id,
      title: form.value.title,
      body: form.value.body,
      link: form.value.link || null,
      region_id: scope.scope === 'region' ? scope.region_id : null,
      community_id: scope.scope === 'community' ? scope.community_id : null,
      audience_cohorts: form.value.audience_cohorts ?? [],
      starts_at: startsAt,
      ends_at: fromLocal(form.value.ends),
    });
    dlg.value?.close();
    notice.value = 'Saved.';
    await load();
    emit('changed');
  } catch (e) {
    formError.value = errorText(e);
  } finally {
    busy.value = false;
  }
}
const save = () => write(new Date().toISOString());
const saveFuture = () => write(fromLocal(form.value.starts) || new Date().toISOString());
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
