<template>
  <div class="widget w-6" id="widget-confession">
    <div class="widget-glow"
         style="width:200px;height:200px;
                background:radial-gradient(circle,rgba(122,176,224,.14),transparent);
                bottom:-60px;right:-40px">
    </div>

    <div class="widget-label">Anonymous</div>
    <div class="widget-title">Confession Wall</div>

    <!-- Input area -->
    <div class="confession-input-wrap">
      <textarea
        class="confession-textarea"
        v-model="inputText"
        placeholder="Share something on your mind... nobody will know it's you."
        maxlength="280"
        @input="updateCharCount"
      ></textarea>
      <span class="char-count" :class="{ warn: inputText.length > 240 }">{{ inputText.length }} / 280</span>
    </div>

    <div class="confession-submit-row">
      <span class="confession-anon">🤫 100% anonymous · never linked to your name</span>
      <button class="btn btn-outline" @click="postConfession">Post</button>
    </div>

    <!-- Post feed -->
    <div class="confession-list" ref="confListRef">
      <div v-if="confs.length === 0" class="conf-empty">No confessions yet. Be the first! 🤫</div>
      <div
        v-for="c in reversedConfs"
        :key="c.id"
        class="confession-item"
      >
        <div class="confession-text">{{ c.text }}</div>
        <div class="confession-meta">
          <span class="confession-time">{{ timeAgo(c.ts) }}</span>
          <button
            v-for="rx in reactions"
            :key="rx.key"
            class="reaction-btn"
            :class="{ reacted: myRx[c.id] === rx.key }"
            @click="rxConf(c.id, rx.key)"
          >
            {{ rx.emoji }} <span>{{ c.r[rx.key] || 0 }}</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { save, load } from '../../composables/useLocalStorage.js';

const props = defineProps({
  config: { type: Object, default: null }
});

function timeAgo(ts) {
  const diff = Date.now() - ts;
  const mins = Math.floor(diff / 60000);
  const hrs  = Math.floor(diff / 3600000);
  if (diff  < 60000) return 'just now';
  if (mins  < 60)    return mins + 'm ago';
  if (hrs   < 24)    return hrs  + 'h ago';
  return Math.floor(hrs / 24) + 'd ago';
}

const SEED = props.config ? props.config.seed.map(s => ({
  id: s.id, text: s.text, ts: Date.now() - s.offsetMs, r: { ...s.reactions }
})) : [
  { id:1, text:"I've submitted 4 assignments as drafts thinking they were submitted. Found out during grade review. Might cry.", ts:Date.now()-7200000,  r:{heart:24,laugh:12,wow:31} },
  { id:2, text:"Started a 6-week course 3 days before the quiz and got 90%. I operate purely on chaos energy.",                 ts:Date.now()-18000000, r:{heart:18,laugh:67,wow:9}  },
  { id:3, text:"I genuinely look forward to Monday technical sessions more than anything else this week. Not cringe, just facts.", ts:Date.now()-86400000, r:{heart:88,laugh:4,wow:11} }
];

const reactions = props.config ? props.config.reactions : [
  { key:'heart', emoji:'❤️' },
  { key:'laugh', emoji:'😂' },
  { key:'wow',   emoji:'😮' }
];

const confs = ref(load('sb_confs', SEED));
const nextId = ref(load('sb_conf_id', 4));
const myRx = ref(load('sb_conf_rx', {}));
const inputText = ref('');
const confListRef = ref(null);

const reversedConfs = computed(() => [...confs.value].reverse());

function updateCharCount() {
  // Handled reactively via v-model
}

function postConfession() {
  const text = inputText.value.trim();
  if (!text) return;

  const c = { id: nextId.value++, text, ts: Date.now(), r: { heart:0, laugh:0, wow:0 } };
  confs.value.push(c);
  if (confs.value.length > 80) confs.value = confs.value.slice(-80);

  save('sb_confs', confs.value);
  save('sb_conf_id', nextId.value);

  inputText.value = '';
  if (confListRef.value) confListRef.value.scrollTop = 0;
}

function rxConf(id, key) {
  const c = confs.value.find(x => x.id === id);
  if (!c) return;

  const prev = myRx.value[id];
  if (prev) c.r[prev] = Math.max(0, (c.r[prev] || 1) - 1);

  if (prev !== key) {
    c.r[key] = (c.r[key] || 0) + 1;
    myRx.value[id] = key;
  } else {
    delete myRx.value[id];
  }

  // Force reactivity
  myRx.value = { ...myRx.value };
  confs.value = [...confs.value];

  save('sb_confs', confs.value);
  save('sb_conf_rx', myRx.value);
}
</script>
