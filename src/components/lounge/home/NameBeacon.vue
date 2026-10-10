<!--
  The member's own light: a paper lantern by night, a kite by day, carrying their preferred
  name (fitted by name-fit.js, verdict decision 7). Same words on both; lines and size per
  object. Without a name: the house crest on the face and a "Name your lantern / kite" chip.

  Use anywhere (Home hero, the ghat card's live preview):
    <NameBeacon :name="draft" />                       follows the theme
    <NameBeacon :name="draft" kind="lantern" :cta="false" :halo="false" />
  Size it with its wrapper's width (the box has the lantern's aspect ratio).
  Emits: name (the chip, the crest, or Edit on the full-name tag), tap.
  Exposes: faceEl() (the name's element, for flights), light() (the lamp catches),
           kind (the shown object).
  Motion (spec: _notes/motion.md): theme change = edge-on turn, paper swaps at the half
  (900ms); tap = lantern sways 3deg damped / kite string tug; idle bob is the caller's.
-->
<template>
  <div
    ref="root"
    class="nb"
    :class="[`is-${shown}`, { empty: !words, unlit: !isLit, still: !bob }]"
    :style="{ '--k-scale': KSCALE }"
  >
    <span v-if="halo" ref="haloEl" class="nb-halo" aria-hidden="true"></span>
    <div class="nb-bob">
      <div ref="tapEl" class="nb-tap">
        <div ref="spinEl" class="nb-spin">
          <!-- lantern -->
          <div
            class="nb-paper nb-l"
            :aria-hidden="shown !== 'lantern'"
            :inert="shown !== 'lantern'"
          >
            <img class="nb-art" :src="LANTERN.src" alt="" draggable="false" />
            <img
              v-if="!isLit || lighting"
              ref="unlitEl"
              class="nb-art nb-unlit"
              :src="LANTERN_UNLIT || LANTERN.src"
              alt=""
              draggable="false"
            />
            <span
              v-if="words"
              ref="faceL"
              class="nb-face"
              :style="faceStyle(fitL, LANTERN.face)"
              aria-hidden="true"
              ><span v-for="(l, i) in fitL?.lines ?? []" :key="i">{{ l }}</span></span
            >
            <button
              v-else
              type="button"
              class="nb-crest"
              :style="{ top: `${LANTERN.face.cy * 100}%` }"
              :tabindex="cta || !tappable ? -1 : 0"
              :disabled="!tappable"
              aria-label="Name your lantern"
              @click="emit('name')"
            >
              <img :src="CREST" alt="" draggable="false" />
            </button>
          </div>
          <!-- kite -->
          <div class="nb-paper nb-k" :aria-hidden="shown !== 'kite'" :inert="shown !== 'kite'">
            <svg v-if="string" class="nb-string" viewBox="0 0 100 100" preserveAspectRatio="none">
              <path d="M100 0 C 78 38, 48 74, 0 100" pathLength="1" />
            </svg>
            <img class="nb-art" :src="KITE_MINE.src" data-art alt="" draggable="false" />
            <span
              v-if="words"
              ref="faceK"
              class="nb-face"
              :style="faceStyle(fitK, KITE_MINE.face, KITE_MINE.ratio)"
              aria-hidden="true"
              ><span v-for="(l, i) in fitK?.lines ?? []" :key="i">{{ l }}</span></span
            >
            <button
              v-else
              type="button"
              class="nb-crest"
              :style="{
                top: `${50 + (KITE_MINE.face.cy - 0.5) * 100 * (LANTERN.ratio / KITE_MINE.ratio)}%`,
              }"
              :tabindex="cta || !tappable ? -1 : 0"
              :disabled="!tappable"
              aria-label="Name your kite"
              @click="emit('name')"
            >
              <img :src="CREST" alt="" draggable="false" />
            </button>
          </div>
        </div>
      </div>
    </div>
    <!-- The whole object is the tap target when named. -->
    <button
      v-if="words && tappable"
      type="button"
      class="nb-hit"
      :aria-label="dropped ? `${fullName}: show your full name` : `Your ${shown}`"
      @click="tap"
    ></button>
    <button v-if="!words && cta" type="button" class="nb-cta" @click="emit('name')">
      Name your {{ shown }}
    </button>
    <p v-if="tagOpen" class="nb-tag" role="status">
      <span>{{ fullName }}</span>
      <button type="button" @click="emit('name')">Edit</button>
    </p>
  </div>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import CREST from '../../../assets/crest.webp';
import { lanternWords, layout, fontsReady } from '../name-fit.js';
import { mode } from '../state.js';
import { fadeReady } from '../tide.js';
import { KITE_MINE, LANTERN, LANTERN_UNLIT } from './art.js';
import { animate, motionTimeout, reduced } from './motion.js';

const props = defineProps({
  name: { type: String, default: '' },
  /* 'auto' follows the theme (lantern at night, kite by day). */
  kind: { type: String, default: 'auto' },
  halo: { type: Boolean, default: true },
  cta: { type: Boolean, default: true },
  /* false: the lantern starts unlit (the arrival); call light() to catch it. */
  lit: { type: Boolean, default: true },
  bob: { type: Boolean, default: true },
  string: { type: Boolean, default: false },
  tappable: { type: Boolean, default: true },
});
const emit = defineEmits(['name', 'tap']);

/* The kite is drawn a little narrower than the lantern (verdict: 220 vs 240 on desktop). */
const KSCALE = 0.92;
const TURN = 900;

const root = ref(null);
const haloEl = ref(null);
const spinEl = ref(null);
const tapEl = ref(null);
const unlitEl = ref(null);
const faceL = ref(null);
const faceK = ref(null);
const W = ref(0);
const ready = ref(false);
const lighting = ref(false);
const isLit = ref(props.lit);
const tagOpen = ref(false);

const desired = computed(() =>
  props.kind === 'auto' ? (mode.value === 'night' ? 'lantern' : 'kite') : props.kind
);
const shown = ref(desired.value);
const fullName = computed(() => props.name.trim().replace(/\s+/g, ' '));

/* Words: once per name, against the tightest panels (lantern 176px, kite 168px). */
const words = computed(() => {
  if (!ready.value) return fullName.value ? { units: [fullName.value], pending: true } : null;
  return lanternWords(fullName.value, [
    [LANTERN.face, 176],
    [KITE_MINE.face, 168],
  ]);
});
const dropped = computed(() => !!words.value?.dropped);
const fitL = computed(() =>
  words.value && W.value && !words.value.pending ? layout(words.value, LANTERN.face, W.value) : null
);
const fitK = computed(() =>
  words.value && W.value && !words.value.pending
    ? layout(words.value, KITE_MINE.face, W.value * KSCALE)
    : null
);

function faceStyle(fit, face, ratio = LANTERN.ratio) {
  /* The paper box is the lantern's. The kite art is width-fitted and centred in it, and the
     whole kite paper is scaled by KSCALE (so its text is fitted at W * KSCALE and drawn at
     size / KSCALE inside the scaled paper). */
  const kite = ratio !== LANTERN.ratio;
  const top = kite ? 50 + (face.cy - 0.5) * 100 * (LANTERN.ratio / ratio) : face.cy * 100;
  const size = fit ? fit.size / (kite ? KSCALE : 1) : 0;
  return {
    top: `${top}%`,
    fontSize: `${size.toFixed(2)}px`,
    fontStretch: fit ? `${fit.wdth}%` : undefined,
    visibility: fit ? 'visible' : 'hidden',
  };
}

let ro = null;
let markReady;
const readyP = new Promise((r) => (markReady = r));
onMounted(async () => {
  ro = new ResizeObserver(([e]) => {
    W.value = Math.round(e.contentRect.width);
  });
  ro.observe(root.value);
  W.value = Math.round(root.value.getBoundingClientRect().width);
  await fontsReady();
  ready.value = true;
  await nextTick();
  markReady();
});

/* Start after the new view-transition image exists. Keep the old paper until edge-on. */
let turnTimer = () => {};
let turnGeneration = 0;
watch(desired, async (paper) => {
  const generation = ++turnGeneration;
  tagOpen.value = false;
  turnTimer();
  if (reduced() || !spinEl.value) {
    shown.value = paper;
    return;
  }
  await fadeReady();
  if (generation !== turnGeneration || !spinEl.value) return;
  animate(
    spinEl.value,
    [
      { transform: 'none' },
      { transform: 'scaleX(0.02) scaleY(1.06)', offset: 0.5 },
      { transform: 'none' },
    ],
    { duration: TURN, easing: 'cubic-bezier(0.65, 0, 0.35, 1)' }
  );
  turnTimer = motionTimeout(() => {
    if (generation === turnGeneration) shown.value = paper;
  }, TURN / 2);
});

/* The lantern catches: the lit sprite shows through the unlit one in two quick steps. */
async function light(delay = 0) {
  if (isLit.value) return;
  lighting.value = true;
  isLit.value = true;
  await nextTick();
  const u = unlitEl.value;
  if (!u || reduced()) {
    lighting.value = false;
    return;
  }
  const a = animate(
    u,
    [{ opacity: 1 }, { opacity: 0.45, offset: 0.2 }, { opacity: 0.7, offset: 0.4 }, { opacity: 0 }],
    { duration: 400, delay, easing: 'linear', fill: 'both' }
  );
  await a.finished.catch(() => {});
  lighting.value = false;
}
watch(
  () => props.lit,
  (v) => {
    if (v) light();
    else isLit.value = false;
  }
);

let tagT = () => {};
function tap() {
  emit('tap');
  if (dropped.value) {
    tagOpen.value = true;
    tagT();
    tagT = motionTimeout(() => (tagOpen.value = false), 3000);
  }
  if (reduced() || !tapEl.value) return;
  const kite = shown.value === 'kite';
  animate(
    tapEl.value,
    kite
      ? [
          { transform: 'none' },
          { transform: 'translate3d(0, 6px, 0) rotate(-2deg)', offset: 0.25 },
          { transform: 'translate3d(0, -2px, 0) rotate(1deg)', offset: 0.6 },
          { transform: 'none' },
        ]
      : [
          { transform: 'none' },
          { transform: 'rotate(3deg)', offset: 0.2 },
          { transform: 'rotate(-2deg)', offset: 0.45 },
          { transform: 'rotate(0.8deg)', offset: 0.7 },
          { transform: 'none' },
        ],
    { duration: 900, easing: 'ease-out' }
  );
}

onBeforeUnmount(() => {
  turnGeneration++;
  turnTimer();
  ro?.disconnect();
  tagT();
  root.value?.getAnimations({ subtree: true }).forEach((a) => a.cancel());
});

/* A name was just written on the face: the lantern's halo blooms, the kite tugs. */
function bloom() {
  if (reduced()) return;
  if (shown.value === 'lantern' && haloEl.value) {
    animate(haloEl.value, [{ opacity: 0.35 }, { opacity: 1 }], {
      duration: 900,
      easing: 'ease-out',
    });
  }
  if (tapEl.value)
    animate(
      tapEl.value,
      shown.value === 'kite'
        ? [
            { transform: 'none' },
            { transform: 'translate3d(0, 6px, 0)', offset: 0.3 },
            { transform: 'none' },
          ]
        : [
            { transform: 'none' },
            { transform: 'rotate(2deg)', offset: 0.3 },
            { transform: 'rotate(-1deg)', offset: 0.65 },
            { transform: 'none' },
          ],
      { duration: 900, easing: 'ease-out' }
    );
}

defineExpose({
  faceEl: () => (shown.value === 'kite' ? faceK.value : faceL.value),
  light,
  bloom,
  whenReady: () => readyP,
  kind: shown,
});
</script>

<style scoped>
.nb {
  position: relative;
  width: 100%;
  aspect-ratio: 480 / 621;
}

/* The one halo: static, behind the sprite, never pulsing (verdict section 1). */
.nb-halo {
  position: absolute;
  left: -35%;
  right: -35%;
  top: -25%;
  bottom: -25%;
  border-radius: 50%;
  background: radial-gradient(
    closest-side,
    rgb(255 220 150 / 0.34),
    rgb(255 176 74 / 0.13) 42%,
    rgb(255 176 74 / 0.04) 66%,
    transparent
  );
  pointer-events: none;
  transition: opacity 600ms linear;
}
.is-kite .nb-halo,
.unlit .nb-halo {
  opacity: 0;
  transition-duration: 300ms;
}

.nb-bob,
.nb-tap,
.nb-spin,
.nb-paper {
  position: absolute;
  inset: 0;
}
/* Idle: the lantern floats (2.5%, 0.8deg, 7s); the kite sways from its bridle (4deg, 5.2s). */
.nb-bob {
  transform-origin: 50% 12%;
  animation: nb-bob 7s ease-in-out infinite;
}
.is-kite .nb-bob {
  transform-origin: 50% 70%;
  animation: nb-sway 5.2s ease-in-out infinite;
}
.still .nb-bob {
  animation: none;
}
@keyframes nb-bob {
  50% {
    transform: translate3d(0, -2.5%, 0) rotate(0.8deg);
  }
}
@keyframes nb-sway {
  0%,
  100% {
    transform: rotate(-3deg);
  }
  50% {
    transform: rotate(4deg) translate3d(0, -2%, 0);
  }
}
.nb-tap {
  transform-origin: 50% 8%;
}
.is-kite .nb-tap {
  transform-origin: 50% 90%;
}

/* JS swaps the paper at the edge-on midpoint, including inside a view transition. */
.nb-paper {
  transition: none;
}
.is-lantern .nb-k,
.is-kite .nb-l {
  opacity: 0;
  pointer-events: none;
}
.nb-k {
  transform: scale(var(--k-scale));
}

.nb-art {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: contain;
  user-select: none;
  -webkit-user-drag: none;
}
/* The unlit lantern (r6) over the lit one; lighting fades it out in two quick steps. */
.nb-unlit {
  opacity: 1;
}
.nb-k .nb-art {
  filter: drop-shadow(0 8px 6px rgb(90 40 0 / 0.22));
}

.nb-face {
  position: absolute;
  left: 50%;
  display: grid;
  justify-items: center;
  transform: translate(-50%, -50%);
  color: #2a1a0f;
  font-family: 'Anek Latin Lounge', system-ui, sans-serif;
  font-weight: 700;
  line-height: 0.96;
  letter-spacing: -0.01em;
  text-align: center;
  white-space: nowrap;
  pointer-events: none;
}

.nb-crest {
  position: absolute;
  left: 50%;
  width: 36%;
  aspect-ratio: 1;
  padding: 0;
  border: 0;
  background: none;
  transform: translate(-50%, -50%);
  cursor: pointer;
  border-radius: 50%;
}
.nb-crest img {
  width: 100%;
  height: 100%;
  opacity: 0.9;
}
.nb-k .nb-crest {
  width: 30%;
}

.nb-hit {
  position: absolute;
  inset: 8% 14% 6%;
  padding: 0;
  border: 0;
  background: none;
  cursor: pointer;
  border-radius: 40%;
}
.nb-hit:focus-visible,
.nb-crest:focus-visible,
.nb-cta:focus-visible {
  outline: 2px solid var(--focus, #f5ae4b);
  outline-offset: 3px;
}

.nb-cta {
  position: absolute;
  left: 50%;
  top: calc(100% + 10px);
  transform: translateX(-50%);
  white-space: nowrap;
  min-height: 36px;
  padding: 7px 14px 6px;
  border-radius: 999px;
  font:
    600 13px/1.1 'Anek Latin Lounge',
    system-ui,
    sans-serif;
  cursor: pointer;
  color: #2a1a0f;
  background: #fcf3dd;
  border: 1.5px solid #2a1a0f;
  box-shadow: 0 2px 0 #2a1a0f;
  transition: transform var(--t-press, 120ms) ease-out;
}
:root[data-theme='dark'] .nb-cta {
  color: #f4e8d0;
  background: #131a2c;
  border: 1px solid #5a4a34;
  box-shadow: 0 2px 0 #03060e;
}
.nb-cta:active {
  transform: translate(-50%, 2px);
}

/* Full name, when the face carries fewer words: a small hung tag for 3s. */
.nb-tag {
  position: absolute;
  left: 50%;
  top: calc(100% + 8px);
  z-index: 2;
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 0;
  padding: 7px 10px 6px 12px;
  transform: translateX(-50%);
  white-space: nowrap;
  font:
    600 13px/1.2 'Anek Latin Lounge',
    system-ui,
    sans-serif;
  color: var(--t-1, #2a1a0f);
  background: var(--paper, #fcf3dd);
  border: 1px solid var(--keyline, #2a1a0f);
  border-radius: 6px;
  box-shadow: 0 3px 0 var(--under, #2a1a0f);
  animation: m-paper-in var(--t-paper, 280ms) var(--ease-out) both;
}
.nb-tag button {
  padding: 2px 0;
  border: 0;
  background: none;
  font: inherit;
  font-weight: 700;
  color: var(--accent, #915114);
  text-decoration: underline;
  text-underline-offset: 2px;
  cursor: pointer;
}

/* The kite's string: from the tail down and away to the flyer on the ghat (Home). */
.nb-string {
  position: absolute;
  right: 50%;
  top: 90%;
  width: var(--str-w, 30vw);
  height: var(--str-h, 60vh);
  overflow: visible;
  pointer-events: none;
}
.nb-string path {
  fill: none;
  stroke: #3a2414;
  stroke-opacity: 0.5;
  stroke-width: 1.2;
  vector-effect: non-scaling-stroke;
}
.is-lantern .nb-string {
  display: none;
}
/* At daybreak the string pays out from the kite down to the ghat (B). */
:root.theme-move .is-kite .nb-string path {
  stroke-dasharray: 1;
  animation: nb-str-draw 1600ms var(--ease-out) 300ms backwards;
}
@keyframes nb-str-draw {
  from {
    stroke-dashoffset: 1;
  }
}

@media (prefers-reduced-motion: reduce) {
  .nb-paper,
  .nb-halo {
    transition: none;
  }
  .nb-bob,
  .is-kite .nb-bob {
    animation: none;
  }
}
</style>
