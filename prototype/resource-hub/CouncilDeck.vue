<!--
  PROTOTYPE — a tier of the council as a dealt hand (Teams page). When it scrolls in, the cards
  fly face down from one deck and turn over as they land. Names share one size per tier.
-->
<template>
  <ul ref="root" class="deck" :class="[size, { waiting: !dealt }]">
    <li v-for="p in people" :key="p.id" class="cc">
      <PersonCard :p="p" :size="size" show-meetups @region="$emit('region', $event)" />
    </li>
  </ul>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue';
import PersonCard from './PersonCard.vue';
import { useFitNames } from './fit.js';

defineProps({
  people: { type: Array, required: true },
  size: { type: String, default: 'card' },
});
defineEmits(['region']);

const root = ref(null);
const dealt = ref(false);
const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
useFitNames(root);

// Deal: every card starts on one deck (top centre, face down) and flies to its seat.
function deal() {
  dealt.value = true;
  if (reduced) return;
  const box = root.value.getBoundingClientRect();
  const deckX = box.left + box.width / 2;
  const deckY = box.top + 90;
  root.value.querySelectorAll('.cc').forEach((card, i) => {
    const r = card.getBoundingClientRect();
    const dx = deckX - (r.left + r.width / 2);
    const dy = deckY - (r.top + r.height / 2);
    const rot = ((i * 37) % 17) - 8;
    card.animate(
      [
        {
          transform: `translate(${dx}px, ${dy}px) rotate(${rot}deg) rotateY(180deg) scale(0.62)`,
          offset: 0,
        },
        {
          transform: `translate(${dx * 0.2}px, ${dy * 0.35 - 30}px) rotateY(120deg) scale(0.9)`,
          offset: 0.55,
        },
        { transform: 'none' },
      ],
      {
        duration: 1000,
        delay: i * 85,
        easing: 'cubic-bezier(.2,.75,.25,1.05)',
        fill: 'backwards',
      }
    );
  });
}

const io = new IntersectionObserver(
  ([en]) => {
    if (en.isIntersecting) {
      deal();
      io.disconnect();
    }
  },
  { threshold: 0.18 }
);
onMounted(() => io.observe(root.value));
onBeforeUnmount(() => io.disconnect());
</script>

<style scoped>
.deck {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(184px, 1fr));
  gap: 16px;
  margin: 0;
  padding: 0;
  list-style: none;
  perspective: 1400px;
}
.deck.big {
  grid-template-columns: repeat(3, minmax(0, 1fr));
  max-width: 760px;
}
.cc {
  transform-style: preserve-3d;
}
/* Before the deal the seats stay empty — the cards arrive from the deck. */
.waiting .cc {
  visibility: hidden;
}
@media (max-width: 560px) {
  .deck {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 10px;
  }
  .deck.big {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}
</style>
