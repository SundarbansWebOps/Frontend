<!-- Member form in the existing Lounge paper dialog. -->
<template>
  <LoungeDialog ref="dlg" labelledby="ff-h" @close="emit('close')">
    <form class="evd-form" @submit.prevent="send">
      <p class="gp-kicker">{{ kicker }}</p>
      <h2 id="ff-h" class="evd-h">{{ form.group_label || form.title }}</h2>
      <p v-if="form.group_purpose || form.description" class="evd-desc">
        {{ form.group_purpose || form.description }}
      </p>
      <p v-if="form.submitted" class="evd-done">
        Your application is saved. Sending this form is not WhatsApp admission.
      </p>
      <FormFields
        v-else-if="canSubmit"
        ref="fieldsEl"
        v-model:save-phone="savePhone"
        :fields="form.fields || []"
      />
      <p v-else-if="!form.submitted" class="evd-plain" role="status">
        This form is not accepting responses.
      </p>
      <p v-if="error" class="ff-err" role="alert">{{ error }}</p>
      <p v-if="invite" class="ff-invite" role="status">
        WhatsApp invite:
        <a :href="invite" target="_blank" rel="noopener noreferrer">Open the group</a>. Request
        entry there. An admin checks house membership (and region, for regional groups) before they
        add you. Sending this form is not admission.
      </p>
      <p v-else-if="done" class="ff-invite" role="status">
        Saved. If this form has a WhatsApp group, the invite appears after the database confirms
        your response. An admin still checks membership before they add you.
      </p>
      <div class="evd-acts">
        <button
          v-if="!form.submitted && !done && canSubmit"
          type="submit"
          class="gp-btn is-big"
          :disabled="busy"
        >
          {{ busy ? 'Sending…' : submitLabel }}
        </button>
        <button type="button" class="gp-btn is-ghost" @click="dlg?.close()">
          {{ done || form.submitted ? 'Back to the river' : 'Back' }}
        </button>
      </div>
    </form>
  </LoungeDialog>
</template>

<script setup>
import { computed, ref } from 'vue';
import { errorText } from '../../lib/auth.js';
import FormFields from './FormFields.vue';
import LoungeDialog from './LoungeDialog.vue';
import { fetchInvite, submitLoungeForm } from './session.js';

const props = defineProps({
  form: { type: Object, required: true },
  submitLabel: { type: String, default: 'Send' },
  kicker: { type: String, default: 'Form' },
});
const emit = defineEmits(['close', 'done']);

const dlg = ref(null);
const canSubmit = computed(() => props.form.accepting_responses ?? props.form.is_open ?? false);
const fieldsEl = ref(null);
const savePhone = ref(false);
const busy = ref(false);
const error = ref('');
const done = ref(false);
const invite = ref('');

async function send() {
  if (busy.value || props.form.submitted || !canSubmit.value) return;
  if (!(await fieldsEl.value?.validate())) return;
  busy.value = true;
  error.value = '';
  try {
    const answers = fieldsEl.value?.answers() ?? {};
    const result = await submitLoungeForm(props.form.id, answers, savePhone.value);
    done.value = true;
    invite.value = result?.invite_url || '';
    if (!invite.value && result?.response_id) {
      invite.value = (await fetchInvite(props.form.id).catch(() => '')) || '';
    }
    emit('done', result);
  } catch (err) {
    error.value = errorText(err);
  } finally {
    busy.value = false;
  }
}
</script>
