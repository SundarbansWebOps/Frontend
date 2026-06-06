<template>
  <div>
    <PageHero
      bg-image="https://img.freepik.com/free-vector/politician-sitting-round-table-boardroom-board-directors-with-ceo-holding-formal-talk-office-room-flat-vector-illustration-business-authority-corporate-leader-planning-strategy-concept_74855-22013.jpg?semt=ais_hybrid&w=740&q=80"
      breadcrumb-title="Meetups"
      title="City"
      accent-title="Meetups"
      subtitle="Find and connect with Sundarbans members in your city"
    />

    <section class="section rs" ref="gridSection">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">Across India</div>
          <h2 class="section-title-xl">
            Choose <span class="tg">your city</span>
          </h2>
        </div>

        <div class="regions-grid">
          <div
            v-for="region in regions"
            :key="region.slug"
            class="region-card reveal"
            :class="{ featured: region.featured }"
            @mouseenter="hoveredRegion = region.slug"
            @mouseleave="hoveredRegion = null"
            @click="goToRegion(region.slug)"
          >
            <img :src="region.image" :alt="region.name" class="region-bg" loading="lazy" />
            <div class="region-overlay"></div>
            <div class="region-gold-tint" v-if="hoveredRegion === region.slug"></div>
            <div class="region-content">
              <div class="region-top">
                <span class="region-badge" v-if="region.badge">{{ region.badge }}</span>
              </div>
              <div class="region-bottom">
                <h3 class="region-name">{{ region.name }}</h3>
                <p class="region-members">{{ region.members }} members</p>
              </div>
            </div>
          </div>
        </div>

        <div style="margin-top: 4rem; text-align: center; padding: 3rem 2rem; background: var(--surface); border: 1px solid var(--border); border-radius: 16px;">
          <div style="font-size: 2.2rem; margin-bottom: 1rem;">🌍</div>
          <h3 style="font-family: Cinzel, serif; font-size: 1.6rem; margin-bottom: 1rem; font-weight: 700; color: var(--text);">
            Bring the Community to Your City
          </h3>
          <p style="color: var(--text2); margin-bottom: 1.75rem; max-width: 600px; margin-left: auto; margin-right: auto; line-height: 1.6;">
            Want a meetup in your city like Siliguri or Guwahati? Suggest a location, pitch an activity, or volunteer as a host. Help us expand the Sundarbans family!
          </p>
          <a href="https://forms.gle/iHeYQsAbsUTBHJJC6" target="_blank" rel="noopener noreferrer" class="submit-btn" style="display: inline-block; text-decoration: none;">
            Suggest Location or Volunteer
          </a>
        </div>
      </div>
    </section>

    <section class="section rs" style="background: var(--bg2)">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">Hall of Fame</div>
          <h2 class="section-title-xl">
            Regional Coordinator <span class="tg">Leaderboard</span>
          </h2>
          <p class="sec-sub">
           Top Contributors and Most Active Regional Coordinators of Sundarbans House
          </p>
        </div>

        <div class="card-base">
          <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 1.5rem; flex-wrap: wrap; gap: 0.75rem;">
            <div class="filter-tabs" style="margin: 0">
              <div
                class="ftab"
                v-for="tab in tabs"
                :key="tab.key"
                :class="{ active: activeTab === tab.key }"
                @click="activeTab = tab.key"
              >
                {{ tab.label }}
              </div>
            </div>
            <span style="font-size: 0.8rem; color: var(--text2)">Updated daily</span>
          </div>

          <table class="lboard-table">
            <thead>
              <tr>
                <th>#</th>
                <th>Member</th>
                <th>City</th>
                <th>Points</th>
                <th>Badge</th>
              </tr>
            </thead>
            <tbody>
              <tr class="lboard-row" v-for="m in members" :key="m.name + activeTab">
                <td>
                  <span class="lboard-rank" :class="m.rankClass">{{ m.rank }}</span>
                </td>
                <td>
                  <div class="lboard-member">
                    <img v-if="m.img" :src="m.img" alt="" class="lboard-avatar" />
                    <div v-else class="lboard-avatar-placeholder">{{ m.initial }}</div>
                    <div>
                      <div class="lboard-name">{{ m.name }}</div>
                      <div class="lboard-city">{{ m.city }}</div>
                    </div>
                  </div>
                </td>
                <td style="color: var(--text2); font-size: 0.85rem">{{ m.city }}</td>
                <td><span class="lboard-score">{{ m.points }}</span></td>
                <td><span class="lboard-badge">{{ m.badge }}</span></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useScrollReveal } from '../composables/useAnimations.js'
import PageHero from '../components/PageHero.vue'
import { leaderboardData } from '@/data/leaderboard.js'

import imgDelhi      from '@/assets/regions/delhi.jpg'
import imgMumbai     from '@/assets/regions/mumbai.jpg'
import imgBangalore  from '@/assets/regions/bangalore.jpg'
import imgKolkata    from '@/assets/regions/kolkata.jpg'
import imgHyderabad  from '@/assets/regions/hyderabad.jpg'
import imgPatna      from '@/assets/regions/patna.jpg'
import imgChandigarh from '@/assets/regions/chandigarh.jpg'
import imgChennai    from '@/assets/regions/chennai.jpg'
import imgLucknow    from '@/assets/regions/lucknow.jpg'

useScrollReveal()

const router = useRouter()
const hoveredRegion = ref(null)

const regions = [
  { slug: 'delhi-ncr',  name: 'Delhi-NCR',  members: '320+', image: imgDelhi,      badge: 'Most Active',    featured: true },
  { slug: 'mumbai',     name: 'Mumbai',     members: '450+', image: imgMumbai,     badge: 'Largest Chapter'               },
  { slug: 'bangalore',  name: 'Bangalore',  members: '390+', image: imgBangalore,  badge: null                            },
  { slug: 'kolkata',    name: 'Kolkata',    members: '280+', image: imgKolkata,    badge: null                            },
  { slug: 'hyderabad',  name: 'Hyderabad',  members: '210+', image: imgHyderabad,  badge: null                            },
  { slug: 'patna',      name: 'Patna',      members: '180+', image: imgPatna,      badge: null                            },
  { slug: 'chandigarh', name: 'Chandigarh', members: '120+', image: imgChandigarh, badge: 'Rising Chapter'                },
  { slug: 'chennai',    name: 'Chennai',    members: '150+', image: imgChennai,    badge: null                            },
  { slug: 'lucknow',    name: 'Lucknow',    members: '110+', image: imgLucknow,    badge: null                            },
]

function goToRegion(slug) {
  router.push('/meetups/' + slug)
}

const MEDALS  = ['🥇', '🥈', '🥉']
const RANK_CLASSES = ['rank-1', 'rank-2', 'rank-3']

const tabs = [
  { label: 'All Time',         key: 'allTime' },
  { label: 'Term 1 (Jan–Apr)', key: 'term1'   },
  { label: 'Term 2 (May–Aug)', key: 'term2'   },
  { label: 'Term 3 (Sep–Dec)', key: 'term3'   },
]

const activeTab = ref('allTime')

const members = computed(() => {
  const raw = leaderboardData[activeTab.value] ?? []
  return [...raw]
    .sort((a, b) => b.points - a.points)
    .map((m, i) => ({
      ...m,
      rank:      MEDALS[i] ?? String(i + 1),
      rankClass: RANK_CLASSES[i] ?? '',
      points:    m.points.toLocaleString(),
    }))
})
</script>

<style scoped>
.regions-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}
.region-card {
  position: relative;
  border-radius: 18px;
  overflow: hidden;
  cursor: pointer;
  aspect-ratio: 3/4;
  border: 1px solid var(--border);
  transition: border-color .3s, transform .35s, box-shadow .35s;
}
.region-card:hover {
  border-color: rgba(212,160,23,.4);
  transform: translateY(-4px);
  box-shadow: 0 24px 64px rgba(0,0,0,.7);
}
.region-card.featured { border-color: rgba(212,160,23,.3); }
.region-bg {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform .6s ease, filter .4s;
  filter: saturate(.8) brightness(.75);
}
.region-card:hover .region-bg {
  transform: scale(1.06);
  filter: saturate(1) brightness(.85);
}
.region-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(to top, rgba(8,7,5,.88) 0%, rgba(8,7,5,.3) 50%, transparent 80%);
  transition: opacity .35s;
}
.region-card:hover .region-overlay {
  background: linear-gradient(to top, rgba(8,7,5,.92) 0%, rgba(8,7,5,.4) 55%, rgba(212,160,23,.04) 100%);
}
.region-gold-tint {
  position: absolute;
  inset: 0;
  background: radial-gradient(ellipse 80% 60% at 50% 100%, rgba(212,160,23,.12) 0%, transparent 70%);
  pointer-events: none;
}
.region-content {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: 20px;
}
.region-top { display: flex; justify-content: flex-end; }
.region-badge {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: .12em;
  text-transform: uppercase;
  color: var(--accent2);
  background: rgba(212,160,23,0.12);
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
  border: 1px solid rgba(212,160,23,0.4);
  padding: 5px 12px;
  border-radius: 100px;
}
.region-bottom { display: flex; flex-direction: column; gap: 4px; }
.region-name {
  font-family: 'Cinzel', serif;
  font-size: clamp(20px, 2vw, 26px);
  font-weight: 700;
  letter-spacing: .01em;
  color: #ffffff;
  line-height: 1.1;
}
.region-members {
  font-size: 14px;
  font-weight: 400;
  color: var(--text2);
  letter-spacing: .03em;
}
.submit-btn {
  background: var(--accent);
  color: #000;
  padding: 12px 28px;
  border-radius: 8px;
  font-weight: 700;
  font-size: 0.95rem;
  transition: all 0.3s;
  box-shadow: 0 4px 20px rgba(212, 160, 23, 0.25);
  font-family: 'Outfit', sans-serif;
}
.submit-btn:hover {
  background: var(--gold-light);
  transform: translateY(-2px);
  box-shadow: 0 8px 30px rgba(212, 160, 23, 0.4);
}
.card-base {
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: 24px;
  padding: 2.5rem;
}
.lboard-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0 8px;
  margin-top: 1rem;
}
.lboard-table th {
  text-align: left;
  padding: 0 16px 12px;
  font-size: 0.75rem;
  font-weight: 500;
  color: var(--text2);
  text-transform: uppercase;
  letter-spacing: 0.12em;
  border-bottom: 1px solid var(--border);
}
.lboard-row td {
  background: var(--surface);
  padding: 16px;
  transition: background 0.3s;
}
.lboard-row:hover td { background: var(--surface2); }
.lboard-row td:first-child { border-top-left-radius: 12px; border-bottom-left-radius: 12px; }
.lboard-row td:last-child  { border-top-right-radius: 12px; border-bottom-right-radius: 12px; }
.lboard-rank {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  font-size: 0.9rem;
  font-weight: 700;
  color: var(--text2);
  background: var(--bg);
  border: 1px solid var(--border);
}
.rank-1 { background: rgba(212,160,23,0.15); color: var(--accent); border-color: rgba(212,160,23,0.3); font-size: 1.2rem; }
.rank-2 { background: rgba(200,200,200,0.1); color: #ccc; border-color: rgba(200,200,200,0.2); font-size: 1.2rem; }
.rank-3 { background: rgba(184,115,51,0.1); color: #b87333; border-color: rgba(184,115,51,0.2); font-size: 1.2rem; }
.lboard-member { display: flex; align-items: center; gap: 12px; }
.lboard-avatar,
.lboard-avatar-placeholder {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  object-fit: cover;
  border: 1px solid var(--border);
}
.lboard-avatar-placeholder {
  background: var(--surface2);
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: 'Cinzel', serif;
  font-weight: 700;
  color: var(--accent);
  font-size: 1.1rem;
}
.lboard-name {
  font-family: 'Cinzel', serif;
  font-weight: 700;
  font-size: 1.05rem;
  color: var(--text);
  line-height: 1.2;
}
.lboard-city {
  font-size: 0.75rem;
  color: var(--text2);
  display: none;
}
.lboard-score {
  font-family: 'Cinzel', serif;
  font-weight: 700;
  font-size: 1.1rem;
  color: var(--accent);
}
.lboard-badge {
  display: inline-block;
  padding: 4px 10px;
  background: var(--surface2);
  border: 1px solid var(--border);
  border-radius: 100px;
  font-size: 0.75rem;
  color: var(--text2);
}
.filter-tabs {
  display: flex;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 100px;
  padding: 4px;
  width: fit-content;
}
.ftab {
  padding: 6px 16px;
  font-size: 0.8rem;
  font-weight: 500;
  color: var(--text2);
  border-radius: 100px;
  cursor: pointer;
  transition: all 0.3s;
}
.ftab.active { background: var(--accent); color: #000; }
.ftab:hover:not(.active) { color: var(--text); }

@media (max-width: 1100px) { .regions-grid { grid-template-columns: repeat(3, 1fr); } }
@media (max-width: 800px) {
  .regions-grid { grid-template-columns: repeat(2, 1fr); }
  .card-base { padding: 1.5rem; }
  .lboard-table th:nth-child(3), .lboard-row td:nth-child(3) { display: none; }
  .lboard-city { display: block; margin-top: 2px; }
}
@media (max-width: 480px) {
  .regions-grid { grid-template-columns: 1fr; }
  .lboard-table th:last-child, .lboard-row td:last-child { display: none; }
}
</style>
