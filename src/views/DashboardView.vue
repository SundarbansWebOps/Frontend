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
        <div class="dashboard-column dashboard-column-main">
          <div class="dashboard-section">
            <div class="section-heading">
              <span class="section-eyebrow">Today</span>
              <h2>Start Here</h2>
            </div>
            <div class="priority-stack">
              <StudyStreak class="widget-priority" @confetti="onConfetti" />
              <PomodoroRoom class="widget-priority" :config="DATA.pomodoro" @confetti="onConfetti" />
            </div>
          </div>

          <div class="dashboard-section">
            <div class="section-heading">
              <span class="section-eyebrow">Practice</span>
              <h2>Skill &amp; Progress</h2>
            </div>
            <DailyChallenge class="widget-wide" :config="DATA.dailyChallenge" @confetti="onConfetti" />
          </div>

          <div class="dashboard-section">
            <div class="section-heading">
              <span class="section-eyebrow">Community</span>
              <h2>House Pulse</h2>
            </div>
            <div class="community-stack">
              <MoodWall class="widget-wide" :config="DATA.moods" />
              <ConfessionWall class="widget-wide" :config="DATA.confessions" />
            </div>
          </div>
        </div>

        <aside class="dashboard-column dashboard-column-side" aria-label="Community and ranking widgets">
          <HousePoints class="widget-compact" :config="DATA.housePoints" />
          <BuddyMatcher class="widget-compact" :pool="DATA.studyBuddies" :options="DATA.buddyOptions" />
          <MemeOfWeek class="widget-compact" :config="DATA.meme" />
        </aside>
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
const { canvasRef, fireConfetti } = useConfetti();

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
