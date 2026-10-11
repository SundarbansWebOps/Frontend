<!--
  The doorway to the contribution form. The raw Google Form link lives only here, so the rest of
  the site points at /contribute-resources and the form can move without touching every CTA.
-->
<template>
  <main class="wrap">
    <p class="eyebrow mono rise" style="--i: 0">Contribute</p>
    <h1 class="rise" style="--i: 1">Add your notes &amp; past papers</h1>
    <p class="sub rise" style="--i: 2">
      {{ intro }}
    </p>
    <div class="acts rise" style="--i: 3">
      <a v-if="!isPlaceholder" class="cta" :href="FORM" target="_blank" rel="noopener">
        Open the contribution form <span aria-hidden="true">↗</span>
      </a>
      <RouterLink class="back" to="/resources">Back to Resources</RouterLink>
    </div>
  </main>
</template>

<script setup>
import { onBeforeUnmount, onMounted } from 'vue';

// Placeholder until Raja supplies the live form; every "contribute" link reaches it through here.
const FORM = 'https://forms.gle/your-form-id';
const isPlaceholder = FORM.includes('your-form-id');

const intro = isPlaceholder
  ? 'The contribution form isn’t live yet — check back soon, or head back to Resources.'
  : 'Taking you to the contribution form — it should open in a moment. If it doesn’t, open it yourself below.';

let timer;
onMounted(() => {
  if (isPlaceholder) return;
  // Replace, not assign: the reader leaves the site, and Back returns to Resources, not here.
  // 1.8s clears the entrance animation (~910ms), so the fallback buttons are actually seen.
  timer = setTimeout(() => window.location.replace(FORM), 1800);
});
onBeforeUnmount(() => clearTimeout(timer));
</script>

<style scoped>
.wrap {
  display: grid;
  justify-items: center;
  align-content: center;
  gap: 12px;
  min-height: calc(100svh - var(--nav-h) - 180px);
  padding: 40px 24px 80px;
  text-align: center;
}
.eyebrow {
  margin: 0;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: var(--mari-ink);
}
h1 {
  margin: 0;
  max-width: 20ch;
  font-size: clamp(28px, 4vw, 40px);
  font-weight: 750;
  letter-spacing: -0.04em;
  line-height: 1.02;
}
.sub {
  margin: 2px 0 0;
  max-width: 46ch;
  color: var(--ink-2);
  font-size: 16px;
  line-height: 1.5;
}
.acts {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  gap: 10px;
  margin-top: 10px;
}
.cta,
.back {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 11px 20px;
  border-radius: 99px;
  font-size: 15px;
  font-weight: 650;
  text-decoration: none;
  transition:
    background 0.2s,
    transform 0.25s var(--ease-spring);
}
.cta {
  background: var(--mari);
  color: var(--on-mari);
}
.back {
  padding: 11px 18px;
  border: 1.5px solid var(--line-strong);
  color: var(--ink);
}
.cta:hover,
.back:hover {
  transform: translateY(-1px);
}
.back:hover {
  background: var(--sunk);
}
@media (max-width: 560px) {
  .wrap {
    padding: 24px 16px 90px;
  }
}
</style>
