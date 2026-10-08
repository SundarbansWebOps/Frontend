<!-- Students in scope (RC: own region; Super Admin: all). Open one to see their details and file a
     request: edit details, delete, blacklist; Super Admins also status and position changes. -->
<template>
  <div>
    <div class="adm-toolbar">
      <label class="adm-field grow">
        <span>Search</span>
        <input
          v-model.trim="query"
          class="adm-input"
          type="search"
          placeholder="Name, email, phone or roll number"
          @input="onSearch"
        />
      </label>
      <label v-if="isSuperAdmin" class="adm-field">
        <span>Region</span>
        <select v-model="regionId" class="adm-input" @change="reload">
          <option :value="null">All regions</option>
          <option v-for="r in lookups.regions" :key="r.id" :value="r.id">{{ r.name }}</option>
        </select>
      </label>
      <label class="adm-field">
        <span>Status</span>
        <select v-model="status" class="adm-input" @change="reload">
          <option value="current">Current</option>
          <option value="active">Active</option>
          <option value="suspended">Suspended</option>
          <option value="blacklisted">Blacklisted</option>
          <option v-if="isSuperAdmin" value="deleted">Deleted</option>
        </select>
      </label>
    </div>

    <p v-if="error" class="adm-msg err" role="alert">{{ error }}</p>
    <p v-if="query && query.length < 3" class="adm-note">Type at least 3 characters to search.</p>

    <ul v-if="rows.length" class="adm-list">
      <li v-for="m in rows" :key="m.id">
        <button type="button" class="adm-row button" @click="open(m.id)">
          <div>
            <b>{{ m.preferred_name || m.full_name }}</b>
            <div class="adm-meta">
              <span class="mono">{{ m.member_code }}</span>
              <span>{{ regionOf(m.region_id) }}</span>
              <span>{{ m.email }}</span>
            </div>
          </div>
          <span class="adm-badge" :class="statusTone(m.account_status)">{{
            m.account_status
          }}</span>
        </button>
      </li>
    </ul>
    <p v-else-if="!loading" class="adm-empty">
      {{
        query.length >= 3
          ? 'No student matches that search.'
          : 'No students here yet. Add them on the Roster tab.'
      }}
    </p>
    <div v-if="!searching && rows.length < total" class="more">
      <button type="button" class="adm-btn ghost" :disabled="loading" @click="more">
        Show more ({{ total - rows.length }} left)
      </button>
    </div>

    <AdminDialog v-if="detail" ref="dlg" :title="detailTitle" @close="detail = null">
      <template v-if="mode === 'view'">
        <dl class="adm-facts">
          <div>
            <dt>Roll / code</dt>
            <dd class="mono">{{ detail.member.member_code }}</dd>
          </div>
          <div>
            <dt>Status</dt>
            <dd>{{ detail.member.account_status }}</dd>
          </div>
          <div>
            <dt>Email</dt>
            <dd>{{ detail.member.email }}</dd>
          </div>
          <div>
            <dt>Phone</dt>
            <dd class="mono">{{ detail.member.phone || '–' }}</dd>
          </div>
          <div>
            <dt>Region</dt>
            <dd>{{ regionOf(detail.member.region_id) }}</dd>
          </div>
          <div>
            <dt>Gender</dt>
            <dd>{{ detail.member.gender || '–' }}</dd>
          </div>
          <div>
            <dt>Full name</dt>
            <dd>{{ detail.member.full_name }}</dd>
          </div>
          <div>
            <dt>Preferred name</dt>
            <dd>{{ detail.member.preferred_name || '–' }}</dd>
          </div>
          <div>
            <dt>Position</dt>
            <dd>{{ positionText(detail.position) }}</dd>
          </div>
          <div>
            <dt>Joined</dt>
            <dd>{{ day(detail.member.created_at) }}</dd>
          </div>
          <div>
            <dt>Regional form</dt>
            <dd>
              {{ detail.regional ? `Filled ${day(detail.regional.updated_at)}` : 'Not filled' }}
            </dd>
          </div>
        </dl>

        <p v-if="done" class="adm-msg ok spaced" role="status">{{ done }}</p>
        <p v-if="actionError" class="adm-msg err spaced" role="alert">{{ actionError }}</p>

        <p class="adm-kicker spaced">Ask for a change</p>
        <div class="adm-chips">
          <button v-if="canEdit" type="button" class="adm-btn small" @click="startEdit">
            Edit details
          </button>
          <button
            v-if="canRequestRemoval"
            type="button"
            class="adm-btn ghost small"
            @click="ask('delete')"
          >
            Delete
          </button>
          <button
            v-if="canRequestRemoval"
            type="button"
            class="adm-btn danger small"
            @click="ask('blacklist')"
          >
            Blacklist
          </button>
          <template v-if="isSuperAdmin && !isSelf">
            <button
              v-for="a in statusActions"
              :key="a"
              type="button"
              class="adm-btn ghost small"
              @click="ask(a)"
            >
              {{ STATUS_ACTION_LABEL[a] }}
            </button>
            <button
              v-if="canErase"
              type="button"
              class="adm-btn danger small"
              @click="ask('erase')"
            >
              Erase permanently
            </button>
            <button
              v-if="detail.position"
              type="button"
              class="adm-btn ghost small"
              @click="ask('revoke')"
            >
              Revoke position
            </button>
            <button
              v-else-if="detail.member.account_status === 'active'"
              type="button"
              class="adm-btn ghost small"
              @click="startPosition"
            >
              Give a position
            </button>
          </template>
        </div>
        <p v-if="!canEdit && !isSuperAdmin" class="adm-note spaced">
          Coordinators and Super Admins are changed by a Super Admin only.
        </p>
      </template>

      <form v-else-if="mode === 'edit'" class="adm-form" @submit.prevent="submitEdit">
        <label class="adm-field wide">
          <span>Full name (as on the roster)</span>
          <input v-model="form.full_name" class="adm-input" required maxlength="200" />
        </label>
        <label class="adm-field">
          <span>Preferred name</span>
          <input v-model="form.preferred_name" class="adm-input" maxlength="100" />
        </label>
        <label class="adm-field">
          <span>Gender</span>
          <input v-model="form.gender" class="adm-input" maxlength="50" />
        </label>
        <label class="adm-field">
          <span>Phone (optional)</span>
          <input
            v-model="form.phone"
            class="adm-input"
            inputmode="tel"
            placeholder="+919876543210"
          />
        </label>
        <label class="adm-field">
          <span>Region</span>
          <select v-model="form.region_id" class="adm-input">
            <option v-for="r in lookups.regions" :key="r.id" :value="r.id">{{ r.name }}</option>
          </select>
        </label>
        <label class="adm-field wide">
          <span>Why</span>
          <textarea v-model.trim="form.reason" class="adm-input" required maxlength="2000" />
          <small>A Super Admin reads this before approving. Email can’t be changed here.</small>
        </label>
        <p v-if="actionError" class="adm-msg err wide" role="alert">{{ actionError }}</p>
        <div class="wide row-end">
          <button type="button" class="adm-btn ghost" @click="mode = 'view'">Back</button>
          <button type="submit" class="adm-btn mari" :disabled="busy">Send for approval</button>
        </div>
      </form>

      <form v-else-if="mode === 'position'" class="adm-form" @submit.prevent="submitPosition">
        <label class="adm-field">
          <span>Position</span>
          <select v-model="form.position" class="adm-input" required>
            <option value="rc">
              Regional Coordinator ({{ regionOf(detail.member.region_id) }})
            </option>
            <option value="head">Community Head</option>
            <option value="co_head">Community Co-Head</option>
          </select>
        </label>
        <label v-if="form.position !== 'rc'" class="adm-field">
          <span>Community</span>
          <select v-model="form.community_id" class="adm-input" required>
            <option v-for="c in lookups.communities" :key="c.id" :value="c.id">{{ c.name }}</option>
          </select>
        </label>
        <label class="adm-field wide">
          <span>Why</span>
          <textarea v-model.trim="form.reason" class="adm-input" required maxlength="2000" />
          <small
            >An RC coordinates the region they live in. Another Super Admin approves this.</small
          >
        </label>
        <p v-if="actionError" class="adm-msg err wide" role="alert">{{ actionError }}</p>
        <div class="wide row-end">
          <button type="button" class="adm-btn ghost" @click="mode = 'view'">Back</button>
          <button type="submit" class="adm-btn mari" :disabled="busy">Send for approval</button>
        </div>
      </form>

      <form v-else-if="mode === 'reason'" class="adm-form" @submit.prevent="submitReason">
        <p class="adm-note wide">{{ pending.explain }}</p>
        <label class="adm-field wide">
          <span>Why</span>
          <textarea v-model.trim="form.reason" class="adm-input" required maxlength="2000" />
        </label>
        <p v-if="actionError" class="adm-msg err wide" role="alert">{{ actionError }}</p>
        <div class="wide row-end">
          <button type="button" class="adm-btn ghost" @click="mode = 'view'">Back</button>
          <button
            type="submit"
            class="adm-btn"
            :class="pending.danger ? 'danger' : 'mari'"
            :disabled="busy"
          >
            {{ pending.cta }}
          </button>
        </div>
      </form>
    </AdminDialog>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import AdminDialog from './AdminDialog.vue';
import { auth, errorText, isSuperAdmin } from '../../lib/auth.js';
import {
  POSITION_LABEL,
  STATUS_ACTION_LABEL,
  getMember,
  listMembers,
  requestBlacklist,
  requestDeletion,
  requestHardDelete,
  requestPosition,
  requestStatus,
  requestUpdate,
  searchMembers,
} from '../../lib/admin.js';

const props = defineProps({ lookups: { type: Object, required: true } });
const emit = defineEmits(['changed']);

const query = ref('');
const regionId = ref(null);
const status = ref('current');
const rows = ref([]);
const total = ref(0);
const page = ref(0);
const loading = ref(false);
const searching = ref(false);
const error = ref('');

const regionOf = (id) => props.lookups.regions.find((r) => r.id === id)?.name ?? '–';
const statusTone = (s) => (s === 'active' ? '' : s === 'suspended' ? 'mari' : 'verm');
const day = (iso) =>
  iso
    ? new Date(iso).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
    : '–';
const positionText = (p) =>
  !p
    ? 'None'
    : p.position === 'rc'
      ? `RC, ${regionOf(p.region_id)}`
      : `${POSITION_LABEL[p.position]}, ${props.lookups.communities.find((c) => c.id === p.community_id)?.name ?? ''}`;

async function reload() {
  if (query.value.length >= 3) return runSearch();
  searching.value = false;
  page.value = 0;
  loading.value = true;
  error.value = '';
  try {
    const { data, count } = await listMembers({
      regionId: regionId.value,
      status: status.value,
      page: 0,
    });
    rows.value = data;
    total.value = count;
  } catch (e) {
    error.value = errorText(e);
  } finally {
    loading.value = false;
  }
}

async function more() {
  loading.value = true;
  try {
    const { data } = await listMembers({
      regionId: regionId.value,
      status: status.value,
      page: page.value + 1,
    });
    page.value += 1;
    rows.value = rows.value.concat(data);
  } catch (e) {
    error.value = errorText(e);
  } finally {
    loading.value = false;
  }
}

let searchTimer;
function onSearch() {
  clearTimeout(searchTimer);
  if (!query.value) return reload();
  if (query.value.length < 3) return;
  searchTimer = setTimeout(runSearch, 300);
}
async function runSearch() {
  searching.value = true;
  loading.value = true;
  error.value = '';
  try {
    const found = await searchMembers(query.value.slice(0, 100), status.value === 'deleted');
    rows.value = found.filter(
      (m) =>
        (!regionId.value || m.region_id === regionId.value) &&
        (status.value === 'current'
          ? m.account_status !== 'deleted'
          : m.account_status === status.value)
    );
  } catch (e) {
    error.value = errorText(e);
  } finally {
    loading.value = false;
  }
}

onMounted(reload);

// Detail and requests

const detail = ref(null);
const mode = ref('view');
const busy = ref(false);
const done = ref('');
const actionError = ref('');
const pending = ref(null);
const form = reactive({});

const detailTitle = computed(() =>
  detail.value ? detail.value.member.preferred_name || detail.value.member.full_name : ''
);
const isSelf = computed(() => detail.value?.member.id === auth.profile?.id);
const targetIsAdmin = computed(() => !!detail.value?.position);
const canEdit = computed(
  () =>
    !isSelf.value &&
    detail.value?.member.account_status !== 'deleted' &&
    (isSuperAdmin.value || !targetIsAdmin.value)
);
const canRequestRemoval = computed(
  () =>
    !isSelf.value &&
    !targetIsAdmin.value &&
    !['deleted', 'blacklisted'].includes(detail.value?.member.account_status)
);
const statusActions = computed(() => {
  const s = detail.value?.member.account_status;
  return (
    {
      active: ['suspend'],
      suspended: ['reinstate'],
      deleted: ['restore'],
      blacklisted: ['lift_blacklist'],
    }[s] ?? []
  );
});
const canErase = computed(() => {
  const m = detail.value?.member;
  return (
    m?.account_status === 'deleted' &&
    m.deleted_at &&
    Date.now() - new Date(m.deleted_at) >= 30 * 864e5
  );
});

async function open(id) {
  done.value = actionError.value = '';
  mode.value = 'view';
  try {
    detail.value = await getMember(id);
  } catch (e) {
    error.value = errorText(e);
  }
}

function reset(extra = {}) {
  for (const k of Object.keys(form)) delete form[k];
  Object.assign(form, { reason: '' }, extra);
  actionError.value = '';
}

function startEdit() {
  const m = detail.value.member;
  reset({
    full_name: m.full_name,
    preferred_name: m.preferred_name ?? '',
    gender: m.gender ?? '',
    phone: m.phone,
    region_id: m.region_id,
  });
  mode.value = 'edit';
}

const ASK = {
  delete: {
    explain:
      'The student is removed from the house and can no longer sign in. A Super Admin can restore them later.',
    cta: 'Ask to delete',
    danger: true,
    run: (id, why) => requestDeletion(id, why),
  },
  blacklist: {
    explain: 'The student is removed and can never be added again with the same email or phone.',
    cta: 'Ask to blacklist',
    danger: true,
    run: (id, why) => requestBlacklist(id, why),
  },
  suspend: {
    explain: 'The student cannot sign in until reinstated.',
    cta: 'Ask to suspend',
    run: (id, why) => requestStatus(id, 'suspend', why),
  },
  reinstate: {
    explain: 'The student can sign in again.',
    cta: 'Ask to reinstate',
    run: (id, why) => requestStatus(id, 'reinstate', why),
  },
  restore: {
    explain: 'The deleted student becomes active again.',
    cta: 'Ask to restore',
    run: (id, why) => requestStatus(id, 'restore', why),
  },
  lift_blacklist: {
    explain: 'The blacklist ends; a blacklisted (not deleted) student becomes active again.',
    cta: 'Ask to lift',
    run: (id, why) => requestStatus(id, 'lift_blacklist', why),
  },
  erase: {
    explain:
      'Permanent: personal details are erased and the account is removed. A second Super Admin carries it out from Requests.',
    cta: 'Ask to erase',
    danger: true,
    run: (id, why) => requestHardDelete(id, why),
  },
  revoke: {
    explain: 'The student stops being a coordinator or community lead.',
    cta: 'Ask to revoke',
    run: (id, why) => requestPosition(id, 'revoke', null, null, why),
  },
};

function ask(kind) {
  pending.value = ASK[kind];
  reset();
  mode.value = 'reason';
}

async function file(run) {
  busy.value = true;
  actionError.value = '';
  try {
    await run();
    done.value = isSuperAdmin.value
      ? 'Request sent. Another Super Admin has to approve it.'
      : 'Request sent. A Super Admin will review it.';
    mode.value = 'view';
    emit('changed');
  } catch (e) {
    actionError.value = errorText(e);
  } finally {
    busy.value = false;
  }
}

function submitReason() {
  return file(() => pending.value.run(detail.value.member.id, form.reason));
}

function submitEdit() {
  const m = detail.value.member;
  const changes = {};
  for (const k of ['full_name', 'preferred_name', 'gender', 'phone', 'region_id']) {
    const before = m[k] ?? '';
    const after = typeof form[k] === 'string' ? form[k].trim() : form[k];
    if (String(after ?? '') !== String(before)) changes[k] = after === '' ? null : after;
  }
  if (!Object.keys(changes).length) {
    actionError.value = 'Nothing has changed.';
    return;
  }
  return file(() => requestUpdate(m.id, changes, form.reason));
}

function submitPosition() {
  return file(() =>
    requestPosition(
      detail.value.member.id,
      'assign',
      form.position,
      form.position === 'rc' ? null : form.community_id,
      form.reason
    )
  );
}

function startPosition() {
  reset({ position: 'rc', community_id: props.lookups.communities[0]?.id ?? null });
  mode.value = 'position';
}
</script>

<style scoped>
.grow {
  flex: 1 1 280px;
}
select.adm-input {
  min-width: 160px;
}
.more {
  display: flex;
  justify-content: center;
  margin-top: 14px;
}
.spaced {
  margin-top: 18px;
}
.row-end {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}
</style>
