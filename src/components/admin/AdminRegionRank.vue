<!-- Meetups per region, ranked by turnout count (Super Admin only; an Overview card). -->
<template>
  <section aria-labelledby="rank-h">
    <h3 id="rank-h" class="rank-h">Meetups by region</h3>
    <ol class="rank">
      <li v-for="(g, i) in ranked" :key="g.id" class="row" :style="{ '--i': i }">
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
        <span class="bar"><i :style="{ '--w': g.items.length / ranked[0].items.length }" /></span>
        <span class="n mono">{{ g.items.length }}</span>
      </li>
    </ol>
  </section>
</template>

<script setup>
import { portrait, regions } from '../../lib/house.js';

// house.js already orders regions by meetup count, largest first.
const ranked = regions;
</script>

<style scoped>
.rank-h {
  margin: 0 0 10px;
  font-size: 15px;
  font-weight: 700;
  color: var(--ink);
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
  padding: 8px 10px;
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
.row:first-child .bar i {
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
@media (max-width: 560px) {
  .row {
    grid-template-columns: 96px 44px minmax(0, 1fr) 24px;
    gap: 8px;
  }
}
@media (prefers-reduced-motion: reduce) {
  .bar i {
    animation: none;
  }
}
</style>
