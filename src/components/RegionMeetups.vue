<template>
  <div class="region-meetups">

    <!-- HERO -->
    <section class="hero">
      <div class="container">
        <div class="hero-pill">
          <span class="hero-pill-dot"></span>
          IIT Madras BS · {{ config.chapterLabel }}
        </div>
        <h1 class="hero-title">{{ config.heroTitle }}<br><span class="accent">Meetups</span></h1>
        <p class="hero-desc">{{ config.heroDesc }}</p>

        <!-- GLOBAL STATS (From Meetups Hub) -->
        <div class="hero-stats">
          <div class="hstat">
            <span class="hstat-num">7</span>
            <span class="hstat-lbl">Cities</span>
          </div>
          <div class="hstat-div"></div>
          <div class="hstat">
            <span class="hstat-num">2410<span class="hstat-plus">+</span></span>
            <span class="hstat-lbl">Members</span>
          </div>
          <div class="hstat-div"></div>
          <div class="hstat">
            <span class="hstat-num">48<span class="hstat-plus">+</span></span>
            <span class="hstat-lbl">Meetups Held</span>
          </div>
        </div>


      </div>
    </section>

    <!-- STATS -->
    <section class="section" style="padding-top:0">
      <div class="container">
        <div class="stats-row reveal" ref="statsRow">
          <div class="stat-cell">
            <span class="stat-num">{{ animStats.total }}</span>
            <span class="stat-lbl">Total Meetups Hosted</span>
          </div>
          <div class="stat-cell">
            <span class="stat-num">{{ animStats.cities }}</span>
            <span class="stat-lbl">Cities &amp; Locations</span>
          </div>
          <div class="stat-cell">
            <span class="stat-num">{{ animStats.members }}<span style="font-size:.55em;font-weight:700">+</span></span>
            <span class="stat-lbl">Members Connected</span>
          </div>
        </div>
      </div>
    </section>

    <!-- UPCOMING -->
    <section class="section" id="upcoming">
      <div class="container">
        <span class="sec-eyebrow reveal">Next Event</span>
        <h2 class="sec-title reveal rd1">Upcoming Meetup</h2>
        <div class="sec-rule reveal rd2"></div>

        <!-- NO UPCOMING STATE -->
        <div v-if="!config.upcoming" class="no-upcoming reveal">
          <div class="no-upcoming-icon">📅</div>
          <h3>No upcoming meetup scheduled</h3>
          <p>Check back soon — we're planning the next one. Join our community to get notified first.</p>
          <router-link to="/community" class="btn-primary" style="margin-top:20px;display:inline-flex;">
            Join Community
          </router-link>
        </div>

        <!-- UPCOMING CARD -->
        <div v-else class="upcoming-card reveal">
          <div class="upcoming-inner">
            <div class="upcoming-info">
              <div class="upcoming-badge">
                <span class="upcoming-badge-dot"></span>
                Upcoming
              </div>
              <h3 class="event-name" v-html="config.upcoming.name"></h3>
              <div class="event-chips">
                <div class="chip">📅 {{ config.upcoming.date }}</div>
                <div class="chip">⏰ {{ config.upcoming.time }}</div>
                <div class="chip">🆓 Free Entry</div>
              </div>
              <div class="info-block">
                <span class="info-lbl">About this Meetup</span>
                <p>{{ config.upcoming.about }}</p>
              </div>
              <div class="info-block">
                <span class="info-lbl">Venue &amp; Address</span>
                <div class="address-box">
                  <div class="address-pin">📍</div>
                  <div class="address-lines">
                    <strong>{{ config.upcoming.venue }}</strong>
                    <span>{{ config.upcoming.address1 }}</span>
                    <span>{{ config.upcoming.address2 }}</span>
                    <a :href="config.upcoming.mapsUrl" target="_blank" class="address-map">Open in Google Maps →</a>
                  </div>
                </div>
              </div>
            </div>
            <div class="upcoming-register">
              <div class="spots-display">
                <span class="spots-big">{{ config.upcoming.spots }}</span>
                <span class="spots-sub">Spots Remaining</span>
              </div>
              <div class="reg-rule"></div>
              <p class="reg-desc">Free &amp; open to all IITM BS students and Sundarbans members. No prior registration required but helps us plan better!</p>
              <a href="#" class="register-cta">
                Register Now
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
              </a>
              <p class="reg-closing">Registration closes 2 days before · No fee required</p>
              <div class="reg-rule"></div>
              <div class="reg-tags">
                <span v-for="tag in config.upcoming.tags" :key="tag" class="rtag">{{ tag }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- PAST MEETUPS -->
    <section class="section" style="padding-top:20px">
      <div class="container">
        <span class="sec-eyebrow reveal">Archive</span>
        <h2 class="sec-title reveal rd1">Past Meetups</h2>
        <div class="sec-rule reveal rd2"></div>

        <div v-if="!config.pastMeetups || config.pastMeetups.length === 0" class="no-upcoming reveal" style="margin-top:40px">
          <div class="no-upcoming-icon">🗂️</div>
          <h3>No past meetups yet</h3>
          <p>This chapter is just getting started. The first meetup will be the one to remember.</p>
        </div>

        <div v-else class="timeline">
          <div v-for="meetup in config.pastMeetups" :key="meetup.id" class="tl-item">
            <div class="tl-dot"></div>
            <div class="past-card">
              <div class="past-card-head">
                <div class="past-card-top">
                  <span class="tl-badge">{{ meetup.badge }}</span>
                  <a v-if="meetup.instaUrl" :href="meetup.instaUrl" target="_blank" class="past-insta">
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="2" width="20" height="20" rx="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" y1="6.5" x2="17.51" y2="6.5"/></svg>
                    View Post
                  </a>
                </div>
                <h3 class="tl-title">{{ meetup.title }}</h3>
                <div class="past-meta-row">
                  <div v-if="meetup.date" class="past-chip">📅 {{ meetup.date }}</div>
                  <div v-if="meetup.location" class="past-chip">📍 {{ meetup.location }}</div>
                  <div v-if="meetup.duration" class="past-chip">⏱️ {{ meetup.duration }}</div>
                  <div v-if="meetup.meetupNumber" class="past-chip">#️⃣ {{ meetup.meetupNumber }}</div>
                  <span v-if="meetup.special" class="past-chip green">🏆 {{ meetup.special }}</span>
                </div>
              </div>
              <div class="past-about">
                <span class="past-about-label">About this Meetup</span>
                <p>{{ meetup.about }}</p>
              </div>
              <div class="past-stats">
                <div v-if="meetup.attended" class="past-stat">
                  <span class="past-stat-num">{{ meetup.attended }}</span>
                  <span class="past-stat-lbl">Attended</span>
                </div>
                <div v-if="meetup.organizer" class="past-stat">
                  <span class="past-stat-num">👤</span>
                  <span class="past-stat-lbl">{{ meetup.organizer }}</span>
                </div>
                <div v-else-if="meetup.numberDisplay" class="past-stat">
                  <span class="past-stat-num">{{ meetup.numberDisplay }}</span>
                  <span class="past-stat-lbl">Meetup No.</span>
                </div>
                <div class="past-stat">
                  <span class="past-stat-num">⭐</span>
                  <span class="past-stat-lbl">Community Event</span>
                </div>
              </div>
              <div class="past-photos" v-if="meetup.photos && meetup.photos.length > 0">
                <div v-for="(photo, index) in meetup.photos" :key="index" class="ph">
                  <img :src="photo" alt="" loading="lazy" referrerpolicy="no-referrer">
                  <div class="ph-ov"></div>
                </div>
              </div>
              <div class="past-card-footer">
                <div class="past-footer-tags">
                  <span v-for="tag in meetup.tags" :key="tag" class="past-ftag">{{ tag }}</span>
                </div>
                <a v-if="meetup.instaUrl" :href="meetup.instaUrl" target="_blank" class="past-view-more">View on Instagram →</a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

  </div>
</template>

<script>
import logoSrc  from '@/assets/LOGO.JPEG'
import houseSrc from '@/assets/Sundarbans-House_Vue.jpg'

export default {
  name: 'RegionMeetups',

  props: {
    // Each region page passes its own config object
    config: {
      type: Object,
      required: true,
      /*
        config shape:
        {
          chapterLabel: 'Delhi NCR Chapter',
          heroTitle:    'Delhi',
          heroDesc:     '...',
          stats: { total: 9, cities: 3, members: 200 },
          upcoming: null | {
            name, date, time, about, venue, address1, address2, mapsUrl, spots, tags[]
          },
          pastMeetups: [
            { id, badge, instaUrl, title, date, location, duration, special, about, attended, photos, tags[] }
          ]
        }
      */
    },
  },

  data() {
    return {
      logoSrc,
      houseSrc,
      logoError: false,
      statsAnimated: false,
      animStats: { total: 0, cities: 0, members: 0 },
    }
  },

  mounted() {
    this.$nextTick(() => {
      this.initReveal()
      this.initStatsObserver()
    })
  },

  beforeUnmount() {
  },

  methods: {    initReveal() {
      const obs = new IntersectionObserver(
        (es) => es.forEach(e => { if (e.isIntersecting) e.target.classList.add('visible') }),
        { threshold: 0.08, rootMargin: '0px 0px -30px 0px' }
      )
      this.$el.querySelectorAll('.reveal, .tl-item').forEach(el => obs.observe(el))
    },

    initStatsObserver() {
      const sr = this.$refs.statsRow
      if (!sr) return
      const obs = new IntersectionObserver((es) => {
        es.forEach(e => {
          if (e.isIntersecting && !this.statsAnimated) {
            this.statsAnimated = true
            const s = this.config.stats || {}
            this.countUp('total',   s.total   || 0)
            this.countUp('cities',  s.cities  || 0)
            this.countUp('members', s.members || 0)
            obs.disconnect()
          }
        })
      }, { threshold: 0.4 })
      obs.observe(sr)
    },

    countUp(key, target, dur = 1100) {
      let start = 0
      const step = (ts) => {
        if (!start) start = ts
        const p = Math.min((ts - start) / dur, 1)
        this.animStats[key] = Math.floor((1 - Math.pow(1 - p, 3)) * target)
        if (p < 1) requestAnimationFrame(step)
      }
      requestAnimationFrame(step)
    },
  },
}
</script>

<style scoped>
.region-meetups {
  --bg:          #080705;
  --surface:     #110f0a;
  --surface2:    #18150e;
  --border:      rgba(212,160,23,0.13);
  --border2:     rgba(212,160,23,0.22);
  --gold:        #D4A017;
  --gold-l:      #F0C040;
  --gold-d:      #8B6914;
  --gold-dim:    rgba(212,160,23,0.12);
  --white:       #F5EDD0;
  --white-dim:   rgba(245,237,208,0.55);
  --white-faint: rgba(245,237,208,0.08);

  font-family: 'Outfit', sans-serif;
  background: var(--bg);
  color: var(--white);
  overflow-x: hidden;
  min-height: 100vh;
}

/* HERO */
.hero { min-height:100vh;display:flex;flex-direction:column;justify-content:center;padding:100px 48px 80px;position:relative;z-index:2; }
.container { max-width:1160px;margin:0 auto; }
.hero-pill { display:inline-flex;align-items:center;gap:8px;background:rgba(212,160,23,.1);border:1px solid rgba(212,160,23,.3);padding:7px 16px;border-radius:100px;width:fit-content;font-size:12px;font-weight:500;color:var(--gold-l);margin-bottom:28px;opacity:0;animation:fadeUp .7s ease .2s forwards; }
.hero-pill-dot { width:6px;height:6px;border-radius:50%;background:var(--gold);animation:pulse-dot 1.8s ease-in-out infinite; }
.hero-title { font-family:'Cinzel',serif;font-size:clamp(50px,8.5vw,112px);font-weight:900;line-height:.95;color:var(--white);opacity:0;animation:fadeUp .9s ease .4s forwards; }
.hero-title .accent { background:linear-gradient(135deg,var(--gold-l),var(--gold),var(--gold-d));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text; }
.hero-desc { margin-top:28px;max-width:520px;font-size:16px;font-weight:300;line-height:1.75;color:var(--white-dim);opacity:0;animation:fadeUp .7s ease .7s forwards; }

.hero-stats { margin-top:40px;display:flex;align-items:center;gap:32px;opacity:0;animation:fadeUp .7s ease .8s forwards; }
.hstat { display:flex;flex-direction:column;gap:4px; }
.hstat-num { font-family:'Cinzel',serif;font-size:36px;font-weight:700;color:var(--gold-l);line-height:1;letter-spacing:-.02em; }
.hstat-plus { font-size:.6em; }
.hstat-lbl { font-size:11px;font-weight:400;color:var(--white-dim);letter-spacing:.08em;text-transform:uppercase; }
.hstat-div { width:1px;height:40px;background:var(--border2); }

.hero-actions { margin-top:40px;display:flex;align-items:center;gap:16px;flex-wrap:wrap;opacity:0;animation:fadeUp .7s ease .9s forwards; }
.btn-primary { background:var(--gold);color:#000;font-size:14px;font-weight:700;padding:13px 28px;border-radius:10px;text-decoration:none;display:flex;align-items:center;gap:8px;transition:background .25s,transform .2s,box-shadow .3s;box-shadow:0 6px 28px rgba(212,160,23,.35);letter-spacing:.04em; }
.btn-primary:hover { background:var(--gold-l);transform:translateY(-2px); }
.btn-ghost { background:transparent;color:var(--white-dim);font-size:14px;padding:13px 24px;border-radius:10px;text-decoration:none;display:flex;align-items:center;gap:8px;border:1px solid var(--border2);transition:color .25s,border-color .25s; }
.btn-ghost:hover { color:var(--gold-l);border-color:rgba(212,160,23,.4); }

/* STATS */
.stats-row { display:grid;grid-template-columns:repeat(3,1fr);gap:1px;background:var(--border);border:1px solid var(--border);border-radius:14px;overflow:hidden; }
.stat-cell { background:var(--surface);padding:36px 32px;display:flex;flex-direction:column;gap:6px;transition:background .3s; }
.stat-cell:hover { background:var(--surface2); }
.stat-num { font-family:'Cinzel',serif;font-size:48px;font-weight:700;color:var(--gold-l);line-height:1;letter-spacing:-.02em; }
.stat-lbl { font-size:12px;color:var(--white-dim);letter-spacing:.05em; }

/* SECTION */
.section { padding:80px 48px;position:relative;z-index:2; }
.sec-eyebrow { font-size:11px;font-weight:500;letter-spacing:.2em;text-transform:uppercase;color:var(--gold);display:block;margin-bottom:12px; }
.sec-title { font-family:'Cinzel',serif;font-size:clamp(28px,4vw,48px);font-weight:700;line-height:1.1; }
.sec-rule { width:40px;height:2px;background:var(--gold);border-radius:2px;margin:20px 0 0; }

/* NO UPCOMING */
.no-upcoming { margin-top:48px;text-align:center;padding:64px 32px;background:var(--surface);border:1px solid var(--border);border-radius:18px; }
.no-upcoming-icon { font-size:40px;margin-bottom:16px; }
.no-upcoming h3 { font-family:'Cinzel',serif;font-size:22px;font-weight:700;margin-bottom:10px; }
.no-upcoming p { font-size:14px;font-weight:300;color:var(--white-dim);line-height:1.75;max-width:400px;margin:0 auto; }

/* UPCOMING CARD */
.upcoming-card { margin-top:48px;border-radius:18px;background:var(--surface);border:1px solid rgba(212,160,23,.18);overflow:hidden;position:relative; }
.upcoming-card::before { content:'';position:absolute;top:0;left:0;right:0;height:2px;background:linear-gradient(90deg,var(--gold),var(--gold-l),transparent); }
.upcoming-inner { display:grid;grid-template-columns:1fr 320px; }
.upcoming-info { padding:48px;border-right:1px solid var(--border); }
.upcoming-badge { display:inline-flex;align-items:center;gap:7px;background:rgba(212,160,23,.1);border:1px solid rgba(212,160,23,.3);color:var(--gold-l);padding:5px 14px;border-radius:100px;font-size:11px;font-weight:600;letter-spacing:.12em;text-transform:uppercase;margin-bottom:24px; }
.upcoming-badge-dot { width:6px;height:6px;border-radius:50%;background:var(--gold);animation:pulse-dot 1.5s ease-in-out infinite; }
.event-name { font-family:'Cinzel',serif;font-size:clamp(26px,3.2vw,42px);font-weight:700;line-height:1.1;margin-bottom:24px; }
.event-chips { display:flex;gap:10px;flex-wrap:wrap;margin-bottom:36px; }
.chip { display:flex;align-items:center;gap:7px;background:var(--surface2);border:1px solid var(--border2);padding:8px 16px;border-radius:8px;font-size:13px;color:var(--white-dim); }
.info-block { margin-bottom:32px; }
.info-lbl { font-size:10px;font-weight:500;letter-spacing:.18em;text-transform:uppercase;color:var(--gold);margin-bottom:10px;display:block; }
.info-block p { font-size:14.5px;font-weight:300;line-height:1.8;color:var(--white-dim); }
.address-box { background:var(--surface2);border:1px solid var(--border);border-radius:12px;padding:20px;display:flex;gap:14px; }
.address-pin { width:36px;height:36px;flex-shrink:0;border-radius:8px;background:var(--gold-dim);display:flex;align-items:center;justify-content:center;font-size:16px; }
.address-lines { display:flex;flex-direction:column;gap:3px; }
.address-lines strong { font-size:13.5px;font-weight:600;color:var(--white); }
.address-lines span { font-size:12px;font-weight:300;color:var(--white-dim);line-height:1.6; }
.address-map { font-size:11px;font-weight:500;color:var(--gold);text-decoration:none;margin-top:8px;display:inline-flex; }
.upcoming-register { padding:48px 36px;display:flex;flex-direction:column; }
.spots-display { text-align:center;margin-bottom:20px; }
.spots-big { font-family:'Cinzel',serif;font-size:72px;font-weight:700;color:var(--gold-l);letter-spacing:-.03em;display:block; }
.spots-sub { font-size:11px;color:var(--white-dim);letter-spacing:.12em;text-transform:uppercase;margin-top:4px;display:block; }
.reg-rule { height:1px;background:var(--border);margin:20px 0; }
.reg-desc { font-size:13px;font-weight:300;color:var(--white-dim);line-height:1.7;text-align:center;margin-bottom:24px; }
.register-cta { display:flex;align-items:center;justify-content:center;gap:10px;background:var(--gold);color:#000;width:100%;padding:15px;border-radius:10px;font-size:14px;font-weight:700;text-decoration:none;transition:background .25s,transform .2s;overflow:hidden;position:relative; }
.register-cta:hover { background:var(--gold-l);transform:translateY(-2px); }
.reg-closing { font-size:11px;color:rgba(245,237,208,.25);text-align:center;margin-top:12px;letter-spacing:.05em; }
.reg-tags { display:flex;flex-wrap:wrap;gap:8px;margin-top:4px; }
.rtag { font-size:11px;padding:5px 12px;border-radius:6px;background:var(--white-faint);color:var(--white-dim);border:1px solid var(--border); }

/* TIMELINE */
.timeline { position:relative;margin-top:48px;padding-left:32px; }
.timeline::before { content:'';position:absolute;left:0;top:8px;bottom:0;width:1px;background:linear-gradient(to bottom,var(--gold),transparent);opacity:.2; }
.tl-item { position:relative;margin-bottom:40px;opacity:0;transform:translateY(24px);transition:opacity .65s ease,transform .65s ease; }
.tl-item.visible { opacity:1;transform:translateY(0); }
.tl-dot { position:absolute;left:-38px;top:22px;width:13px;height:13px;border-radius:50%;border:2px solid var(--gold);background:var(--bg);transition:background .3s; }
.tl-item:hover .tl-dot { background:var(--gold); }

/* PAST CARD */
.past-card { background:var(--surface);border:1px solid var(--border);border-radius:16px;overflow:hidden;transition:border-color .3s,box-shadow .35s; }
.past-card:hover { border-color:rgba(212,160,23,.25);box-shadow:0 16px 56px rgba(0,0,0,.5); }
.past-card-head { padding:28px 32px 0; }
.past-card-top { display:flex;align-items:flex-start;justify-content:space-between;gap:16px;flex-wrap:wrap;margin-bottom:16px; }
.tl-badge { font-size:10px;font-weight:500;letter-spacing:.18em;text-transform:uppercase;color:var(--gold);background:var(--gold-dim);border:1px solid rgba(212,160,23,.22);padding:4px 12px;border-radius:100px; }
.past-insta { display:inline-flex;align-items:center;gap:6px;font-size:11px;color:var(--white-dim);background:rgba(245,237,208,.06);border:1px solid var(--border2);padding:5px 13px;border-radius:100px;text-decoration:none;transition:color .2s; }
.past-insta:hover { color:var(--gold-l); }
.tl-title { font-family:'Cinzel',serif;font-size:22px;font-weight:700;margin-bottom:10px;line-height:1.15; }
.past-meta-row { display:flex;gap:10px;flex-wrap:wrap;margin-bottom:18px; }
.past-chip { display:flex;align-items:center;gap:6px;background:var(--surface2);border:1px solid var(--border);padding:6px 14px;border-radius:7px;font-size:12px;color:var(--white-dim); }
.past-chip.green { border-color:rgba(212,160,23,.3);color:var(--gold-l);background:rgba(212,160,23,.06); }
.past-about { padding:0 32px 18px; }
.past-about-label { font-size:9px;font-weight:500;letter-spacing:.2em;text-transform:uppercase;color:var(--gold);display:block;margin-bottom:8px; }
.past-about p { font-size:13.5px;font-weight:300;line-height:1.75;color:var(--white-dim); }
.past-stats { display:grid;grid-template-columns:repeat(3,1fr);gap:1px;background:var(--border);border-top:1px solid var(--border);border-bottom:1px solid var(--border); }
.past-stat { background:var(--surface);padding:18px 20px;text-align:center; }
.past-stat-num { font-family:'Cinzel',serif;font-size:26px;font-weight:700;color:var(--gold-l);line-height:1;display:block; }
.past-stat-lbl { font-size:10px;color:var(--white-dim);letter-spacing:.08em;margin-top:3px;display:block; }
.past-photos { display:grid;grid-template-columns:2fr 1fr 1fr;grid-template-rows:170px 170px;gap:3px; }
.past-photos .ph:first-child { grid-row:1/3; }
.ph { overflow:hidden;position:relative;background:var(--surface2); }
.ph img { width:100%;height:100%;object-fit:cover;transition:transform .6s ease,filter .4s;filter:saturate(.75) brightness(.85); }
.ph:hover img { transform:scale(1.06);filter:saturate(1) brightness(1); }
.ph-ov { position:absolute;inset:0;background:linear-gradient(to top,rgba(8,7,5,.55),transparent 55%);opacity:0;transition:opacity .35s; }
.ph:hover .ph-ov { opacity:1; }
.past-card-footer { padding:16px 32px;display:flex;align-items:center;justify-content:space-between;border-top:1px solid var(--border); }
.past-footer-tags { display:flex;gap:8px;flex-wrap:wrap; }
.past-ftag { font-size:11px;padding:4px 10px;border-radius:5px;background:var(--white-faint);color:var(--white-dim);border:1px solid var(--border); }
.past-view-more { font-size:11px;font-weight:500;color:var(--gold);text-decoration:none;transition:opacity .2s; }
.past-view-more:hover { opacity:.7; }

/* REVEAL */
.reveal { opacity:0;transform:translateY(20px);transition:opacity .7s ease,transform .7s ease; }
.reveal.visible { opacity:1;transform:translateY(0); }
.rd1 { transition-delay:.1s; }
.rd2 { transition-delay:.2s; }

@keyframes fadeUp { to { opacity:1;transform:translateY(0); } }
@keyframes orbit-spin { from{transform:rotate(0deg);}to{transform:rotate(360deg);} }
@keyframes pulse-logo { 0%,100%{transform:scale(1);}50%{transform:scale(1.08);} }
@keyframes pulse-dot { 0%,100%{transform:scale(1);opacity:1;}50%{transform:scale(1.5);opacity:.6;} }

@media (max-width:900px) {
  nav { padding:0 20px; }
  .nav-links,.nav-cta { display:none; }
  .hero { padding:100px 24px 60px; }
  .section { padding:60px 24px; }
  .upcoming-inner { grid-template-columns:1fr; }
  .upcoming-info { border-right:none;border-bottom:1px solid var(--border);padding:32px 24px; }
  .upcoming-register { padding:32px 24px; }
  .stats-row { grid-template-columns:1fr 1fr; }
  footer { flex-direction:column;gap:14px;text-align:center; }
}
@media (max-width:700px) {
  .past-photos { grid-template-columns:1fr 1fr;grid-template-rows:auto; }
  .past-photos .ph:first-child { grid-row:auto; }
  .past-photos .ph { height:140px; }
  .past-stats { grid-template-columns:1fr 1fr; }
}
@media (max-width: 480px) {
  .hero-stats { flex-wrap: wrap; gap: 16px; }
  .hstat-div { display: none; }
  .stats-row { grid-template-columns: 1fr; }
  .past-stats { grid-template-columns: 1fr; }
  .upcoming-info { padding: 24px 16px; }
  .upcoming-register { padding: 24px 16px; }
  .past-card-head { padding: 24px 16px 0; }
  .past-about { padding: 0 16px 18px; }
  .past-card-footer { padding: 16px; flex-direction: column; align-items: flex-start; gap: 12px; }
}
</style>
