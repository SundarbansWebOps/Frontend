<!-- Requests: the two-person rule. Super Admins approve or reject anyone else's request; everyone
     can cancel their own while it is pending. Approving a status change also updates whether the
     student can sign in (apply-account-status); permanent erasure runs hard-delete-member. -->
<template>
  <div>
    <div class="adm-toolbar">
      <div class="adm-chips" role="group" aria-label="Which requests">
        <button
          type="button"
          class="adm-chip"
          :class="{ on: status === 'pending' }"
          @click="show('pending')"
        >
          Pending
        </button>
        <button
          type="button"
          class="adm-chip"
          :class="{ on: status === 'decided' }"
          @click="show('decided')"
        >
          Decided
        </button>
      </div>
    </div>

    <p v-if="error" class="adm-msg err" role="alert">{{ error }}</p>
    <p v-if="notice" class="adm-msg ok" role="status">{{ notice }}</p>

    <ul v-if="requests.length" class="adm-list">
      <li v-for="r in requests" :key="r.id" class="adm-card req">
        <div class="top">
          <div>
            <p class="adm-kicker">{{ REQUEST_LABEL[r.type] ?? r.type }}</p>
            <b class="name">{{ targetName(r) }}</b>
            <span class="mono code">{{
              r.target?.member_code ?? r.target_snapshot?.member?.member_code
            }}</span>
          </div>
          <span class="adm-badge" :class="tone(r.status)">{{ r.status }}</span>
        </div>
        <p v-if="change(r)" class="what">{{ change(r) }}</p>
        <p class="why">“{{ r.reason }}”</p>
        <div class="adm-meta">
          <span
            >Asked by
            {{ r.requested_by === me ? 'you' : (r.requester?.full_name ?? 'a former admin') }}</span
          >
          <span class="mono">{{ day(r.requested_at) }}</span>
          <span v-if="r.reviewed_at && r.status !== 'pending'">
            {{ r.status }} {{ day(r.reviewed_at)
            }}{{ r.review_note ? ` · “${r.review_note}”` : '' }}
          </span>
        </div>

        <div v-if="r.status === 'pending'" class="acts">
          <template v-if="isSuperAdmin && r.requested_by !== me">
            <input
              v-model.trim="notes[r.id]"
              class="adm-input note"
              maxlength="2000"
              placeholder="Note (optional)"
            />
            <button type="button" class="adm-btn mari small" :disabled="busy" @click="approve(r)">
              {{ r.type === 'member_hard_delete' ? 'Approve and erase' : 'Approve' }}
            </button>
            <button type="button" class="adm-btn ghost small" :disabled="busy" @click="reject(r)">
              Reject
            </button>
          </template>
          <template v-else-if="r.requested_by === me">
            <span class="adm-note"
              >Waiting for {{ isSuperAdmin ? 'another' : 'a' }} Super Admin.</span
            >
            <button type="button" class="adm-btn ghost small" :disabled="busy" @click="cancel(r)">
              Cancel request
            </button>
          </template>
        </div>
      </li>
    </ul>
    <p v-else-if="!loading" class="adm-empty">
      {{ status === 'pending' ? 'Nothing is waiting.' : 'No decided requests yet.' }}
    </p>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { auth, errorText, isSuperAdmin } from '../../lib/auth.js';
import {
  POSITION_LABEL,
  REQUEST_LABEL,
  STATUS_ACTION_LABEL,
  approveRequest,
  cancelRequest,
  executeContactChange,
  executeHardDelete,
  listRequests,
  rejectRequest,
  syncSignInAccess,
} from '../../lib/admin.js';

const props = defineProps({ lookups: { type: Object, required: true } });
const emit = defineEmits(['changed']);

const me = computed(() => auth.profile?.id);
const status = ref('pending');
const requests = ref([]);
const loading = ref(false);
const busy = ref(false);
const error = ref('');
const notice = ref('');
const notes = reactive({});

const regionOf = (id) => props.lookups.regions.find((r) => r.id === Number(id))?.name ?? '';
const communityOf = (id) => props.lookups.communities.find((c) => c.id === Number(id))?.name ?? '';
const tone = (s) => (s === 'approved' ? 'mari' : s === 'rejected' ? 'verm' : '');
const day = (iso) =>
  new Date(iso).toLocaleString('en-IN', {
    day: 'numeric',
    month: 'short',
    hour: 'numeric',
    minute: '2-digit',
  });
const targetName = (r) =>
  r.target?.full_name ?? r.target_snapshot?.member?.full_name ?? 'Former member';

const FIELD = {
  full_name: 'Full name',
  preferred_name: 'Preferred name',
  gender: 'Gender',
  phone: 'Phone',
  region_id: 'Region',
};
function change(r) {
  const c = r.requested_change ?? {};
  if (r.type === 'member_profile_update')
    return Object.entries(c)
      .map(([k, v]) => `${FIELD[k] ?? k} → ${k === 'region_id' ? regionOf(v) : (v ?? 'cleared')}`)
      .join(' · ');
  if (r.type === 'member_contact_change') return `Login email → ${c.email}`;
  if (r.type === 'member_status_change') return STATUS_ACTION_LABEL[c.action] ?? c.action;
  if (r.type === 'position_change')
    return c.action === 'revoke'
      ? 'Revoke their position'
      : c.position === 'rc'
        ? `Make Regional Coordinator of ${regionOf(c.region_id)}`
        : `Make ${POSITION_LABEL[c.position]} of ${communityOf(c.community_id)}`;
  return '';
}

// Approvals that change whether the student may sign in.
const AFFECTS_SIGN_IN = new Set(['member_deletion', 'member_blacklist', 'member_status_change']);

async function load() {
  loading.value = true;
  error.value = '';
  try {
    requests.value = await listRequests({ status: status.value });
  } catch (e) {
    error.value = errorText(e);
  } finally {
    loading.value = false;
  }
}
onMounted(load);

function show(s) {
  status.value = s;
  notice.value = '';
  load();
}

async function act(run, message) {
  busy.value = true;
  error.value = notice.value = '';
  try {
    await run();
    notice.value = message;
    await load();
    emit('changed');
  } catch (e) {
    error.value = errorText(e);
  } finally {
    busy.value = false;
  }
}

function approve(r) {
  if (r.type === 'member_contact_change')
    return act(
      () => executeContactChange(r.id, notes[r.id]),
      'Approved. Their sign-in now uses the new email.'
    );
  if (r.type === 'member_hard_delete') {
    if (!confirm(`Erase ${targetName(r)} permanently? This cannot be undone.`)) return;
    return act(() => executeHardDelete(r.id), 'Erased. Their account has been removed.');
  }
  return act(async () => {
    await approveRequest(r.id, notes[r.id]);
    if (AFFECTS_SIGN_IN.has(r.type)) {
      try {
        await syncSignInAccess(r.target_member_id);
      } catch (e) {
        throw new Error(
          `Approved, but sign-in access was not updated yet (${e.message}). Ask the web admin to check the apply-account-status function.`
        );
      }
    }
  }, 'Approved and applied.');
}
const reject = (r) => act(() => rejectRequest(r.id, notes[r.id]), 'Rejected. Nothing was changed.');
const cancel = (r) => act(() => cancelRequest(r.id), 'Request cancelled.');
</script>

<style scoped>
.req {
  display: grid;
  gap: 8px;
}
.top {
  display: flex;
  justify-content: space-between;
  align-items: start;
  gap: 12px;
}
.name {
  font-size: 17px;
  font-weight: 650;
}
.code {
  margin-left: 8px;
  font-size: 12.5px;
  color: var(--ink-3);
}
.what {
  margin: 0;
  font-weight: 600;
}
.why {
  margin: 0;
  max-width: 70ch;
  color: var(--ink-2);
  font-size: 14px;
  overflow-wrap: anywhere;
}
.acts {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  margin-top: 6px;
}
.note {
  flex: 1 1 220px;
  height: 36px;
}
</style>
