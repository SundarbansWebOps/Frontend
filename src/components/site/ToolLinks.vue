<!-- Quick links expand from their card into a floating window without reflowing the grid. -->
<template>
  <ul class="tools">
    <li v-for="(tool, i) in TOOLS" :key="tool.id" :style="{ '--i': i }" class="tool-item rise">
      <button
        v-if="tool.options?.length"
        :ref="(el) => setTrigger(tool.id, el)"
        type="button"
        class="tool-card"
        :class="{ concealed: activeTool?.id === tool.id }"
        aria-haspopup="dialog"
        :aria-expanded="activeTool?.id === tool.id"
        :aria-controls="activeTool?.id === tool.id ? `resource-window-${tool.id}` : undefined"
        @click="openTool(tool)"
      >
        <span class="ico"><LineIcon :name="tool.icon" /></span>
        <span class="txt">
          <b>{{ tool.label }}</b>
          <small>{{ tool.hint }}</small>
        </span>
        <span class="arr" aria-hidden="true">↗</span>
      </button>
      <a
        v-else
        class="tool-card"
        :href="tool.href"
        :target="tool.internal ? undefined : '_blank'"
        :rel="tool.internal ? undefined : 'noopener noreferrer'"
        @click="handleDirect(tool, $event)"
      >
        <span class="ico"><LineIcon :name="tool.icon" /></span>
        <span class="txt">
          <b>{{ tool.label }}</b>
          <small>{{ tool.hint }}</small>
        </span>
        <span class="arr" aria-hidden="true">{{ tool.internal ? '→' : '↗' }}</span>
      </a>
    </li>
  </ul>

  <Teleport to="body">
    <div v-if="activeTool" class="floating-layer" @click.self="closeTool">
      <section
        ref="windowElement"
        class="resource-window"
        :class="{ expanded: contentVisible }"
        :style="windowStyle"
        :id="`resource-window-${activeTool.id}`"
        role="dialog"
        aria-modal="true"
        :aria-labelledby="`resource-title-${activeTool.id}`"
        tabindex="-1"
      >
        <header class="window-head">
          <div class="window-title">
            <p class="window-kicker mono">Quick link</p>
            <h2 :id="`resource-title-${activeTool.id}`">{{ activeTool.label }}</h2>
            <p class="window-hint">{{ activeTool.hint }}</p>
          </div>
          <button class="close" type="button" aria-label="Close" @click="closeTool">
            <svg viewBox="0 0 20 20" aria-hidden="true"><path d="m5 5 10 10M15 5 5 15" /></svg>
          </button>
        </header>

        <ul class="resource-options">
          <li v-for="(option, index) in optionsFor(activeTool)" :key="option.label">
            <a
              v-if="option.href"
              :href="option.href"
              :target="option.internal ? undefined : '_blank'"
              :rel="option.internal ? undefined : 'noopener noreferrer'"
              class="resource-option"
              :style="{ '--i': index }"
            >
              <span class="option-copy">
                <b>{{ option.label }}</b>
                <small v-if="option.hint">{{ option.hint }}</small>
              </span>
              <span class="option-arrow" aria-hidden="true">{{ option.internal ? '→' : '↗' }}</span>
            </a>
            <div v-else class="resource-option unavailable" :style="{ '--i': index }">
              <span class="option-copy">
                <b>{{ option.label }}</b>
                <small>{{ option.hint || 'Coming soon' }}</small>
              </span>
              <span class="option-status">Soon</span>
            </div>
          </li>
        </ul>
      </section>
    </div>
  </Teleport>
</template>

<script setup>
import { nextTick, onBeforeUnmount, onMounted, ref } from 'vue';
import LineIcon from './LineIcon.vue';
import { TOOLS } from '../../lib/courses.js';
import { toast } from '../../lib/store.js';

const activeTool = ref(null);
const contentVisible = ref(false);
const windowElement = ref(null);
const windowStyle = ref({});
const triggers = new Map();
let sourceRect = null;
let motion = null;
let opening = false;

function setTrigger(id, element) {
  if (element) triggers.set(id, element);
  else triggers.delete(id);
}

function handleDirect(tool, event) {
  if (!tool.soon) return;
  event.preventDefault();
  toast(`${tool.label} is coming soon`);
}

function optionsFor(tool) {
  return tool.options ?? [];
}

function rectStyle(rect) {
  return {
    left: `${rect.left}px`,
    top: `${rect.top}px`,
    width: `${rect.width}px`,
    height: `${rect.height}px`,
  };
}

function expandedRect(tool, source) {
  const width = Math.min(500, window.innerWidth - 32);
  const height = Math.min(164 + optionsFor(tool).length * 70, window.innerHeight - 32);
  return {
    left: Math.max(16, Math.min(source.left, window.innerWidth - width - 16)),
    top: Math.max(16, Math.min(source.top, window.innerHeight - height - 16)),
    width,
    height,
  };
}

async function animateWindow(from, to, duration = 320) {
  await nextTick();
  const element = windowElement.value;
  if (!element || matchMedia('(prefers-reduced-motion: reduce)').matches) {
    windowStyle.value = rectStyle(to);
    return;
  }
  motion?.cancel();
  motion = element.animate(
    [
      { ...rectStyle(from), borderRadius: '12px' },
      { ...rectStyle(to), borderRadius: '22px' },
    ],
    { duration, easing: 'cubic-bezier(.2, .8, .2, 1)', fill: 'forwards' }
  );
  try {
    await motion.finished;
  } catch {
    return;
  }
  windowStyle.value = rectStyle(to);
  await nextTick();
  motion?.cancel();
}

async function openTool(tool) {
  if (activeTool.value) return;
  const trigger = triggers.get(tool.id);
  if (!trigger) return;
  sourceRect = trigger.getBoundingClientRect();
  const source = {
    left: sourceRect.left,
    top: sourceRect.top,
    width: sourceRect.width,
    height: sourceRect.height,
  };
  const destination = expandedRect(tool, source);
  opening = true;
  contentVisible.value = false;
  windowStyle.value = rectStyle(source);
  activeTool.value = tool;
  await animateWindow(source, destination);
  if (activeTool.value?.id === tool.id) {
    contentVisible.value = true;
    await nextTick();
    windowElement.value?.focus();
  }
  opening = false;
}

async function closeTool() {
  if (!activeTool.value || opening) return;
  const closingId = activeTool.value.id;
  contentVisible.value = false;
  const element = windowElement.value;
  const current = element?.getBoundingClientRect();
  const from = current
    ? { left: current.left, top: current.top, width: current.width, height: current.height }
    : null;
  if (from && sourceRect) await animateWindow(from, sourceRect, 220);
  activeTool.value = null;
  windowStyle.value = {};
  nextTick(() => triggers.get(closingId)?.focus());
}

function onKeydown(event) {
  if (event.key === 'Escape' && activeTool.value) closeTool();
}

onMounted(() => document.addEventListener('keydown', onKeydown));
onBeforeUnmount(() => {
  document.removeEventListener('keydown', onKeydown);
  motion?.cancel();
});
</script>

<style scoped>
.tools {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 8px;
  grid-template-columns: repeat(auto-fill, minmax(min(230px, 100%), 1fr));
}
.tool-item {
  min-width: 0;
}
.tool-card {
  width: 100%;
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto;
  align-items: center;
  gap: 12px;
  padding: 11px 12px;
  border-radius: 12px;
  text-align: left;
  border: 1px solid var(--line);
  background: var(--card);
  color: var(--ink);
  font: inherit;
  text-decoration: none;
  cursor: pointer;
  transition:
    border-color 0.2s,
    transform 0.3s var(--ease-out);
}
.tool-card.concealed {
  visibility: hidden;
}
.tool-card:hover {
  border-color: var(--mari-ink);
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
.tool-card:hover .ico {
  background: var(--mari-soft);
  color: var(--mari-ink);
  transform: rotate(-6deg);
}
.txt,
.option-copy {
  display: grid;
  min-width: 0;
}
.txt b,
.option-copy b {
  font-size: 14.5px;
  font-weight: 620;
}
.txt small,
.option-copy small {
  font-size: 12px;
  color: var(--ink-2);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.arr,
.option-arrow {
  color: var(--ink-3);
  transition:
    transform 0.3s var(--ease-out),
    color 0.2s;
}
.tool-card:hover .arr {
  transform: translate(2px, -2px);
  color: var(--mari-ink);
}
.floating-layer {
  position: fixed;
  z-index: 1200;
  inset: 0;
}
.resource-window {
  position: fixed;
  z-index: 1;
  display: grid;
  align-content: start;
  gap: 10px;
  overflow: auto;
  scrollbar-color: var(--line-strong) transparent;
  scrollbar-width: thin;
  padding: 16px;
  border: 1px solid var(--line-strong);
  border-radius: 12px;
  background: var(--card);
  box-shadow: var(--shadow);
  transform-origin: top left;
  outline: none;
  transition:
    border-radius 0.18s var(--ease-out),
    background 0.16s var(--ease-out);
}
.resource-window::-webkit-scrollbar {
  width: 8px;
}
.resource-window::-webkit-scrollbar-track {
  margin: 14px 0;
  background: transparent;
}
.resource-window::-webkit-scrollbar-thumb {
  border: 2px solid transparent;
  border-radius: 99px;
  background: var(--line-strong);
  background-clip: content-box;
}
.resource-window.expanded {
  border-radius: 22px;
  border-color: color-mix(in srgb, var(--mari-ink) 32%, var(--line-strong));
  background: color-mix(in srgb, var(--mari-soft) 16%, var(--paper));
}
.window-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  opacity: 0;
  transform: translateY(6px);
  transition:
    opacity 0.16s var(--ease-out),
    transform 0.16s var(--ease-out);
}
.resource-window.expanded .window-head,
.resource-window.expanded .resource-options {
  opacity: 1;
  transform: translateY(0);
}
.window-title {
  min-width: 0;
}
.window-kicker {
  width: fit-content;
  margin: 0 0 7px;
  padding: 3px 8px;
  border: 1px solid color-mix(in srgb, var(--mari-ink) 22%, var(--line));
  border-radius: 99px;
  background: var(--mari-soft);
  color: var(--mari-ink);
  font-size: 9px;
  font-weight: 650;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}
.window-head h2 {
  margin: 0;
  color: var(--ink);
  font-size: clamp(22px, 3vw, 28px);
  font-weight: 750;
  letter-spacing: -0.035em;
}
.window-hint {
  margin: 3px 0 0;
  color: var(--ink-2);
  font-size: 13px;
}
.close {
  flex: none;
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  border: 1px solid color-mix(in srgb, var(--mari-ink) 20%, var(--line));
  border-radius: 50%;
  background: color-mix(in srgb, var(--mari-soft) 44%, var(--card));
  color: var(--mari-ink);
  cursor: pointer;
  transition:
    background 0.16s,
    transform 0.2s var(--ease-out);
}
.close:hover {
  background: var(--mari-soft);
  transform: rotate(5deg);
}
.close svg {
  width: 16px;
  fill: none;
  stroke: currentColor;
  stroke-width: 1.8;
  stroke-linecap: round;
}
.resource-options {
  display: grid;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
  opacity: 0;
  transform: translateY(6px);
  transition:
    opacity 0.16s var(--ease-out) 0.05s,
    transform 0.16s var(--ease-out) 0.05s;
}
.resource-option {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  min-height: 58px;
  padding: 10px 14px;
  border: 1px solid color-mix(in srgb, var(--mari-ink) 18%, var(--line));
  border-radius: 12px;
  background: color-mix(in srgb, var(--mari-soft) 20%, var(--card));
  color: var(--ink);
  text-decoration: none;
  animation: option-in 0.24s var(--ease-out) backwards;
  animation-delay: calc(var(--i, 0) * 28ms + 35ms);
  transition:
    transform 0.2s var(--ease-out),
    border-color 0.2s,
    background 0.2s;
}
a.resource-option:hover {
  transform: translateY(-1px);
  border-color: color-mix(in srgb, var(--mari-ink) 54%, var(--line));
  background: color-mix(in srgb, var(--mari-soft) 66%, var(--card));
}
.option-arrow {
  flex: none;
  display: grid;
  place-items: center;
  width: 27px;
  height: 27px;
  border-radius: 50%;
  background: var(--mari-soft);
  color: var(--mari-ink);
  transition:
    transform 0.2s var(--ease-out),
    background 0.16s,
    color 0.16s;
}
a.resource-option:hover .option-arrow {
  transform: translate(1px, -1px);
  background: var(--mari);
  color: var(--on-mari);
}
.option-status {
  flex: none;
  padding: 3px 9px;
  border-radius: 99px;
  background: var(--mari-soft);
  color: var(--mari-ink);
  font-size: 11px;
}
@keyframes option-in {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
}
@media (max-width: 560px) {
  .resource-window {
    padding: 14px;
  }
}
@media (prefers-reduced-motion: reduce) {
  .tool-card,
  .ico,
  .resource-option,
  .window-head,
  .resource-options {
    animation: none;
    transition: none;
  }
}
</style>
