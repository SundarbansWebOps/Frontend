<!--
  Top bar on desktop, thumb-reach tab bar on phones. Five destinations; the
  members-only Lounge is set apart as a lit doorway at the end. The doorway knows the
  visitor: "Sign in" goes straight to Google, "Lounge" goes straight in, and the avatar menu
  (signed in) holds Sign out so the Lounge itself doesn't need one.
-->
<template>
  <header class="nav">
    <div class="in">
      <RouterLink class="brand" to="/" aria-label="Sundarbans House, home">
        <img :src="CREST" alt="" width="34" height="34" />
        <span class="word">
          <b>Sundarbans</b>
          <small>IIT Madras BS · House</small>
        </span>
      </RouterLink>
      <nav class="links" aria-label="Main">
        <RouterLink v-for="l in LINKS" :key="l.to" :to="l.to" active-class="on">
          <span>{{ l.label }}</span>
        </RouterLink>
      </nav>
      <div class="acts">
        <a
          class="lounge"
          :class="{ on: route.path === '/login', busy }"
          href="#/login"
          :aria-busy="busy"
          @click="enterLounge"
        >
          <i class="glow" aria-hidden="true" />
          <span>{{ loungeLabel }}</span>
          <small v-if="!signedIn">members</small>
        </a>
        <div v-if="signedIn" ref="meEl" class="me-wrap">
          <button
            type="button"
            class="me"
            aria-haspopup="menu"
            :aria-expanded="menuOpen"
            :aria-label="callName ? `Your account, ${callName}` : 'Your account'"
            @click="menuOpen = !menuOpen"
          >
            <img
              v-if="avatarUrl"
              :src="avatarUrl"
              alt=""
              referrerpolicy="no-referrer"
              @error="avatarFailed"
            />
            <span v-else-if="initials" aria-hidden="true">{{ initials }}</span>
            <img v-else :src="CREST" alt="" />
          </button>
          <div v-if="menuOpen" class="menu" role="menu" @keydown.esc="menuOpen = false">
            <p v-if="callName" class="who">{{ callName }}</p>
            <RouterLink to="/lounge" role="menuitem" @click="menuOpen = false">
              <LineIcon name="door" />
              Open the Lounge
            </RouterLink>
            <RouterLink v-if="canAdmin" to="/admin" role="menuitem" @click="menuOpen = false">
              <LineIcon name="people" />
              Admin lounge
            </RouterLink>
            <button type="button" role="menuitem" class="out" @click="leave">
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <path d="M14 4h4a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-4" />
                <path d="M10 8 6 12l4 4M6 12h10" />
              </svg>
              Sign out
            </button>
          </div>
        </div>
        <button
          type="button"
          class="theme"
          :class="{ dark: theme === 'dark' }"
          :aria-label="theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'"
          :title="theme === 'dark' ? 'Light mode' : 'Dark mode'"
          @click="toggleTheme($event)"
        >
          <svg viewBox="0 0 24 24" aria-hidden="true">
            <mask id="nav-moon">
              <rect width="24" height="24" fill="#fff" />
              <circle class="bite" cx="24" cy="4" r="7" fill="#000" />
            </mask>
            <circle class="orb" cx="12" cy="12" r="5" mask="url(#nav-moon)" />
            <g class="rays">
              <path
                d="M12 1.8v2.4M12 19.8v2.4M1.8 12h2.4M19.8 12h2.4M4.8 4.8l1.7 1.7M17.5 17.5l1.7 1.7M4.8 19.2l1.7-1.7M17.5 6.5l1.7-1.7"
              />
            </g>
          </svg>
        </button>
      </div>
    </div>
  </header>

  <nav class="tabbar" aria-label="Main">
    <RouterLink v-for="l in LINKS" :key="l.to" :to="l.to" active-class="on">
      <LineIcon :name="l.icon" />
      <span>{{ l.label }}</span>
    </RouterLink>
    <a
      class="lounge"
      :class="{ on: route.path === '/login', busy }"
      href="#/login"
      :aria-busy="busy"
      @click="enterLounge"
    >
      <LineIcon name="door" />
      <span>{{ loungeLabel }}</span>
    </a>
  </nav>
</template>

<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import CREST from '../../assets/crest.webp';
import LineIcon from './LineIcon.vue';
import { theme, toggleTheme } from '../../lib/theme.js';
import {
  auth,
  avatarFailed,
  avatarUrl,
  canAdmin,
  signedIn,
  signInWithGoogle,
  signOut,
} from '../../lib/auth.js';
import { toast } from '../../lib/store.js';

const LINKS = [
  { to: '/resources', label: 'Resources', icon: 'book' },
  { to: '/events', label: 'Events', icon: 'cal' },
  { to: '/house', label: 'House', icon: 'house' },
  { to: '/teams', label: 'Teams', icon: 'people' },
];

const route = useRoute();
const router = useRouter();
const busy = ref(false);
const menuOpen = ref(false);
const meEl = ref(null);

// Same rule as the Lounge's own avatar: the preferred name, never the roll number; the crest
// until a name is set.
const callName = computed(() => auth.profile?.preferred_name?.trim() || '');
const initials = computed(() =>
  callName.value
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0].toUpperCase())
    .join('')
);
const loungeLabel = computed(() =>
  busy.value && !signedIn.value ? 'Opening Google…' : signedIn.value ? 'Lounge' : 'Sign in'
);

// One tap in either state. Signed in: straight to the Lounge. Signed out: straight to Google,
// which brings the member back through the sign-in door and on into the Lounge. If Google
// cannot be reached, the door itself explains.
async function enterLounge(e) {
  if (e.metaKey || e.ctrlKey || e.shiftKey || e.button) return;
  e.preventDefault();
  if (busy.value) return;
  if (signedIn.value) {
    router.push('/lounge');
    return;
  }
  busy.value = true;
  try {
    await signInWithGoogle('/lounge');
  } catch {
    busy.value = false;
    router.push('/login');
  }
}

async function leave() {
  menuOpen.value = false;
  await signOut().catch(() => {});
  // A members-only page (Admin) has nothing left to show once signed out.
  if (route.meta.member) await router.push('/');
  toast('Signed out');
}

function away(e) {
  if (!meEl.value?.contains(e.target)) menuOpen.value = false;
}
function onKey(e) {
  if (e.key === 'Escape') menuOpen.value = false;
}
watch(menuOpen, (open) => {
  const op = open ? addEventListener : removeEventListener;
  op('pointerdown', away);
  op('keydown', onKey);
});
watch(
  () => route.fullPath,
  () => (menuOpen.value = false)
);
onBeforeUnmount(() => {
  removeEventListener('pointerdown', away);
  removeEventListener('keydown', onKey);
});
</script>

<style scoped>
.nav {
  position: sticky;
  top: 0;
  z-index: 50;
  height: var(--nav-h);
  background: color-mix(in srgb, var(--paper) 88%, transparent);
  backdrop-filter: saturate(1.4) blur(10px);
  border-bottom: 1px solid var(--line);
  animation: drop-in 0.6s var(--ease-out) both;
}
@keyframes drop-in {
  from {
    transform: translateY(-100%);
  }
}
.in {
  max-width: 1240px;
  height: 100%;
  margin: 0 auto;
  padding: 0 24px;
  display: flex;
  align-items: center;
  gap: 24px;
}
.brand {
  display: flex;
  align-items: center;
  gap: 10px;
  text-decoration: none;
}
.brand img {
  border-radius: 50%;
  background: #111;
}
.word {
  display: grid;
  line-height: 1.05;
}
.word b {
  font-size: 17px;
  font-weight: 750;
  letter-spacing: -0.02em;
}
.word small {
  font-size: 10.5px;
  color: var(--ink-2);
  letter-spacing: 0.02em;
}
.links {
  display: flex;
  gap: 4px;
  margin: 0 auto;
}
.links a {
  position: relative;
  padding: 8px 14px;
  border-radius: 99px;
  font-size: 14.5px;
  font-weight: 550;
  color: var(--ink-2);
  text-decoration: none;
  transition:
    color 0.2s,
    background 0.2s;
}
.links a:hover {
  color: var(--ink);
  background: var(--sunk);
}
.links a.on {
  color: var(--ink);
}

/* The lounge: always night inside, lit from within by a slow turning edge of light. */
.acts .lounge {
  position: relative;
  display: inline-flex;
  align-items: baseline;
  gap: 6px;
  padding: 9px 16px;
  border-radius: 99px;
  font-size: 14.5px;
  font-weight: 600;
  text-decoration: none;
  isolation: isolate;
  overflow: hidden;
  background: #15120e;
  color: #f6d9a8;
}
.acts .lounge::before {
  content: '';
  position: absolute;
  inset: 0;
  z-index: -1;
  border-radius: inherit;
  padding: 1.5px;
  background: conic-gradient(
    from var(--turn, 0deg),
    #f2a93b00 0deg,
    #f2a93b 70deg,
    #ffd488 100deg,
    #f2a93b00 160deg,
    #f2a93b00 360deg
  );
  -webkit-mask:
    linear-gradient(#000 0 0) content-box,
    linear-gradient(#000 0 0);
  -webkit-mask-composite: xor;
  mask-composite: exclude;
  animation: turn 4.5s linear infinite;
}
@property --turn {
  syntax: '<angle>';
  inherits: false;
  initial-value: 0deg;
}
@keyframes turn {
  to {
    --turn: 360deg;
  }
}
.acts .lounge .glow {
  position: absolute;
  inset: auto 10% -60% 10%;
  z-index: -1;
  height: 100%;
  border-radius: 50%;
  background: radial-gradient(closest-side, rgb(242 169 59 / 0.55), transparent);
  opacity: 0.55;
  transition: opacity 0.4s;
}
.acts .lounge small {
  font-size: 10.5px;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: #f2a93b;
}
.acts .lounge:hover {
  background: #1d1813;
  color: #fff4dc;
}
.acts .lounge:hover .glow,
.acts .lounge.on .glow {
  opacity: 1;
}
.links a.on::after {
  content: '';
  position: absolute;
  left: 14px;
  right: 14px;
  bottom: 2px;
  height: 2.5px;
  border-radius: 2px;
  background: var(--mari);
  animation: grow 0.6s var(--ease-out) 0.3s both;
}
@keyframes grow {
  from {
    transform: scaleX(0);
  }
}
.acts {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}

/* Theme toggle: the sun's rays fold away and a bite turns the disc into a moon. */
.theme {
  display: grid;
  place-items: center;
  width: 38px;
  height: 38px;
  padding: 0;
  border-radius: 50%;
  border: 1.5px solid var(--line-strong);
  background: transparent;
  color: var(--ink);
  cursor: pointer;
  transition:
    transform 0.25s var(--ease-spring),
    background 0.2s;
}
.theme:hover {
  background: var(--sunk);
  transform: translateY(-1px);
}
.theme:focus-visible {
  outline: 2px solid var(--mari);
  outline-offset: 2px;
}
.theme svg {
  width: 20px;
  height: 20px;
  overflow: visible;
  transition: transform 0.6s var(--ease-out);
}
.theme .orb {
  fill: currentColor;
  transform-origin: center;
  transition: r 0.5s var(--ease-spring);
}
.theme .bite {
  transition:
    cx 0.5s var(--ease-out),
    cy 0.5s var(--ease-out);
}
.theme .rays {
  fill: none;
  stroke: currentColor;
  stroke-width: 2;
  stroke-linecap: round;
  transform-origin: center;
  transition:
    transform 0.5s var(--ease-out),
    opacity 0.3s;
}
.theme.dark svg {
  transform: rotate(-40deg);
}
.theme.dark .orb {
  r: 8.5px;
}
.theme.dark .bite {
  cx: 17px;
  cy: 8px;
}
.theme.dark .rays {
  transform: scale(0.4) rotate(45deg);
  opacity: 0;
}
@media (prefers-reduced-motion: reduce) {
  .theme svg,
  .theme .orb,
  .theme .bite,
  .theme .rays {
    transition: none;
  }
}

.acts .lounge.busy,
.tabbar .lounge.busy {
  opacity: 0.75;
  pointer-events: none;
}

/* Signed in: the account avatar and its small menu (Open the Lounge, Admin, Sign out). */
.me-wrap {
  position: relative;
}
.me {
  display: grid;
  place-items: center;
  width: 38px;
  height: 38px;
  padding: 0;
  overflow: hidden;
  border-radius: 50%;
  border: 1.5px solid var(--line-strong);
  background: var(--card);
  color: var(--mari-ink);
  font: inherit;
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.02em;
  cursor: pointer;
  transition:
    transform 0.25s var(--ease-spring),
    background 0.2s;
}
.me:hover {
  background: var(--sunk);
  transform: translateY(-1px);
}
.me:focus-visible {
  outline: 2px solid var(--mari);
  outline-offset: 2px;
}
.me[aria-expanded='true'] {
  outline: 2px solid var(--mari);
  outline-offset: 2px;
}
.me img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.menu {
  position: absolute;
  top: calc(100% + 10px);
  right: 0;
  z-index: 70;
  display: grid;
  gap: 2px;
  min-width: 210px;
  padding: 8px;
  border: 1px solid var(--line);
  border-radius: 16px;
  background: var(--card);
  box-shadow: var(--shadow);
  animation: menu-in 0.22s var(--ease-out) both;
}
@keyframes menu-in {
  from {
    opacity: 0;
    transform: translateY(-6px) scale(0.98);
  }
}
.menu .who {
  margin: 0;
  padding: 8px 10px 10px;
  border-bottom: 1px solid var(--line);
  font-size: 13.5px;
  font-weight: 700;
  color: var(--ink);
}
.menu a,
.menu button {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px;
  border: 0;
  border-radius: 10px;
  background: none;
  color: var(--ink);
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  text-align: left;
  text-decoration: none;
  cursor: pointer;
}
.menu a:hover,
.menu button:hover {
  background: var(--sunk);
}
.menu :focus-visible {
  outline: 2px solid var(--mari);
  outline-offset: -2px;
}
.menu .out {
  color: var(--verm);
}
.menu .ic,
.menu svg {
  width: 18px;
  height: 18px;
  flex: none;
}
.menu .out svg {
  fill: none;
  stroke: currentColor;
  stroke-width: 1.8;
  stroke-linecap: round;
  stroke-linejoin: round;
}
@media (prefers-reduced-motion: reduce) {
  .menu {
    animation: none;
  }
}

.tabbar {
  display: none;
}

@media (min-width: 761px) and (max-width: 1020px) {
  .in {
    gap: 12px;
    padding-inline: 16px;
  }
  .links a {
    padding-inline: 10px;
  }
}

@media (max-width: 760px) {
  .links {
    display: none;
  }
  .in {
    padding: 0 16px;
    justify-content: space-between;
  }
  .acts .lounge {
    display: none;
  }
  .tabbar {
    position: fixed;
    inset: auto 0 0;
    z-index: 60;
    display: grid;
    grid-template-columns: repeat(5, minmax(0, 1fr));
    padding: 6px 8px calc(6px + env(safe-area-inset-bottom));
    background: color-mix(in srgb, var(--paper) 92%, transparent);
    backdrop-filter: blur(10px);
    border-top: 1px solid var(--line);
  }
  .tabbar a {
    display: grid;
    justify-items: center;
    gap: 3px;
    padding: 6px 0;
    border-radius: 12px;
    font-size: 11.5px;
    font-weight: 600;
    color: var(--ink-2);
    text-decoration: none;
  }
  .tabbar a.on {
    color: var(--ink);
    background: var(--mari-soft);
  }
  .tabbar .lounge {
    position: relative;
    margin: 0 2px;
    background: #15120e;
    color: #f6d9a8;
  }
  .tabbar .lounge :deep(svg) {
    color: #f2a93b;
    filter: drop-shadow(0 0 5px rgb(242 169 59 / 0.7));
  }
  .tabbar .lounge.on {
    background: #15120e;
    color: #fff4dc;
    box-shadow: inset 0 0 0 1.5px #f2a93b;
  }
}
</style>
