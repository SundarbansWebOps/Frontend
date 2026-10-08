<!--
  One event's pop-up: its community's painted figures standing on Home's river, what and when,
  then one action. Live: Join (opens the Meet). Upcoming: Register: lounge-a's questions
  (Raja liked them) in B's register sheet (the event in one line, plain fields, pill choices),
  then "You're in" with the member's own lantern (night) or kite (day) rising. Registering is
  one-way: there is no unregister. Past: the member's attendance and, if earned, their
  certificate.
-->
<template>
  <LoungeDialog ref="dlg" labelledby="ed-h" @close="emit('close')">
    <div class="evd" :class="[commOf(event).cls, `s-${st}`, step]">
      <div class="evd-art" :style="{ '--plate': `url('${plate}')` }" aria-hidden="true">
        <img :src="commOf(event).art" alt="" />
      </div>

      <!-- Info -->
      <template v-if="step === 'info'">
        <p class="evd-kick gp-kicker" :class="{ 'is-live': st === 'live' }">
          <template v-if="st === 'live'">Live now · </template>
          <span :class="{ 'evd-comm': st !== 'live' }">{{ commOf(event).label }}</span>
          <template v-if="event.type"> · {{ event.type }}</template>
        </p>
        <h2 id="ed-h" class="evd-h">{{ event.name }}</h2>
        <p class="evd-when">
          <span>{{ spanOf(event) }}</span>
          <span class="sep" aria-hidden="true">·</span>
          <span>{{ event.platform }}</span>
        </p>
        <p class="evd-desc">{{ event.description }}</p>

        <div v-if="st === 'live'" class="evd-air gp-inset">
          <p class="gp-title">On air now</p>
          <p class="gp-meta">
            Started {{ ago(event.starts_at) }} · <b>{{ endsIn(event) }}</b>
          </p>
          <a
            class="gp-btn is-big"
            :href="event.meet_link"
            target="_blank"
            rel="noopener noreferrer"
          >
            Join on Meet <span aria-hidden="true">→</span>
          </a>
          <p class="evd-small">Stay 20 minutes and it counts as attended.</p>
        </div>

        <div v-else-if="st === 'upcoming'" class="evd-act">
          <p v-if="isRegistered(event)" class="evd-done">
            <span class="evd-tick" aria-hidden="true">
              <svg viewBox="0 0 24 24"><path d="m5 12.5 4.2 4L19 7" /></svg>
            </span>
            <span
              ><b>You're registered.</b> The Join button shows up in your Lounge when it starts,
              {{ until(event.starts_at) }}.</span
            >
          </p>
          <template v-else>
            <button type="button" class="gp-btn is-big" @click="step = 'form'">Register</button>
            <p class="evd-small">Starts {{ until(event.starts_at) }}.</p>
          </template>
        </div>

        <div v-else class="evd-act">
          <template v-if="mark?.kind === 'attended'">
            <p class="evd-done">
              <span class="evd-tick" aria-hidden="true">
                <svg viewBox="0 0 24 24"><path d="m5 12.5 4.2 4L19 7" /></svg>
              </span>
              <span><b>You attended.</b> You were in the call for {{ mark.minutes }} minutes.</span>
            </p>
            <button v-if="cert" type="button" class="gp-btn is-big" @click="toCert">
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <circle cx="12" cy="9" r="5.5" />
                <path d="m8.5 13.5-1.8 7 5.3-2.6 5.3 2.6-1.8-7" />
              </svg>
              View certificate
            </button>
          </template>
          <p v-else-if="mark?.kind === 'early'" class="evd-plain">
            You were in the call for {{ mark.minutes }} minutes. A certificate needs 20, so this one
            has none.
          </p>
          <p v-else-if="mark?.kind === 'missed'" class="evd-plain">
            You registered but didn't join this one.
          </p>
          <p v-else-if="event.attendees" class="evd-plain">
            {{ event.attendees }} members came to this one.
          </p>
          <p v-else class="evd-plain">This event has ended.</p>
        </div>
      </template>

      <!-- Register: B's sheet -->
      <template v-else-if="step === 'form'">
        <p class="evd-kick gp-kicker">Register</p>
        <h2 id="ed-h" class="evd-h">{{ event.name }}</h2>
        <p class="evd-sub">
          <b>{{ spanOf(event) }}</b> · {{ until(event.starts_at) }}
        </p>
        <form class="evd-form" @submit.prevent="submit">
          <label>
            <span>Your name <small>so the hosts know who is coming</small></span>
            <input
              ref="nameEl"
              v-model="form.name"
              type="text"
              required
              pattern=".*\S.*"
              title="Enter your name"
              autocomplete="name"
              maxlength="60"
            />
          </label>
          <label>
            <span>Roll number</span>
            <input :value="member.roll" type="text" readonly />
          </label>
          <fieldset>
            <legend>Been to a house event before?</legend>
            <label class="evd-opt"
              ><input v-model="form.first" type="radio" value="no" /> This is my first</label
            >
            <label class="evd-opt"
              ><input v-model="form.first" type="radio" value="yes" /> Yes</label
            >
          </fieldset>
          <label>
            <span>Anything you want the hosts to cover? <small>optional</small></span>
            <textarea v-model="form.ask" rows="2" maxlength="300"></textarea>
          </label>
          <label class="evd-check">
            <input v-model="form.remind" type="checkbox" /> Remind me in the house WhatsApp group
          </label>
          <p class="evd-final">
            Registering is final. It can't be undone, so check the date first.
          </p>
          <div class="evd-acts">
            <button type="submit" class="gp-btn is-big">Register</button>
            <button type="button" class="gp-btn is-ghost" @click="step = 'info'">Back</button>
          </div>
        </form>
      </template>

      <!-- Registered -->
      <div v-else class="evd-sent" role="status">
        <span class="evd-lamp" :class="{ 'is-kite': mode === 'day' }" aria-hidden="true">
          <span v-if="mode === 'night'" class="evd-halo"></span>
          <img :src="mode === 'night' ? LANTERN.src : KITE_MINE.src" alt="" />
        </span>
        <h2 id="ed-h" class="evd-h">{{ youreIn }}</h2>
        <p>
          <b>{{ event.name }}</b> starts {{ until(event.starts_at) }}. The Join button shows up in
          your Lounge then. Stay 20 minutes and you get a certificate.
        </p>
        <button ref="doneEl" type="button" class="gp-btn is-ghost" @click="dlg?.close()">
          Back to the river
        </button>
      </div>
    </div>
  </LoungeDialog>
</template>

<script setup>
import { computed, nextTick, reactive, ref, watch } from 'vue';
import { KITE_MINE, LANTERN } from './home/art.js';
import LoungeDialog from './LoungeDialog.vue';
import {
  ago,
  certOf,
  commOf,
  endsIn,
  isRegistered,
  markOf,
  register,
  spanOf,
  status,
  until,
} from './events.js';
import { member } from './fixtures.js';
import { firstName, mode, shownName } from './state.js';

/* The member's own lantern and kite: Home's art (home/art.js). */

const props = defineProps({
  event: { type: Object, required: true },
  start: { type: String, default: 'info' },
  /* Home's plate for the current theme: the figures stand on the same river. */
  plate: { type: String, default: '' },
});
const emit = defineEmits(['close', 'cert']);

const dlg = ref(null);
const nameEl = ref(null);
const doneEl = ref(null);
const st = computed(() => status(props.event));
const mark = computed(() => markOf(props.event));
const cert = computed(() => certOf(props.event));

/* Already registered: never show the form again. */
const step = ref(
  props.start === 'form' && !isRegistered(props.event) && st.value === 'upcoming' ? 'form' : 'info'
);
const form = reactive({ name: shownName.value, first: 'no', ask: '', remind: true });
const youreIn = computed(() => {
  const f = form.name.trim().split(' ')[0] || firstName.value;
  return f ? `You're in, ${f}.` : "You're in.";
});

watch(step, async (s) => {
  await nextTick();
  if (s === 'form') nameEl.value?.focus();
  if (s === 'done') doneEl.value?.focus();
});
if (step.value === 'form') nextTick(() => nameEl.value?.focus());

function submit() {
  /* An event can start while its registration sheet is open. Return to its current
     state rather than showing a success for a registration the store rejected. */
  if (st.value !== 'upcoming') {
    step.value = 'info';
    return;
  }
  if (!form.name.trim()) return;
  register(props.event);
  step.value = 'done';
}

function toCert() {
  emit('cert', cert.value.id);
  dlg.value?.swap();
}
</script>
