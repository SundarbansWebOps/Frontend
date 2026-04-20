<template>
  <div>
    <PageHero
      bg-image="https://images.unsplash.com/photo-1542751371-adc38448a05e?w=1920&q=80&auto=format&fit=crop"
      breadcrumb-title="Community"
      title="E-Sports"
      accent-title="Community"
      subtitle="Play. Compete. Win. — where Sundarbans players grind together."
    />

    <!-- Upcoming Events -->
    <section class="section rs">
      <div class="container">
        <div class="section-header">
          <div class="section-tag esports-tag">Upcoming Events</div>
          <h2 class="section-title-xl">What's <span class="tg-esports">Coming Up</span></h2>
          <p class="desc" style="max-width: 600px">
            Tournaments and sessions dropping soon — register before slots fill.
          </p>
        </div>

        <div class="events-grid">
          <div v-for="event in upcomingEvents" :key="event.id" class="event-card">
            <div class="event-date-badge">
              <span class="event-day">{{ event.day }}</span>
              <span class="event-month">{{ event.month }}</span>
            </div>
            <div class="event-info">
              <span class="event-type-tag">{{ event.type }}</span>
              <h3 class="event-title">{{ event.title }}</h3>
              <p class="event-desc">{{ event.description }}</p>
              <div class="event-meta">
                <span>🕐 {{ event.time }}</span>
                <span>📍 {{ event.venue }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Past Events -->
    <section class="section rs" style="background: var(--bg2)">
      <div class="container">
        <div class="section-header">
          <div class="section-tag esports-tag">Past Events</div>
          <h2 class="section-title-xl">What We've <span class="tg-esports">Done</span></h2>
          <p class="desc" style="max-width: 600px">
            Tournaments played, champions crowned, and clips worth rewatching.
          </p>
        </div>

        <div class="past-events-grid">
          <div v-for="event in pastEvents" :key="event.id" class="past-event-card">
            <div class="past-event-img-wrap">
              <!-- Blurred background to fill space and prevent empty black bars -->
              <img :src="event.image" class="past-event-img-blur" aria-hidden="true" />
              <!-- Distinct foreground image scaled properly -->
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
    <section class="section rs" style="background: var(--bg2)">
      <div class="container">
        <div class="section-header">
          <div class="section-tag esports-tag">Hall of Fame</div>
          <h2 class="section-title-xl">Event <span class="tg-esports">Winners</span></h2>
          <p class="desc" style="max-width: 600px">Champions who rose to the top across every tournament and challenge.</p>
        </div>
        <div class="winners-grid">
          <div v-for="event in eventWinners" :key="event.id" class="winner-card">
            <div class="winner-card-header">
              <span class="winner-event-tag">{{ event.type }}</span>
              <h3 class="winner-event-title">{{ event.title }}</h3>
            </div>
            <div v-if="event.noWinner" class="no-winner">
              <span class="no-winner-icon">—</span>
              <span>No winner recorded</span>
            </div>
            <ul v-else class="winners-list">
              <li v-for="(winner, index) in event.winners" :key="index" class="winner-row">
                <span class="winner-rank">{{ index + 1 }}</span>
                <div class="winner-info">
                  <span class="winner-name">{{ winner.name }}</span>
                  <span class="winner-email" v-if="winner.email">{{ winner.email }}</span>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </section>

    <!-- Community Team -->
    <section class="section rs">
      <div class="container">
        <div class="section-header">
          <div class="section-tag esports-tag">The Team</div>
          <h2 class="section-title-xl">People Behind the <span class="tg-esports">Community</span></h2>
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

import imgBgmiShowdown from "../assets/Community Events/E-Sports/BGMI Showdown 2025.jpeg";
import imgBtb from "../assets/Community Events/E-Sports/Back to Bachpan.jpeg";
import imgIpl from "../assets/Community Events/E-Sports/IPL Auction.jpeg";
import imgChessComp from "../assets/Community Events/E-Sports/Great Chess Competetion.jpeg";
import imgBgmiTourn from "../assets/Community Events/E-Sports/BGMI Tournament.jpeg";
import imgSportsQuiz from "../assets/Community Events/E-Sports/Sports Quiz.jpeg";
import imgBol from "../assets/Community Events/E-Sports/Battle Of Legends.jpeg";
import imgSkribbl from "../assets/Community Events/E-Sports/Skribbl Night.jpeg";
import imgAmongUs from "../assets/Community Events/E-Sports/Among Us night.jpeg";
import imgChessShowdown from "../assets/Community Events/E-Sports/Chess Tournament.jpeg";
import imgOpenMic from "../assets/Community Events/E-Sports/Open Mic.jpeg";

useScrollReveal();

const upcomingEvents = [
  {
    id: 1,
    title: "Valorant 5v5 House Tournament",
    type: "Tournament",
    description:
      "Internal Valorant tournament. 8 teams, single elimination, prizes for top 3.",
    day: "20",
    month: "APR",
    time: "4:00 PM",
    venue: "Gaming Lab, Block C",
  },
  {
    id: 2,
    title: "Chess Blitz Night",
    type: "Tournament",
    description:
      "Speed chess rounds — 3 minutes per side. Open to all skill levels.",
    day: "27",
    month: "APR",
    time: "8:00 PM",
    venue: "Common Room, Floor 2",
  },
  {
    id: 3,
    title: "BGMI Squad Scrimmage",
    type: "Scrimmage",
    description:
      "Casual squad matches to build team chemistry before the main tournament season.",
    day: "03",
    month: "MAY",
    time: "5:00 PM",
    venue: "Gaming Lab, Block C",
  },
];

const pastEvents = [
  {
    id: 1,
    title: "Sundarbans House BGMI Showdown 2025",
    type: "Tournament",
    description: "Sundarbans House BGMI Showdown 2025 brought together gaming enthusiasts from across the community for an action-packed battleground experience. Participants competed in custom rooms, showcased their strategies, teamwork, and reflexes, and prepared themselves for the upcoming Saavan event. The tournament created excitement, healthy competition, and gave players a platform to prove their skills while strengthening the e-sports spirit within the house.",
    date: "13 Sep 2025 | 5:00 PM",
    attendees: "50+",
    image: imgBgmiShowdown,
  },
  {
    id: 2,
    title: "Back to Bachpan",
    type: "Casual Event",
    description: "Back to Bachpan was a nostalgic and heartwarming event that gave members a chance to relive the joy of childhood games and memories. From classic fun activities to light-hearted challenges, the evening created an atmosphere full of laughter, bonding, and team spirit. More than just an event, it reminded everyone of the importance of simple joys and brought the Sundarbans community closer together.",
    date: "7 Nov 2025 | 8:30 PM",
    attendees: "50+",
    image: imgBtb,
  },
  {
    id: 3,
    title: "IPL Auction – Sundarbans Edition",
    type: "Strategy Event",
    description: "The IPL Auction – Sundarbans Edition gave participants the thrilling experience of becoming team owners and strategists. Members bid for players, built dream squads, and planned their tactics just like a real IPL auction. The event was filled with excitement, competitive bidding, and strategic decision-making, making it one of the most engaging sports-based events hosted by the community.",
    date: "10 Nov 2025 | 8:00 PM",
    attendees: "50+",
    image: imgIpl,
  },
  {
    id: 4,
    title: "Chess Competition",
    type: "Competition",
    description: "The Sundarbans Chess Competition brought together sharp minds and strategic thinkers for an intense battle of intellect. Participants competed in multiple rounds, testing their patience, concentration, and decision-making skills. The event encouraged sportsmanship and mental agility, while giving members an opportunity to challenge themselves in a highly competitive yet enjoyable setting.",
    date: "8 Dec 2025 | 6:00 PM",
    attendees: "50+",
    image: imgChessComp,
  },
  {
    id: 5,
    title: "BGMI Tournament",
    type: "Tournament",
    description: "The Sundarbans BGMI Tournament was an adrenaline-filled e-sports showdown where players battled in intense matches to prove their dominance on the battleground. The event saw impressive team coordination, clutch moments, and unforgettable finishes. It not only showcased gaming talent but also strengthened the growing e-sports culture within the Sundarbans community.",
    date: "10 Dec 2025 | 7:00 PM",
    attendees: "50+",
    image: imgBgmiTourn,
  },
  {
    id: 6,
    title: "Sports Quiz Showdown",
    type: "Quiz",
    description: "The Sports Quiz Showdown was a fun and energetic event that tested participants’ knowledge across various sports, players, records, and iconic moments. Members competed in a lively quiz environment filled with excitement, learning, and friendly banter. The event successfully blended entertainment with knowledge and brought out the competitive spirit of sports lovers.",
    date: "12 Dec 2025 | 7:00 PM",
    attendees: "50+",
    image: imgSportsQuiz,
  },
  {
    id: 7,
    title: "Battle of Legends 1.0 – Free Fire Tournament",
    type: "Tournament",
    description: "Battle of Legends 1.0 was a high-voltage Free Fire tournament that delivered excitement, action, and unforgettable moments. Participants showcased their gaming skills, strategy, and teamwork in a fiercely competitive environment. The event was a huge success in bringing together passionate gamers and creating an engaging platform for members to connect and compete.",
    date: "13 Dec 2025 | 6:00 PM",
    attendees: "50+",
    image: imgBol,
  },
  {
    id: 8,
    title: "Skribbl Night",
    type: "Interactive Event",
    description: "Skribbl Night was a light-hearted and interactive event that filled the evening with creativity, laughter, and fun. Members drew, guessed, and competed in a relaxed setting that encouraged participation from everyone. The event provided a refreshing break from academics and created memorable moments of joy and bonding within the community.",
    date: "6 Feb 2026 | 7:00 PM",
    attendees: "50+",
    image: imgSkribbl,
  },
  {
    id: 9,
    title: "Among Us Night",
    type: "Social Gaming",
    description: "Among Us Night brought members together for an exciting evening of mystery, teamwork, and deception. Participants worked together to complete tasks while trying to identify the impostors among them. The event was packed with suspense, laughter, and surprise twists, making it one of the most entertaining social gaming nights for the Sundarbans community.",
    date: "13 Feb 2026 | 7:00 PM",
    attendees: "50+",
    image: imgAmongUs,
  },
  {
    id: 10,
    title: "Chess Showdown",
    type: "Competition",
    description: "The Sundarbans Chess Showdown was an intense competition that challenged members to think critically and stay calm under pressure. Featuring elimination rounds and a grand finale, the event pushed participants to bring their best strategies to the board. It highlighted the growing interest in mind sports and gave players a chance to showcase their tactical excellence.",
    date: "27 Feb 2026 | 7:00 PM",
    attendees: "50+",
    image: imgChessShowdown,
  },
  {
    id: 11,
    title: "Open Mic – Feedback Session",
    type: "Feedback Session",
    description: "The Open Mic Feedback Session was a meaningful community interaction where members openly shared their experiences, suggestions, and ideas for future events. It served as a platform to understand participation challenges, gather valuable insights, and improve future planning. The session reflected Sundarbans House’s commitment to inclusivity, transparency, and continuous growth as a student community.",
    date: "8:30 PM onwards",
    attendees: "50+",
    image: imgOpenMic,
  }
];

const eventWinners = [
  {
    id: 1, title: "Free Fire – Battle of Legends", type: "Tournament", noWinner: false,
    winners: [
      { name: "Bhoopendra Chandel", email: "23f3000441@es.study.iitm.ac.in" },
      { name: "Agampreet Singh",    email: "24f2002079@ds.study.iitm.ac.in" },
      { name: "Aditya Chaubey",     email: "25f2008372@ds.study.iitm.ac.in" },
      { name: "Alok Chaubey",       email: "24f2006338@ds.study.iitm.ac.in" },
    ],
  },
  {
    id: 2, title: "BGMI Showdown 2025", type: "Tournament", noWinner: false,
    winners: [
      { name: "Divyansh Chandra", email: "25f2002300@ds.study.iitm.ac.in" },
      { name: "Sumit Singhal",    email: "24f2003662@ds.study.iitm.ac.in" },
    ],
  },
  {
    id: 3, title: "Valorant Tournament", type: "Tournament", noWinner: true, winners: [],
  },
  {
    id: 4, title: "Great Chess Competition", type: "Competition", noWinner: false,
    winners: [
      { name: "Syan Das",                    email: "25f2007719@ds.study.iitm.ac.in" },
      { name: "Pradip Boro",                 email: "25f2001618@ds.study.iitm.ac.in" },
      { name: "Daggubati Bapaiah Chowdary",  email: "25f3100064@es.study.iitm.ac.in" },
    ],
  },
  {
    id: 5, title: "Sports Quiz Showdown", type: "Quiz", noWinner: false,
    winners: [
      { name: "Naren Sampath",     email: "25f3001304@ds.study.iitm.ac.in" },
      { name: "Sai Rajith Ponnuru", email: "25f3100110@ds.study.iitm.ac.in" },
    ],
  },
  {
    id: 6, title: "Back to Bachpan", type: "Casual Event", noWinner: false,
    winners: [
      { name: "Shaik Neeha Jasmine", email: "25f3100078@es.study.iitm.ac.in" },
      { name: "Aditri Bordoloi",     email: "25f2008346@ds.study.iitm.ac.in" },
      { name: "Aarya",               email: "25f1000637@ds.study.iitm.ac.in" },
    ],
  },
  {
    id: 7, title: "IPL Auction – Sundarbans Edition", type: "Strategy Event", noWinner: false,
    winners: [
      { name: "Chandigarh Region", email: "" },
      { name: "Kolkata Region",    email: "" },
      { name: "Lucknow Region",    email: "" },
    ],
  },
  {
    id: 8, title: "Open Mic – Feedback Session", type: "Feedback Session", noWinner: true, winners: [],
  },
  {
    id: 9, title: "Chess Showdown", type: "Competition", noWinner: false,
    winners: [
      { name: "Plavit Chandalia", email: "25f2000710@ds.study.iitm.ac.in" },
      { name: "Ashish Kumar",     email: "25f1002782@ds.study.iitm.ac.in" },
      { name: "Divyansh Tiwari",  email: "22f3001534@ds.study.iitm.ac.in" },
    ],
  },
  {
    id: 10, title: "BGMI Tournament", type: "Tournament", noWinner: false,
    winners: [
      { name: "Abdul Kadir", email: "25f2000502@ds.study.iitm.ac.in" },
    ],
  },
  {
    id: 11, title: "Sports Quiz", type: "Quiz", noWinner: false,
    winners: [
      { name: "Bhavana S",            email: "25f3001430@ds.study.iitm.ac.in" },
      { name: "Neeha Jasmine Shaik",  email: "25f3100078@es.study.iitm.ac.in" },
    ],
  },
  {
    id: 12, title: "Free Fire", type: "Tournament", noWinner: true, winners: [],
  },
];

const team = [
  {
    name: "Vivaan Singh",
    role: "Community Lead",
    track: "Valorant",
    city: "Delhi",
    photo: "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&q=80&auto=format&fit=crop&crop=face",
    email: "mailto:vivaan@sundarbans.in",
    linkedin: "#",
    instagram: "#",
  },
  {
    name: "Tanya Reddy",
    role: "Tournament Director",
    track: "BGMI",
    city: "Hyderabad",
    photo: "https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=400&q=80&auto=format&fit=crop&crop=face",
    email: "mailto:tanya@sundarbans.in",
    linkedin: "#",
    instagram: "#",
  },
  {
    name: "Aman Joshi",
    role: "Strategy Coach",
    track: "Chess & FPS",
    city: "Pune",
    photo: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&q=80&auto=format&fit=crop&crop=face",
    email: "mailto:aman@sundarbans.in",
    linkedin: "#",
    instagram: "#",
  },
  {
    name: "Riya Menon",
    role: "Community Manager",
    track: "Operations",
    city: "Kochi",
    photo: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80&auto=format&fit=crop&crop=face",
    email: "mailto:riya@sundarbans.in",
    linkedin: "#",
    instagram: "#",
  },
];
</script>

<style scoped>
/* ── Accent: Blood Protocol — #DC2626 Crimson / #F97316 Ember ── */

.section-header {
  margin-bottom: 2.5rem;
}

.tg-esports {
  background: linear-gradient(135deg, #DC2626, #F97316);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
}

/* Tags */
.esports-tag {
  background: rgba(220, 38, 38, 0.10);
  color: #EF4444;
  border-color: rgba(220, 38, 38, 0.30);
}

.event-type-tag {
  display: inline-block;
  font-size: 0.72rem;
  font-weight: 700;
  padding: 0.25rem 0.65rem;
  border-radius: 6px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  margin-bottom: 0.75rem;
  background: rgba(220, 38, 38, 0.10);
  color: #EF4444;
  border: 1px solid rgba(220, 38, 38, 0.25);
  box-shadow: 0 0 10px rgba(220, 38, 38, 0.05);
}

/* Upcoming Events */
.events-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 1.5rem;
}

.event-card {
  position: relative;
  display: flex;
  gap: 1.2rem;
  align-items: flex-start;
  background: rgba(15, 10, 10, 0.85);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(220, 38, 38, 0.15);
  border-radius: 12px;
  padding: 1.5rem;
  overflow: hidden;
  transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
}

.event-card::before {
  content: '';
  position: absolute;
  left: 0; top: 0; bottom: 0;
  width: 4px;
  background: linear-gradient(180deg, #DC2626, #F97316);
  opacity: 0.5;
  transition: width 0.3s ease, opacity 0.3s ease;
}

.event-card:hover {
  transform: translateY(-4px);
  border-color: rgba(220, 38, 38, 0.45);
  box-shadow:
    0 10px 30px rgba(220, 38, 38, 0.12),
    0 0 40px rgba(220, 38, 38, 0.06);
}

.event-card:hover::before {
  width: 6px;
  opacity: 1;
  box-shadow: 0 0 15px #DC2626;
}

.event-date-badge {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-width: 54px;
  border-radius: 8px;
  padding: 0.6rem;
  background: rgba(220, 38, 38, 0.15);
  border: 1px solid rgba(220, 38, 38, 0.30);
  color: #EF4444;
  line-height: 1;
  flex-shrink: 0;
  text-shadow: 0 0 8px rgba(239, 68, 68, 0.5);
}

.event-day {
  font-size: 1.5rem;
  font-weight: 800;
}

.event-month {
  font-size: 0.7rem;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  margin-top: 3px;
}

.event-info { flex: 1; }

.event-title {
  font-size: 1.1rem;
  font-weight: 800;
  margin: 0 0 0.5rem;
  color: #fff;
  letter-spacing: 0.02em;
}

.event-desc {
  font-size: 0.88rem;
  color: rgba(255, 255, 255, 0.65);
  margin: 0 0 0.8rem;
  line-height: 1.6;
}

.event-meta {
  display: flex;
  gap: 1.2rem;
  font-size: 0.82rem;
  color: rgba(220, 38, 38, 0.80);
  font-family: 'Courier New', Courier, monospace;
  font-weight: 600;
  flex-wrap: wrap;
}

/* Past Events */
.past-events-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1.8rem;
}

.past-event-card {
  background: rgba(15, 10, 10, 0.85);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(220, 38, 38, 0.15);
  border-radius: 12px;
  overflow: hidden;
  transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
  position: relative;
  display: flex;
  flex-direction: column;
}

.past-event-card::before {
  content: '';
  position: absolute;
  top: 0; left: 0; right: 0;
  height: 2px;
  background: linear-gradient(90deg, #DC2626, #F97316);
  opacity: 0;
  transition: opacity 0.3s ease;
  z-index: 10;
}

.past-event-card:hover {
  transform: translateY(-6px) scale(1.01);
  box-shadow:
    0 12px 32px rgba(220, 38, 38, 0.15),
    0 0 20px rgba(249, 115, 22, 0.08);
  border-color: rgba(220, 38, 38, 0.50);
}

.past-event-card:hover::before {
  opacity: 1;
  box-shadow: 0 2px 10px #DC2626;
}

.past-event-img-wrap {
  position: relative;
  width: 100%;
  aspect-ratio: 16 / 9;
  background: #0a0a0a;
  overflow: hidden;
}

.past-event-img-blur {
  position: absolute;
  top: -15%; left: -15%;
  width: 130%; height: 130%;
  object-fit: cover;
  filter: blur(20px) brightness(0.3);
  z-index: 0;
}

.past-event-img {
  position: absolute;
  top: 0; left: 0;
  width: 100%;
  height: 100%;
  object-fit: contain;
  z-index: 1;
  transition: transform 0.5s cubic-bezier(0.25, 0.8, 0.25, 1);
}

.past-event-card:hover .past-event-img {
  transform: scale(1.06);
}

.past-event-overlay {
  position: absolute;
  bottom: 8px; right: 8px;
  padding: 0;
  z-index: 2;
}

.past-event-date {
  font-family: 'Courier New', Courier, monospace;
  font-size: 0.75rem;
  color: #fff;
  font-weight: 700;
  background: rgba(0, 0, 0, 0.7);
  border: 1px solid rgba(220, 38, 38, 0.30);
  padding: 0.3rem 0.6rem;
  border-radius: 6px;
  backdrop-filter: blur(4px);
  text-shadow: 0 0 5px rgba(220, 38, 38, 0.80);
  letter-spacing: 0.05em;
}

.past-event-body {
  padding: 1.4rem;
  flex: 1;
  display: flex;
  flex-direction: column;
}

.past-event-title {
  font-size: 1.1rem;
  font-weight: 800;
  margin: 0.2rem 0 0.5rem;
  color: #fff;
  letter-spacing: 0.02em;
  transition: text-shadow 0.3s ease;
}

.past-event-card:hover .past-event-title {
  text-shadow: 0 0 10px rgba(220, 38, 38, 0.5);
}

.past-event-desc {
  font-size: 0.88rem;
  color: rgba(255, 255, 255, 0.65);
  line-height: 1.6;
  margin: 0 0 1rem;
  flex: 1;
}

.past-event-stat {
  font-family: 'Courier New', Courier, monospace;
  font-weight: 600;
  font-size: 0.82rem;
  color: rgba(220, 38, 38, 0.80);
  padding-top: 0.8rem;
  border-top: 1px dashed rgba(220, 38, 38, 0.20);
}

/* Team — photo card style */
.team-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 1.5rem;
}

.team-card {
  background: #111;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 20px;
  overflow: hidden;
  transition: transform 0.2s, box-shadow 0.2s;
}

.team-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 32px rgba(220, 38, 38, 0.20);
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
  background: linear-gradient(to top, rgba(0,0,0,0.88) 0%, transparent 100%);
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
  color: #fff;
  background: #DC2626;
  padding: 0.2rem 0.65rem;
  border-radius: 999px;
  width: fit-content;
}

.team-footer {
  padding: 0.75rem 1rem 0.9rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
  background: #111;
}

.team-course {
  font-size: 0.78rem;
  color: rgba(255, 255, 255, 0.45);
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
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.07);
  color: rgba(255, 255, 255, 0.5);
  text-decoration: none;
  transition: background 0.2s, color 0.2s;
  border: 1px solid rgba(255, 255, 255, 0.08);
}

.social-btn:hover {
  background: #DC2626;
  color: #fff;
  border-color: #DC2626;
}

/* ── GAMING EFFECTS ── */

/* Scanning line — subtle CRT/HUD sweep */
@keyframes scanLine {
  0%   { top: -2px; }
  100% { top: 100%; }
}

/* Pulsing border glow for first upcoming event */
.event-card:first-child {
  animation: borderPulse 3s ease-in-out infinite;
}

@keyframes borderPulse {
  0%, 100% {
    border-color: rgba(220, 38, 38, 0.15);
    box-shadow: 0 0 0px rgba(220, 38, 38, 0);
  }
  50% {
    border-color: rgba(220, 38, 38, 0.45);
    box-shadow: 0 0 25px rgba(220, 38, 38, 0.10);
  }
}
/* ─── Winners ─── */
.winners-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1.5rem;
}

.winner-card {
  position: relative;
  background: rgba(15, 10, 10, 0.85);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(220, 38, 38, 0.2);
  border-radius: 10px;
  padding: 1.5rem 1.5rem 1.5rem 1.8rem;
  overflow: hidden;
  transition: border-color 0.3s ease, box-shadow 0.3s ease;
}

.winner-card::before {
  content: '';
  position: absolute;
  left: 0; top: 0; bottom: 0;
  width: 4px;
  background: linear-gradient(180deg, #DC2626, #F97316);
  box-shadow: 0 0 10px #DC2626;
}

.winner-card:hover {
  border-color: rgba(220, 38, 38, 0.45);
  box-shadow: 0 10px 30px rgba(220, 38, 38, 0.12);
}

.winner-card-header { margin-bottom: 1.1rem; }

.winner-event-tag {
  display: inline-block;
  font-size: 0.7rem;
  font-weight: 700;
  padding: 0.2rem 0.6rem;
  border-radius: 4px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  margin-bottom: 0.5rem;
  background: rgba(220, 38, 38, 0.1);
  color: #EF4444;
  border: 1px solid rgba(220, 38, 38, 0.3);
}

.winner-event-title {
  font-size: 1rem;
  font-weight: 700;
  color: #e0e0e0;
  margin: 0;
  letter-spacing: 0.02em;
}

.winners-list {
  list-style: none;
  margin: 0; padding: 0;
  display: flex; flex-direction: column; gap: 0.5rem;
}

.winner-row {
  display: flex; align-items: center; gap: 0.8rem;
  padding: 0.55rem 0.8rem;
  border-radius: 6px;
  background: rgba(220, 38, 38, 0.05);
  border: 1px solid rgba(220, 38, 38, 0.1);
  transition: background 0.2s;
}
.winner-row:hover { background: rgba(220, 38, 38, 0.1); }

.winner-rank {
  display: flex; align-items: center; justify-content: center;
  width: 24px; height: 24px;
  border-radius: 50%;
  font-size: 0.72rem; font-weight: 800;
  flex-shrink: 0;
}
.winner-row:nth-child(1) .winner-rank { background: rgba(250,204,21,0.15); color: #facc15; border: 1px solid rgba(250,204,21,0.4); }
.winner-row:nth-child(2) .winner-rank { background: rgba(148,163,184,0.15); color: #94a3b8; border: 1px solid rgba(148,163,184,0.4); }
.winner-row:nth-child(3) .winner-rank { background: rgba(180,120,60,0.15); color: #cd7f32; border: 1px solid rgba(180,120,60,0.4); }
.winner-row:nth-child(n+4) .winner-rank { background: rgba(220,38,38,0.1); color: #EF4444; border: 1px solid rgba(220,38,38,0.3); }

.winner-info { display: flex; flex-direction: column; gap: 0.15rem; min-width: 0; }
.winner-name { font-size: 0.88rem; font-weight: 600; color: #e0e0e0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.winner-email { font-size: 0.68rem; color: rgba(220, 38, 38, 0.6); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

.no-winner {
  display: flex; align-items: center; gap: 0.75rem;
  padding: 0.75rem;
  border-radius: 6px;
  background: rgba(255,255,255,0.02);
  border: 1px dashed rgba(255,255,255,0.1);
  font-size: 0.82rem;
  color: rgba(255,255,255,0.3);
  font-style: italic;
}
.no-winner-icon { color: rgba(255,255,255,0.2); }
</style>
