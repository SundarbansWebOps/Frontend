<!--
  PROTOTYPE — beside the map: every region ranked by meetups, or one region opened up —
  its coordinator, what it's about, and its meetup log. Picking a dot on the map
  highlights that meetup here.
-->
<template>
  <div ref="root" class="panel">
    <Transition :name="house.region ? 'in' : 'out'" mode="out-in">
      <div v-if="!r" key="all" class="all">
        <p class="lede">
          <b>{{ meetupCount }}</b> meetups across <b>{{ regions.length }}</b> regions,
          {{ monthLabel(season.from) }} – {{ monthLabel(season.to) }}. Pick a region.
        </p>
        <p class="legend" aria-hidden="true">
          <span><i class="lg" /><i class="lg lg2" /> sized by turnout</span>
          <span><i class="lg big" /> 40+ students</span>
          <span><i class="lg nd" /> date not recorded</span>
          <span><i class="lg ph" /> has photos</span>
        </p>
        <ol class="rank">
          <li v-for="(g, i) in regions" :key="g.id" :style="{ '--i': i }">
            <button type="button" class="row" @click="house.region = g.id">
              <span class="nm">{{ g.name }}</span>
              <span class="faces" aria-hidden="true">
                <img
                  v-for="c in g.coordinators"
                  :key="c.id"
                  :src="portrait.face(c.img)"
                  alt=""
                  loading="lazy"
                  width="26"
                  height="26"
                />
              </span>
              <span class="bar"
                ><i :style="{ '--w': g.items.length / regions[0].items.length }"
              /></span>
              <span class="n mono">{{ g.items.length }}</span>
            </button>
          </li>
        </ol>
      </div>

      <div v-else :key="r.id" class="one">
        <button type="button" class="back" @click="house.region = null">
          <LineIcon name="back" /> All regions
        </button>
        <h3>{{ r.name }}</h3>
        <p v-if="r.blurb" class="blurb">{{ r.blurb }}</p>

        <div class="who">
          <template v-if="r.coordinators.length">
            <span v-for="c in r.coordinators" :key="c.id" class="coord">
              <img :src="portrait.face(c.img)" alt="" width="40" height="40" />
              <span>
                <small>Regional coordinator</small>
                <strong>{{ c.name }}</strong>
              </span>
            </span>
          </template>
          <span v-else class="coord none">No coordinator listed for 2026–27</span>
        </div>

        <dl class="facts">
          <div>
            <dt>meetups</dt>
            <dd class="mono">{{ r.items.length }}</dd>
          </div>
          <div>
            <dt>students</dt>
            <dd class="mono">{{ r.people || '—' }}</dd>
          </div>
          <div>
            <dt>latest</dt>
            <dd class="mono">{{ r.last ? meetupDate(r.last) : '—' }}</dd>
          </div>
        </dl>

        <ol class="log">
          <li
            v-for="(m, i) in r.items"
            :key="m.id"
            :ref="(el) => (rows[m.id] = el)"
            :class="{ hot: house.meetup === m.id, open: opened === m.id }"
            :style="{ '--i': i }"
          >
            <span class="when mono">
              <b>{{ m.at ? `${m.d ?? ''} ${MONTH[m.m]}`.trim() : '—' }}</b>
              <small>{{ m.at ? m.y : 'no date' }}</small>
            </span>
            <span class="what">
              <button
                type="button"
                class="t"
                :aria-expanded="opened === m.id"
                @click="opened = opened === m.id ? null : m.id"
              >
                {{ m.title }}<small v-if="m.no" class="mono"> #{{ m.no }}</small>
              </button>
              <span class="meta">
                <template v-if="m.venue">{{ m.venue }}</template>
                <template v-if="m.venue && m.people"> · </template>
                <template v-if="m.people"
                  >{{ m.approx ? '~' : '' }}{{ m.people }} students</template
                >
              </span>
              <span v-if="m.collab.length" class="with">
                with {{ m.collab.slice(0, 3).join(', ')
                }}<template v-if="m.collab.length > 3"> +{{ m.collab.length - 3 }}</template>
              </span>
              <span v-if="m.desc" class="desc">{{ m.desc }}</span>
            </span>
            <button
              v-if="livePhotos(m).length"
              type="button"
              class="stack"
              :title="`${livePhotos(m).length} photos`"
              @click="house.photos = { m, i: 0 }"
            >
              <img
                referrerpolicy="no-referrer"
                v-for="(u, k) in livePhotos(m).slice(0, 3)"
                :key="u"
                :src="photo(u, 120, 120)"
                alt=""
                width="46"
                height="46"
                loading="lazy"
                :style="{ '--k': k }"
                @load="$event.target.classList.add('ok')"
                @error="markDead(u, $event)"
              />
              <small class="mono">{{ livePhotos(m).length }}</small>
              <span class="visually-hidden">See {{ livePhotos(m).length }} photos</span>
            </button>
            <a
              v-if="m.insta"
              class="ig"
              :href="m.insta"
              target="_blank"
              rel="noopener"
              :title="`Photos of ${m.title} on Instagram`"
            >
              <LineIcon name="instagram" />
              <span class="visually-hidden">Photos on Instagram</span>
            </a>
          </li>
        </ol>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { computed, nextTick, ref, watch } from 'vue';
import LineIcon from './LineIcon.vue';
import { MONTH } from './events.js';
import {
  house,
  meetupCount,
  meetupDate,
  monthLabel,
  livePhotos,
  markDead,
  photo,
  portrait,
  regionById,
  regions,
  season,
} from './house.js';

const r = computed(() => (house.region ? regionById[house.region] : null));
const rows = {};
const opened = ref(null);
const root = ref(null);

// A dot picked on the map: open and scroll to its row once the region has rendered.
watch(
  () => house.meetup,
  async (id) => {
    if (!id) return;
    opened.value = id;
    await nextTick();
    setTimeout(() => rows[id]?.scrollIntoView({ behavior: 'smooth', block: 'nearest' }), 380);
  }
);
watch(
  () => house.region,
  () => {
    if (!house.meetup) opened.value = null;
  }
);
</script>

<style scoped>
.panel {
  min-width: 0;
}
.lede {
  margin: 4px 0 16px;
  font-size: 15px;
  color: var(--ink-2);
  line-height: 1.5;
}
.lede b {
  color: var(--ink);
  font-weight: 700;
}
.legend {
  display: flex;
  flex-wrap: wrap;
  gap: 6px 16px;
  margin: -6px 0 14px;
  font-size: 12.5px;
  color: var(--ink-2);
}
.legend span {
  display: inline-flex;
  align-items: center;
  gap: 5px;
}
.lg {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--w-meetups);
}
.lg2 {
  width: 11px;
  height: 11px;
  margin-left: -2px;
}
.lg.big {
  width: 11px;
  height: 11px;
  background: var(--mari);
}
.lg.ph {
  width: 11px;
  height: 11px;
  background: var(--w-meetups);
  box-shadow:
    0 0 0 2px var(--paper),
    0 0 0 3px var(--mari-ink);
  margin: 0 3px;
}
.lg.nd {
  width: 9px;
  height: 9px;
  background: none;
  border: 1.5px dashed var(--w-meetups);
}
.rank {
  display: grid;
  gap: 2px;
  margin: 0;
  padding: 0;
  list-style: none;
}
.row {
  display: grid;
  grid-template-columns: 104px 58px minmax(0, 1fr) 28px;
  align-items: center;
  gap: 10px;
  width: 100%;
  padding: 9px 10px;
  border: 0;
  border-radius: 12px;
  background: none;
  text-align: left;
  transition: background 0.2s;
}
.row:hover {
  background: var(--sunk);
}
.nm {
  font-size: 15px;
  font-weight: 650;
}
.faces {
  display: flex;
}
.faces img {
  width: 26px;
  height: 26px;
  border-radius: 50%;
  border: 2px solid var(--paper);
  object-fit: cover;
  background: var(--sunk);
}
.faces img + img {
  margin-left: -9px;
}
.bar {
  height: 8px;
  border-radius: 99px;
  background: var(--sunk);
  overflow: hidden;
}
.bar i {
  display: block;
  height: 100%;
  width: calc(var(--w) * 100%);
  border-radius: 99px;
  background: var(--w-meetups);
  transform-origin: left;
  animation: grow 0.9s var(--ease-out) both;
  animation-delay: calc(200ms + var(--i) * 60ms);
}
li:first-child .bar i {
  background: var(--mari);
}
@keyframes grow {
  from {
    transform: scaleX(0);
  }
}
.n {
  text-align: right;
  font-size: 14px;
  font-weight: 600;
}

.back {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 10px 6px 6px;
  border: 0;
  border-radius: 99px;
  background: var(--sunk);
  font-size: 13px;
  font-weight: 600;
  color: var(--ink-2);
}
.back :deep(svg) {
  width: 16px;
  height: 16px;
}
.back:hover {
  color: var(--ink);
}
h3 {
  margin: 12px 0 4px;
  font-size: clamp(28px, 3vw, 36px);
  font-weight: 750;
  letter-spacing: -0.04em;
}
.blurb {
  margin: 0 0 14px;
  font-size: 15px;
  line-height: 1.55;
  color: var(--ink-2);
  max-width: 56ch;
}
.who {
  display: flex;
  flex-wrap: wrap;
  gap: 10px 18px;
  margin-bottom: 14px;
}
.coord {
  display: flex;
  align-items: center;
  gap: 10px;
}
.coord img {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  object-fit: cover;
  background: var(--sunk);
}
.coord small {
  display: block;
  font-size: 11.5px;
  color: var(--ink-2);
}
.coord strong {
  font-size: 15px;
}
.coord.none {
  font-size: 14px;
  color: var(--ink-2);
}
.facts {
  display: flex;
  gap: 26px;
  margin: 0 0 12px;
  padding: 12px 0;
  border-block: 1px solid var(--line);
}
.facts div {
  display: flex;
  flex-direction: column-reverse;
}
.facts dt {
  font-size: 12px;
  color: var(--ink-2);
}
.facts dd {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  letter-spacing: -0.03em;
}

.log {
  display: grid;
  margin: 0;
  padding: 0;
  list-style: none;
}
.log li {
  position: relative;
  display: grid;
  grid-template-columns: 62px minmax(0, 1fr) 66px 34px;
  align-items: start;
  gap: 12px;
  padding: 11px 8px 11px 0;
  border-bottom: 1px solid var(--line);
  animation: rowin 0.5s var(--ease-out) both;
  animation-delay: calc(min(var(--i), 12) * 35ms);
  transition: background 0.3s;
}
/* A tide mark runs down the log; each row is a notch on it. */
.log li::before {
  content: '';
  position: absolute;
  left: 64px;
  top: 17px;
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--w-meetups);
}
.log li.hot {
  background: linear-gradient(90deg, var(--mari-soft), transparent 80%);
}
.log li.hot::before {
  background: var(--mari);
  box-shadow: 0 0 0 4px var(--mari-soft);
}
@keyframes rowin {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
}
.when {
  display: grid;
  align-content: start;
  padding-left: 4px;
}
.when b {
  font-size: 13.5px;
  font-weight: 600;
}
.when small {
  font-size: 11px;
  color: var(--ink-3);
}
.what {
  display: grid;
  gap: 2px;
  min-width: 0;
}
.t {
  padding: 0;
  border: 0;
  background: none;
  text-align: left;
  font-size: 15.5px;
  font-weight: 650;
  line-height: 1.3;
}
.t small {
  font-size: 12px;
  font-weight: 500;
  color: var(--ink-3);
}
.t:hover {
  text-decoration: underline;
  text-decoration-color: var(--mari);
  text-decoration-thickness: 2px;
  text-underline-offset: 3px;
}
.meta,
.with {
  font-size: 13px;
  color: var(--ink-2);
}
.with {
  color: var(--mari-ink);
  font-weight: 550;
}
.desc {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  margin-top: 3px;
  font-size: 13.5px;
  line-height: 1.5;
  color: var(--ink-2);
}
.open .desc {
  -webkit-line-clamp: unset;
}
/* A small fanned stack of prints; it spreads when you reach for it. */
.stack {
  grid-column: 3;
  position: relative;
  width: 66px;
  height: 52px;
  margin-top: 2px;
  padding: 0;
  border: 0;
  background: none;
}
.stack img {
  position: absolute;
  top: 3px;
  left: 8px;
  width: 46px;
  height: 46px;
  padding: 2px 2px 5px;
  border-radius: 3px;
  background: #fffdf8;
  object-fit: cover;
  box-shadow: 0 3px 10px -4px rgb(29 25 21 / 0.45);
  transform: rotate(calc((var(--k) - 1) * 7deg)) translateX(calc((var(--k) - 1) * 3px));
  opacity: 0;
  transition:
    transform 0.35s var(--ease-spring),
    opacity 0.3s;
  z-index: calc(3 - var(--k));
}
.stack img.ok {
  opacity: 1;
}
.stack:hover img,
.stack:focus-visible img {
  transform: rotate(calc((var(--k) - 1) * 14deg)) translateX(calc((var(--k) - 1) * 12px))
    translateY(-3px);
}
.stack small {
  position: absolute;
  right: -2px;
  bottom: -2px;
  z-index: 4;
  min-width: 20px;
  padding: 2px 5px;
  border-radius: 99px;
  background: var(--ink);
  color: var(--paper);
  font-size: 10.5px;
  font-weight: 600;
  text-align: center;
}
.ig {
  grid-column: 4;
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  border-radius: 50%;
  color: var(--ink-2);
  transition:
    background 0.2s,
    color 0.2s;
}
.ig:hover {
  background: var(--sunk);
  color: var(--ink);
}

.in-enter-active,
.out-enter-active {
  transition:
    opacity 0.3s var(--ease-out),
    transform 0.45s var(--ease-out);
}
.in-leave-active,
.out-leave-active {
  transition:
    opacity 0.18s,
    transform 0.2s;
}
.in-enter-from,
.out-leave-to {
  opacity: 0;
  transform: translateX(24px);
}
.in-leave-to,
.out-enter-from {
  opacity: 0;
  transform: translateX(-24px);
}

@media (max-width: 560px) {
  .log li {
    grid-template-columns: 54px minmax(0, 1fr) 34px;
  }
  .log .ig {
    grid-column: 3;
    grid-row: 1;
  }
  .log li::before {
    left: 56px;
  }
  .log .stack {
    grid-column: 2;
    grid-row: 2;
    margin-top: -4px;
  }
  .row {
    grid-template-columns: 96px 44px minmax(0, 1fr) 24px;
    gap: 8px;
  }
}
@media (prefers-reduced-motion: reduce) {
  .bar i,
  .log li {
    animation: none;
  }
}
</style>
