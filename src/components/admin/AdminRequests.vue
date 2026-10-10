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

    <section v-if="status === 'pending'" class="block" aria-labelledby="region-req-h">
      <h3 id="region-req-h" class="adm-kicker">Student region corrections</h3>
      <p class="adm-note">
        The student’s current-region coordinator or a Super Admin reviews these. They are not the
        two-person admin workflow.
      </p>
      <ul v-if="regionRequests.length" class="adm-list">
        <li v-for="r in regionRequests" :key="r.id" class="adm-card req">
          <div class="top">
            <div>
              <p class="adm-kicker">Region change</p>
              <b class="name">{{
                r.member?.preferred_name || r.member?.full_name || r.member?.email || r.member_id
              }}</b>
              <span class="mono code">{{ r.member?.member_code }}</span>
            </div>
            <span class="adm-badge">{{ r.status }}</span>
          </div>
          <p class="what">{{ regionOf(r.from_region_id) }} → {{ regionOf(r.to_region_id) }}</p>
          <p class="why">“{{ r.reason }}”</p>
          <div v-if="r.status === 'pending'" class="acts">
            <input
              v-model.trim="notes[r.id]"
              class="adm-input note"
              maxlength="2000"
              placeholder="Note (optional)"
            />
            <button
              type="button"
              class="adm-btn mari small"
              :disabled="busy"
              @click="reviewRegion(r, true)"
            >
              Approve
            </button>
            <button
              type="button"
              class="adm-btn ghost small"
              :disabled="busy"
              @click="reviewRegion(r, false)"
            >
              Reject
            </button>
          </div>
        </li>
      </ul>
      <p v-else-if="!loading" class="adm-empty">No student region requests waiting.</p>
    </section>

    <section v-if="isSuperAdmin && status === 'pending'" class="block" aria-labelledby="cert-req-h">
      <h3 id="cert-req-h" class="adm-kicker">Certificate name corrections</h3>
      <ul v-if="certRequests.length" class="adm-list">
        <li v-for="r in certRequests" :key="r.id" class="adm-card req">
          <div class="top">
            <div>
              <p class="adm-kicker">Certificate name</p>
              <b class="name">{{
                r.member?.preferred_name || r.member?.full_name || r.member?.email || r.member_id
              }}</b>
            </div>
            <span class="adm-badge">{{ r.status }}</span>
          </div>
          <p class="what">{{ r.old_name }} → {{ r.new_name }}</p>
          <p class="why">“{{ r.reason }}”</p>
          <div v-if="r.status === 'pending' && r.member_id !== me" class="acts">
            <input
              v-model.trim="notes[r.id]"
              class="adm-input note"
              maxlength="2000"
              placeholder="Note (optional)"
            />
            <button
              type="button"
              class="adm-btn mari small"
              :disabled="busy"
              @click="reviewCert(r, true)"
            >
              Approve
            </button>
            <button
              type="button"
              class="adm-btn ghost small"
              :disabled="busy"
              @click="reviewCert(r, false)"
            >
              Reject
            </button>
          </div>
          <p v-else-if="r.member_id === me" class="adm-note">You cannot review your own request.</p>
        </li>
      </ul>
      <p v-else-if="!loading" class="adm-empty">No certificate-name requests waiting.</p>
    </section>

    <h3 class="adm-kicker">Admin student changes</h3>
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
  listCertificateNameRequests,
  listRegionRequests,
  listRequests,
  rejectRequest,
  reviewCertificateNameRequest,
  reviewRegionRequest,
  syncSignInAccess,
} from '../../lib/admin.js';

const props = defineProps({ lookups: { type: Object, required: true } });
const emit = defineEmits(['changed']);

const me = computed(() => auth.profile?.id);
const status = ref('pending');
const requests = ref([]);
const regionRequests = ref([]);
const certRequests = ref([]);
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
    if (status.value === 'pending') {
      try {
        regionRequests.value = (await listRegionRequests()).filter((r) => r.status === 'pending');
      } catch (e) {
        regionRequests.value = [];
        error.value = errorText(e);
      }
      if (isSuperAdmin.value) {
        try {
          certRequests.value = (await listCertificateNameRequests()).filter(
            (r) => r.status === 'pending'
          );
        } catch (e) {
          certRequests.value = [];
          error.value = errorText(e);
        }
      }
    } else {
      regionRequests.value = [];
      certRequests.value = [];
    }
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
const reviewRegion = (r, approve) =>
  act(
    () => reviewRegionRequest(r.id, approve, notes[r.id]),
    approve ? 'Region change applied.' : 'Region request rejected. Nothing was changed.'
  );
const reviewCert = (r, approve) =>
  act(
    () => reviewCertificateNameRequest(r.id, approve, notes[r.id]),
    approve
      ? 'Certificate name updated for future certificates.'
      : 'Certificate-name request rejected.'
  );
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
.block {
  margin-bottom: 22px;
}
</style>
