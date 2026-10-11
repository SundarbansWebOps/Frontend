<!--
  Teams-page doorway into the Legacy Board. Same card chrome as a council card
  (PersonCard front): paper card, line, shadow. Names are the latest council only.
-->
<template>
  <RouterLink class="entry" to="/teams/legacy">
    <img class="motif" :src="boat" alt="" width="78" height="32" />
    <span class="copy">
      <span class="line">
        <span class="title">Legacy Board</span>
        <span class="years">{{ FOUNDED }}–{{ latest.year }}</span>
      </span>
      <span class="who">{{ latest.secretary.name }} <small>Secretary</small></span>
      <span class="who">{{ latest.deputy.name }} <small>Deputy Secretary</small></span>
    </span>
  </RouterLink>
</template>

<script setup>
import boat from '../../assets/legacy/a-boat.webp';
import { FOUNDED, LEGACY } from '../../data/legacy.data.js';

const latest = LEGACY[LEGACY.length - 1];
</script>

<style scoped>
.entry {
  display: flex;
  align-items: center;
  gap: 10px;
  width: max-content;
  max-width: min(340px, 100%);
  padding: 7px 12px 7px 8px;
  border: 1px solid var(--line);
  border-radius: 16px;
  background: var(--card);
  box-shadow: var(--shadow);
  text-decoration: none;
}
.entry:hover {
  background: var(--sunk);
}
.motif {
  display: block;
  width: auto;
  height: 34px;
  flex: none;
}
.copy {
  display: grid;
  gap: 1px;
  min-width: 0;
}
.line {
  display: flex;
  align-items: baseline;
  gap: 8px;
}
.title {
  font-size: 14px;
  font-weight: 750;
  letter-spacing: -0.02em;
  line-height: 1.1;
}
.years {
  font-size: 12px;
  font-weight: 600;
  color: var(--ink-3);
  font-variant-numeric: tabular-nums;
}
.who {
  font-size: 12.5px;
  font-weight: 600;
  line-height: 1.25;
  color: var(--ink-2);
  white-space: nowrap;
}
.who small {
  margin-left: 4px;
  font-size: 10.5px;
  font-weight: 650;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--ink-3);
}
@media (max-width: 900px) {
  .entry {
    width: 100%;
    max-width: none;
  }
}
@media (max-width: 560px) {
  .who {
    white-space: normal;
  }
}
</style>
