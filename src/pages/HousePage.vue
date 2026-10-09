<!--
  House: the public face of the house. Story (the About page, folded in) →
  the Upper House Council (everyone else is on Teams) → where we meet (regions + meetups) →
  the lounge door, which leads to the Lounge tab. A sticky section rail tracks where you are.
-->
<template>
  <main class="wrap">
    <header class="head rise" style="--i: 0">
      <h1>House</h1>
      <dl class="stats">
        <div v-for="s in STATS" :key="s.label">
          <dt>{{ s.label }}</dt>
          <dd class="mono">{{ shown[s.key] }}</dd>
        </div>
      </dl>
      <p class="sub">
        One of the student houses of the IIT Madras BS, since 2021. Who we are, who runs the house,
        and where we meet.
      </p>
    </header>

    <SectionRail
      ref="rail"
      class="rise"
      style="--i: 1"
      :sections="SECTIONS"
      label="House sections"
    />

    <section id="story" class="sec" aria-labelledby="story-h">
      <h2 id="story-h" class="sec-h"><span class="mono">01</span> Who we are</h2>
      <HouseStory />
    </section>

    <section id="council" class="sec" aria-labelledby="council-h">
      <h2 id="council-h" class="sec-h"><span class="mono">02</span> The council, 2026–27</h2>
      <p class="sec-sub">
        The Upper House Council runs the house. The regional coordinators, communities and crew are
        on Teams.
      </p>
      <CouncilTrio @region="openRegion" />
    </section>

    <section id="regions" class="sec" aria-labelledby="regions-h">
      <h2 id="regions-h" class="sec-h"><span class="mono">03</span> Where we meet</h2>
      <div class="meet">
        <RegionSky class="sky" />
        <RegionPanel />
      </div>
    </section>

    <section id="lounge" class="sec" aria-labelledby="lounge-h">
      <LoungeDoor teaser />
    </section>
    <PhotoViewer />
  </main>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue';
import SectionRail from '../components/site/SectionRail.vue';
import HouseStory from '../components/site/HouseStory.vue';
import CouncilTrio from '../components/site/CouncilTrio.vue';
import RegionSky from '../components/site/RegionSky.vue';
import RegionPanel from '../components/site/RegionPanel.vue';
import LoungeDoor from '../components/site/LoungeDoor.vue';
import PhotoViewer from '../components/site/PhotoViewer.vue';
import { council, house, meetupCount, regions } from '../lib/house.js';

const SECTIONS = [
  { id: 'story', label: 'Story' },
  { id: 'council', label: 'Council' },
  { id: 'regions', label: 'Regions' },
  { id: 'lounge', label: 'Lounge' },
];

const STATS = [
  { key: 'council', label: 'council', to: council.length },
  { key: 'regions', label: 'regions', to: regions.length },
  { key: 'meetups', label: 'meetups', to: meetupCount },
];
const shown = reactive(Object.fromEntries(STATS.map((s) => [s.key, 0])));
function countUp() {
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
}

const rail = ref(null);
function openRegion(id) {
  house.region = id;
  house.meetup = null;
  rail.value.goTo('regions');
}

onMounted(countUp);
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
.sec-sub {
  margin: -12px 0 22px;
  max-width: 60ch;
  font-size: 15px;
  color: var(--ink-2);
}
.sec-h span {
  margin-right: 8px;
  font-size: 13px;
  font-weight: 500;
  color: var(--mari-ink);
  vertical-align: 0.5em;
}
#lounge {
  border-top: 0;
}

.meet {
  display: grid;
  grid-template-columns: minmax(0, 1.25fr) minmax(0, 1fr);
  gap: 28px;
  align-items: start;
}
.meet .sky {
  position: sticky;
  top: calc(var(--nav-h) + 64px);
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
  .meet {
    grid-template-columns: minmax(0, 1fr);
  }
  .meet .sky {
    position: relative;
    top: 0;
  }
}
@media (max-width: 560px) {
  .wrap {
    padding: 14px 16px 90px;
  }
}
</style>
