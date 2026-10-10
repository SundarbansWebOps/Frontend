<!--
  The members' lounge, seen from outside. The door swings open as it scrolls in and warm light
  spills onto the floor; the rooms inside are listed beside it. On House it is a teaser that leads
  to sign-in. In entry mode it is the sign-in door, closed until the member enters. With `overlay`
  it is that same door laid over the live Lounge: it starts exactly on the sign-in door's opening,
  swings open, the camera passes through, and it emits `done` once the Lounge is in view.
-->
<template>
  <div ref="root" class="lounge" :class="{ open, entry: entry || overlay, overlay }">
    <div v-if="!entry" class="copy">
      <p class="eyebrow mono">Members only</p>
      <component :is="teaser ? 'h2' : 'h1'" id="lounge-h">The lounge</component>
      <p class="lede">Everything live happens inside, for Sundarbans members.</p>
      <ul class="rooms">
        <li v-for="(r, i) in LOUNGE_ROOMS" :key="r.key" :style="{ '--i': i }">
          <a class="room" href="?page=lounge" @click.prevent="nav.go('lounge', r.key)">
            <LineIcon :name="r.icon" />
            <span>
              <strong>{{ r.title }}</strong>
              <small>{{ r.desc }}</small>
            </span>
          </a>
        </li>
      </ul>
      <div class="ctas">
        <button type="button" class="enter" @click="nav.go('login')">
          Sign in with IITM email
          <LineIcon name="arrow" />
        </button>
      </div>
    </div>

    <div class="doorway" aria-hidden="true" :style="overlay ? doorStyle : undefined">
      <div ref="arch" class="arch">
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
    <div v-if="entry && !overlay" class="entry-actions">
      <slot />
      <ul class="inside" aria-label="Inside the lounge">
        <li v-for="(r, i) in LOUNGE_ROOMS" :key="r.key" :style="{ '--i': i }">
          <LineIcon :name="r.icon" />
          {{ r.title }}
        </li>
      </ul>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import LineIcon from './LineIcon.vue';
import { LOUNGE_ROOMS } from './lounge-rooms.js';
import { nav } from '../../lib/store.js';

// rect: the opening the overlay starts on, as measured from the sign-in door (see archRect).
const props = defineProps({
  teaser: Boolean,
  entry: Boolean,
  overlay: Boolean,
  rect: { type: Object, default: null },
});
const emit = defineEmits(['done']);

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
const arch = ref(null);
const open = ref(false);
let openTimer;
let raf = 0;

const doorStyle = computed(() =>
  props.rect
    ? {
        left: `${props.rect.left}px`,
        top: `${props.rect.top}px`,
        width: `${props.rect.width}px`,
        height: `${props.rect.height}px`,
      }
    : undefined
);

// The opening as a plain box, for the overlay to start on.
function archRect() {
  const { left, top, width, height } = arch.value.getBoundingClientRect();
  return { left, top, width, height };
}

// The overlay's film, in ms from the start: the leaf swings open with a slow start (0-850); the light
// goes out as the opening clears; the camera pushes through from 600; the scene fades over 1400-1900,
// when `done` fires. It runs on requestAnimationFrame, not Web Animations or CSS animations: the
// Lounge's motion gate pauses both while the door holds the Lounge, and the door must keep moving.
const FILM_MS = 1900;
const segment = (t, from, len) => Math.min(Math.max((t - from) / len, 0), 1);
const easeInOut = (p) => (p < 0.5 ? 4 * p * p * p : 1 - Math.pow(-2 * p + 2, 3) / 2);
function playDoor() {
  const vw = document.documentElement.clientWidth;
  const vh = document.documentElement.clientHeight;
  const r = props.rect;
  // Enough to carry the opening past every corner of the viewport before the fade.
  const scale = (Math.hypot(vw, vh) / r.width) * 1.1;
  root.value.style.transformOrigin = `${r.left + r.width / 2}px ${r.top + r.height / 2}px`;
  const leaf = arch.value.querySelector('.door');
  const light = arch.value.querySelector('.light');
  const start = performance.now();
  const frame = (now) => {
    const t = now - start;
    leaf.style.transform = `rotateY(${-90 * easeInOut(segment(t, 0, 850))}deg)`;
    leaf.style.opacity = String(1 - segment(t, 850, 150));
    light.style.opacity = String(0.25 * (1 - segment(t, 0, 700)));
    root.value.style.transform = `scale(${1 + (scale - 1) * easeInOut(segment(t, 600, 1300))})`;
    root.value.style.opacity = String(1 - segment(t, 1400, 500));
    if (t < FILM_MS) raf = requestAnimationFrame(frame);
    else emit('done');
  };
  raf = requestAnimationFrame(frame);
}

defineExpose({ archRect });

// Entry mode waits for the member: the door stays closed until they press the button.
const io = new IntersectionObserver(
  ([en]) => {
    if (en.isIntersecting) {
      openTimer = setTimeout(() => (open.value = true), 250);
      io.disconnect();
    }
  },
  { threshold: 0.4 }
);
onMounted(() => {
  if (props.overlay) playDoor();
  else if (!props.entry) io.observe(root.value);
});
onBeforeUnmount(() => {
  io.disconnect();
  clearTimeout(openTimer);
  cancelAnimationFrame(raf);
});
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
:root[data-theme='dark'] .lounge:not(.entry) {
  --l-bg: #0b0907;
  box-shadow: inset 0 0 0 1px #2e271f;
}
.lounge.entry {
  grid-template-columns: minmax(0, 1fr);
  gap: 0;
  padding: 0;
  overflow: visible;
  background: transparent;
  box-shadow: none;
}
.entry .arch,
.entry .spill {
  width: min(clamp(200px, 40vh, 340px), 70vw);
}
.entry .spill {
  height: 60px;
}
.entry-actions {
  display: grid;
  justify-items: center;
  text-align: center;
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
.inside {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 10px 22px;
  margin: 26px 0 0;
  padding: 0;
  list-style: none;
  font-size: 14px;
  color: var(--l-ink-2);
}
.inside li {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  opacity: 0;
  transform: translateY(6px);
  transition:
    opacity 0.6s var(--ease-out),
    transform 0.6s var(--ease-out);
  transition-delay: calc(900ms + var(--i) * 120ms);
}
.open .inside li {
  opacity: 1;
  transform: none;
}
.inside :deep(svg) {
  width: 18px;
  height: 18px;
  color: #f2a93b;
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
/* The arch's own shadow is its frame; in the overlay --wall adds the room wall around it, so the
   opening is the only hole in it. */
.arch {
  position: relative;
  width: min(250px, 80%);
  aspect-ratio: 5 / 8;
  border-radius: 999px 999px 6px 6px;
  background: #0b0907;
  box-shadow:
    0 0 0 10px #2a211a,
    0 0 0 11px #3a3027,
    var(--wall, 0 0 transparent);
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

/* The sign-in door stands large: roughly two thirds of the space under the navbar, so it reads
   as a door you are about to walk through. */
.lounge.entry:not(.overlay) .arch {
  width: min(400px, 70vw, calc((100svh - var(--nav-h) - 230px) * 5 / 8));
}

/* ---- Overlay: the same door over the live Lounge. The scene is the whole viewport; the door's
   opening sits where the sign-in door was, so the first frame matches it. The scene's transform
   (set by playDoor) moves from the opening's centre, and the room wall is what rushes past. */
.lounge.overlay {
  position: fixed;
  inset: 0;
  z-index: 1000;
}
.lounge.overlay .doorway {
  position: absolute;
  display: block; /* a grid would size the arch's percentage height to 0 */
}
.lounge.overlay .arch {
  --wall: 0 0 0 100vmax var(--l-bg);
  width: 100%;
  height: 100%;
  aspect-ratio: auto;
  /* Nothing solid behind the leaf: the opening shows the live Lounge. */
  background: transparent;
}
.lounge.overlay .spill {
  display: none;
}
/* The film sets these every frame; a CSS transition would lag behind it. */
.lounge.overlay .door,
.lounge.overlay .light {
  transition: none;
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
  .lounge.entry:not(.overlay) .arch {
    width: min(300px, 74vw, calc((100svh - var(--nav-h) - 350px) * 5 / 8));
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
  .room,
  .inside li {
    transition: none;
  }
  .mote {
    animation: none;
  }
}
</style>
