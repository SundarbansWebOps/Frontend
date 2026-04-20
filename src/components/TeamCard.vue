<template>
  <div class="tm-card rc" :style="`--card-delay:${delay}s`">
    <div class="tm-photo-wrap">
      <img
        :src="photoSrc"
        :alt="member.name"
        @error="onImgError"
      >
      <div class="tm-no-photo" style="display:none">{{ member.initials }}</div>
      <div class="tm-overlay">
        <div class="tm-name">{{ member.name }}</div>
        <div class="tm-role">{{ member.role }}</div>
      </div>
    </div>
    <div class="tm-info">
      <div class="tm-level">{{ member.level }}</div>
      <div class="tm-socials">

        <!-- Email -->
        <a v-if="member.email" :href="`mailto:${member.email}`" class="tm-soc" title="Email">
          <EmailIcon />
        </a>
        <span v-else class="tm-soc tm-soc-disabled" title="Email not available">
          <EmailIcon /><span class="tm-tip">Email</span>
        </span>

        <!-- LinkedIn -->
        <a v-if="member.linkedin" :href="member.linkedin" target="_blank" rel="noopener" class="tm-soc li" title="LinkedIn">
          <LinkedInIcon />
        </a>
        <span v-else class="tm-soc tm-soc-disabled" title="LinkedIn not available">
          <LinkedInIcon /><span class="tm-tip">LinkedIn</span>
        </span>

        <!-- Instagram -->
        <a v-if="member.instagram" :href="member.instagram" target="_blank" rel="noopener" class="tm-soc ig" title="Instagram">
          <InstagramIcon />
        </a>
        <span v-else class="tm-soc tm-soc-disabled" title="Instagram not available">
          <InstagramIcon /><span class="tm-tip">Instagram</span>
        </span>

      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from "vue";

// SVG icon sub-components defined inline to avoid extra files
import EmailIcon from "@/components/icons/EmailIcon.vue";
import LinkedInIcon from "@/components/icons/LinkedInIcon.vue";
import InstagramIcon from "@/components/icons/InstagramIcon.vue";

const props = defineProps({
  member: {
    type: Object,
    required: true
  },
  delay: {
    type: Number,
    default: 0.1
  }
});

// Dynamically resolve the image path from assets/teams/
// Vite requires explicit glob or dynamic import for assets
const teamImages = import.meta.glob("@/assets/teams/*", { eager: true, import: "default" });

const photoSrc = computed(() => {
  const key = `/src/assets/teams/${props.member.photo}`;
  return teamImages[key] ?? "";
});

function onImgError(event) {
  event.target.style.display = "none";
  event.target.nextElementSibling.style.display = "flex";
}
</script>

<style scoped>
/* ── MEMBER CARD ─────────────────────────────────────── */
.tm-card {
  position: relative;
  border-radius: 20px;
  overflow: hidden;
  background: var(--surface);
  border: 1px solid var(--border);
  transition: transform 0.35s cubic-bezier(0.2, 0, 0, 1), box-shadow 0.35s ease, border-color 0.3s;
}

.tm-card:hover {
  transform: translateY(-8px);
  border-color: rgba(212, 160, 23, 0.4);
  box-shadow: 0 32px 64px rgba(0, 0, 0, 0.5), 0 0 0 1px rgba(212, 160, 23, 0.15);
}

.tm-photo-wrap {
  position: relative;
  width: 100%;
  aspect-ratio: 3/4;
  overflow: hidden;
  background: rgba(212, 160, 23, 0.05);
}

.tm-photo-wrap img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: top center;
  transition: transform 0.5s ease, filter 0.4s ease;
  filter: grayscale(15%);
}

.tm-card:hover .tm-photo-wrap img {
  transform: scale(1.06);
  filter: grayscale(0%);
}

.tm-photo-wrap::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(to top, rgba(8, 7, 5, 0.95) 0%, rgba(8, 7, 5, 0.35) 45%, transparent 70%);
  pointer-events: none;
}

.tm-overlay {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 1.25rem 1.25rem 1rem;
  z-index: 2;
}

.tm-name {
  font-family: 'Syne', sans-serif;
  font-weight: 700;
  font-size: 1rem;
  color: #F5EDD0;
  margin-bottom: 0.3rem;
  line-height: 1.2;
}

.tm-role {
  display: inline-flex;
  font-size: 0.68rem;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: #D4A017;
  background: rgba(212, 160, 23, 0.12);
  border: 1px solid rgba(212, 160, 23, 0.3);
  padding: 0.2rem 0.6rem;
  border-radius: 99px;
}

.tm-info {
  padding: 0.85rem 1.25rem 1rem;
}

.tm-level {
  font-size: 0.75rem;
  color: var(--text3);
  margin-bottom: 0.75rem;
}

.tm-socials {
  display: flex;
  gap: 0.45rem;
}

.tm-soc {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  border-radius: 8px;
  border: 1px solid var(--border);
  background: none;
  color: var(--text3);
  text-decoration: none;
  transition: all 0.2s;
}

.tm-soc:hover {
  background: rgba(212, 160, 23, 0.1);
  border-color: rgba(212, 160, 23, 0.35);
  color: var(--accent);
  transform: translateY(-2px);
}

.tm-soc.li:hover {
  background: rgba(10, 102, 194, 0.15);
  border-color: rgba(10, 102, 194, 0.4);
  color: #0A66C2;
}

.tm-soc.ig:hover {
  background: rgba(220, 39, 67, 0.12);
  border-color: rgba(220, 39, 67, 0.35);
  color: #e6683c;
}

/* ── DISABLED SOCIAL BUTTONS ───────────────────────── */
.tm-soc-disabled {
  opacity: 0.25;
  cursor: default;
  position: relative;
}

.tm-soc-disabled:hover {
  background: none !important;
  border-color: var(--border) !important;
  color: var(--text3) !important;
  transform: none !important;
}

.tm-tip {
  position: absolute;
  bottom: calc(100% + 5px);
  left: 50%;
  transform: translateX(-50%);
  background: #1a1500;
  border: 1px solid rgba(212, 160, 23, 0.2);
  color: rgba(255, 255, 255, 0.6);
  font-size: 0.6rem;
  white-space: nowrap;
  padding: 0.15rem 0.4rem;
  border-radius: 4px;
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.15s;
}

.tm-soc-disabled:hover .tm-tip {
  opacity: 1;
}

/* ── NO PHOTO FALLBACK ─────────────────────────────── */
.tm-no-photo {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: 'Syne', sans-serif;
  font-size: 2.5rem;
  font-weight: 800;
  color: rgba(212, 160, 23, 0.25);
  background: linear-gradient(135deg, rgba(212, 160, 23, 0.04), rgba(212, 160, 23, 0.08));
}

[data-theme="light"] .tm-photo-wrap::after {
  background: linear-gradient(to top, rgba(5, 5, 5, 0.88) 0%, rgba(5, 5, 5, 0.3) 45%, transparent 70%);
}

[data-theme="light"] .tm-card {
  background: #fff;
  border-color: rgba(0, 0, 0, 0.08);
}
</style>
