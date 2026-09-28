<!--
  Top bar on desktop, thumb-reach tab bar on phones. Five destinations; the
  members-only Lounge is set apart as a lit doorway at the end.
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
        <RouterLink
          v-for="l in LINKS"
          :key="l.to"
          :to="l.to"
          active-class="on"
          :class="{ lounge: l.lounge }"
        >
          <i v-if="l.lounge" class="glow" aria-hidden="true" />
          <span>{{ l.label }}</span>
          <small v-if="l.lounge">members</small>
        </RouterLink>
      </nav>
      <div class="acts">
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
        <a class="wa" :href="WHATSAPP" target="_blank" rel="noopener">
          <LineIcon name="wa" />
          <span>Join WhatsApp</span>
        </a>
      </div>
    </div>
  </header>

  <nav class="tabbar" aria-label="Main">
    <RouterLink
      v-for="l in LINKS"
      :key="l.to"
      :to="l.to"
      active-class="on"
      :class="{ lounge: l.lounge }"
    >
      <LineIcon :name="l.icon" />
      <span>{{ l.label }}</span>
    </RouterLink>
  </nav>
</template>

<script setup>
import LineIcon from './LineIcon.vue';
import { WHATSAPP } from '../../lib/courses.js';
import { theme, toggleTheme } from '../../lib/theme.js';

// Same official crest, delivered at 80px instead of the 1000px the old site pulled.
const CREST =
  'https://res.cloudinary.com/l59gy0g2/image/upload/f_auto,q_auto,w_80,c_limit/v1785911356/sundarbans/src/assets/LOGO.jpg';
const LINKS = [
  { to: '/resources', label: 'Resources', icon: 'book' },
  { to: '/events', label: 'Events', icon: 'cal' },
  { to: '/house', label: 'House', icon: 'house' },
  { to: '/teams', label: 'Teams', icon: 'people' },
  { to: '/lounge', label: 'Lounge', icon: 'door', lounge: true },
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

@media (min-width: 761px) and (max-width: 1020px) {
  .in {
    gap: 12px;
    padding-inline: 16px;
  }
  .links a {
    padding-inline: 10px;
  }
  .wa span {
    display: none;
  }
  .wa {
    padding: 9px;
    flex-shrink: 0;
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
