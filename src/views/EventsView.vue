<template>
  <div>
    <PageHero
      bg-image="https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=1920&q=80&auto=format&fit=crop"
      breadcrumb-title="Events"
      title="Events &"
      accent-title="Activities"
      subtitle="Workshops, competitions, meetups and so much more awaits you"
    />

    <!-- Featured Event -->
    <section class="section rs" style="background: var(--bg2)">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">Next Big Event</div>
          <h2 class="section-title-xl">
            Upcoming <span class="tg">Highlight</span>
          </h2>
        </div>
        <div
          class="card-base rs grid-2"
          style="
            align-items: center;
            border: 1px solid rgba(79, 142, 247, 0.3);
          ">
          <div>
            <img
              src="https://images.unsplash.com/photo-1475721027785-f74eccf877e2?w=700&q=80&auto=format&fit=crop"
              alt="AI Conference"
              style="
                width: 100%;
                border-radius: 12px;
                aspect-ratio: 16/9;
                object-fit: cover;
              " />
          </div>
          <div>
            <div class="section-tag">Featured</div>
            <h3
              style="
                font-family: Cinzel, serif;
                font-size: 1.8rem;
                font-weight: 800;
                margin: 0.75rem 0;
              ">
              Guest Lecture: AI &amp; Machine Learning
            </h3>
            <p class="desc">
              Exclusive talk by IIT Madras faculty — deep dive into the future
              of AI, research opportunities and career paths in machine
              learning.
            </p>
            <div style="margin: 1.5rem 0">
              <div id="mainEventCountdown" class="countdown-widget"></div>
            </div>
            <div
              style="
                display: flex;
                gap: 0.75rem;
                flex-wrap: wrap;
                margin-bottom: 1.25rem;
              ">
              <span style="font-size: 0.8rem; color: var(--text2)"
                >📅 This Friday, 6:00 PM – 8:00 PM</span
              >
              <span style="font-size: 0.8rem; color: var(--text2)"
                >📍 Online (Zoom)</span
              >
              <span style="font-size: 0.8rem; color: var(--text2)"
                >🎟️ Free for all members</span
              >
            </div>
            <a href="#" class="btn-hero-primary" style="display: inline-flex"
              >Register Now →</a
            >
          </div>
        </div>
      </div>
    </section>

    <!-- Upcoming Events -->
    <section class="section rs">
      <div class="container">
        <div
          style="
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 2rem;
            flex-wrap: wrap;
            gap: 1rem;
          ">
          <div>
            <div class="section-tag">What's On</div>
            <h2 class="section-title-xl" style="margin: 0">
              Upcoming <span class="tg">Events</span>
            </h2>
          </div>
          <div class="filter-tabs">
            <div
              class="ftab"
              v-for="tab in tabs"
              :key="tab"
              :class="{ active: activeTab === tab }"
              @click="activeTab = tab">
              {{ tab }}
            </div>
          </div>
        </div>
        <div class="grid-3">
          <div
            class="card-base rc"
            v-for="(ev, i) in filteredEvents"
            :key="ev.title"
            :style="`--card-delay:${(i + 1) * 0.1}s`">
            <div
              style="
                height: 160px;
                border-radius: 10px;
                overflow: hidden;
                margin-bottom: 1rem;
              ">
              <img
                :src="ev.img"
                :alt="ev.title"
                style="width: 100%; height: 100%; object-fit: cover" />
            </div>
            <div class="section-tag" :style="ev.tagStyle || ''">
              {{ ev.category }}
            </div>
            <h3
              style="
                font-family: Cinzel, serif;
                font-weight: 700;
                margin: 0.5rem 0 0.4rem;
              ">
              {{ ev.title }}
            </h3>
            <p class="desc" style="margin-bottom: 0.75rem">{{ ev.desc }}</p>
            <div
              style="
                display: flex;
                gap: 1rem;
                margin-bottom: 1rem;
                font-size: 0.8rem;
                color: var(--text2);
              ">
              <span>📅 {{ ev.date }}</span
              ><span>🕐 {{ ev.time }}</span
              ><span>📍 {{ ev.location }}</span>
            </div>
            <a
              href="#"
              class="submit-btn"
              style="font-size: 0.85rem; padding: 0.55rem 1.25rem"
              >Register Now</a
            >
          </div>
        </div>
      </div>
    </section>

<!-- Past Events -->
<section class="section rs" style="background: var(--bg2)">
  <div class="container">
    <div class="sec-hdr">
      <div class="section-tag">Memories</div>
      <h2 class="section-title-xl">Past <span class="tg">Events</span></h2>
    </div>
    <div class="grid-3">
      <div
        class="card-base rc"
        v-for="(p, i) in pastEvents"
        :key="p.title"
        :style="`--card-delay:${(i % 6) * 0.08}s`">

        <div style="height:160px; border-radius:10px; overflow:hidden; margin-bottom:1rem;">
          <img :src="p.img" :alt="p.title" style="width:100%; height:100%; object-fit:cover;" />
        </div>

        <div class="section-tag" style="opacity:0.7;">{{ p.category }}</div>

        <h3 style="font-family:Cinzel,serif; font-weight:700; margin:0.5rem 0 0.4rem;">
          {{ p.title }}
        </h3>

        <p class="desc" style="margin-bottom:0.75rem;">{{ p.desc }}</p>

        <div style="display:flex; gap:1rem; margin-bottom:1rem; font-size:0.8rem; color:var(--text2); flex-wrap:wrap;">
          <span>📅 {{ p.date }}</span>
          <span v-if="p.location">📍 {{ p.location }}</span>
        </div>

      </div>
    </div>
  </div>
</section>

    <!-- Host CTA -->
    <section
      class="cta-section rs"
      style="
        padding: 5rem 0;
        background: linear-gradient(
          135deg,
          rgba(212, 160, 23, 0.06),
          rgba(8, 7, 5, 0.95)
        );
      ">
      <div class="container">
        <div class="cta-wrap">
          <div class="section-tag light">Got an idea?</div>
          <h2 class="cta-heading">
            Host Your Own <span class="cta-acc">Event</span>
          </h2>
          <p class="cta-sub">
            Have an idea for a workshop, talk, or meetup? We support student-led
            initiatives. Submit your proposal and we'll make it happen.
          </p>
          <div class="cta-acts">
            <router-link to="/contact" class="cta-btn-p"
              >Submit Proposal →</router-link
            >
            <router-link to="/contact" class="cta-btn-o"
              >Talk to Team</router-link
            >
          </div>
        </div>
      </div>
    </section>


  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from "vue";
import PageHero from "../components/PageHero.vue";

import { useScrollReveal } from "../composables/useAnimations.js";
useScrollReveal();

const tabs = ["All", "Workshops", "Meetups", "Competitions", "Talks"];
const activeTab = ref("All");

const allEvents = [
  {
    title: "Delhi Meetup 2026",
    category: "Offline Meetup",
    tagStyle:
      "background:rgba(245,158,11,0.1);color:#F59E0B;border-color:rgba(245,158,11,0.3)",
    date: "Apr 10",
    time: "4 PM",
    location: "Delhi",
    img: "https://images.unsplash.com/photo-1587474260584-136574528ed5?w=500&q=80&auto=format&fit=crop",
    desc: "Network with Sundarbans members in Delhi — food, fun and friendships",
    type: "Meetups",
  },
  {
    title: "Chennai Meetup 2026",
    category: "Offline Meetup",
    tagStyle:
      "background:rgba(245,158,11,0.1);color:#F59E0B;border-color:rgba(245,158,11,0.3)",
    date: "Mar 25",
    time: "3 PM",
    location: "Chennai",
    img: "https://images.unsplash.com/photo-1529253355930-ddbe423a2ac7?w=500&q=80&auto=format&fit=crop",
    desc: "Connect with fellow students in Chennai — sessions, games and more",
    type: "Meetups",
  },
  {
    title: "Career in Research",
    category: "Guest Talk",
    date: "May 5",
    time: "7–9 PM",
    location: "Virtual",
    img: "https://images.unsplash.com/photo-1475721027785-f74eccf877e2?w=500&q=80&auto=format&fit=crop",
    desc: "PhD scholars discuss research life, opportunities and how to get started",
    type: "Talks",
  },
];

const filteredEvents = computed(() =>
  activeTab.value === "All"
    ? allEvents
    : allEvents.filter((e) => e.type === activeTab.value),
);

const pastEvents = [
  {
    title: "Shakti Series — Episode 1",
    category: "Empowerment",
    desc: "Inaugural session of the empowerment series celebrating strength, resilience and community spirit",
    date: "October 2025",
    location: "Virtual",
    img: "https://images.unsplash.com/photo-1523580494863-6f3031224c94?w=500&q=80&auto=format&fit=crop",
  },
  {
    title: "Navrang 2.0 — Celebrate Navratri",
    category: "Cultural",
    desc: "Nine nights of vibrant cultural celebration featuring dance, music and festive traditions",
    date: "September 2025",
    location: "Virtual",
    img: "https://images.unsplash.com/photo-1567591370762-b3db2e82eb3e?w=500&q=80&auto=format&fit=crop",
  },
  {
    title: "Pre-Independence Day Session",
    category: "Guest Talk",
    desc: "Inspiring talk by Capt. Albert Louis on patriotism, sacrifice and the journey of our nation",
    date: "August 2025",
    location: "Virtual",
    img: "https://images.unsplash.com/photo-1532375810709-75b1da00537c?w=500&q=80&auto=format&fit=crop",
  },
  {
    title: "Paradox Champions League — Football Faceoff",
    category: "Sports",
    desc: "High-energy football tournament at Paradox'25 — strategy, skill and spirit on the field",
    date: "May 2025",
    location: "Offline",
    img: "public/assets/pastevent/2025-05-15_12-44-00_UTC.jpg",
  },
  {
    title: "Ghost in the Firewall",
    category: "Technical",
    desc: "Capture-the-flag style cybersecurity challenge at Paradox'25 — decode, defend and uncover the rogue AI",
    date: "May 2025",
    location: "Offline",
    img: "public/assets/pastevent/2025-05-14_08-34-35_UTC.jpg",
  },
  {
    title: "Hack Eclipse — 24-hour Hackathon",
    category: "Hackathon",
    desc: "Round-the-clock coding marathon where teams built innovative solutions across environment, healthcare, fintech and more",
    date: "May 2025",
    location: "Virtual",
    img: "public/assets/pastevent/2025-05-09_06-25-51_UTC.jpg",
  },
  {
    title: "Paradox Badminton League 2.0",
    category: "Sports",
    desc: "Inter-house badminton tournament with intense rallies and fierce competition across divisions",
    date: "May 2025",
    location: "Virtual",
    img: "https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=500&q=80&auto=format&fit=crop",
  },
  {
    title: "IPL Auction Showdown",
    category: "E-Sports",
    desc: "Strategic mock IPL auction where participants built dream teams with limited budgets",
    date: "May 2025",
    location: "Virtual",
    img: "https://images.unsplash.com/photo-1540747913346-19212a4f3b1e?w=500&q=80&auto=format&fit=crop",
  },
  {
    title: "FrameQuest — Photography Contest",
    category: "Cultural",
    desc: "Three-round photography contest with a ₹6000 prize pool — portraits that tell a lasting story",
    date: "February 2025",
    location: "Virtual",
    img: "public/assets/pastevent/2025-02-10_10-25-33_UTC.jpg",
  },
  {
    title: "Into the Shadows — Special Forces Talk",
    category: "Guest Talk",
    desc: "Gripping session with Maj. Sushant Singh on courage, resilience and life as a Special Forces operative",
    date: "February 2025",
    location: "Virtual",
    img: "public/assets/pastevent/2025-02-13_02-15-54_UTC.jpg",
  },
  {
    title: "Python Odyssey",
    category: "Workshop",
    desc: "7-episode hands-on Python journey covering fundamentals, OOP and Flask web development",
    date: "February 2025",
    location: "Virtual",
    img: "public/assets/pastevent/2025-02-06_00-30-44_UTC.jpg",
  },
  {
    title: "Mahabharata — Science Meets History",
    category: "Guest Talk",
    desc: "Nilesh Oak takes the audience through scientific dating of the Mahabharata and the mysteries of ancient India",
    date: "January 2025",
    location: "Virtual",
    img: "public/assets/pastevent/2025-01-27_08-57-27_UTC.jpg",
  },
  {
    title: "Frames of Freedom — Republic Day Photography",
    category: "Cultural",
    desc: "Photography contest celebrating patriotism and India's culture — themes of Tiranga, Unsung Heroes and India in Motion",
    date: "January 2025",
    location: "Virtual",
    img: "public/assets/pastevent/2025-01-25_01-20-01_UTC.jpg",
  },
  {
    title: "Navodaya — Voices of Power with Smriti Irani",
    category: "Guest Talk",
    desc: "Grand finale of Voices of Power featuring Smriti Irani on leadership, empowerment and women shaping the future",
    date: "December 2024",
    location: "Virtual",
    img: "public/assets/pastevent/2024-12-05_11-31-48_UTC.jpg",
  },
  {
    title: "Dinkar Ki Pratiksha — Open Mic",
    category: "Cultural",
    desc: "Collaborative open mic celebrating the 116th birth anniversary of poet Ramdhari Singh Dinkar — poetry across all languages",
    date: "September 2024",
    location: "Virtual",
    img: "public/assets/pastevent/2024-09-23_06-54-49_UTC.jpg",
  },
  {
    title: "Sundarbans BS Talent Show",
    category: "Cultural",
    desc: "Platform for IITM BS students to showcase their extraordinary talents to the wider community",
    date: "July 2024",
    location: "Virtual",
    img: "public/assets/pastevent/2024-07-16_11-41-17_UTC.jpg",
  },
  {
    title: "How to Improve Concentration — Swami Mukundanand",
    category: "Guest Talk",
    desc: "Enlightening session by IIT-IIM alumnus and spiritual leader Swami Mukundanand Ji on focus and Vedic wisdom",
    date: "March 2023",
    location: "Virtual",
    img: "public/assets/pastevent/2023-03-22_09-54-19_UTC.jpg",
  },
];
  
// Countdown
let cdTimer = null;
function updateCd() {
  const el = document.getElementById("mainEventCountdown");
  if (!el) return;
  const now = new Date();
  const fri = new Date();
  fri.setDate(now.getDate() + ((5 - now.getDay() + 7) % 7) || 7);
  fri.setHours(18, 0, 0, 0);
  const diff = fri - now;
  if (diff <= 0) {
    el.innerHTML = '<span class="cd-over">Event Started!</span>';
    return;
  }
  const d = Math.floor(diff / 86400000),
    h = Math.floor((diff % 86400000) / 3600000);
  const m = Math.floor((diff % 3600000) / 60000),
    s = Math.floor((diff % 60000) / 1000);
  el.innerHTML = `<div class="cd-unit"><span class="cd-num">${String(d).padStart(2, "0")}</span><span class="cd-label">days</span></div><div class="cd-sep">:</div><div class="cd-unit"><span class="cd-num">${String(h).padStart(2, "0")}</span><span class="cd-label">hrs</span></div><div class="cd-sep">:</div><div class="cd-unit"><span class="cd-num">${String(m).padStart(2, "0")}</span><span class="cd-label">min</span></div><div class="cd-sep">:</div><div class="cd-unit"><span class="cd-num">${String(s).padStart(2, "0")}</span><span class="cd-label">sec</span></div>`;
}
onMounted(() => {
  updateCd();
  cdTimer = setInterval(updateCd, 1000);
});
onUnmounted(() => clearInterval(cdTimer));
</script>
