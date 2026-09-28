<!--
  PROTOTYPE — a meetup's photos, full screen. Opens from the season's roll or a meetup's stack.
  Arrow keys / swipe to move, Esc or the phone's back button to close. Photos load at screen
  size only when shown; the thumbnails below are tiny crops.
-->
<template>
  <Teleport to="body">
    <Transition name="pv">
      <div
        v-if="v"
        class="pv"
        role="dialog"
        aria-modal="true"
        :aria-label="`Photos: ${v.m.title}`"
        @click.self="close"
      >
        <header>
          <span class="cap">
            <small class="mono">{{ meetupDate(v.m) }} · {{ regionById[v.m.region].name }}</small>
            <strong>{{ v.m.title }}</strong>
            <span v-if="v.m.venue || v.m.people"
              >{{ v.m.venue }}<template v-if="v.m.venue && v.m.people"> · </template
              ><template v-if="v.m.people">{{ v.m.people }} students</template></span
            >
          </span>
          <button ref="closeBtn" type="button" class="x" aria-label="Close photos" @click="close">
            <LineIcon name="close" />
          </button>
        </header>

        <div class="stage" @pointerdown="swipeStart" @pointerup="swipeEnd" @click.self="close">
          <Transition :name="dir > 0 ? 'nx' : 'pr'">
            <img
              referrerpolicy="no-referrer"
              v-if="list[v.i]"
              :key="list[v.i]"
              class="big"
              :src="photo(list[v.i], bigW)"
              :data-photo="list[v.i]"
              :alt="`${v.m.title}, photo ${v.i + 1} of ${list.length}`"
              draggable="false"
              @error="lost($event.target.dataset.photo, $event)"
            />
          </Transition>
          <p v-if="!list.length" class="unavailable" role="status">
            These photos couldn't load.<template v-if="v.m.insta">
              Try the original post below.</template
            >
          </p>
          <button
            v-if="list.length > 1"
            type="button"
            class="nav prev"
            aria-label="Previous photo"
            @click="step(-1)"
          >
            <LineIcon name="prev" />
          </button>
          <button
            v-if="list.length > 1"
            type="button"
            class="nav next"
            aria-label="Next photo"
            @click="step(1)"
          >
            <LineIcon name="next" />
          </button>
        </div>

        <footer>
          <ol class="thumbs">
            <li v-for="(u, k) in list" :key="u">
              <button
                type="button"
                :class="{ on: k === v.i }"
                :aria-label="`Photo ${k + 1}`"
                :aria-current="k === v.i ? 'true' : undefined"
                @click="go(k)"
              >
                <img
                  referrerpolicy="no-referrer"
                  :src="photo(u, 96, 96)"
                  alt=""
                  width="48"
                  height="48"
                  @error="lost(u, $event)"
                />
              </button>
            </li>
          </ol>
          <span v-if="list.length" class="mono count">{{ v.i + 1 }} / {{ list.length }}</span>
          <a v-if="v.m.insta" class="ig" :href="v.m.insta" target="_blank" rel="noopener"
            ><LineIcon name="instagram" /> <span>Instagram post</span></a
          >
        </footer>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import LineIcon from './LineIcon.vue';
import { house, livePhotos, markDead, meetupDate, photo, regionById } from './house.js';

const v = computed(() => house.photos);
const list = computed(() => (v.value ? livePhotos(v.value.m) : []));
const dir = ref(1);
const closeBtn = ref(null);
// Width to request: the screen, capped — 1280 is plenty for a phone or a laptop.
const bigW = Math.min(1280, Math.round(innerWidth * Math.min(devicePixelRatio, 2)));

// A dead link drops out; keep the viewer usable even when the source is unavailable.
function lost(u, e) {
  markDead(u, e);
}
watch(list, (photos) => {
  if (v.value && v.value.i >= photos.length) house.photos = { ...v.value, i: 0 };
});
function go(k) {
  if (!v.value || !list.value[k]) return;
  dir.value = k >= v.value.i ? 1 : -1;
  house.photos = { ...v.value, i: k };
}
function step(d) {
  const n = list.value.length;
  if (!v.value || !n) return;
  dir.value = d;
  house.photos = { ...v.value, i: (v.value.i + d + n) % n };
}

// Back closes the viewer instead of leaving the page.
function close() {
  if (!house.photos) return;
  house.photos = null;
  if (history.state?.photos) history.back();
}
function onPop() {
  if (house.photos) house.photos = null;
}
watch(
  () => !!house.photos,
  async (open, was) => {
    if (open && !was) {
      history.pushState({ photos: true }, '', location.href);
      document.documentElement.style.overflow = 'hidden';
      await nextTick();
      closeBtn.value?.focus();
    } else if (!open && was) document.documentElement.style.overflow = '';
  }
);

function onKey(e) {
  if (!v.value) return;
  if (e.key === 'Escape') close();
  else if (e.key === 'ArrowRight') step(1);
  else if (e.key === 'ArrowLeft') step(-1);
}
let x0 = null;
const swipeStart = (e) => (x0 = e.clientX);
function swipeEnd(e) {
  if (x0 == null) return;
  const dx = e.clientX - x0;
  x0 = null;
  if (Math.abs(dx) > 50 && list.value.length > 1) step(dx < 0 ? 1 : -1);
}

onMounted(() => {
  addEventListener('keydown', onKey);
  addEventListener('popstate', onPop);
});
onBeforeUnmount(() => {
  removeEventListener('keydown', onKey);
  removeEventListener('popstate', onPop);
  document.documentElement.style.overflow = '';
});
</script>

<style scoped>
.pv {
  position: fixed;
  inset: 0;
  z-index: 400;
  display: grid;
  grid-template-rows: auto minmax(0, 1fr) auto;
  gap: 10px;
  padding: 14px clamp(12px, 3vw, 28px) calc(14px + env(safe-area-inset-bottom));
  background: rgb(15 12 9 / 0.94);
  backdrop-filter: blur(8px);
  color: #f3ebdd;
}
header {
  display: flex;
  align-items: flex-start;
  gap: 16px;
}
.cap {
  display: grid;
  gap: 2px;
  margin-right: auto;
  min-width: 0;
}
.cap small {
  font-size: 12px;
  color: #f2a93b;
}
.cap strong {
  font-size: clamp(18px, 2.4vw, 24px);
  font-weight: 700;
  letter-spacing: -0.02em;
}
.cap span {
  font-size: 13.5px;
  color: #b9ac9a;
}
.x {
  display: grid;
  place-items: center;
  flex: none;
  width: 42px;
  height: 42px;
  border: 0;
  border-radius: 50%;
  background: #2a231c;
  color: #f3ebdd;
}
.x:hover {
  background: #3a3027;
}
.stage {
  position: relative;
  display: grid;
  place-items: center;
  min-height: 0;
  overflow: hidden;
  touch-action: pan-y;
}
.big {
  grid-area: 1 / 1;
  max-width: 100%;
  max-height: 100%;
  border-radius: 10px;
  object-fit: contain;
  user-select: none;
  box-shadow: 0 30px 80px -30px rgb(0 0 0 / 0.8);
  background: #2a231c;
}
.nav {
  position: absolute;
  top: 50%;
  display: grid;
  place-items: center;
  width: 46px;
  height: 46px;
  margin-top: -23px;
  border: 0;
  border-radius: 50%;
  background: rgb(29 25 21 / 0.7);
  color: #f3ebdd;
  backdrop-filter: blur(6px);
  transition: background 0.2s;
}
.nav:hover {
  background: #f2a93b;
  color: #1d1915;
}
.prev {
  left: 6px;
}
.next {
  right: 6px;
}
footer {
  display: flex;
  align-items: center;
  gap: 14px;
  min-width: 0;
}
.thumbs {
  display: flex;
  gap: 6px;
  min-width: 0;
  margin: 0;
  padding: 2px;
  list-style: none;
  overflow-x: auto;
  scrollbar-width: none;
}
.thumbs button {
  display: block;
  padding: 0;
  border: 0;
  border-radius: 6px;
  background: none;
  opacity: 0.5;
  outline-offset: 2px;
  transition:
    opacity 0.2s,
    transform 0.3s var(--ease-spring);
}
.thumbs button:hover {
  opacity: 0.85;
}
.thumbs button.on {
  opacity: 1;
  transform: translateY(-2px);
  box-shadow: 0 0 0 2px #f2a93b;
}
.thumbs img {
  display: block;
  width: 48px;
  height: 48px;
  border-radius: 6px;
  object-fit: cover;
  background: #2a231c;
}
.count {
  flex: none;
  font-size: 13px;
  color: #b9ac9a;
}
.ig {
  display: inline-flex;
  flex: none;
  align-items: center;
  gap: 6px;
  margin-left: auto;
  font-size: 13.5px;
  font-weight: 600;
  color: #f3ebdd;
  text-decoration: none;
}
.ig :deep(svg) {
  width: 18px;
  height: 18px;
}
.ig:hover {
  color: #f2a93b;
}

.pv-enter-active {
  transition: opacity 0.3s var(--ease-out);
}
.pv-enter-active .big {
  transition: transform 0.5s var(--ease-spring);
}
.pv-leave-active {
  transition: opacity 0.2s;
}
.pv-enter-from,
.pv-leave-to {
  opacity: 0;
}
.pv-enter-from .big {
  transform: scale(0.9) rotate(-2deg);
}
.nx-enter-active,
.nx-leave-active,
.pr-enter-active,
.pr-leave-active {
  transition:
    transform 0.45s var(--ease-out),
    opacity 0.3s;
}
.nx-enter-from,
.pr-leave-to {
  transform: translateX(60px) rotate(2deg);
  opacity: 0;
}
.nx-leave-to,
.pr-enter-from {
  transform: translateX(-60px) rotate(-2deg);
  opacity: 0;
}
@media (max-width: 560px) {
  .ig span,
  .count {
    display: none;
  }
  .nav {
    display: none;
  }
}
@media (prefers-reduced-motion: reduce) {
  .pv-enter-active .big,
  .nx-enter-active,
  .nx-leave-active,
  .pr-enter-active,
  .pr-leave-active {
    transition: none;
  }
}
</style>
