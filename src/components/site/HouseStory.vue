<!--
  The About story, folded into House. The mangrove grows in when it comes into
  view, and each paragraph inks in word by word as it crosses the reading line. Copy is the
  house's About text as supplied by the members.
-->
<template>
  <div class="story">
    <div ref="art" class="art">
      <MangroveArt :p="grown" />
    </div>

    <div class="text">
      <p
        v-for="(para, pi) in PARAS"
        :key="pi"
        :ref="(el) => (paraEls[pi] = el)"
        class="para"
        :class="{ lead: pi === 0 }"
        :style="{ '--r': ink[pi] }"
      >
        <span v-for="(w, i) in para" :key="i" class="w" :style="{ '--i': i }">{{ w }}</span>
      </p>

      <ol class="values">
        <li v-for="(v, i) in VALUES" :key="v.title" v-inview :style="{ '--i': i }">
          <span class="num mono">0{{ i + 1 }}</span>
          <strong>{{ v.title }}</strong>
          <span>{{ v.desc }}</span>
        </li>
      </ol>
    </div>
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted, reactive, ref } from 'vue';
import MangroveArt from './MangroveArt.vue';

const PARAS = [
  'Sundarbans House has been one of the most recognized houses throughout the IIT Madras BS. This recognition reflects the dedication, teamwork, and continuous efforts of our members. Our former secretaries have played a significant role in strengthening the house, improving its activities, and building a strong foundation for future generations.',
  'Since its founding, Sundarbans House has undergone a remarkable transformation. The journey from its early days to where it stands today has been filled with challenges, learning experiences, and countless efforts. The journey was never easy; it took determination, resilience, and the collective contribution of students and former secretaries to shape the house into what it is today. Every milestone achieved, every challenge overcome, and every effort made has become a part of our legacy. The foundation laid by those who came before us continues to inspire us to aim higher and carry the house forward with pride.',
  'Our vision is to create a collaborative and inclusive environment where every student feels welcomed, valued, and encouraged to participate. We believe that the true spirit of a house lies in the connections we build, the experiences we share, and the memories we create together.',
  'Our mission is to build a united, collaborative, and vibrant community where every student belongs, every contribution matters, and every experience becomes a lasting memory. We aspire to honour the legacy of our founders and predecessors while continuing to evolve, overcome challenges, and create an even brighter future for Sundarbans House.',
].map((p) => p.split(' ').map((w) => `${w} `)); // trailing space kept so lines wrap

const VALUES = [
  {
    title: 'Academic excellence',
    desc: 'A culture of learning, peer mentorship and high achievement.',
  },
  {
    title: 'Community spirit',
    desc: 'Lasting connections across the country, celebrating our differences.',
  },
  {
    title: 'Growth mindset',
    desc: 'Every student reaching their potential through innovation and resilience.',
  },
];

const art = ref(null);
const paraEls = [];
const ink = reactive(PARAS.map(() => 0));
const grown = ref(0);
const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;

// The tree grows once, when it comes into view: roots, trunk, branches, then the canopy.
let raf = 0;
function grow() {
  const t0 = performance.now();
  const tick = (t) => {
    const k = Math.min(1, (t - t0) / 2600);
    grown.value = 1 - Math.pow(1 - k, 2.2);
    if (k < 1) raf = requestAnimationFrame(tick);
  };
  raf = requestAnimationFrame(tick);
}
const artIO = new IntersectionObserver(
  ([en]) => {
    if (!en.isIntersecting) return;
    artIO.disconnect();
    if (reduced) grown.value = 1;
    else grow();
  },
  { threshold: 0.3 }
);

// Each paragraph inks in word by word as it rises past the reading line.
function measure() {
  const vh = innerHeight;
  PARAS.forEach((words, i) => {
    const r = paraEls[i]?.getBoundingClientRect();
    if (!r) return;
    const p = Math.min(1, Math.max(0, (vh * 0.86 - r.top) / (vh * 0.4)));
    ink[i] = reduced ? 999 : p * (words.length + 4);
  });
}

const io = new IntersectionObserver(
  (entries) => {
    for (const en of entries)
      if (en.isIntersecting) {
        en.target.classList.add('in');
        io.unobserve(en.target);
      }
  },
  { rootMargin: '0px 0px -10% 0px' }
);
const vInview = { mounted: (el) => io.observe(el), unmounted: (el) => io.unobserve(el) };

onMounted(() => {
  artIO.observe(art.value);
  measure();
  addEventListener('scroll', measure, { passive: true });
  addEventListener('resize', measure);
});
onBeforeUnmount(() => {
  cancelAnimationFrame(raf);
  artIO.disconnect();
  io.disconnect();
  removeEventListener('scroll', measure);
  removeEventListener('resize', measure);
});
</script>

<style scoped>
.story {
  display: grid;
  grid-template-columns: minmax(0, 5fr) minmax(0, 6fr);
  gap: 48px;
  align-items: start;
}
.art {
  position: sticky;
  top: calc(var(--nav-h) + 72px);
}
.para {
  margin: 0 0 22px;
  font-size: clamp(19px, 2vw, 23px);
  line-height: 1.45;
  letter-spacing: -0.012em;
  font-weight: 520;
  text-wrap: pretty;
}
.para.lead {
  font-size: clamp(24px, 2.8vw, 32px);
  line-height: 1.22;
  letter-spacing: -0.025em;
  font-weight: 650;
}
.w {
  opacity: clamp(0.16, calc(0.16 + (var(--r) - var(--i)) * 0.84), 1);
  transition: opacity 0.12s linear;
}

.values {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 18px;
  margin: 34px 0 0;
  padding: 22px 0 0;
  list-style: none;
  border-top: 1px solid var(--line);
}
.values li {
  display: grid;
  gap: 4px;
  opacity: 0;
  transform: translateY(14px);
  transition:
    opacity 0.6s var(--ease-out),
    transform 0.7s var(--ease-out);
  transition-delay: calc(var(--i) * 110ms);
}
.values li.in {
  opacity: 1;
  transform: none;
}
.num {
  font-size: 12px;
  color: var(--mari-ink);
  font-weight: 600;
}
.values strong {
  font-size: 16px;
  font-weight: 700;
  letter-spacing: -0.01em;
}
.values span:last-child {
  font-size: 14px;
  line-height: 1.45;
  color: var(--ink-2);
}

@media (max-width: 860px) {
  .story {
    grid-template-columns: minmax(0, 1fr);
    gap: 8px;
  }
  .art {
    position: relative;
    top: 0;
    max-width: 420px;
    width: 100%;
    margin: 0 auto;
  }
  .values {
    grid-template-columns: minmax(0, 1fr);
  }
}
@media (prefers-reduced-motion: reduce) {
  .values li {
    opacity: 1;
    transform: none;
    transition: none;
  }
}
</style>
