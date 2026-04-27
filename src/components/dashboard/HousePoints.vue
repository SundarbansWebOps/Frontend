<template>
  <div class="widget w-6" id="widget-points" ref="widgetRef">
    <div class="widget-glow"
         style="width:320px;height:320px;
                background:radial-gradient(circle,rgba(201,168,76,.14),transparent);
                top:-100px;left:-80px">
    </div>

    <div class="widget-label">Live Total</div>
    <div class="widget-title">House Points</div>

    <!-- Animated total counter -->
    <div class="points-total-wrap">
      <span class="points-total">{{ displayTotal }}</span>
      <div class="points-total-label">Total Points · Season 2</div>
    </div>

    <!-- Category breakdown bars -->
    <div class="points-categories">
      <div class="points-cat" v-for="c in cats" :key="c.name">
        <div class="points-cat-icon">{{ c.icon }}</div>
        <div class="points-cat-info">
          <div class="points-cat-name">{{ c.name }}</div>
          <div class="points-cat-bar">
            <div
              class="points-cat-fill"
              :style="{ background: c.color, width: animFired ? Math.round(c.points / c.max * 100) + '%' : '0%' }"
            ></div>
          </div>
        </div>
        <div class="points-cat-val">{{ c.points }}</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';

const props = defineProps({
  config: { type: Object, default: null }
});

const cats = props.config ? props.config.categories : [
  { name:'Academic',  icon:'📚', points:312, max:400, color:'#e8c97a' },
  { name:'Cultural',  icon:'🎭', points:198, max:400, color:'#b07ae0' },
  { name:'Sports',    icon:'🏏', points:241, max:400, color:'#4caf50' },
  { name:'Community', icon:'🤝', points:167, max:400, color:'#7ab0e0' }
];

const TOTAL = cats.reduce((s, c) => s + c.points, 0);

const displayTotal = ref(0);
const animFired = ref(false);
const widgetRef = ref(null);
let observer = null;

function animateCount(target, dur) {
  const start = performance.now();
  function tick(now) {
    const t = Math.min((now - start) / dur, 1);
    const ease = 1 - Math.pow(1 - t, 3);
    displayTotal.value = Math.round(target * ease);
    if (t < 1) requestAnimationFrame(tick);
  }
  tick(start);
}

onMounted(() => {
  observer = new IntersectionObserver((entries) => {
    entries.forEach((e) => {
      if (e.isIntersecting && !animFired.value) {
        animFired.value = true;
        animateCount(TOTAL, 2000);
      }
    });
  }, { threshold: 0.3 });

  if (widgetRef.value) {
    observer.observe(widgetRef.value);
  }
});

onUnmounted(() => {
  if (observer) observer.disconnect();
});
</script>
