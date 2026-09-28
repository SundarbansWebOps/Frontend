<!--
  Teams: everyone who runs the house, 2026–27. How the house works (drawn as a
  river) → the Upper House Council → the Lower House Council (a coordinator per region) → the
  communities → the crew. A coordinator's region chip opens that region on House.
-->
<template>
  <main class="wrap">
    <header class="head rise" style="--i: 0">
      <h1>Teams</h1>
      <dl class="stats">
        <div v-for="s in STATS" :key="s.label">
          <dt>{{ s.label }}</dt>
          <dd class="mono">{{ shown[s.key] }}</dd>
        </div>
      </dl>
      <p class="sub">The people who run Sundarbans in 2026–27, and how the house fits together.</p>
    </header>

    <SectionRail
      ref="rail"
      class="rise"
      style="--i: 1"
      :sections="SECTIONS"
      label="Teams sections"
    />

    <section id="how" class="sec" aria-labelledby="how-h">
      <h2 id="how-h" class="sec-h"><span class="mono">01</span> How the house works</h2>
      <p class="sec-sub">
        One council, three channels, one house. Tap any part to meet the people in it.
        <em class="draft mono">structure to confirm</em>
      </p>
      <HouseFlow @go="(id) => rail.goTo(id)" />
    </section>

    <section id="uhc" class="sec" aria-labelledby="uhc-h">
      <h2 id="uhc-h" class="sec-h"><span class="mono">02</span> Upper House Council</h2>
      <p class="sec-sub">Secretary, Deputy Secretary and Web Admin. They run the house.</p>
      <CouncilDeck :people="upper" size="big" @region="toRegion" />
    </section>

    <section id="lhc" class="sec" aria-labelledby="lhc-h">
      <h2 id="lhc-h" class="sec-h"><span class="mono">03</span> Lower House Council</h2>
      <p class="sec-sub">
        A coordinator for each region runs its meetups and WhatsApp group, with city coordinators
        and volunteers. Tap a region to see its meetups.
      </p>
      <CouncilDeck :people="lower" @region="toRegion" />
    </section>

    <section id="communities" class="sec" aria-labelledby="com-h">
      <h2 id="com-h" class="sec-h"><span class="mono">04</span> Communities</h2>
      <p class="sec-sub">They run the house’s events.</p>
      <TeamCards :teams="COMMUNITIES" />
    </section>

    <section id="crew" class="sec" aria-labelledby="crew-h">
      <h2 id="crew-h" class="sec-h"><span class="mono">05</span> Crew</h2>
      <p class="sec-sub">They keep the house seen and online.</p>
      <TeamCards :teams="CREW" />
    </section>
  </main>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue';
import SectionRail from '../components/site/SectionRail.vue';
import HouseFlow from '../components/site/HouseFlow.vue';
import CouncilDeck from '../components/site/CouncilDeck.vue';
import TeamCards from '../components/site/TeamCards.vue';
import { council, house, lower, regions, upper } from '../lib/house.js';
import { COMMUNITIES, CREW } from '../data/teams.js';
import { nav } from '../lib/store.js';

const SECTIONS = [
  { id: 'how', label: 'How it works' },
  { id: 'uhc', label: 'Council' },
  { id: 'lhc', label: 'Regions' },
  { id: 'communities', label: 'Communities' },
  { id: 'crew', label: 'Crew' },
];

const STATS = [
  { key: 'council', label: 'council', to: council.length },
  { key: 'regions', label: 'regions', to: regions.length },
  { key: 'teams', label: 'teams', to: COMMUNITIES.length + CREW.length },
];
const shown = reactive(Object.fromEntries(STATS.map((s) => [s.key, 0])));
onMounted(() => {
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
    for (const s of STATS) shown[s.key] = s.to;
    return;
  }
  const t0 = performance.now();
  const tick = (t) => {
    const k = Math.min(1, (t - t0) / 1200);
    const e = 1 - Math.pow(1 - k, 3);
    for (const s of STATS) shown[s.key] = Math.round(s.to * e);
    if (k < 1) requestAnimationFrame(tick);
  };
  requestAnimationFrame(tick);
});

const rail = ref(null);
function toRegion(id) {
  house.region = id;
  house.meetup = null;
  nav.go('house', 'regions');
}
</script>

<style scoped>
.wrap {
  max-width: 1240px;
  margin: 0 auto;
  padding: 18px 24px 80px;
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 18px;
}
.head {
  display: grid;
  grid-template-columns: auto 1fr;
  align-items: end;
  gap: 4px 28px;
}
h1 {
  margin: 0;
  font-size: clamp(34px, 4.4vw, 48px);
  font-weight: 750;
  letter-spacing: -0.04em;
  line-height: 0.95;
}
.stats {
  display: flex;
  justify-content: flex-end;
  gap: 26px;
  margin: 0;
}
.stats div {
  display: flex;
  flex-direction: column-reverse;
  align-items: flex-end;
}
.stats dt {
  font-size: 12px;
  color: var(--ink-2);
}
.stats dd {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
  letter-spacing: -0.04em;
  line-height: 1;
  font-variant-numeric: tabular-nums;
}
.sub {
  grid-column: 1 / -1;
  margin: 4px 0 0;
  font-size: 15px;
  color: var(--ink-2);
}
.sec {
  padding-top: 34px;
  scroll-margin-top: 120px;
}
.sec + .sec {
  margin-top: 26px;
  border-top: 1px solid var(--line);
}
.sec-h {
  margin: 0 0 22px;
  font-size: clamp(24px, 2.6vw, 30px);
  font-weight: 750;
  letter-spacing: -0.035em;
}
.sec-h span {
  margin-right: 8px;
  font-size: 13px;
  font-weight: 500;
  color: var(--mari-ink);
  vertical-align: 0.5em;
}
.sec-sub {
  margin: -12px 0 22px;
  max-width: 62ch;
  font-size: 15px;
  line-height: 1.5;
  color: var(--ink-2);
}
.draft {
  display: inline-block;
  margin-left: 6px;
  padding: 2px 8px;
  border: 1px dashed var(--line-strong);
  border-radius: 99px;
  font-size: 11px;
  font-style: normal;
  vertical-align: 1px;
}
@media (max-width: 900px) {
  .head {
    grid-template-columns: 1fr;
  }
  .stats {
    justify-content: flex-start;
  }
  .stats div {
    align-items: flex-start;
  }
}
@media (max-width: 560px) {
  .wrap {
    padding: 14px 16px 90px;
  }
}
</style>
