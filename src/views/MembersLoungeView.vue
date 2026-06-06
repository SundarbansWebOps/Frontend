<template>
  <div class="members-lounge-page">
    <!-- PAGE LOADER -->
    <transition name="fade-slow">
      <div id="page-loader" v-if="pageLoading">
        <div class="loader-monogram">S</div>
        <div class="loader-tagline">Members Lounge</div>
        <div class="loader-bar"><div class="loader-fill"></div></div>
      </div>
    </transition>

    <div class="grain"></div>

    <!-- NAVBAR -->
    <MembersNavbar
      :member-email="memberEmail"
      @logout="logout"
    />

    <!-- ═══════════════ HERO ═══════════════ -->
    <section class="hero">
      <div class="hero-bg-grid"></div>
      <div class="hero-orb hero-orb-1"></div>
      <div class="hero-orb hero-orb-2"></div>
      <div class="hero-orb hero-orb-3"></div>

      <div class="hero-content">
        <div class="hero-badge">
          <span class="badge-dot"></span>
          Exclusive Members Lounge
          <span class="badge-dot badge-dot-r"></span>
        </div>

        <h1 class="hero-greeting">
          Welcome Back,<br />
          <em>{{ memberRoll }}</em>
        </h1>

        <p class="hero-sub">Grow Together. Lead Together. Build Together.</p>

        <div class="hero-stats">
          <div class="stat">
            <div class="stat-val">{{ todayEventName }}</div>
            <div class="stat-lbl">Today</div>
          </div>
          <div class="stat-sep"></div>
          <div class="stat">
            <div class="stat-val countdown-val">{{ countdownText }}</div>
            <div class="stat-lbl">Reading Lounge</div>
          </div>
          <div class="stat-sep"></div>
          <div class="stat">
            <div class="stat-val">5</div>
            <div class="stat-lbl">Events / Week</div>
          </div>
        </div>

        <div class="hero-cta-row">
          <a href="#events" class="cta-primary" @click.prevent="smoothScroll('#events')">View Schedule</a>
          <a href="#lounge" class="cta-secondary" @click.prevent="smoothScroll('#lounge')">Reading Rooms</a>
          <a href="#community" class="cta-secondary" @click.prevent="smoothScroll('#community')">WhatsApp</a>
        </div>
      </div>

      <div class="hero-scroll-hint">
        <div class="scroll-line"></div>
        <span>Scroll</span>
      </div>
    </section>

    <div class="divider"></div>

    <!-- ═══════════════ EVENTS ═══════════════ -->
    <section id="events">
      <div class="container">
        <div class="reveal" v-observe>
          <div class="section-label">Weekly Schedule</div>
          <h2 class="section-title">Live Events</h2>
          <p class="section-desc">Five curated sessions every week — technical, cultural, and everything in between.</p>
        </div>

        <div class="events-grid">
          <div
            v-for="(ev, index) in events"
            :key="index"
            class="event-card"
            :class="{ 'today-event': ev.isToday, 'past-event': ev.isPast }"
            v-observe
            :style="{ transitionDelay: `${index * 0.09}s` }"
          >
            <div class="event-card-top">
              <span class="event-day-badge">{{ ev.dayLabel }}</span>
              <span class="event-icon">{{ ev.icon }}</span>
            </div>
            <h3>{{ ev.title }}</h3>
            <p>{{ ev.desc }}</p>
            <div class="event-card-footer">
              <div class="event-time">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>
                {{ ev.time }}
              </div>
              <a
                :href="ev.gmeetLink"
                target="_blank"
                rel="noopener"
                class="join-btn"
                :class="{ 'btn-disabled': ev.isPast }"
                @click="ev.isPast ? $event.preventDefault() : null"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 10l5 5-5 5"/><path d="M4 4v7a4 4 0 0 0 4 4h12"/></svg>
                {{ ev.isPast ? 'Session Ended' : 'Join GMeet' }}
              </a>
            </div>
            <div v-if="ev.isToday" class="today-tag">
              <span class="today-dot"></span> Live Today
            </div>
          </div>
        </div>
      </div>
    </section>

    <div class="divider"></div>

    <!-- ═══════════════ NIGHT OWL ═══════════════ -->
    <section id="lounge" class="night-section">
      <div class="container">
        <div class="reveal" v-observe>
          <div class="section-label">Night Owl</div>
          <h2 class="section-title">
            Reading Lounge
            <span class="title-aside">9:30 PM · Every Night</span>
          </h2>
          <p class="section-desc">A quiet hour for the curious. Pick a room, bring your book, read alongside your house.</p>
        </div>

        <div class="reading-grid">
          <div class="reading-card" v-observe>
            <div class="reading-card-header">
              <span class="reading-icon">📘</span>
              <div class="room-live-chip">
                <span class="room-dot"></span>
                {{ isNightOwlTime ? 'Live Now' : 'Tonight' }}
              </div>
            </div>
            <h3>English Room</h3>
            <div class="reading-meta">
              <span class="meta-tag">{{ currentEnglishGenre }}</span>
              <span class="meta-sep">·</span>
              <span class="meta-text">60 min session</span>
            </div>
            <p>A quiet, focused reading session. No discussion — just the company of readers and the page.</p>
            <div class="reading-card-footer">
              <div class="reading-members">
                <div class="member-dots">
                  <div class="mdot" style="background:#c9a84c"></div>
                  <div class="mdot" style="background:#8bc8a8"></div>
                  <div class="mdot" style="background:#a8b8e8"></div>
                </div>
                <span>{{ englishRoomCount }} reading</span>
              </div>
              <a :href="NIGHT_OWL_LINKS.english" target="_blank" rel="noopener" class="join-btn">Enter Room</a>
            </div>
          </div>

          <div class="reading-card" v-observe style="transition-delay:0.1s">
            <div class="reading-card-header">
              <span class="reading-icon">📙</span>
              <div class="room-live-chip">
                <span class="room-dot"></span>
                {{ isNightOwlTime ? 'Live Now' : 'Tonight' }}
              </div>
            </div>
            <h3>Hindi Room</h3>
            <div class="reading-meta">
              <span class="meta-tag">{{ currentHindiGenre }}</span>
              <span class="meta-sep">·</span>
              <span class="meta-text">60 min session</span>
            </div>
            <p>Hindi sahitya ke saath ek shant shaam. Apni pasandida kitaab lekar aayein.</p>
            <div class="reading-card-footer">
              <div class="reading-members">
                <div class="member-dots">
                  <div class="mdot" style="background:#e8c97a"></div>
                  <div class="mdot" style="background:#c87878"></div>
                  <div class="mdot" style="background:#78c878"></div>
                </div>
                <span>{{ hindiRoomCount }} reading</span>
              </div>
              <a :href="NIGHT_OWL_LINKS.hindi" target="_blank" rel="noopener" class="join-btn">Enter Room</a>
            </div>
          </div>

          <div class="reading-card reading-pick-card" v-observe style="transition-delay:0.2s">
            <div class="pick-label">House Pick of the Week</div>
            <div class="pick-book">
              <div class="book-spine"><span>{{ houseBookPick.title }}</span></div>
              <div class="book-info">
                <div class="book-title">{{ houseBookPick.title }}</div>
                <div class="book-author">— {{ houseBookPick.author }}</div>
                <div class="book-desc">{{ houseBookPick.desc }}</div>
                <div class="book-tags">
                  <span v-for="tag in houseBookPick.tags" :key="tag" class="book-tag">{{ tag }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <div class="divider"></div>

    <!-- ═══════════════ WHATSAPP COMMUNITY ═══════════════ -->
    <section id="community">
      <div class="container">
        <div class="reveal" v-observe>
          <div class="section-label">Stay Connected</div>
          <h2 class="section-title">WhatsApp Groups</h2>
          <p class="section-desc">Join the main Sundarbans house group or find your regional group below. Fill the form to get added.</p>
        </div>

        <!-- Main Group -->
        <div class="wa-main-card reveal" v-observe>
          <div class="wa-main-left">
            <div class="wa-icon-wrap">
              <svg class="wa-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/><path d="M12 0C5.373 0 0 5.373 0 12c0 2.127.558 4.122 1.532 5.852L.057 23.155a.75.75 0 0 0 .918.918l5.303-1.475A11.953 11.953 0 0 0 12 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 22a9.956 9.956 0 0 1-5.193-1.453l-.372-.22-3.148.875.875-3.148-.22-.372A9.956 9.956 0 0 1 2 12C2 6.477 6.477 2 12 2s10 4.477 10 10-4.477 10-10 10z"/></svg>
            </div>
            <div>
              <div class="wa-main-label">Main House Group</div>
              <h3 class="wa-main-title">Sundarbans House</h3>
              <p class="wa-main-desc">Official sign-up for the main Sundarbans house group. Announcements, events, and everything in between.</p>
            </div>
          </div>
          <a href="https://docs.google.com/forms/d/e/1FAIpQLSdP9gY3ET4EylNi771CaXQ8ihmsqEdjbat7rvSDZAsu2j0a9Q/viewform" target="_blank" rel="noopener" class="wa-join-btn wa-join-main">
            <svg viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/><path d="M12 0C5.373 0 0 5.373 0 12c0 2.127.558 4.122 1.532 5.852L.057 23.155a.75.75 0 0 0 .918.918l5.303-1.475A11.953 11.953 0 0 0 12 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 22a9.956 9.956 0 0 1-5.193-1.453l-.372-.22-3.148.875.875-3.148-.22-.372A9.956 9.956 0 0 1 2 12C2 6.477 6.477 2 12 2s10 4.477 10 10-4.477 10-10 10z"/></svg>
            Join Main Group
          </a>
        </div>

        <!-- Regional Groups -->
        <div class="wa-regions-header reveal" v-observe>
          <div class="section-label" style="margin-bottom:0">Regional Groups</div>
        </div>

        <div class="whatsapp-grid">
          <div class="whatsapp-card" v-observe :style="{ transitionDelay: `${index * 0.07}s` }"
            v-for="(region, index) in waRegions" :key="region.id">
            <div class="wa-card-top">
              <div class="wa-icon-wrap wa-icon-region">
                <svg class="wa-icon" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/><path d="M12 0C5.373 0 0 5.373 0 12c0 2.127.558 4.122 1.532 5.852L.057 23.155a.75.75 0 0 0 .918.918l5.303-1.475A11.953 11.953 0 0 0 12 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 22a9.956 9.956 0 0 1-5.193-1.453l-.372-.22-3.148.875.875-3.148-.22-.372A9.956 9.956 0 0 1 2 12C2 6.477 6.477 2 12 2s10 4.477 10 10-4.477 10-10 10z"/></svg>
              </div>
              <span class="wa-region-badge">{{ region.id.toUpperCase() }}</span>
            </div>
            <h3 class="wa-title">{{ region.name }}</h3>
            <div v-if="region.coordinator" class="wa-coordinator">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
              {{ region.coordinator }}
            </div>
            <a :href="region.form" target="_blank" rel="noopener" class="wa-join-btn">
              <svg viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/><path d="M12 0C5.373 0 0 5.373 0 12c0 2.127.558 4.122 1.532 5.852L.057 23.155a.75.75 0 0 0 .918.918l5.303-1.475A11.953 11.953 0 0 0 12 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 22a9.956 9.956 0 0 1-5.193-1.453l-.372-.22-3.148.875.875-3.148-.22-.372A9.956 9.956 0 0 1 2 12C2 6.477 6.477 2 12 2s10 4.477 10 10-4.477 10-10 10z"/></svg>
              Sign Up
            </a>
          </div>
        </div>

      </div>
    </section>

    <div class="divider"></div>

    <!-- ═══════════════ LEADERBOARD ═══════════════ -->
    <section id="leaderboard">
      <div class="container">
        <div class="reveal" v-observe>
          <div class="section-label">Recognition</div>
          <h2 class="section-title">Top Performers</h2>
          <p class="section-desc">Rankings reset monthly. Earn points by attending sessions, winning challenges, and contributing to the house.</p>
        </div>

        <div class="leaderboard-wrap">
          <div class="podium" v-observe>
            <div class="podium-slot podium-2" v-if="leaderboard[1]">
              <div class="podium-avatar silver-av">{{ leaderboard[1].name.charAt(0) }}</div>
              <div class="podium-name">{{ leaderboard[1].name.split(' ')[0] }}</div>
              <div class="podium-pts">{{ leaderboard[1].pts }}<span>pts</span></div>
              <div class="podium-block podium-block-2">2</div>
            </div>
            <div class="podium-slot podium-1" v-if="leaderboard[0]">
              <div class="podium-crown">♛</div>
              <div class="podium-avatar gold-av">{{ leaderboard[0].name.charAt(0) }}</div>
              <div class="podium-name">{{ leaderboard[0].name.split(' ')[0] }}</div>
              <div class="podium-pts">{{ leaderboard[0].pts }}<span>pts</span></div>
              <div class="podium-block podium-block-1">1</div>
            </div>
            <div class="podium-slot podium-3" v-if="leaderboard[2]">
              <div class="podium-avatar bronze-av">{{ leaderboard[2].name.charAt(0) }}</div>
              <div class="podium-name">{{ leaderboard[2].name.split(' ')[0] }}</div>
              <div class="podium-pts">{{ leaderboard[2].pts }}<span>pts</span></div>
              <div class="podium-block podium-block-3">3</div>
            </div>
          </div>

          <ul class="leaderboard-list">
            <li
              v-for="(member, index) in leaderboard"
              :key="member.roll"
              class="leaderboard-item"
              v-observe
              :style="{ transitionDelay: `${index * 0.07}s` }"
              :class="{ 'is-you': member.roll === memberEmail }"
            >
              <div class="lb-rank" :class="getMedalClass(index)">
                <span v-if="index < 3">{{ ['♛','♜','♝'][index] }}</span>
                <span v-else>{{ index + 1 }}</span>
              </div>
              <div class="lb-avatar" :style="{ background: memberColors[index % memberColors.length] }">
                {{ member.name.charAt(0) }}
              </div>
              <div class="lb-info">
                <div class="lb-name">
                  {{ member.name }}
                  <span v-if="member.roll === memberEmail" class="you-tag">you</span>
                </div>
                <div class="lb-roll">{{ member.roll }}</div>
              </div>
              <div class="lb-right">
                <div class="lb-bar-wrap">
                  <div class="lb-bar" :style="{ width: (member.pts / leaderboard[0].pts * 100) + '%' }"></div>
                </div>
                <div class="lb-pts-row">
                  <span class="lb-pts">{{ member.pts }}</span>
                  <span class="lb-pts-lbl">pts</span>
                </div>
              </div>
            </li>
          </ul>

          <div class="lb-footer-note">
            Points awarded for event attendance, challenge completions, and community contributions.
            Rankings refresh on the 1st of each month.
          </div>
        </div>
      </div>
    </section>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import MembersNavbar from '../components/MembersNavbar.vue';

const router = useRouter();

// ── GMEET LINKS — replace placeholders with real recurring links ───────────
const NIGHT_OWL_LINKS = {
  english: 'https://meet.google.com/placeholder-english',
  hindi:   'https://meet.google.com/placeholder-hindi',
};
const GMEET_LINKS = {
  monday:   'https://meet.google.com/placeholder-technical',
  tuesday:  'https://meet.google.com/placeholder-doubt',
  thursday: 'https://meet.google.com/placeholder-cultural',
  friday:   'https://meet.google.com/placeholder-sports',
  sunday:   'https://meet.google.com/placeholder-talk',
};

// ── STATE ─────────────────────────────────────────────────────────────────
const pageLoading   = ref(true);
const memberEmail   = ref('');
const memberRoll    = ref('');
const countdownText = ref('—');
let   countdownInterval = null;

// ── EVENTS ────────────────────────────────────────────────────────────────
const dayIndex = new Date().getDay();
const events = ref([
  { day: 1, dayLabel: 'Monday',   icon: '🧠', title: 'Technical Session', desc: 'Advanced DSA, system design, and competitive programming with live mentors.', time: '8:00 PM IST', gmeetLink: GMEET_LINKS.monday,   isToday: dayIndex === 1, isPast: false },
  { day: 2, dayLabel: 'Tuesday',  icon: '❓', title: 'Doubt Session',      desc: 'Live mentor Q&A. Bring your questions, leave with clarity. No question is too small.', time: '8:00 PM IST', gmeetLink: GMEET_LINKS.tuesday,  isToday: dayIndex === 2, isPast: false },
  { day: 4, dayLabel: 'Thursday', icon: '🎭', title: 'Cultural Night',     desc: 'Debate nights, open mic, talent showcase. Express yourself with your Sundarbans family.', time: '8:00 PM IST', gmeetLink: GMEET_LINKS.thursday, isToday: dayIndex === 4, isPast: false },
  { day: 5, dayLabel: 'Friday',   icon: '🏏', title: 'Sports & Fitness',   desc: 'House matches, fitness challenges, and friendly competitions. Stay active, stay sharp.', time: '8:00 PM IST', gmeetLink: GMEET_LINKS.friday,   isToday: dayIndex === 5, isPast: false },
  { day: 0, dayLabel: 'Sunday',   icon: '🎤', title: 'Talk with Senior',   desc: 'Career guidance, strategy sessions, and real stories from seniors who have been there.', time: '8:00 PM IST', gmeetLink: GMEET_LINKS.sunday,   isToday: dayIndex === 0, isPast: false },
]);

// Mark today's event as past if hour >= 22
events.value.forEach(ev => {
  if (ev.isToday && new Date().getHours() >= 22) ev.isPast = true;
});

const todayEventName = computed(() => {
  const ev = events.value.find(e => e.isToday);
  return ev ? ev.title.split(' ')[0] : 'Rest Day';
});

// ── NIGHT OWL ────────────────────────────────────────────────────────────
const isNightOwlTime = computed(() => {
  const h = new Date().getHours();
  return h >= 21 && h < 23;
});
const ENGLISH_GENRES = ['Fiction','Sci-Fi','Non-Fiction','Mystery','Biography','Philosophy'];
const HINDI_GENRES   = ['Kahani','Kavita','Upanyas','Sahitya','Natak'];
const currentEnglishGenre = ENGLISH_GENRES[new Date().getDay() % ENGLISH_GENRES.length];
const currentHindiGenre   = HINDI_GENRES[new Date().getDay() % HINDI_GENRES.length];
const englishRoomCount    = ref(Math.floor(Math.random() * 12) + 4);
const hindiRoomCount      = ref(Math.floor(Math.random() * 8)  + 2);

const houseBookPick = {
  title:  'Sapiens',
  author: 'Yuval Noah Harari',
  desc:   'A brief history of humankind — from foragers to rulers of the planet.',
  tags:   ['Non-Fiction','History','Anthropology'],
};

// ── LEADERBOARD ───────────────────────────────────────────────────────────
const leaderboard = [
  { name: 'Aditi Sharma', roll: '23f1000052@ds.study.iitm.ac.in', pts: 120 },
  { name: 'Rohan Verma',  roll: '22f1000119@ds.study.iitm.ac.in', pts: 110 },
  { name: 'Mehak Singh',  roll: '24f1000093@ds.study.iitm.ac.in', pts: 102 },
  { name: 'Dev Patel',    roll: '23f2000114@ds.study.iitm.ac.in', pts: 98  },
  { name: 'Priya Nair',   roll: '24f2000050@ds.study.iitm.ac.in', pts: 91  },
];
const memberColors = ['#c9a84c','#8bc8a8','#a8b8e8','#c87878','#78b878'];
function getMedalClass(i) { return ['gold','silver','bronze'][i] || ''; }

// ── COUNTDOWN ────────────────────────────────────────────────────────────
function updateCountdown() {
  const now = new Date(), target = new Date();
  target.setHours(21, 30, 0, 0);
  if (now >= target) target.setDate(target.getDate() + 1);
  const diff = target - now;
  const h = Math.floor(diff / 3600000);
  const m = Math.floor((diff % 3600000) / 60000);
  const s = Math.floor((diff % 60000) / 1000);
  countdownText.value = `${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}`;
}

function smoothScroll(hash) {
  const el = document.querySelector(hash);
  if (el) el.scrollIntoView({ behavior: 'smooth' });
}

function logout() {
  const p = document.querySelector('.members-lounge-page');
  if (p) { p.style.opacity = '0'; p.style.transition = 'opacity 0.5s'; }
  setTimeout(() => { localStorage.removeItem('sundarbans_auth_token'); router.push('/members'); }, 500);
}

// ── SCROLL REVEAL ────────────────────────────────────────────────────────
const vObserve = {
  mounted(el) {
    const obs = new IntersectionObserver((entries, o) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) { entry.target.classList.add('visible'); o.unobserve(entry.target); }
      });
    }, { threshold: 0.08, rootMargin: '0px 0px -30px 0px' });
    obs.observe(el);
  },
};

onMounted(() => {
  const token = localStorage.getItem('sundarbans_auth_token');
  if (!token) { router.push('/members'); return; }
  memberEmail.value = token;
  memberRoll.value  = token.split('@')[0] || token;
  updateCountdown();
  countdownInterval = setInterval(updateCountdown, 1000);
  setTimeout(() => { pageLoading.value = false; }, 1400);
  const p = document.querySelector('.members-lounge-page');
  if (p) { p.style.opacity = '0'; p.style.transition = 'opacity 0.6s'; setTimeout(() => { p.style.opacity = '1'; }, 100); }
});

onUnmounted(() => { if (countdownInterval) clearInterval(countdownInterval); });

// ── WHATSAPP REGIONS ─────────────────────────────────────────────────────
const waRegions = [
  { id: 'chd', name: 'Chandigarh',  form: 'https://forms.gle/roBd62dYk6829eYCA', coordinator: 'Aakash Rawal' },
  { id: 'hyd', name: 'Hyderabad',   form: 'https://forms.gle/d8QRQ5eXooDHL8Db6', coordinator: 'Dishi Gupta' },
  { id: 'lko', name: 'Lucknow',     form: 'https://forms.gle/poriXvnwuENkmiKF8', coordinator: 'Kartik Singh' },
  { id: 'kol', name: 'Kolkata',     form: 'https://forms.gle/z6qnTg58cvjjNtxP6', coordinator: 'Chanan Shaw' },
  { id: 'pat', name: 'Patna',       form: 'https://forms.gle/jK7W2USVNEj9ifi17', coordinator: 'Nivash Kumar' },
  { id: 'del', name: 'Delhi',       form: 'https://forms.gle/2gagK33ZhBzsqGz67', coordinator: 'Divy Prakash & Laksh Wadhawan' },
  { id: 'mum', name: 'Mumbai',      form: 'https://shorturl.at/EfRDc',            coordinator: 'Rushabh Kapse' },
  { id: 'che', name: 'Chennai',     form: 'https://forms.gle/uYzCs5WwngKm4zHH8', coordinator: null },
  { id: 'blr', name: 'Bengaluru',   form: 'https://forms.gle/G2qfFnE4hRPj682B9', coordinator: null },
];
</script>

<style scoped>
.members-lounge-page {
  --black:       #050707;
  --deep:        #090d09;
  --panel:       rgba(12,18,12,0.88);
  --border:      rgba(201,168,76,0.18);
  --border-soft: rgba(255,255,255,0.065);
  --gold:        #c9a84c;
  --gold-light:  #e8c97a;
  --gold-dim:    rgba(201,168,76,0.1);
  --cream:       #f0ebe0;
  --muted:       rgba(240,235,224,0.45);
  --subtle:      rgba(240,235,224,0.1);
  --radius:      14px;
  --radius-lg:   20px;

  background: var(--black);
  color: var(--cream);
  font-family: 'Outfit', sans-serif;
  min-height: 100vh;
  overflow-x: hidden;
  position: relative;
  width: 100%;
}

/* LOADER */
#page-loader {
  position: fixed; inset: 0; z-index: 9999;
  background: var(--black);
  display: flex; align-items: center; justify-content: center;
  flex-direction: column; gap: 20px;
}
.fade-slow-leave-active { transition: opacity 0.9s ease; }
.fade-slow-leave-to { opacity: 0; }
.loader-monogram {
  font-family: 'Cormorant Garamond', serif;
  font-size: 72px; font-weight: 300; color: var(--gold); line-height: 1;
  animation: mono-pulse 1.6s ease-in-out infinite;
}
@keyframes mono-pulse { 0%,100%{opacity:0.6;text-shadow:0 0 30px rgba(201,168,76,0.2)} 50%{opacity:1;text-shadow:0 0 60px rgba(201,168,76,0.6)} }
.loader-tagline { font-size: 10px; letter-spacing: 0.4em; text-transform: uppercase; color: var(--muted); }
.loader-bar { width: 140px; height: 1px; background: var(--border-soft); position: relative; overflow: hidden; }
.loader-fill { position: absolute; inset-y: 0; left: 0; width: 0; height: 100%; background: linear-gradient(to right, var(--gold), var(--gold-light)); animation: load-fill 1.3s cubic-bezier(0.4,0,0.2,1) forwards; }
@keyframes load-fill { to { width: 100%; } }

/* GRAIN */
.grain {
  position: fixed; inset: -200%; width: 400%; height: 400%;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)' opacity='0.05'/%3E%3C/svg%3E");
  opacity: 0.03; pointer-events: none; z-index: 1;
  animation: grain-drift 8s steps(10) infinite;
}
@keyframes grain-drift {
  0%,100%{transform:translate(0,0)} 10%{transform:translate(-2%,-3%)} 20%{transform:translate(-5%,2%)} 30%{transform:translate(3%,-4%)} 40%{transform:translate(-4%,5%)} 50%{transform:translate(-1%,-2%)} 60%{transform:translate(4%,3%)} 70%{transform:translate(3%,1%)} 80%{transform:translate(-3%,4%)} 90%{transform:translate(2%,-3%)}
}

/* HERO */
.hero {
  position: relative; min-height: 92vh;
  display: flex; align-items: center; justify-content: center;
  overflow: hidden; padding: 120px 60px 100px;
}
.hero-bg-grid {
  position: absolute; inset: 0; pointer-events: none;
  background-image: linear-gradient(rgba(201,168,76,0.04) 1px, transparent 1px), linear-gradient(90deg, rgba(201,168,76,0.04) 1px, transparent 1px);
  background-size: 60px 60px;
  mask-image: radial-gradient(ellipse 80% 70% at 50% 50%, black, transparent);
}
.hero-orb { position: absolute; border-radius: 50%; pointer-events: none; filter: blur(120px); }
.hero-orb-1 { width: 700px; height: 700px; background: radial-gradient(circle, rgba(35,80,35,0.28), transparent 70%); top: -250px; left: -200px; animation: orb-drift 16s ease-in-out infinite; }
.hero-orb-2 { width: 500px; height: 500px; background: radial-gradient(circle, rgba(201,168,76,0.1), transparent 70%); bottom: -100px; right: -150px; animation: orb-drift 11s ease-in-out infinite 4s; }
.hero-orb-3 { width: 300px; height: 300px; background: radial-gradient(circle, rgba(60,120,60,0.15), transparent 70%); top: 40%; right: 15%; animation: orb-drift 9s ease-in-out infinite 2s; }
@keyframes orb-drift { 0%,100%{transform:translate(0,0) scale(1)} 33%{transform:translate(-30px,25px) scale(1.07)} 66%{transform:translate(25px,-20px) scale(0.94)} }

.hero-content { position: relative; z-index: 2; text-align: center; max-width: 820px; }

.hero-badge {
  display: inline-flex; align-items: center; gap: 12px;
  padding: 9px 24px; background: var(--gold-dim); border: 1px solid var(--border);
  border-radius: 100px; font-size: 10px; letter-spacing: 0.3em; text-transform: uppercase;
  color: var(--gold); margin-bottom: 40px;
  animation: hero-reveal 0.8s cubic-bezier(0.16,1,0.3,1) 0.2s both;
}
.badge-dot { width: 5px; height: 5px; border-radius: 50%; background: #4caf50; box-shadow: 0 0 8px #4caf50; animation: badge-pulse 2.2s ease-in-out infinite; }
.badge-dot-r { animation-delay: 1.1s; }
@keyframes badge-pulse { 0%,100%{opacity:1} 50%{opacity:0.3} }

.hero-greeting {
  font-family: 'Cormorant Garamond', serif; font-weight: 300;
  font-size: clamp(44px, 6.5vw, 88px); line-height: 1.06; color: var(--cream); margin: 0;
  animation: hero-reveal 0.9s cubic-bezier(0.16,1,0.3,1) 0.35s both;
}
.hero-greeting em {
  font-style: italic;
  background: linear-gradient(130deg, var(--gold) 0%, var(--gold-light) 60%, var(--gold) 100%);
  -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;
  background-size: 200% 100%;
  animation: gold-shimmer 4s linear infinite;
}
@keyframes gold-shimmer { 0%{background-position:100% 0} 100%{background-position:-100% 0} }

.hero-sub { margin-top: 22px; font-size: 15px; font-weight: 300; letter-spacing: 0.05em; color: var(--muted); animation: hero-reveal 0.9s cubic-bezier(0.16,1,0.3,1) 0.5s both; }

.hero-stats { display: flex; align-items: center; justify-content: center; gap: 48px; margin-top: 60px; animation: hero-reveal 1s cubic-bezier(0.16,1,0.3,1) 0.65s both; }
.stat { text-align: center; }
.stat-val { font-family: 'Cormorant Garamond', serif; font-size: 38px; font-weight: 300; color: var(--gold-light); line-height: 1; }
.countdown-val { font-size: 28px; font-variant-numeric: tabular-nums; letter-spacing: 0.05em; }
.stat-lbl { font-size: 10px; letter-spacing: 0.22em; text-transform: uppercase; color: var(--muted); margin-top: 8px; }
.stat-sep { width: 1px; height: 52px; background: linear-gradient(to bottom, transparent, var(--border), transparent); }

.hero-cta-row { display: flex; align-items: center; justify-content: center; gap: 16px; margin-top: 52px; animation: hero-reveal 1s cubic-bezier(0.16,1,0.3,1) 0.8s both; }
.cta-primary { padding: 14px 36px; background: var(--gold); color: var(--black); border-radius: 100px; font-family: 'Outfit', sans-serif; font-size: 13px; font-weight: 600; letter-spacing: 0.12em; text-transform: uppercase; text-decoration: none; transition: all 0.25s; box-shadow: 0 4px 24px rgba(201,168,76,0.25); }
.cta-primary:hover { background: var(--gold-light); box-shadow: 0 6px 36px rgba(201,168,76,0.4); transform: translateY(-1px); }
.cta-secondary { padding: 14px 28px; background: transparent; border: 1px solid var(--border); border-radius: 100px; font-size: 13px; font-weight: 400; letter-spacing: 0.06em; color: var(--muted); text-decoration: none; transition: all 0.25s; }
.cta-secondary:hover { border-color: var(--gold); color: var(--gold); }

.hero-scroll-hint { position: absolute; bottom: 40px; left: 50%; transform: translateX(-50%); display: flex; flex-direction: column; align-items: center; gap: 10px; opacity: 0.4; animation: hero-reveal 1s cubic-bezier(0.16,1,0.3,1) 1.2s both; }
.scroll-line { width: 1px; height: 48px; background: linear-gradient(to bottom, var(--gold), transparent); animation: scroll-pulse 2.4s ease-in-out infinite; }
@keyframes scroll-pulse { 0%,100%{opacity:0.3} 50%{opacity:1} }
.hero-scroll-hint span { font-size: 9px; letter-spacing: 0.3em; text-transform: uppercase; color: var(--gold); }

@keyframes hero-reveal { from{opacity:0;transform:translateY(28px)} to{opacity:1;transform:translateY(0)} }

/* LAYOUT */
.container { max-width: 1320px; margin: 0 auto; padding: 0 60px; }
section { padding: 110px 0; }
.divider { height: 1px; background: linear-gradient(to right, transparent, var(--border), transparent); margin: 0 60px; }
.section-label { font-size: 10px; letter-spacing: 0.38em; text-transform: uppercase; color: var(--gold); display: flex; align-items: center; gap: 16px; margin-bottom: 18px; }
.section-label::before { content: ''; display: block; width: 28px; height: 1px; background: var(--gold); }
.section-title { font-family: 'Cormorant Garamond', serif; font-size: clamp(36px, 4vw, 54px); font-weight: 300; line-height: 1.1; margin: 0 0 12px; }
.section-desc { font-size: 14px; color: var(--muted); font-weight: 300; max-width: 520px; line-height: 1.7; margin: 0 0 52px; }

/* EVENT CARDS */
.events-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(290px,1fr)); gap: 18px; }
.event-card {
  background: var(--panel); border: 1px solid var(--border-soft); border-radius: var(--radius-lg);
  padding: 30px 28px; position: relative; overflow: hidden; backdrop-filter: blur(16px);
  opacity: 0; transform: translateY(32px); display: flex; flex-direction: column;
}
.event-card.visible {
  opacity: 1; transform: translateY(0);
  transition: opacity 0.65s cubic-bezier(0.16,1,0.3,1), transform 0.65s cubic-bezier(0.16,1,0.3,1), border-color 0.3s, box-shadow 0.3s;
}
.event-card::before { content: ''; position: absolute; inset: 0; background: linear-gradient(140deg, var(--gold-dim), transparent 60%); opacity: 0; transition: opacity 0.3s; }
.event-card:hover { border-color: var(--border); box-shadow: 0 24px 56px rgba(0,0,0,0.45); }
.event-card:hover::before { opacity: 1; }
.event-card.today-event { border-color: rgba(201,168,76,0.3); box-shadow: 0 0 0 1px rgba(201,168,76,0.1), 0 0 48px rgba(201,168,76,0.07); }
.event-card.past-event { opacity: 0.5 !important; }
.event-card-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 18px; }
.event-day-badge { font-size: 10px; letter-spacing: 0.22em; text-transform: uppercase; color: var(--gold); background: var(--gold-dim); border: 1px solid var(--border); padding: 4px 12px; border-radius: 100px; }
.event-icon { font-size: 28px; }
.event-card h3 { font-family: 'Cormorant Garamond', serif; font-size: 22px; font-weight: 400; margin: 0 0 10px; line-height: 1.2; }
.event-card p { font-size: 13px; color: var(--muted); line-height: 1.65; margin: 0; flex: 1; }
.event-card-footer { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin-top: 24px; flex-wrap: wrap; }
.event-time { display: flex; align-items: center; gap: 6px; font-size: 11px; color: var(--muted); letter-spacing: 0.04em; }

.join-btn {
  display: inline-flex; align-items: center; gap: 8px; padding: 9px 20px;
  background: transparent; border: 1px solid var(--border); border-radius: 100px;
  font-family: 'Outfit', sans-serif; font-size: 11px; font-weight: 500;
  letter-spacing: 0.14em; text-transform: uppercase; color: var(--gold);
  cursor: pointer; transition: all 0.22s; text-decoration: none; white-space: nowrap;
}
.join-btn:hover { background: var(--gold); color: var(--black); border-color: var(--gold); box-shadow: 0 4px 20px rgba(201,168,76,0.3); }
.join-btn svg { width: 12px; height: 12px; }
.join-btn.btn-disabled { opacity: 0.35; pointer-events: none; }

.today-tag { position: absolute; top: 14px; right: 14px; display: flex; align-items: center; gap: 6px; padding: 4px 12px; background: rgba(201,168,76,0.12); border: 1px solid rgba(201,168,76,0.32); border-radius: 100px; font-size: 9px; font-weight: 600; letter-spacing: 0.18em; text-transform: uppercase; color: var(--gold); }
.today-dot { width: 5px; height: 5px; border-radius: 50%; background: #5cdd6c; box-shadow: 0 0 6px #5cdd6c; animation: badge-pulse 1.8s ease-in-out infinite; }

/* NIGHT OWL */
.night-section { background: linear-gradient(180deg, transparent, rgba(15,25,15,0.4), transparent); }
.title-aside { display: block; font-family: 'Outfit', sans-serif; font-size: 14px; color: var(--muted); font-weight: 300; letter-spacing: 0.05em; margin-top: 6px; }
.reading-grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 18px; }
.reading-card {
  background: var(--panel); border: 1px solid var(--border-soft); border-radius: var(--radius-lg);
  padding: 36px 32px; position: relative; overflow: hidden;
  transition: border-color 0.3s, box-shadow 0.3s;
  opacity: 0; transform: translateY(30px); display: flex; flex-direction: column;
}
.reading-card.visible { opacity: 1; transform: translateY(0); transition: opacity 0.65s cubic-bezier(0.16,1,0.3,1), transform 0.65s cubic-bezier(0.16,1,0.3,1), border-color 0.3s; }
.reading-card:hover { border-color: var(--border); box-shadow: 0 24px 56px rgba(0,0,0,0.35); }
.reading-card-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 20px; }
.reading-icon { font-size: 42px; }
.room-live-chip { display: flex; align-items: center; gap: 6px; font-size: 10px; letter-spacing: 0.18em; text-transform: uppercase; color: var(--muted); padding: 4px 10px; border: 1px solid var(--border-soft); border-radius: 100px; }
.room-dot { width: 5px; height: 5px; border-radius: 50%; background: #5cdd6c; box-shadow: 0 0 6px #5cdd6c; animation: badge-pulse 2s ease-in-out infinite; }
.reading-card h3 { font-family: 'Cormorant Garamond', serif; font-size: 28px; font-weight: 300; margin: 0 0 10px; }
.reading-meta { display: flex; align-items: center; gap: 8px; margin-bottom: 14px; }
.meta-tag { font-size: 10px; letter-spacing: 0.18em; text-transform: uppercase; color: var(--gold); background: var(--gold-dim); border: 1px solid var(--border); padding: 3px 10px; border-radius: 100px; }
.meta-sep { color: var(--muted); font-size: 10px; }
.meta-text { font-size: 11px; color: var(--muted); }
.reading-card p { font-size: 13px; color: var(--muted); line-height: 1.65; margin: 0; flex: 1; }
.reading-card-footer { display: flex; align-items: center; justify-content: space-between; margin-top: 28px; gap: 12px; }
.reading-members { display: flex; align-items: center; gap: 10px; font-size: 11px; color: var(--muted); }
.member-dots { display: flex; }
.mdot { width: 18px; height: 18px; border-radius: 50%; border: 1.5px solid var(--black); margin-right: -5px; opacity: 0.85; }

.reading-pick-card { background: linear-gradient(145deg, rgba(20,28,20,0.95), rgba(12,18,12,0.88)); border-color: rgba(201,168,76,0.12); }
.pick-label { font-size: 9px; letter-spacing: 0.35em; text-transform: uppercase; color: var(--gold); margin-bottom: 28px; }
.pick-book { display: flex; gap: 24px; align-items: flex-start; flex: 1; }
.book-spine { width: 36px; min-height: 160px; background: linear-gradient(180deg, var(--gold), rgba(201,168,76,0.5)); border-radius: 3px 0 0 3px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; box-shadow: 3px 0 12px rgba(0,0,0,0.4), inset -2px 0 4px rgba(0,0,0,0.2); }
.book-spine span { writing-mode: vertical-rl; font-family: 'Cormorant Garamond', serif; font-size: 10px; color: var(--black); letter-spacing: 0.1em; font-weight: 600; transform: rotate(180deg); white-space: nowrap; overflow: hidden; max-height: 140px; text-overflow: ellipsis; }
.book-info { flex: 1; }
.book-title { font-family: 'Cormorant Garamond', serif; font-size: 22px; font-weight: 400; line-height: 1.2; margin-bottom: 4px; }
.book-author { font-size: 12px; color: var(--muted); margin-bottom: 12px; font-style: italic; }
.book-desc { font-size: 12px; color: var(--muted); line-height: 1.65; margin-bottom: 18px; }
.book-tags { display: flex; flex-wrap: wrap; gap: 6px; }
.book-tag { font-size: 9px; letter-spacing: 0.14em; text-transform: uppercase; color: var(--gold); border: 1px solid var(--border); padding: 3px 8px; border-radius: 4px; }

/* LEADERBOARD */
.leaderboard-wrap { display: flex; flex-direction: column; gap: 40px; }
.podium { display: flex; align-items: flex-end; justify-content: center; gap: 12px; opacity: 0; transform: translateY(24px); }
.podium.visible { opacity: 1; transform: translateY(0); transition: opacity 0.7s cubic-bezier(0.16,1,0.3,1), transform 0.7s cubic-bezier(0.16,1,0.3,1); }
.podium-slot { display: flex; flex-direction: column; align-items: center; gap: 8px; }
.podium-crown { font-size: 20px; color: var(--gold); animation: crown-float 3s ease-in-out infinite; }
@keyframes crown-float { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-5px)} }
.podium-avatar { width: 52px; height: 52px; border-radius: 50%; display: grid; place-items: center; font-family: 'Cormorant Garamond', serif; font-size: 22px; font-weight: 400; border: 2px solid var(--border); }
.gold-av   { background: rgba(201,168,76,0.18); border-color: var(--gold); color: var(--gold-light); }
.silver-av { background: rgba(168,184,200,0.12); border-color: #a8b8c8; color: #c0cedd; }
.bronze-av { background: rgba(200,160,112,0.12); border-color: #c8a070; color: #ddb87a; }
.podium-name { font-size: 13px; font-weight: 500; color: var(--cream); }
.podium-pts { font-family: 'Cormorant Garamond', serif; font-size: 20px; color: var(--gold-light); }
.podium-pts span { font-size: 11px; color: var(--muted); margin-left: 2px; }
.podium-block { width: 100px; display: grid; place-items: center; font-family: 'Cormorant Garamond', serif; font-size: 16px; font-weight: 300; border-radius: 6px 6px 0 0; border: 1px solid rgba(255,255,255,0.05); border-bottom: none; }
.podium-block-1 { height: 80px; background: linear-gradient(180deg, rgba(201,168,76,0.25), rgba(201,168,76,0.08)); border-color: rgba(201,168,76,0.2); color: var(--gold); }
.podium-block-2 { height: 56px; background: rgba(168,184,200,0.1); border-color: rgba(168,184,200,0.15); color: #a8b8c8; }
.podium-block-3 { height: 42px; background: rgba(200,160,112,0.1); border-color: rgba(200,160,112,0.15); color: #c8a070; }

.leaderboard-list { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 6px; }
.leaderboard-item { display: flex; align-items: center; gap: 18px; padding: 18px 24px; border-radius: var(--radius); border: 1px solid transparent; transition: background 0.22s, border-color 0.22s; opacity: 0; transform: translateX(-20px); }
.leaderboard-item.visible { opacity: 1; transform: translateX(0); transition: opacity 0.5s cubic-bezier(0.16,1,0.3,1), transform 0.5s cubic-bezier(0.16,1,0.3,1), background 0.22s, border-color 0.22s; }
.leaderboard-item:hover { background: var(--gold-dim); border-color: var(--border); }
.leaderboard-item.is-you { background: rgba(201,168,76,0.06); border-color: var(--border); }

.lb-rank { font-family: 'Cormorant Garamond', serif; font-size: 20px; min-width: 32px; text-align: center; color: var(--muted); }
.lb-rank.gold { color: var(--gold); }
.lb-rank.silver { color: #a8b8c8; }
.lb-rank.bronze { color: #c8a070; }
.lb-avatar { width: 36px; height: 36px; border-radius: 50%; display: grid; place-items: center; font-family: 'Cormorant Garamond', serif; font-size: 16px; color: var(--black); flex-shrink: 0; }
.lb-info { flex: 1; min-width: 0; }
.lb-name { font-size: 15px; font-weight: 500; display: flex; align-items: center; gap: 8px; }
.lb-roll { font-size: 11px; color: var(--muted); margin-top: 2px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.you-tag { font-size: 9px; letter-spacing: 0.16em; text-transform: uppercase; color: var(--black); background: var(--gold); padding: 2px 7px; border-radius: 100px; }
.lb-right { display: flex; flex-direction: column; align-items: flex-end; gap: 6px; min-width: 130px; }
.lb-bar-wrap { width: 120px; height: 2px; background: var(--border-soft); border-radius: 2px; overflow: hidden; }
.lb-bar { height: 100%; background: linear-gradient(to right, var(--gold), var(--gold-light)); border-radius: 2px; }
.lb-pts-row { display: flex; align-items: baseline; gap: 4px; }
.lb-pts { font-family: 'Cormorant Garamond', serif; font-size: 24px; font-weight: 300; color: var(--gold-light); }
.lb-pts-lbl { font-size: 10px; letter-spacing: 0.12em; text-transform: uppercase; color: var(--muted); }
.lb-footer-note { font-size: 12px; color: var(--muted); line-height: 1.65; text-align: center; padding-top: 16px; border-top: 1px solid var(--border-soft); }

/* SCROLL REVEAL */
.reveal { opacity: 0; transform: translateY(24px); transition: none; }
.reveal.visible { opacity: 1; transform: translateY(0); transition: opacity 0.7s cubic-bezier(0.16,1,0.3,1), transform 0.7s cubic-bezier(0.16,1,0.3,1); }

/* WHATSAPP COMMUNITY */
.wa-main-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 32px;
  background: var(--panel);
  border: 1px solid rgba(37,211,102,0.18);
  border-radius: var(--radius-lg);
  padding: 36px 40px;
  margin-bottom: 52px;
  position: relative;
  overflow: hidden;
  flex-wrap: wrap;
}
.wa-main-card::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(120deg, rgba(37,211,102,0.05), transparent 55%);
  pointer-events: none;
}
.wa-main-left {
  display: flex;
  align-items: flex-start;
  gap: 24px;
  flex: 1;
  min-width: 0;
}
.wa-main-label {
  font-size: 9px;
  letter-spacing: 0.35em;
  text-transform: uppercase;
  color: #25d366;
  margin-bottom: 6px;
}
.wa-main-title {
  font-family: 'Cormorant Garamond', serif;
  font-size: 32px;
  font-weight: 300;
  margin: 0 0 8px;
  line-height: 1.1;
}
.wa-main-desc {
  font-size: 13px;
  color: var(--muted);
  line-height: 1.65;
  margin: 0;
  max-width: 480px;
}

.wa-regions-header {
  margin-bottom: 24px;
}

.whatsapp-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 14px;
}
.whatsapp-card {
  background: var(--panel);
  border: 1px solid var(--border-soft);
  border-radius: var(--radius);
  padding: 24px 22px;
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  gap: 0;
  opacity: 0;
  transform: translateY(24px);
  transition: border-color 0.3s, box-shadow 0.3s;
}
.whatsapp-card.visible {
  opacity: 1;
  transform: translateY(0);
  transition: opacity 0.55s cubic-bezier(0.16,1,0.3,1), transform 0.55s cubic-bezier(0.16,1,0.3,1), border-color 0.3s, box-shadow 0.3s;
}
.whatsapp-card:hover {
  border-color: rgba(37,211,102,0.2);
  box-shadow: 0 16px 40px rgba(0,0,0,0.35);
}

.wa-card-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}
.wa-icon-wrap {
  width: 38px;
  height: 38px;
  border-radius: 10px;
  background: rgba(37,211,102,0.1);
  border: 1px solid rgba(37,211,102,0.18);
  display: grid;
  place-items: center;
  flex-shrink: 0;
}
.wa-icon-region { background: rgba(37,211,102,0.08); border-color: rgba(37,211,102,0.14); }
.wa-icon { width: 18px; height: 18px; color: #25d366; }
.wa-region-badge {
  font-size: 9px;
  letter-spacing: 0.28em;
  text-transform: uppercase;
  color: var(--muted);
  padding: 3px 10px;
  border: 1px solid var(--border-soft);
  border-radius: 100px;
}

.wa-title {
  font-family: 'Cormorant Garamond', serif;
  font-size: 22px;
  font-weight: 300;
  margin: 0 0 8px;
  line-height: 1.2;
  color: var(--cream);
}
.wa-coordinator {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: var(--muted);
  margin-bottom: 20px;
  flex: 1;
}
.wa-coordinator svg { width: 13px; height: 13px; flex-shrink: 0; opacity: 0.6; }

.wa-join-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 9px 18px;
  background: rgba(37,211,102,0.08);
  border: 1px solid rgba(37,211,102,0.2);
  border-radius: 100px;
  font-family: 'Outfit', sans-serif;
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: #25d366;
  cursor: pointer;
  transition: all 0.22s;
  text-decoration: none;
  align-self: flex-start;
  white-space: nowrap;
}
.wa-join-btn svg { width: 13px; height: 13px; flex-shrink: 0; }
.wa-join-btn:hover {
  background: #25d366;
  color: var(--black);
  border-color: #25d366;
  box-shadow: 0 4px 18px rgba(37,211,102,0.28);
  transform: translateY(-1px);
}
.wa-join-main {
  padding: 12px 28px;
  font-size: 11px;
  flex-shrink: 0;
}

@media (max-width: 1100px) {
  .whatsapp-grid { grid-template-columns: repeat(3, 1fr); }
}
@media (max-width: 860px) {
  .whatsapp-grid { grid-template-columns: 1fr 1fr; }
  .wa-main-card { flex-direction: column; align-items: flex-start; }
}
@media (max-width: 500px) {
  .whatsapp-grid { grid-template-columns: 1fr; }
}

/* RESPONSIVE */
@media (max-width: 1100px) {
  .reading-grid { grid-template-columns: 1fr 1fr; }
  .reading-pick-card { grid-column: 1 / -1; }
}
@media (max-width: 900px) {
  .container { padding: 0 24px; }
  .hero { padding: 90px 24px 80px; }
  section { padding: 76px 0; }
  .divider { margin: 0 24px; }
  .hero-stats { gap: 24px; flex-wrap: wrap; }
  .stat-sep { display: none; }
  .reading-grid { grid-template-columns: 1fr; }
  .podium { display: none; }
}
@media (max-width: 600px) {
  .events-grid { grid-template-columns: 1fr; }
  .hero-cta-row { flex-direction: column; }
  .hero-greeting { font-size: 38px; }
}
</style>
