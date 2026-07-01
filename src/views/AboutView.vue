<template>
  <div>
    <PageHero
      bg-image="https://t3.ftcdn.net/jpg/01/64/19/92/360_F_164199298_CRLCgfoGAoEEprge3Deyc8L1dXSHOCMQ.jpg"
      breadcrumb-title="About"
      title="About"
      accent-title="Sundarbans House"
      subtitle="Our story, mission, and the vibrant community that makes us unique"
    />

    <!-- Flipbook Embed -->
    <section class="section rs" style="padding-bottom: 0">
      <div class="container">
        <div
          style="
            width: 100%;
            aspect-ratio: 16 / 9;
            max-height: 720px;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.25);
            position: relative;
            background: #111;
          ">
          <iframe
            v-if="showFlipbook"
            src="https://937908f4-trial.flowpaper.com/Thedeltadiaries"
            title="The Delta Diaries"
            style="
              width: 100%;
              height: calc(100% + 56px);
              margin-top: -56px;
              border: 0;
              display: block;
            "
            allow="fullscreen"
            allowfullscreen></iframe>
          <div
            v-else
            @click="showFlipbook = true"
            style="
              width: 100%;
              height: 100%;
              display: flex;
              flex-direction: column;
              align-items: center;
              justify-content: center;
              cursor: pointer;
              background: linear-gradient(135deg, rgba(212,160,23,0.15), rgba(8,7,5,0.95));
            ">
            <div style="font-size: 3rem; margin-bottom: 1rem">📖</div>
            <h3
              style="
                font-family: Cinzel, serif;
                font-size: 1.4rem;
                font-weight: 700;
                color: #fff;
                margin-bottom: 0.5rem;
              ">
              The Delta Diaries — Vol. 1
            </h3>
            <p style="color: var(--text2); margin-bottom: 1.5rem">
              Click to view the flipbook
            </p>
            <button
              class="cta-btn-p"
              style="border: none; cursor: pointer"
              @click="showFlipbook = true">
              View Flipbook →
            </button>
          </div>
        </div>
      </div>
    </section>

    <!-- Our Story -->
    <section class="section about-section rs">
      <div class="container">
        <div class="about-grid">
          <div class="about-text-col">
            <div class="section-tag">Our Story</div>
            <h2 class="section-title-xl">
              Named after the
              <span class="tg">world's largest mangrove forest</span>
            </h2>
            <p class="desc">
              Sundarbans House is one of the vibrant student houses under the
              IIT Madras BS Online Degree Programme. We are a diverse community
              of learners, innovators, and leaders spread across India and
              beyond, united by our passion for knowledge and excellence.
            </p>
            <p class="desc">
              Just as the Sundarbans ecosystem thrives through collaboration of
              diverse species, our house flourishes through the collective
              efforts of our members from all walks of life.
            </p>
            <p class="desc">
              From Foundation level students to advanced BS degree scholars — we
              grow together, learn together, and celebrate together.
            </p>
            <h3
              style="
                font-family: Cinzel, serif;
                font-size: 1.5rem;
                font-weight: 700;
                margin: 2rem 0 1rem;
              ">
              Building More Than Just a Community
            </h3>
            <p class="desc">
              Sundarbans House is one of the most active and dynamic student
              communities within the IIT Madras BS Degree Programme. It
              represents a network of passionate individuals who come together
              to connect, collaborate, and grow beyond academics.
            </p>
            <p class="desc">
              Inspired by unity and collaboration, the house creates a platform
              where students support each other and experience a meaningful
              college life, even in an online environment.
            </p>
          </div>
          <div class="about-img-col">
            <div class="about-img-stack">
              <div class="about-img-main">
                <img
                  src="https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=700&q=80&auto=format&fit=crop"
                  alt="Team" />
              </div>
              <div class="about-img-secondary">
                <img
                  src="https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=400&q=80&auto=format&fit=crop"
                  alt="Study" />
              </div>
              <div class="about-img-badge">
                <div class="ib-num">Since 2021</div>
                <div class="ib-label">Founded</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Vision & Mission -->
    <section class="section rs" style="background: var(--bg2)">
      <div class="container">
        <div class="grid-2" style="gap: 3rem; align-items: center">
          <div>
            <div class="section-tag">Our Vision</div>
            <h2 class="section-title-xl">
              Discover your <span class="tg">potential</span>
            </h2>
            <p class="desc" style="font-size: 1.05rem">
              To build a strong, inclusive, and growth-driven community where
              every student can discover their potential, develop skills, and
              emerge as a future leader.
            </p>
          </div>
          <div class="card-base" style="padding: 2.5rem">
            <div class="section-tag">Our Mission</div>
            <h3
              style="
                font-family: Cinzel, serif;
                font-size: 1.3rem;
                font-weight: 700;
                margin-bottom: 1rem;
                color: var(--text);
              ">
              Driving Excellence Together
            </h3>
            <ul
              class="mission-list"
              style="
                line-height: 1.9;
                color: var(--text2);
                padding-left: 1.2rem;
              ">
              <li>Promote collaboration and teamwork</li>
              <li>Encourage learning beyond academics</li>
              <li>Provide opportunities for leadership and innovation</li>
              <li>Build a supportive and inclusive environment</li>
            </ul>
          </div>
        </div>
      </div>
    </section>

    <!-- Values -->
    <section class="section rs" style="background: var(--bg2)">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">Our Values</div>
          <h2 class="section-title-xl">
            What <span class="tg">drives us</span>
          </h2>
        </div>
        <div class="grid-3">
          <div
            class="card-base rc"
            style="--card-delay: 0.1s; text-align: center"
            v-for="v in values"
            :key="v.title">
            <div style="font-size: 2.5rem; margin-bottom: 1rem">
              {{ v.icon }}
            </div>
            <h3
              style="
                font-family: Cinzel, serif;
                font-size: 1.1rem;
                font-weight: 700;
                margin-bottom: 0.5rem;
              ">
              {{ v.title }}
            </h3>
            <p class="desc" style="margin: 0">{{ v.desc }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- Stats -->
    <section class="section rs">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">By the Numbers</div>
          <h2 class="section-title-xl">Our <span class="tg">impact</span></h2>
        </div>
        <div
          class="stats-band grid-4"
          style="gap: 1.5rem;">
          <div
            class="card-base"
            style="text-align: center"
            v-for="s in stats"
            :key="s.label">
            <div
              class="stat-number"
              :data-count="s.count"
              :style="`font-family:Cinzel,serif;font-size:3rem;font-weight:800;background:${s.gradient};-webkit-background-clip:text;background-clip:text;-webkit-text-fill-color:transparent`">
              0
            </div>
            <div
              style="
                color: var(--text2);
                font-size: 0.85rem;
                margin-top: 0.3rem;
              ">
              {{ s.label }}
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- What We Do -->
    <section class="section rs" style="background: var(--bg2)">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">What We Do</div>
          <h2 class="section-title-xl">
            Built for <span class="tg">students, by students</span>
          </h2>
        </div>
        <div class="grid-2">
          <div class="card-base rs">
            <div style="font-size: 2rem; margin-bottom: 1rem">🎓</div>
            <h3
              style="
                font-family: Cinzel, serif;
                font-weight: 700;
                font-size: 1.1rem;
                margin-bottom: 0.75rem;
              ">
              Academic Support
            </h3>
            <p class="desc" style="margin: 0">
              Providing curated study materials, doubt sessions, and peer
              tutoring to help every member excel in their academics — from
              Foundation to advanced BS levels.
            </p>
          </div>
          <div class="card-base rs">
            <div style="font-size: 2rem; margin-bottom: 1rem">🌐</div>
            <h3
              style="
                font-family: Cinzel, serif;
                font-weight: 700;
                font-size: 1.1rem;
                margin-bottom: 0.75rem;
              ">
              Community Building
            </h3>
            <p class="desc" style="margin: 0">
              Connecting students through interactions, meetups, and collaborative
              initiatives, ensuring no one feels disconnected in an online program.
            </p>
          </div>
          <div class="card-base rs">
            <div style="font-size: 2rem; margin-bottom: 1rem">🚀</div>
            <h3
              style="
                font-family: Cinzel, serif;
                font-weight: 700;
                font-size: 1.1rem;
                margin-bottom: 0.75rem;
              ">
              Skill Development
            </h3>
            <p class="desc" style="margin: 0">
              Focusing on holistic growth — from coding and design to communication
              and management — helping students develop real-world skills.
            </p>
          </div>
          <div class="card-base rs">
            <div style="font-size: 2rem; margin-bottom: 1rem">🤝</div>
            <h3
              style="
                font-family: Cinzel, serif;
                font-weight: 700;
                font-size: 1.1rem;
                margin-bottom: 0.75rem;
              ">
              Events & Activities
            </h3>
            <p class="desc" style="margin: 0">
              Organizing workshops, webinars, hackathons, competitions, meetups,
              networking sessions, and cultural events that build confidence and
              practical exposure.
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- Domains -->
    <section class="section rs">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">Opportunities & Domains</div>
          <h2 class="section-title-xl">
            Find your <span class="tg">space to grow</span>
          </h2>
        </div>
        <div class="grid-2">
          <div
            class="card-base rc"
            style="text-align: center"
            v-for="d in domains"
            :key="d.title">
            <div style="font-size: 2.2rem; margin-bottom: 1rem">{{ d.icon }}</div>
            <h3
              style="
                font-family: Cinzel, serif;
                font-size: 1.1rem;
                font-weight: 700;
                margin-bottom: 0.5rem;
              ">
              {{ d.title }}
            </h3>
            <p class="desc" style="margin: 0">{{ d.desc }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- What Makes Us Different -->
    <section class="section rs" style="background: var(--bg2)">
      <div class="container">
        <div class="sec-hdr">
          <h2 class="section-title-xl">
            What Makes Us <span class="tg">Different</span>
          </h2>
        </div>
        <div class="grid-3">
          <div
            class="card-base rc"
            style="--card-delay: 0.1s"
            v-for="d in differentiators"
            :key="d.title">
            <div style="font-size: 2rem; margin-bottom: 1rem">{{ d.icon }}</div>
            <h3
              style="
                font-family: Cinzel, serif;
                font-size: 1.05rem;
                font-weight: 700;
                margin-bottom: 0.5rem;
              ">
              {{ d.title }}
            </h3>
            <p class="desc" style="margin: 0">{{ d.desc }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- Our Belief Quote -->
    <section class="section rs">
      <div class="container">
        <div
          class="card-base"
          style="
            text-align: center;
            padding: 4rem 3rem;
            background: linear-gradient(135deg, rgba(212,160,23,0.08), rgba(8,7,5,0.6));
            border: 1px solid rgba(212,160,23,0.2);
          ">
          <div style="font-size: 3rem; margin-bottom: 1.5rem; opacity: 0.6">❝</div>
          <p
            style="
              font-family: Cinzel, serif;
              font-size: 1.4rem;
              font-weight: 600;
              color: var(--text);
              line-height: 1.7;
              max-width: 700px;
              margin: 0 auto 1rem;
            ">
            Sundarbans House is not just a community — it's a family where
            learning meets belonging.
          </p>
          <div style="color: var(--text2); font-size: 0.9rem; letter-spacing: 0.1em">
            — OUR BELIEF
          </div>
        </div>
      </div>
    </section>

    <!-- Leadership Legacy -->
    <section class="section rs" style="background: var(--bg2)">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">A Legacy of Leadership</div>
          <h2 class="section-title-xl">
            The people who <span class="tg">built this</span>
          </h2>
          <p class="desc" style="max-width: 600px; margin: 0 auto 2rem">
            Over the years, Sundarbans House has been shaped by dedicated leaders
            whose vision and efforts have built a strong and inspiring community.
          </p>
        </div>

        <div style="display: flex; flex-direction: column; gap: 2rem">
          <div
            class="card-base"
            v-for="year in leadership"
            :key="year.period">
            <div
              style="
                display: flex;
                align-items: center;
                gap: 1rem;
                margin-bottom: 1.5rem;
                padding-bottom: 1rem;
                border-bottom: 1px solid rgba(212,160,23,0.15);
              ">
              <div
                style="
                  font-family: Cinzel, serif;
                  font-size: 1.2rem;
                  font-weight: 800;
                  background: linear-gradient(135deg,#d4a017,#f0c040);
                  -webkit-background-clip: text;
                  background-clip: text;
                  -webkit-text-fill-color: transparent;
                ">
                {{ year.period }}
              </div>
            </div>
            <div class="grid-3" style="gap: 1rem">
              <div
                v-for="member in year.members"
                :key="member.role"
                style="padding: 1.25rem; background: rgba(255,255,255,0.03); border-radius: 0.75rem; border: 1px solid rgba(212,160,23,0.12); display: flex; flex-direction: column; gap: 0.75rem">
                <!-- Role label -->
                <div style="font-size: 0.72rem; letter-spacing: 0.1em; color: #d4a017; text-transform: uppercase;">
                  {{ member.role }}
                </div>
                <!-- Avatar + Name row -->
                <div style="display: flex; align-items: center; gap: 0.85rem">
                  <div
                    style="
                      width: 52px; height: 52px; border-radius: 50%;
                      border: 2px solid rgba(212,160,23,0.4);
                      flex-shrink: 0;
                      background: linear-gradient(135deg, #2a2006, #3d2e08);
                      display: flex; align-items: center; justify-content: center;
                      font-family: Cinzel, serif;
                      font-weight: 700;
                      font-size: 0.85rem;
                      color: #d4a017;
                      letter-spacing: 0.05em;
                    ">
                    {{ member.name.split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase() }}
                  </div>
                  <div
                    style="font-family: Cinzel, serif; font-weight: 700; font-size: 1rem; color: var(--text); line-height: 1.3;">
                    {{ member.name }}
                  </div>
                </div>
                <!-- Social icon buttons -->
                <div style="display: flex; gap: 0.5rem; flex-wrap: wrap">
                  <!-- Email: only show if available -->
                  <a
                    v-if="member.email"
                    :href="`mailto:${member.email}`"
                    :title="member.email"
                    style="
                      display: flex; align-items: center; justify-content: center;
                      width: 36px; height: 36px; border-radius: 8px;
                      background: rgba(212,160,23,0.08);
                      border: 1px solid rgba(212,160,23,0.2);
                      color: #d4a017; text-decoration: none;
                      transition: background 0.2s;
                    "
                    onmouseover="this.style.background='rgba(212,160,23,0.2)'"
                    onmouseout="this.style.background='rgba(212,160,23,0.08)'"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                      <rect x="2" y="4" width="20" height="16" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>
                    </svg>
                  </a>

                  <!-- LinkedIn: always shown, dimmed + tooltip if no data -->
                  <a
                    v-if="member.linkedin"
                    :href="member.linkedin"
                    target="_blank"
                    title="LinkedIn"
                    style="
                      display: flex; align-items: center; justify-content: center;
                      width: 36px; height: 36px; border-radius: 8px;
                      background: rgba(212,160,23,0.08);
                      border: 1px solid rgba(212,160,23,0.2);
                      color: #d4a017; text-decoration: none;
                      transition: background 0.2s;
                    "
                    onmouseover="this.style.background='rgba(212,160,23,0.2)'"
                    onmouseout="this.style.background='rgba(212,160,23,0.08)'"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                      <path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6z"/><rect x="2" y="9" width="4" height="12"/><circle cx="4" cy="4" r="2"/>
                    </svg>
                  </a>
                  <span
                    v-else
                    title="LinkedIn not available"
                    style="
                      display: flex; align-items: center; justify-content: center;
                      width: 36px; height: 36px; border-radius: 8px;
                      background: rgba(255,255,255,0.03);
                      border: 1px solid rgba(255,255,255,0.08);
                      color: rgba(255,255,255,0.2);
                      cursor: default;
                      position: relative;
                    "
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                      <path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6z"/><rect x="2" y="9" width="4" height="12"/><circle cx="4" cy="4" r="2"/>
                    </svg>
                    <span style="
                      position: absolute; bottom: calc(100% + 6px); left: 50%; transform: translateX(-50%);
                      background: #1a1500; border: 1px solid rgba(212,160,23,0.2);
                      color: rgba(255,255,255,0.5); font-size: 0.65rem; white-space: nowrap;
                      padding: 0.2rem 0.5rem; border-radius: 4px; pointer-events: none;
                      opacity: 0; transition: opacity 0.2s;
                    " class="sc-tip">LinkedIn</span>
                  </span>

                  <!-- Instagram: always shown, dimmed + tooltip if no data -->
                  <a
                    v-if="member.instagram"
                    :href="`https://instagram.com/${member.instagram.replace('@','')}`"
                    target="_blank"
                    :title="member.instagram"
                    style="
                      display: flex; align-items: center; justify-content: center;
                      width: 36px; height: 36px; border-radius: 8px;
                      background: rgba(212,160,23,0.08);
                      border: 1px solid rgba(212,160,23,0.2);
                      color: #d4a017; text-decoration: none;
                      transition: background 0.2s;
                    "
                    onmouseover="this.style.background='rgba(212,160,23,0.2)'"
                    onmouseout="this.style.background='rgba(212,160,23,0.08)'"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                      <rect x="2" y="2" width="20" height="20" rx="5" ry="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" y1="6.5" x2="17.51" y2="6.5"/>
                    </svg>
                  </a>
                  <span
                    v-else
                    title="Instagram not available"
                    style="
                      display: flex; align-items: center; justify-content: center;
                      width: 36px; height: 36px; border-radius: 8px;
                      background: rgba(255,255,255,0.03);
                      border: 1px solid rgba(255,255,255,0.08);
                      color: rgba(255,255,255,0.2);
                      cursor: default;
                      position: relative;
                    "
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                      <rect x="2" y="2" width="20" height="20" rx="5" ry="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" y1="6.5" x2="17.51" y2="6.5"/>
                    </svg>
                    <span style="
                      position: absolute; bottom: calc(100% + 6px); left: 50%; transform: translateX(-50%);
                      background: #1a1500; border: 1px solid rgba(212,160,23,0.2);
                      color: rgba(255,255,255,0.5); font-size: 0.65rem; white-space: nowrap;
                      padding: 0.2rem 0.5rem; border-radius: 4px; pointer-events: none;
                      opacity: 0; transition: opacity 0.2s;
                    " class="sc-tip">Instagram</span>
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div
          class="card-base"
          style="text-align: center; margin-top: 2rem; padding: 2rem; background: rgba(212,160,23,0.05)">
          <p class="desc" style="margin: 0; font-style: italic">
            Each year adds a new chapter to Sundarbans House. With every leader
            and every member, the community continues to grow stronger, more
            impactful, and more inspiring.
          </p>
        </div>
      </div>
    </section>

    <!-- CTA -->
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
          <div class="section-tag light">Be Part of Us</div>
          <h2 class="cta-heading">
            Join <span class="cta-acc">Sundarbans</span>
          </h2>
          <p class="cta-sub">
            Become part of one of IIT Madras BS's most vibrant student
            communities. Connect, learn, and grow with thousands of motivated
            students.
          </p>
          <div class="cta-acts">
            <router-link to="/community" class="cta-btn-p"
              >Join Community →</router-link
            >
            <router-link to="/contact" class="cta-btn-o"
              >Contact Us</router-link
            >
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref } from "vue";
import { useScrollReveal, useCounters } from "../composables/useAnimations.js";
import PageHero from "../components/PageHero.vue";
useScrollReveal();
useCounters();

const showFlipbook = ref(false);

const values = [
  {
    icon: "🎓",
    title: "Academic Excellence",
    desc: "Committed to fostering a culture of learning, peer mentorship and high academic achievement.",
  },
  {
    icon: "🌟",
    title: "Community Spirit",
    desc: "Building lasting connections across the nation, celebrating diversity and collective growth.",
  },
  {
    icon: "🚀",
    title: "Growth Mindset",
    desc: "Empowering every student to reach their full potential through innovation and resilience.",
  },
];

const stats = [
  {
    count: 5170,
    label: "Active Members",
    gradient: "linear-gradient(135deg,#d4a017,#f0c040)",
  },
  {
    count: 500,
    label: "Events Hosted",
    gradient: "linear-gradient(135deg,#10B981,#059669)",
  },
  {
    count: 40,
    label: "Cities Connected",
    gradient: "linear-gradient(135deg,#F59E0B,#EF4444)",
  },
  {
    count: 3,
    label: "Active Communities",
    gradient: "linear-gradient(135deg,#d4a017,#8b6914)",
  },
];

const domains = [
  {
    icon: "💻",
    title: "Tech & Development",
    desc: "Build real projects, contribute to open source, and sharpen your engineering skills with fellow developers.",
  },
  {
    icon: "🎨",
    title: "Design & Creativity",
    desc: "Explore UI/UX, graphic design, and creative storytelling — build a portfolio that stands out.",
  },
  {
    icon: "📈",
    title: "Finance & Entrepreneurship",
    desc: "Develop business acumen, explore startups, and learn financial thinking with like-minded peers.",
  },
  {
    icon: "🤝",
    title: "Community & Welfare",
    desc: "Drive inclusion, support fellow students, and lead initiatives that strengthen the entire community.",
  },
];

const differentiators = [
  {
    icon: "🏡",
    title: "Strong Community Culture",
    desc: "We believe in 'no student left behind' — a supportive ecosystem where collaboration and guidance are always present.",
  },
  {
    icon: "🛠️",
    title: "Skill-Driven Growth",
    desc: "We emphasize practical skills over theory, preparing students for real-world challenges from day one.",
  },
  {
    icon: "🎯",
    title: "Events That Matter",
    desc: "Our events are designed to provide real value — helping students learn, network, and grow meaningfully.",
  },
  {
    icon: "🌍",
    title: "Diversity & Inclusion",
    desc: "Students from across India come together to form a vibrant and inclusive community that celebrates every background.",
  },
  {
    icon: "👑",
    title: "Leadership & Growth",
    desc: "Students lead as organizers, coordinators, and team leads — building essential real-world leadership skills.",
  },
  {
    icon: "🎉",
    title: "Beyond Academics",
    desc: "From celebrations to competitions, we ensure students enjoy a fun, engaging, and memorable journey.",
  },
];

const leadership = [
  {
    period: "2025–26",
    members: [
      {
        role: "Web Admin",
        name: "Samar Ahmad",
        email: "23f3001032@ds.study.iitm.ac.in",
        linkedin: "https://www.linkedin.com/in/samarahmad10",
        instagram: "@thesamarsoldier",
      },
      {
        role: "Secretary",
        name: "Mannu Yadav",
        email: "23f3001972@ds.study.iitm.ac.in",
        linkedin: "https://www.linkedin.com/in/mannuyadav",
        instagram: "@mannu",
      },
      {
        role: "Deputy Secretary",
        name: "Aditya Vaidhya",
        email: "23f2000809@ds.study.iitm.ac.in",
        linkedin: "http://linkedin.com/in/aditya-vaidhya",
        instagram: "@aditya",
      },
    ],
  },
  {
    period: "2024–25",
    members: [
      {
        role: "Web Admin",
        name: "Jivraj",
        email: "23f3001032@ds.study.iitm.ac.in",
      },
      {
        role: "Secretary",
        name: "Shreyansh Mall",
        email: "23f1002638@ds.study.iitm.ac.in",
      },
      {
        role: "Deputy Secretary",
        name: "Divya Chinmay",
        email: "23f1002974@ds.study.iitm.ac.in",
      },
    ],
  },
  {
    period: "2023–24",
    members: [
      {
        role: "Web Admin",
        name: "Ravi Kumawat",
        email: "21f1004119@ds.study.iitm.ac.in",
        instagram: "@ravikumawat7716",
      },
      {
        role: "Secretary",
        name: "Abhishek Ojha",
        email: "22f1001774@ds.study.iitm.ac.in",
      },
      {
        role: "Deputy Secretary",
        name: "Ravi Kant",
        email: "21f3002792@ds.study.iitm.ac.in",
      },
    ],
  },
  {
    period: "2022–23",
    members: [
      {
        role: "Secretary",
        name: "Kunal Chaturvedi",
        email: "21f1003533@ds.study.iitm.ac.in",
      },
      {
        role: "Deputy Secretary",
        name: "Abhishek Ojha",
        email: "21f1003533@ds.study.iitm.ac.in",
      },
    ],
  },
  {
    period: "2021–22",
    members: [
      {
        role: "Web Admin",
        name: "Abhigyan Das",
        email: "21f1003533@ds.study.iitm.ac.in",
      },
      {
        role: "Secretary",
        name: "Anshuman",
        email: "21f1003533@ds.study.iitm.ac.in",
      },
      {
        role: "Deputy Secretary",
        name: "Utkarsh Gaurav",
        email: "21f1003533@ds.study.iitm.ac.in",
      },
    ],
  },
];
</script>
<style scoped>
/* Show tooltip on hover for dimmed social buttons */
span:hover > .sc-tip {
  opacity: 1 !important;
}
</style>
