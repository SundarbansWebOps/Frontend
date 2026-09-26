<!--
  PROTOTYPE — the members' lounge, seen from outside. The door swings open as it scrolls in
  and warm light spills onto the floor; the rooms inside are listed beside it. On House it is
  a teaser that leads to the Lounge tab; on the Lounge tab it is the page's opening.
-->
<template>
  <div ref="root" class="lounge" :class="{ open }">
    <div class="copy">
      <p class="eyebrow mono">Members only</p>
      <component :is="teaser ? 'h2' : 'h1'" id="lounge-h">The lounge</component>
      <p class="lede">
        Everything live happens inside, for Sundarbans members. Sign in with your IITM student email
        — it’s checked against the house roster.
      </p>
      <ul class="rooms">
        <li v-for="(r, i) in ROOMS" :key="r.key" :style="{ '--i': i }">
          <component
            :is="teaser ? 'a' : 'span'"
            class="room"
            :href="teaser ? `?page=lounge` : undefined"
            @click="teaser && ($event.preventDefault(), nav.go('lounge', r.key))"
          >
            <LineIcon :name="r.icon" />
            <span>
              <strong>{{ r.title }}<em v-if="r.planned" class="mono">planned</em></strong>
              <small>{{ r.desc }}</small>
            </span>
          </component>
        </li>
      </ul>
      <div class="ctas">
        <button v-if="teaser" type="button" class="enter" @click="nav.go('lounge')">
          Take the tour
          <LineIcon name="arrow" />
        </button>
        <button
          type="button"
          :class="teaser ? 'ghost' : 'enter'"
          @click="toast('Sign-in arrives with the Supabase wiring')"
        >
          Sign in with IITM email
          <LineIcon v-if="!teaser" name="arrow" />
        </button>
      </div>
    </div>

    <div class="doorway" aria-hidden="true">
      <div class="arch">
        <div class="light">
          <i v-for="m in MOTES" :key="m.k" class="mote" :style="m.style" />
        </div>
        <div class="door">
          <i class="panel p1" />
          <i class="panel p2" />
          <i class="knob" />
        </div>
      </div>
      <div class="spill" />
    </div>
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue';
import LineIcon from './LineIcon.vue';
import { nav, toast } from './store.js';

defineProps({ teaser: Boolean });

const ROOMS = [
  { key: 'live', icon: 'live', title: 'Live events', desc: 'This week’s schedule and join links' },
  {
    key: 'owl',
    icon: 'moon',
    title: 'Night Owl rooms',
    desc: 'Late-night study rooms, English and Hindi',
  },
  { key: 'groups', icon: 'people', title: 'Regional groups', desc: 'Your region’s WhatsApp group' },
  { key: 'board', icon: 'trophy', title: 'Leaderboard', desc: 'Top performers of the month' },
  {
    key: 'certificates',
    icon: 'cert',
    title: 'Certificates',
    desc: 'Generate a participation certificate for events you took part in',
    planned: true,
  },
];

// Dust in the light: scattered positions, speeds and drift, fixed per mote.
const MOTES = Array.from({ length: 16 }, (_, k) => ({
  k,
  style: {
    left: `${((k * 37 + 11) % 88) + 6}%`,
    animationDuration: `${5 + ((k * 13) % 5)}s`,
    animationDelay: `${-((k * 7) % 11) * 0.6}s`,
    '--dx': `${((k * 29) % 21) - 10}px`,
  },
}));

const root = ref(null);
const open = ref(false);
const io = new IntersectionObserver(
  ([en]) => {
    if (en.isIntersecting) {
      setTimeout(() => (open.value = true), 250);
      io.disconnect();
    }
  },
  { threshold: 0.4 }
);
onMounted(() => io.observe(root.value));
onBeforeUnmount(() => io.disconnect());
</script>

<style scoped>
/* Always night in here, whatever the site theme. */
.lounge {
  --l-bg: #15120e;
  --l-ink: #f3ebdd;
  --l-ink-2: #b9ac9a;
  --l-line: #2e271f;
  position: relative;
  display: grid;
  grid-template-columns: minmax(0, 1.2fr) minmax(0, 1fr);
  gap: 40px;
  padding: clamp(24px, 4vw, 44px);
  border-radius: 28px;
  background: var(--l-bg);
  color: var(--l-ink);
  overflow: hidden;
}
:root[data-theme='dark'] .lounge {
  --l-bg: #0b0907;
  box-shadow: inset 0 0 0 1px #2e271f;
}
.eyebrow {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin: 0;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: #f2a93b;
}
.eyebrow :deep(svg) {
  width: 15px;
  height: 15px;
}
#lounge-h {
  margin: 8px 0 8px;
  font-size: clamp(32px, 4vw, 46px);
  font-weight: 750;
  letter-spacing: -0.045em;
  line-height: 1;
}
.lede {
  margin: 0 0 20px;
  max-width: 50ch;
  font-size: 15.5px;
  line-height: 1.55;
  color: var(--l-ink-2);
}
.rooms {
  display: grid;
  gap: 4px;
  margin: 0 0 22px;
  padding: 0;
  list-style: none;
}
.room {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 9px 10px;
  border-radius: 12px;
  opacity: 0.35;
  transform: translateX(-8px);
  transition:
    opacity 0.6s var(--ease-out),
    transform 0.6s var(--ease-out),
    background 0.4s;
  transition-delay: calc(500ms + var(--i) * 110ms);
}
.open .room {
  opacity: 1;
  transform: none;
}
.rooms :deep(svg) {
  flex: none;
  width: 22px;
  height: 22px;
  margin-top: 1px;
  color: #f2a93b;
}
.rooms strong {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 15.5px;
  font-weight: 650;
}
.rooms em {
  padding: 1px 7px;
  border: 1px dashed #6f6255;
  border-radius: 99px;
  font-style: normal;
  font-size: 10.5px;
  font-weight: 500;
  color: var(--l-ink-2);
}
.rooms small {
  display: block;
  font-size: 13.5px;
  color: var(--l-ink-2);
}
a.room {
  color: inherit;
  text-decoration: none;
}
a.room:hover {
  background: rgb(242 169 59 / 0.1);
}
.ctas {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}
.ghost {
  padding: 13px 18px;
  border: 1.5px solid #4a4035;
  border-radius: 99px;
  background: none;
  color: var(--l-ink);
  font-size: 15px;
  font-weight: 600;
  transition: border-color 0.2s;
}
.ghost:hover {
  border-color: #f2a93b;
}
.enter {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 13px 20px;
  border: 0;
  border-radius: 99px;
  background: #f2a93b;
  color: #1d1915;
  font-size: 15px;
  font-weight: 700;
  box-shadow: 0 0 0 0 rgb(242 169 59 / 0.5);
  transition:
    box-shadow 0.4s,
    transform 0.3s var(--ease-spring);
}
.enter:hover {
  box-shadow: 0 0 0 8px rgb(242 169 59 / 0.16);
  transform: translateY(-1px);
}
.enter :deep(svg) {
  width: 18px;
  height: 18px;
  transition: transform 0.3s var(--ease-spring);
}
.enter:hover :deep(svg) {
  transform: translateX(3px);
}
.enter:focus-visible {
  outline-color: #f2a93b;
  outline-offset: 3px;
}

/* ---- The door --------------------------------------------------------------------- */
.doorway {
  position: relative;
  display: grid;
  justify-items: center;
  align-content: end;
  perspective: 1200px;
}
.arch {
  position: relative;
  width: min(250px, 80%);
  aspect-ratio: 5 / 8;
  border-radius: 999px 999px 6px 6px;
  background: #0b0907;
  box-shadow:
    0 0 0 10px #2a211a,
    0 0 0 11px #3a3027;
  transform-style: preserve-3d;
}
.light {
  position: absolute;
  inset: 0;
  border-radius: inherit;
  overflow: hidden;
  background: radial-gradient(120% 90% at 50% 100%, #ffd488 0%, #f2a93b 38%, #9a5200 78%, #3a2410);
  opacity: 0.25;
  transition: opacity 1.6s var(--ease-out);
}
.open .light {
  opacity: 1;
}
.mote {
  position: absolute;
  bottom: -6px;
  width: 3px;
  height: 3px;
  border-radius: 50%;
  background: #fff4dc;
  opacity: 0;
  animation: mote 6s linear infinite;
}
.open .mote {
  opacity: 0.8;
}
@keyframes mote {
  from {
    transform: translate(0, 0);
  }
  to {
    transform: translate(var(--dx), -380px);
  }
}
.door {
  position: absolute;
  inset: 0;
  border-radius: inherit;
  background: linear-gradient(90deg, #3e2d1f, #4a3624 60%, #3a2a1c);
  transform-origin: left center;
  transition: transform 1.8s cubic-bezier(0.25, 0.9, 0.2, 1);
  box-shadow: inset -6px 0 12px rgb(0 0 0 / 0.35);
}
.open .door {
  transform: rotateY(-74deg);
}
.panel {
  position: absolute;
  left: 16%;
  right: 16%;
  border: 2px solid rgb(0 0 0 / 0.25);
  border-radius: 999px 999px 4px 4px;
}
.p1 {
  top: 8%;
  height: 40%;
}
.p2 {
  top: 54%;
  height: 38%;
  border-radius: 4px;
}
.knob {
  position: absolute;
  right: 12%;
  top: 52%;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #f2a93b;
  box-shadow: 0 0 8px rgb(242 169 59 / 0.6);
}
.spill {
  width: min(250px, 80%);
  height: 90px;
  margin-top: -1px;
  background: linear-gradient(180deg, rgb(242 169 59 / 0.55), transparent);
  clip-path: polygon(0 0, 100% 0, 100% 0, 0 0);
  transition: clip-path 1.8s cubic-bezier(0.25, 0.9, 0.2, 1);
  filter: blur(2px);
}
.open .spill {
  clip-path: polygon(0 0, 100% 0, 150% 100%, -50% 100%);
}

@media (max-width: 860px) {
  .lounge {
    grid-template-columns: minmax(0, 1fr);
    gap: 22px;
  }
  .doorway {
    grid-row: 1;
  }
  .arch {
    width: 150px;
  }
  .spill {
    width: 150px;
    height: 50px;
  }
}
@media (prefers-reduced-motion: reduce) {
  .door,
  .spill,
  .light,
  .room {
    transition: none;
  }
  .mote {
    animation: none;
  }
}
</style>
