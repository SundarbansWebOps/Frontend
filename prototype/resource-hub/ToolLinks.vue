<!-- PROTOTYPE — the portals students actually open, one tap each. -->
<template>
  <ul class="tools">
    <li v-for="(t, i) in TOOLS" :key="t.id" :style="{ '--i': i }" class="rise">
      <a
        :href="t.href"
        :target="t.internal ? undefined : '_blank'"
        rel="noopener"
        @click="
          t.internal && ($event.preventDefault(), toast(`${t.label} isn’t part of this prototype`))
        "
      >
        <span class="ico"><LineIcon :name="t.icon" /></span>
        <span class="txt">
          <b>{{ t.label }}</b>
          <small>{{ t.hint }}</small>
        </span>
        <span class="arr" aria-hidden="true">{{ t.internal ? '→' : '↗' }}</span>
      </a>
    </li>
  </ul>
</template>

<script setup>
import LineIcon from './LineIcon.vue';
import { TOOLS } from './data.js';
import { toast } from './store.js';
</script>

<style scoped>
.tools {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 8px;
  grid-template-columns: repeat(auto-fill, minmax(230px, 1fr));
}
a {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 12px;
  padding: 11px 12px;
  border-radius: 12px;
  text-decoration: none;
  border: 1px solid var(--line);
  background: var(--card);
  transition:
    border-color 0.2s,
    transform 0.3s var(--ease-out);
}
a:hover {
  border-color: var(--ink-3);
  transform: translateY(-1px);
}
.ico {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  border-radius: 10px;
  background: var(--sunk);
  color: var(--ink);
  transition:
    background 0.25s,
    transform 0.4s var(--ease-spring);
}
a:hover .ico {
  background: var(--mari);
  color: var(--on-mari);
  transform: rotate(-6deg);
}
.txt {
  display: grid;
  min-width: 0;
}
b {
  font-size: 14.5px;
  font-weight: 620;
}
small {
  font-size: 12px;
  color: var(--ink-2);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.arr {
  color: var(--ink-3);
  transition: transform 0.3s var(--ease-out);
}
a:hover .arr {
  transform: translateX(3px);
  color: var(--ink);
}
</style>
