<!-- Local entry for now; replace the button action with Google sign-in later. -->
<template>
  <main class="sign-in" :class="{ leaving }" :aria-busy="busy">
    <section aria-labelledby="login-h">
      <LoungeDoor entry>
        <h1 id="login-h">The lounge</h1>
        <button type="button" class="enter" :disabled="busy" @click="signIn">
          {{ busy ? 'Entering…' : 'Sign in' }}
          <LineIcon name="arrow" />
        </button>
        <p v-if="error" class="error" role="alert">{{ error }}</p>
      </LoungeDoor>
    </section>
  </main>
</template>

<script setup>
import { nextTick, onBeforeUnmount, ref } from 'vue';
import { useRouter } from 'vue-router';
import LoungeDoor from '../components/site/LoungeDoor.vue';
import LineIcon from '../components/site/LineIcon.vue';

const router = useRouter();
document.documentElement.classList.add('sign-in-active');
const busy = ref(false);
const leaving = ref(false);
const error = ref('');
let disposed = false;
let fadeTimer;

const reducedMotion = () => matchMedia('(prefers-reduced-motion: reduce)').matches;

async function signIn() {
  if (busy.value) return;
  busy.value = true;
  error.value = '';
  try {
    // Load both scenes before fading, so a slow chunk cannot leave an empty screen.
    const [, , state] = await Promise.all([
      import('./LoungePage.vue'),
      import('../components/lounge/WelcomeTour.vue'),
      import('../components/lounge/state.js'),
    ]);
    if (disposed) return;
    // Deliberately replay on every sign-in until the backend owns the seen flag.
    state.resetTour();
    if (document.startViewTransition && !reducedMotion()) await crossfadeToLounge();
    else await fadeToLounge();
  } catch {
    if (!disposed) fail();
  }
}

// The door and the lounge's first frame cross-dissolve in one 900ms overlap. Fading the sign-in
// out first would leave a dark gap before the tour could appear.
async function crossfadeToLounge() {
  const root = document.documentElement;
  root.classList.add('sign-in-cross');
  try {
    const transition = document.startViewTransition(() =>
      router.push({ path: '/lounge' }).then(() => nextTick())
    );
    // A transition skipped by a hidden tab or a quick second navigation still swaps the page.
    transition.ready.catch(() => {});
    await transition.finished;
  } catch {
    if (!disposed) fail();
  } finally {
    root.classList.remove('sign-in-cross');
  }
}

// No View Transitions (or reduced motion): fade the sign-in out, then arrive with the lounge's
// own fade-in.
async function fadeToLounge() {
  leaving.value = true;
  const enter = async () => {
    try {
      await router.push({ path: '/lounge', state: { signIn: true } });
    } catch {
      if (!disposed) fail();
    }
  };
  if (reducedMotion()) await enter();
  else fadeTimer = setTimeout(enter, 900);
}

function fail() {
  busy.value = leaving.value = false;
  error.value = 'Couldn’t open the lounge. Please try again.';
}

onBeforeUnmount(() => {
  disposed = true;
  document.documentElement.classList.remove('sign-in-active');
  clearTimeout(fadeTimer);
});
</script>

<style scoped>
.sign-in {
  display: grid;
  place-items: center;
  min-height: calc(100svh - var(--nav-h));
  padding: 32px 24px;
  background: #15120e;
  color: #f3ebdd;
  opacity: 1;
  transition: opacity 900ms ease-in-out;
}
.sign-in.leaving {
  opacity: 0;
  pointer-events: none;
}
section {
  width: min(360px, 100%);
}
h1 {
  margin: 0 0 24px;
  font-size: clamp(32px, 4vw, 42px);
  font-weight: 750;
  letter-spacing: -0.04em;
  line-height: 1.1;
}
.enter {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  min-width: 172px;
  min-height: 48px;
  padding: 12px 24px;
  border: 0;
  border-radius: 99px;
  background: #f2a93b;
  color: #1d1915;
  font-size: 17px;
  font-weight: 700;
  box-shadow: 0 0 0 0 rgb(242 169 59 / 0.5);
  transition:
    box-shadow 0.4s,
    transform 0.3s var(--ease-spring);
}
.enter:hover:not(:disabled) {
  box-shadow: 0 0 0 8px rgb(242 169 59 / 0.16);
  transform: translateY(-1px);
}
.enter:disabled {
  cursor: wait;
}
.enter:focus-visible {
  outline: 2px solid #ffd488;
  outline-offset: 5px;
}
.enter :deep(svg) {
  width: 20px;
  height: 20px;
  transition: transform 0.3s var(--ease-spring);
}
.enter:hover:not(:disabled) :deep(svg) {
  transform: translateX(3px);
}
.error {
  max-width: 28ch;
  margin: 18px 0 0;
  color: #ffd488;
}
::selection {
  background: #f2a93b;
  color: #1d1915;
}
@media (max-width: 760px) {
  .sign-in {
    padding-bottom: calc(32px + 72px + env(safe-area-inset-bottom));
  }
}
@media (prefers-reduced-motion: reduce) {
  .sign-in {
    transition: none;
  }
}
</style>

<style>
/* The sign-in → lounge cross-dissolve; the same 900ms as the fallback fade. */
:root.sign-in-cross::view-transition-old(root),
:root.sign-in-cross::view-transition-new(root) {
  animation-duration: 900ms;
  animation-timing-function: ease-in-out;
}
</style>
