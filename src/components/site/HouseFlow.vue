<template>
  <section class="mangrove-network" aria-labelledby="network-title">
    <header class="network-heading">
      <span class="eyebrow">THE SUNDARBANS NETWORK</span>
      <h2 id="network-title">One house, <em>many branches.</em></h2>
      <p>One council, three channels, one house.</p>
    </header>

    <div class="tree-canvas">
      <svg
        class="tree-wiring"
        viewBox="0 0 1000 1000"
        preserveAspectRatio="none"
        aria-hidden="true"
      >
        <defs>
          <linearGradient id="sundarbansBranchGold" x1="0" y1="0" x2="1" y2="0">
            <stop offset="0" stop-color="#bd873c" stop-opacity=".72" />
            <stop offset=".52" stop-color="#e1b66d" />
            <stop offset="1" stop-color="#bd873c" stop-opacity=".72" />
          </linearGradient>
        </defs>
        <!-- One uninterrupted council connection. The line ends at the node rims. -->
        <path
          class="main-wire"
          :class="{ 'is-active': activeBranch === 'council' }"
          d="M143 500 H281"
        />
        <!-- LHC fans out cleanly: upper branch, straight centre branch, lower branch. -->
        <path
          class="branch-wire branch-wire-regions"
          :class="{ 'is-active': activeBranch === 'regions' }"
          d="M303 500 C353 500 353 167 388 167"
        />
        <path
          class="branch-wire branch-wire-communities"
          :class="{ 'is-active': activeBranch === 'communities' }"
          d="M303 500 H388"
        />
        <path
          class="branch-wire branch-wire-crew"
          :class="{ 'is-active': activeBranch === 'crew' }"
          d="M303 500 C353 500 353 833 388 833"
        />
      </svg>

      <div class="tree-grid">
        <!-- Responsive council edge: this lives in the same grid as both nodes. -->
        <div class="council-wire" aria-hidden="true"></div>

        <div class="council-node uhc-node">
          <button
            class="council-dot"
            type="button"
            @mouseenter="activeBranch = 'council'"
            @mouseleave="activeBranch = null"
            @focus="activeBranch = 'council'"
            @blur="activeBranch = null"
            @click="emit('go', 'uhc')"
            aria-label="Open Upper House Council"
          >
            <span class="node-core"></span>
          </button>
          <div class="council-popover uhc-popover">
            <span class="seat-dots" aria-hidden="true"
              ><i v-for="n in upper.length" :key="n"></i
            ></span>
            <span class="level-label">LEVEL 01 · LEADERSHIP</span>
            <strong>Upper House Council</strong>
            <small>House leadership · {{ upper.length }} seats</small>
            <span class="avatars"
              ><img
                v-for="person in upper"
                :key="person.id"
                :src="portrait.face(person.img)"
                :alt="person.name"
            /></span>
          </div>
        </div>

        <div class="council-node lhc-node">
          <button
            class="council-dot"
            type="button"
            @mouseenter="activeBranch = 'council'"
            @mouseleave="activeBranch = null"
            @focus="activeBranch = 'council'"
            @blur="activeBranch = null"
            @click="emit('go', 'lhc')"
            aria-label="Open Lower House Council"
          >
            <span class="node-core"></span>
          </button>
          <div class="council-popover lhc-popover">
            <span class="level-label">LEVEL 02 · COORDINATION</span>
            <strong>Lower House Council</strong>
          </div>
        </div>

        <section
          class="branch-hub regions-hub"
          :class="{ active: activeBranch === 'regions' }"
          @mouseenter="activeBranch = 'regions'"
          @mouseleave="activeBranch = null"
          @focusin="activeBranch = 'regions'"
          @focusout="onBranchFocusOut"
        >
          <button type="button" class="hub-hit" @click="emit('go', 'lhc')">
            <span class="hub-ring">✳</span
            ><span class="hub-copy"
              ><small>GEOGRAPHICAL NETWORK</small
              ><strong
                >Regions <i>{{ regionNodes.length }}</i></strong
              ><em>Students across cities</em></span
            >
          </button>
        </section>

        <section
          class="branch-hub communities-hub"
          :class="{ active: activeBranch === 'communities' }"
          @mouseenter="activeBranch = 'communities'"
          @mouseleave="activeBranch = null"
          @focusin="activeBranch = 'communities'"
          @focusout="onBranchFocusOut"
        >
          <button type="button" class="hub-hit" @click="emit('go', 'communities')">
            <span class="hub-ring">✿</span
            ><span class="hub-copy"
              ><small>CULTURE & ACTIVITIES</small
              ><strong
                >Communities <i>{{ COMMUNITIES.length }}</i></strong
              ><em>Experiences that bring us together</em></span
            >
          </button>
        </section>

        <section
          class="branch-hub crew-hub"
          :class="{ active: activeBranch === 'crew' }"
          @mouseenter="activeBranch = 'crew'"
          @mouseleave="activeBranch = null"
          @focusin="activeBranch = 'crew'"
          @focusout="onBranchFocusOut"
        >
          <button type="button" class="hub-hit" @click="emit('go', 'crew')">
            <span class="hub-ring">✧</span
            ><span class="hub-copy"
              ><small>HOUSE OPERATIONS</small
              ><strong
                >Crew <i>{{ CREW.length }}</i></strong
              ><em>The people behind the scenes</em></span
            >
          </button>
        </section>

        <section
          class="leaf-group regions-group"
          aria-label="Regions"
          @mouseenter="activeBranch = 'regions'"
          @mouseleave="activeBranch = null"
        >
          <button
            v-for="region in regionNodes"
            :key="region.id"
            class="leaf region-leaf"
            type="button"
            @click="emit('go', 'lhc', region.id)"
          >
            <span class="leaf-dot"></span
            ><span class="leaf-copy"
              ><strong>{{ region.name }}</strong>
              <small v-if="(region.coordinators || []).length">{{
                coordinatorNames(region.coordinators || [])
              }}</small>
              <small v-else-if="region.recruiting" class="recruiting">Coordinator seat open</small>
              <small v-else>No coordinator listed</small></span
            >
            <span class="leaf-avatars" v-if="(region.coordinators || []).length"
              ><img
                v-for="person in region.coordinators || []"
                :key="person.id"
                :src="portrait.face(person.img)"
                :alt="person.name"
            /></span>
            <span class="leaf-arrow" aria-hidden="true">↗</span>
          </button>
        </section>

        <section
          class="leaf-group communities-group"
          aria-label="Communities"
          @mouseenter="activeBranch = 'communities'"
          @mouseleave="activeBranch = null"
        >
          <button
            v-for="community in COMMUNITIES"
            :key="community.id"
            class="leaf"
            type="button"
            @click="emit('go', 'communities', community.id)"
          >
            <span class="leaf-dot" :class="`wing-${community.wing}`"></span
            ><span class="leaf-copy"
              ><strong>{{ community.name }}</strong
              ><small>{{ community.events }} events</small></span
            ><span class="leaf-arrow" aria-hidden="true">↗</span>
          </button>
        </section>

        <section
          class="leaf-group crew-group"
          aria-label="Crew"
          @mouseenter="activeBranch = 'crew'"
          @mouseleave="activeBranch = null"
        >
          <button
            v-for="team in CREW"
            :key="team.id"
            class="leaf"
            type="button"
            @click="emit('go', 'crew', team.id)"
          >
            <span class="leaf-dot crew-dot"></span
            ><span class="leaf-copy"
              ><strong>{{ team.name }}</strong
              ><small>{{ team.tag.join(' ') }}</small></span
            ><span class="leaf-arrow" aria-hidden="true">↗</span>
          </button>
        </section>
      </div>
    </div>

    <footer class="members-root">
      <span class="root-mark" aria-hidden="true">⌁</span>
      <small>THE FOUNDATION OF SUNDARBANS</small>
      <strong>Our Members</strong>
      <p>Every student is part of the roots that keep this house growing.</p>
    </footer>
  </section>
</template>

<script setup>
import { computed, ref } from 'vue';
import { lower, portrait, regions, upper } from '../../lib/house.js';
import { COMMUNITIES, CREW } from '../../data/teams.js';

const emit = defineEmits(['go']);
const activeBranch = ref(null);
const regionNodes = computed(() => [...regions].sort((a, b) => a.name.localeCompare(b.name)));

function coordinatorNames(people) {
  return people.map((person) => person.name.split(' ')[0]).join(' · ');
}
function onBranchFocusOut(event) {
  if (!event.currentTarget.contains(event.relatedTarget)) activeBranch.value = null;
}
</script>

<style scoped>
.mangrove-network {
  --gold: var(--mari-ink, #d6a04e);
  --gold-soft: rgba(214, 160, 78, 0.24);
  --gold-line: rgba(214, 160, 78, 0.64);
  --muted: var(--ink-2, #a49a8a);
  color: var(--ink, #f1e9dc);
  padding: 42px clamp(12px, 2.5vw, 32px) 28px;
  overflow: hidden;
}
.network-heading {
  text-align: center;
  margin: 0 auto 34px;
}
.eyebrow,
.level-label,
.hub-copy > small,
.members-root > small {
  color: var(--gold);
  font: 700 9px/1.4 monospace;
  letter-spacing: 0.17em;
}
.network-heading h2 {
  margin: 9px 0 6px;
  font-size: clamp(27px, 3vw, 39px);
  letter-spacing: -0.05em;
}
.network-heading h2 em {
  color: var(--gold);
  font:
    italic 400 1em Georgia,
    serif;
}
.network-heading p {
  margin: 0;
  color: var(--muted);
  font-size: 11px;
}
.tree-canvas {
  position: relative;
  width: 100%;
  max-width: 1420px;
  margin: 0 auto;
}
.tree-grid {
  position: relative;
  display: grid;
  isolation: isolate;
  grid-template-columns: minmax(145px, 17%) minmax(165px, 19%) minmax(205px, 23%) minmax(0, 41%);
  grid-template-rows: repeat(3, minmax(190px, auto));
  align-items: center;
  column-gap: 0;
  row-gap: 0;
}
.tree-wiring {
  position: absolute;
  inset: 0;
  z-index: 0;
  width: 100%;
  height: 100%;
  overflow: visible;
  pointer-events: none;
}
.tree-wiring path {
  fill: none;
  stroke: url(#sundarbansBranchGold);
  stroke-linecap: round;
  vector-effect: non-scaling-stroke;
  transition:
    stroke-width 0.22s ease,
    opacity 0.22s ease,
    filter 0.22s ease;
}
.main-wire {
  display: none;
}
.branch-wire {
  stroke-width: 2.6;
  stroke-dasharray: 2 9;
  opacity: 0.8;
}

.tree-wiring .is-active {
  opacity: 1;
  stroke-width: 4;
  filter: drop-shadow(0 0 5px rgba(231, 180, 93, 0.82));
}
.wire-joint {
  fill: var(--gold);
  stroke: var(--card, #171410);
  stroke-width: 2;
}
.tree-grid {
  z-index: 1;
}
/* The UHC–LHC connector is grid-aligned, so it stays attached at every desktop width. */
.council-wire {
  grid-column: 1 / 3;
  grid-row: 2;
  align-self: center;
  justify-self: stretch;
  position: relative;
  z-index: 1;
  height: 2px;
  margin: 0;
  pointer-events: none;
}
.council-wire::before {
  content: '';
  position: absolute;
  left: 24%;
  right: 26%;
  top: 50%;
  height: 2px;
  transform: translateY(-50%);
  border-radius: 2px;
  background: repeating-linear-gradient(
    90deg,
    rgba(225, 182, 109, 0.95) 0 3px,
    transparent 3px 11px
  );
  filter: drop-shadow(0 0 3px rgba(214, 160, 78, 0.3));
}
.council-node,
.branch-hub,
.leaf-group {
  min-width: 0;
}
.uhc-node {
  grid-column: 1;
  grid-row: 2;
}
.lhc-node {
  grid-column: 2;
  grid-row: 2;
}
.council-node {
  position: relative;
  z-index: 2;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 1px;
}
.council-dot {
  position: relative;
  z-index: 3;
  display: grid;
  place-items: center;
  width: 22px;
  height: 22px;
  padding: 0;
  border: 2px solid #d8a34f;
  border-radius: 50%;
  background: #17130e;
  box-shadow:
    0 0 0 4px rgba(214, 160, 78, 0.08),
    0 0 12px rgba(214, 160, 78, 0.24);
  cursor: pointer;
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease,
    border-color 0.2s ease;
}
.node-core {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #efbd68;
  box-shadow: 0 0 8px rgba(239, 189, 104, 0.7);
}
.council-dot:hover,
.council-dot:focus-visible {
  transform: scale(1.28);
  border-color: #ffe0a0;
  box-shadow:
    0 0 0 7px rgba(214, 160, 78, 0.15),
    0 0 29px rgba(255, 194, 91, 0.82);
  outline: none;
}
.council-popover {
  position: absolute;
  z-index: 5;
  left: 50%;
  bottom: calc(50% + 20px);
  width: max-content;
  min-width: 238px;
  max-width: 290px;
  display: grid;
  gap: 6px;
  padding: 16px 18px;
  border: 1px solid rgba(226, 174, 91, 0.68);
  border-radius: 11px;
  color: var(--ink, #f1e9dc);
  background: linear-gradient(135deg, rgba(45, 34, 20, 0.98), rgba(24, 20, 15, 0.98));
  box-shadow:
    0 12px 34px rgba(0, 0, 0, 0.38),
    0 0 28px rgba(214, 160, 78, 0.25);
  opacity: 0;
  visibility: hidden;
  transform: translate(-50%, 9px) scale(0.96);
  pointer-events: none;
  transition:
    opacity 0.18s ease,
    transform 0.18s ease,
    visibility 0.18s;
}
.council-dot:hover ~ .council-popover,
.council-dot:focus-visible ~ .council-popover {
  opacity: 1;
  visibility: visible;
  transform: translate(-50%, -3px) scale(1.05);
}
.council-popover::after {
  content: '';
  position: absolute;
  left: 50%;
  bottom: -6px;
  width: 10px;
  height: 10px;
  border-right: 1px solid rgba(226, 174, 91, 0.58);
  border-bottom: 1px solid rgba(226, 174, 91, 0.58);
  background: #211a12;
  transform: translateX(-50%) rotate(45deg);
}
.council-popover strong {
  font-size: 16px;
  line-height: 1.35;
  white-space: nowrap;
}
.council-popover > small {
  color: var(--muted);
  font-size: 12px;
}
.level-label {
  font-size: 8px;
}
.lhc-popover {
  min-width: 205px;
}
.avatars {
  display: flex;
  margin-top: 5px;
}
.avatars img,
.leaf-avatars img {
  width: 24px;
  height: 24px;
  object-fit: cover;
  border-radius: 50%;
  border: 2px solid var(--card, #171410);
}
.avatars img + img,
.leaf-avatars img + img {
  margin-left: -7px;
}
.seat-dots {
  display: flex;
  gap: 4px;
}
.seat-dots i,
.seat-pips i {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--gold);
  box-shadow: 0 0 0 1px rgba(214, 160, 78, 0.24);
}
.seat-count {
  position: absolute;
  right: 11px;
  top: 50%;
  transform: translateY(-50%);
  color: var(--gold);
  font-size: 22px;
  font-weight: 700;
}
.seat-count small {
  display: block;
  color: var(--muted);
  text-align: center;
  font: 9px monospace;
}
.seat-pips {
  display: flex;
  flex-wrap: wrap;
  gap: 5px;
  margin-top: 4px;
  max-width: 105px;
}
.branch-hub {
  display: flex;
  align-items: center;
  height: 100%;
}
.regions-hub {
  grid-column: 3;
  grid-row: 1;
}
.communities-hub {
  grid-column: 3;
  grid-row: 2;
}
.crew-hub {
  grid-column: 3;
  grid-row: 3;
}
.hub-hit {
  display: flex;
  align-items: center;
  gap: 11px;
  width: 100%;
  padding: 12px 8px;
  border: 1px solid transparent;
  border-radius: 12px;
  color: inherit;
  background: transparent;
  text-align: left;
  font: inherit;
  cursor: pointer;
  transition:
    background 0.2s,
    border-color 0.2s;
}
.hub-hit:hover,
.hub-hit:focus-visible,
.branch-hub.active .hub-hit {
  border-color: rgba(232, 181, 95, 0.62);
  background: linear-gradient(110deg, rgba(214, 160, 78, 0.14), rgba(214, 160, 78, 0.035));
  box-shadow:
    0 0 0 1px rgba(214, 160, 78, 0.08),
    0 0 25px rgba(214, 160, 78, 0.16);
  outline: none;
}
.branch-hub.active .hub-ring,
.hub-hit:hover .hub-ring,
.hub-hit:focus-visible .hub-ring {
  border-color: #f0c77e;
  color: #ffe2a9;
  background: rgba(214, 160, 78, 0.13);
  box-shadow:
    0 0 0 4px rgba(214, 160, 78, 0.09),
    0 0 22px rgba(214, 160, 78, 0.38);
}
.branch-hub.active .hub-copy strong,
.hub-hit:hover .hub-copy strong {
  color: #fff0d2;
  text-shadow: 0 0 12px rgba(236, 190, 111, 0.3);
}
.hub-ring {
  display: grid;
  place-items: center;
  flex: none;
  width: 37px;
  height: 37px;
  border: 1.5px solid var(--gold);
  border-radius: 50%;
  color: var(--gold);
  background: var(--card, #171410);
  font-size: 18px;
  box-shadow: 0 0 0 5px rgba(214, 160, 78, 0.035);
}
.hub-copy {
  display: grid;
  gap: 5px;
  min-width: 0;
}
.hub-copy > small {
  font-size: 8px;
}
.hub-copy strong {
  font-size: clamp(12px, 1.1vw, 15px);
  white-space: nowrap;
}
.hub-copy strong i {
  margin-left: 4px;
  color: var(--gold);
  font: 700 10px monospace;
}
.hub-copy em {
  color: var(--muted);
  font-size: 9px;
  font-style: normal;
}
.leaf-group {
  position: relative;
  display: grid;
  gap: 6px;
  padding: 13px 5px 13px 17px;
  align-content: center;
}
.regions-group {
  grid-column: 4;
  grid-row: 1;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  grid-template-rows: repeat(3, minmax(47px, auto));
}
.communities-group {
  grid-column: 4;
  grid-row: 2;
  grid-template-columns: 1fr;
  grid-template-rows: repeat(3, minmax(48px, auto));
}
.crew-group {
  grid-column: 4;
  grid-row: 3;
  grid-template-columns: 1fr;
  grid-template-rows: repeat(3, minmax(48px, auto));
}
.leaf-group::before {
  content: '';
  position: absolute;
  left: 5px;
  top: 18%;
  bottom: 18%;
  width: 1px;
  background: linear-gradient(transparent, var(--gold-line), transparent);
  transition:
    box-shadow 0.2s,
    background 0.2s;
}
.leaf-group:hover::before {
  background: var(--gold);
  box-shadow: 0 0 8px rgba(214, 160, 78, 0.42);
}
.leaf {
  position: relative;
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
  min-height: 43px;
  padding: 6px 7px;
  border: 1px solid transparent;
  border-radius: 8px;
  color: inherit;
  background: transparent;
  text-align: left;
  font: inherit;
  cursor: pointer;
  transition:
    background 0.2s,
    border-color 0.2s,
    transform 0.2s;
}
.leaf::before {
  content: '';
  position: absolute;
  left: -13px;
  top: 50%;
  width: 13px;
  height: 1px;
  background: var(--gold-line);
}
.leaf:hover,
.leaf:focus-visible {
  z-index: 1;
  border-color: rgba(232, 181, 95, 0.6);
  background: linear-gradient(100deg, rgba(214, 160, 78, 0.15), rgba(214, 160, 78, 0.045));
  transform: translateX(3px);
  box-shadow:
    0 0 0 1px rgba(214, 160, 78, 0.08),
    0 0 20px rgba(214, 160, 78, 0.13);
  outline: none;
}
.leaf:hover .leaf-copy strong,
.leaf:focus-visible .leaf-copy strong {
  color: #fff0d2;
  text-shadow: 0 0 10px rgba(236, 190, 111, 0.28);
}
.leaf:hover .leaf-copy small,
.leaf:focus-visible .leaf-copy small {
  color: #d8c6a7;
}
.leaf:hover .leaf-dot,
.leaf:focus-visible .leaf-dot {
  box-shadow:
    0 0 0 4px rgba(214, 160, 78, 0.1),
    0 0 13px rgba(236, 190, 111, 0.72);
}
.leaf:hover .leaf-arrow,
.leaf:focus-visible .leaf-arrow {
  opacity: 1;
  text-shadow: 0 0 10px rgba(236, 190, 111, 0.7);
}
.leaf-dot {
  flex: none;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #c58b3c;
  box-shadow: 0 0 8px rgba(214, 160, 78, 0.22);
}
.wing-cultural {
  background: #a96c25;
}
.wing-tech {
  background: #4569ad;
}
.wing-games {
  background: #b94e3b;
}
.crew-dot {
  background: #898477;
}
.leaf-copy {
  display: grid;
  flex: 1;
  min-width: 0;
  gap: 3px;
}
.leaf-copy strong {
  font-size: 10px;
  line-height: 1.25;
}
.leaf-copy small {
  color: var(--muted);
  font-size: 8px;
  line-height: 1.3;
  overflow-wrap: anywhere;
}
.leaf-avatars {
  display: flex;
  flex: none;
}
.leaf-avatars img {
  width: 20px;
  height: 20px;
}
.leaf-arrow {
  flex: none;
  color: var(--gold);
  font-size: 13px;
  opacity: 0.75;
}
.recruiting {
  color: var(--gold) !important;
}
.members-root {
  display: grid;
  justify-items: center;
  gap: 5px;
  max-width: 520px;
  margin: 24px auto 0;
  padding: 20px 12px 4px;
  border-top: 1px solid rgba(214, 160, 78, 0.16);
  text-align: center;
}
.root-mark {
  color: var(--gold);
  font:
    26px Georgia,
    serif;
  line-height: 1;
}
.members-root > small {
  font-size: 8px;
}
.members-root strong {
  font-size: 18px;
}
.members-root p {
  margin: 0;
  color: var(--muted);
  font-size: 10px;
  line-height: 1.5;
}
button:focus-visible {
  outline: 2px solid var(--gold);
  outline-offset: 3px;
}

@media (max-width: 1050px) and (min-width: 701px) {
  .tree-grid {
    grid-template-columns: minmax(125px, 16%) minmax(145px, 18%) minmax(180px, 24%) minmax(0, 42%);
    grid-template-rows: repeat(3, minmax(190px, auto));
  }
  .hub-hit {
    gap: 7px;
    padding-inline: 3px;
  }
  .hub-ring {
    width: 31px;
    height: 31px;
  }
  .hub-copy em {
    display: none;
  }
  .regions-group {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .leaf-avatars {
    display: none;
  }
}

/* Mobile: keep the same hierarchy, but let it flow top-to-bottom. */
@media (max-width: 700px) {
  .mangrove-network {
    padding: 28px 13px 22px;
    overflow-x: clip;
  }
  .tree-canvas,
  .tree-grid {
    min-width: 0;
    max-width: 100%;
  }
  .network-heading {
    margin-bottom: 24px;
  }
  .network-heading h2 {
    font-size: clamp(26px, 7vw, 34px);
  }
  .network-heading p {
    font-size: 10px;
  }
  .tree-wiring {
    display: none;
  }
  .council-wire {
    display: none;
  }
  .tree-grid {
    display: flex;
    flex-direction: column;
    gap: 0;
    width: 100%;
  }
  .council-node,
  .branch-hub,
  .leaf-group {
    width: 100%;
  }
  .council-node {
    position: relative;
    justify-content: flex-start;
    min-height: 54px;
    padding-left: 18px;
  }
  .council-dot {
    width: 20px;
    height: 20px;
  }
  .council-popover {
    left: 42px;
    bottom: auto;
    top: 50%;
    min-width: 0;
    width: calc(100% - 55px);
    max-width: none;
    padding: 10px 12px;
    opacity: 1;
    visibility: visible;
    transform: translateY(-50%);
    pointer-events: auto;
  }
  .council-popover::after {
    display: none;
  }
  .council-popover strong {
    font-size: 12px;
  }
  .council-popover > small {
    font-size: 8px;
  }
  .lhc-node {
    margin-bottom: 17px;
  }
  .branch-hub {
    position: relative;
    min-height: 54px;
    margin: 0;
    padding: 0 0 0 17px;
  }
  .branch-hub::before {
    content: '';
    position: absolute;
    left: 50%;
    top: -13px;
    height: 13px;
    width: 2px;
    background: var(--gold-line);
  }
  .hub-hit {
    min-height: 52px;
    padding: 7px 10px;
    border: 1px solid rgba(214, 160, 78, 0.17);
    border-radius: 10px;
    background: rgba(214, 160, 78, 0.035);
  }
  .hub-ring {
    width: 31px;
    height: 31px;
  }
  .hub-copy > small {
    font-size: 7px;
  }
  .hub-copy strong {
    font-size: 12px;
  }
  .hub-copy em {
    display: none;
  }
  .leaf-group {
    margin: 0 0 16px 17px;
    width: calc(100% - 17px);
    padding: 8px 8px 8px 17px;
    border-left: 1px solid var(--gold-line);
  }
  .leaf-group::before {
    display: none;
  }
  .leaf {
    min-height: 47px;
    padding: 7px 7px;
    border-color: rgba(214, 160, 78, 0.1);
    background: rgba(255, 255, 255, 0.012);
  }
  .leaf::before {
    left: -18px;
    width: 17px;
  }
  .leaf-copy strong {
    font-size: 10px;
  }
  .leaf-copy small {
    font-size: 8px;
  }
  .regions-group {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    grid-template-rows: auto;
    grid-auto-rows: minmax(48px, auto);
    gap: 5px;
  }
  .communities-group,
  .crew-group {
    grid-template-columns: 1fr;
    grid-template-rows: auto;
    grid-auto-rows: minmax(47px, auto);
    gap: 5px;
  }
  .leaf-avatars {
    display: none;
  }
  .members-root {
    margin-top: 6px;
    padding-top: 17px;
  }
}
@media (max-width: 390px) {
  .mangrove-network {
    padding-inline: 10px;
  }
  .regions-group {
    grid-template-columns: 1fr;
  }
  .seat-count {
    right: 9px;
  }
}
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    transition-duration: 0.01ms !important;
    animation-duration: 0.01ms !important;
  }
}
</style>
