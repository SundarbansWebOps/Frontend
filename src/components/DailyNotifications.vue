<template>
  <section class="section rs daily-notif-section">
    <div class="container">

      <!-- Section Header -->
      <div class="sec-hdr">
        <div class="section-tag">What's Happening</div>
        <h2 class="section-title-xl">
          Daily <span class="tg">Updates</span>
        </h2>
      </div>

      <!-- Notification Card Rotator -->
      <div class="notif-stage" v-if="sorted.length">

        <!-- Progress dots -->
        <div class="notif-dots">
          <button
            v-for="(n, i) in sorted"
            :key="n.id"
            class="notif-dot"
            :class="{ active: i === current }"
            @click="goTo(i)"
            :aria-label="`Go to notification ${i + 1}`"
          />
        </div>

        <!-- Cards (all mounted, only active visible for transition) -->
        <div class="notif-track">
          <transition name="card-slide" mode="out-in">
            <div
              :key="active.id"
              class="notif-card"
              :class="`type-${active.type}`"
            >
              <!-- Left accent bar -->
              <div class="notif-accent-bar" />

              <!-- Top row: tag + date chip -->
              <div class="notif-top-row">
                <span class="notif-tag" :class="`tag-${active.type}`">
                  <span class="notif-tag-icon">{{ typeIcon(active.type) }}</span>
                  {{ active.tag }}
                </span>
                <span class="notif-date-chip" v-if="active.date && isToday(active.date)">
                  Today
                </span>
                <span class="notif-date-chip upcoming" v-else-if="active.date">
                  {{ formatDate(active.date) }}
                </span>
              </div>

              <!-- Content -->
              <h3 class="notif-title">{{ active.title }}</h3>
              <p class="notif-message">{{ active.message }}</p>

              <!-- Footer: link + counter -->
              <div class="notif-footer">
                <a
                  v-if="active.link"
                  :href="active.link"
                  target="_blank"
                  class="notif-link"
                >
                  Learn More →
                </a>
                <span v-else class="notif-spacer" />
                <span class="notif-counter">{{ current + 1 }} / {{ sorted.length }}</span>
              </div>
            </div>
          </transition>
        </div>

        <!-- Prev / Next controls -->
        <div class="notif-controls">
          <button class="notif-btn" @click="prev" :disabled="sorted.length <= 1" aria-label="Previous">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
              <polyline points="15 18 9 12 15 6"/>
            </svg>
          </button>

          <button
            class="notif-btn play-btn"
            @click="toggleAuto"
            :aria-label="autoPlay ? 'Pause' : 'Play'"
          >
            <!-- Play icon -->
            <svg v-if="!autoPlay" width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
              <polygon points="5 3 19 12 5 21 5 3"/>
            </svg>
            <!-- Pause icon -->
            <svg v-else width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
              <rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/>
            </svg>
          </button>

          <button class="notif-btn" @click="next" :disabled="sorted.length <= 1" aria-label="Next">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
              <polyline points="9 18 15 12 9 6"/>
            </svg>
          </button>
        </div>

        <!-- Auto-play progress bar -->
        <div class="notif-progress-wrap" v-if="autoPlay">
          <div class="notif-progress-bar" :style="{ animationDuration: `${interval}ms` }" :key="progressKey" />
        </div>

      </div>

      <!-- Empty state -->
      <div v-else class="notif-empty">
        <div style="font-size:2rem;margin-bottom:0.5rem">📭</div>
        <p class="desc" style="margin:0">No notifications right now. Check back soon.</p>
      </div>

    </div>
  </section>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch } from "vue";
import rawNotifs from "../data/notifications.json";

// ─── Config ───────────────────────────────────────────────────
const interval = 4500; // ms between auto-rotations

// ─── State ────────────────────────────────────────────────────
const current   = ref(0);
const autoPlay  = ref(true);
const progressKey = ref(0);
let   timer     = null;

// ─── Sort: today's birthdays first, then rest in order ────────
const sorted = computed(() => {
  const todayBirthdays = rawNotifs.filter(
    (n) => n.type === "birthday" && n.date && isToday(n.date)
  );
  const rest = rawNotifs.filter((n) => !todayBirthdays.includes(n));
  return [...todayBirthdays, ...rest];
});

const active = computed(() => sorted.value[current.value] ?? sorted.value[0]);

// ─── Navigation ───────────────────────────────────────────────
function next() {
  current.value = (current.value + 1) % sorted.value.length;
  resetProgress();
}
function prev() {
  current.value = (current.value - 1 + sorted.value.length) % sorted.value.length;
  resetProgress();
}
function goTo(i) {
  current.value = i;
  resetProgress();
}

// ─── Auto-play ────────────────────────────────────────────────
function startTimer() {
  clearInterval(timer);
  timer = setInterval(next, interval);
}
function stopTimer() {
  clearInterval(timer);
}
function toggleAuto() {
  autoPlay.value = !autoPlay.value;
}
function resetProgress() {
  progressKey.value++;
  if (autoPlay.value) startTimer();
}

watch(autoPlay, (val) => {
  if (val) { startTimer(); progressKey.value++; }
  else     stopTimer();
});

onMounted(() => startTimer());
onBeforeUnmount(() => stopTimer());

// ─── Helpers ──────────────────────────────────────────────────
function isToday(dateStr) {
  // dateStr format: "MM-DD"
  const now   = new Date();
  const [m, d] = dateStr.split("-").map(Number);
  return now.getMonth() + 1 === m && now.getDate() === d;
}

function formatDate(dateStr) {
  const [m, d] = dateStr.split("-").map(Number);
  return new Date(new Date().getFullYear(), m - 1, d)
    .toLocaleDateString("en-IN", { month: "short", day: "numeric" });
}

function typeIcon(type) {
  return { birthday: "🎂", event: "📢", achievement: "🏆", alert: "⚠️" }[type] ?? "📌";
}
</script>

<style scoped>
/* ─── Section wrapper ──────────────────────────────────────── */
.daily-notif-section {
  background: rgba(13, 11, 8, 0.5);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}

/* ─── Stage ────────────────────────────────────────────────── */
.notif-stage {
  max-width: 680px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.25rem;
}

/* ─── Progress dots ────────────────────────────────────────── */
.notif-dots {
  display: flex;
  gap: 0.45rem;
}
.notif-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  border: none;
  cursor: pointer;
  background: rgba(212, 160, 23, 0.2);
  transition: background 0.25s, transform 0.2s;
  padding: 0;
}
.notif-dot.active {
  background: #d4a017;
  transform: scale(1.3);
}

/* ─── Track + card ─────────────────────────────────────────── */
.notif-track {
  width: 100%;
}

.notif-card {
  position: relative;
  background: rgba(13, 11, 8, 0.5);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(212, 160, 23, 0.15);
  border-radius: 1rem;
  padding: 1.75rem 1.75rem 1.5rem 2.25rem;
  overflow: hidden;
  transition: border-color 0.3s;
}
.notif-card:hover {
  border-color: rgba(212, 160, 23, 0.35);
}

/* Type-specific border tints */
.notif-card.type-birthday  { border-color: rgba(240, 100, 150, 0.25); }
.notif-card.type-event     { border-color: rgba(80, 180, 255, 0.2); }
.notif-card.type-achievement { border-color: rgba(80, 220, 140, 0.2); }
.notif-card.type-alert     { border-color: rgba(255, 180, 50, 0.25); }

/* ─── Accent bar (left edge) ───────────────────────────────── */
.notif-accent-bar {
  position: absolute;
  left: 0; top: 0; bottom: 0;
  width: 4px;
  border-radius: 1rem 0 0 1rem;
  background: linear-gradient(180deg, #d4a017, #f0c040);
}
.type-birthday  .notif-accent-bar { background: linear-gradient(180deg, #f06496, #ff9cc0); }
.type-event     .notif-accent-bar { background: linear-gradient(180deg, #50b4ff, #a0d4ff); }
.type-achievement .notif-accent-bar { background: linear-gradient(180deg, #50dc8c, #a0f0c0); }
.type-alert     .notif-accent-bar { background: linear-gradient(180deg, #ffb432, #ffd280); }

/* ─── Top row ──────────────────────────────────────────────── */
.notif-top-row {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.notif-tag {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  padding: 0.25rem 0.65rem;
  border-radius: 999px;
  background: rgba(212, 160, 23, 0.12);
  color: #d4a017;
  border: 1px solid rgba(212, 160, 23, 0.25);
}
.tag-birthday    { background: rgba(240, 100, 150, 0.1); color: #f06496; border-color: rgba(240,100,150,0.25); }
.tag-event       { background: rgba(80, 180, 255, 0.1);  color: #50b4ff; border-color: rgba(80,180,255,0.2); }
.tag-achievement { background: rgba(80, 220, 140, 0.1);  color: #50dc8c; border-color: rgba(80,220,140,0.2); }
.tag-alert       { background: rgba(255, 180, 50, 0.1);  color: #ffb432; border-color: rgba(255,180,50,0.2); }

.notif-tag-icon { font-style: normal; }

.notif-date-chip {
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.07em;
  text-transform: uppercase;
  padding: 0.2rem 0.55rem;
  border-radius: 999px;
  background: rgba(212, 160, 23, 0.9);
  color: #0a0800;
}
.notif-date-chip.upcoming {
  background: transparent;
  color: var(--text2);
  border: 1px solid rgba(255,255,255,0.1);
}

/* ─── Content ──────────────────────────────────────────────── */
.notif-title {
  font-family: Cinzel, serif;
  font-size: 1.15rem;
  font-weight: 700;
  color: var(--text);
  margin: 0 0 0.6rem;
  line-height: 1.4;
}
.notif-message {
  color: var(--text2);
  font-size: 0.92rem;
  line-height: 1.65;
  margin: 0;
}

/* ─── Footer ───────────────────────────────────────────────── */
.notif-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 1.25rem;
  padding-top: 1rem;
  border-top: 1px solid rgba(212, 160, 23, 0.1);
}
.notif-link {
  font-size: 0.82rem;
  font-weight: 700;
  color: #d4a017;
  text-decoration: none;
  letter-spacing: 0.04em;
  transition: opacity 0.2s;
}
.notif-link:hover { opacity: 0.7; }
.notif-spacer { flex: 1; }
.notif-counter {
  font-size: 0.78rem;
  color: var(--text2);
  opacity: 0.6;
  font-variant-numeric: tabular-nums;
}

/* ─── Controls ─────────────────────────────────────────────── */
.notif-controls {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.notif-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: 1px solid rgba(212, 160, 23, 0.2);
  background: rgba(212, 160, 23, 0.06);
  color: #d4a017;
  cursor: pointer;
  transition: background 0.2s, border-color 0.2s;
}
.notif-btn:hover:not(:disabled) {
  background: rgba(212, 160, 23, 0.18);
  border-color: rgba(212, 160, 23, 0.4);
}
.notif-btn:disabled { opacity: 0.3; cursor: default; }
.play-btn {
  width: 40px;
  height: 40px;
  background: rgba(212, 160, 23, 0.12);
  border-color: rgba(212, 160, 23, 0.35);
}

/* ─── Progress bar ─────────────────────────────────────────── */
.notif-progress-wrap {
  width: 100%;
  height: 2px;
  background: rgba(212, 160, 23, 0.1);
  border-radius: 999px;
  overflow: hidden;
}
.notif-progress-bar {
  height: 100%;
  width: 0%;
  background: linear-gradient(90deg, #d4a017, #f0c040);
  border-radius: 999px;
  animation: progress-fill linear forwards;
}
@keyframes progress-fill {
  from { width: 0%; }
  to   { width: 100%; }
}

/* ─── Card transition ──────────────────────────────────────── */
.card-slide-enter-active,
.card-slide-leave-active {
  transition: all 0.35s cubic-bezier(0.4, 0, 0.2, 1);
}
.card-slide-enter-from {
  opacity: 0;
  transform: translateX(24px) scale(0.98);
}
.card-slide-leave-to {
  opacity: 0;
  transform: translateX(-24px) scale(0.98);
}

/* ─── Empty state ──────────────────────────────────────────── */
.notif-empty {
  text-align: center;
  padding: 3rem;
  opacity: 0.6;
}
</style>
