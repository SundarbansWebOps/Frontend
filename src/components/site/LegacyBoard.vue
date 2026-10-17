<!--
  House-page doorway into the Legacy Board, drawn as a small Legacy page: the painted pat arch
  as the door, the board's river with a mooring post per council year, and its boat. The whole
  stage is one link. It arrives at the first council (2021, boat at the first post) and pins
  below the navbar and the section rail; scrolling on sails the boat post to post, and each post
  lights as the boat reaches it and that year's Secretary and Deputy appear in painted arches either side of the year. After the last
  council the pin releases and the page carries on; scrolling back sails the boat back. The year
  is written large: split around the door on wide screens, across the water between the posts on
  narrow ones (the same placement the Legacy page uses). Clicking walks through the door to the
  year it shows: the router's page view transition (router/index.js) is restyled so the Legacy
  page opens out of the arch's aperture while this page zooms toward it. Reduced
  motion: no pin, boat docked at the latest year, plain navigation.
-->
<template>
  <div ref="trackRef" class="track" :style="trackVars">
    <RouterLink
      ref="gateRef"
      class="gate"
      :class="{ seen }"
      :to="legacyTo"
      :aria-label="`Open the Legacy Board: every council since ${FOUNDED}`"
      :style="riverVars"
      @click="enter"
    >
      <span class="since mono" aria-hidden="true">Since {{ FOUNDED }}</span>

      <span class="side" aria-hidden="true">
        <span class="trio">
          <span
            v-for="(who, k) in [council.secretary, council.deputy]"
            :key="k"
            class="sec"
            :class="k ? 'is-dep' : 'is-sec'"
          >
            <Transition name="roll" mode="out-in">
              <span :key="council.year" class="who">
                <span class="who-photo">
                  <span class="who-ap"><img :src="who.photo" alt="" decoding="async" /></span>
                  <img
                    class="arch"
                    :src="archFrame"
                    alt=""
                    width="825"
                    height="1200"
                    decoding="async"
                  />
                </span>
                <span class="who-text">
                  <span class="who-name">{{ who.name }}</span>
                  <span class="who-role"
                    >{{ k ? 'Deputy' : 'Secretary'
                    }}<span v-if="k" class="role-long"> Secretary</span></span
                  >
                </span>
              </span>
            </Transition>
          </span>
        </span>
      </span>

      <span class="door" aria-hidden="true">
        <span ref="slotRef" class="slot">
          <span class="plaque-kicker mono">Council</span>
          <Transition name="roll" mode="out-in">
            <span :key="council.year" class="plaque">{{ council.year }}</span>
          </Transition>
          <span class="rule" />
        </span>
      </span>

      <span class="cta" aria-hidden="true">Step inside <LineIcon name="arrow" /></span>

      <span ref="riverRef" class="river" aria-hidden="true">
        <span class="river-year">
          <Transition name="roll" mode="out-in">
            <span :key="council.year" class="digits">
              <span v-for="(d, k) in String(council.year)" :key="k" :style="{ '--k': k }">{{
                d
              }}</span>
            </span>
          </Transition>
        </span>
        <span
          v-for="(c, i) in LEGACY"
          :key="c.year"
          class="post"
          :class="{ lit: i <= active, on: i === active }"
          :style="{ '--i': i }"
        >
          <img
            class="post-img"
            :src="mooringArt"
            alt=""
            width="493"
            height="1200"
            decoding="async"
          />
          <span class="tag mono">{{ c.year }}</span>
        </span>
        <span ref="boatRef" class="boat" :class="{ back: sailingBack }">
          <img class="boat-img" :src="boatArt" alt="" width="1200" height="494" decoding="async" />
        </span>
      </span>
    </RouterLink>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import LineIcon from './LineIcon.vue';
import archFrame from '../../assets/legacy/a-arch-frame.webp';
import boatArt from '../../assets/legacy/a-boat.webp';
import mooringArt from '../../assets/legacy/a-mooring.webp';
import plateDay from '../lounge/home/art/plate-day-1536.webp';
import plateNight from '../lounge/home/art/plate-night-1536.webp';
import { FOUNDED, LEGACY } from '../../data/legacy.data.js';
import { theme } from '../../lib/theme.js';

const LAST = LEGACY.length - 1;
// Post spacing along the river, as a fraction of its width (matches .post's left).
const EDGE = 0.1;
const STEP = (1 - 2 * EDGE) / LAST;
// Scroll distance per council after the first, in vh: the card stays pinned for this long a year.
const YEAR_VH = 36;

const trackRef = ref(null);
const gateRef = ref(null);
const slotRef = ref(null);
const riverRef = ref(null);
const boatRef = ref(null);
const seen = ref(false);
const active = ref(LAST);
const sailingBack = ref(false);
const council = computed(() => LEGACY[active.value]);
// Through the door is the council it shows (the first year is the page's bare URL).
const legacyTo = computed(() =>
  council.value.year === FOUNDED
    ? '/teams/legacy'
    : { path: '/teams/legacy', query: { year: String(council.value.year) } }
);
// The track holds the card's scroll run: its height is the card's plus one span per council after
// the first (the ::after spacer in the style), and the card pins to the top of it.
const trackVars = { '--span': `${YEAR_VH * LAST}vh` };
const riverVars = computed(() => ({
  '--plate': `url("${theme.value === 'dark' ? plateNight : plateDay}")`,
  '--edge': `${EDGE * 100}%`,
  '--step': `${STEP * 100}%`,
}));

const reduced = () => matchMedia('(prefers-reduced-motion: reduce)').matches;

/* Scroll progress 0→1 across the track's scroll run: 0 while the card scrolls in (the pin line
   is still below it), 1 once the track has scrolled past its pin line and the card has left the
   pin. Between, the card is pinned and the boat sails. */
let frame = 0;
let lastP = null;
function place() {
  frame = 0;
  const el = gateRef.value?.$el;
  const track = trackRef.value;
  const river = riverRef.value;
  const boat = boatRef.value;
  if (!el || !track || !river || !boat) return;
  let p = 1;
  if (!reduced()) {
    const t = track.getBoundingClientRect();
    const pin = parseFloat(getComputedStyle(el).top);
    const span = t.height - el.getBoundingClientRect().height;
    p = Math.min(1, Math.max(0, (pin - t.top) / span));
  }
  if (lastP !== null && p !== lastP) sailingBack.value = p < lastP;
  lastP = p;
  const w = river.clientWidth;
  const x = (EDGE + p * LAST * STEP) * w - boat.offsetWidth * 0.62;
  boat.style.transform = `translateX(${x.toFixed(1)}px)`;
  active.value = Math.round(p * LAST);
}
function schedule() {
  if (!frame) frame = requestAnimationFrame(place);
}

let io = null;
let listening = false;
function listen(on) {
  if (on === listening) return;
  listening = on;
  const fn = on ? addEventListener : removeEventListener;
  fn('scroll', schedule, { passive: true });
  fn('resize', schedule);
}

onMounted(() => {
  place();
  io = new IntersectionObserver(([entry]) => {
    if (entry.isIntersecting) seen.value = true;
    listen(entry.isIntersecting);
    schedule();
  });
  io.observe(trackRef.value);
});
onBeforeUnmount(() => {
  io?.disconnect();
  listen(false);
  cancelAnimationFrame(frame);
});

/* Walking through the door. The router starts the page view transition; these vars and the
   class give it the arch's aperture to open from. Cleared once the transition has played. */
function enter(e) {
  // RouterLink has already called preventDefault, so only the keys that open a new tab count.
  if (e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
  if (reduced() || !document.startViewTransition || !slotRef.value) return;
  const r = slotRef.value.getBoundingClientRect();
  const root = document.documentElement;
  const px = (n) => `${n.toFixed(1)}px`;
  const cx = r.left + r.width / 2;
  const cy = r.top + r.height / 2;
  const a = r.width / 2;
  // The aperture scaled by s about its centre: insets plus the arch's round top.
  const door = (s) =>
    `inset(${px(cy - s * (cy - r.top))} ${px(innerWidth - cx - s * a)} ${px(innerHeight - cy - s * (r.bottom - cy))} ${px(cx - s * a)} round ${px(s * a)} ${px(s * a)} ${px(s * 6)} ${px(s * 6)})`;
  // Smallest scale at which the arch's opening covers all four viewport corners.
  const covers = (s) =>
    [0, innerWidth].every((x) =>
      [0, innerHeight].every((y) => {
        const dx = x - cx;
        const top = cy - s * (cy - r.top - a); // centre of the round top
        if (Math.abs(dx) > s * a || y > cy + s * (r.bottom - cy)) return false;
        return y >= top || dx * dx + (y - top) ** 2 <= (s * a) ** 2;
      })
    );
  let lo = 1;
  let hi = 64;
  while (hi - lo > 0.05) {
    const mid = (lo + hi) / 2;
    if (covers(mid)) hi = mid;
    else lo = mid;
  }
  // The old page zooms by the same factor the opening grows, so the arch's frame stays locked
  // to the edge of the new page as the reader walks through it.
  root.style.setProperty('--door', door(1));
  root.style.setProperty('--door-end', door(hi));
  root.style.setProperty('--door-s', hi.toFixed(2));
  root.style.setProperty('--door-at', `${px(cx)} ${px(cy)}`);
  root.classList.add('through-door');
  let fallback = 0;
  const done = () => {
    clearTimeout(fallback);
    document.removeEventListener('pagetransitionend', done);
    root.classList.remove('through-door');
    for (const v of ['--door', '--door-end', '--door-s', '--door-at']) root.style.removeProperty(v);
  };
  // The router fires this once the whole transition has finished (or been skipped).
  document.addEventListener('pagetransitionend', done);
  // A navigation that fails never starts a transition.
  fallback = setTimeout(done, 6000);
}
</script>

<style scoped>
/* The card's scroll run. The spacer after the card is what the card scrolls through while
   pinned: the sticky card can only move within its track's content box. */
.track::after {
  content: '';
  display: block;
  height: var(--span);
}
.gate {
  --arch-h: clamp(250px, 50vh, 500px);
  --river-h: clamp(110px, 19vh, 170px);
  --post-h: clamp(52px, 9vh, 84px);
  --boat-w: clamp(96px, 11vw, 168px);
  /* Pins under the navbar (--nav-h) and the House section rail (8px below the navbar, ~44px
     tall), with a gap. The card is 80vh, so it fits above the fold while pinned; the small-
     screen query below shortens it to clear the bottom tab bar. */
  position: sticky;
  top: calc(var(--nav-h) + 72px);
  display: grid;
  grid-template-rows: minmax(0, 1fr) auto var(--river-h);
  justify-items: center;
  align-items: end;
  height: 80vh;
  min-height: 500px;
  max-height: 860px;
  overflow: hidden;
  border: 1px solid var(--line);
  border-radius: 22px;
  background: var(--paper);
  color: var(--ink);
  text-decoration: none;
  isolation: isolate;
}
.gate:focus-visible {
  outline: 3px solid var(--mari);
  outline-offset: 4px;
}

/* "Since 2021" over the door, outside the painted frame. */
.since {
  grid-area: 1 / 1;
  align-self: start;
  margin-top: clamp(14px, 3vh, 28px);
  font-size: 12px;
  font-weight: 650;
  letter-spacing: 0.22em;
  text-transform: uppercase;
  color: var(--mari-ink);
}

/* The council's two leaders flank the door in matching frames: Secretary left, Deputy right.
   Same box as the door and a three-column grid around it, so cq units are the door's height
   (68.75cqh is its width). */
.side {
  grid-area: 1 / 1;
  justify-self: stretch;
  height: min(var(--arch-h), calc(100% - 44px));
  container-type: size;
  pointer-events: none;
  user-select: none;
}
.trio {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 68.75cqh minmax(0, 1fr);
  align-items: center;
  height: 100%;
}

/* The year written across the water, one digit between each pair of posts. */
.river-year {
  position: absolute;
  inset: 0;
  display: none;
  container-type: size;
  color: var(--paper);
  opacity: 0.55;
}
:root[data-theme='dark'] .river-year {
  color: var(--ink);
  opacity: 0.3;
}
.digits {
  position: absolute;
  inset: 0;
}
.digits > span {
  position: absolute;
  bottom: 4%;
  left: calc(var(--edge) + (var(--k) + 0.5) * var(--step));
  transform: translateX(-50%);
  font-size: 92cqh;
  font-weight: 750;
  line-height: 0.8;
  font-variant-numeric: tabular-nums;
}

.door {
  grid-area: 1 / 1;
  position: relative;
  display: block;
  height: min(var(--arch-h), calc(100% - 44px));
  aspect-ratio: 825 / 1200;
  transform-origin: 50% 100%;
  container-type: size;
}
.arch {
  position: absolute;
  inset: 0;
  z-index: 1;
  display: block;
  width: 100%;
  height: 100%;
  pointer-events: none;
  transition:
    transform 0.45s var(--ease-out),
    filter 0.45s var(--ease-out);
}
/* The arch's clear aperture, measured on the webp. Sizes inside are in cq units of the door. */
.slot {
  position: absolute;
  inset: 14% 17.5% 12.5% 17.5%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 2.6cqw;
  padding: 6.5cqw 4cqw 4cqw;
  overflow: hidden;
  text-align: center;
}
.plaque-kicker {
  font-size: max(9.5px, 3.5cqw);
  font-weight: 650;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: var(--mari-ink);
}
.plaque {
  font-size: 30cqw;
  font-weight: 750;
  letter-spacing: -0.03em;
  line-height: 1;
  font-variant-numeric: tabular-nums;
}
.rule {
  width: 14cqw;
  height: 2px;
  margin: 1.3cqw 0;
  border-radius: 2px;
  background: var(--mari);
}
/* That year's Secretary. Narrow stages have no paper beside the door, so the card sits on the
   aperture's sill (cq units there are the stage's). */
.sec {
  width: min(52cqh, 80%);
}
.is-sec {
  grid-column: 1;
  justify-self: end;
  margin-right: 2cqh;
}
.is-dep {
  grid-column: 3;
  justify-self: start;
  margin-left: 2cqh;
}
.who {
  display: grid;
  justify-items: center;
  gap: 3cqh;
  text-align: center;
}
/* Each leader stands in the painted pat arch; the photo fills its clear aperture. */
.who-photo {
  position: relative;
  display: block;
  width: 100%;
  aspect-ratio: 825 / 1200;
}
.who-ap {
  position: absolute;
  inset: 14% 17.5% 12.5% 17.5%;
  overflow: hidden;
  border-radius: 999px 999px 4px 4px;
  background: var(--sunk);
}
.who-ap img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: 50% 20%;
}
.who-text {
  display: grid;
  justify-items: center;
  gap: 0.8cqh;
}
.who-name {
  max-width: 100%;
  font-size: max(14px, 4.4cqh);
  font-weight: 700;
  letter-spacing: -0.01em;
  line-height: 1.1;
  text-wrap: balance;
}
.who-role {
  font-size: max(9.5px, 2.3cqh);
  font-weight: 650;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--mari-ink);
}
.roll-enter-active,
.roll-leave-active {
  transition:
    opacity 0.22s var(--ease-out),
    transform 0.22s var(--ease-out);
}
.roll-enter-from {
  opacity: 0;
  transform: translateY(8px);
}
.roll-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}

.cta {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  margin: 14px 0 12px;
  padding: 8px 18px;
  border-radius: 99px;
  background: var(--mari);
  color: var(--on-mari);
  font-size: 14px;
  font-weight: 700;
  box-shadow: var(--shadow);
  transition: transform 0.3s var(--ease-out);
}
.cta :deep(.ic) {
  width: 16px;
  height: 16px;
  fill: none;
  stroke: currentColor;
  stroke-width: 2;
  stroke-linecap: round;
  stroke-linejoin: round;
  transition: transform 0.3s var(--ease-out);
}

/* The Legacy page's river strip. */
.river {
  position: relative;
  align-self: stretch;
  justify-self: stretch;
  overflow: hidden;
  border-top: 1.5px solid var(--line-strong);
  background: var(--sunk) var(--plate) center 40% / cover no-repeat;
}
.post {
  position: absolute;
  bottom: 12%;
  left: calc(var(--edge) + var(--i) * var(--step));
  z-index: 1;
  display: flex;
  flex-direction: column-reverse;
  align-items: center;
  gap: 5px;
  transform: translateX(-50%);
}
.post-img {
  display: block;
  width: auto;
  height: var(--post-h);
  filter: saturate(0.25) brightness(0.9);
  opacity: 0.7;
  transition:
    filter 0.4s var(--ease-out),
    opacity 0.4s var(--ease-out);
}
.post.lit .post-img {
  filter: none;
  opacity: 1;
}
.tag {
  padding: 2px 7px;
  border: 1px solid transparent;
  border-radius: 99px;
  background: color-mix(in srgb, var(--card) 60%, transparent);
  color: var(--ink-2);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.04em;
  line-height: 1.5;
  font-variant-numeric: tabular-nums;
  transition:
    background-color 0.3s var(--ease-out),
    color 0.3s var(--ease-out),
    transform 0.3s var(--ease-spring);
}
.post.on .tag {
  border-color: var(--ink);
  background: var(--ink);
  color: var(--paper);
  font-weight: 750;
  transform: scale(1.18);
}
.boat {
  position: absolute;
  left: 0;
  bottom: 12%;
  z-index: 2;
  width: var(--boat-w);
  aspect-ratio: 1200 / 494;
  will-change: transform;
}
.boat-img {
  display: block;
  width: 100%;
  height: auto;
  transform-origin: 50% 100%;
  transform: scaleX(-1);
  transition: transform 0.32s var(--ease-out);
}
.boat.back .boat-img {
  transform: scaleX(1);
}

/* One-shot arrival the first time the stage scrolls into view. */
.door,
.cta,
.post {
  opacity: 0;
}
.door {
  transform: translateY(18px) scale(0.96);
}
.seen .door {
  opacity: 1;
  transform: none;
  transition:
    opacity 0.6s var(--ease-out),
    transform 0.7s var(--ease-out);
}
.seen .cta {
  opacity: 1;
  transition: opacity 0.5s var(--ease-out) 0.35s;
}
.seen .post {
  opacity: 1;
  transition: opacity 0.4s var(--ease-out) calc(0.2s + var(--i) * 0.08s);
}

.gate:hover .arch {
  transform: scale(1.025);
  filter: drop-shadow(0 0 18px var(--mari-soft)) drop-shadow(0 0 6px var(--mari));
}
.gate:hover .cta {
  transform: translateY(-2px);
}
.gate:hover .cta :deep(.ic) {
  transform: translateX(3px);
}
.gate:active .door {
  transform: scale(0.99);
}

/* Too little paper beside the door for the split year: it moves onto the river. */
@media (max-width: 860px) {
  .side {
    z-index: 2;
  }
  .trio {
    grid-template-columns: 1fr 1fr;
    align-items: end;
    justify-self: center;
    width: 100%;
    padding: 0 7cqw;
    gap: 4cqw;
  }
  .is-sec,
  .is-dep {
    grid-column: auto;
    justify-self: center;
    width: 100%;
    margin: 0;
  }
  .slot {
    justify-content: flex-start;
    padding-top: 2cqh;
  }
  .plaque {
    font-size: 22cqw;
  }
  .who {
    gap: 1.5cqh;
  }
  .who-name {
    font-size: max(12px, 3.6cqh);
  }
  .role-long {
    display: none;
  }
  .who-role {
    font-size: max(8px, 2cqh);
    letter-spacing: 0.08em;
  }
  .river-year {
    display: block;
  }
}

/* Where the bottom tab bar shows (60px, fixed): the pinned card must end above it. The 144px is
   the pin offset (72px) plus the bar and a 12px gap. */
@media (max-width: 760px) {
  .gate {
    height: min(80vh, calc(100svh - var(--nav-h) - 144px));
  }
}

@media (max-width: 640px) {
  .gate {
    --arch-h: clamp(250px, 48vh, 420px);
    --river-h: clamp(100px, 16vh, 130px);
    --boat-w: clamp(76px, 22vw, 104px);
    min-height: 480px;
    border-radius: 18px;
  }
  .tag {
    padding: 1px 5px;
    font-size: 10px;
  }
}

@media (prefers-reduced-motion: reduce) {
  .door,
  .cta,
  .post {
    opacity: 1;
  }
  .door {
    transform: none;
  }
  .track::after {
    height: 0;
  }
  .gate {
    position: relative;
  }
}

/* Walking through the door: restyles the router's page view transition while enter() has put
   .through-door on <html>. Both halves share one duration and easing: the clip's edges and the
   zoom are each linear in the scale, so the frame and the opening never drift apart. */
:global(html.through-door::view-transition-old(root)),
:global(html.through-door::view-transition-new(root)) {
  animation-duration: 0.8s;
  animation-timing-function: cubic-bezier(0.6, 0, 0.85, 0.2);
  animation-fill-mode: both;
  mix-blend-mode: normal;
}
:global(html.through-door::view-transition-old(root)) {
  animation-name: door-zoom;
  transform-origin: var(--door-at);
}
:global(html.through-door::view-transition-new(root)) {
  animation-name: door-open;
}
@keyframes door-zoom {
  to {
    transform: scale(var(--door-s));
  }
}
@keyframes door-open {
  from {
    clip-path: var(--door);
  }
  to {
    clip-path: var(--door-end);
  }
}
</style>
