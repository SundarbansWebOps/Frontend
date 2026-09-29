<template>
  <main class="home-page">
    <!-- ============ 1. Hero Section ============ -->
    <section class="hero-section" aria-labelledby="hero-title">
      <div class="hero-container">
        <div class="hero-main">
          <div class="hero-badge">
            <img :src="CREST" alt="IIT Madras Crest" class="crest-img" width="28" height="28" />
            <span>IIT Madras BS Degree · Sundarbans House</span>
          </div>

          <h1 id="hero-title" class="hero-title">
            The Academic &amp; Community Hub of Sundarbans House
          </h1>

          <p class="hero-desc">
            Past papers, lecture notes, student events, and regional chapters for IIT Madras BS
            learners.
          </p>

          <div class="hero-actions">
            <button type="button" class="btn btn-primary" @click="nav.go('resources')">
              <span>Browse Resources</span>
              <LineIcon name="arrow" />
            </button>
            <button type="button" class="btn btn-secondary" @click="nav.go('events')">
              <LineIcon name="cal" />
              <span>Explore Events</span>
            </button>
          </div>

          <!-- Quick Course Search Bar -->
          <div class="hero-search-wrap">
            <div class="search-box">
              <LineIcon name="book" />
              <input
                v-model="searchQuery"
                type="search"
                autocomplete="off"
                spellcheck="false"
                placeholder="Search courses, past papers, notes (e.g. Maths 1, DBMS, DL)..."
                aria-label="Search courses, past papers, and notes"
                @keydown.enter="handleSearchSubmit"
              />
              <button
                v-if="searchQuery.trim()"
                type="button"
                class="search-clear"
                aria-label="Clear search"
                @click="searchQuery = ''"
              >
                <LineIcon name="close" />
              </button>
              <button
                v-if="searchQuery.trim()"
                type="button"
                class="search-submit"
                @click="handleSearchSubmit"
              >
                Search
              </button>
            </div>

            <!-- Instant search results dropdown -->
            <div v-if="searchHits.length" class="search-results" role="listbox">
              <div
                v-for="hit in searchHits"
                :key="hit.code"
                class="search-hit"
                role="option"
                tabindex="0"
                @click="(e) => openCourse(hit.code, hit, e)"
                @keydown.enter="(e) => openCourse(hit.code, hit, e)"
              >
                <div class="hit-info">
                  <strong class="hit-name">{{ byCode[hit.code]?.short || hit.code }}</strong>
                  <span class="hit-code mono">{{ hit.code }}</span>
                </div>
                <div class="hit-meta">
                  <span class="hit-count">{{ hitCountText(hit) }}</span>
                  <LineIcon name="arrow" />
                </div>
              </div>
            </div>

            <!-- Search chips -->
            <div class="search-chips">
              <span class="chips-label">Popular:</span>
              <button
                v-for="chip in POPULAR_SEARCHES"
                :key="chip.q"
                type="button"
                class="chip"
                @click="applySearchChip(chip)"
              >
                {{ chip.label }}
              </button>
            </div>
          </div>
        </div>

        <!-- Hero Companion: Live Vitals Bento -->
        <aside class="hero-vitals" aria-label="House metrics and term dates">
          <div class="vitals-header">
            <div class="vitals-title-group">
              <span class="vitals-sub">Academic &amp; Student Operations</span>
              <h2 class="vitals-heading">House Vitals</h2>
            </div>
            <span class="status-pill">Active House</span>
          </div>

          <div class="stats-grid">
            <div class="stat-card">
              <span class="stat-num mono">{{ courses.length }}</span>
              <span class="stat-label">Courses Indexed</span>
            </div>
            <div class="stat-card">
              <span class="stat-num mono">{{ totalPapers }}</span>
              <span class="stat-label">Past Exam Papers</span>
            </div>
            <div class="stat-card">
              <span class="stat-num mono">{{ totalNotes }}</span>
              <span class="stat-label">Verified Study Notes</span>
            </div>
            <div class="stat-card">
              <span class="stat-num mono">{{ regions.length }}</span>
              <span class="stat-label">Regional Chapters</span>
            </div>
          </div>

          <div v-if="nextExam" class="exam-alert">
            <div class="alert-icon">
              <LineIcon name="cal" />
            </div>
            <div class="alert-content">
              <strong>Upcoming Academic Milestone</strong>
              <p>{{ nextExam.label }} scheduled for {{ formatExamDate(nextExam.date) }}.</p>
            </div>
            <button
              type="button"
              class="alert-link"
              aria-label="View relevant past papers"
              @click="findExamPyqs(nextExam.exam)"
            >
              Past Papers
            </button>
          </div>
        </aside>
      </div>
    </section>

    <!-- ============ 2. Academic Resources & Study Hub ============ -->
    <section id="resources" class="section-container" aria-labelledby="resources-heading">
      <div class="section-head">
        <div>
          <h2 id="resources-heading" class="section-title">Academic Resources</h2>
          <p class="section-desc">
            Organized course materials across all degree levels with direct access to exam papers
            and lecture notes.
          </p>
        </div>
        <button type="button" class="btn btn-secondary" @click="nav.go('resources')">
          <span>Open Full Course Map</span>
          <LineIcon name="arrow" />
        </button>
      </div>

      <!-- Pinned Courses Bar (if student has pinned courses) -->
      <div v-if="store.mine.length" class="pinned-bar">
        <span class="pinned-label">Your Pinned Courses:</span>
        <div class="pinned-chips">
          <button
            v-for="code in store.mine"
            :key="code"
            type="button"
            class="pinned-chip"
            @click="(e) => openCourse(code, {}, e)"
          >
            <b>{{ byCode[code]?.short || code }}</b>
            <span class="mono">{{ code }}</span>
          </button>
        </div>
      </div>

      <!-- Level Filter Tabs -->
      <div class="level-tabs" role="tablist" aria-label="Course levels">
        <button
          v-for="tab in LEVEL_TABS"
          :key="tab.id"
          type="button"
          role="tab"
          class="level-tab"
          :class="{ active: activeLevel === tab.id }"
          :aria-selected="activeLevel === tab.id"
          @click="activeLevel = tab.id"
        >
          <span>{{ tab.label }}</span>
          <span class="tab-count mono">{{ getCoursesByLevel(tab.id).length }}</span>
        </button>
      </div>

      <!-- Course Cards Grid -->
      <div class="courses-grid">
        <article v-for="course in displayedCourses" :key="course.code" class="course-card">
          <div class="course-card-top">
            <div class="course-identity">
              <span class="course-code mono">{{ course.code }}</span>
              <span class="course-level-tag">{{ getTrackLabel(course.track) }}</span>
            </div>
            <button
              type="button"
              class="pin-btn"
              :class="{ pinned: isMine(course.code) }"
              :aria-label="isMine(course.code) ? 'Unpin course' : 'Pin course'"
              @click="togglePin(course.code)"
            >
              <LineIcon name="pin" />
            </button>
          </div>

          <h3 class="course-title">{{ course.name }}</h3>

          <div class="course-metrics">
            <span class="metric-item">
              <LineIcon name="book" />
              <span>{{ course.pyqs.length }} Past Papers</span>
            </span>
            <span class="metric-item">
              <LineIcon name="portal" />
              <span>{{ course.notes.length }} Note Sets</span>
            </span>
          </div>

          <div class="course-card-actions">
            <button
              type="button"
              class="btn-open-course"
              @click="(e) => openCourse(course.code, { tab: 'pyqs' }, e)"
            >
              <span>View Past Papers</span>
              <LineIcon name="arrow" />
            </button>
            <button
              type="button"
              class="btn-open-notes"
              @click="(e) => openCourse(course.code, { tab: 'notes' }, e)"
            >
              Notes
            </button>
          </div>
        </article>
      </div>

      <div class="section-footer-action">
        <button type="button" class="btn btn-secondary" @click="nav.go('resources')">
          <span>Search all {{ courses.length }} courses in the Study Corner</span>
          <LineIcon name="arrow" />
        </button>
      </div>
    </section>

    <!-- ============ 3. Events & Wings Showcase ============ -->
    <section id="events" class="section-container" aria-labelledby="events-heading">
      <div class="section-head">
        <div>
          <h2 id="events-heading" class="section-title">House Events &amp; Wings</h2>
          <p class="section-desc">
            Competitions, cultural evenings, tech workshops, and guest talks curated by our student
            committees.
          </p>
        </div>
        <button type="button" class="btn btn-secondary" @click="nav.go('events')">
          <span>View All {{ events.length }} Events</span>
          <LineIcon name="arrow" />
        </button>
      </div>

      <!-- Wing Filter Pills -->
      <div class="wing-filters" role="tablist" aria-label="Event wings">
        <button
          type="button"
          class="wing-filter-btn"
          :class="{ active: activeWing === 'all' }"
          @click="activeWing = 'all'"
        >
          All Wings
        </button>
        <button
          v-for="(meta, key) in WINGS"
          :key="key"
          type="button"
          class="wing-filter-btn"
          :class="[`w-${key}`, { active: activeWing === key }]"
          @click="activeWing = key"
        >
          {{ meta.label }}
        </button>
      </div>

      <!-- Events Presentation: Spotlight + Recent Grid -->
      <div class="events-layout">
        <!-- Spotlight Event Card -->
        <article v-if="spotlightEvent" class="event-spotlight-card">
          <div v-if="spotlightEvent.image" class="spotlight-image-wrap">
            <img
              :src="img.card(spotlightEvent.image)"
              :alt="spotlightEvent.title"
              loading="lazy"
              decoding="async"
              class="spotlight-img"
            />
          </div>
          <div class="spotlight-body">
            <div class="spotlight-meta">
              <span class="wing-tag" :class="`w-${spotlightEvent.wing}`">
                {{ WINGS[spotlightEvent.wing]?.label || spotlightEvent.wing }}
              </span>
              <span class="date-badge mono">{{ formatEventDate(spotlightEvent) }}</span>
            </div>
            <h3 class="spotlight-title">{{ spotlightEvent.title }}</h3>
            <p class="spotlight-desc">{{ spotlightEvent.desc }}</p>
            <div class="spotlight-foot">
              <span v-if="spotlightEvent.attendees" class="attendee-count">
                <LineIcon name="people" />
                <span>{{ spotlightEvent.attendees }} Attendees</span>
              </span>
              <button type="button" class="btn btn-secondary btn-sm" @click="nav.go('events')">
                <span>Event Archive</span>
                <LineIcon name="arrow" />
              </button>
            </div>
          </div>
        </article>

        <!-- Recent Events Column -->
        <div class="recent-events-list">
          <article v-for="event in recentEvents" :key="event.id" class="recent-event-card">
            <div class="recent-event-header">
              <span class="wing-indicator" :class="`w-${event.wing}`" />
              <span class="wing-name">{{ WINGS[event.wing]?.label || event.wing }}</span>
              <span class="event-date-text mono">{{ formatEventDate(event) }}</span>
            </div>
            <h4 class="recent-event-title">{{ event.title }}</h4>
            <p class="recent-event-snippet">{{ truncateText(event.desc, 120) }}</p>
          </article>
        </div>
      </div>
    </section>

    <!-- ============ 4. Regional Chapters Network ============ -->
    <section id="house" class="section-container" aria-labelledby="regions-heading">
      <div class="section-head">
        <div>
          <h2 id="regions-heading" class="section-title">Regional Chapters</h2>
          <p class="section-desc">
            Nine regional hubs across India connecting students through in-person meetups, hack
            sessions, and celebrations.
          </p>
        </div>
        <button type="button" class="btn btn-secondary" @click="nav.go('house', 'regions')">
          <span>Explore Regional Chapters</span>
          <LineIcon name="arrow" />
        </button>
      </div>

      <div class="regions-grid">
        <article
          v-for="region in regions"
          :key="region.id"
          class="region-card"
          tabindex="0"
          @click="nav.go('house', 'regions')"
          @keydown.enter="nav.go('house', 'regions')"
        >
          <div class="region-top">
            <span class="region-pin">
              <LineIcon name="pin" />
            </span>
            <span class="region-meetup-count mono">{{ region.items.length }} Meetups</span>
          </div>
          <h3 class="region-city">{{ region.name }}</h3>
          <p class="region-info">
            {{
              region.items.length > 0
                ? `${region.items.length} community gatherings hosted`
                : 'Active regional hub'
            }}
          </p>
          <div class="region-link">
            <span>View Meetup Log</span>
            <LineIcon name="arrow" />
          </div>
        </article>
      </div>
    </section>

    <!-- ============ 5. Upper House Council (UHC) Leadership ============ -->
    <section id="teams" class="section-container" aria-labelledby="council-heading">
      <div class="section-head">
        <div>
          <h2 id="council-heading" class="section-title">House Leadership &amp; Crew</h2>
          <p class="section-desc">
            Elected student representatives steering academic operations, community wings, and
            student welfare.
          </p>
        </div>
        <button type="button" class="btn btn-secondary" @click="nav.go('teams')">
          <span>View Full House Roster</span>
          <LineIcon name="arrow" />
        </button>
      </div>

      <div class="council-grid">
        <article v-for="leader in upper" :key="leader.id" class="council-card">
          <div class="council-photo-wrap">
            <img
              v-if="leader.img"
              :src="portrait.card(leader.img)"
              :alt="leader.name"
              loading="lazy"
              decoding="async"
              class="council-photo"
            />
            <div v-else class="council-photo-fallback">
              <LineIcon name="people" />
            </div>
          </div>
          <div class="council-body">
            <h3 class="council-name">{{ leader.name }}</h3>
            <span class="council-role">{{ leader.role }}</span>
            <span class="council-house-tag">Upper House Council</span>
            <!-- UHC Social Media Buttons -->
            <div v-if="leader.links && leader.links.length" class="council-socials">
              <a
                v-for="link in leader.links"
                :key="link.kind"
                :href="link.href"
                target="_blank"
                rel="noopener noreferrer"
                class="council-social-btn"
                :class="`social-${link.kind.toLowerCase()}`"
                :aria-label="`${leader.name} on ${link.kind}`"
                :title="`${leader.name} on ${link.kind}`"
              >
                <LineIcon
                  :name="
                    link.kind === 'LinkedIn'
                      ? 'linkedin'
                      : link.kind === 'X'
                        ? 'x'
                        : link.kind.toLowerCase()
                  "
                />
              </a>
            </div>
          </div>
        </article>
      </div>

      <!-- House Crew Structure (Crew Map: Helm, Oars, Drum, Hull) -->
      <div class="crew-structure-section">
        <div class="crew-section-head">
          <h3 class="crew-section-title">House Crew Breakdown</h3>
          <p class="crew-section-subtitle">
            How Sundarbans House is organized across four collaborative tiers.
          </p>
        </div>
        <div class="crew-map-grid">
          <article
            v-for="crew in CREWMAP"
            :key="crew.n"
            class="crew-card"
            tabindex="0"
            role="button"
            @click="nav.go(crew.link)"
            @keydown.enter="nav.go(crew.link)"
          >
            <div class="crew-card-head">
              <span class="crew-num mono">{{ crew.n }}</span>
              <span class="crew-where">{{ crew.where }}</span>
              <span class="crew-count mono">{{ crew.count }}</span>
            </div>
            <h4 class="crew-who">{{ crew.who }}</h4>
            <p class="crew-what">{{ crew.what }}</p>
          </article>
        </div>
      </div>

      <div class="teams-banner">
        <div class="teams-banner-text">
          <strong>Looking for community wings and crew teams?</strong>
          <p>
            Sundarbans House is supported by Lower House regional coordinators, technical builders,
            and cultural curators.
          </p>
        </div>
        <button type="button" class="btn btn-secondary" @click="nav.go('teams', 'how')">
          <span>See How Teams Work</span>
          <LineIcon name="arrow" />
        </button>
      </div>
    </section>

    <!-- ============ 6. Student Quick Access & Portal Integration ============ -->
    <section class="section-container" aria-labelledby="utilities-heading">
      <div class="section-head">
        <div>
          <h2 id="utilities-heading" class="section-title">Student Access &amp; Portals</h2>
          <p class="section-desc">
            Direct shortcuts to verified certificate validation, the official IITM student portal,
            official grading documents, and community channels.
          </p>
        </div>
      </div>

      <!-- Academic Policy & Term Deadlines Summary (from Sep 2026 Student Document) -->
      <div class="term-brief-card">
        <div class="term-brief-head">
          <div class="term-brief-title-wrap">
            <span class="term-chip mono">Sep 2026 Term</span>
            <h3 class="term-brief-title">Academic Schedule &amp; Grading Rules</h3>
          </div>
          <a
            href="https://docs.google.com/document/d/e/2PACX-1vT_FeqnTq0Br4sUaN7OYAmj1B9MwjchyTEed1Bh5FkZvi5NyIMeAvvkuttostVsJBPjZcs3SjjEfiho/pub"
            target="_blank"
            rel="noopener noreferrer"
            class="btn btn-secondary btn-sm"
          >
            <span>Full Document</span>
            <LineIcon name="arrow" />
          </a>
        </div>

        <div class="term-milestones-row">
          <div class="milestone-item">
            <span class="milestone-name">Quiz 1 (In Person)</span>
            <span class="milestone-date mono">Sun, 15 Nov 2026</span>
            <span class="milestone-note">Centres across India &amp; abroad</span>
          </div>
          <div class="milestone-item">
            <span class="milestone-name">OPPE 1 (Online Proctored)</span>
            <span class="milestone-date mono">Sun, 22 Nov 2026</span>
            <span class="milestone-note">Requires SCT completion</span>
          </div>
          <div class="milestone-item highlight">
            <span class="milestone-name">End Term Eligibility Cutoff</span>
            <span class="milestone-date mono">Wed, 25 Nov 2026</span>
            <span class="milestone-note">Best 5 of 7 weeks average &gt;= 40/100</span>
          </div>
          <div class="milestone-item">
            <span class="milestone-name">Quiz 2 (In Person)</span>
            <span class="milestone-date mono">Sat, 5 Dec 2026</span>
            <span class="milestone-note">Centres across India &amp; abroad</span>
          </div>
          <div class="milestone-item">
            <span class="milestone-name">OPPE 2 (Days 1 &amp; 2)</span>
            <span class="milestone-date mono">20 Dec 2026 &amp; 3 Jan 2027</span>
            <span class="milestone-note">Syllabus Weeks 1 to 8</span>
          </div>
          <div class="milestone-item">
            <span class="milestone-name">End Term Exam</span>
            <span class="milestone-date mono">Sun, 10 Jan 2027</span>
            <span class="milestone-note">In person centres, 2 sessions</span>
          </div>
        </div>

        <div class="policy-pills-row">
          <div class="policy-pill">
            <strong>GAA Weightage:</strong>
            <span>Foundation = 0 (tested in Quizzes/ET) · Diploma = 5 marks</span>
          </div>
          <div class="policy-pill">
            <strong>Bonus Marks:</strong>
            <span>Up to 2 marks for mocks (&gt;= 40) + up to 3 for extra course activities</span>
          </div>
          <div class="policy-pill">
            <strong>Discourse Badges:</strong>
            <span>Badge 1 (4h read time) · Badge 2 (8h) · Badge 3 (12h+)</span>
          </div>
        </div>
      </div>

      <div class="utilities-grid">
        <article class="utility-card">
          <div class="utility-icon">
            <LineIcon name="book" />
          </div>
          <h3 class="utility-title">Sep 2026 Grading Document</h3>
          <p class="utility-desc">
            Official IITM grading document detailing exam dates, formula calculations, bonus marks,
            and OPPE eligibility criteria.
          </p>
          <a
            href="https://docs.google.com/document/d/e/2PACX-1vT_FeqnTq0Br4sUaN7OYAmj1B9MwjchyTEed1Bh5FkZvi5NyIMeAvvkuttostVsJBPjZcs3SjjEfiho/pub"
            target="_blank"
            rel="noopener noreferrer"
            class="utility-btn"
          >
            <span>Read Official Document</span>
            <LineIcon name="arrow" />
          </a>
        </article>

        <article class="utility-card">
          <div class="utility-icon">
            <LineIcon name="cert" />
          </div>
          <h3 class="utility-title">OPPE SCT Setup Guide</h3>
          <p class="utility-desc">
            Standard Operating Procedure for completing the mandatory System Compatibility Test
            before OPPE 1 and OPPE 2.
          </p>
          <a
            href="https://docs.google.com/document/d/e/2PACX-1vS4Hhh4MsKD2WL8_D26Vw2WJKw0CBtPihZyKrnEM_kefRXm_O75GqTcJA6lR0X_xCiVL5gUi5y6_bjw/pub"
            target="_blank"
            rel="noopener noreferrer"
            class="utility-btn"
          >
            <span>Open SCT SoP Guide</span>
            <LineIcon name="arrow" />
          </a>
        </article>

        <article class="utility-card">
          <div class="utility-icon">
            <LineIcon :name="PORTAL.icon" />
          </div>
          <h3 class="utility-title">IITM Student Portal</h3>
          <p class="utility-desc">
            Access your primary IIT Madras BS degree portal for course registration, grades, and
            official submissions.
          </p>
          <a :href="PORTAL.href" target="_blank" rel="noopener noreferrer" class="utility-btn">
            <span>Launch Student Portal</span>
            <LineIcon name="arrow" />
          </a>
        </article>

        <article class="utility-card">
          <div class="utility-icon">
            <LineIcon name="seal" />
          </div>
          <h3 class="utility-title">Verify Certificate</h3>
          <p class="utility-desc">
            Validate authentic event participation and council certificates issued under Sundarbans
            House.
          </p>
          <RouterLink to="/verify-certificate" class="utility-btn">
            <span>Verify Credential</span>
            <LineIcon name="arrow" />
          </RouterLink>
        </article>

        <article class="utility-card">
          <div class="utility-icon">
            <LineIcon name="wa" />
          </div>
          <h3 class="utility-title">WhatsApp Announcements</h3>
          <p class="utility-desc">
            Join the verified official broadcast channel for instant meetup updates, reminders, and
            house news.
          </p>
          <a :href="WHATSAPP" target="_blank" rel="noopener noreferrer" class="utility-btn">
            <span>Join Official Channel</span>
            <LineIcon name="arrow" />
          </a>
        </article>

        <article class="utility-card">
          <div class="utility-icon">
            <LineIcon name="door" />
          </div>
          <h3 class="utility-title">Members Lounge</h3>
          <p class="utility-desc">
            Access the house lounge for study rooms, collaborative discussions, and community
            achievements.
          </p>
          <RouterLink to="/lounge" class="utility-btn">
            <span>Enter Lounge</span>
            <LineIcon name="arrow" />
          </RouterLink>
        </article>
      </div>
    </section>
  </main>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import { RouterLink } from 'vue-router';
import { animate, stagger } from 'animejs';
import CREST from '../assets/crest.webp';
import LineIcon from '../components/site/LineIcon.vue';
import { courses, byCode, nextExam, TOOLS, WHATSAPP } from '../lib/courses.js';
import { events, WINGS, MONTH } from '../lib/events.js';
import { regions, upper, lower, portrait } from '../lib/house.js';
import { COMMUNITIES, CREW } from '../data/teams.js';
import { isMine, nav, openCourse, search, store, togglePin } from '../lib/store.js';

const PORTAL = TOOLS[0];

// ---- Totals & Stats -------------------------------------------------------------
const totalPapers = computed(() => courses.reduce((acc, c) => acc + (c.pyqs?.length || 0), 0));
const totalNotes = computed(() => courses.reduce((acc, c) => acc + (c.notes?.length || 0), 0));

// ---- Crew Map (Original House Structure) ----------------------------------------
const CREWMAP = [
  {
    n: 1,
    where: 'At the helm',
    who: 'Upper House Council',
    count: upper.length,
    what: `${upper.map((p) => p.role).join(', ')}: steering academic and executive operations.`,
    link: 'teams',
  },
  {
    n: 2,
    where: 'At the oars',
    who: 'Lower House Council',
    count: lower.length,
    what: 'Regional coordinators across 9 hubs pulling together.',
    link: 'house',
  },
  {
    n: 3,
    where: 'On the drum',
    who: 'Communities',
    count: COMMUNITIES.length,
    what: 'Cultural, Technical, and E-Sports setting the pace with tournaments and workshops.',
    link: 'teams',
  },
  {
    n: 4,
    where: 'In the hull',
    who: 'Technical & Creative Crew',
    count: CREW.length,
    what: 'PR & Outreach, Graphic Design, and WebOps keeping the house built and running.',
    link: 'teams',
  },
];

// ---- Search Handling -----------------------------------------------------------
const searchQuery = ref('');
const searchHits = computed(() => {
  const q = searchQuery.value.trim();
  if (!q) return [];
  return search(q).courses.slice(0, 5);
});

const POPULAR_SEARCHES = [
  { label: 'Maths 1 PYQs', q: 'Maths 1 pyq' },
  { label: 'DBMS Notes', q: 'dbms notes' },
  { label: 'Deep Learning', q: 'deep learning' },
  { label: 'Python Notes', q: 'python notes' },
  { label: 'PDSA PYQs', q: 'pdsa pyq' },
];

function applySearchChip(chip) {
  searchQuery.value = chip.q;
  const res = search(chip.q);
  if (res.courses.length > 0) {
    const first = res.courses[0];
    openCourse(first.code, first);
  } else {
    handleSearchSubmit();
  }
}

function handleSearchSubmit() {
  if (!searchQuery.value.trim()) return;
  store.q = searchQuery.value.trim();
  nav.go('resources');
}

function hitCountText(hit) {
  const n = hit.count;
  if (hit.tab === 'notes') {
    return `${n} ${n === 1 ? 'note set' : 'note sets'}`;
  }
  return `${n} ${n === 1 ? 'paper' : 'papers'}`;
}

// ---- Level Tabs -----------------------------------------------------------------
const LEVEL_TABS = [
  { id: 'all', label: 'All Courses' },
  { id: 'foundation', label: 'Foundation' },
  { id: 'programming', label: 'Diploma Programming' },
  { id: 'datascience', label: 'Diploma Data Science' },
  { id: 'degree', label: 'Degree Level' },
];

const activeLevel = ref('all');

function getCoursesByLevel(levelId) {
  if (levelId === 'all') return courses;
  return courses.filter((c) => c.track === levelId);
}

const displayedCourses = computed(() => {
  const list = getCoursesByLevel(activeLevel.value);
  return list.slice(0, 6);
});

function getTrackLabel(track) {
  switch (track) {
    case 'foundation':
      return 'Foundation';
    case 'programming':
      return 'Diploma Prog';
    case 'datascience':
      return 'Diploma DS';
    case 'degree':
      return 'Degree Level';
    default:
      return 'Course';
  }
}

// ---- Events Filter --------------------------------------------------------------
const activeWing = ref('all');

const filteredEvents = computed(() => {
  if (activeWing.value === 'all') return events;
  return events.filter((e) => e.wing === activeWing.value);
});

const spotlightEvent = computed(() => filteredEvents.value[0] || null);
const recentEvents = computed(() => filteredEvents.value.slice(1, 4));

function formatEventDate(ev) {
  if (!ev) return '';
  if (ev.d != null && ev.m != null) {
    return `${ev.d} ${MONTH[ev.m]} ${ev.y || ''}`.trim();
  }
  if (ev.m != null) {
    return `${MONTH[ev.m]} ${ev.y || ''}`.trim();
  }
  return ev.date || 'Recent';
}

function formatExamDate(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return dateStr;
  return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
}

function findExamPyqs(examName) {
  store.q = `${examName || 'exam'} pyq`;
  nav.go('resources');
}

function truncateText(text, maxLen) {
  if (!text) return '';
  if (text.length <= maxLen) return text;
  return text.slice(0, maxLen).trim() + '...';
}

// ---- Subtle Anime.js Animations (Respects prefers-reduced-motion) ----------------
let animInstances = [];

onMounted(() => {
  if (
    typeof window !== 'undefined' &&
    window.matchMedia &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches
  ) {
    return;
  }

  try {
    const heroAnim = animate('.hero-main > *', {
      translateY: [14, 0],
      opacity: [0, 1],
      delay: stagger(60, { start: 80 }),
      duration: 600,
      ease: 'outCubic',
    });
    if (heroAnim) animInstances.push(heroAnim);

    const vitalsAnim = animate('.hero-vitals', {
      translateY: [18, 0],
      opacity: [0, 1],
      delay: 200,
      duration: 650,
      ease: 'outCubic',
    });
    if (vitalsAnim) animInstances.push(vitalsAnim);

    const statAnim = animate('.stat-card', {
      scale: [0.96, 1],
      opacity: [0, 1],
      delay: stagger(50, { start: 280 }),
      duration: 500,
      ease: 'outCubic',
    });
    if (statAnim) animInstances.push(statAnim);
  } catch {
    // Non-blocking fallback
  }
});

onBeforeUnmount(() => {
  animInstances.forEach((inst) => {
    try {
      if (typeof inst.revert === 'function') inst.revert();
      else if (typeof inst.pause === 'function') inst.pause();
    } catch {
      // ignore
    }
  });
  animInstances = [];
});
</script>

<style scoped>
.home-page {
  display: flex;
  flex-direction: column;
  gap: 56px;
  padding-bottom: 72px;
}

/* ==========================================================================
   1. HERO SECTION
   ========================================================================== */
.hero-section {
  padding: 32px 24px 16px;
  background: radial-gradient(
    ellipse 80% 50% at 50% -20%,
    color-mix(in srgb, var(--mari) 12%, transparent),
    transparent
  );
}

.hero-container {
  max-width: 1240px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: minmax(0, 1.2fr) minmax(340px, 0.8fr);
  gap: 40px;
  align-items: start;
}

.hero-main {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.hero-badge {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 4px 12px 4px 6px;
  border-radius: 999px;
  background: var(--card);
  border: 1px solid var(--line);
  color: var(--ink-2);
  font-size: 13px;
  font-weight: 550;
  width: fit-content;
}

.crest-img {
  width: 24px;
  height: 24px;
  object-fit: contain;
}

.hero-title {
  font-size: clamp(32px, 4.5vw, 54px);
  line-height: 1.1;
  font-weight: 750;
  letter-spacing: -0.025em;
  color: var(--ink);
  margin: 0;
  text-wrap: balance;
}

.hero-desc {
  font-size: 17px;
  line-height: 1.5;
  color: var(--ink-2);
  margin: 0;
  max-width: 58ch;
}

.hero-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}

/* Base button styling */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 10px 20px;
  border-radius: 10px;
  font-size: 15px;
  font-weight: 600;
  border: none;
  cursor: pointer;
  transition:
    transform 0.18s var(--ease-out),
    background-color 0.2s var(--ease-out),
    box-shadow 0.2s var(--ease-out);
  text-decoration: none;
}

.btn:active {
  transform: translateY(1px);
}

.btn-primary {
  background: var(--mari);
  color: var(--on-mari);
  box-shadow: 0 2px 8px color-mix(in srgb, var(--mari) 35%, transparent);
}

.btn-primary:hover {
  background: color-mix(in srgb, var(--mari) 88%, #000);
}

.btn-secondary {
  background: var(--card);
  color: var(--ink);
  border: 1px solid var(--line-strong);
}

.btn-secondary:hover {
  background: var(--sunk);
  border-color: var(--ink-3);
}

.btn-sm {
  padding: 6px 14px;
  font-size: 13px;
}

/* Search Box */
.hero-search-wrap {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-top: 8px;
}

.search-box {
  position: relative;
  display: flex;
  align-items: center;
  gap: 12px;
  background: var(--card);
  border: 1.5px solid var(--line-strong);
  border-radius: 12px;
  padding: 0 10px 0 16px;
  height: 52px;
  box-shadow: var(--shadow);
  transition:
    border-color 0.2s,
    box-shadow 0.2s;
}

.search-box:focus-within {
  border-color: var(--mari-ink);
  box-shadow: 0 0 0 3px color-mix(in srgb, var(--mari) 25%, transparent);
}

.search-box input {
  flex: 1;
  border: none;
  background: transparent;
  color: var(--ink);
  font-size: 15px;
  outline: none;
}

.search-box input::placeholder {
  color: var(--ink-3);
}

.search-clear {
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  color: var(--ink-3);
  padding: 4px;
  border-radius: 6px;
  cursor: pointer;
}

.search-clear:hover {
  color: var(--ink);
  background: var(--sunk);
}

.search-submit {
  background: var(--mari);
  color: var(--on-mari);
  border: none;
  border-radius: 8px;
  padding: 8px 14px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.18s;
}

.search-submit:hover {
  background: color-mix(in srgb, var(--mari) 90%, #000);
}

/* Results dropdown */
.search-results {
  position: absolute;
  top: 58px;
  left: 0;
  right: 0;
  z-index: 40;
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 12px;
  box-shadow: 0 16px 36px -12px rgb(0 0 0 / 0.2);
  overflow: hidden;
  max-height: 320px;
  overflow-y: auto;
}

.search-hit {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-bottom: 1px solid var(--line);
  cursor: pointer;
  transition: background-color 0.15s;
}

.search-hit:last-child {
  border-bottom: none;
}

.search-hit:hover,
.search-hit:focus-visible {
  background: var(--sunk);
  outline: none;
}

.hit-info {
  display: flex;
  align-items: center;
  gap: 10px;
}

.hit-name {
  font-size: 14px;
  color: var(--ink);
}

.hit-code {
  font-size: 12px;
  padding: 2px 6px;
  border-radius: 4px;
  background: var(--sunk);
  color: var(--ink-2);
}

.hit-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  color: var(--ink-3);
  font-size: 13px;
}

/* Search Chips */
.search-chips {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
  font-size: 13px;
}

.chips-label {
  color: var(--ink-3);
}

.chip {
  background: var(--card);
  border: 1px solid var(--line);
  color: var(--ink-2);
  padding: 4px 10px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  transition:
    background-color 0.15s,
    border-color 0.15s,
    color 0.15s;
}

.chip:hover {
  background: var(--sunk);
  border-color: var(--line-strong);
  color: var(--ink);
}

/* Hero Vitals Aside */
.hero-vitals {
  display: flex;
  flex-direction: column;
  gap: 16px;
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 16px;
  padding: 24px;
  box-shadow: var(--shadow);
}

.vitals-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.vitals-title-group {
  display: flex;
  flex-direction: column;
}

.vitals-sub {
  font-size: 12px;
  font-weight: 600;
  color: var(--mari-ink);
  letter-spacing: 0.02em;
}

.vitals-heading {
  font-size: 20px;
  font-weight: 700;
  color: var(--ink);
  margin: 2px 0 0;
}

.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 3px 10px;
  border-radius: 999px;
  background: var(--mari-soft);
  color: var(--mari-ink);
  font-size: 12px;
  font-weight: 600;
}

.stats-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.stat-card {
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 14px 16px;
  border-radius: 12px;
  background: var(--sunk);
  border: 1px solid var(--line);
}

.stat-num {
  font-size: 26px;
  font-weight: 750;
  color: var(--ink);
  line-height: 1.1;
}

.stat-label {
  font-size: 12px;
  color: var(--ink-2);
  font-weight: 500;
}

.exam-alert {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 14px;
  border-radius: 10px;
  background: color-mix(in srgb, var(--mari) 12%, var(--card));
  border: 1px solid var(--mari-soft);
}

.alert-icon {
  color: var(--mari-ink);
  display: flex;
  align-items: center;
}

.alert-content {
  flex: 1;
  min-width: 0;
}

.alert-content strong {
  display: block;
  font-size: 13px;
  color: var(--ink);
}

.alert-content p {
  font-size: 12px;
  color: var(--ink-2);
  margin: 1px 0 0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.alert-link {
  background: var(--card);
  border: 1px solid var(--line-strong);
  color: var(--ink);
  border-radius: 6px;
  padding: 4px 10px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
}

.alert-link:hover {
  background: var(--sunk);
}

/* ==========================================================================
   2. SHARED SECTION STYLES
   ========================================================================== */
.section-container {
  max-width: 1240px;
  margin: 0 auto;
  padding: 0 24px;
  display: flex;
  flex-direction: column;
  gap: 24px;
  width: 100%;
}

.section-head {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  justify-content: space-between;
  gap: 16px;
}

.section-title {
  font-size: clamp(24px, 3vw, 32px);
  font-weight: 750;
  color: var(--ink);
  letter-spacing: -0.02em;
  margin: 0 0 6px;
}

.section-desc {
  font-size: 15px;
  color: var(--ink-2);
  margin: 0;
  max-width: 65ch;
  line-height: 1.5;
}

/* ==========================================================================
   3. ACADEMIC RESOURCES SECTION
   ========================================================================== */
.pinned-bar {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
  padding: 10px 16px;
  border-radius: 12px;
  background: var(--sunk);
  border: 1px solid var(--line);
}

.pinned-label {
  font-size: 13px;
  font-weight: 600;
  color: var(--ink-2);
}

.pinned-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.pinned-chip {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  border-radius: 6px;
  background: var(--card);
  border: 1px solid var(--line);
  color: var(--ink);
  font-size: 12px;
  cursor: pointer;
}

.pinned-chip:hover {
  border-color: var(--mari-ink);
}

.pinned-chip .mono {
  color: var(--ink-3);
  font-size: 11px;
}

.level-tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  border-bottom: 1px solid var(--line);
  padding-bottom: 12px;
}

.level-tab {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  border-radius: 8px;
  border: 1px solid transparent;
  background: transparent;
  color: var(--ink-2);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
}

.level-tab:hover {
  background: var(--sunk);
  color: var(--ink);
}

.level-tab.active {
  background: var(--card);
  border-color: var(--line-strong);
  color: var(--ink);
  box-shadow: 0 1px 3px rgb(0 0 0 / 0.05);
}

.tab-count {
  font-size: 11px;
  padding: 1px 6px;
  border-radius: 999px;
  background: var(--sunk);
  color: var(--ink-3);
}

.level-tab.active .tab-count {
  background: var(--mari);
  color: var(--on-mari);
}

.courses-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 20px;
}

.course-card {
  display: flex;
  flex-direction: column;
  gap: 14px;
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 14px;
  padding: 20px;
  box-shadow: var(--shadow);
  transition:
    transform 0.2s var(--ease-out),
    border-color 0.2s;
}

.course-card:hover {
  transform: translateY(-2px);
  border-color: var(--line-strong);
}

.course-card-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.course-identity {
  display: flex;
  align-items: center;
  gap: 8px;
}

.course-code {
  font-size: 13px;
  font-weight: 700;
  color: var(--mari-ink);
}

.course-level-tag {
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 4px;
  background: var(--sunk);
  color: var(--ink-2);
}

.pin-btn {
  background: transparent;
  border: none;
  color: var(--ink-3);
  padding: 4px;
  cursor: pointer;
  border-radius: 6px;
}

.pin-btn:hover {
  color: var(--ink);
  background: var(--sunk);
}

.pin-btn.pinned {
  color: var(--mari-ink);
}

.course-title {
  font-size: 18px;
  font-weight: 700;
  color: var(--ink);
  margin: 0;
  line-height: 1.3;
}

.course-metrics {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
  font-size: 13px;
  color: var(--ink-2);
}

.metric-item {
  display: flex;
  align-items: center;
  gap: 6px;
}

.course-card-actions {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 10px;
  margin-top: auto;
  padding-top: 6px;
}

.btn-open-course {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 8px 14px;
  border-radius: 8px;
  background: var(--sunk);
  border: 1px solid var(--line);
  color: var(--ink);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-open-course:hover {
  background: var(--mari);
  color: var(--on-mari);
  border-color: var(--mari);
}

.btn-open-notes {
  padding: 8px 12px;
  border-radius: 8px;
  background: transparent;
  border: 1px solid var(--line);
  color: var(--ink-2);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
}

.btn-open-notes:hover {
  background: var(--sunk);
  color: var(--ink);
}

.section-footer-action {
  display: flex;
  justify-content: center;
  padding-top: 8px;
}

/* ==========================================================================
   4. EVENTS & WINGS SECTION
   ========================================================================== */
.wing-filters {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.wing-filter-btn {
  padding: 6px 14px;
  border-radius: 999px;
  border: 1px solid var(--line);
  background: var(--card);
  color: var(--ink-2);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
}

.wing-filter-btn:hover {
  border-color: var(--line-strong);
  color: var(--ink);
}

.wing-filter-btn.active {
  background: var(--ink);
  color: var(--paper);
  border-color: var(--ink);
}

.events-layout {
  display: grid;
  grid-template-columns: minmax(0, 1.1fr) minmax(320px, 0.9fr);
  gap: 24px;
}

.event-spotlight-card {
  display: flex;
  flex-direction: column;
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 16px;
  overflow: hidden;
  box-shadow: var(--shadow);
}

.spotlight-image-wrap {
  width: 100%;
  max-height: 280px;
  overflow: hidden;
  background: var(--sunk);
}

.spotlight-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.spotlight-body {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.spotlight-meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.wing-tag {
  font-size: 12px;
  font-weight: 700;
  color: var(--w, var(--mari-ink));
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.date-badge {
  font-size: 13px;
  color: var(--ink-2);
}

.spotlight-title {
  font-size: 22px;
  font-weight: 750;
  color: var(--ink);
  margin: 0;
  line-height: 1.25;
}

.spotlight-desc {
  font-size: 14px;
  color: var(--ink-2);
  line-height: 1.55;
  margin: 0;
}

.spotlight-foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-top: 10px;
  border-top: 1px solid var(--line);
}

.attendee-count {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: var(--ink-3);
}

.recent-events-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.recent-event-card {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 18px 20px;
  border-radius: 14px;
  background: var(--card);
  border: 1px solid var(--line);
  box-shadow: var(--shadow);
  transition:
    transform 0.15s,
    border-color 0.15s;
}

.recent-event-card:hover {
  transform: translateX(2px);
  border-color: var(--line-strong);
}

.recent-event-header {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
}

.wing-indicator {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--w, var(--mari));
}

.wing-name {
  font-weight: 600;
  color: var(--ink-2);
}

.event-date-text {
  margin-left: auto;
  color: var(--ink-3);
}

.recent-event-title {
  font-size: 16px;
  font-weight: 700;
  color: var(--ink);
  margin: 0;
}

.recent-event-snippet {
  font-size: 13px;
  color: var(--ink-2);
  line-height: 1.45;
  margin: 0;
}

/* ==========================================================================
   5. REGIONAL CHAPTERS SECTION
   ========================================================================== */
.regions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 16px;
}

.region-card {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 20px;
  border-radius: 14px;
  background: var(--card);
  border: 1px solid var(--line);
  cursor: pointer;
  box-shadow: var(--shadow);
  transition:
    transform 0.18s var(--ease-out),
    border-color 0.18s;
}

.region-card:hover,
.region-card:focus-visible {
  transform: translateY(-2px);
  border-color: var(--mari-ink);
  outline: none;
}

.region-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.region-pin {
  color: var(--mari-ink);
  display: flex;
}

.region-meetup-count {
  font-size: 12px;
  padding: 2px 8px;
  border-radius: 999px;
  background: var(--sunk);
  color: var(--ink-2);
  font-weight: 600;
}

.region-city {
  font-size: 18px;
  font-weight: 750;
  color: var(--ink);
  margin: 0;
}

.region-info {
  font-size: 13px;
  color: var(--ink-2);
  margin: 0;
}

.region-link {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 600;
  color: var(--mari-ink);
  margin-top: auto;
  padding-top: 4px;
}

/* ==========================================================================
   6. COUNCIL LEADERSHIP SECTION
   ========================================================================== */
.council-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 20px;
}

.council-card {
  display: flex;
  flex-direction: column;
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 14px;
  overflow: hidden;
  box-shadow: var(--shadow);
  text-align: center;
}

.council-photo-wrap {
  width: 100%;
  aspect-ratio: 1 / 1;
  background: var(--sunk);
  overflow: hidden;
}

.council-photo {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.council-photo-fallback {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--ink-3);
  font-size: 32px;
}

.council-body {
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.council-name {
  font-size: 17px;
  font-weight: 750;
  color: var(--ink);
  margin: 0;
}

.council-role {
  font-size: 13px;
  font-weight: 600;
  color: var(--mari-ink);
}

.council-house-tag {
  font-size: 11px;
  color: var(--ink-3);
  margin-top: 2px;
}

.council-socials {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  margin-top: 10px;
}

.council-social-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 8px;
  background: var(--sunk);
  border: 1px solid var(--line);
  color: var(--ink-2);
  text-decoration: none;
  cursor: pointer;
  transition:
    color 0.15s,
    background-color 0.15s,
    border-color 0.15s,
    transform 0.15s;
}

.council-social-btn:hover {
  background: var(--card);
  color: var(--mari-ink);
  border-color: var(--mari-ink);
  transform: translateY(-1px);
}

.council-social-btn:focus-visible {
  outline: 2px solid var(--mari);
  outline-offset: 2px;
}

/* Crew Structure Breakdown */
.crew-structure-section {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-top: 8px;
}

.crew-section-head {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.crew-section-title {
  font-size: 18px;
  font-weight: 750;
  color: var(--ink);
  margin: 0;
}

.crew-section-subtitle {
  font-size: 13.5px;
  color: var(--ink-2);
  margin: 0;
}

.crew-map-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 16px;
}

.crew-card {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 18px 20px;
  border-radius: 14px;
  background: var(--card);
  border: 1px solid var(--line);
  box-shadow: var(--shadow);
  cursor: pointer;
  text-align: left;
  transition:
    transform 0.16s var(--ease-out),
    border-color 0.16s;
}

.crew-card:hover,
.crew-card:focus-visible {
  transform: translateY(-2px);
  border-color: var(--mari-ink);
  outline: none;
}

.crew-card-head {
  display: flex;
  align-items: center;
  gap: 8px;
}

.crew-num {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: var(--mari-soft);
  color: var(--mari-ink);
  font-size: 12px;
  font-weight: 750;
}

.crew-where {
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--mari-ink);
}

.crew-count {
  margin-left: auto;
  font-size: 11px;
  font-weight: 600;
  color: var(--ink-3);
  padding: 2px 6px;
  border-radius: 4px;
  background: var(--sunk);
}

.crew-who {
  font-size: 16px;
  font-weight: 700;
  color: var(--ink);
  margin: 0;
}

.crew-what {
  font-size: 13px;
  color: var(--ink-2);
  line-height: 1.45;
  margin: 0;
}

.teams-banner {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 20px 24px;
  border-radius: 14px;
  background: var(--sunk);
  border: 1px solid var(--line);
}

.teams-banner-text strong {
  display: block;
  font-size: 15px;
  color: var(--ink);
}

.teams-banner-text p {
  font-size: 13px;
  color: var(--ink-2);
  margin: 4px 0 0;
}

/* ==========================================================================
   7. STUDENT UTILITIES SECTION
   ========================================================================== */
.term-brief-card {
  display: flex;
  flex-direction: column;
  gap: 18px;
  padding: 24px;
  border-radius: 16px;
  background: var(--card);
  border: 1.5px solid color-mix(in srgb, var(--mari) 30%, var(--line));
  box-shadow: var(--shadow);
}

.term-brief-head {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.term-brief-title-wrap {
  display: flex;
  align-items: center;
  gap: 12px;
}

.term-chip {
  padding: 4px 10px;
  border-radius: 999px;
  background: var(--mari-soft);
  color: var(--mari-ink);
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.04em;
}

.term-brief-title {
  font-size: 18px;
  font-weight: 750;
  color: var(--ink);
  margin: 0;
}

.term-milestones-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 12px;
}

.milestone-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 12px 14px;
  border-radius: 10px;
  background: var(--sunk);
  border: 1px solid var(--line);
}

.milestone-item.highlight {
  border-color: color-mix(in srgb, var(--mari) 40%, var(--line));
  background: color-mix(in srgb, var(--mari) 8%, var(--card));
}

.milestone-name {
  font-size: 12px;
  font-weight: 700;
  color: var(--ink);
}

.milestone-date {
  font-size: 13.5px;
  font-weight: 700;
  color: var(--mari-ink);
}

.milestone-note {
  font-size: 11px;
  color: var(--ink-3);
  line-height: 1.35;
}

.policy-pills-row {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.policy-pill {
  display: inline-flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  border-radius: 8px;
  background: var(--sunk);
  border: 1px solid var(--line);
  font-size: 12.5px;
  color: var(--ink-2);
}

.policy-pill strong {
  color: var(--ink);
}

.utilities-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 20px;
}

.utility-card {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 24px;
  border-radius: 16px;
  background: var(--card);
  border: 1px solid var(--line);
  box-shadow: var(--shadow);
}

.utility-icon {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  background: var(--mari-soft);
  color: var(--mari-ink);
  display: flex;
  align-items: center;
  justify-content: center;
}

.utility-title {
  font-size: 18px;
  font-weight: 750;
  color: var(--ink);
  margin: 0;
}

.utility-desc {
  font-size: 14px;
  line-height: 1.5;
  color: var(--ink-2);
  margin: 0;
}

.utility-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin-top: auto;
  padding-top: 8px;
  color: var(--mari-ink);
  font-size: 14px;
  font-weight: 650;
  text-decoration: none;
}

.utility-btn:hover {
  text-decoration: underline;
}

/* ==========================================================================
   RESPONSIVE MEDIA QUERIES
   ========================================================================== */
@media (max-width: 960px) {
  .hero-container {
    grid-template-columns: 1fr;
  }

  .events-layout {
    grid-template-columns: 1fr;
  }

  .term-milestones-row {
    grid-template-columns: 1fr 1fr;
  }
}

@media (max-width: 640px) {
  .home-page {
    gap: 40px;
    padding-bottom: 56px;
  }

  .hero-section {
    padding: 20px 16px 8px;
  }

  .section-container {
    padding: 0 16px;
    gap: 18px;
  }

  .stats-grid {
    grid-template-columns: 1fr 1fr;
  }

  .courses-grid {
    grid-template-columns: 1fr;
  }

  .regions-grid {
    grid-template-columns: 1fr;
  }

  .council-grid {
    grid-template-columns: 1fr;
  }

  .crew-map-grid {
    grid-template-columns: 1fr;
  }

  .term-milestones-row {
    grid-template-columns: 1fr;
  }

  .utilities-grid {
    grid-template-columns: 1fr;
  }
}
</style>
