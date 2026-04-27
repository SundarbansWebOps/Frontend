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

    <!-- ══ PAGE HERO ══ -->
    <div class="page-hero">
      <h1>Your <em>House Dashboard</em></h1>
      <p>Eight interactive features — all working, all persisting across sessions.</p>
    </div>

    <!-- ══ WIDGETS GRID ══ -->
    <main class="widgets-grid">
      <StudyStreak   @confetti="onConfetti" />
      <MoodWall      :config="DATA.moods" />
      <ConfessionWall :config="DATA.confessions" />
      <HousePoints   :config="DATA.housePoints" />
      <PomodoroRoom  :config="DATA.pomodoro" @confetti="onConfetti" />
      <BuddyMatcher  :pool="DATA.studyBuddies" :options="DATA.buddyOptions" />
      <DailyChallenge :config="DATA.dailyChallenge" @confetti="onConfetti" />
      <MemeOfWeek    :config="DATA.meme" />
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
