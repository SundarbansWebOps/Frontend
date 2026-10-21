<!-- House-wide email check for any admin. One exact address, never a list: the answer says
     whether it is a student or still on the roster, and shows what the house holds for it. The
     database records every lookup in the activity log. -->
<template>
  <div>
    <form class="adm-toolbar lookup-form" novalidate @submit.prevent="search">
      <label class="adm-field grow">
        <span>Email</span>
        <input
          v-model.trim="email"
          class="adm-input"
          type="email"
          inputmode="email"
          autocomplete="off"
          autocapitalize="none"
          spellcheck="false"
          placeholder="21f1000000@ds.study.iitm.ac.in"
          maxlength="320"
          :aria-invalid="invalid ? 'true' : undefined"
          :aria-describedby="invalid ? 'lookup-invalid' : undefined"
          @input="reset"
        />
      </label>
      <button type="submit" class="adm-btn mari" :disabled="busy">
        <LineIcon name="search" />{{ busy ? 'Searching' : 'Find' }}
      </button>
    </form>
    <p v-if="invalid" id="lookup-invalid" class="adm-msg err" role="alert">{{ invalid }}</p>
    <p v-if="error" class="adm-msg err" role="alert">{{ error }}</p>

    <p v-if="busy" class="adm-note" role="status">Searching the house...</p>

    <p v-else-if="result && !result.found" class="adm-empty" role="status">
      No one in Sundarbans House uses this email.
    </p>

    <template v-else-if="result">
      <article
        v-for="card in cards"
        :key="card.kind"
        class="adm-card lookup-card"
        :aria-label="card.kind === 'student' ? 'Student' : 'Pending roster entry'"
      >
        <header class="lookup-head">
          <div class="lookup-badges">
            <span class="adm-badge" :class="card.kind === 'student' ? '' : 'mari'">{{
              card.kind === 'student' ? 'Student' : 'Pending roster'
            }}</span>
            <span
              v-if="card.kind === 'student'"
              class="adm-badge"
              :class="card.data.account_status === 'active' ? '' : 'verm'"
              >{{ card.data.account_status }}</span
            >
            <span v-if="card.data.is_super_admin" class="adm-badge mari">Super Admin</span>
          </div>
          <h2 class="lookup-region">{{ card.data.region_name || 'No region yet' }}</h2>
          <p class="lookup-who">
            <b>{{ card.data.preferred_name || card.data.full_name || 'Name not set' }}</b>
            <span>{{ card.data.email }}</span>
          </p>
          <p v-if="card.kind === 'pending'" class="adm-note lookup-wait">
            On the roster. They have not signed in with Google yet.
          </p>
        </header>

        <dl class="adm-facts">
          <div v-if="card.data.preferred_name && card.data.full_name">
            <dt>Full name</dt>
            <dd>{{ card.data.full_name }}</dd>
          </div>
          <div v-if="card.kind === 'student'">
            <dt>Roll number</dt>
            <dd class="mono">{{ card.data.roll_number || '–' }}</dd>
          </div>
          <div>
            <dt>Phone</dt>
            <dd class="mono">{{ card.data.phone || '–' }}</dd>
          </div>
          <div>
            <dt>Gender</dt>
            <dd>{{ card.data.gender || '–' }}</dd>
          </div>
          <div>
            <dt>Cohort</dt>
            <dd>{{ card.data.cohort || '–' }}</dd>
          </div>
          <template v-if="card.kind === 'student'">
            <div>
              <dt>Signed up</dt>
              <dd>{{ day(card.data.created_at) }}</dd>
            </div>
            <div>
              <dt>Last sign-in</dt>
              <dd>{{ day(card.data.last_login_at) }}</dd>
            </div>
            <div>
              <dt>Position</dt>
              <dd>{{ positionText(card.data.position) }}</dd>
            </div>
          </template>
          <template v-else>
            <div>
              <dt>Added</dt>
              <dd>{{ day(card.data.added_at) }}</dd>
            </div>
            <div>
              <dt>Added by</dt>
              <dd>{{ addedBy(card.data.added_by) }}</dd>
            </div>
          </template>
        </dl>

        <section v-if="card.kind === 'student'" class="lookup-forms" aria-label="Forms">
          <p class="adm-kicker">Forms and groups</p>
          <ul v-if="card.data.forms?.length" class="adm-list">
            <li v-for="f in card.data.forms" :key="f.response_id" class="adm-row">
              <div>
                <b>{{ f.form_title }}</b>
                <div class="adm-meta">
                  <span>{{ KIND_LABEL[f.form_kind] || f.form_kind }}</span>
                  <span v-if="f.group_label">{{ f.group_label }}</span>
                </div>
              </div>
              <span class="mono when">{{ day(f.submitted_at) }}</span>
            </li>
          </ul>
          <p v-else class="adm-note">No form responses yet.</p>
        </section>
      </article>
    </template>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, ref } from 'vue';
import LineIcon from '../site/LineIcon.vue';
import { POSITION_LABEL, lookupEmail } from '../../lib/admin.js';
import { errorText } from '../../lib/auth.js';

// Same shape the database accepts; the server checks again.
const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
const KIND_LABEL = { general: 'Form', group: 'Group form', recruitment: 'Recruitment' };

const email = ref('');
const busy = ref(false);
const error = ref('');
const invalid = ref('');
const result = ref(null);
let sequence = 0;

const cards = computed(() =>
  [
    result.value?.student && { kind: 'student', data: result.value.student },
    result.value?.pending && { kind: 'pending', data: result.value.pending },
  ].filter(Boolean)
);

const day = (iso) =>
  iso
    ? new Date(iso).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
    : '–';
const positionText = (p) =>
  !p
    ? 'None'
    : p.position === 'rc'
      ? `${POSITION_LABEL.rc}, ${p.region_name ?? ''}`
      : `${POSITION_LABEL[p.position]}, ${p.community_name ?? ''}`;
const addedBy = (a) => (a ? a.full_name || a.email : '–');

// Typing again clears the last answer, so nothing stale sits beside a new address.
function reset() {
  sequence++;
  busy.value = false;
  invalid.value = error.value = '';
  result.value = null;
}

async function search() {
  const value = email.value.toLowerCase();
  reset();
  if (!EMAIL.test(value)) {
    invalid.value = value
      ? 'Enter the full email, like name@example.com.'
      : 'Type an email to look up.';
    return;
  }
  const token = sequence;
  busy.value = true;
  try {
    const found = await lookupEmail(value);
    if (token === sequence) result.value = found;
  } catch (e) {
    if (token === sequence) error.value = errorText(e);
  } finally {
    if (token === sequence) busy.value = false;
  }
}

onBeforeUnmount(() => sequence++);
</script>

<style scoped>
.grow {
  flex: 1 1 280px;
}
.lookup-form {
  align-items: flex-end;
}
.lookup-form .adm-btn svg {
  width: 16px;
  height: 16px;
}
.lookup-card {
  margin-top: 16px;
}
.lookup-head {
  margin-bottom: 18px;
  padding-bottom: 16px;
  border-bottom: 1px solid var(--line);
}
.lookup-badges {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.lookup-region {
  margin: 10px 0 4px;
  font-size: clamp(24px, 2.6vw, 30px);
  font-weight: 750;
  letter-spacing: -0.035em;
  line-height: 1.05;
}
.lookup-who {
  display: grid;
  gap: 2px;
  margin: 0;
  font-size: 14px;
}
.lookup-who span {
  color: var(--ink-3);
  font-size: 12.5px;
  overflow-wrap: anywhere;
}
.lookup-wait {
  margin: 8px 0 0;
}
.lookup-forms {
  margin-top: 20px;
}
.when {
  font-size: 12.5px;
  color: var(--ink-3);
  white-space: nowrap;
}
</style>
