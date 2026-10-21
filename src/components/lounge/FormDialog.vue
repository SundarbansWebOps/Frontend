<!-- Member form in the existing Lounge paper dialog. -->
<template>
  <LoungeDialog ref="dlg" labelledby="ff-h" @close="emit('close')">
    <form class="evd-form" @submit.prevent="send">
      <p class="gp-kicker">{{ kicker }}</p>
      <h2 id="ff-h" class="evd-h">{{ form.group_label || form.title }}</h2>
      <p v-if="form.group_purpose || form.description" class="evd-desc">
        {{ form.group_purpose || form.description }}
      </p>
      <p v-if="rejected" class="evd-plain" role="status">
        <b>Not approved.</b>
        {{ form.review_reason || 'The admins could not approve this one.' }}
        Fill it in again below and send it for another look.
      </p>
      <p v-else-if="form.review_status === 'pending'" class="evd-small" role="status">
        Under review.
      </p>
      <p v-if="locked && !isSuperAdmin && !invite" class="evd-done">
        Your application is saved. Sending this form is not WhatsApp admission.
      </p>
      <FormFields
        v-else-if="canViewFields"
        ref="fieldsEl"
        v-model:save-phone="savePhone"
        :fields="form.fields || []"
        :disabled="previewOnly || locked || done"
      />
      <p v-if="previewOnly" class="evd-plain" role="status">
        Preview only. {{ unavailableMessage }}
      </p>
      <p v-else-if="!canSubmit && !locked" class="evd-plain" role="status">
        {{ unavailableMessage }}
      </p>
      <p v-if="error" class="ff-err" role="alert">{{ error }}</p>
      <p v-if="invite" class="ff-invite" role="status">
        <strong>Saved. One step left.</strong>
        Open the invite and request to join. An admin adds you after checking.
      </p>
      <p v-else-if="done" class="ff-invite" role="status">
        Saved. If this form has a WhatsApp group, the invite appears after the database confirms
        your response. An admin still checks membership before they add you.
      </p>
      <div class="evd-acts">
        <button
          v-if="!locked && !done && canSubmit"
          type="submit"
          class="gp-btn is-big"
          :disabled="busy"
        >
          {{ busy ? 'Sending…' : rejected ? 'Send again' : submitLabel }}
        </button>
        <a
          v-if="invite"
          class="gp-btn is-big"
          :href="invite"
          target="_blank"
          rel="noopener noreferrer"
          >Open WhatsApp invite <span aria-hidden="true">→</span></a
        >
        <button type="button" class="gp-btn is-ghost" @click="dlg?.close()">
          {{ done || locked ? 'Back to the river' : 'Back' }}
        </button>
      </div>
    </form>
  </LoungeDialog>
</template>

<script setup>
import { computed, ref } from 'vue';
import { errorText, isSuperAdmin } from '../../lib/auth.js';
import { formUnavailableMessage, isLocked, reviewOf } from '../../lib/lounge.js';
import { member } from './fixtures.js';
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
const done = ref(false);
/* Submitted and not rejected: final. A rejected response can be filled in again. */
const locked = computed(() => isLocked(props.form));
/* The dialog holds the form as it was when opened, so a resend ends the rejected state here. */
const rejected = computed(() => !done.value && reviewOf(props.form) === 'rejected');
const canSubmit = computed(() => props.form.accepting_responses ?? props.form.is_open ?? false);
const previewOnly = computed(() => isSuperAdmin.value && !canSubmit.value);
const canViewFields = computed(() => canSubmit.value || isSuperAdmin.value);
const unavailableMessage = computed(() =>
  formUnavailableMessage(props.form, member.region_id, member.cohort)
);
const fieldsEl = ref(null);
const savePhone = ref(false);
const busy = ref(false);
const error = ref('');
const invite = ref('');

async function send() {
  if (busy.value || locked.value || !canSubmit.value) return;
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
