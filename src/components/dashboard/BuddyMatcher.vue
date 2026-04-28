<template>
  <div class="widget w-7" id="widget-buddy">
    <div class="widget-label">Find Your Match</div>
    <div class="widget-title">Study Buddy Matcher</div>

    <div class="buddy-intro">
      <span>{{ POOL.length }} active members</span>
      <span>3-step match</span>
    </div>

    <!-- Filter dropdowns -->
    <div class="buddy-fields">
      <div class="buddy-field">
        <label for="buddySub">Subject</label>
        <select
          class="buddy-select"
          id="buddySub"
          v-model="selectedSub"
          :class="{ error: errors.sub }"
          @change="errors.sub = false"
        >
          <option value="">Select a subject…</option>
          <option v-for="s in subjects" :key="s">{{ s }}</option>
        </select>
      </div>
      <div class="buddy-field">
        <label for="buddyTime">Time Slot</label>
        <select
          class="buddy-select"
          id="buddyTime"
          v-model="selectedTime"
          :class="{ error: errors.time }"
          @change="errors.time = false"
        >
          <option value="">When do you study?</option>
          <option v-for="t in timeSlots" :key="t">{{ t }}</option>
        </select>
      </div>
      <div class="buddy-field">
        <label for="buddyStyle">Study Style</label>
        <select
          class="buddy-select"
          id="buddyStyle"
          v-model="selectedStyle"
          :class="{ error: errors.style }"
          @change="errors.style = false"
        >
          <option value="">How do you study?</option>
          <option v-for="st in studyStyles" :key="st">{{ st }}</option>
        </select>
      </div>
    </div>

    <button class="btn btn-gold buddy-find-btn" @click="findBuddy">
      Find My Buddy ✨
    </button>

    <!-- Match result card -->
    <div class="buddy-result" :class="{ show: showResult }">
      <div class="buddy-result-header">
        <div class="buddy-avatar">{{ matchInitial }}</div>
        <div style="flex:1">
          <div class="buddy-name-lbl">{{ matchName }}</div>
          <div class="buddy-roll-lbl">{{ matchRoll }}</div>
        </div>
        <div style="text-align:right">
          <div class="buddy-match-pct">{{ matchPct }}%</div>
          <div class="buddy-match-sub">match</div>
        </div>
      </div>
      <div class="buddy-tags">
        <span v-for="tag in matchTags" :key="tag" class="buddy-tag">{{ tag }}</span>
      </div>
      <div class="buddy-criteria">
        <span>{{ selectedSub }}</span>
        <span>{{ selectedTime }}</span>
        <span>{{ selectedStyle }}</span>
      </div>
      <div class="buddy-connect-row">
        <button class="btn btn-outline" :disabled="connectSent" @click="connectBuddy">
          {{ connectSent ? 'Sent!' : '💬 Connect' }}
        </button>
        <button class="btn btn-ghost" @click="findBuddy">🔀 Shuffle</button>
        <span class="buddy-sent-msg" :class="{ show: connectSent }">✓ Request sent!</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue';

const props = defineProps({
  pool: { type: Array, default: null },
  options: { type: Object, default: null }
});

const POOL = props.pool || [
  { name:'Aditi Sharma',  roll:'23f1000052', tags:['Night Owl','Explains Well','Speed Runner']    },
  { name:'Rohan Verma',   roll:'22f1000119', tags:['Silent Mode','Topper Energy','Note Sharer']   },
  { name:'Mehak Singh',   roll:'24f1000093', tags:['Discussion Queen','Mock Test Fan','Patient']  },
  { name:'Dev Patel',     roll:'23f2000114', tags:['Problem Solver','Early Riser','Flashcard Pro']},
  { name:'Priya Nair',    roll:'24f2000050', tags:['Chill Vibes','Group Study','Mentor Mode']     },
  { name:'Arjun Mehra',   roll:'23f3000021', tags:['Competitive','CP Grinder','Deadline Chaser']  },
  { name:'Sneha Iyer',    roll:'24f1000078', tags:['Structured Notes','Pomodoro Fan','Consistent']},
  { name:'Karan Joshi',   roll:'23f4000031', tags:['Visual Learner','Diagram Lover','Calm Energy']}
];

const subjects = props.options ? props.options.subjects : [];
const timeSlots = props.options ? props.options.timeSlots : [];
const studyStyles = props.options ? props.options.studyStyles : [];

const selectedSub = ref('');
const selectedTime = ref('');
const selectedStyle = ref('');
const errors = reactive({ sub: false, time: false, style: false });

const showResult = ref(false);
const matchInitial = ref('');
const matchName = ref('');
const matchRoll = ref('');
const matchPct = ref(0);
const matchTags = ref([]);
const connectSent = ref(false);

let lastIdx = -1;

function findBuddy() {
  let valid = true;
  if (!selectedSub.value)   { errors.sub = true;   setTimeout(() => errors.sub = false, 2000);   valid = false; }
  if (!selectedTime.value)  { errors.time = true;   setTimeout(() => errors.time = false, 2000);  valid = false; }
  if (!selectedStyle.value) { errors.style = true;  setTimeout(() => errors.style = false, 2000); valid = false; }
  if (!valid) return;

  let idx, attempts = 0;
  do {
    idx = Math.floor(Math.random() * POOL.length);
    attempts++;
  } while (idx === lastIdx && POOL.length > 1 && attempts < 10);
  lastIdx = idx;

  const m = POOL[idx];
  const pct = 75 + Math.floor(Math.random() * 24);

  matchInitial.value = m.name.charAt(0);
  matchName.value = m.name;
  matchRoll.value = m.roll + '@ds.study.iitm.ac.in';
  matchPct.value = pct;
  matchTags.value = m.tags;
  connectSent.value = false;
  showResult.value = true;
}

function connectBuddy() {
  if (!matchName.value) return;
  connectSent.value = true;
}
</script>
