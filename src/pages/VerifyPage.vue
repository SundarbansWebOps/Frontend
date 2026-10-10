<!--
  Verify a certificate: type the ID printed on it, get the record back with a rubber stamp.
  Looks the ID up in public/data/certificates.json; the PDF itself lives on Google Drive.
-->
<template>
  <main class="wrap">
    <header class="head rise" style="--i: 0">
      <h1>Verify a certificate</h1>
      <p class="sub">
        Every certificate the house issues carries an ID. Type it below to check the record.
      </p>
    </header>

    <form class="slip rise" style="--i: 1" @submit.prevent="verify">
      <label for="cert-id">Certificate ID</label>
      <div class="field">
        <input
          id="cert-id"
          v-model="certificateId"
          class="mono"
          type="text"
          placeholder="SH2024001"
          autocomplete="off"
          autocapitalize="characters"
          spellcheck="false"
          :disabled="loading"
        />
        <button type="submit" class="go" :disabled="loading || !certificateId.trim()">
          <span v-if="!loading">Verify</span>
          <span v-else class="dots" aria-label="Checking"><i /><i /><i /></span>
        </button>
      </div>
      <p class="note">Nothing you type is stored.</p>
    </form>

    <div aria-live="polite">
      <Transition name="slip" mode="out-in">
        <section v-if="result" :key="result.id" class="record ok" aria-label="Certificate record">
          <span class="stamp" aria-hidden="true">Verified</span>
          <p class="kicker">{{ certType === 'department' ? 'Department' : 'Event' }} certificate</p>
          <h2>{{ result.name }}</h2>
          <p class="for">
            {{ certType === 'department' ? result.department : result.event }}
          </p>
          <dl>
            <div v-for="f in fields" :key="f.label">
              <dt>{{ f.label }}</dt>
              <dd :class="{ mono: f.mono }">{{ f.value }}</dd>
            </div>
          </dl>
          <div v-if="hasCertificateFile" class="acts">
            <a :href="certificateViewUrl(result)" target="_blank" rel="noopener" class="btn">
              <LineIcon name="cert" /> View certificate
            </a>
            <a
              :href="certificateDownloadUrl(result)"
              target="_blank"
              rel="noopener"
              class="btn ghost"
            >
              Download PDF
            </a>
          </div>
          <p v-else-if="!result.valid" class="note">
            The certificate file hasn’t been uploaded yet.
          </p>
        </section>

        <section v-else-if="errorMsg" :key="errorMsg" class="record miss">
          <span class="stamp" aria-hidden="true">Not found</span>
          <h2>{{ missTitle }}</h2>
          <p>{{ errorMsg }}</p>
        </section>
      </Transition>
    </div>
  </main>
</template>

<script setup>
import { computed, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import LineIcon from '../components/site/LineIcon.vue';
import { verifyCertificate } from '../lib/lounge.js';

const certificateId = ref('');
const loading = ref(false);
const result = ref(null);
const errorMsg = ref('');
const missTitle = ref('');
const route = useRoute();
let request = 0;

// The printed link opens this hash route with its ID already checked.
watch(
  () => route.query.id,
  (id) => {
    certificateId.value = typeof id === 'string' ? id : '';
    verify();
  },
  { immediate: true }
);

// certificates.json does not store an explicit "type" field.
// Infer it from which fields are actually present on the record,
// so old records without "type" still classify correctly.
const certType = computed(() => {
  if (!result.value) return null;
  if (result.value.type) return result.value.type;
  return result.value.event ? 'event' : 'department';
});

const fields = computed(() => {
  const c = result.value;
  if (!c) return [];
  if (c.valid) {
    return [
      { label: 'Certificate ID', value: c.id, mono: true },
      { label: 'Issued', value: c.issued_at || c.date },
    ].filter((f) => f.value);
  }
  const dept = certType.value === 'department';
  return [
    { label: 'Certificate ID', value: c.id, mono: true },
    { label: 'Issued', value: c.date },
    { label: 'Category', value: c.category },
    { label: dept ? 'Rank' : 'Role', value: dept ? c.rank : c.role },
    { label: 'Tenure', value: c.tenure },
  ].filter((f) => f.value);
});

/** True when we can open a PDF on Drive (local /certificates PDFs removed from repo). */
const hasCertificateFile = computed(() => {
  const c = result.value;
  if (!c) return false;
  return Boolean(c.driveUrl || c.driveFileId);
});

/** Google Drive view URL only (T-16). */
function certificateViewUrl(cert) {
  if (!cert) return null;
  if (cert.driveUrl) return cert.driveUrl;
  if (cert.driveFileId) {
    return `https://drive.google.com/file/d/${encodeURIComponent(cert.driveFileId)}/view`;
  }
  return null;
}

/** Direct download via Drive export when we have a file id. */
function certificateDownloadUrl(cert) {
  if (!cert) return null;
  if (cert.driveFileId) {
    return `https://drive.google.com/uc?export=download&id=${encodeURIComponent(cert.driveFileId)}`;
  }
  if (cert.driveUrl) {
    const m = String(cert.driveUrl).match(/\/file\/d\/([^/]+)/);
    if (m) {
      return `https://drive.google.com/uc?export=download&id=${encodeURIComponent(m[1])}`;
    }
    return cert.driveUrl;
  }
  return null;
}

async function verify() {
  const mine = ++request;
  const id = certificateId.value.trim();
  result.value = null;
  errorMsg.value = '';
  if (!id) {
    loading.value = false;
    return;
  }
  loading.value = true;

  try {
    const cert = await verifyCertificate(id);
    if (mine !== request) return;
    if (cert && cert.valid) {
      result.value = {
        id: cert.id,
        event: cert.event_name,
        name: cert.event_name,
        issued_at: cert.issued_at,
        date: cert.issued_at,
        valid: true,
        type: 'event',
      };
    } else {
      missTitle.value = 'No certificate with that ID';
      errorMsg.value = `We couldn’t find “${id}”. Check the ID printed on your certificate and try again.`;
    }
  } catch {
    if (mine !== request) return;
    missTitle.value = 'Couldn’t check right now';
    errorMsg.value = 'The certificate records didn’t load. Check your connection and try again.';
  }

  if (mine === request) loading.value = false;
}
</script>

<style scoped>
.wrap {
  max-width: 760px;
  margin: 0 auto;
  padding: 40px 24px 72px;
  display: grid;
  gap: 22px;
}
h1 {
  margin: 0;
  font-size: clamp(34px, 4.4vw, 48px);
  font-weight: 750;
  letter-spacing: -0.04em;
  line-height: 0.95;
}
.sub {
  margin: 12px 0 0;
  max-width: 52ch;
  color: var(--ink-2);
  font-size: 17px;
  line-height: 1.45;
}

/* The form is a paper slip with a perforated stub edge. */
.slip {
  position: relative;
  display: grid;
  gap: 10px;
  padding: 22px 24px 18px;
  border-radius: var(--r);
  background: var(--card);
  border: 1px solid var(--line);
  box-shadow: var(--shadow);
}
.slip::before {
  content: '';
  position: absolute;
  inset: 12px auto 12px -1px;
  width: 2px;
  background: repeating-linear-gradient(var(--paper) 0 6px, transparent 6px 12px);
}
label {
  font-size: 12.5px;
  font-weight: 650;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--ink-2);
}
.field {
  display: flex;
  gap: 10px;
}
input {
  flex: 1 1 auto;
  min-width: 0;
  height: 52px;
  padding: 0 16px;
  border-radius: 12px;
  border: 1.5px solid var(--line-strong);
  background: var(--paper);
  color: var(--ink);
  font-size: 19px;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  transition: border-color 0.2s;
}
input::placeholder {
  color: var(--ink-3);
  opacity: 0.6;
}
input:focus {
  outline: none;
  border-color: var(--mari);
  box-shadow: 0 0 0 4px var(--mari-soft);
}
.go {
  min-width: 112px;
  height: 52px;
  padding: 0 22px;
  border: 0;
  border-radius: 12px;
  background: var(--mari);
  color: var(--on-mari);
  font-size: 16px;
  font-weight: 700;
  transition:
    transform 0.25s var(--ease-spring),
    opacity 0.2s;
}
.go:hover:not(:disabled) {
  transform: translateY(-1px);
}
.go:disabled {
  opacity: 0.55;
  cursor: default;
}
.dots {
  display: inline-flex;
  gap: 5px;
}
.dots i {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: currentColor;
  animation: bob 0.9s var(--ease-out) infinite;
}
.dots i:nth-child(2) {
  animation-delay: 0.12s;
}
.dots i:nth-child(3) {
  animation-delay: 0.24s;
}
@keyframes bob {
  50% {
    transform: translateY(-4px);
    opacity: 0.5;
  }
}
.note {
  margin: 0;
  color: var(--ink-3);
  font-size: 13.5px;
}

/* The record: a card with a rubber stamp that lands a beat after it appears. */
.record {
  position: relative;
  overflow: hidden;
  padding: 26px 26px 22px;
  border-radius: var(--r);
  background: var(--card);
  border: 1px solid var(--line);
  box-shadow: var(--shadow);
}
.kicker {
  margin: 0 0 6px;
  font-size: 12.5px;
  font-weight: 650;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--mari-ink);
}
.record h2 {
  margin: 0;
  max-width: calc(100% - 130px);
  font-size: clamp(26px, 3.4vw, 34px);
  font-weight: 750;
  letter-spacing: -0.03em;
  line-height: 1.05;
}
.for {
  margin: 8px 0 0;
  color: var(--ink-2);
  font-size: 17px;
}
dl {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 14px 24px;
  margin: 22px 0 0;
  padding-top: 18px;
  border-top: 1px dashed var(--line-strong);
}
dt {
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--ink-3);
}
dd {
  margin: 3px 0 0;
  font-size: 16px;
  font-weight: 600;
}
.acts {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 22px;
}
.btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 44px;
  padding: 0 18px;
  border-radius: 99px;
  background: var(--ink);
  color: var(--paper);
  font-size: 15px;
  font-weight: 650;
  text-decoration: none;
  transition: transform 0.25s var(--ease-spring);
}
.btn:hover {
  transform: translateY(-1px);
}
.btn.ghost {
  background: transparent;
  color: var(--ink);
  border: 1.5px solid var(--line-strong);
}
.btn .ic {
  width: 18px;
  height: 18px;
}
.record.miss p {
  margin: 8px 0 0;
  max-width: 48ch;
  color: var(--ink-2);
  font-size: 16px;
  line-height: 1.45;
}
.stamp {
  --c: var(--verm);
  position: absolute;
  top: 22px;
  right: 20px;
  padding: 6px 12px;
  border: 2.5px solid var(--c);
  border-radius: 8px;
  color: var(--c);
  font-family: var(--mono);
  font-size: 14px;
  font-weight: 700;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  transform: rotate(-9deg);
  mix-blend-mode: multiply;
  opacity: 0.9;
  animation: stamp 0.5s var(--ease-spring) 0.25s both;
}
:root[data-theme='dark'] .stamp {
  mix-blend-mode: normal;
}
.ok .stamp {
  --c: var(--mari-ink);
}
@keyframes stamp {
  from {
    opacity: 0;
    transform: rotate(-18deg) scale(1.9);
  }
}

.slip-enter-active {
  transition:
    opacity 0.35s,
    transform 0.5s var(--ease-out);
}
.slip-leave-active {
  transition: opacity 0.15s;
}
.slip-enter-from {
  opacity: 0;
  transform: translateY(14px);
}
.slip-leave-to {
  opacity: 0;
}

@media (max-width: 760px) {
  .wrap {
    padding: 24px 16px 40px;
  }
  .field {
    flex-direction: column;
  }
  .go {
    width: 100%;
  }
  .record {
    padding: 22px 18px 18px;
  }
  .record h2 {
    max-width: none;
    padding-top: 36px;
  }
  .stamp {
    top: 16px;
    right: 14px;
  }
}
</style>
