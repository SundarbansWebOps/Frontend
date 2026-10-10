<template>
  <div class="wrap">
    <section class="pick" aria-labelledby="bp-h">
      <p class="eyebrow">Resources</p>
      <h2 id="bp-h">Which branch are you in?</h2>
      <p class="sub">Everything here — the course map, calendar, notes — follows your branch.</p>
      <div class="opts">
        <button
          v-for="b in list"
          :key="b.id"
          class="opt"
          type="button"
          @click="$emit('pick', b.id)"
        >
          <b>{{ b.short }} · {{ b.label }}</b>
          <span>{{ b.blurb }}</span>
        </button>
      </div>
    </section>
  </div>
</template>

<script setup>
import { BRANCHES } from '../../data/branches.js';

defineEmits(['pick']);
const list = Object.values(BRANCHES);
</script>

<style scoped>
.wrap {
  --acc: var(--verm);
  --acc-wash: color-mix(in srgb, var(--acc) 15%, transparent);
  max-width: 1240px;
  margin: 0 auto;
  padding: 60px 24px 80px;
  display: grid;
  gap: 28px;
  background:
    url('../../assets/pat/grain.webp') 0 0 / 512px 512px,
    var(--paper);
  background-blend-mode: multiply, normal;
}
.pick {
  max-width: 760px;
  margin: 0 auto;
  width: 100%;
  display: grid;
  gap: 14px;
}
.eyebrow {
  margin: 0;
  font-size: 13px;
  font-weight: 650;
  letter-spacing: 0.01em;
  color: var(--ink-2);
}
.pick h2 {
  margin: 0;
  font-size: clamp(28px, 4vw, 40px);
  letter-spacing: -0.02em;
}
.sub {
  margin: 0 0 10px;
  color: var(--ink-2);
  font-size: 15px;
}
.opts {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}
.opt {
  display: grid;
  gap: 8px;
  text-align: left;
  padding: 28px 26px;
  border: 1.5px solid var(--line-strong);
  border-radius: 18px;
  background:
    url('../../assets/pat/grain.webp') 0 0 / 512px 512px,
    var(--card);
  background-blend-mode: multiply, normal;
  color: var(--ink);
  cursor: pointer;
  box-shadow: var(--shadow);
  transition:
    border-color 0.25s,
    background 0.25s,
    transform 0.25s;
}
.opt:nth-child(odd) {
  transform: rotate(-0.4deg);
}
.opt:nth-child(even) {
  transform: rotate(0.4deg);
}
.opt b {
  font-size: 19px;
}
.opt span {
  font-size: 14.5px;
  color: var(--ink-2);
}
.opt:hover {
  border-color: var(--acc);
  transform: translateY(-3px) rotate(0deg);
}
@media (max-width: 760px) {
  .opts {
    grid-template-columns: 1fr;
  }
}
</style>
