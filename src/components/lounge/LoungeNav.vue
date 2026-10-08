<!--
  The Lounge header, shared by Home and Events: the crest and wordmark (left), Home / Events
  (centred), and the notices bell (badge = unread), the theme toggle and the profile avatar
  (right). No progress bar. Under it, the newest urgent notice as a slim paper strip with a
  vermilion rule, dismissible (verdict §9.5).
-->
<template>
  <header class="lnav">
    <a class="lnav-brand" href="#/lounge" aria-label="Sundarbans House, the Lounge: Home">
      <img :src="CREST" alt="" width="34" height="34" />
      <span class="lnav-word" aria-hidden="true">
        <b>Sundarbans</b>
        <small>The Lounge</small>
      </span>
    </a>
    <nav class="lnav-links" aria-label="Main">
      <a href="#/lounge" :aria-current="view === 'home' ? 'page' : undefined">Home</a>
      <a href="#/lounge?view=events" :aria-current="view === 'events' ? 'page' : undefined"
        >Events</a
      >
    </nav>
    <div class="lnav-acts">
      <button
        type="button"
        class="lnav-btn"
        :aria-label="unread ? `Notices, ${unread} unread` : 'Notices'"
        aria-haspopup="dialog"
        @click="emit('notices')"
      >
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path d="M6 9a6 6 0 1 1 12 0c0 5 2 6.5 2 6.5H4S6 14 6 9Z" />
          <path d="M10 18.5a2 2 0 0 0 4 0" />
        </svg>
        <span v-if="unread" class="gp-badge lnav-badge" aria-hidden="true">{{ unread }}</span>
      </button>
      <button
        type="button"
        class="lnav-btn lnav-theme"
        :class="{ dark: theme === 'dark' }"
        :aria-label="theme === 'dark' ? 'Switch to day' : 'Switch to night'"
        @pointerenter="tide.warmOther?.()"
        @focus="tide.warmOther?.()"
        @click="(e) => tide.toggleTheme?.(e)"
      >
        <svg class="lnav-sun" viewBox="0 0 24 24" aria-hidden="true">
          <circle cx="12" cy="12" r="4.4" />
          <path
            d="M12 2.2v2.4M12 19.4v2.4M2.2 12h2.4M19.4 12h2.4M5.1 5.1l1.7 1.7M17.2 17.2l1.7 1.7M5.1 18.9l1.7-1.7M17.2 6.8l1.7-1.7"
          />
        </svg>
        <svg class="lnav-moon" viewBox="0 0 24 24" aria-hidden="true">
          <path d="M19.5 14.6A8 8 0 0 1 9.4 4.5a8 8 0 1 0 10.1 10.1Z" />
        </svg>
      </button>
      <button
        type="button"
        class="lnav-me"
        :aria-label="callName ? `Your profile, ${callName}` : 'Your profile'"
        aria-haspopup="dialog"
        :aria-expanded="profileOpen ? 'true' : 'false'"
        @click="emit('profile')"
      >
        <span v-if="initials" aria-hidden="true">{{ initials }}</span>
        <img v-else :src="CREST" alt="" />
      </button>
    </div>
  </header>

  <div v-if="strip" class="lnav-strip" role="region" aria-label="New notice">
    <button type="button" class="lnav-strip-open" @click="emit('notices', strip.id)">
      <span class="lnav-strip-k">Notice</span>
      <span class="lnav-strip-text"
        ><b>{{ strip.title }}.</b> <span class="lnav-strip-body">{{ strip.body }}</span></span
      >
    </button>
    <button
      type="button"
      class="lnav-strip-x"
      aria-label="Dismiss this notice"
      @click="ev.dismissBanner?.(strip)"
    >
      <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 6l12 12M18 6 6 18" /></svg>
    </button>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, watchEffect } from 'vue';
import CREST from '../../assets/crest.webp';
import * as ev from './events.js';
import { callName, initialsOf, theme } from './state.js';
import * as tide from './tide.js';

defineProps({ view: { type: String, default: 'home' }, profileOpen: Boolean });
const emit = defineEmits(['notices', 'profile']);

/* events.js and tide.js belong to other workers; read them defensively. */
const unread = computed(() => ev.unreadCount?.value ?? 0);
const strip = computed(() => ev.bannerNotice?.value ?? null);
const initials = computed(() => initialsOf(callName.value));

/* Views pad their top by --banner-h while the strip shows. */
watchEffect(() => document.documentElement.classList.toggle('has-banner', !!strip.value));
onBeforeUnmount(() => document.documentElement.classList.remove('has-banner'));
</script>

<style>
:where(html.lounge-active) .lnav {
  position: fixed;
  inset: 0 0 auto;
  z-index: 20;
  height: var(--nav-h);
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto minmax(0, 1fr);
  align-items: center;
  gap: 12px;
  padding: 0 20px;
  background: var(--bg);
  color: var(--t-1);
  border-bottom: 1px solid color-mix(in srgb, var(--keyline) 55%, transparent);
}

:where(html.lounge-active) .lnav-brand {
  justify-self: start;
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
  color: inherit;
  text-decoration: none;
  border-radius: 999px;
}

:where(html.lounge-active) .lnav-brand img {
  flex: none;
  width: 34px;
  height: 34px;
}

:where(html.lounge-active) .lnav-word {
  display: grid;
  line-height: 1;
  white-space: nowrap;
}

:where(html.lounge-active) .lnav-word b {
  font-size: 16px;
  font-weight: 700;
  letter-spacing: -0.01em;
}

:where(html.lounge-active) .lnav-word small {
  margin-top: 3px;
  font-size: 11px;
  font-weight: 700;
  font-stretch: 112.5%;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--accent);
}

:where(html.lounge-active) .lnav-links {
  display: flex;
  gap: 4px;
}

:where(html.lounge-active) .lnav-links a {
  position: relative;
  display: grid;
  place-items: center;
  min-height: 40px;
  padding: 0 14px;
  border-radius: 999px;
  font-size: 15px;
  font-weight: 600;
  color: var(--t-2);
  text-decoration: none;
}

:where(html.lounge-active) .lnav-links a:hover {
  color: var(--t-1);
}

:where(html.lounge-active) .lnav-links a[aria-current='page'] {
  color: var(--t-1);
  font-weight: 700;
}

/* The current page: a short lamp rule under the word. */
:where(html.lounge-active) .lnav-links a[aria-current='page']::after {
  content: '';
  position: absolute;
  left: 14px;
  right: 14px;
  bottom: 5px;
  height: 2px;
  border-radius: 2px;
  background: var(--lamp);
}

:where(html.lounge-active) .lnav-acts {
  justify-self: end;
  display: flex;
  align-items: center;
  gap: 8px;
}

:where(html.lounge-active) .lnav-btn,
:where(html.lounge-active) .lnav-me {
  position: relative;
  display: grid;
  place-items: center;
  width: 38px;
  height: 38px;
  padding: 0;
  border: 1px solid color-mix(in srgb, var(--keyline) 80%, transparent);
  border-radius: 50%;
  background: transparent;
  color: var(--t-1);
  cursor: pointer;
}

:where(html.lounge-active) .lnav-btn:hover {
  background: color-mix(in srgb, var(--t-1) 7%, transparent);
}

:where(html.lounge-active) .lnav-btn svg {
  grid-area: 1 / 1;
  width: 20px;
  height: 20px;
  fill: none;
  stroke: currentColor;
  stroke-width: 1.8;
  stroke-linecap: round;
  stroke-linejoin: round;
}

:where(html.lounge-active) .lnav-badge {
  position: absolute;
  top: -4px;
  right: -5px;
  box-shadow: 0 0 0 2px var(--bg);
}

:where(html.lounge-active) .lnav-sun circle,
:where(html.lounge-active) .lnav-moon path {
  fill: currentColor;
  stroke: none;
}

:where(html.lounge-active) .lnav-theme svg {
  transition:
    transform 0.4s var(--ease-out),
    opacity 0.25s linear;
}

:where(html.lounge-active) .lnav-moon,
:where(html.lounge-active) .lnav-theme.dark .lnav-sun {
  opacity: 0;
  transform: rotate(-60deg) scale(0.6);
}

:where(html.lounge-active) .lnav-theme.dark .lnav-moon {
  opacity: 1;
  transform: none;
}

:where(html.lounge-active) .lnav-me {
  overflow: hidden;
  background: var(--paper);
  border-color: var(--keyline);
  color: var(--accent);
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.02em;
}

:where(html.lounge-active) .lnav-me img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

:where(html.lounge-active) .lnav-me[aria-expanded='true'] {
  outline: 2px solid var(--lamp);
  outline-offset: 2px;
}

/* ---------- Slim notice strip ---------- */
:where(html.lounge-active) .lnav-strip {
  position: fixed;
  top: var(--nav-h);
  left: 0;
  right: 0;
  z-index: 19;
  display: flex;
  align-items: center;
  height: var(--banner-h);
  padding: 0 6px 0 0;
  background: var(--paper);
  color: var(--t-1);
  border-bottom: 1px solid color-mix(in srgb, var(--keyline) 55%, transparent);
  box-shadow: inset 3px 0 0 var(--verm);
}

:where(html.lounge-active) .lnav-strip-open {
  display: flex;
  align-items: center;
  gap: 10px;
  flex: 1;
  min-width: 0;
  height: 100%;
  padding: 0 8px 0 18px;
  border: 0;
  background: none;
  color: inherit;
  font: inherit;
  text-align: left;
  cursor: pointer;
}

:where(html.lounge-active) .lnav-strip-k {
  flex: none;
  font-size: 11px;
  font-weight: 700;
  font-stretch: 112.5%;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--live);
}

:where(html.lounge-active) .lnav-strip-text {
  min-width: 0;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
  font-size: 14px;
  color: var(--t-2);
}

:where(html.lounge-active) .lnav-strip-text b {
  font-weight: 700;
  color: var(--t-1);
}

:where(html.lounge-active) .lnav-strip-open:hover .lnav-strip-text b {
  text-decoration: underline;
  text-underline-offset: 3px;
}

:where(html.lounge-active) .lnav-strip-x {
  flex: none;
  display: grid;
  place-items: center;
  width: 32px;
  height: 32px;
  padding: 0;
  border: 0;
  border-radius: 50%;
  background: none;
  color: var(--t-2);
  cursor: pointer;
}

:where(html.lounge-active) .lnav-strip-x:hover {
  color: var(--t-1);
  background: color-mix(in srgb, var(--t-1) 7%, transparent);
}

:where(html.lounge-active) .lnav-strip-x svg {
  width: 16px;
  height: 16px;
  fill: none;
  stroke: currentColor;
  stroke-width: 2.2;
  stroke-linecap: round;
}

:where(html.lounge-active) .lnav-strip :focus-visible {
  outline-offset: -2px;
}

/* Page switch (tide.js adds html.vt-page): the header and strip hold still. */
html:where(.lounge-active).vt-page .lnav {
  view-transition-name: lounge-nav;
}

html:where(.lounge-active).vt-page .lnav-strip {
  view-transition-name: lounge-notice;
}

@media (max-width: 759px) {
  :where(html.lounge-active) .lnav {
    gap: 6px;
    padding: 0 12px;
  }

  :where(html.lounge-active) .lnav-links a {
    padding: 0 10px;
  }

  :where(html.lounge-active) .lnav-links a[aria-current='page']::after {
    left: 10px;
    right: 10px;
  }

  :where(html.lounge-active) .lnav-acts {
    gap: 6px;
  }

  :where(html.lounge-active) .lnav-btn,
  :where(html.lounge-active) .lnav-me {
    width: 36px;
    height: 36px;
  }

  :where(html.lounge-active) .lnav-strip-body {
    display: none;
  }

  :where(html.lounge-active) .lnav-strip-open {
    padding-left: 14px;
  }
}

@media (max-width: 480px) {
  /* No room for equal side columns: the links take the middle and stay centred in it. */
  :where(html.lounge-active) .lnav {
    grid-template-columns: auto minmax(0, 1fr) auto;
  }

  :where(html.lounge-active) .lnav-links {
    justify-self: center;
  }

  :where(html.lounge-active) .lnav-word {
    display: none;
  }
}

@media (prefers-reduced-motion: reduce) {
  :where(html.lounge-active) .lnav-theme svg {
    transition: none;
  }
}
</style>
