<template>
  <header class="anav">
    <div class="anav-in">
      <a class="anav-brand" href="#/lounge" aria-label="Sundarbans House Admin">
        <img :src="CREST" alt="" width="34" height="34" />
        <span class="anav-word" aria-hidden="true">
          <b>Sundarbans</b>
          <small>Admin</small>
        </span>
      </a>

      <nav class="anav-links" aria-label="Site destinations">
        <a href="#/lounge">Lounge</a>
        <a class="anav-site" href="#/" aria-label="Open the website">
          <span>Website</span>
          <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 17 17 7M9 7h8v8" /></svg>
        </a>
      </nav>

      <div class="anav-actions">
        <button
          v-if="membersVisible"
          type="button"
          class="anav-action anav-add"
          aria-label="Add students"
          @click="emit('add-students')"
        >
          <LineIcon name="people" /><span>Add students</span>
        </button>
        <button
          type="button"
          class="anav-action anav-create"
          aria-label="Create"
          @click="emit('create')"
        >
          <span class="plus" aria-hidden="true">+</span><span class="create-label">Create</span>
        </button>
        <button
          type="button"
          class="anav-icon"
          :aria-label="theme === 'dark' ? 'Switch to light theme' : 'Switch to dark theme'"
          @click="emit('toggle-theme', $event)"
        >
          <LineIcon :name="theme === 'dark' ? 'sun' : 'moon'" />
        </button>
        <button
          type="button"
          class="anav-profile"
          aria-label="Your account"
          @click="emit('profile')"
        >
          <span class="anav-initials" aria-hidden="true">{{ avatarInitials }}</span>
        </button>
      </div>
    </div>
  </header>
</template>

<script setup>
import LineIcon from '../site/LineIcon.vue';
import CREST from '../../assets/crest.webp';

defineProps({
  membersVisible: Boolean,
  theme: { type: String, required: true },
  avatarInitials: { type: String, default: 'A' },
});
const emit = defineEmits(['add-students', 'create', 'profile', 'toggle-theme']);
</script>

<style scoped>
.anav {
  position: fixed;
  inset: 0 0 auto;
  z-index: 40;
  height: var(--nav-h);
  background: color-mix(in srgb, var(--paper) 94%, transparent);
  color: var(--ink);
  border-bottom: 1px solid var(--line);
  backdrop-filter: blur(10px);
}

.anav-in {
  position: relative;
  width: 100%;
  max-width: 1240px;
  height: 100%;
  margin: 0 auto;
  padding: 0 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.anav-brand {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
  flex: none;
  color: inherit;
  text-decoration: none;
  border-radius: 999px;
}

.anav-brand img {
  flex: none;
  width: 34px;
  height: 34px;
}

.anav-word {
  display: grid;
  line-height: 1.05;
  white-space: nowrap;
}

.anav-word b {
  font-size: 17px;
  font-weight: 750;
  letter-spacing: -0.02em;
}

.anav-word small {
  font-size: 10.5px;
  letter-spacing: 0.02em;
  color: var(--ink-2);
}

.anav-links {
  display: flex;
  position: absolute;
  top: 50%;
  left: 50%;
  flex: none;
  gap: 2px;
  transform: translate(-50%, -50%);
}

.anav-links a {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 8px 9px;
  border-radius: 9px;
  color: var(--ink-2);
  font-size: 13px;
  font-weight: 600;
  text-decoration: none;
  white-space: nowrap;
}

.anav-links a:hover {
  color: var(--ink);
  background: var(--sunk);
}

.anav-links .anav-site {
  color: var(--mari-ink);
}

.anav-site svg {
  width: 13px;
  height: 13px;
  flex: none;
  fill: none;
  stroke: currentColor;
  stroke-width: 2;
  stroke-linecap: round;
  stroke-linejoin: round;
}

.anav-actions {
  display: flex;
  flex: none;
  align-items: center;
  gap: 7px;
  margin-left: auto;
}

.anav-action {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 7px;
  height: 36px;
  padding: 0 12px;
  border: 1px solid var(--line);
  border-radius: 9px;
  background: var(--card);
  color: var(--ink);
  font: inherit;
  font-size: 13px;
  font-weight: 600;
  white-space: nowrap;
  cursor: pointer;
}

.anav-action:hover {
  border-color: var(--ink-3);
}

.anav-action :deep(svg) {
  width: 16px;
  height: 16px;
}

.anav-create {
  border-color: var(--mari);
  background: var(--mari);
  color: var(--on-mari);
}

.anav-create:hover {
  filter: brightness(1.05);
}

.plus {
  font-size: 17px;
  line-height: 1;
}

.anav-icon,
.anav-profile {
  display: grid;
  flex: none;
  width: 34px;
  height: 34px;
  place-items: center;
  border: 1px solid transparent;
  border-radius: 50%;
  background: transparent;
  color: var(--ink-2);
  cursor: pointer;
}

.anav-icon:hover,
.anav-profile:hover {
  border-color: var(--line);
  background: var(--sunk);
}

.anav-icon :deep(svg) {
  width: 19px;
  height: 19px;
}

.anav-profile {
  overflow: hidden;
  width: 38px;
  height: 38px;
  border: 0;
  background: transparent;
}

.anav-profile img {
  width: 100%;
  height: 100%;
  border-radius: 50%;
  object-fit: cover;
}

.anav-initials {
  display: grid;
  width: 100%;
  height: 100%;
  place-items: center;
  border-radius: 50%;
  background: var(--mari);
  color: var(--on-mari);
  font-size: 12px;
  font-weight: 800;
  letter-spacing: 0.02em;
}

@media (max-width: 1020px) {
  .anav-in {
    padding: 0 16px;
  }

  .anav-links {
    gap: 0;
  }

  .anav-links a {
    padding: 8px 6px;
    font-size: 12px;
  }
}

@media (max-width: 860px) {
  .anav-in {
    gap: 6px;
  }

  .anav-add span,
  .create-label {
    display: none;
  }

  .anav-action {
    width: 34px;
    padding: 0;
  }

  .anav-actions {
    gap: 4px;
  }
}

@media (max-width: 760px) {
  .anav-in {
    padding: 0 10px;
  }

  .anav-word {
    display: none;
  }

  .anav-brand img {
    width: 32px;
    height: 32px;
  }
}

@media (max-width: 560px) {
  .anav-in {
    gap: 2px;
    padding: 0 7px;
  }

  .anav-brand img {
    width: clamp(28px, 7vw, 32px);
    height: clamp(28px, 7vw, 32px);
  }

  .anav-action {
    width: clamp(26px, 7vw, 32px);
    height: clamp(26px, 7vw, 32px);
  }

  .anav-links a {
    padding: 5px clamp(0px, 0.25vw, 2px);
    font-size: clamp(10px, 2vw, 11px);
  }

  .anav-site svg {
    width: clamp(11px, 2.3vw, 13px);
    height: clamp(11px, 2.3vw, 13px);
  }

  .anav-icon,
  .anav-profile {
    width: clamp(26px, 7vw, 30px);
    height: clamp(26px, 7vw, 30px);
  }

  .anav-actions {
    gap: clamp(1px, 0.5vw, 2px);
  }
}
</style>
