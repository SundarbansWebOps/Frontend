<!-- The sign-in door: Google sign-in for members on the house roster, then into the Lounge. -->
<template>
  <main id="main-content" class="sign-in" tabindex="-1" :class="{ leaving }" :aria-busy="busy">
    <section aria-labelledby="login-h">
      <LoungeDoor entry>
        <h1 id="login-h">The lounge</h1>
        <button type="button" class="enter" :disabled="busy" @click="signIn">
          {{ busy ? (auth.session ? 'Entering…' : 'Opening Google…') : label }}
          <LineIcon name="arrow" />
        </button>
        <p v-if="error || auth.error" class="error" role="alert">{{ error || auth.error }}</p>
      </LoungeDoor>
    </section>
  </main>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import LoungeDoor from '../components/site/LoungeDoor.vue';
import LineIcon from '../components/site/LineIcon.vue';
import { auth, authReady, signInWithGoogle, takeNext } from '../lib/auth.js';

const router = useRouter();
const route = useRoute();
const requestedNext = computed(() => {
  if (typeof route.query.next === 'string') return route.query.next;
  const room = ['live', 'groups', 'certificates'].includes(route.query.room)
    ? route.query.room
    : null;
  return room ? `/lounge?room=${room}` : '/lounge';
});
// Only members-only paths are honoured, so a crafted ?next= cannot send anyone off-site.
const safeNext = (p) =>
  typeof p === 'string' && /^\/(lounge|admin)(?:[/?#]|$)/.test(p) ? p : '/lounge';
const label = computed(() => (auth.session ? 'Enter the lounge' : 'Sign in with Google'));
document.documentElement.classList.add('sign-in-active');
const busy = ref(false);
const leaving = ref(false);
const error = ref('');
let disposed = false;
let fadeTimer;

const reducedMotion = () => matchMedia('(prefers-reduced-motion: reduce)').matches;

// Back from Google with a session: carry on to where the member was going.
onMounted(async () => {
  await authReady();
  const next = takeNext();
  if (!disposed && auth.session && auth.profile && next) enter(safeNext(next));
});

async function signIn() {
  if (busy.value) return;
  if (!auth.session) {
    busy.value = true;
    error.value = '';
    try {
      await signInWithGoogle(safeNext(requestedNext.value));
    } catch {
      busy.value = false;
    }
    return;
  }
  enter(safeNext(requestedNext.value));
}

async function enter(next) {
  busy.value = true;
  error.value = '';
  if (next.startsWith('/admin')) {
    router.push(next).catch(() => fail());
    return;
  }
  try {
    // Load both scenes before fading, so a slow chunk cannot leave an empty screen.
    await Promise.all([
      import('./LoungePage.vue'),
      import('../components/lounge/WelcomeTour.vue'),
      import('../components/lounge/state.js'),
    ]);
    if (disposed) return;
    if (document.startViewTransition && !reducedMotion()) await crossfadeToLounge(next);
    else await fadeToLounge(next);
  } catch {
    if (!disposed) fail();
  }
}

// The door and the lounge's first frame cross-dissolve in one 900ms overlap. Fading the sign-in
// out first would leave a dark gap before the tour could appear.
async function crossfadeToLounge(next) {
  const root = document.documentElement;
  root.classList.add('sign-in-cross');
  try {
    const transition = document.startViewTransition(() => router.push(next).then(() => nextTick()));
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
async function fadeToLounge(next) {
  leaving.value = true;
  const enter = async () => {
    try {
      const target = router.resolve(next);
      await router.push({
        path: target.path,
        query: target.query,
        hash: target.hash,
        state: { signIn: true },
      });
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
