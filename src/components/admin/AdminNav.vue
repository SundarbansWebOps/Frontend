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
          <LineIcon name="external" />
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
          aria-haspopup="dialog"
          :aria-expanded="profileOpen ? 'true' : 'false'"
          @click="emit('profile')"
        >
          <img
            v-if="avatarUrl"
            :src="avatarUrl"
            alt=""
            referrerpolicy="no-referrer"
            @error="avatarFailed"
          />
          <img v-else :src="CREST" alt="" />
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
  profileOpen: Boolean,
  avatarUrl: { type: String, default: '' },
  avatarFailed: { type: Function, required: true },
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
  max-width: none;
  height: 100%;
  margin: 0;
  padding: 0 var(--admin-gutter);
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
  background: var(--mari-soft);
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
  border: 1px solid var(--line-strong);
  border-radius: 9px;
  background: var(--card);
  box-shadow: 0 1px 0 var(--line-strong);
  color: var(--ink);
  font: inherit;
  font-size: 13px;
  font-weight: 600;
  white-space: nowrap;
  cursor: pointer;
}

.anav-action:hover {
  border-color: var(--mari-ink);
  background: var(--mari-soft);
}

.anav-action :deep(svg) {
  width: 16px;
  height: 16px;
}

.anav-create {
  border-color: var(--mari-ink);
  background: var(--mari);
  box-shadow: 0 1px 0 var(--mari-ink);
  color: var(--on-mari);
}

.anav-create:hover {
  background: var(--mari);
  filter: brightness(1.06);
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
  border: 1px solid var(--line-strong);
  border-radius: 50%;
  background: var(--card);
  color: var(--ink-2);
  cursor: pointer;
}

.anav-icon:hover,
.anav-profile:hover {
  border-color: var(--mari-ink);
  background: var(--mari-soft);
  color: var(--ink);
}

.anav-icon :deep(svg) {
  width: 19px;
  height: 19px;
}

.anav-profile {
  overflow: hidden;
  width: 38px;
  height: 38px;
  padding: 0;
  border: 1.5px solid var(--line-strong);
  background: var(--paper);
}

.anav-profile img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

@media (max-width: 1020px) {
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
  .anav-links {
    position: static;
    transform: none;
  }

  .anav-actions {
    margin-left: 0;
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
  }

  .anav-brand img {
    width: clamp(28px, 7vw, 32px);
    height: clamp(28px, 7vw, 32px);
  }

  .anav-action {
    width: 32px;
    height: 32px;
  }

  .anav-links {
    gap: 8px;
  }

  .anav-links a {
    padding: 8px 0;
    font-size: 12px;
  }

  .anav-site svg {
    width: clamp(11px, 2.3vw, 13px);
    height: clamp(11px, 2.3vw, 13px);
  }

  .anav-icon,
  .anav-profile {
    width: 32px;
    height: 32px;
  }

  .anav-actions {
    gap: 2px;
  }
}
</style>
