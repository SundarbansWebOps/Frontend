<template>
  <div>
    <PageHero
      bg-image="https://images.unsplash.com/photo-1491438590914-bc09fcaaf77a?w=1920&q=80&auto=format&fit=crop"
      breadcrumb-title="Community"
      title="Cultural"
      accent-title="Community"
      subtitle="Art. Music. Culture. — celebrating what makes us human."
    />

    <!-- Upcoming Events -->
    <section class="section rs">
      <div class="container">
        <div class="section-header">
          <div class="section-tag cultural-tag">Upcoming Events</div>
          <h2 class="section-title-xl">What's <span class="tg-cultural">Coming Up</span></h2>
          <p class="desc" style="max-width: 600px">Events planned ahead — mark your calendar and show up.</p>
        </div>
        <div class="events-grid">
          <div v-for="event in upcomingEvents" :key="event.id" class="event-card">
            <div class="event-img-wrap">
              <img :src="event.image" :alt="event.title" class="event-img" />
            </div>
            <div class="event-body">
              <span class="event-type-tag">{{ event.type }}</span>
              <h3 class="event-title">{{ event.title }}</h3>
              <p class="event-desc">{{ event.description }}</p>
              <div class="event-meta">
                <span>📅 {{ event.day }} {{ event.month }}</span>
                <span>🕐 {{ event.time }}</span>
                <span>📍 {{ event.venue }}</span>
              </div>
              <a :href="event.registerLink || '#'" target="_blank" rel="noopener noreferrer" class="register-btn">Register Now</a>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Past Events -->
    <section class="section rs" style="background: var(--bg2)">
      <div class="container">
        <div class="section-header">
          <div class="section-tag cultural-tag">Past Events</div>
          <h2 class="section-title-xl">What We've <span class="tg-cultural">Done</span></h2>
          <p class="desc" style="max-width: 600px">A record of everything we've celebrated, performed, and created.</p>
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

    <!-- Winners -->
    <section class="section rs">
      <div class="container">
        <div class="section-header">
          <div class="section-tag cultural-tag">Hall of Fame</div>
          <h2 class="section-title-xl">Event <span class="tg-cultural">Winners</span></h2>
          <p class="desc" style="max-width: 600px">The voices, performers, and creators who stood out.</p>
        </div>
        <div class="winners-grid">
          <div v-for="event in eventWinners" :key="event.id" class="winner-card">
            <div class="winner-card-header">
              <span class="winner-event-tag">{{ event.type }}</span>
              <h3 class="winner-event-title">{{ event.title }}</h3>
            </div>
            <ul class="winners-list">
              <li v-for="(winner, index) in event.winners" :key="winner.name" class="winner-row">
                <span class="winner-rank">{{ index + 1 }}</span>
                <div class="winner-info">
                  <span class="winner-name">{{ winner.name }}</span>
                  <div class="winner-meta-row">
                    <span class="winner-house">🏠 {{ winner.house }}</span>
                    <span class="winner-email">{{ winner.email }}</span>
                  </div>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </section>

    <!-- Community Team -->
    <section class="section rs" style="background: var(--bg2)">
      <div class="container">
        <div class="section-header">
          <div class="section-tag cultural-tag">The Team</div>
          <h2 class="section-title-xl">People Behind the <span class="tg-cultural">Community</span></h2>
          <p class="desc" style="max-width: 600px">The leads and members who keep things running.</p>
        </div>
        <div class="team-grid">
          <div v-for="member in team" :key="member.name" class="team-card">
            <div class="team-photo-wrap">
              <img :src="member.photo" :alt="member.name" class="team-photo" />
              <div class="team-overlay">
                <h4 class="team-name">{{ member.name }}</h4>
                <span class="team-role-badge">{{ member.role }}</span>
              </div>
            </div>
            <div class="team-footer">
              <p class="team-course">{{ member.Level }} · {{ member.track }}</p>
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

import imgShivShakti from "../assets/Community Events/Cultural/Shiv Shakti.jpeg";
import imgPhotography from "../assets/Community Events/Cultural/Photography Workshop.jpeg";
import imgDance from "../assets/Community Events/Cultural/Dance Workshop.jpeg";
import img3AmThoughts from "../assets/Community Events/Cultural/3 AM thoughts.jpeg";
import imgOpenMic from "../assets/Community Events/Cultural/Open Mic.jpeg";

import imgUtsav from "../assets/Community Events/Cultural/Shiv Shakti.jpeg";
import imgPhotoWalk from "../assets/Community Events/Cultural/Photography Workshop.jpeg";
import imgOpenMicUpcoming from "../assets/Community Events/Cultural/Open Mic.jpeg";

import imgLiza from "../assets/teams/Liza.jpg";
import imgMegha from "../assets/teams/Megha.jpg";
import imgKaviya from "../assets/teams/R.Kaviya Kaviarasi.jpg";

useScrollReveal();

const upcomingEvents = [
  {
    id: 1, title: "Sundarban Utsav — Cultural Night", type: "Performance",
    description: "An evening of music, dance, and spoken word from across the country.",
    day: "25", month: "APR", time: "7:00 PM", venue: "Open Amphitheatre",
    image: imgUtsav, registerLink: "#",
  },
  {
    id: 2, title: "Photography Walk", type: "Workshop",
    description: "A guided campus walk focused on composition, light, and storytelling through a lens.",
    day: "30", month: "APR", time: "6:30 AM", venue: "Main Gate, Campus",
    image: imgPhotoWalk, registerLink: "#",
  },
  {
    id: 3, title: "Spoken Word Open Mic", type: "Performance",
    description: "A stage for poetry, stories, and raw expression. All languages welcome.",
    day: "08", month: "MAY", time: "6:00 PM", venue: "Courtyard, Block D",
    image: imgOpenMicUpcoming, registerLink: "#",
  },
];

const pastEvents = [
  {
    id: 1, title: "Shiv–Shakti: The Eternal Union", type: "Event",
    description: "Shiv–Shakti: The Eternal Union was a spiritually enriching cultural evening that beautifully celebrated devotion, art, and timeless values. The event brought members together to experience the divine essence of Shiva and Shakti through soulful shlokas, graceful dance performances, devotional expressions, and heartfelt reflections. It created a peaceful and uplifting atmosphere, allowing participants to reconnect with spirituality, culture, and inner calm while celebrating the deeper meaning of togetherness and faith.",
    date: "15 Feb 2026 | 8:00 PM", attendees: "50+", image: imgShivShakti,
  },
  {
    id: 2, title: "Photography Workshop with Manish Kumar", type: "Workshop",
    description: "The Photography Workshop was an inspiring and interactive learning session designed for members who wanted to explore the art of visual storytelling. Led by Manish Kumar, a talented creative professional skilled in photography, design, and digital art, the workshop focused on composition, lighting, framing, and creative perspective. Participants gained practical insights into how to transform ordinary moments into meaningful visuals. The session encouraged creativity, curiosity, and helped members develop a stronger artistic eye.",
    date: "19 Feb 2026 | 7:00 PM", attendees: "50+", image: imgPhotography,
  },
  {
    id: 3, title: "Dance Workshop with Aditri Bordoloi", type: "Workshop",
    description: "The Dance Workshop was a vibrant and energetic session that brought rhythm, movement, and excitement to the Sundarbans community. Led by Aditri Bordoloi, the workshop introduced participants to a mix of Bollywood, freestyle, and classical dance styles in a beginner-friendly format. Members learned new moves, explored different forms of expression, and enjoyed an engaging experience filled with fun and positivity. The event successfully encouraged confidence, creativity, and active participation.",
    date: "26 Feb 2026 | 7:30 PM", attendees: "50+", image: imgDance,
  },
  {
    id: 4, title: "3 AM Thoughts", type: "Reflection Event",
    description: "3 AM Thoughts was a unique and heartfelt community initiative that provided members with a safe and comforting space to express their late-night feelings, thoughts, dreams, and emotions. Through written reflections and anonymous submissions, participants shared personal stories, fears, hopes, and moments of vulnerability. The event fostered emotional openness, connection, and understanding within the community, making it one of the most meaningful and relatable cultural initiatives.",
    date: "Online Submission", attendees: "50+", image: img3AmThoughts,
  },
  {
    id: 5, title: "Open Mic Night", type: "Open Mic",
    description: "Open Mic Night was a lively and expressive cultural evening that gave members the chance to showcase their hidden talents and creativity. From poetry and shayari to singing, storytelling, and fun performances, the event created a warm and supportive stage for everyone to share their voice. It encouraged confidence, self-expression, and community bonding while making the evening memorable with laughter, emotions, and inspiring performances.",
    date: "26 Mar 2026 | 8:00 PM", attendees: "50+", image: imgOpenMic,
  },
];

// Winners — replace house names and emails when available
const eventWinners = [
  {
    id: 1, title: "Debate", type: "Competition",
    winners: [
      { name: "Srija Chawla",  house: "Sundarbans House", email: "winner@sundarbans.in" }, // Replace
      { name: "Sabal Sneh",    house: "Sundarbans House", email: "winner@sundarbans.in" }, // Replace
    ],
  },
  {
    id: 2, title: "Sur Taal", type: "Music Event",
    winners: [
      { name: "S. Padmashree", house: "Sundarbans House", email: "winner@sundarbans.in" }, // Replace
      { name: "Yash Sharma",   house: "Sundarbans House", email: "winner@sundarbans.in" }, // Replace
      { name: "Megha Sharma",  house: "Sundarbans House", email: "winner@sundarbans.in" }, // Replace
    ],
  },
  {
    id: 3, title: "Poetry", type: "Creative Writing",
    winners: [
      { name: "Aditya Kr. Chaubey", house: "Sundarbans House", email: "winner@sundarbans.in" }, // Replace
      { name: "Megha Sharma",       house: "Sundarbans House", email: "winner@sundarbans.in" }, // Replace
    ],
  },
];

const team = [
  {
    name: "Liza Rathi", role: "Co-head", track: "Design & Illustration", Level: "Foundation Data Science",
    photo: imgLiza, email: "mailto:24f3001980@ds.study.iitm.ac.in",
    linkedin: "https://www.linkedin.com/in/liza-rathi-63374034b?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app",
    instagram: "https://www.instagram.com/rathi_liza?igsh=MWZvcDN3ZDF3bzcyaw==",
  },
  {
    name: "Megha Sharma", role: "Event Coordinator", track: "Performing Arts", Level: "Foundation Data Science",
    photo: imgMegha, email: "mailto:25f2000267@ds.study.iitm.ac.in",
    linkedin: "https://www.linkedin.com/in/megha-sharma-9489a3357/", instagram: "#",
  },
  {
    name: "R Kavya Kaviarasi", role: "Event Coordinator", track: "Music & Sound", Level: "Foundation Data Science",
    photo: imgKaviya, email: "mailto:24f3003690@ds.study.iitm.ac.in",
    linkedin: "https://www.linkedin.com/in/kaviya-kaviarasi-b44178328?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app",
    instagram: "#",
  },
];
</script>

<style scoped>
/* ─── Accent color: #f59e0b (amber) ─── */

.section-header { margin-bottom: 2.5rem; }

.tg-cultural {
  background: linear-gradient(135deg, #f59e0b, #ef4444);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
}

.cultural-tag { background: rgba(245, 158, 11, 0.1); color: #f59e0b; border-color: rgba(245, 158, 11, 0.3); }

.event-type-tag {
  display: inline-flex; align-items: center; font-size: 0.75rem; font-weight: 600;
  padding: 0.3rem 0.9rem; border-radius: 999px; text-transform: uppercase; letter-spacing: 0.1em;
  margin-bottom: 0.8rem;
  background: linear-gradient(135deg, rgba(245, 158, 11, 0.15), rgba(239, 68, 68, 0.1));
  color: #fbbf24; border: 1px solid rgba(245, 158, 11, 0.25);
}

/* ─── Upcoming Events ─── */
.events-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 2rem; }

.event-card {
  background: rgba(20, 15, 10, 0.5); border: 1px solid rgba(245, 158, 11, 0.15);
  border-radius: 20px; overflow: hidden; display: flex; flex-direction: column;
  transition: transform 0.35s cubic-bezier(0.2, 0.8, 0.2, 1), box-shadow 0.35s ease;
}

.event-card:hover {
  transform: translateY(-6px);
  box-shadow: 0 20px 50px rgba(245, 158, 11, 0.12), 0 6px 16px rgba(239, 68, 68, 0.08);
  border-color: rgba(245, 158, 11, 0.3);
}

.event-img-wrap { width: 100%; aspect-ratio: 16 / 9; overflow: hidden; flex-shrink: 0; }
.event-img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.5s ease; }
.event-card:hover .event-img { transform: scale(1.05); }

.event-body { padding: 1.5rem; display: flex; flex-direction: column; flex: 1; }
.event-title { font-size: 1.2rem; font-weight: 700; margin: 0 0 0.5rem; color: #fff; letter-spacing: 0.01em; }
.event-desc { font-size: 0.9rem; color: rgba(255, 255, 255, 0.65); line-height: 1.6; margin: 0 0 1.1rem; flex: 1; }
.event-meta { display: flex; flex-wrap: wrap; gap: 0.8rem 1.2rem; font-size: 0.82rem; color: rgba(245, 158, 11, 0.85); font-weight: 500; margin-bottom: 1.3rem; }

.register-btn {
  display: inline-flex; align-items: center; justify-content: center;
  padding: 0.65rem 1.4rem; border-radius: 10px; background: #f59e0b; color: #0a0f1e;
  font-weight: 700; font-size: 0.9rem; text-decoration: underline; text-underline-offset: 2px;
  letter-spacing: 0.02em; transition: background 0.2s, transform 0.2s; width: fit-content;
}
.register-btn:hover { background: #fbbf24; transform: translateY(-1px); }

/* ─── Past Events ─── */
.past-events-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 2rem; }

.past-event-card {
  background: rgba(20, 15, 10, 0.4); backdrop-filter: blur(12px);
  border: 1px solid rgba(245, 158, 11, 0.15); border-radius: 24px; overflow: hidden;
  transition: all 0.4s cubic-bezier(0.2, 0.8, 0.2, 1); display: flex; flex-direction: column;
}

.past-event-card:hover {
  transform: translateY(-8px); border-color: rgba(239, 68, 68, 0.3);
  box-shadow: 0 20px 50px rgba(245, 158, 11, 0.15), 0 8px 20px rgba(239, 68, 68, 0.1);
}

.past-event-img-wrap { position: relative; width: 100%; aspect-ratio: 4 / 3; background: #050505; overflow: hidden; }

.past-event-img-blur {
  position: absolute; top: -20%; left: -20%; width: 140%; height: 140%;
  object-fit: cover; filter: blur(25px) brightness(0.4) saturate(1.2); z-index: 0;
  transition: transform 0.6s ease, filter 0.6s ease;
}
.past-event-card:hover .past-event-img-blur { transform: scale(1.1); filter: blur(15px) brightness(0.5) saturate(1.4); }

.past-event-img {
  position: absolute; top: 0; left: 0; width: 100%; height: 100%;
  object-fit: contain; z-index: 1; transition: transform 0.6s cubic-bezier(0.2, 0.8, 0.2, 1); padding: 0.5rem;
}
.past-event-card:hover .past-event-img { transform: scale(1.05); }

.past-event-overlay { position: absolute; bottom: 12px; right: 12px; z-index: 2; }
.past-event-date {
  font-size: 0.8rem; color: #fff; font-weight: 500; letter-spacing: 0.05em;
  background: rgba(0, 0, 0, 0.4); backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.15); padding: 0.4rem 0.8rem; border-radius: 20px;
}

.past-event-body { padding: 1.8rem; flex: 1; display: flex; flex-direction: column; }
.past-event-title { font-size: 1.25rem; font-weight: 600; margin: 0.2rem 0 0.8rem; color: #fff; letter-spacing: 0.01em; }
.past-event-desc { font-size: 0.95rem; color: rgba(255, 255, 255, 0.7); line-height: 1.6; margin: 0 0 1.2rem; flex: 1; }
.past-event-stat { font-size: 0.85rem; color: rgba(245, 158, 11, 0.8); padding-top: 1rem; border-top: 1px solid rgba(245, 158, 11, 0.15); font-weight: 500; }

/* ─── Winners Section ─── */
.winners-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 1.5rem; }

.winner-card {
  position: relative;
  background: rgba(20, 15, 10, 0.5); backdrop-filter: blur(12px);
  border: 1px solid rgba(245, 158, 11, 0.2); border-radius: 20px;
  padding: 1.5rem 1.5rem 1.5rem 1.8rem; overflow: hidden;
  transition: border-color 0.3s ease, box-shadow 0.3s ease;
}

.winner-card::before {
  content: ''; position: absolute; left: 0; top: 0; bottom: 0; width: 4px;
  background: linear-gradient(180deg, #f59e0b, #ef4444);
  box-shadow: 0 0 10px rgba(245, 158, 11, 0.5); border-radius: 20px 0 0 20px;
}

.winner-card:hover {
  border-color: rgba(245, 158, 11, 0.4);
  box-shadow: 0 10px 30px rgba(245, 158, 11, 0.1), 0 4px 12px rgba(239, 68, 68, 0.06);
}

.winner-card-header { margin-bottom: 1.2rem; }

.winner-event-tag {
  display: inline-flex; align-items: center; font-size: 0.72rem; font-weight: 600;
  padding: 0.2rem 0.7rem; border-radius: 999px; text-transform: uppercase; letter-spacing: 0.1em;
  margin-bottom: 0.6rem;
  background: linear-gradient(135deg, rgba(245, 158, 11, 0.15), rgba(239, 68, 68, 0.1));
  color: #fbbf24; border: 1px solid rgba(245, 158, 11, 0.25);
}

.winner-event-title { font-size: 1.1rem; font-weight: 700; color: #fff; margin: 0; letter-spacing: 0.01em; }

.winners-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 0.6rem; }

.winner-row {
  display: flex; align-items: center; gap: 0.9rem;
  padding: 0.6rem 0.9rem; border-radius: 12px;
  background: rgba(245, 158, 11, 0.05); border: 1px solid rgba(245, 158, 11, 0.1);
  transition: background 0.2s;
}
.winner-row:hover { background: rgba(245, 158, 11, 0.1); }

/* Rank badges — gold / silver / bronze */
.winner-rank {
  display: flex; align-items: center; justify-content: center;
  width: 26px; height: 26px; border-radius: 50%;
  font-size: 0.75rem; font-weight: 800; flex-shrink: 0;
}
.winner-row:nth-child(1) .winner-rank { background: rgba(250, 204, 21, 0.15); color: #facc15; border: 1px solid rgba(250, 204, 21, 0.4); text-shadow: 0 0 6px rgba(250, 204, 21, 0.5); }
.winner-row:nth-child(2) .winner-rank { background: rgba(148, 163, 184, 0.15); color: #94a3b8; border: 1px solid rgba(148, 163, 184, 0.4); }
.winner-row:nth-child(3) .winner-rank { background: rgba(180, 120, 60, 0.15); color: #cd7f32; border: 1px solid rgba(180, 120, 60, 0.4); }

.winner-info { display: flex; flex-direction: column; gap: 0.2rem; min-width: 0; }

.winner-name { font-size: 0.92rem; font-weight: 600; color: #fff; letter-spacing: 0.01em; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

.winner-meta-row { display: flex; align-items: center; gap: 0.6rem; flex-wrap: wrap; }

.winner-house {
  font-size: 0.72rem; font-weight: 600;
  color: #0a0f1e; background: #f59e0b;
  padding: 0.1rem 0.5rem; border-radius: 999px;
  white-space: nowrap;
}

.winner-email { font-size: 0.72rem; color: rgba(255, 255, 255, 0.4); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

/* ─── Team ─── */
.team-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 1.5rem; }

.team-card { background: #111; border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 20px; overflow: hidden; transition: transform 0.2s, box-shadow 0.2s; }
.team-card:hover { transform: translateY(-4px); box-shadow: 0 12px 32px rgba(245, 158, 11, 0.18); }

.team-photo-wrap { position: relative; aspect-ratio: 3 / 4; overflow: hidden; }
.team-photo { width: 100%; height: 100%; object-fit: cover; object-position: top; display: block; transition: transform 0.4s ease; }
.team-card:hover .team-photo { transform: scale(1.04); }

.team-overlay {
  position: absolute; bottom: 0; left: 0; right: 0; padding: 2.5rem 1rem 0.9rem;
  background: linear-gradient(to top, rgba(0,0,0,0.88) 0%, transparent 100%);
  display: flex; flex-direction: column; gap: 0.35rem;
}

.team-name { font-size: 1.05rem; font-weight: 700; color: #fff; margin: 0; line-height: 1.2; }

.team-role-badge {
  display: inline-flex; align-items: center; font-size: 0.72rem; font-weight: 700;
  letter-spacing: 0.08em; text-transform: uppercase; color: #0a0f1e; background: #f59e0b;
  padding: 0.2rem 0.65rem; border-radius: 999px; width: fit-content;
}

.team-footer { padding: 0.75rem 1rem 0.9rem; display: flex; align-items: center; justify-content: space-between; gap: 0.5rem; background: #111; }
.team-course { font-size: 0.78rem; color: rgba(255, 255, 255, 0.45); margin: 0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.team-socials { display: flex; gap: 0.35rem; flex-shrink: 0; }

.social-btn {
  display: flex; align-items: center; justify-content: center; width: 28px; height: 28px;
  border-radius: 8px; background: rgba(255, 255, 255, 0.07); color: rgba(255, 255, 255, 0.5);
  text-decoration: none; transition: background 0.2s, color 0.2s; border: 1px solid rgba(255, 255, 255, 0.08);
}
.social-btn:hover { background: #f59e0b; color: #0a0f1e; border-color: #f59e0b; }
</style>
