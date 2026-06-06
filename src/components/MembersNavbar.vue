<template>
  <header class="members-navbar" :class="{ scrolled: navScrolled }" id="navbar">
    <div class="nav-inner">
      <router-link to="/" class="nav-brand">
        <div class="nav-brand-icon">🌿</div>
        <span class="nav-brand-name">Sundarbans</span>
      </router-link>

      <nav class="nav-links">
        <router-link to="/lounge#events" class="nav-link">Events</router-link>
        <router-link to="/lounge#lounge" class="nav-link">Reading</router-link>
        <router-link to="/lounge#community" class="nav-link">Community</router-link>
        <router-link to="/lounge#leaderboard" class="nav-link">Leaderboard</router-link>
        <router-link to="/dashboard" class="nav-link">Dashboard</router-link>
      </nav>

      <div class="nav-right">
        <div class="member-chip">
          <div class="member-avatar">{{ memberInitial }}</div>
          <span class="member-id">{{ memberEmail }}</span>
        </div>
        <button class="logout-btn" @click="$emit('logout')">Logout</button>
      </div>
    </div>
  </header>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';

const props = defineProps({
  memberEmail: { type: String, default: '' },
});

defineEmits(['logout']);

const memberInitial = computed(() =>
  props.memberEmail ? props.memberEmail.charAt(0).toUpperCase() : '?'
);

const navScrolled = ref(false);
function handleScroll() {
  navScrolled.value = window.scrollY > 60;
}
onMounted(() => window.addEventListener('scroll', handleScroll));
onUnmounted(() => window.removeEventListener('scroll', handleScroll));
</script>

<style scoped>
/* CSS custom properties scoped to this component */
.members-navbar {
  --black: #060808;
  --deep: #0a0f0a;
  --forest: #131d13;
  --panel: rgba(15,22,15,0.85);
  --border: rgba(201,168,76,0.15);
  --border-soft: rgba(255,255,255,0.07);
  --gold: #c9a84c;
  --gold-light: #e8c97a;
  --gold-dim: rgba(201,168,76,0.12);
  --cream: #f5f0e8;
  --muted: rgba(245,240,232,0.5);
  --subtle: rgba(245,240,232,0.12);

  position: sticky; top: 0; z-index: 100;
  background: rgba(6,8,8,0.9);
  backdrop-filter: blur(24px);
  border-bottom: 1px solid var(--border-soft);
  padding: 0 60px;
  height: 72px;
  display: flex; align-items: center;
  transition: border-color 0.3s;
}
.members-navbar.scrolled { border-color: rgba(201,168,76,0.2); }

.nav-inner {
  width: 100%; max-width: 1300px;
  margin: 0 auto;
  display: flex; align-items: center; justify-content: space-between;
}
.nav-brand {
  display: flex; align-items: center; gap: 12px;
  text-decoration: none;
}
.nav-brand-icon {
  width: 36px; height: 36px;
  border: 1px solid var(--border);
  border-radius: 7px;
  display: grid; place-items: center;
  font-size: 16px;
  background: var(--gold-dim);
}
.nav-brand-name {
  font-weight: 800; font-size: 18px;
  letter-spacing: 0.25em; text-transform: uppercase;
  color: var(--gold);
  font-family: 'Outfit', sans-serif;
}
.nav-links {
  display: flex; align-items: center; gap: 4px;
}
.nav-link {
  padding: 8px 16px;
  font-size: 17px; font-weight: 400;
  color: var(--muted);
  text-decoration: none;
  border-radius: 6px;
  transition: color 0.2s, background 0.2s;
  letter-spacing: 0.03em;
  font-family: 'Outfit', sans-serif;
}
.nav-link:hover { color: var(--cream); background: var(--subtle); }
.nav-link.router-link-active { color: var(--gold); }

.nav-right { display: flex; align-items: center; gap: 16px; }
.member-chip {
  display: flex; align-items: center; gap: 10px;
  background: var(--gold-dim);
  border: 1px solid var(--border);
  border-radius: 100px;
  padding: 8px 16px 8px 10px;
}
.member-avatar {
  width: 28px; height: 28px;
  border-radius: 50%;
  background: var(--gold);
  display: grid; place-items: center;
  font-size: 13px; font-weight: 600;
  color: var(--black);
}
.member-id {
  font-size: 12px; color: var(--muted); font-weight: 400;
  max-width: 160px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  font-family: 'Outfit', sans-serif;
}
.logout-btn {
  padding: 9px 20px;
  background: transparent;
  border: 1px solid rgba(255,255,255,0.12);
  border-radius: 6px;
  color: var(--muted);
  font-family: 'Outfit', sans-serif;
  font-size: 12px; font-weight: 500;
  letter-spacing: 0.1em; text-transform: uppercase;
  cursor: pointer;
  transition: all 0.2s;
}
.logout-btn:hover { border-color: rgba(255,100,100,0.4); color: #e08080; }

@media (max-width: 900px) {
  .members-navbar { padding: 0 24px; }
  .nav-links { display: none; }
  .member-id { display: none; }
}
</style>
