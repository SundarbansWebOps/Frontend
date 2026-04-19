<template>
  <div class="video-bg-mode">
    <!-- HERO -->
    <section class="hero-section" id="hero">
      <div
        class="hero-bg"
        style="
          background: url(&quot;/assets/frames/ezgif-frame-001.jpg&quot;) center
            center / cover no-repeat;
        ">
        <canvas class="hero-bg-canvas" ref="heroCanvas"></canvas>
        <div class="hero-overlay"></div>
      </div>
      <div class="hero-content" id="heroContent">
        <div class="hero-badge animate-in" style="--delay: 0.1s">
          <span class="badge-dot"></span>
          IIT Madras BS Degree Programme
        </div>
        <h1 class="hero-title animate-in" style="--delay: 0.3s">
          <span class="hero-title-sm">Welcome to</span>
          <span class="hero-title-main">Sundarbans</span>
          <span class="hero-title-accent">House</span>
        </h1>
        <p class="hero-subtitle animate-in" style="--delay: 0.6s">
          Empowering minds, building futures. A vibrant student community<br />
          driving excellence across
          <em>India's top online degree programme</em>.
        </p>
        <div class="hero-actions animate-in" style="--delay: 0.8s">
          <router-link to="/community" class="btn-hero-primary">
            <span>Join the Community</span>
            <svg
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2.5">
              <path d="M5 12h14M12 5l7 7-7 7" />
            </svg>
          </router-link>
          <router-link to="/about" class="btn-hero-secondary">
            <svg
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2">
              <circle cx="12" cy="12" r="10" />
              <polygon points="10 8 16 12 10 16 10 8" />
            </svg>
            <span>Explore More</span>
          </router-link>
        </div>
        <div class="hero-stats animate-in" style="--delay: 1s">
          <div class="stat-card">
            <div class="stat-number" data-count="5170">0</div>
            <div class="stat-label">Active Members</div>
          </div>
          <div class="stat-div"></div>
          <div class="stat-card">
            <div class="stat-number" data-count="500">0</div>
            <div class="stat-label">Events Hosted</div>
          </div>
          <div class="stat-div"></div>
          <div class="stat-card">
            <div class="stat-number" data-count="40">0</div>
            <div class="stat-label">Cities Connected</div>
          </div>
        </div>
      </div>
  
    </section>

    <!-- MARQUEE -->
    <div class="marquee-band">
      <div class="marquee-track">
        <span>Academic Excellence</span><span class="mdot">✦</span>
        <span>Community Spirit</span><span class="mdot">✦</span>
        <span>Innovation Hub</span><span class="mdot">✦</span>
        <span>IIT Madras BS</span><span class="mdot">✦</span>
        <span>Sundarbans House</span><span class="mdot">✦</span>
        <span>5170+ Members</span><span class="mdot">✦</span>
        <span>40+ Cities</span><span class="mdot">✦</span>
        <span>Academic Excellence</span><span class="mdot">✦</span>
        <span>Community Spirit</span><span class="mdot">✦</span>
        <span>Innovation Hub</span><span class="mdot">✦</span>
        <span>IIT Madras BS</span><span class="mdot">✦</span>
        <span>Sundarbans House</span><span class="mdot">✦</span>
        <span>5170+ Members</span><span class="mdot">✦</span>
        <span>40+ Cities</span><span class="mdot">✦</span>
      </div>
    </div>

    <!-- ABOUT SECTION -->
    <section class="section about-section rs">
      <div class="container">
        <div class="about-grid">
          <div class="about-text-col">
            <div class="section-tag">Who We Are</div>
            <h2 class="section-title-xl">
              About <span class="tg">Sundarbans</span><br />House
            </h2>
            <p class="desc">
              Sundarbans House is a vibrant student community under the IIT
              Madras BS Degree Programme, fostering collaboration, leadership,
              and peer learning across India.
            </p>
            <p class="desc">
              We believe in the power of community — that learning together,
              supporting each other, and growing as one unit makes every
              individual stronger.
            </p>
            <div class="about-highlights">
              <div class="hi">
                <div class="hi-icon">🎯</div>
                <div>
                  <strong>Mission-driven</strong>
                  <p>
                    Empowering every student to achieve their academic goals
                  </p>
                </div>
              </div>
              <div class="hi">
                <div class="hi-icon">🌐</div>
                <div>
                  <strong>Nation-wide reach</strong>
                  <p>Members from 40+ cities across India</p>
                </div>
              </div>
              <div class="hi">
                <div class="hi-icon">⚡</div>
                <div>
                  <strong>Always active</strong>
                  <p>Events, study sessions and discussions every week</p>
                </div>
              </div>
            </div>
            <router-link to="/about" class="learn-link"
              >Learn more about us
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2.5">
                <path d="M5 12h14M12 5l7 7-7 7" />
              </svg>
            </router-link>
          </div>
          <div class="about-img-col">
            <div class="about-img-stack">
              <div class="about-img-main">
                <img
                  src="https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=700&q=80&auto=format&fit=crop"
                  alt="Students collaborating" />
              </div>
              <div class="about-img-secondary">
                <img
                  src="https://images.unsplash.com/photo-1427504494785-3a9ca7044f45?w=400&q=80&auto=format&fit=crop"
                  alt="Study session" />
              </div>
              <div class="about-img-badge">
                <div class="ib-num">⭐ 4.9</div>
                <div class="ib-label">Community Rating</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- FEATURES -->
    <section class="section features-section rs">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">Our Offerings</div>
          <h2 class="section-title-xl">
            Everything you need to <span class="tg">thrive</span>
          </h2>
          <p class="sec-sub">
            From study resources to community events — we've got you covered
          </p>
        </div>
        <div class="features-grid">
          <div class="fcard rc" v-for="f in features" :key="f.title">
            <div class="fcard-img"><img :src="f.img" :alt="f.title" /></div>
            <div class="fcard-body">
              <div class="fcard-icon">{{ f.icon }}</div>
              <h3>{{ f.title }}</h3>
              <p>{{ f.desc }}</p>
              <router-link :to="f.url" class="flink"
                >{{ f.cta }}
                <svg
                  width="13"
                  height="13"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2.5">
                  <path d="M5 12h14M12 5l7 7-7 7" />
                </svg>
              </router-link>
            </div>
          </div>
        </div>
      </div>
    </section>

  <!-- DAILY NOTIFICATIONS (replaces Pulse) -->
    <DailyNotifications />


    <!-- MEET HUB -->
    <section class="section meet-section rs">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">Connect Live</div>
          <h2 class="section-title-xl">
            Smart <span class="tg">Meet Hub</span>
          </h2>
          <p class="sec-sub">
            Join live sessions and never miss an upcoming event
          </p>
        </div>
        <div class="meet-grid">
          <div class="mcard live">
            <div class="mlive-badge">
              <span class="live-dot"></span> LIVE NOW
            </div>
            <div class="mcard-icon">💡</div>
            <h3>Study Group Session</h3>
            <p>Foundation Mathematics — Calculus deep dive with Q&amp;A</p>
            <div class="mtime">
              <svg
                width="14"
                height="14"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2">
                <circle cx="12" cy="12" r="10" />
                <path d="M12 6v6l4 2" />
              </svg>
              Today, 7:00 PM – 9:00 PM
            </div>
            <div class="mavs">
              <div class="mav">A</div>
              <div class="mav">B</div>
              <div class="mav">C</div>
              <div class="mav-more">+12</div>
              <span class="mol">active</span>
            </div>
            <a href="#" class="mjoin-btn"
              ><span>Join Meet</span>
              <svg
                width="14"
                height="14"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2.5">
                <path d="M5 12h14M12 5l7 7-7 7" />
              </svg>
            </a>
          </div>
          <div class="mcard">
            <div class="msoon-badge">STARTING SOON</div>
            <div class="mcard-icon">👥</div>
            <h3>Team Coordination Meeting</h3>
            <p>Weekly sync for all team leads and house coordinators</p>
            <div class="mtime">
              <svg
                width="14"
                height="14"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2">
                <circle cx="12" cy="12" r="10" />
                <path d="M12 6v6l4 2" />
              </svg>
              Tomorrow, 10:00 AM – 11:00 AM
            </div>
            <div class="mavs">
              <div class="mav">D</div>
              <div class="mav">E</div>
              <div class="mav-more">+5</div>
              <span class="mol">registered</span>
            </div>
            <a href="#" class="mrem-btn"><span>Set Reminder</span></a>
          </div>
          <div class="mcard upcoming">
            <div class="mupc-badge">UPCOMING</div>
            <div class="mcard-icon">🎤</div>
            <h3>Guest Lecture — AI &amp; ML</h3>
            <p>
              Exclusive talk by IIT Madras faculty on future of Artificial
              Intelligence
            </p>
            <div class="mtime">
              <svg
                width="14"
                height="14"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2">
                <circle cx="12" cy="12" r="10" />
                <path d="M12 6v6l4 2" />
              </svg>
              This Friday, 6:00 PM – 8:00 PM
            </div>
            <div class="mcountdown">{{ meetCountdown }}</div>
            <a href="#" class="mjoin-btn"><span>Register Now</span></a>
          </div>
        </div>
      </div>
    </section>

    <!-- TESTIMONIALS -->
    <section class="section testimonials-section rs">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">What Members Say</div>
          <h2 class="section-title-xl">
            Voices of <span class="tg">Sundarbans</span>
          </h2>
        </div>
        <div class="tgrid">
          <div class="tcard rc" v-for="t in testimonials" :key="t.name">
            <div class="tquote">"</div>
            <p>{{ t.quote }}</p>
            <div class="tauthor">
              <img :src="t.img" :alt="t.name" />
              <div>
                <strong>{{ t.name }}</strong
                ><span>{{ t.role }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA -->
    <section
      class="cta-section rs"
      style="
        background: rgba(13, 11, 8, 0.5);
        backdrop-filter: blur(12px);
        -webkit-backdrop-filter: blur(12px);
      ">
      <div class="cta-bg">
        <img
          src="https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=1920&q=80&auto=format&fit=crop"
          alt="Students" />
        <div class="cta-ov"></div>
      </div>
      <div class="container">
        <div class="cta-wrap">
          <div class="section-tag light">Academic Excellence</div>
          <h2 class="cta-heading">
            Your Academic<br /><span class="cta-acc">Companion</span>
          </h2>
          <p class="cta-sub">
            From Foundation to BS level, access structured academic resources
            designed to help you succeed. Join thousands of students already
            excelling.
          </p>
          <div class="cta-acts">
            <router-link to="/study" class="cta-btn-p"
              ><span>Go to Study Corner</span>
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2.5">
                <path d="M5 12h14M12 5l7 7-7 7" />
              </svg>
            </router-link>
            <router-link to="/contact" class="cta-btn-o"
              >Contact Us</router-link
            >
          </div>
          <div class="cta-trust">
            <span>✓ Free for all members</span>
            <span>✓ Updated regularly</span>
            <span>✓ Expert-curated</span>
          </div>
        </div>
      </div>
    </section>


  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from "vue";

import { useScrollReveal, useCounters } from "../composables/useAnimations.js";

useScrollReveal();
useCounters();

const heroCanvas = ref(null);

// Features data
const features = [
  {
    icon: "📚",
    title: "Study Resources",
    desc: "Comprehensive materials curated by toppers for all levels",
    img: "https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=600&q=80&auto=format&fit=crop",
    url: "/study",
    cta: "Access Now",
  },
  {
    icon: "🎯",
    title: "Events & Competitions",
    desc: "Hackathons, quizzes, cultural fests and much more",
    img: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=600&q=80&auto=format&fit=crop",
    url: "/events",
    cta: "View Events",
  },
  {
    icon: "🤝",
    title: "Community",
    desc: "Connect with 5000+ peers and build lasting friendships",
    img: "https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=600&q=80&auto=format&fit=crop",
    url: "/community",
    cta: "Join Now",
  },
  {
    icon: "📍",
    title: "City Meetups",
    desc: "Meet fellow students in your city — Delhi to Bangalore",
    img: "https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=600&q=80&auto=format&fit=crop",
    url: "/meetups",
    cta: "Find Meetups",
  },
];

// Pulse
const pulseItems = [
  {
    icon: "📢",
    title: "New Study Material Released",
    desc: "Foundation course materials for Mathematics now available in Study Corner",
    tag: "Academic",
    time: "2 hours ago",
    color: "pa-blue",
  },
  {
    icon: "🏆",
    title: "Community Milestone!",
    desc: "Sundarbans House crosses 5000+ active members — a historic achievement!",
    tag: "Milestone",
    time: "5 hours ago",
    color: "pa-green",
  },
  {
    icon: "📅",
    title: "Upcoming Tech Talk",
    desc: "Guest lecture by IIT Madras faculty on AI and Data Science — Register now!",
    tag: "Event",
    time: "1 day ago",
    color: "pa-orange",
  },
  {
    icon: "🌟",
    title: "Student Achievement",
    desc: "3 Sundarbans students placed in top 10 of national coding competition",
    tag: "Achievement",
    time: "2 days ago",
    color: "pa-purple",
  },
];

// Testimonials
const testimonials = [
  {
    quote:
      "Sundarbans House completely transformed my IIT BS journey. The study groups, the events, the friends — I wouldn't trade this community for anything.",
    name: "Arjun Sharma",
    role: "2nd Year, Data Science",
    img: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&q=80&auto=format&fit=crop&crop=face",
  },
  {
    quote:
      "The peer mentorship here is incredible. When I was struggling with stats, seniors from Sundarbans were there helping me through practice problems.",
    name: "Priya Patel",
    role: "3rd Year, Electronic Systems",
    img: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&q=80&auto=format&fit=crop&crop=face",
  },
  {
    quote:
      "Being part of Sundarbans gave me confidence I never had. The city meetups especially — meeting fellow students from Delhi changed everything for me.",
    name: "Rahul Gupta",
    role: "1st Year, Mathematics",
    img: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&q=80&auto=format&fit=crop&crop=face",
  },
];

// Meet countdown
const meetCountdown = ref("Loading...");
let countTimer = null;
function updateCountdown() {
  const now = new Date();
  const fri = new Date();
  fri.setDate(now.getDate() + ((5 - now.getDay() + 7) % 7) || 7);
  fri.setHours(18, 0, 0, 0);
  const diff = fri - now;
  const d = Math.floor(diff / 86400000);
  const h = Math.floor((diff % 86400000) / 3600000);
  const m = Math.floor((diff % 3600000) / 60000);
  meetCountdown.value = `⏱ Starts in: ${d}d ${h}h ${m}m`;
}

// Hero scroll canvas animation
function initHeroScrollAnimation(canvas) {
  if (!canvas) return;
  const ctx = canvas.getContext("2d");
  const frameCount = 240;
  const currentFrame = (i) =>
    `/assets/frames/ezgif-frame-${String(i + 1).padStart(3, "0")}.jpg`;
  const images = [];
  let framesLoaded = 0;

  function resizeCanvas() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    render();
  }

  for (let i = 0; i < frameCount; i++) {
    const img = new Image();
    img.src = currentFrame(i);
    img.onload = () => {
      framesLoaded++;
      if (framesLoaded === 1) resizeCanvas();
    };
    images.push(img);
  }

  window.addEventListener("resize", resizeCanvas);

  function render() {
    if (!images[0] || !images[0].complete) return;
    const maxScroll = Math.max(
      1,
      document.documentElement.scrollHeight - window.innerHeight,
    );
    const scrollFraction = Math.max(0, Math.min(1, window.scrollY / maxScroll));
    const frameIndex = Math.min(
      frameCount - 1,
      Math.floor(scrollFraction * frameCount),
    );
    const img = images[frameIndex];
    if (img && img.complete) {
      const cw = canvas.width,
        ch = canvas.height;
      const iw = img.width || cw,
        ih = img.height || ch;
      const ratio = Math.max(cw / iw, ch / ih);
      const zw = iw * ratio * 1.15,
        zh = ih * ratio * 1.15;
      const cx = (cw - zw) / 2,
        cy = (ch - zh) / 2;
      ctx.clearRect(0, 0, cw, ch);
      ctx.drawImage(img, 0, 0, iw, ih, cx, cy, zw, zh);
    }
  }

  window.addEventListener("scroll", () => requestAnimationFrame(render));
}

onMounted(() => {
  document.body.classList.add("video-bg-mode");
  updateCountdown();
  countTimer = setInterval(updateCountdown, 60000);
  initHeroScrollAnimation(heroCanvas.value);
});

onUnmounted(() => {
  document.body.classList.remove("video-bg-mode");
  clearInterval(countTimer);
});
</script>

<style scoped>
/* Brighten text for transparent backgrounds (over forest image) */
:deep(.sec-sub), 
:deep(.desc) {
  color: #ffffff;
}

/* Maintain muted gold for glassmorphic (blurred) elements to preserve luxury aesthetic */
.about-section :deep(.desc),
.about-section :deep(.sec-sub),
.fcard p,
.pcard p,
.mcard p,
.tcard p,
.cta-sub {
  color: var(--text2);
}

/* Specific overrides for HomeView components */
.tcard p {
  color: var(--text2);
}

.hi p {
  color: var(--text2);
}
</style>

