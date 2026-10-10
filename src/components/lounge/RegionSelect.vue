<!-- First region pick (no region yet) or a later correction request. -->
<template>
  <LoungeDialog ref="dlg" labelledby="rg-h" @close="emit('close')">
    <form class="pe" @submit.prevent="save">
      <p class="gp-kicker">Your region</p>
      <h2 id="rg-h" class="ed-h">{{ heading }}</h2>
      <p class="pe-cert">{{ help }}</p>
      <label class="pe-field">
        <span>Region</span>
        <select v-model="regionId" required>
          <option value="">Choose your region</option>
          <option v-for="r in lounge.regions" :key="r.id" :value="String(r.id)">
            {{ r.name }}
          </option>
        </select>
      </label>
      <label v-if="!first" class="pe-field">
        <span>Why the change</span>
        <textarea v-model="reason" rows="3" required maxlength="2000"></textarea>
      </label>
      <p v-if="pending" class="pe-cert" role="status">
        Your request is {{ pending.status }}. The saved region stays
        {{ member.region.name || 'unset' }} until it is approved.
      </p>
      <p v-else-if="sameRegion" class="pe-cert" role="status">
        This is already your saved region. Choose another region to request a correction.
      </p>
      <p v-if="error" class="ff-err" role="alert">{{ error }}</p>
      <div class="reg-acts">
        <button
          type="submit"
          class="gp-btn is-big"
          :disabled="busy || (!first && (!!pending || sameRegion))"
        >
          {{ busy ? 'Saving…' : first ? 'Save region' : 'Request change' }}
        </button>
        <button type="button" class="gp-btn is-ghost is-big" @click="dlg?.close()">Cancel</button>
      </div>
    </form>
  </LoungeDialog>
</template>

<script setup>
import { computed, ref } from 'vue';
import { errorText } from '../../lib/auth.js';
import { member } from './fixtures.js';
import LoungeDialog from './LoungeDialog.vue';
import {
  chooseInitialRegion,
  lounge,
  pendingRegionRequest,
  submitRegionRequest,
} from './session.js';

const emit = defineEmits(['close']);
const dlg = ref(null);
const first = computed(() => !member.region_id);
const sameRegion = computed(
  () => !first.value && Number(regionId.value) === Number(member.region_id)
);
const heading = computed(() =>
  first.value ? 'Which region are you in?' : 'Ask to change your region'
);
const help = computed(() =>
  first.value
    ? 'The four students without an allocation pick once. Later changes need approval.'
    : 'The saved region does not change until your current-region coordinator or the Upper House Council approves it.'
);
const pending = pendingRegionRequest;
const regionId = ref(member.region_id ? String(member.region_id) : '');
const reason = ref('');
const busy = ref(false);
const error = ref('');

async function save() {
  if (busy.value) return;
  busy.value = true;
  error.value = '';
  try {
    const id = Number(regionId.value);
    if (first.value) await chooseInitialRegion(id);
    else await submitRegionRequest(id, reason.value);
    dlg.value?.close();
  } catch (err) {
    error.value = errorText(err);
  } finally {
    busy.value = false;
  }
}
</script>
