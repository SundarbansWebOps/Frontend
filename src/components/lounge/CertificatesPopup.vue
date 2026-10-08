<!--
  My certificates: a grid of the member's certificates; tap one to see it full size in the
  same pop-up with Download and a Verify link, then Back to the grid. The name printed on
  them is locked here; a change is a request to the council (spec 002, Open).
  Opened from the profile menu (grid) or from Events (straight to one certificate). Minis are
  printed artefacts: cream paper in both themes.
-->
<template>
  <LoungeDialog ref="dlg" class="ld-wide" labelledby="cp-h" @close="emit('close')">
    <div class="cp">
      <template v-if="!current">
        <p class="gp-kicker">Your profile</p>
        <h2 id="cp-h" ref="headEl" class="ed-h" tabindex="-1">
          My certificates <span class="gp-badge cp-n">{{ certificates.length }}</span>
        </h2>
        <p class="cp-sub">One for every event where you stayed 20 minutes or more.</p>
        <ul v-if="certificates.length" class="cp-grid">
          <li v-for="c in certificates" :key="c.id">
            <button
              type="button"
              class="mini"
              :class="commOf(c.event).cls"
              :data-id="c.id"
              @click="show(c.id)"
            >
              <span class="mini-band" aria-hidden="true"></span>
              <img class="mini-crest" :src="CREST" alt="" width="30" height="30" />
              <span class="mini-stamp" aria-hidden="true"></span>
              <img class="mini-art" :src="commOf(c.event).art" alt="" loading="lazy" />
              <span class="mini-k">Certificate of participation</span>
              <span class="mini-name">{{ c.event.name }}</span>
              <span class="mini-meta">
                <span class="mini-comm">{{ commOf(c.event).label }}</span> · {{ longDate(c.event) }}
              </span>
              <span class="mini-id tnum">{{ c.id }}</span>
            </button>
          </li>
        </ul>
        <div v-else class="ev-empty">
          <img :src="SEAL" alt="" width="160" height="160" />
          <h3>No certificates yet</h3>
          <p>Stay 20 minutes or more at an event and its certificate shows up here.</p>
        </div>
      </template>

      <template v-else>
        <button ref="backEl" type="button" class="cp-back" @click="back">
          <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M15 5 8 12l7 7" /></svg>
          All certificates
        </button>
        <p class="gp-kicker">
          <span class="ed-comm" :class="commOf(current.event).cls">{{
            commOf(current.event).label
          }}</span>
          ·
          <span class="tnum">{{ current.id }}</span>
        </p>
        <h2 id="cp-h" class="ed-h">{{ current.event.name }}</h2>
        <div v-if="!printed" class="cp-noname gp-inset">
          <p>
            Certificates print your name, and you haven't added one yet. Add it once and every
            certificate carries it.
          </p>
          <button type="button" class="gp-btn" @click="addName">Add your name</button>
        </div>
        <div v-else class="cp-cert" :class="{ ready: url }">
          <img
            v-if="url"
            :src="url"
            :alt="`Certificate of participation for ${printed}, ${current.event.name}, ${longDate(current.event)}`"
            width="1600"
            height="1130"
          />
          <p v-else-if="drawError" class="cp-cooking" role="status">
            The certificate image couldn't load.
            <button type="button" class="gp-link" @click="draw(current)">Try again</button>
          </p>
          <p v-else class="cp-cooking">Pressing the seal…</p>
        </div>

        <p v-if="printed" class="cp-name">
          <span
            >Printed name <b>{{ printed }}</b></span
          >
          <button v-if="!asked" type="button" class="gp-link" @click="asked = true">
            Request a change
          </button>
          <span v-else role="status" class="cp-asked"
            >In the live Lounge, this request goes to the council. This preview doesn't send
            it.</span
          >
        </p>

        <div v-if="printed" class="reg-acts">
          <a
            class="gp-btn is-big"
            :class="{ off: !url }"
            :href="url || undefined"
            :aria-disabled="url ? undefined : 'true'"
            :download="`sundarbans-${current.id}.png`"
          >
            <svg class="ic" viewBox="0 0 24 24" aria-hidden="true">
              <path d="M12 4v11M7 10.5l5 5 5-5M5 20h14" />
            </svg>
            Download
          </a>
          <a
            class="gp-btn is-ghost is-big"
            :href="verifyHref(current.id)"
            target="_blank"
            rel="noopener noreferrer"
          >
            Verify link <span aria-hidden="true">↗</span>
          </a>
        </div>
        <p class="cp-verify">
          Anyone can check this certificate at <span class="tnum">{{ verifyText }}</span>
        </p>
      </template>
    </div>
  </LoungeDialog>
</template>

<script setup>
import { computed, nextTick, ref, watch } from 'vue';
import CREST from '../../assets/crest.webp';
import LoungeDialog from './LoungeDialog.vue';
import { renderCertificate } from './cert.js';
import { certificates, commKey, commOf, longDate, verifyHref } from './events.js';
import { member } from './fixtures.js';
import { certName, openNameCard } from './state.js';

const props = defineProps({ start: { type: String, default: '' } });
const emit = defineEmits(['close']);

const SEAL = new URL('./art/prop-seal.webp', import.meta.url).href;
const dlg = ref(null);
const headEl = ref(null);
const backEl = ref(null);
const currentId = ref(props.start || null);
const current = computed(() => certificates.find((c) => c.id === currentId.value) ?? null);
const url = ref('');
const drawError = ref(false);
const asked = ref(false);
/* The name certificates print. Never the roll number: with no name, the detail asks for one. */
const printed = computed(() => certName.value);
const verifyText = computed(
  () => current.value && `${location.host}${verifyHref(current.value.id)}`
);

const cache = new Map();
let token = 0;
async function draw(c) {
  const mine = ++token;
  drawError.value = false;
  const key = `${c.id}|${printed.value}`;
  url.value = cache.get(key) ?? '';
  if (url.value) return;
  try {
    const png = await renderCertificate({
      name: certName.value,
      roll: member.roll,
      region: member.region.name,
      cert: c,
      when: longDate(c.event),
      commKey: commKey(c.event),
      commLabel: commOf(c.event).label,
      art: commOf(c.event).art,
    });
    cache.set(key, png);
    if (mine === token) url.value = png;
  } catch (err) {
    if (mine === token) drawError.value = true;
    console.error(err);
  }
}

watch(
  [current, printed],
  ([c, name]) => {
    asked.value = false;
    if (c && name) draw(c);
    else {
      ++token;
      url.value = '';
      drawError.value = false;
    }
  },
  { immediate: true }
);

/* Hand this pop-up's Back entry to the name card. */
function addName() {
  dlg.value?.swap();
  openNameCard();
}

async function show(id) {
  currentId.value = id;
  await nextTick();
  backEl.value?.focus();
}

async function back() {
  const from = currentId.value;
  currentId.value = null;
  await nextTick();
  const card = document.querySelector(`.cp-grid [data-id="${from}"]`);
  (card ?? headEl.value)?.focus();
}
</script>
