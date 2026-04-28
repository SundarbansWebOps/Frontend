<template>
  <div class="widget w-5" id="widget-pomo">
    <div class="widget-glow"
         style="width:200px;height:200px;
                background:radial-gradient(circle,rgba(76,175,80,.2),transparent);
                bottom:-60px;right:-40px">
    </div>

    <div class="widget-label">Focus Timer</div>
    <div class="widget-title">Study Room</div>

    <div class="pomo-status-strip">
      <div>
        <span>Mode</span>
        <strong>{{ currentPhaseLabel }}</strong>
      </div>
      <div>
        <span>Room</span>
        <strong>{{ inRoom ? 'Joined' : 'Open' }}</strong>
      </div>
    </div>

    <!-- Phase selector tabs -->
    <div class="pomo-phase-tabs">
      <button
        v-for="p in phases"
        :key="p.key"
        class="pomo-tab"
        :class="{ active: phase === p.key }"
        :data-phase="p.key"
        :data-secs="p.seconds"
        @click="setPhase(p)"
      >{{ p.tabLabel }}</button>
    </div>

    <!-- SVG ring timer -->
    <div class="pomo-ring-wrap">
      <svg class="pomo-ring-svg" width="160" height="160" viewBox="0 0 160 160"
           aria-label="Timer progress ring" role="img">
        <circle class="pomo-ring-bg" cx="80" cy="80" r="70"/>
        <circle
          :class="ringClass"
          cx="80" cy="80" r="70"
          :style="{ strokeDasharray: CIRC, strokeDashoffset: ringOffset }"
        />
      </svg>
      <div class="pomo-timer-text">
        <div class="pomo-time-display">{{ fmtTime(remaining) }}</div>
        <div class="pomo-phase-label">{{ currentPhaseLabel }}</div>
      </div>
    </div>

    <!-- Session progress dots -->
    <div class="pomo-session-row">
      <span
        v-for="i in maxSessions"
        :key="i"
        class="pomo-session-dot"
        :class="{ filled: i <= sessions }"
      ></span>
      <span class="pomo-session-lbl">{{ sessions }}/{{ maxSessions }} sessions</span>
    </div>

    <!-- Controls -->
    <div class="pomo-controls">
      <button class="btn btn-gold" @click="togglePomo">{{ startBtnText }}</button>
      <button class="btn btn-ghost" @click="resetPomo">Reset</button>
      <button
        class="btn"
        :class="inRoom ? 'btn-green' : 'btn-ghost'"
        @click="toggleRoom"
      >{{ inRoom ? 'Leave Room' : 'Join Room' }}</button>
    </div>

    <!-- Session-complete banner -->
    <div class="pomo-done-banner" :class="{ show: showBanner }">🎉 Session complete! Take a break.</div>

    <!-- Live studiers -->
    <div class="pomo-studiers-label">
      Studying Now (<span>{{ displayPeople.length }}</span>)
    </div>
    <div class="pomo-studiers">
      <div
        v-for="(p, i) in displayPeople"
        :key="i"
        class="pomo-person"
        :class="{ you: p === 'You' }"
      >
        <div v-if="p === 'You'" class="pomo-person-dot"></div>
        {{ p }}
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onUnmounted } from 'vue';
import { save, load } from '../../composables/useLocalStorage.js';

const props = defineProps({
  config: { type: Object, default: null }
});

const emit = defineEmits(['confetti']);

const phases = props.config ? props.config.phases : [
  { key:'focus', label:'Focus',       seconds:1500, tabLabel:'Focus 25' },
  { key:'short', label:'Short Break', seconds:300,  tabLabel:'Break 5'  },
  { key:'long',  label:'Long Break',  seconds:900,  tabLabel:'Long 15'  }
];
const SEED_PEOPLE = props.config ? props.config.seedStudiers : ['Aditi S.','Rohan V.','Dev P.','Mehak S.'];
const maxSessions = props.config ? props.config.maxSessions : 4;

const CIRC = String(2 * Math.PI * 70);

const phase = ref('focus');
const totalSecs = ref(1500);
const remaining = ref(1500);
const running = ref(false);
let ticker = null;
const sessions = ref(0);
const inRoom = ref(load('sb_pomo_room', false));
const roomPeople = ref(load('sb_pomo_people', SEED_PEOPLE));
const showBanner = ref(false);

const ringOffset = computed(() => {
  const circ = 2 * Math.PI * 70;
  return String(circ * (1 - remaining.value / totalSecs.value));
});

const ringClass = computed(() => {
  if (phase.value === 'focus') return 'pomo-ring-fill';
  if (phase.value === 'short') return 'pomo-ring-fill break';
  return 'pomo-ring-fill longbreak';
});

const currentPhaseLabel = computed(() => {
  const p = phases.find(p => p.key === phase.value);
  return p ? p.label : 'Focus';
});

const startBtnText = computed(() => {
  if (!running.value && remaining.value === totalSecs.value) return 'Start';
  if (running.value) return 'Pause';
  return 'Resume';
});

const displayPeople = computed(() => {
  return inRoom.value ? ['You', ...roomPeople.value] : [...roomPeople.value];
});

function pad2(n) { return String(n).padStart(2, '0'); }
function fmtTime(secs) {
  return pad2(Math.floor(secs / 60)) + ':' + pad2(secs % 60);
}

function setPhase(p) {
  clearInterval(ticker); ticker = null; running.value = false;
  showBanner.value = false;
  phase.value = p.key;
  totalSecs.value = p.seconds;
  remaining.value = p.seconds;
}

function togglePomo() {
  running.value = !running.value;
  if (running.value) {
    ticker = setInterval(() => {
      remaining.value--;
      if (remaining.value <= 0) onComplete();
    }, 1000);
  } else {
    clearInterval(ticker); ticker = null;
  }
}

function resetPomo() {
  clearInterval(ticker); ticker = null;
  running.value = false;
  remaining.value = totalSecs.value;
  showBanner.value = false;
}

function onComplete() {
  running.value = false;
  clearInterval(ticker); ticker = null;

  if (phase.value === 'focus') {
    sessions.value = Math.min(sessions.value + 1, maxSessions);
  }

  showBanner.value = true;
  setTimeout(() => { showBanner.value = false; }, 4500);
  emit('confetti');
}

function toggleRoom() {
  inRoom.value = !inRoom.value;
  save('sb_pomo_room', inRoom.value);
}

onUnmounted(() => {
  clearInterval(ticker);
});
</script>
