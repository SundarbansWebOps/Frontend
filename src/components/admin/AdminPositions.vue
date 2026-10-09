<!-- Positions (Super Admin): one RC per region, a Head and Co-Head per community. Revoking or
     giving a position is a request another Super Admin approves; give one from the Students tab. -->
<template>
  <div class="grid">
    <div>
      <p class="adm-kicker">Regional Coordinators</p>
      <ul class="adm-list">
        <li v-for="r in lookups.regions" :key="r.id" class="adm-row">
          <div>
            <b>{{ r.name }}</b>
            <div class="adm-meta">
              <span v-if="rcOf(r.id)"
                >{{ rcOf(r.id).member.full_name }} · since {{ day(rcOf(r.id).started_at) }}</span
              >
              <span v-else class="adm-badge">vacant</span>
            </div>
          </div>
          <button
            v-if="rcOf(r.id)"
            type="button"
            class="adm-btn ghost small"
            @click="ask(rcOf(r.id))"
          >
            Revoke
          </button>
        </li>
      </ul>
    </div>
    <div>
      <p class="adm-kicker">Community leads</p>
      <ul class="adm-list">
        <template v-for="c in lookups.communities" :key="c.id">
          <li v-for="p in ['head', 'co_head']" :key="`${c.id}-${p}`" class="adm-row">
            <div>
              <b>{{ c.name }} · {{ POSITION_LABEL[p] }}</b>
              <div class="adm-meta">
                <span v-if="leadOf(c.id, p)">{{ leadOf(c.id, p).member.full_name }}</span>
                <span v-else class="adm-badge">vacant</span>
              </div>
            </div>
            <button
              v-if="leadOf(c.id, p)"
              type="button"
              class="adm-btn ghost small"
              @click="ask(leadOf(c.id, p))"
            >
              Revoke
            </button>
          </li>
        </template>
      </ul>
      <p class="adm-note spaced">
        To fill a vacant post, open the student on the Students tab and choose Give a position.
      </p>
    </div>
    <p v-if="error" class="adm-msg err wide" role="alert">{{ error }}</p>
    <p v-if="notice" class="adm-msg ok wide" role="status">{{ notice }}</p>

    <AdminDialog v-if="target" ref="dlg" title="Revoke position" @close="target = null">
      <form class="adm-form" @submit.prevent="submit">
        <p class="adm-note wide">
          {{ target.member.full_name }} stops being {{ POSITION_LABEL[target.position] }} once
          another Super Admin approves.
        </p>
        <label class="adm-field wide">
          <span>Why</span>
          <textarea v-model.trim="reason" class="adm-input" required maxlength="2000" />
        </label>
        <p v-if="formError" class="adm-msg err wide" role="alert">{{ formError }}</p>
        <div class="wide row-end">
          <button type="submit" class="adm-btn mari" :disabled="busy">Send for approval</button>
        </div>
      </form>
    </AdminDialog>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue';
import AdminDialog from './AdminDialog.vue';
import { errorText } from '../../lib/auth.js';
import { POSITION_LABEL, listPositions, requestPosition } from '../../lib/admin.js';

defineProps({ lookups: { type: Object, required: true } });
const emit = defineEmits(['changed']);

const positions = ref([]);
const error = ref('');
const notice = ref('');
const target = ref(null);
const reason = ref('');
const formError = ref('');
const busy = ref(false);
const dlg = ref(null);

const rcOf = (regionId) =>
  positions.value.find((p) => p.position === 'rc' && p.region_id === regionId);
const leadOf = (communityId, position) =>
  positions.value.find((p) => p.position === position && p.community_id === communityId);
const day = (iso) =>
  new Date(iso).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });

async function load() {
  try {
    positions.value = await listPositions();
  } catch (e) {
    error.value = errorText(e);
  }
}
onMounted(load);

function ask(p) {
  target.value = p;
  reason.value = '';
  formError.value = '';
}

async function submit() {
  busy.value = true;
  formError.value = '';
  try {
    await requestPosition(target.value.member.id, 'revoke', null, null, reason.value);
    notice.value = 'Request sent. Another Super Admin has to approve it.';
    dlg.value?.close();
    emit('changed');
  } catch (e) {
    formError.value = errorText(e);
  } finally {
    busy.value = false;
  }
}
</script>

<style scoped>
.grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 18px 24px;
  align-items: start;
}
.wide {
  grid-column: 1 / -1;
}
.spaced {
  margin-top: 14px;
}
.row-end {
  display: flex;
  justify-content: flex-end;
}
@media (max-width: 900px) {
  .grid {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
