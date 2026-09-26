<!--
  PROTOTYPE — Lounge room: participation certificates (PLANNED — see docs/council-questions.md).
  A try-it demo: pick a past event, type a name, and watch it written onto a SAMPLE certificate.
  The real one checks attendance first and is issued only after sign-in.
-->
<template>
  <div class="cert">
    <div class="form">
      <ol class="steps">
        <li v-for="(s, i) in STEPS" :key="s" :style="{ '--i': i }">
          <b class="mono">{{ i + 1 }}</b> {{ s }}
        </li>
      </ol>
      <label>
        <span>Event</span>
        <select v-model="eventId">
          <option v-for="e in list" :key="e.id" :value="e.id">{{ e.title }}</option>
        </select>
      </label>
      <label>
        <span>Your name</span>
        <input
          v-model="name"
          type="text"
          maxlength="40"
          placeholder="Type your name"
          autocomplete="off"
        />
      </label>
      <button
        type="button"
        class="dl"
        @click="toast('Certificates are planned — members only, after sign-in')"
      >
        Download PDF <em class="mono">planned</em>
      </button>
    </div>

    <figure class="paper" :style="{ '--wing': `var(--w-${e.wing})` }">
      <span class="wm" aria-hidden="true">SAMPLE</span>
      <svg class="corner tl" viewBox="0 0 60 60" aria-hidden="true">
        <path d="M4 56V20Q4 4 20 4h36M12 56V24q0-12 12-12h32" />
      </svg>
      <svg class="corner br" viewBox="0 0 60 60" aria-hidden="true">
        <path d="M4 56V20Q4 4 20 4h36M12 56V24q0-12 12-12h32" />
      </svg>
      <header>
        <img :src="CREST" alt="" width="40" height="40" />
        <span>
          <b>Sundarbans House</b>
          <small>IIT Madras BS degree</small>
        </span>
      </header>
      <p class="kind">Certificate of participation</p>
      <p class="pre">This is to certify that</p>
      <p :key="shownName" class="nm">
        <span>{{ shownName || 'Your Name' }}</span>
      </p>
      <p class="post">
        took part in <b>{{ e.title }}</b
        ><template v-if="e.at">, {{ fullDate(e) }}</template
        >.
      </p>
      <footer>
        <span class="sig"><i />Head, {{ WINGS[e.wing].label }}</span>
        <span class="id mono">ID {{ certId }}</span>
        <span class="sig"><i />Secretary</span>
      </footer>
    </figure>
  </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue';
import { WINGS, events, fullDate } from './events.js';
import { toast } from './store.js';

const STEPS = [
  'Sign in with your IITM email',
  'We check you took part in the event',
  'Your name goes on the signed template',
  'Anyone can verify it with the ID',
];
const CREST =
  'https://res.cloudinary.com/l59gy0g2/image/upload/f_auto,q_auto,w_80,c_limit/v1785911356/sundarbans/src/assets/LOGO.jpg';

const list = events.filter((x) => x.at).slice(0, 24);
const eventId = ref(list[0].id);
const e = computed(() => list.find((x) => x.id === eventId.value));
const name = ref('');

// The name is re-written (and re-animated) once typing pauses, not on every key.
const shownName = ref('');
let t;
watch(name, (v) => {
  clearTimeout(t);
  t = setTimeout(() => (shownName.value = v.trim()), 320);
});

// A stable-looking ID for the demo: the same name + event always gives the same one.
const certId = computed(() => {
  let h = 2166136261;
  for (const c of `${shownName.value}|${eventId.value}`)
    h = Math.imul(h ^ c.charCodeAt(0), 16777619);
  return `SB-26-${(h >>> 0).toString(36).toUpperCase().padStart(7, '0').slice(0, 7)}`;
});
</script>

<style scoped>
.cert {
  display: grid;
  grid-template-columns: minmax(0, 0.8fr) minmax(0, 1.2fr);
  gap: 26px;
  align-items: start;
}
.form {
  display: grid;
  gap: 14px;
}
.steps {
  display: grid;
  gap: 8px;
  margin: 0 0 6px;
  padding: 0;
  list-style: none;
  font-size: 14px;
  color: var(--ink-2);
}
.steps b {
  display: inline-grid;
  place-items: center;
  width: 22px;
  height: 22px;
  margin-right: 6px;
  border-radius: 50%;
  background: var(--mari-soft);
  color: #f2a93b;
  font-size: 12px;
}
label {
  display: grid;
  gap: 6px;
}
label span {
  font-size: 12.5px;
  font-weight: 600;
  color: var(--ink-2);
}
select,
input {
  width: 100%;
  padding: 12px 14px;
  border: 1.5px solid var(--line-strong);
  border-radius: 12px;
  background: var(--sunk);
  color: var(--ink);
  font: inherit;
  font-size: 15px;
}
select:focus,
input:focus {
  outline: none;
  border-color: #f2a93b;
  box-shadow: 0 0 0 4px rgb(242 169 59 / 0.15);
}
.dl {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  justify-self: start;
  padding: 12px 18px;
  border: 0;
  border-radius: 99px;
  background: #f2a93b;
  color: #1d1915;
  font-weight: 700;
}
.dl em {
  padding: 1px 7px;
  border: 1px dashed rgb(29 25 21 / 0.4);
  border-radius: 99px;
  font-style: normal;
  font-size: 11px;
  font-weight: 500;
}

/* The certificate: warm paper, always light, whatever the theme. */
.paper {
  --ink-c: #2a211a;
  position: relative;
  display: grid;
  justify-items: center;
  gap: 6px;
  aspect-ratio: 1.414;
  margin: 0;
  padding: clamp(18px, 4%, 34px);
  overflow: hidden;
  border-radius: 6px;
  background: radial-gradient(120% 90% at 50% 0%, #fffaf0, #f5ead6), #f7efe0;
  color: var(--ink-c);
  box-shadow:
    0 0 0 1px #d8c6a6,
    inset 0 0 0 10px #f7efe0,
    inset 0 0 0 11px #c9a86b,
    inset 0 0 0 14px #f7efe0,
    inset 0 0 0 15px #e0cda8,
    0 30px 60px -30px rgb(0 0 0 / 0.7);
  text-align: center;
  transform: rotate(-0.6deg);
}
.wm {
  position: absolute;
  inset: 0;
  display: grid;
  place-items: center;
  font-size: clamp(50px, 12vw, 120px);
  font-weight: 800;
  letter-spacing: 0.1em;
  color: rgb(184 52 27 / 0.08);
  transform: rotate(-18deg);
  pointer-events: none;
}
.corner {
  position: absolute;
  width: 11%;
  fill: none;
  stroke: #c9a86b;
  stroke-width: 1.6;
}
.tl {
  left: 18px;
  top: 18px;
}
.br {
  right: 18px;
  bottom: 18px;
  transform: rotate(180deg);
}
header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 4%;
}
header img {
  border-radius: 50%;
  background: #111;
}
header span {
  display: grid;
  text-align: left;
  line-height: 1.1;
}
header b {
  font-size: clamp(13px, 1.6vw, 16px);
}
header small {
  font-size: clamp(10px, 1.1vw, 11.5px);
  color: #6f6255;
}
.kind {
  margin: 3% 0 0;
  font-size: clamp(11px, 1.3vw, 13px);
  font-weight: 700;
  letter-spacing: 0.22em;
  text-transform: uppercase;
  color: #8f4a00;
}
.pre,
.post {
  margin: 0;
  font-size: clamp(11.5px, 1.35vw, 14px);
  color: #5e5449;
}
.post b {
  color: var(--ink-c);
}
/* The name writes itself in, left to right, with a gold rule drawn under it. */
.nm {
  position: relative;
  margin: 1% 0;
  padding: 0 12px 6px;
  font-size: clamp(24px, 3.8vw, 40px);
  font-weight: 700;
  font-style: italic;
  letter-spacing: -0.02em;
  line-height: 1.15;
}
.nm span {
  display: inline-block;
  animation: write 1s cubic-bezier(0.5, 0, 0.2, 1) both;
}
.nm::after {
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  height: 2px;
  background: linear-gradient(90deg, transparent, #c9a86b 15%, #c9a86b 85%, transparent);
  transform-origin: left;
  animation: rule 1.1s var(--ease-out) 0.2s both;
}
@keyframes write {
  from {
    clip-path: inset(0 100% 0 0);
  }
  to {
    clip-path: inset(0 0 0 0);
  }
}
@keyframes rule {
  from {
    transform: scaleX(0);
  }
}
footer {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  align-items: end;
  gap: 12px;
  width: 86%;
  margin-top: auto;
  margin-bottom: 3%;
  font-size: clamp(10px, 1.1vw, 12px);
  color: #6f6255;
}
.sig {
  display: grid;
  gap: 4px;
}
.sig i {
  height: 1px;
  background: #b9a585;
}
.id {
  font-size: clamp(9.5px, 1vw, 11px);
  color: #8f4a00;
}
@media (max-width: 860px) {
  .cert {
    grid-template-columns: minmax(0, 1fr);
  }
  .paper {
    order: -1;
  }
}
</style>
