<template>
  <div class="widget w-6" id="widget-challenge">
    <div class="widget-glow"
         style="width:250px;height:250px;
                background:radial-gradient(circle,rgba(255,180,50,.1),transparent);
                top:-60px;right:-60px">
    </div>

    <div class="widget-label">Daily Challenge</div>
    <div class="widget-title">Today's Problem</div>

    <!-- Difficulty + points header -->
    <div class="challenge-header-row">
      <span class="diff-badge diff-medium">Medium</span>
      <span class="challenge-pts-badge">+25 House Points</span>
    </div>

    <div class="challenge-stats">
      <div>
        <span>Solvers</span>
        <strong>{{ solvers.length }}</strong>
      </div>
      <div>
        <span>Hint penalty</span>
        <strong>-{{ PTS_FULL - PTS_HINT }}</strong>
      </div>
    </div>

    <!-- Problem statement -->
    <div class="challenge-problem">
      <div class="challenge-problem-title">
        Longest Substring Without Repeating Characters
      </div>
      <div class="challenge-problem-desc">
        Given a string <span class="code-inline">s</span>,
        find the length of the longest substring without repeating characters.<br><br>
        <strong>Examples:</strong><br>
        <span class="code-inline">"abcabcbb"</span> → <span class="code-inline">3</span> &nbsp;(substring "abc")<br>
        <span class="code-inline">"bbbbb"</span>    → <span class="code-inline">1</span> &nbsp;(substring "b")<br>
        <span class="code-inline">"pwwkew"</span>   → <span class="code-inline">3</span> &nbsp;(substring "wke")
        <div class="challenge-code">def lengthOfLongestSubstring(s: str) -> int:
    # Your solution here
    pass</div>
      </div>
    </div>

    <!-- Collapsible hint -->
    <div class="challenge-hint" :class="{ show: hintShown }">
      💡 <strong>Hint:</strong> Use a <em>sliding window</em> with a hash set.
      Advance the right pointer; when you hit a duplicate, shrink from the left
      until it is removed. Track the maximum window size throughout.
    </div>

    <!-- Solved confirmation -->
    <div class="challenge-solved-wrap" :class="{ show: mySolved }">
      ✅ You solved it! <strong>{{ solvedPtsText }}</strong> points added to your tally.
    </div>

    <!-- Action buttons -->
    <div class="challenge-actions">
      <button class="btn btn-ghost" @click="toggleHint">
        {{ hintShown ? 'Hide Hint' : 'Hint' }}
      </button>
      <button
        class="btn btn-outline"
        ref="solveBtnRef"
        :disabled="mySolved"
        @click="markSolved"
      >
        {{ mySolved ? '✓ Solved!' : '✓ I Solved It' }}
      </button>
    </div>

    <!-- Live solver leaderboard -->
    <div class="challenge-solvers-label">
      Today's Solvers (<span>{{ solvers.length }}</span>)
    </div>
    <div class="challenge-solvers">
      <div
        v-for="(s, i) in solvers"
        :key="i"
        class="challenge-solver"
        :class="{ me: s.me }"
      >
        <span class="solver-rank">{{ i + 1 }}</span>
        <span class="solver-name">{{ s.name }}{{ s.me ? ' (You)' : '' }}</span>
        <span class="solver-time">{{ s.time }}</span>
        <span class="solver-pts">+{{ s.points }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { save, load } from '../../composables/useLocalStorage.js';

const props = defineProps({
  config: { type: Object, default: null }
});

const emit = defineEmits(['confetti']);

const TODAY = new Date().toDateString();

const SEED_SOLVERS = props.config ? props.config.seedSolvers : [
  { name:'Aditi Sharma', time:'08:42 AM', points:25, me:false },
  { name:'Dev Patel',    time:'09:15 AM', points:25, me:false },
  { name:'Rohan Verma',  time:'10:03 AM', points:20, me:false }
];
const PTS_FULL = props.config ? props.config.points : 25;
const PTS_HINT = props.config ? props.config.pointsWithHint : 15;

// Reset each new day
if (load('sb_ch_date', null) !== TODAY) {
  save('sb_ch_date', TODAY);
  save('sb_ch_solvers', SEED_SOLVERS);
  save('sb_ch_solved', false);
}

const solvers = ref(load('sb_ch_solvers', SEED_SOLVERS));
const mySolved = ref(load('sb_ch_solved', false));
const hintShown = ref(false);
const solvedPtsText = ref('');
const solveBtnRef = ref(null);

function toggleHint() {
  hintShown.value = !hintShown.value;
}

function markSolved() {
  if (mySolved.value) return;

  const now = new Date();
  const time = now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
  const pts = hintShown.value ? PTS_HINT : PTS_FULL;

  solvers.value.push({ name:'You', time, points: pts, me: true });
  solvers.value = [...solvers.value];
  save('sb_ch_solvers', solvers.value);
  save('sb_ch_solved', true);
  mySolved.value = true;
  solvedPtsText.value = '+' + pts;

  if (solveBtnRef.value) {
    const r = solveBtnRef.value.getBoundingClientRect();
    emit('confetti', r.left + r.width / 2, r.top);
  }
}
</script>
