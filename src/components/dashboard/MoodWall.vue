<template>
  <div class="widget w-7" id="widget-mood">
    <div class="widget-glow"
         style="width:260px;height:260px;
                background:radial-gradient(circle,rgba(176,122,224,.2),transparent);
                top:-80px;right:-60px">
    </div>

    <div class="widget-label">Anonymous Vote</div>
    <div class="widget-title">House Mood Wall</div>

    <div class="mood-summary">
      <div>
        <span class="mood-summary-label">Leading mood</span>
        <strong>{{ leadingMood.emoji }} {{ leadingMood.label }}</strong>
      </div>
      <div>
        <span class="mood-summary-label">Participation</span>
        <strong>{{ totalVotes }}</strong>
      </div>
    </div>

    <!-- Vote buttons -->
    <div class="mood-options" id="moodOptions">
      <button
        v-for="m in moods"
        :key="m.key"
        class="mood-opt"
        :class="{ selected: votedToday && myVote === m.key }"
        :data-mood="m.key"
        :disabled="votedToday"
        @click="voteMood(m.key)"
      >
        <span class="mood-emoji">{{ m.emoji }}</span>{{ m.label }}
      </button>
    </div>

    <!-- Live bar chart -->
    <div class="mood-bars">
      <div class="mood-bar-row" v-for="m in moods" :key="m.key">
        <span class="mood-bar-emoji">{{ m.emoji }}</span>
        <div class="mood-bar-track">
          <div
            class="mood-bar-fill"
            :style="{ background: m.color, width: barWidth(m.key) }"
          ></div>
        </div>
        <span class="mood-bar-count">{{ tally[m.key] || 0 }}</span>
      </div>
    </div>

    <div class="mood-total">{{ totalVotes }} votes today</div>
    <div class="mood-voted-msg" :class="{ show: votedToday }">✓ Voted! Come back tomorrow for a fresh vote.</div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue';
import { save, load } from '../../composables/useLocalStorage.js';

const props = defineProps({
  config: { type: Object, default: null }
});

const TODAY = new Date().toDateString();

const moods = props.config ? props.config.options : [
  { key:'happy', emoji:'😄', label:'Thriving', color:'#4caf50' },
  { key:'chill', emoji:'😌', label:'Chill',    color:'#7ab0e0' },
  { key:'grind', emoji:'😤', label:'Grind',    color:'#c9a84c' },
  { key:'meh',   emoji:'😔', label:'Meh',      color:'#b07ae0' },
  { key:'chaos', emoji:'🤯', label:'Chaos',    color:'#e07070' }
];

const SEED_TALLY = props.config ? props.config.seedTally : { happy:12, chill:8, grind:19, meh:5, chaos:7 };

const tally = ref(load('sb_mood_tally', SEED_TALLY));
const myVote = ref(load('sb_mood_mine', null));
const myDate = ref(load('sb_mood_date', null));

const votedToday = computed(() => myDate.value === TODAY);

const totalVotes = computed(() => {
  return Object.values(tally.value).reduce((a, b) => a + b, 0);
});

const leadingMood = computed(() => {
  return moods.reduce((lead, mood) => {
    return (tally.value[mood.key] || 0) > (tally.value[lead.key] || 0) ? mood : lead;
  }, moods[0]);
});

function barWidth(key) {
  const total = totalVotes.value || 1;
  return Math.round(((tally.value[key] || 0) / total) * 100) + '%';
}

function voteMood(key) {
  if (votedToday.value) return;
  tally.value[key] = (tally.value[key] || 0) + 1;
  // Force reactivity by replacing the object
  tally.value = { ...tally.value };
  myVote.value = key;
  myDate.value = TODAY;

  save('sb_mood_tally', tally.value);
  save('sb_mood_mine', key);
  save('sb_mood_date', TODAY);
}
</script>
