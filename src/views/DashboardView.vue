<template>
  <div class="dashboard-page">
    <!-- Film grain texture overlay (purely decorative) -->
    <div class="grain"></div>

    <!-- Confetti canvas (full-screen, pointer-events: none) -->
    <canvas id="confetti-canvas" ref="canvasEl"></canvas>

    <!-- ══ NAVIGATION ══ -->
    <header class="dash-navbar">
      <div class="nav-inner">
        <router-link to="/" class="nav-brand">
          <div class="nav-brand-icon">🌿</div>
          <span class="nav-brand-name">Sundarbans</span>
        </router-link>
        <span class="nav-title">House Widgets</span>
        <router-link to="/lounge" class="back-link" style="margin-left:auto;">← Back to Lounge</router-link>
      </div>
    </header>

    <main class="dashboard-shell">
      <!-- ══ PAGE HERO ══ -->
      <section class="dashboard-hero" aria-labelledby="dashboard-title">
        <div class="hero-copy">
          <span class="hero-kicker">Members Command Center</span>
          <h1 id="dashboard-title">Your <em>House Dashboard</em></h1>
          <p>Track your rhythm, join active study spaces, and keep the house energy moving from one focused workspace.</p>
        </div>
        <div class="hero-panel" aria-label="Dashboard summary">
          <div class="hero-metric">
            <strong>8</strong>
            <span>Live widgets</span>
          </div>
          <div class="hero-metric">
            <strong>{{ DATA.housePoints.categories.length }}</strong>
            <span>Point tracks</span>
          </div>
          <div class="hero-metric">
            <strong>{{ DATA.studyBuddies.length }}</strong>
            <span>Buddy pool</span>
          </div>
        </div>
      </section>

      <!-- ══ DASHBOARD WORKSPACE ══ -->
      <section class="dashboard-workspace" aria-label="House dashboard widgets">
        <div class="dashboard-tabs" role="tablist" aria-label="Dashboard sections">
          <button
            v-for="tab in dashboardTabs"
            :id="`dashboard-tab-${tab.id}`"
            :key="tab.id"
            type="button"
            class="dashboard-tab"
            role="tab"
            :class="{ active: activeTab === tab.id }"
            :aria-selected="activeTab === tab.id"
            :aria-controls="`dashboard-panel-${tab.id}`"
            @click="activeTab = tab.id"
          >
            <span class="tab-label">{{ tab.label }}</span>
            <span class="tab-purpose">{{ tab.purpose }}</span>
          </button>
        </div>

        <div
          id="dashboard-panel-focus"
          class="dashboard-tab-panel"
          role="tabpanel"
          aria-labelledby="dashboard-tab-focus"
          v-show="activeTab === 'focus'"
        >
          <div class="section-heading">
            <span class="section-eyebrow">Focus</span>
            <h2>Start Here</h2>
          </div>
          <div class="dashboard-panel-grid dashboard-panel-grid-two">
            <StudyStreak class="widget-priority" @confetti="onConfetti" />
            <PomodoroRoom class="widget-priority" :config="DATA.pomodoro" @confetti="onConfetti" />
          </div>
        </div>

        <div
          id="dashboard-panel-practice"
          class="dashboard-tab-panel"
          role="tabpanel"
          aria-labelledby="dashboard-tab-practice"
          v-show="activeTab === 'practice'"
        >
          <div class="section-heading">
            <span class="section-eyebrow">Practice</span>
            <h2>Skill &amp; Progress</h2>
          </div>
          <div class="dashboard-panel-grid dashboard-panel-grid-practice">
            <DailyChallenge class="widget-wide" :config="DATA.dailyChallenge" @confetti="onConfetti" />
            <HousePoints class="widget-compact" :config="DATA.housePoints" />
          </div>
        </div>

        <div
          id="dashboard-panel-community"
          class="dashboard-tab-panel"
          role="tabpanel"
          aria-labelledby="dashboard-tab-community"
          v-show="activeTab === 'community'"
        >
          <div class="section-heading">
            <span class="section-eyebrow">Community</span>
            <h2>House Pulse</h2>
          </div>
          <div class="dashboard-panel-grid dashboard-panel-grid-community">
            <MoodWall class="widget-wide" :config="DATA.moods" />
            <ConfessionWall class="widget-wide" :config="DATA.confessions" />
            <BuddyMatcher class="widget-compact" :pool="DATA.studyBuddies" :options="DATA.buddyOptions" />
          </div>
        </div>

        <div
          id="dashboard-panel-fun"
          class="dashboard-tab-panel"
          role="tabpanel"
          aria-labelledby="dashboard-tab-fun"
          v-show="activeTab === 'fun'"
        >
          <div class="section-heading">
            <span class="section-eyebrow">Fun</span>
            <h2>Weekly Fun</h2>
          </div>
          <div class="dashboard-panel-grid dashboard-panel-grid-single">
            <MemeOfWeek class="widget-wide" :config="DATA.meme" />
          </div>
        </div>
      </section>
    </main>

    <!-- ══ FOOTER ══ -->
    <footer class="dash-footer">
      <div class="footer-inner">
        <div class="footer-brand">Sundarbans House</div>
        <div class="footer-copy">© 2026 IIT Madras BS Programme · All rights reserved</div>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useConfetti } from '../composables/useConfetti.js';

// Widget components
import StudyStreak from '../components/dashboard/StudyStreak.vue';
import MoodWall from '../components/dashboard/MoodWall.vue';
import ConfessionWall from '../components/dashboard/ConfessionWall.vue';
import HousePoints from '../components/dashboard/HousePoints.vue';
import PomodoroRoom from '../components/dashboard/PomodoroRoom.vue';
import BuddyMatcher from '../components/dashboard/BuddyMatcher.vue';
import DailyChallenge from '../components/dashboard/DailyChallenge.vue';
import MemeOfWeek from '../components/dashboard/MemeOfWeek.vue';

// Data
import DATA from '../data/dashboard.json';

// CSS
import '../assets/dashboard.css';

// Auth check
const router = useRouter();
onMounted(() => {
  const token = localStorage.getItem('sundarbans_auth_token');
  if (!token) { router.push('/members'); return; }
});

// Confetti engine
const canvasEl = ref(null);
const activeTab = ref('focus');
const { canvasRef, fireConfetti } = useConfetti();

const dashboardTabs = [
  { id: 'focus', label: 'Focus', purpose: 'Streaks & study rooms' },
  { id: 'practice', label: 'Practice', purpose: 'Challenges & points' },
  { id: 'community', label: 'Community', purpose: 'Mood, wall & buddies' },
  { id: 'fun', label: 'Fun', purpose: 'Meme of the week' },
];

onMounted(() => {
  canvasRef.value = canvasEl.value;

  // Re-init canvas size for the composable
  if (canvasEl.value) {
    canvasEl.value.width = window.innerWidth;
    canvasEl.value.height = window.innerHeight;
  }
});

function onConfetti(ox, oy) {
  fireConfetti(ox, oy);
}
</script>
