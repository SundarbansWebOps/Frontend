<!--
  PROTOTYPE — top bar on desktop, thumb-reach tab bar on phones. Five destinations; the
  members-only Lounge is set apart as a lit doorway at the end.
-->
<template>
  <header class="nav">
    <div class="in">
      <a class="brand" href="#" @click.prevent="emit('go', 'resources')">
        <img :src="CREST" alt="" width="34" height="34" />
        <span class="word">
          <b>Sundarbans</b>
          <small>IIT Madras BS · House</small>
        </span>
      </a>
      <nav class="links" aria-label="Main">
        <a
          v-for="l in LINKS"
          :key="l.id"
          href="#"
          :class="{ on: l.id === page, lounge: l.id === 'lounge' }"
          :aria-current="l.id === page ? 'page' : undefined"
          @click.prevent="nav(l)"
        >
          <i v-if="l.id === 'lounge'" class="glow" aria-hidden="true" />
          <span>{{ l.label }}</span>
          <small v-if="l.id === 'lounge'">members</small>
        </a>
      </nav>
      <a class="wa" :href="WHATSAPP" target="_blank" rel="noopener">
        <LineIcon name="wa" />
        <span>Join WhatsApp</span>
      </a>
    </div>
  </header>

  <nav class="tabbar" aria-label="Main">
    <a
      v-for="l in LINKS"
      :key="l.id"
      href="#"
      :class="{ on: l.id === page, lounge: l.id === 'lounge' }"
      :aria-current="l.id === page ? 'page' : undefined"
      @click.prevent="nav(l)"
    >
      <LineIcon :name="l.icon" />
      <span>{{ l.label }}</span>
    </a>
  </nav>
</template>

<script setup>
import LineIcon from './LineIcon.vue';
import { toast } from './store.js';
import { WHATSAPP } from './data.js';

defineProps({ page: { type: String, default: 'resources' } });
const emit = defineEmits(['go']);
const BUILT = ['resources', 'events', 'house', 'teams', 'lounge'];
function nav(l) {
  if (BUILT.includes(l.id)) emit('go', l.id);
  else toast(`${l.label} isn’t part of this prototype`);
}

// Same official crest, delivered at 80px instead of the 1000px the live site pulls.
const CREST =
  'https://res.cloudinary.com/l59gy0g2/image/upload/f_auto,q_auto,w_80,c_limit/v1785911356/sundarbans/src/assets/LOGO.jpg';
const LINKS = [
  { id: 'resources', label: 'Resources', icon: 'book' },
  { id: 'events', label: 'Events', icon: 'cal' },
  { id: 'house', label: 'House', icon: 'house' },
  { id: 'teams', label: 'Teams', icon: 'people' },
  { id: 'lounge', label: 'Lounge', icon: 'door' },
];
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
.links a.lounge {
  display: inline-flex;
  align-items: baseline;
  gap: 6px;
  margin-left: 8px;
  padding: 8px 15px;
  isolation: isolate;
  overflow: hidden;
  background: #15120e;
  color: #f6d9a8;
}
.links a.lounge::before {
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
.links a.lounge .glow {
  position: absolute;
  inset: auto 10% -60% 10%;
  z-index: -1;
  height: 100%;
  border-radius: 50%;
  background: radial-gradient(closest-side, rgb(242 169 59 / 0.55), transparent);
  opacity: 0.55;
  transition: opacity 0.4s;
}
.links a.lounge small {
  font-size: 10.5px;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: #f2a93b;
}
.links a.lounge:hover {
  background: #1d1813;
  color: #fff4dc;
}
.links a.lounge:hover .glow,
.links a.lounge.on .glow {
  opacity: 1;
}
.links a.lounge.on::after {
  display: none;
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
.wa {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 9px 16px 9px 12px;
  border-radius: 99px;
  border: 1.5px solid var(--line-strong);
  color: var(--ink);
  font-size: 14px;
  font-weight: 600;
  text-decoration: none;
  transition:
    transform 0.25s var(--ease-spring),
    background 0.2s;
}
.wa:hover {
  background: var(--sunk);
  transform: translateY(-1px);
}
.wa .ic {
  width: 18px;
  height: 18px;
}

.tabbar {
  display: none;
}

@media (max-width: 760px) {
  .links {
    display: none;
  }
  .in {
    padding: 0 16px;
    justify-content: space-between;
  }
  .wa span {
    display: none;
  }
  .wa {
    padding: 9px;
  }
  .tabbar {
    position: fixed;
    inset: auto 0 0;
    z-index: 60;
    display: grid;
    grid-template-columns: repeat(5, 1fr);
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
  .tabbar a.lounge {
    position: relative;
    margin: 0 2px;
    background: #15120e;
    color: #f6d9a8;
  }
  .tabbar a.lounge :deep(svg) {
    color: #f2a93b;
    filter: drop-shadow(0 0 5px rgb(242 169 59 / 0.7));
  }
  .tabbar a.lounge.on {
    background: #15120e;
    color: #fff4dc;
    box-shadow: inset 0 0 0 1.5px #f2a93b;
  }
}
</style>
