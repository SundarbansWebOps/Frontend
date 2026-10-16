<!--
  Help desk: a short note to the House team, delivered by the House's Formspree form
  (the same one the previous site's contact page used). The footer and the old /contact link land here.
-->
<template>
  <main class="wrap">
    <header class="head">
      <p class="eyebrow mono rise" style="--i: 0">Help</p>
      <h1 class="rise" style="--i: 1">Write to the House</h1>
      <p class="sub rise" style="--i: 2">
        Stuck on resources, events, certificates or anything else? Send us a note and someone from
        the team will reply to your email.
      </p>
    </header>

    <section class="card rise" style="--i: 3" aria-labelledby="help-form-h">
      <h2 id="help-form-h" class="visually-hidden">Help form</h2>

      <div v-if="sent" class="done" role="status">
        <p class="done-h">Message sent.</p>
        <p class="done-p">Thanks for writing in. We’ll reply to the email you gave.</p>
        <button type="button" class="back" @click="sent = false">Send another</button>
      </div>

      <form v-else novalidate @submit.prevent="submit">
        <div class="pair">
          <label class="field">
            <span>Your name</span>
            <input v-model.trim="form.name" name="name" autocomplete="name" required />
          </label>
          <label class="field">
            <span>Student email</span>
            <input
              v-model.trim="form.email"
              type="email"
              name="email"
              autocomplete="email"
              placeholder="you@ds.study.iitm.ac.in"
              required
            />
          </label>
        </div>
        <label class="field">
          <span>Topic</span>
          <select v-model="form.subject" name="subject">
            <option v-for="t in TOPICS" :key="t">{{ t }}</option>
          </select>
        </label>
        <label class="field">
          <span>Message</span>
          <textarea
            v-model.trim="form.message"
            name="message"
            rows="6"
            placeholder="Tell us what you need help with"
            required
          ></textarea>
        </label>
        <!-- Formspree's honeypot: hidden from people, filled by bots. -->
        <input
          v-model="form._gotcha"
          class="trap"
          name="_gotcha"
          tabindex="-1"
          autocomplete="off"
        />

        <p v-if="error" class="err" role="alert">{{ error }}</p>
        <button class="cta" type="submit" :disabled="sending">
          {{ sending ? 'Sending…' : 'Send message' }}
        </button>
      </form>
    </section>
  </main>
</template>

<script setup>
import { reactive, ref } from 'vue';

const ENDPOINT = 'https://formspree.io/f/mgorwpak';
const TOPICS = [
  'General question',
  'Study resources',
  'Events',
  'Certificates',
  'Website issue',
  'Other',
];

const blank = () => ({ name: '', email: '', subject: TOPICS[0], message: '', _gotcha: '' });
const form = reactive(blank());
const sending = ref(false);
const sent = ref(false);
const error = ref('');

async function submit() {
  error.value = '';
  if (!form.name || !form.message || !/^\S+@\S+\.\S+$/.test(form.email)) {
    error.value = 'Please add your name, a valid email and a message.';
    return;
  }
  sending.value = true;
  try {
    const res = await fetch(ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify({ ...form, _subject: `Help: ${form.subject}` }),
    });
    if (res.ok) {
      Object.assign(form, blank());
      sent.value = true;
    } else {
      const data = await res.json().catch(() => null);
      error.value = data?.errors?.[0]?.message || 'Something went wrong. Please try again.';
    }
  } catch {
    error.value = 'Couldn’t reach the server. Check your connection and try again.';
  } finally {
    sending.value = false;
  }
}
</script>

<style scoped>
.wrap {
  display: grid;
  justify-items: center;
  gap: 22px;
  max-width: 1240px;
  margin: 0 auto;
  padding: 40px 24px 80px;
}
.head {
  display: grid;
  justify-items: center;
  gap: 10px;
  text-align: center;
}
.eyebrow {
  margin: 0;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.14em;
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
  margin: 2px 0 0;
  max-width: 52ch;
  color: var(--ink-2);
  font-size: 15px;
  line-height: 1.5;
}
.card {
  width: 100%;
  max-width: 620px;
  padding: 24px;
  border: 1px solid var(--line);
  border-radius: var(--r);
  background: var(--card);
  box-shadow: var(--shadow);
}
form {
  display: grid;
  gap: 16px;
}
.pair {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: 16px;
}
.field {
  display: grid;
  gap: 6px;
}
.field span {
  font-size: 13px;
  font-weight: 600;
  color: var(--ink-2);
}
input,
select,
textarea {
  width: 100%;
  padding: 11px 14px;
  border: 1.5px solid var(--line-strong);
  border-radius: 12px;
  background: var(--paper);
  color: var(--ink);
  font: inherit;
  font-size: 15px;
  transition: border-color 0.2s var(--ease-out);
}
textarea {
  resize: vertical;
  min-height: 140px;
}
input:focus,
select:focus,
textarea:focus {
  border-color: var(--mari-ink);
}
.trap {
  position: absolute;
  left: -9999px;
  width: 1px;
  height: 1px;
  opacity: 0;
}
.err {
  margin: 0;
  color: var(--verm);
  font-size: 14px;
}
.cta,
.back {
  justify-self: start;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 11px 22px;
  border-radius: 99px;
  font: inherit;
  font-size: 15px;
  font-weight: 650;
  cursor: pointer;
  transition:
    background 0.2s,
    transform 0.25s var(--ease-spring);
}
.cta {
  border: 0;
  background: var(--mari);
  color: var(--on-mari);
}
.cta:disabled {
  opacity: 0.6;
  cursor: progress;
}
.back {
  border: 1.5px solid var(--line-strong);
  background: none;
  color: var(--ink);
}
.cta:hover:not(:disabled),
.back:hover {
  transform: translateY(-1px);
}
.done {
  display: grid;
  gap: 8px;
}
.done-h {
  margin: 0;
  font-size: 20px;
  font-weight: 700;
}
.done-p {
  margin: 0 0 8px;
  color: var(--ink-2);
}
@media (max-width: 560px) {
  .wrap {
    padding: 24px 16px 90px;
  }
  .card {
    padding: 18px;
  }
  .pair {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
