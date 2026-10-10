<!-- Issued certificate: the confirmed name on the signed template when present; print from the browser. -->
<template>
  <main class="wrap">
    <header class="head rise" style="--i: 0">
      <p class="kicker">Certificate</p>
      <h1>{{ cert?.event_name || cert?.event?.name || 'Certificate' }}</h1>
      <p class="sub">
        Printed name is locked once you confirm it. Later Lounge-name edits do not change it.
      </p>
    </header>

    <p v-if="loadError" class="msg err" role="alert">{{ loadError }}</p>
    <p v-else-if="!ready" class="msg" role="status">Opening your certificate…</p>
    <p v-else-if="!cert" class="msg err" role="alert">No issued certificate with that id.</p>

    <section v-else class="slip rise" style="--i: 1">
      <div v-if="needsName" class="need">
        <p>
          This event released certificates. Confirm the name that prints. It cannot be edited here
          afterwards.
        </p>
        <form class="name-form" @submit.prevent="confirm">
          <label>
            <span>Name on the certificate</span>
            <input v-model="nameDraft" type="text" required maxlength="200" autocomplete="name" />
          </label>
          <p v-if="error" class="msg err" role="alert">{{ error }}</p>
          <button class="go" type="submit" :disabled="busy">
            {{ busy ? 'Saving…' : 'Confirm name' }}
          </button>
        </form>
      </div>

      <template v-else>
        <p class="printed">
          Printed name <b>{{ printed }}</b>
        </p>
        <div v-if="url" class="sheet">
          <img
            :src="url"
            :alt="`Certificate for ${printed}, ${cert.event_name || cert.event?.name}`"
          />
        </div>
        <p v-else-if="drawError" class="msg err" role="alert">
          The certificate image could not load.
          <button type="button" class="link" @click="draw">Try again</button>
        </p>
        <p v-else class="msg" role="status">Pressing the seal…</p>
        <div class="acts">
          <a
            class="go"
            :class="{ off: !url }"
            :href="url || undefined"
            :download="url ? `sundarbans-${cert.id}.png` : undefined"
            :aria-disabled="url ? undefined : 'true'"
          >
            Download
          </a>
          <button type="button" class="ghost" :disabled="!url" @click="printPage">Print</button>
          <a
            class="ghost"
            :href="`/#/verify-certificate?id=${encodeURIComponent(cert.id)}`"
            target="_blank"
            rel="noopener noreferrer"
            >Verify link</a
          >
        </div>
      </template>
    </section>
  </main>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import { renderCertificate, renderOnTemplate } from '../components/lounge/cert.js';
import { commKey, commOf, longDate } from '../components/lounge/events.js';
import { member } from '../components/lounge/fixtures.js';
import { confirmPrintedName, hydrateLounge, lounge } from '../components/lounge/session.js';
import { certName } from '../components/lounge/state.js';
import { auth, errorText } from '../lib/auth.js';

const route = useRoute();
const ready = ref(false);
const loadError = ref('');
const nameDraft = ref('');
const busy = ref(false);
const error = ref('');
const url = ref('');
const drawError = ref(false);

const cert = computed(
  () => lounge.certificates.find((c) => String(c.id) === String(route.params.id)) ?? null
);
const printed = computed(() => cert.value?.certificate_name || certName.value);
const needsName = computed(() => {
  const c = cert.value;
  if (!c) return false;
  const event = lounge.events.find((e) => e.id === c.event_id);
  return !printed.value && (event?.needs_certificate_name || c.needs_certificate_name);
});

onMounted(async () => {
  if (!auth.session || !auth.profile) return;
  try {
    if (!lounge.ready) await hydrateLounge();
    nameDraft.value = preferredOrRoster();
  } catch (err) {
    loadError.value = errorText(err);
  } finally {
    ready.value = true;
  }
});

function preferredOrRoster() {
  return member.preferred_name || member.full_name || '';
}

async function confirm() {
  busy.value = true;
  error.value = '';
  try {
    await confirmPrintedName(nameDraft.value);
  } catch (err) {
    error.value = errorText(err);
  } finally {
    busy.value = false;
  }
}

async function draw() {
  const c = cert.value;
  if (!c || !printed.value) return;
  drawError.value = false;
  try {
    if (c.template_url) {
      url.value = await renderOnTemplate({
        templateUrl: c.template_url,
        name: printed.value,
        certId: c.id,
      });
      return;
    }
    const event = c.event ||
      lounge.events.find((e) => e.id === c.event_id) || { name: c.event_name };
    url.value = await renderCertificate({
      name: printed.value,
      roll: member.roll,
      region: member.region.name,
      cert: { ...c, event, minutes: c.minutes || 20 },
      when: event.starts_at ? longDate(event) : c.event_date || '',
      commKey: commKey(event),
      commLabel: commOf(event).label,
      art: commOf(event).art,
    });
  } catch {
    drawError.value = true;
  }
}

watch([cert, printed], ([c, name]) => {
  url.value = '';
  if (c && name) draw();
});

function printPage() {
  window.print();
}
</script>

<style scoped>
.wrap {
  max-width: 920px;
  margin: 0 auto;
  padding: 40px 24px 72px;
  display: grid;
  gap: 22px;
}
.kicker {
  margin: 0 0 8px;
  font-size: 12px;
  font-weight: 650;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--mari-ink);
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
  max-width: 62ch;
  color: var(--ink-2);
  font-size: 17px;
  line-height: 1.45;
}
.slip {
  display: grid;
  gap: 14px;
  padding: 22px 24px 18px;
  border-radius: var(--r);
  background: var(--card);
  border: 1px solid var(--line);
  box-shadow: var(--shadow);
}
.msg {
  margin: 0;
  color: var(--ink-2);
  font-size: 15px;
}
.msg.err {
  color: var(--verm);
}
.printed {
  margin: 0;
  color: var(--ink-2);
}
.sheet img {
  width: 100%;
  height: auto;
  border-radius: 8px;
}
.acts {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}
.go,
.ghost,
.link {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 44px;
  padding: 0 18px;
  border-radius: 99px;
  font-size: 15px;
  font-weight: 650;
  text-decoration: none;
}
.go {
  border: 0;
  background: var(--mari);
  color: var(--on-mari);
}
.go.off {
  opacity: 0.55;
  pointer-events: none;
}
.ghost {
  border: 1.5px solid var(--line-strong);
  background: transparent;
  color: var(--ink);
}
.link {
  border: 0;
  background: none;
  color: var(--mari-ink);
  min-height: auto;
  padding: 0;
}
.name-form {
  display: grid;
  gap: 10px;
}
.name-form input {
  height: 44px;
  padding: 0 14px;
  border: 1.5px solid var(--line-strong);
  border-radius: 12px;
  background: var(--paper);
  color: var(--ink);
}
@media print {
  .acts,
  .kicker,
  .sub {
    display: none;
  }
}
</style>
