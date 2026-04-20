<template>
  <div>

    <!-- HERO -->
    <section class="page-hero">
      <div class="page-hero-bg">
        <img
          src="https://media.licdn.com/dms/image/v2/D4D12AQGOJzss-fon-Q/article-cover_image-shrink_720_1280/article-cover_image-shrink_720_1280/0/1709102339863?e=2147483647&v=beta&t=6kQv2j3jMNyrmUzZEG4uokdgkDC_tpWg7ZALaCcw0BM"
          alt="Teams">
        <div class="page-hero-overlay"></div>
      </div>
      <div class="container page-hero-content">
        <div class="breadcrumb-nav"><a href="index.html">Home</a><span>/</span><span>Teams</span></div>
        <h1>Our <span class="tg">Teams</span></h1>
        <p>Meet the passionate people who drive Sundarbans House forward</p>
      </div>
    </section>

    <!-- ══ UPPER HOUSE COUNCIL ══ -->
    <section class="section rs">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">Leadership</div>
          <h2 class="section-title-xl">Upper House <span class="tg">Council</span></h2>
          <p class="sec-sub">The core leadership driving Sundarbans House's vision and operations</p>
        </div>
        <div class="tm-lead-grid">
          <TeamCard
            v-for="(member, i) in teamsData.upperHouseCouncil"
            :key="i"
            :member="member"
            :delay="(i + 1) * 0.1"
          />
        </div>
      </div>
    </section>

    <!-- ══ WEBOPS TEAM ══ -->
    <section class="section rs" style="background:var(--bg2)">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">Tech</div>
          <h2 class="section-title-xl">WebOps <span class="tg">Team</span></h2>
          <p class="sec-sub">Building and maintaining the digital presence of Sundarbans House</p>
        </div>
        <div class="tm-webops-grid">
          <TeamCard
            v-for="(member, i) in teamsData.webOpsTeam"
            :key="i"
            :member="member"
            :delay="(i + 1) * 0.1"
          />
        </div>
      </div>
    </section>

    <!-- ══ LOWER HOUSE COUNCIL ══ -->
    <section class="section rs">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">Regional</div>
          <h2 class="section-title-xl">Lower House <span class="tg">Council</span></h2>
          <p class="sec-sub">Regional coordinators connecting students across India</p>
        </div>
        <div class="tm-lower-grid">
          <TeamCard
            v-for="(member, i) in teamsData.lowerHouseCouncil"
            :key="i"
            :member="member"
            :delay="(i + 1) * 0.1"
          />
        </div>
      </div>
    </section>

    <!-- ══ COMMUNITY HEADS ══ -->
    <section class="section rs" style="background:var(--bg2)">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">Community Leads</div>
          <h2 class="section-title-xl">Community <span class="tg">Heads</span></h2>
          <p class="sec-sub">Department leads powering every initiative inside Sundarbans House</p>
        </div>
        <div class="tm-comm-grid">
          <TeamCard
            v-for="(member, i) in teamsData.communityHeads"
            :key="i"
            :member="member"
            :delay="(i + 1) * 0.1"
          />
        </div>
      </div>
    </section>

  </div>
</template>

<script setup>
import { useScrollReveal } from "../composables/useAnimations.js";
import teamsData from "@/data/teams.json";
import TeamCard from "@/components/TeamCard.vue";

useScrollReveal();
</script>

<style scoped>
/* ── GRIDS ─────────────────────────────────────────── */
.tm-lead-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1.5rem;
}

.tm-webops-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1.25rem;
}

.tm-lower-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1.25rem;
}

.tm-comm-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1.25rem;
}

/* ── RESPONSIVE ────────────────────────────────────── */
@media (max-width: 1024px) {
  .tm-lower-grid,
  .tm-comm-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media (max-width: 768px) {
  .tm-lead-grid,
  .tm-webops-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .tm-lower-grid,
  .tm-comm-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 480px) {
  .tm-lead-grid,
  .tm-webops-grid,
  .tm-lower-grid,
  .tm-comm-grid {
    grid-template-columns: 1fr 1fr;
  }
}
</style>
