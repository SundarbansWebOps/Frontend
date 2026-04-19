<template>
  <div>
    <PageHero
      bg-image="https://images.unsplash.com/photo-1531482615713-2afd69097998?w=1920&q=80&auto=format&fit=crop"
      breadcrumb-title="Community"
      title="Tech"
      accent-title="Community"
      subtitle="Build. Code. Innovate. — where engineers and thinkers come together."
    />

    <!-- Upcoming Events -->
    <section class="section rs">
      <div class="container">
        <div class="section-header">
          <div class="section-tag tech-tag">Upcoming Events</div>
          <h2 class="section-title-xl">What's <span class="tg">Coming Up</span></h2>
          <p class="desc" style="max-width: 600px">
            Events planned ahead — mark your calendar and show up.
          </p>
        </div>

        <div class="events-grid">
          <div v-for="event in upcomingEvents" :key="event.id" class="event-card">
            <!-- Top image -->
            <div class="event-img-wrap">
              <img :src="event.image" :alt="event.title" class="event-img" />
            </div>
            <!-- Card body -->
            <div class="event-body">
              <span class="event-type-tag">{{ event.type }}</span>
              <h3 class="event-title">{{ event.title }}</h3>
              <p class="event-desc">{{ event.description }}</p>
              <div class="event-meta">
                <span>📅 {{ event.day }} {{ event.month }}</span>
                <span>🕐 {{ event.time }}</span>
                <span>📍 {{ event.venue }}</span>
              </div>
              <a
                :href="event.registerLink || '#'"
                target="_blank"
                rel="noopener noreferrer"
                class="register-btn"
              >
                Register Now
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Past Events -->
    <section class="section rs" style="background: var(--bg2)">
      <div class="container">
        <div class="section-header">
          <div class="section-tag tech-tag">Past Events</div>
          <h2 class="section-title-xl">What We've <span class="tg">Done</span></h2>
          <p class="desc" style="max-width: 600px">
            A record of everything we've built, shipped, and learned from.
          </p>
        </div>

        <div class="past-events-grid">
          <div v-for="event in pastEvents" :key="event.id" class="past-event-card">
            <div class="past-event-img-wrap">
              <img :src="event.image" class="past-event-img-blur" aria-hidden="true" />
              <img :src="event.image" :alt="event.title" class="past-event-img" />
              <div class="past-event-overlay">
                <span class="past-event-date">{{ event.date }}</span>
              </div>
            </div>
            <div class="past-event-body">
              <span class="event-type-tag">{{ event.type }}</span>
              <h3 class="past-event-title">{{ event.title }}</h3>
              <p class="past-event-desc">{{ event.description }}</p>
              <div class="past-event-stat">👥 {{ event.attendees }} attended</div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Community Team -->
    <section class="section rs">
      <div class="container">
        <div class="section-header">
          <div class="section-tag tech-tag">The Team</div>
          <h2 class="section-title-xl">People Behind the <span class="tg">Community</span></h2>
          <p class="desc" style="max-width: 600px">
            The leads and members who keep things running.
          </p>
        </div>

        <div class="team-grid">
          <div v-for="member in team" :key="member.name" class="team-card">
            <div class="team-photo-wrap">
              <img :src="member.photo" :alt="member.name" class="team-photo" />
              <div class="team-overlay">
                <h4 class="team-name">{{ member.name }}</h4>
                <span class="team-city">📍 {{ member.city }}</span>
              </div>
            </div>
            <div class="team-footer">
              <p class="team-course">{{ member.role }} · {{ member.track }}</p>
              <div class="team-socials">
                <a :href="member.email" class="social-btn" title="Email">
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>
                </a>
                <a :href="member.linkedin" class="social-btn" title="LinkedIn" target="_blank">
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor"><path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6z"/><rect x="2" y="9" width="4" height="12"/><circle cx="4" cy="4" r="2"/></svg>
                </a>
                <a :href="member.instagram" class="social-btn" title="Instagram" target="_blank">
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="2" width="20" height="20" rx="5" ry="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" y1="6.5" x2="17.51" y2="6.5"/></svg>
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import PageHero from "../components/PageHero.vue";
import { useScrollReveal } from "../composables/useAnimations.js";

import imgVibeCoding from "../assets/Community Events/Technical/Vibe Coding a SAAS application.jpeg";
import imgCodingApt from "../assets/Community Events/Technical/Coding Aptitude Challenge.jpeg";
import imgOpenMicTech from "../assets/Community Events/Technical/Open Mic.jpeg";
import imgStatAnalysis from "../assets/Community Events/Technical/Statistical Analysis Challenge.jpeg";
import imgDarkWeb from "../assets/Community Events/Technical/Dark Web Challenge.jpeg";
import imgUbuntuQuiz from "../assets/Community Events/Technical/Ubuntu Mastery Quiz.jpeg";

useScrollReveal();

const upcomingEvents = [
  {
    id: 1,
    title: "Hackathon: Build in 24hrs",
    type: "Hackathon",
    description:
      "A 24-hour build sprint where teams solve real-world problems using any stack they choose.",
    day: "22",
    month: "APR",
    time: "9:00 AM",
    venue: "Main Hall, Block A",
    image: imgVibeCoding, // Replace with actual hackathon image when available
    registerLink: "#",   // Replace with actual registration link
  },
  {
    id: 2,
    title: "AI/ML Paper Reading Club",
    type: "Workshop",
    description:
      "We break down a recent ML research paper together — no PhD required.",
    day: "28",
    month: "APR",
    time: "6:00 PM",
    venue: "Room 204, Tech Block",
    image: imgStatAnalysis, // Replace with actual event image when available
    registerLink: "#",      // Replace with actual registration link
  },
  {
    id: 3,
    title: "Open Source Contribution Drive",
    type: "Sprint",
    description:
      "Pick an issue, raise a PR, ship it. Mentors available for first-timers.",
    day: "05",
    month: "MAY",
    time: "3:00 PM",
    venue: "Computer Lab 3, Block B",
    image: imgCodingApt, // Replace with actual event image when available
    registerLink: "#",   // Replace with actual registration link
  },
];

const pastEvents = [
  {
    id: 1,
    title: "Vibe Coding a SaaS Application Workshop",
    type: "Workshop",
    description: "Introduced members to modern software development by building a SaaS product from scratch with AI-assisted development.",
    date: "11 Nov 2025 | 9:30 PM",
    attendees: "50+",
    image: imgVibeCoding,
  },
  {
    id: 2,
    title: "Coding Aptitude Challenge",
    type: "Competition",
    description: "A logic-based challenge testing analytical thinking, debugging, and problem-solving through code snippets and output prediction.",
    date: "16 Nov 2025 | 8:30 PM",
    attendees: "50+",
    image: imgCodingApt,
  },
  {
    id: 3,
    title: "Open Mic – Journey Into Tech",
    type: "Open Mic",
    description: "An inspiring session where members shared their personal experiences, challenges, and tech learning journeys in a supportive space.",
    date: "2 Dec 2025 | 8:00 PM",
    attendees: "50+",
    image: imgOpenMicTech,
  },
  {
    id: 4,
    title: "Statistical Analysis Challenge",
    type: "Challenge",
    description: "Participants worked with real-world survey data, using analytical tools to study trends, create charts, and draw logical conclusions.",
    date: "5-7 Dec 2025 | Online",
    attendees: "50+",
    image: imgStatAnalysis,
  },
  {
    id: 5,
    title: "Dark Web Fundamentals Session",
    type: "Session",
    description: "An informative workshop introducing the basics of the dark web, the Tor network, cybersecurity risks, and ethical concerns.",
    date: "24 Mar 2025 | 7:00 PM",
    attendees: "50+",
    image: imgDarkWeb,
  },
  {
    id: 6,
    title: "Ubuntu Mastery Quiz",
    type: "Quiz",
    description: "A competitive technical assessment conducted after the learning series to evaluate participants' understanding of Linux fundamentals.",
    date: "5 Mar 2026 | 8:30 PM",
    attendees: "50+",
    image: imgUbuntuQuiz,
  },
];

const team = [
  {
    name: "Arjun Mehta",
    role: "Community Lead",
    track: "Full Stack",
    city: "Delhi",
    photo: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&q=80&auto=format&fit=crop&fit=crop&crop=face",
    email: "mailto:arjun@sundarbans.in",
    linkedin: "#",
    instagram: "#",
  },
  {
    name: "Priya Sharma",
    role: "AI/ML Head",
    track: "Machine Learning",
    city: "Bengaluru",
    photo: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&q=80&auto=format&fit=crop&crop=face",
    email: "mailto:priya@sundarbans.in",
    linkedin: "#",
    instagram: "#",
  },
  {
    name: "Rohit Das",
    role: "Events Coordinator",
    track: "DevOps",
    city: "Mumbai",
    photo: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&q=80&auto=format&fit=crop&crop=face",
    email: "mailto:rohit@sundarbans.in",
    linkedin: "#",
    instagram: "#",
  },
  {
    name: "Sneha Kapoor",
    role: "Dev Track Lead",
    track: "Frontend",
    city: "Chandigarh",
    photo: "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400&q=80&auto=format&fit=crop&crop=face",
    email: "mailto:sneha@sundarbans.in",
    linkedin: "#",
    instagram: "#",
  },
];
</script>

<style scoped>
/* ── Hacker theme accent colors: #10b981 (emerald) / #0ea5e9 (sky blue) ── */

.section-header {
  margin-bottom: 2.5rem;
}

.tg {
  background: linear-gradient(135deg, #10b981, #0ea5e9);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
}

/* Tags */
.tech-tag {
  background: rgba(16, 185, 129, 0.1);
  color: #10b981;
  border-color: rgba(16, 185, 129, 0.3);
  font-family: 'Courier New', Courier, monospace;
}

.event-type-tag {
  display: inline-block;
  font-size: 0.75rem;
  font-family: 'Courier New', Courier, monospace;
  font-weight: 700;
  padding: 0.25rem 0.65rem;
  border-radius: 4px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  margin-bottom: 0.8rem;
  background: rgba(16, 185, 129, 0.1);
  color: #34d399;
  border: 1px solid rgba(16, 185, 129, 0.3);
  box-shadow: 0 0 10px rgba(16, 185, 129, 0.05);
}

/* ─── Upcoming Events — Image 1 style (matches cultural/esports pages) ─── */
.events-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 2rem;
}

.event-card {
  background: rgba(11, 17, 15, 0.8);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(16, 185, 129, 0.2);
  border-radius: 8px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  transition: transform 0.35s cubic-bezier(0.2, 0.8, 0.2, 1), box-shadow 0.35s ease;
}

.event-card:hover {
  transform: translateY(-6px);
  border-color: rgba(16, 185, 129, 0.5);
  box-shadow: 0 20px 50px rgba(16, 185, 129, 0.12), inset 0 0 15px rgba(14, 165, 233, 0.05);
}

/* Image on top */
.event-img-wrap {
  width: 100%;
  aspect-ratio: 16 / 9;
  overflow: hidden;
  flex-shrink: 0;
}

.event-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.5s ease;
}

.event-card:hover .event-img {
  transform: scale(1.05);
}

/* Card body below image */
.event-body {
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
  flex: 1;
}

.event-title {
  font-size: 1.2rem;
  font-weight: 700;
  margin: 0 0 0.5rem;
  color: #e0e0e0;
  letter-spacing: 0.02em;
  font-family: 'Courier New', Courier, monospace;
}

.event-desc {
  font-size: 0.9rem;
  color: rgba(255, 255, 255, 0.65);
  line-height: 1.6;
  margin: 0 0 1.1rem;
  flex: 1;
}

/* Date / time / venue row */
.event-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.8rem 1.2rem;
  font-size: 0.82rem;
  color: rgba(16, 185, 129, 0.85);
  font-weight: 600;
  font-family: 'Courier New', Courier, monospace;
  margin-bottom: 1.3rem;
}

/* Register Now button — amber, consistent with site-wide CTA */
.register-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.65rem 1.4rem;
  border-radius: 6px;
  background: #f59e0b;
  color: #0a0f1e;
  font-weight: 700;
  font-size: 0.9rem;
  text-decoration: underline;
  text-underline-offset: 2px;
  letter-spacing: 0.02em;
  transition: background 0.2s, transform 0.2s;
  width: fit-content;
}

.register-btn:hover {
  background: #fbbf24;
  transform: translateY(-1px);
}

/* ─── Past Events ─── */
.past-events-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 2rem;
}

.past-event-card {
  background: rgba(11, 17, 15, 0.8);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(16, 185, 129, 0.2);
  border-radius: 8px;
  overflow: hidden;
  transition: all 0.4s cubic-bezier(0.25, 0.8, 0.25, 1);
  display: flex;
  flex-direction: column;
  position: relative;
}

.past-event-card::before {
  content: '';
  position: absolute;
  top: 0; left: 0; right: 0;
  height: 2px;
  background: linear-gradient(90deg, #10b981, #0ea5e9);
  opacity: 0;
  transition: opacity 0.3s ease;
  z-index: 10;
}

.past-event-card:hover {
  transform: translateY(-6px) scale(1.01);
  box-shadow: 0 15px 40px rgba(16, 185, 129, 0.15), inset 0 0 20px rgba(14, 165, 233, 0.05);
  border-color: rgba(16, 185, 129, 0.5);
}

.past-event-card:hover::before {
  opacity: 1;
  box-shadow: 0 2px 10px #10b981;
}

.past-event-img-wrap {
  position: relative;
  width: 100%;
  aspect-ratio: 16 / 9;
  background: #050806;
  overflow: hidden;
  border-bottom: 1px solid rgba(16, 185, 129, 0.15);
}

.past-event-img-blur {
  position: absolute;
  top: -15%; left: -15%;
  width: 130%; height: 130%;
  object-fit: cover;
  filter: blur(20px) brightness(0.3) contrast(1.2);
  z-index: 0;
  transition: transform 0.5s ease;
}

.past-event-img {
  position: absolute;
  top: 0; left: 0;
  width: 100%;
  height: 100%;
  object-fit: contain;
  z-index: 1;
  padding: 0.5rem;
  transition: transform 0.5s cubic-bezier(0.25, 0.8, 0.25, 1);
}

.past-event-card:hover .past-event-img {
  transform: scale(1.04);
}

.past-event-card:hover .past-event-img-blur {
  transform: scale(1.05);
}

.past-event-overlay {
  position: absolute;
  bottom: 10px; right: 10px;
  z-index: 2;
}

.past-event-date {
  font-family: 'Courier New', Courier, monospace;
  font-size: 0.75rem;
  color: #fff;
  font-weight: 700;
  background: rgba(0, 20, 5, 0.8);
  border: 1px solid rgba(16, 185, 129, 0.4);
  padding: 0.3rem 0.6rem;
  border-radius: 4px;
  backdrop-filter: blur(4px);
  text-shadow: 0 0 5px #10b981;
  letter-spacing: 0.05em;
}

.past-event-body {
  padding: 1.5rem;
  flex: 1;
  display: flex;
  flex-direction: column;
}

.past-event-title {
  font-family: 'Courier New', Courier, monospace;
  font-size: 1.15rem;
  font-weight: 700;
  margin: 0.2rem 0 0.6rem;
  color: #e0e0e0;
  letter-spacing: 0.02em;
  transition: text-shadow 0.3s ease;
}

.past-event-card:hover .past-event-title {
  text-shadow: 0 0 8px rgba(16, 185, 129, 0.4);
  color: #fff;
}

.past-event-desc {
  font-size: 0.9rem;
  color: rgba(255, 255, 255, 0.65);
  line-height: 1.6;
  margin: 0 0 1rem;
  flex: 1;
}

.past-event-stat {
  font-family: 'Courier New', Courier, monospace;
  font-weight: 600;
  font-size: 0.85rem;
  color: rgba(16, 185, 129, 0.8);
  padding-top: 1rem;
  border-top: 1px dashed rgba(16, 185, 129, 0.2);
}

/* ─── Team ─── */
.team-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 1.5rem;
}

.team-card {
  background: #111;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 8px;
  overflow: hidden;
  transition: transform 0.2s, box-shadow 0.2s;
  font-family: 'Courier New', Courier, monospace;
}

.team-card:hover {
  transform: translateY(-4px);
  border-color: rgba(16, 185, 129, 0.3);
  box-shadow: 0 12px 32px rgba(16, 185, 129, 0.1);
}

.team-photo-wrap {
  position: relative;
  aspect-ratio: 3 / 4;
  overflow: hidden;
}

.team-photo {
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: top;
  display: block;
  transition: transform 0.4s ease;
}

.team-card:hover .team-photo {
  transform: scale(1.04);
}

.team-overlay {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 2.5rem 1rem 0.9rem;
  background: linear-gradient(to top, rgba(0,0,0,0.9) 0%, transparent 100%);
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}

.team-name {
  font-size: 1.05rem;
  font-weight: 700;
  color: #fff;
  margin: 0;
  line-height: 1.2;
}

.team-city {
  display: inline-flex;
  align-items: center;
  gap: 0.3rem;
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #050806;
  background: #10b981;
  padding: 0.2rem 0.65rem;
  border-radius: 4px;
  width: fit-content;
}

.team-footer {
  padding: 0.75rem 1rem 0.9rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
  background: #111;
  border-top: 1px solid rgba(16, 185, 129, 0.1);
}

.team-course {
  font-size: 0.75rem;
  color: rgba(255, 255, 255, 0.5);
  margin: 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.team-socials {
  display: flex;
  gap: 0.35rem;
  flex-shrink: 0;
}

.social-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 4px;
  background: rgba(255, 255, 255, 0.05);
  color: rgba(255, 255, 255, 0.4);
  text-decoration: none;
  transition: background 0.2s, color 0.2s, border-color 0.2s;
  border: 1px solid rgba(255, 255, 255, 0.08);
}

.social-btn:hover {
  background: rgba(16, 185, 129, 0.1);
  color: #10b981;
  border-color: #10b981;
}
</style>
