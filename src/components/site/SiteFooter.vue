<!--
  The foot of every page except Home (Home ends on its own scroll cloth). A tide line, then
  the few things people come looking for at the bottom: certificate check, portals, socials.
  id="contact" is where the old /contact link lands.
-->
<template>
  <footer id="contact" class="site-foot">
    <svg class="tide" viewBox="0 0 1200 24" preserveAspectRatio="none" aria-hidden="true">
      <path
        d="M0 12 C100 2 200 22 300 12 S500 2 600 12 800 22 900 12 1100 2 1200 12"
        pathLength="1"
      />
    </svg>
    <div class="row">
      <RouterLink to="/verify-certificate"
        ><LineIcon name="seal" /> Verify a certificate</RouterLink
      >
      <a :href="PORTAL.href" target="_blank" rel="noopener">
        <LineIcon :name="PORTAL.icon" /> IITM student portal
      </a>
      <a :href="WHATSAPP" target="_blank" rel="noopener">
        <LineIcon name="wa" /> WhatsApp channel
      </a>
    </div>
    <div class="social">
      <a
        v-for="s in SOCIAL"
        :key="s.icon"
        :href="s.href"
        target="_blank"
        rel="noopener"
        :aria-label="s.label"
        :title="s.label"
      >
        <LineIcon :name="s.icon" />
      </a>
    </div>
    <small>Sundarbans House · IIT Madras BS</small>
  </footer>
</template>

<script setup>
import LineIcon from './LineIcon.vue';
import { TOOLS, WHATSAPP } from '../../lib/courses.js';

const PORTAL = TOOLS[0];
const SOCIAL = [
  {
    icon: 'linkedin',
    label: 'Sundarbans on LinkedIn',
    href: 'https://www.linkedin.com/company/sundarbans-iitm/',
  },
  {
    icon: 'instagram',
    label: 'Sundarbans on Instagram',
    href: 'https://www.instagram.com/sundarbansiitm/',
  },
  {
    icon: 'youtube',
    label: 'Sundarbans on YouTube',
    href: 'https://www.youtube.com/@sundarbansiitm',
  },
];
</script>

<style scoped>
.site-foot {
  position: relative;
  display: grid;
  justify-items: center;
  gap: 14px;
  max-width: 1240px;
  margin: 0 auto;
  padding: 8px 24px 40px;
  color: var(--ink-2);
}
.tide {
  width: 100%;
  height: 24px;
  margin-bottom: 6px;
}
.tide path {
  fill: none;
  stroke: var(--line-strong);
  stroke-width: 1.5;
  vector-effect: non-scaling-stroke;
  stroke-dasharray: 1;
  stroke-dashoffset: 0;
}
/* Where supported, the tide line draws itself as the footer scrolls into view. */
@supports (animation-timeline: view()) {
  .tide path {
    animation: tide-draw linear both;
    animation-timeline: view();
    animation-range: entry 10% cover 30%;
  }
  @keyframes tide-draw {
    from {
      stroke-dashoffset: 1;
    }
  }
}
.row {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 6px 28px;
}
.row a {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 4px;
  color: var(--ink);
  font-size: 14.5px;
  font-weight: 600;
  text-decoration: none;
}
.row a:hover {
  text-decoration: underline;
  text-underline-offset: 4px;
}
.row .ic {
  width: 18px;
  height: 18px;
  color: var(--mari-ink);
}
.social {
  display: flex;
  gap: 8px;
}
.social a {
  display: grid;
  place-items: center;
  width: 38px;
  height: 38px;
  border-radius: 50%;
  border: 1.5px solid var(--line);
  color: var(--ink-2);
  transition:
    color 0.2s,
    border-color 0.2s,
    transform 0.25s var(--ease-spring);
}
.social a:hover {
  color: var(--ink);
  border-color: var(--line-strong);
  transform: translateY(-2px);
}
.social .ic {
  width: 18px;
  height: 18px;
}
small {
  color: var(--ink-3);
  font-size: 12.5px;
}
@media (max-width: 760px) {
  /* Clear the thumb tab bar. */
  .site-foot {
    padding: 0 16px calc(96px + env(safe-area-inset-bottom));
  }
}
</style>
