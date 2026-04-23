<template>
  <div>
    <PageHero
      bg-image="https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=1920&q=80&auto=format&fit=crop"
      breadcrumb-title="Study Corner"
      title="Study"
      accent-title="Corner"
      subtitle="Comprehensive academic resources for Foundation, Diploma and BS level students"
    />

    <section class="section rs" style="background: var(--bg2)" id="levelPicker">
      <div class="container">
        <div class="sc-layout">

          <!-- LEFT: Level cards (vertical sidebar) -->
          <div class="sc-sidebar">
            <div class="sc-sidebar-hdr">
              <div class="section-tag" style="margin-bottom:0">Choose Level</div>
            </div>
            <div class="sc-sidebar-cards">
              <div
                v-for="level in levelMeta"
                :key="level.key"
                class="sc-sidebar-card"
                :class="{ active: currentLevel === level.key }"
                @click="loadLevel(level.key)">
                <div class="sc-sidebar-card-top">
                  <span class="sc-sidebar-emoji">{{ level.emoji }}</span>
                  <div class="sc-sidebar-meta">
                    <h3 class="sc-card-title">{{ level.title }}</h3>
                    <p class="sc-card-desc">{{ level.description }}</p>
                  </div>
                </div>
                <div class="sc-card-stats">
                  <span class="sc-stat-badge">{{ (scData[level.key] || []).length }} subjects</span>
                  <span class="sc-stat-badge">Notes + PYQs</span>
                </div>
                <div class="sc-sidebar-arrow">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <path d="M5 12h14M12 5l7 7-7 7"/>
                  </svg>
                </div>
              </div>
            </div>
          </div>

          <!-- RIGHT: Content panel -->
          <div class="sc-panel-wrap">

            <!-- Search + tabs always visible -->
            <div class="sc-panel-search">
              <div class="sc-search-input-wrap">
                <input
                  v-model="search"
                  type="text"
                  placeholder="Search subjects, notes, PYQs..."
                  class="form-input sc-mid-search-input" />
                <svg class="sc-mid-search-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <circle cx="11" cy="11" r="8" />
                  <path d="m21 21-4.35-4.35" />
                </svg>
              </div>
            </div>

            <!-- Empty state: no level selected -->
            <div v-if="!currentLevel" class="sc-panel-empty">
              <div style="font-size:3rem;margin-bottom:1rem">📚</div>
              <p style="font-size:1rem;color:var(--text2)">Select a level on the left to browse subjects</p>
            </div>

            <!-- Level selected: subjects + resources -->
            <template v-else>
              <div class="sc-panel-body">
                <!-- Subject strip -->
                <div class="sc-subject-strip" id="scSubjectStrip">
                  <div class="sc-strip-header">
                    <span class="sc-strip-label">{{ currentLevelLabel }} — Subjects</span>
                    <button class="sc-back-btn" @click="resetLevel">&larr; Clear</button>
                  </div>
                  <div class="sc-badges-row" id="scSubjectList">
                    <button
                      v-for="subject in filteredSubjects"
                      :key="subject.code"
                      class="sc-subj-badge"
                      :class="{ active: currentSubject?.code === subject.code }"
                      @click="selectSubject(subject)">
                      {{ subject.subject }}
                    </button>
                  </div>
                </div>

                <!-- Resource panel -->
                <div class="sc-resource-panel" id="scPanel">
                <template v-if="currentSubject">
                  <div style="margin-bottom:0.25rem">
                    <div class="section-tag" style="margin-bottom:0.5rem">{{ currentSubject.code }}</div>
                    <p style="font-size:0.8rem;color:var(--text3);letter-spacing:0.03em">{{ currentSubject.description }}</p>
                  </div>

                  <div class="sc-tab-bar">
                    <button class="sc-tab" :class="{ active: currentResourceType === 'lectures' }" @click="currentResourceType = 'lectures'">📺 Lectures</button>
                    <button class="sc-tab" :class="{ active: currentResourceType === 'notes' }" @click="currentResourceType = 'notes'">📝 Notes</button>
                    <button class="sc-tab" :class="{ active: currentResourceType === 'pyq' }" @click="currentResourceType = 'pyq'">📄 PYQs</button>
                  </div>

                  <template v-if="currentResourceType === 'notes' && groupedNotes.length">
                    <div class="sc-author-card" v-for="(group, index) in groupedNotes" :key="group.author">
                      <div class="sc-author-header" @click="toggleAuthor(index)">
                        <span class="sc-author-name">✦ {{ group.author }}
                          <span class="sc-author-count">({{ group.items.length }} {{ group.items.length === 1 ? "note" : "notes" }})</span>
                        </span>
                        <svg class="sc-author-chevron" :style="{ transform: openAuthors[index] ? 'rotate(180deg)' : 'rotate(0deg)' }" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                          <path d="M6 9l6 6 6-6" />
                        </svg>
                      </div>
                      <div class="sc-author-body" :class="{ open: openAuthors[index] }">
                        <div class="sc-author-notes">
                          <a v-for="item in group.items" :key="item.title" :href="item.link" target="_blank" rel="noopener noreferrer" class="sc-resource-item">
                            <span>{{ cleanTitle(item.title) }}</span>
                            <div style="display:flex;align-items:center;gap:0.75rem">
                              <span v-if="item.badge" class="sc-badge">{{ item.badge }}</span>
                              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color:var(--text3)"><path d="M5 12h14M12 5l7 7-7 7" /></svg>
                            </div>
                          </a>
                        </div>
                      </div>
                    </div>
                  </template>

                  <template v-else-if="currentResourceType === 'pyq' && groupedPyq.length">
                    <div class="sc-year-group" v-for="group in groupedPyq" :key="group.year">
                      <div class="sc-year-label">📅 {{ group.year }} <span class="sc-year-count">({{ group.items.length }} papers)</span></div>
                      <a v-for="item in group.items" :key="item.title" :href="item.link" target="_blank" rel="noopener noreferrer" class="sc-resource-item">
                        <span>{{ cleanTitle(item.title) }}</span>
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color:var(--text3)"><path d="M5 12h14M12 5l7 7-7 7" /></svg>
                      </a>
                    </div>
                  </template>

                  <template v-else-if="filteredResources.length">
                    <a v-for="item in filteredResources" :key="item.title" :href="item.link" target="_blank" rel="noopener noreferrer" class="sc-resource-item">
                      <span>{{ cleanTitle(item.title) }}</span>
                      <div style="display:flex;align-items:center;gap:0.75rem">
                        <span v-if="item.badge" class="sc-badge">{{ item.badge }}</span>
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color:var(--text3)"><path d="M5 12h14M12 5l7 7-7 7" /></svg>
                      </div>
                    </a>
                  </template>

                  <div v-else class="sc-empty">
                    <div style="font-size:2rem">🔍</div>
                    <p style="font-size:0.85rem">No matching resources found.</p>
                  </div>
                </template>

                <div v-else class="sc-empty">
                  <div style="font-size:3rem">📖</div>
                  <p style="font-size:0.9rem">Select a subject above to view resources</p>
                </div>
              </div> <!-- /sc-resource-panel -->
              </div> <!-- /sc-panel-body -->
            </template>

          </div>
        </div>
      </div>
    </section>

    <section
      class="section rs"
      style="background: var(--bg2)"
      id="studentTools">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">Student Tools</div>
          <h2 class="section-title-xl">
            Weekly <span class="tg">Study Planner</span>
          </h2>
          <p class="sec-sub">Plan your week day-by-day. Click a task to mark it done.</p>
        </div>
        <!-- Study Planner Tool -->
        <div class="sp-planner-wrap">
          <!-- Week Nav -->
          <div class="sp-week-nav">
            <button class="sp-nav-btn" @click="prevWeek">&#8592;</button>
            <span class="sp-week-label">Week of {{ weekLabel }}</span>
            <button class="sp-nav-btn" @click="nextWeek">&#8594;</button>
            <button class="sp-nav-btn sp-today-btn" @click="goToThisWeek" style="margin-left:0.5rem;font-size:0.75rem;padding:0.3rem 0.75rem">Today</button>
          </div>

          <!-- Day columns -->
          <div class="sp-grid">
            <div
              v-for="day in weekDays"
              :key="day.key"
              class="sp-day-col"
              :class="{ 'sp-today': day.isToday }">
              <div class="sp-day-header">
                <span class="sp-day-name">{{ day.name }}</span>
                <span class="sp-day-date">{{ day.dateStr }}</span>
              </div>
              <div class="sp-tasks">
                <div
                  v-for="task in day.tasks"
                  :key="task.id"
                  class="sp-task"
                  :class="{ 'sp-done': task.done }"
                  @click="toggleTask(day.key, task.id)">
                  <span class="sp-check">{{ task.done ? '✓' : '' }}</span>
                  <span class="sp-task-text">{{ task.text }}</span>
                  <button class="sp-del" @click.stop="deleteTask(day.key, task.id)">×</button>
                </div>
                <div v-if="day.tasks.length === 0" class="sp-empty-day">No tasks</div>
              </div>
              <div class="sp-add-wrap">
                <input
                  v-model="newTaskText[day.key]"
                  class="sp-add-input"
                  :placeholder="'Add task...'"
                  @keyup.enter="addTask(day.key)" />
                <button class="sp-add-btn" @click="addTask(day.key)">+</button>
              </div>
            </div>
          </div>

          <!-- Progress bar -->
          <div class="sp-progress-wrap">
            <div class="sp-progress-label">
              Week Progress — {{ completedCount }}/{{ totalCount }} tasks done
              <span v-if="totalCount > 0" style="color:var(--accent)"> ({{ Math.round(completedCount/totalCount*100) }}%)</span>
            </div>
            <div class="sp-progress-bar">
              <div class="sp-progress-fill" :style="{ width: totalCount > 0 ? (completedCount/totalCount*100)+'%' : '0%' }"></div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="section rs" id="doubtBoard">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">Community</div>
          <h2 class="section-title-xl">
            Anonymous <span class="tg">Doubts Board</span>
          </h2>
          <p class="sec-sub">
            Community-answered doubts. Ask anonymously, learn together.
          </p>
        </div>

        <div
          style="
            display: flex;
            gap: 0.6rem;
            flex-wrap: wrap;
            justify-content: center;
            margin-bottom: 2.5rem;
          ">
          <button
            class="db-filter"
            :class="{ active: dbCurrentFilter === 'all' }"
            @click="setDbFilter('all')">
            All Subjects
          </button>
          <button
            class="db-filter"
            :class="{ active: dbCurrentFilter === 'Math' }"
            @click="setDbFilter('Math')">
            Mathematics
          </button>
          <button
            class="db-filter"
            :class="{ active: dbCurrentFilter === 'Stats' }"
            @click="setDbFilter('Stats')">
            Statistics
          </button>
          <button
            class="db-filter"
            :class="{ active: dbCurrentFilter === 'Python' }"
            @click="setDbFilter('Python')">
            Python
          </button>
          <button
            class="db-filter"
            :class="{ active: dbCurrentFilter === 'DBMS' }"
            @click="setDbFilter('DBMS')">
            DBMS
          </button>
          <button
            class="db-filter"
            :class="{ active: dbCurrentFilter === 'DSA' }"
            @click="setDbFilter('DSA')">
            DSA
          </button>
          <button
            class="db-filter"
            :class="{ active: dbCurrentFilter === 'ML' }"
            @click="setDbFilter('ML')">
            Machine Learning
          </button>
          <button
            v-if="myDoubtsCount > 0"
            class="db-filter"
            :class="{ active: dbCurrentFilter === 'my-doubts' }"
            @click="setDbFilter('my-doubts')">
            My Doubts ({{ myDoubtsCount }})
          </button>
          <button
            class="db-filter"
            :class="{ active: dbCurrentFilter === 'answer-doubts' }"
            @click="setDbFilter('answer-doubts')">
            Answer Doubts
          </button>
        </div>

        <div class="db-scroll-box">
          <template v-if="filteredDoubts.length">
            <div class="db-card" v-for="d in filteredDoubts" :key="d.id">
              <span class="db-tag">{{ d.subject }}</span>
              <div class="db-question">{{ d.question }}</div>
              <div class="db-answer" v-if="d.answer">{{ d.answer }}</div>
              <div
                v-if="dbCurrentFilter === 'answer-doubts' && !d.answer"
                style="margin: 0.75rem 0 0.5rem">
                <textarea
                  v-model="dbDraftAnswers[d.id]"
                  class="db-input"
                  rows="3"
                  placeholder="Write an answer for the community..."></textarea>
                <button
                  class="submit-btn"
                  style="margin-top: 0.55rem; padding: 0.4rem 0.9rem"
                  @click="postAnswer(d.id)">
                  Post Answer
                </button>
              </div>
              <div class="db-footer">
                <span>{{ d.time }}</span>
                <button
                  class="db-upvote"
                  :disabled="Boolean(dbVoted[d.id])"
                  @click="upvoteDoubt(d.id)">
                  {{
                    dbVoted[d.id]
                      ? "✓ Voted"
                      : `👍 ${d.upvotes + (dbVoted[d.id] ? 1 : 0)}`
                  }}
                </button>
              </div>
            </div>
          </template>
          <p
            v-else
            style="text-align: center; color: var(--text3); padding: 2rem">
            {{ emptyDoubtsLabel }}
          </p>
        </div>

        <div
          class="card-base"
          style="max-width: 820px; margin: 0 auto; padding: 2.5rem 2rem; text-align: center;">
          <h3
            style="
              font-family: Cinzel, serif;
              font-weight: 700;
              font-size: 1.4rem;
              margin-bottom: 1rem;
            ">
            Have a Doubt?
          </h3>
          <p style="color: var(--text2); margin-bottom: 1.5rem; font-size: 0.95rem; max-width: 600px; margin-left: auto; margin-right: auto;">
            Submit your doubts anonymously using our Google form. Community members or WebOps will review and post answers on the board.
          </p>
          <a
            href="https://forms.gle/vZox3LpVrXti74UH7"
            target="_blank"
            rel="noopener noreferrer"
            class="submit-btn"
            style="display: inline-block; text-decoration: none;">
            Open Doubts Form
          </a>
        </div>
      </div>
    </section>

    <!-- Exam Cities Section -->
    <section class="section rs" id="examCities">
      <div class="container">
        <div class="sec-hdr">
          <div class="section-tag">Exam Info</div>
          <h2 class="section-title-xl">
            IITM BS <span class="tg">Exam Cities</span>
          </h2>
          <p class="sec-sub">Find your nearest exam centre. Cities are organized by state across India.</p>
        </div>

        <!-- Search + filter -->
        <div class="ec-search-wrap">
          <div class="sc-search-input-wrap" style="max-width:420px;margin:0 auto 1.5rem">
            <input
              v-model="citySearch"
              type="text"
              placeholder="Search city or state..."
              class="form-input sc-mid-search-input" />
            <svg class="sc-mid-search-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
            </svg>
          </div>
        </div>

        <!-- Region tabs -->
        <div style="display:flex;flex-wrap:wrap;gap:0.5rem;justify-content:center;margin-bottom:2rem">
          <button
            v-for="r in examRegions"
            :key="r"
            class="db-filter"
            :class="{ active: activeRegion === r }"
            @click="activeRegion = r">
            {{ r }}
          </button>
        </div>

        <!-- Cities grid -->
        <div class="ec-grid">
          <div
            v-for="row in filteredExamCities"
            :key="row.state"
            class="ec-card card-base rc">
            <div class="ec-state">{{ row.state }}</div>
            <div class="ec-cities-list">
              <span v-for="city in row.cities" :key="city" class="ec-city-tag">{{ city }}</span>
            </div>
          </div>
        </div>

        <div v-if="filteredExamCities.length === 0" class="sc-empty">
          <div style="font-size:2.5rem">🔍</div>
          <p>No cities found for "{{ citySearch }}"</p>
        </div>

        <!-- Info cards -->
        <div class="ec-info-row" style="margin-top:2.5rem">
          <div class="ec-info-card card-base">
            <div style="font-size:1.4rem;margin-bottom:0.5rem">🗓️</div>
            <h4 style="font-family:Cinzel,serif;font-weight:700;margin-bottom:0.4rem">City Selection</h4>
            <p style="font-size:0.82rem;color:var(--text2)">Done during course enrollment each term. Change window opens ~1 month before exams.</p>
          </div>
          <div class="ec-info-card card-base">
            <div style="font-size:1.4rem;margin-bottom:0.5rem">🎫</div>
            <h4 style="font-family:Cinzel,serif;font-weight:700;margin-bottom:0.4rem">Hall Tickets</h4>
            <p style="font-size:0.82rem;color:var(--text2)">Released 2-7 days before exam. Verify your centre address immediately on receipt.</p>
          </div>
          <div class="ec-info-card card-base">
            <div style="font-size:1.4rem;margin-bottom:0.5rem">🪪</div>
            <h4 style="font-family:Cinzel,serif;font-weight:700;margin-bottom:0.4rem">What to Carry</h4>
            <p style="font-size:0.82rem;color:var(--text2)">Hall ticket + original photo ID (Aadhaar/PAN/Passport). Arrive 30 min early. No watches allowed at most centres.</p>
          </div>
        </div>
      </div>
    </section>

    <section class="section rs" style="background: var(--bg2)">
      <div class="container">
        <div
          style="
            align-items: stretch;
          "
          class="sc-contrib-grid grid-2">
          <div
            class="card-base"
            style="
              padding: 2.5rem;
              display: flex;
              flex-direction: column;
              border-color: rgba(212, 160, 23, 0.2);
            ">
            <div style="font-size: 2rem; margin-bottom: 1rem">📤</div>
            <div
              class="section-tag"
              style="margin-bottom: 1rem; align-self: flex-start">
              Student Contribution
            </div>
            <h3
              style="
                font-family: Cinzel, serif;
                font-weight: 700;
                font-size: 1.4rem;
                margin-bottom: 0.5rem;
              ">
              Share Your Notes
            </h3>
            <p
              style="
                color: var(--text2);
                font-size: 0.9rem;
                margin-bottom: 1.25rem;
              ">
              <strong style="color: var(--text)">Purpose:</strong>
              Community-driven academic content
            </p>
            <ul
              style="
                list-style: none;
                padding: 0;
                margin: 0 0 1.75rem;
                display: flex;
                flex-direction: column;
                gap: 0.6rem;
              ">
              <li
                style="
                  display: flex;
                  align-items: center;
                  gap: 0.6rem;
                  font-size: 0.88rem;
                  color: var(--text2);
                ">
                <span style="color: var(--accent); font-size: 0.9rem">✦</span
                >Upload notes & resources
              </li>
              <li
                style="
                  display: flex;
                  align-items: center;
                  gap: 0.6rem;
                  font-size: 0.88rem;
                  color: var(--text2);
                ">
                <span style="color: var(--accent); font-size: 0.9rem">✦</span
                >Help juniors & peers
              </li>
              <li
                style="
                  display: flex;
                  align-items: center;
                  gap: 0.6rem;
                  font-size: 0.88rem;
                  color: var(--text2);
                ">
                <span style="color: var(--accent); font-size: 0.9rem">✦</span
                >WebOps review ensures quality
              </li>
            </ul>
            <a
              href="https://forms.gle/c86b55AZ517Q8Ahg6"
              target="_blank"
              rel="noopener noreferrer"
              class="submit-btn"
              style="align-self: flex-start; text-decoration: none;"
              >Submit a Resource</a
            >
          </div>

          <div
            class="card-base"
            style="
              padding: 2.5rem;
              display: flex;
              flex-direction: column;
              border-color: rgba(212, 160, 23, 0.2);
            ">
            <div style="font-size: 2rem; margin-bottom: 1rem">🎯</div>
            <div
              class="section-tag"
              style="margin-bottom: 1rem; align-self: flex-start">
              Resource Request
            </div>
            <h3
              style="
                font-family: Cinzel, serif;
                font-weight: 700;
                font-size: 1.4rem;
                margin-bottom: 0.5rem;
              ">
              Request a Resource
            </h3>
            <p
              style="
                color: var(--text2);
                font-size: 0.9rem;
                margin-bottom: 1.25rem;
              ">
              <strong style="color: var(--text)">Purpose:</strong>
              Identify missing academic needs
            </p>
            <ul
              style="
                list-style: none;
                padding: 0;
                margin: 0 0 1.75rem;
                display: flex;
                flex-direction: column;
                gap: 0.6rem;
              ">
              <li
                style="
                  display: flex;
                  align-items: center;
                  gap: 0.6rem;
                  font-size: 0.88rem;
                  color: var(--text2);
                ">
                <span style="color: var(--accent); font-size: 0.9rem">✦</span
                >Request missing topics
              </li>
              <li
                style="
                  display: flex;
                  align-items: center;
                  gap: 0.6rem;
                  font-size: 0.88rem;
                  color: var(--text2);
                ">
                <span style="color: var(--accent); font-size: 0.9rem">✦</span
                >Exam-focused content
              </li>
              <li
                style="
                  display: flex;
                  align-items: center;
                  gap: 0.6rem;
                  font-size: 0.88rem;
                  color: var(--text2);
                ">
                <span style="color: var(--accent); font-size: 0.9rem">✦</span
                >Helps WebOps prioritize
              </li>
            </ul>
            <a
              href="https://forms.gle/KNm4hyupaG22Huxd6"
              target="_blank"
              rel="noopener noreferrer"
              class="submit-btn"
              style="
                align-self: flex-start;
                background: transparent;
                border: 1px solid var(--accent);
                color: var(--accent);
                text-decoration: none;
              "
              >Request a Resource</a
            >
          </div>
        </div>
      </div>
    </section>


  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref, watch } from "vue";

import { useScrollReveal } from "../composables/useAnimations.js";
import PageHero from "../components/PageHero.vue";
import scData from "../data/scData_generated.js";

useScrollReveal();

// ─── Study Planner ────────────────────────────────────────────────────────────
const weekOffset = ref(0);

function getMondayOf(date) {
  const d = new Date(date);
  const day = d.getDay();
  const diff = (day === 0 ? -6 : 1 - day);
  d.setDate(d.getDate() + diff);
  d.setHours(0, 0, 0, 0);
  return d;
}

const thisMonday = getMondayOf(new Date());

const currentMonday = computed(() => {
  const d = new Date(thisMonday);
  d.setDate(d.getDate() + weekOffset.value * 7);
  return d;
});

const weekLabel = computed(() => {
  const m = currentMonday.value;
  return m.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
});

const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const plannerTasks = reactive({});

function getDayKey(baseMonday, offset) {
  const d = new Date(baseMonday);
  d.setDate(d.getDate() + offset);
  return d.toISOString().slice(0, 10);
}

const weekDays = computed(() => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return dayNames.map((name, i) => {
    const d = new Date(currentMonday.value);
    d.setDate(d.getDate() + i);
    const key = d.toISOString().slice(0, 10);
    if (!plannerTasks[key]) plannerTasks[key] = [];
    return {
      name,
      key,
      dateStr: d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' }),
      isToday: d.getTime() === today.getTime(),
      tasks: plannerTasks[key],
    };
  });
});

const newTaskText = reactive({});
let taskIdCounter = 1;

function addTask(dayKey) {
  const text = (newTaskText[dayKey] || '').trim();
  if (!text) return;
  if (!plannerTasks[dayKey]) plannerTasks[dayKey] = [];
  plannerTasks[dayKey].push({ id: taskIdCounter++, text, done: false });
  newTaskText[dayKey] = '';
}

function toggleTask(dayKey, id) {
  const task = (plannerTasks[dayKey] || []).find(t => t.id === id);
  if (task) task.done = !task.done;
}

function deleteTask(dayKey, id) {
  if (plannerTasks[dayKey]) {
    plannerTasks[dayKey] = plannerTasks[dayKey].filter(t => t.id !== id);
  }
}

function prevWeek() { weekOffset.value--; }
function nextWeek() { weekOffset.value++; }
function goToThisWeek() { weekOffset.value = 0; }

const totalCount = computed(() => weekDays.value.reduce((s, d) => s + d.tasks.length, 0));
const completedCount = computed(() => weekDays.value.reduce((s, d) => s + d.tasks.filter(t => t.done).length, 0));

// ─── Exam Cities ─────────────────────────────────────────────────────────────
const citySearch = ref('');
const activeRegion = ref('All');

const examCitiesData = [
  { state: 'Andaman & Nicobar Islands', region: 'Kolkata', cities: ['Port Blair'] },
  { state: 'Andhra Pradesh', region: 'Hyderabad', cities: ['Anantapur', 'Bhimavaram', 'Guntur', 'Kadapa', 'Kurnool', 'Rajahmundry', 'Tirupathi', 'Vijayawada', 'Vishakhapatnam'] },
  { state: 'Arunachal Pradesh', region: 'Kolkata', cities: ['Naharlagun'] },
  { state: 'Assam', region: 'Kolkata', cities: ['Dibrugarh', 'Guwahati', 'Silchar', 'Tezpur'] },
  { state: 'Bihar', region: 'Patna', cities: ['Patna', 'Bhagalpur', 'Gaya', 'Muzaffarpur', 'Darbhanga'] },
  { state: 'Chhattisgarh', region: 'Patna', cities: ['Raipur'] },
  { state: 'Delhi', region: 'Delhi', cities: ['Delhi'] },
  { state: 'Goa', region: 'Mumbai', cities: ['Panaji'] },
  { state: 'Gujarat', region: 'Mumbai', cities: ['Ahmedabad', 'Anand', 'Rajkot', 'Surat', 'Vadodara'] },
  { state: 'Haryana', region: 'Chandigarh', cities: ['Faridabad', 'Gurgaon', 'Kurukshetra'] },
  { state: 'Himachal Pradesh', region: 'Chandigarh', cities: ['Hamirpur', 'Shimla'] },
  { state: 'Jammu & Kashmir', region: 'Chandigarh', cities: ['Jammu', 'Srinagar'] },
  { state: 'Jharkhand', region: 'Patna', cities: ['Dhanbad', 'Jamshedpur', 'Ranchi'] },
  { state: 'Karnataka', region: 'Bengaluru', cities: ['Belgaum', 'Bengaluru', 'Dharwad', 'Gulbarga', 'Mangalore', 'Mysore'] },
  { state: 'Kerala', region: 'Bengaluru', cities: ['Calicut', 'Ernakulam', 'Kollam', 'Kottayam', 'Palakkad', 'Thrissur', 'Trivandrum'] },
  { state: 'Madhya Pradesh', region: 'Mumbai', cities: ['Bhopal', 'Gwalior', 'Indore', 'Jabalpur'] },
  { state: 'Maharashtra', region: 'Mumbai', cities: ['Amravati', 'Aurangabad', 'Jalgaon', 'Kolhapur', 'Mumbai', 'Nagpur', 'Nanded', 'Nashik', 'Pune', 'Solapur'] },
  { state: 'Manipur', region: 'Kolkata', cities: ['Imphal'] },
  { state: 'Meghalaya', region: 'Kolkata', cities: ['Shillong'] },
  { state: 'Mizoram', region: 'Kolkata', cities: ['Aizawl'] },
  { state: 'Nagaland', region: 'Kolkata', cities: ['Dimapur'] },
  { state: 'Odisha', region: 'Kolkata', cities: ['Bhubaneswar', 'Rourkela', 'Sambalpur'] },
  { state: 'Puducherry', region: 'Chennai', cities: ['Puducherry'] },
  { state: 'Punjab', region: 'Chandigarh', cities: ['Chandigarh', 'Jalandhar', 'Ludhiana', 'Amritsar'] },
  { state: 'Rajasthan', region: 'Chandigarh', cities: ['Jaipur', 'Jodhpur', 'Kota', 'Udaipur'] },
  { state: 'Sikkim', region: 'Kolkata', cities: ['Bardang'] },
  { state: 'Tamil Nadu', region: 'Chennai', cities: ['Chennai-Avadi', 'Chennai-South', 'Coimbatore', 'Erode', 'Kanchipuram', 'Madurai', 'Salem', 'Thanjavur', 'Tiruchirappalli', 'Tirunelveli', 'Vellore'] },
  { state: 'Telangana', region: 'Hyderabad', cities: ['Hyderabad', 'Warangal'] },
  { state: 'Tripura', region: 'Kolkata', cities: ['Agartala'] },
  { state: 'Uttar Pradesh', region: 'Lucknow', cities: ['Agra', 'Allahabad', 'Ghaziabad', 'Gorakhpur', 'Greater Noida', 'Kanpur', 'Lucknow', 'Meerut', 'Varanasi'] },
  { state: 'Uttarakhand', region: 'Chandigarh', cities: ['Dehradun', 'Haldwani', 'Roorkee'] },
  { state: 'West Bengal', region: 'Kolkata', cities: ['Asansol', 'Adisaptagram', 'Durgapur', 'Kolkata', 'Siliguri'] },
];

const examRegions = ['All', 'Delhi', 'Chennai', 'Bengaluru', 'Hyderabad', 'Mumbai', 'Kolkata', 'Patna', 'Chandigarh', 'Lucknow'];

const filteredExamCities = computed(() => {
  const q = citySearch.value.trim().toLowerCase();
  return examCitiesData.filter(row => {
    const regionMatch = activeRegion.value === 'All' || row.region === activeRegion.value;
    if (!regionMatch) return false;
    if (!q) return true;
    return row.state.toLowerCase().includes(q) || row.cities.some(c => c.toLowerCase().includes(q));
  });
});

const search = ref("");
const tabs = ["All Levels", "Foundation", "Diploma", "BS Degree"];
const activeTab = ref("All Levels");

const levelMeta = [
  {
    key: "foundation",
    emoji: "🌱",
    title: "Foundation Level",
    description:
      "Maths, English, Computational Thinking, Statistics, Python basics",
  },
  {
    key: "diploma",
    emoji: "📐",
    title: "Diploma Level",
    description: "DSA, DBMS, Machine Learning, App Development, Java and more",
  },
  {
    key: "bs",
    emoji: "🎓",
    title: "BS Degree Level",
    description: "Deep Learning, LLMs, NLP, CV, MLOps and more electives",
  },
];

const tabToLevel = {
  Foundation: "foundation",
  Diploma: "diploma",
  "BS Degree": "bs",
};

const visibleLevels = computed(() => {
  if (activeTab.value === "All Levels") return levelMeta;
  const key = tabToLevel[activeTab.value];
  return levelMeta.filter((l) => l.key === key);
});

const currentLevel = ref(null);
const currentSubjectCode = ref(null);
const currentResourceType = ref("notes");
const openAuthors = ref({});

const currentLevelLabel = computed(() => {
  if (currentLevel.value === "foundation") return "🌱 Foundation";
  if (currentLevel.value === "diploma") return "📐 Diploma";
  if (currentLevel.value === "bs") return "🎓 BS Degree";
  return "Subjects";
});

const levelSubjects = computed(() => {
  if (!currentLevel.value) return [];
  return scData[currentLevel.value] || [];
});

function subjectMatchesSearch(subject, query) {
  const q = query.toLowerCase();
  if (subject.subject.toLowerCase().includes(q)) return true;
  if (
    String(subject.code || "")
      .toLowerCase()
      .includes(q)
  )
    return true;
  const resources = subject.resources || {};
  return ["lectures", "notes", "pyq"].some((type) =>
    (resources[type] || []).some((item) =>
      String(item.title || "")
        .toLowerCase()
        .includes(q),
    ),
  );
}

const filteredSubjects = computed(() => {
  const q = search.value.trim().toLowerCase();
  
  let baseSubjects = [];
  if (activeTab.value === "All Levels" && q) {
    // Collect all subjects from all levels for global search
    ['foundation', 'diploma', 'bs'].forEach(lvl => {
      (scData[lvl] || []).forEach(sub => {
        baseSubjects.push({ ...sub, levelKey: lvl });
      });
    });
  } else {
    // Only current level subjects
    baseSubjects = levelSubjects.value.map(sub => ({ ...sub, levelKey: currentLevel.value }));
  }

  if (!q) return baseSubjects;
  
  return baseSubjects.filter((subject) =>
    subjectMatchesSearch(subject, q),
  );
});

const currentSubject = computed(
  () =>
    levelSubjects.value.find((s) => s.code === currentSubjectCode.value) ||
    null,
);

const filteredResources = computed(() => {
  if (!currentSubject.value) return [];
  const source =
    currentSubject.value.resources?.[currentResourceType.value] || [];
  const q = search.value.trim().toLowerCase();
  if (!q) return source;
  return source.filter((item) =>
    String(item.title || "")
      .toLowerCase()
      .includes(q),
  );
});

function parseAuthor(title) {
  const match = String(title).match(/\(by\s+(.+?)\)\s*$/i);
  return match ? match[1].trim() : "Unknown";
}

function cleanTitle(title) {
  let cleaned = String(title || "")
    .replace(/\s*\(by\s+.+?\)\s*$/i, "")
    .trim();
  cleaned = cleaned.replace(/^[\s\-–:]+/, "");
  return cleaned || String(title || "Untitled");
}

function parsePYQYear(title) {
  const monthYear = String(title).match(
    /(January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{4})/i,
  );
  if (monthYear) return monthYear[2];
  const yearOnly = String(title).match(/\b(20\d{2})\b/);
  return yearOnly ? yearOnly[1] : "Other";
}

const groupedNotes = computed(() => {
  if (currentResourceType.value !== "notes") return [];
  const map = new Map();
  filteredResources.value.forEach((item) => {
    const author = parseAuthor(item.title);
    if (!map.has(author)) map.set(author, []);
    map.get(author).push(item);
  });
  return Array.from(map.entries())
    .sort((a, b) => {
      if (a[0] === "Unknown") return 1;
      if (b[0] === "Unknown") return -1;
      return a[0].localeCompare(b[0]);
    })
    .map(([author, items]) => ({ author, items }));
});

const groupedPyq = computed(() => {
  if (currentResourceType.value !== "pyq") return [];
  const map = new Map();
  filteredResources.value.forEach((item) => {
    const year = parsePYQYear(item.title);
    if (!map.has(year)) map.set(year, []);
    map.get(year).push(item);
  });
  return Array.from(map.entries())
    .sort((a, b) => {
      if (a[0] === "Other") return 1;
      if (b[0] === "Other") return -1;
      return Number(b[0]) - Number(a[0]);
    })
    .map(([year, items]) => ({ year, items }));
});

function toggleAuthor(index) {
  openAuthors.value = {
    ...openAuthors.value,
    [index]: !openAuthors.value[index],
  };
}

function loadLevel(level) {
  currentLevel.value = level;
  currentResourceType.value = "notes";
  openAuthors.value = {};
  const first = (scData[level] || [])[0];
  currentSubjectCode.value = first ? first.code : null;
}

function selectSubject(subject) {
  if (subject.levelKey && subject.levelKey !== currentLevel.value) {
    currentLevel.value = subject.levelKey;
  }
  currentSubjectCode.value = subject.code;
  currentResourceType.value = "notes";
  openAuthors.value = {};
}

function resetLevel() {
  currentLevel.value = null;
  currentSubjectCode.value = null;
  currentResourceType.value = "notes";
  openAuthors.value = {};
}

watch(activeTab, (newTab) => {
  if (newTab === "All Levels") return;
  const key = tabToLevel[newTab];
  if (key) loadLevel(key);
});

watch(filteredSubjects, (subjects) => {
  if (!currentLevel.value || !subjects.length) return;
  const hasActive = subjects.some((s) => s.code === currentSubjectCode.value);
  if (!hasActive) currentSubjectCode.value = subjects[0].code;
});

const DB_JSON_PATH = "/data/doubts.json";
const DB_STUDENT_KEY = "sb_student_doubts_v1";
const DB_VOTED_KEY = "sb_voted_doubts_v1";
const DB_ANSWERS_KEY = "sb_doubt_answers_v1";

const dbCurrentFilter = ref("all");
const dbDoubts = ref([]);
const dbVoted = ref({});
const dbAnswers = ref({});
const dbDraftAnswers = reactive({});

const dbForm = reactive({
  subject: "",
  question: "",
});

const dbMessage = ref("");
const dbMessageType = ref("success");

function dbStorageGet(key, fallback) {
  try {
    const raw = localStorage.getItem(key);
    if (raw === null) return fallback;
    const parsed = JSON.parse(raw);
    return parsed === null ? fallback : parsed;
  } catch {
    return fallback;
  }
}

function dbStorageSet(key, value) {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch {
    // ignore quota / storage errors
  }
}

function dbNowLabel() {
  const now = new Date();
  return now.toLocaleString([], {
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function normalizeSubject(subject) {
  const value = String(subject || "")
    .trim()
    .toLowerCase();
  const map = {
    math: "Math",
    mathematics: "Math",
    stats: "Stats",
    statistics: "Stats",
    python: "Python",
    dbms: "DBMS",
    dsa: "DSA",
    ml: "ML",
    "machine learning": "ML",
    other: "Other",
    "my-doubts": "my-doubts",
    "answer-doubts": "answer-doubts",
    all: "all",
  };
  return map[value] || String(subject || "Other");
}

function hydrateDoubt(d, index = 0, prefix = "plh") {
  const subject = normalizeSubject(d.subject);
  const question = String(d.question || "").trim();
  if (!question) return null;
  const id = d.id || `${prefix}-${subject.toLowerCase()}-${index + 1}`;
  const savedAnswer = dbAnswers.value[id]
    ? String(dbAnswers.value[id].answer || "").trim()
    : "";
  return {
    id,
    subject,
    question,
    answer: savedAnswer || String(d.answer || "").trim(),
    time: String(d.time || "Recently"),
    upvotes: Number.isFinite(Number(d.upvotes)) ? Number(d.upvotes) : 0,
    isStudent: Boolean(d.isStudent),
  };
}

const myDoubtsCount = computed(
  () => dbDoubts.value.filter((d) => d.isStudent).length,
);

const filteredDoubts = computed(() => {
  const active = normalizeSubject(dbCurrentFilter.value);
  let list = dbDoubts.value;
  if (active === "my-doubts") list = list.filter((d) => d.isStudent);
  else if (active === "answer-doubts")
    list = list.filter((d) => !String(d.answer || "").trim());
  else if (active !== "all")
    list = list.filter((d) => normalizeSubject(d.subject) === active);

  const q = search.value.trim().toLowerCase();
  if (!q) return list;
  return list.filter(
    (d) =>
      d.question.toLowerCase().includes(q) ||
      String(d.answer || "")
        .toLowerCase()
        .includes(q) ||
      d.subject.toLowerCase().includes(q),
  );
});

const emptyDoubtsLabel = computed(() => {
  if (dbCurrentFilter.value === "my-doubts")
    return "You have not posted any doubts yet.";
  if (dbCurrentFilter.value === "answer-doubts")
    return "No unanswered doubts right now.";
  return "No doubts in this subject yet.";
});

function setDbFilter(filter) {
  dbCurrentFilter.value = normalizeSubject(filter);
}

function upvoteDoubt(id) {
  if (dbVoted.value[id]) return;
  dbVoted.value = { ...dbVoted.value, [id]: true };
  dbStorageSet(DB_VOTED_KEY, dbVoted.value);
}

function submitDoubt() {
  const subject = normalizeSubject(dbForm.subject);
  const question = dbForm.question.trim();

  if (!dbForm.subject || question.length < 10) {
    dbMessageType.value = "error";
    dbMessage.value =
      "⚠ Please select a subject and write at least 10 characters.";
    return;
  }

  const newDoubt = hydrateDoubt(
    {
      id: `stu-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
      subject,
      question,
      answer: "",
      time: dbNowLabel(),
      upvotes: 0,
      isStudent: true,
    },
    0,
    "stu",
  );

  if (!newDoubt) return;

  dbDoubts.value = [newDoubt, ...dbDoubts.value];
  const saved = dbStorageGet(DB_STUDENT_KEY, []);
  dbStorageSet(DB_STUDENT_KEY, [newDoubt, ...saved]);

  dbForm.subject = "";
  dbForm.question = "";
  dbCurrentFilter.value = subject;
  dbMessageType.value = "success";
  dbMessage.value =
    "✓ Your doubt has been submitted! Also visible in My Doubts.";

  setTimeout(() => {
    dbMessage.value = "";
  }, 3000);
}

function postAnswer(id) {
  const answer = String(dbDraftAnswers[id] || "").trim();
  if (answer.length < 8) return;

  dbAnswers.value = {
    ...dbAnswers.value,
    [id]: {
      answer,
      time: dbNowLabel(),
    },
  };
  dbStorageSet(DB_ANSWERS_KEY, dbAnswers.value);

  dbDoubts.value = dbDoubts.value.map((d) =>
    d.id === id ? { ...d, answer } : d,
  );
  dbDraftAnswers[id] = "";
}

async function initDoubts() {
  dbVoted.value = dbStorageGet(DB_VOTED_KEY, {});
  dbAnswers.value = dbStorageGet(DB_ANSWERS_KEY, {});

  const studentDoubtsRaw = dbStorageGet(DB_STUDENT_KEY, []);
  const studentDoubts = Array.isArray(studentDoubtsRaw)
    ? studentDoubtsRaw.map((d, i) => hydrateDoubt(d, i, "stu")).filter(Boolean)
    : [];

  let placeholderRaw = [];
  try {
    const response = await fetch(DB_JSON_PATH, { cache: "no-store" });
    if (response.ok) {
      const data = await response.json();
      if (Array.isArray(data)) placeholderRaw = data;
    }
  } catch {
    placeholderRaw = [];
  }

  const placeholders = placeholderRaw
    .map((d, i) => hydrateDoubt(d, i, "plh"))
    .filter(Boolean);

  dbDoubts.value = [...studentDoubts, ...placeholders];
}

onMounted(async () => {
  // loadLevel("foundation");
  await initDoubts();
});
</script>

<style scoped>
/* ─── Two-column layout ───────────────────────────────────── */
.sc-layout {
  display: grid;
  grid-template-columns: 280px 1fr;
  gap: 1.75rem;
  align-items: start;
}

/* ─── Left sidebar ────────────────────────────────────────── */
.sc-sidebar {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  position: sticky;
  top: 100px;
}

.sc-sidebar-hdr {
  padding-bottom: 0.75rem;
  border-bottom: 1px solid rgba(212, 160, 23, 0.15);
  margin-bottom: 0.25rem;
}

.sc-sidebar-cards {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.sc-sidebar-card {
  background: var(--surface);
  border: 1px solid rgba(212, 160, 23, 0.15);
  border-radius: 14px;
  padding: 1.6rem 1.4rem;
  cursor: pointer;
  transition: all 0.25s ease;
  position: relative;
  overflow: hidden;
}

.sc-sidebar-card:hover {
  border-color: rgba(212, 160, 23, 0.4);
  background: rgba(212, 160, 23, 0.04);
}

.sc-sidebar-card.active {
  border-color: var(--accent);
  background: rgba(212, 160, 23, 0.07);
  box-shadow: 0 0 0 2px rgba(212, 160, 23, 0.2);
}

.sc-sidebar-card.active .sc-sidebar-arrow {
  color: var(--accent);
  transform: translateX(3px);
}

.sc-sidebar-card-top {
  display: flex;
  gap: 0.75rem;
  align-items: flex-start;
  margin-bottom: 1rem;
}

.sc-sidebar-emoji {
  font-size: 1.6rem;
  flex-shrink: 0;
  line-height: 1;
  margin-top: 0.1rem;
}

.sc-sidebar-meta {
  flex: 1;
  min-width: 0;
}

.sc-sidebar-card .sc-card-title {
  font-size: 0.95rem;
  margin-bottom: 0.25rem;
}

.sc-sidebar-card .sc-card-desc {
  font-size: 0.75rem;
  margin-bottom: 0;
  line-height: 1.5;
}

.sc-sidebar-arrow {
  position: absolute;
  right: 1rem;
  bottom: 1rem;
  color: var(--text3);
  transition: all 0.2s;
}

/* ─── Right panel ─────────────────────────────────────────── */
.sc-panel-wrap {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.sc-panel-search {
  margin-bottom: 0;
  flex-shrink: 0;
}

.sc-search-input-wrap {
  position: relative;
  max-width: 420px;
}

.sc-mid-search-input {
  width: 100%;
  padding-left: 2.5rem;
}

.sc-mid-search-icon {
  position: absolute;
  left: 0.85rem;
  top: 50%;
  transform: translateY(-50%);
  color: var(--text2);
  pointer-events: none;
}

.sc-panel-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 580px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 16px;
  text-align: center;
  padding: 3rem;
  color: var(--text3);
}

/* Wrapper that holds strip + resource panel as one fixed box */
.sc-panel-body {
  display: flex;
  flex-direction: column;
  height: 580px;
  border: 1px solid var(--border);
  border-radius: 16px;
  overflow: hidden;
}

/* Subject strip: fixed top, no scroll */
.sc-subject-strip {
  background: var(--surface);
  border-bottom: 1px solid var(--border);
  border-radius: 0;
  padding: 1.25rem 1.5rem;
  flex-shrink: 0;
}

/* Resource panel: fills remaining height, scrollable */
.sc-resource-panel {
  background: var(--surface);
  padding: 1.5rem 2rem;
  flex: 1;
  overflow-y: auto;
  scrollbar-width: thin;
  scrollbar-color: rgba(212, 160, 23, 0.3) transparent;
}

.sc-resource-panel::-webkit-scrollbar {
  width: 5px;
}
.sc-resource-panel::-webkit-scrollbar-thumb {
  background: rgba(212, 160, 23, 0.3);
  border-radius: 99px;
}

/* ─── Responsive ──────────────────────────────────────────── */
@media (max-width: 900px) {
  .sc-layout {
    grid-template-columns: 1fr;
  }
  .sc-sidebar {
    position: static;
  }
  .sc-sidebar-cards {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
  }
}

.sc-level-card {
  cursor: pointer;
  transition: all 0.3s ease;
  border-color: rgba(212, 160, 23, 0.15) !important;
}

.sc-level-card:hover {
  transform: translateY(-6px);
}

.sc-level-card.active {
  border-color: var(--accent) !important;
  box-shadow: 0 0 0 2px rgba(212, 160, 23, 0.3);
}

.sc-card-emoji {
  font-size: 1.8rem;
  margin-bottom: 0.5rem;
}

.sc-card-title {
  font-family: Cinzel, serif;
  font-weight: 700;
  margin-bottom: 0.4rem;
  font-size: 1.1rem;
}

.sc-card-desc {
  font-size: 0.82rem;
  margin-bottom: 1rem;
}

.sc-card-stats {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
  margin-bottom: 1rem;
}

.sc-stat-badge {
  font-size: 0.68rem;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  background: rgba(212, 160, 23, 0.1);
  color: var(--accent);
  border: 1px solid rgba(212, 160, 23, 0.25);
  padding: 0.2rem 0.6rem;
  border-radius: 99px;
}

.sc-browse-btn {
  font-size: 0.82rem;
  padding: 0.5rem 1.1rem;
  pointer-events: none;
}

.sc-strip-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}

.sc-strip-label {
  font-family: Cinzel, serif;
  font-weight: 700;
  font-size: 1rem;
}

.sc-badges-row {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.sc-back-btn,
.db-filter,
.db-upvote,
.sc-tab,
.sc-subj-badge {
  background: none;
  border: 1px solid var(--border);
  color: var(--text2);
  border-radius: 99px;
  font-family: inherit;
  cursor: pointer;
  transition: all 0.2s;
}

.sc-back-btn {
  padding: 0.35rem 0.9rem;
  font-size: 0.78rem;
}

.sc-subj-badge {
  padding: 0.4rem 0.9rem;
  font-size: 0.82rem;
}

.sc-subj-badge.active,
.sc-tab.active,
.db-filter.active {
  background: var(--accent);
  border-color: var(--accent);
  color: #000;
  font-weight: 700;
}

.sc-tab-bar {
  display: flex;
  gap: 0.5rem;
  margin: 1.5rem 0 1.25rem;
  flex-wrap: wrap;
}

.sc-tab {
  padding: 0.45rem 1.1rem;
  font-size: 0.82rem;
}

.sc-resource-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.85rem 1rem;
  background: rgba(212, 160, 23, 0.03);
  border: 1px solid var(--border);
  border-radius: 10px;
  text-decoration: none;
  color: var(--text);
  font-size: 0.88rem;
  transition: all 0.2s;
  margin-bottom: 0.5rem;
}

.sc-resource-item:hover {
  background: rgba(212, 160, 23, 0.08);
}

.sc-badge {
  font-size: 0.65rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  background: rgba(212, 160, 23, 0.15);
  color: var(--accent);
  border: 1px solid rgba(212, 160, 23, 0.3);
  padding: 0.15rem 0.55rem;
  border-radius: 99px;
}

.sc-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 3rem;
  color: var(--text3);
  gap: 0.75rem;
}

.sc-author-card {
  background: rgba(212, 160, 23, 0.04);
  border: 1px solid var(--border);
  border-radius: 12px;
  margin-bottom: 0.75rem;
  overflow: hidden;
}

.sc-author-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.85rem 1.15rem;
  cursor: pointer;
}

.sc-author-name {
  font-weight: 600;
  font-size: 0.9rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.sc-author-count {
  font-size: 0.7rem;
  color: var(--text3);
}

.sc-author-body {
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.35s ease;
}

.sc-author-body.open {
  max-height: 2000px;
}

.sc-author-notes {
  padding: 0 1rem 1rem;
}

.sc-year-group {
  margin-bottom: 1.25rem;
}

.sc-year-label {
  font-family: Cinzel, serif;
  font-weight: 700;
  font-size: 0.9rem;
  color: var(--accent);
  margin-bottom: 0.5rem;
  padding-bottom: 0.35rem;
  border-bottom: 1px solid rgba(212, 160, 23, 0.15);
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.sc-year-count {
  font-size: 0.7rem;
  color: var(--text3);
  font-weight: 400;
}

.db-filter {
  padding: 0.4rem 1rem;
  font-size: 0.8rem;
}

.db-scroll-box {
  max-width: 820px;
  margin: 0 auto 3rem;
  height: 560px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 1rem;
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 1.25rem;
  scrollbar-width: thin;
  scrollbar-color: rgba(212, 160, 23, 0.3) transparent;
}

.db-scroll-box::-webkit-scrollbar {
  width: 5px;
}
.db-scroll-box::-webkit-scrollbar-thumb {
  background: rgba(212, 160, 23, 0.3);
  border-radius: 99px;
}

.db-card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: 1.25rem 1.5rem;
}

.db-tag {
  display: inline-block;
  font-size: 0.65rem;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  background: rgba(212, 160, 23, 0.1);
  color: var(--accent);
  border: 1px solid rgba(212, 160, 23, 0.25);
  padding: 0.15rem 0.55rem;
  border-radius: 99px;
  margin-bottom: 0.75rem;
}

.db-question {
  font-size: 0.95rem;
  font-weight: 500;
  margin-bottom: 0.5rem;
  line-height: 1.5;
}

.db-answer {
  font-size: 0.85rem;
  color: var(--text2);
  line-height: 1.6;
  margin-bottom: 0.75rem;
  padding-left: 0.75rem;
  border-left: 2px solid rgba(212, 160, 23, 0.25);
}

.db-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 0.75rem;
  color: var(--text3);
}

.db-upvote {
  padding: 0.25rem 0.65rem;
  font-size: 0.75rem;
}

.db-upvote:disabled {
  border-color: var(--accent);
  color: var(--accent);
}

.db-input {
  width: 100%;
  background: rgba(212, 160, 23, 0.04);
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 0.75rem 1rem;
  color: var(--text);
  font-family: inherit;
  font-size: 0.9rem;
  transition: border-color 0.2s;
  box-sizing: border-box;
}

.db-input:focus {
  outline: none;
  border-color: var(--accent);
}

.db-input option {
  background: var(--bg2);
  color: var(--text);
}

@media (max-width: 768px) {
  .sc-sidebar-cards {
    grid-template-columns: 1fr;
  }

  .sc-badges-row {
    max-height: 200px;
    overflow-y: auto;
  }

  .sc-contrib-grid {
    grid-template-columns: 1fr !important;
  }
}

/* ─── Study Planner ─────────────────────────────────────────────────── */
.sp-planner-wrap {
  background: var(--surface);
  border: 1px solid rgba(212,160,23,0.18);
  border-radius: 18px;
  padding: 1.75rem;
  margin-top: 0.5rem;
}

.sp-week-nav {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1.5rem;
  flex-wrap: wrap;
}

.sp-week-label {
  font-family: Cinzel, serif;
  font-weight: 700;
  font-size: 1rem;
  color: var(--text);
  flex: 1;
  text-align: center;
}

.sp-nav-btn {
  background: rgba(212,160,23,0.08);
  border: 1px solid rgba(212,160,23,0.25);
  color: var(--accent);
  border-radius: 8px;
  padding: 0.35rem 0.85rem;
  cursor: pointer;
  font-size: 1rem;
  transition: background 0.2s;
}
.sp-nav-btn:hover { background: rgba(212,160,23,0.16); }

.sp-today-btn { font-size: 0.75rem !important; padding: 0.35rem 0.75rem !important; }

.sp-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.6rem;
  margin-bottom: 1.5rem;
}

.sp-day-col {
  background: rgba(255,255,255,0.02);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 0.75rem 0.6rem;
  min-height: 200px;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  transition: border-color 0.2s;
}

.sp-day-col.sp-today {
  border-color: rgba(212,160,23,0.5);
  background: rgba(212,160,23,0.05);
}

.sp-day-header {
  text-align: center;
  margin-bottom: 0.4rem;
}

.sp-day-name {
  font-family: Cinzel, serif;
  font-weight: 700;
  font-size: 0.75rem;
  color: var(--accent);
  display: block;
}

.sp-day-date {
  font-size: 0.65rem;
  color: var(--text3);
}

.sp-tasks { flex: 1; display: flex; flex-direction: column; gap: 0.35rem; }

.sp-task {
  display: flex;
  align-items: flex-start;
  gap: 0.3rem;
  background: rgba(212,160,23,0.04);
  border: 1px solid var(--border);
  border-radius: 7px;
  padding: 0.35rem 0.4rem;
  cursor: pointer;
  transition: all 0.15s;
  font-size: 0.72rem;
}

.sp-task:hover { background: rgba(212,160,23,0.1); }
.sp-task.sp-done { opacity: 0.5; }
.sp-task.sp-done .sp-task-text { text-decoration: line-through; }

.sp-check {
  color: var(--accent);
  font-size: 0.65rem;
  min-width: 10px;
  margin-top: 1px;
}

.sp-task-text { flex: 1; line-height: 1.3; word-break: break-word; }

.sp-del {
  background: none;
  border: none;
  color: var(--text3);
  cursor: pointer;
  font-size: 0.85rem;
  line-height: 1;
  padding: 0;
  opacity: 0;
  transition: opacity 0.15s;
}
.sp-task:hover .sp-del { opacity: 1; }

.sp-empty-day { font-size: 0.65rem; color: var(--text3); text-align: center; padding: 0.5rem 0; }

.sp-add-wrap { display: flex; gap: 0.3rem; }
.sp-add-input {
  flex: 1;
  background: rgba(212,160,23,0.04);
  border: 1px solid var(--border);
  border-radius: 7px;
  padding: 0.3rem 0.4rem;
  color: var(--text);
  font-size: 0.68rem;
  font-family: inherit;
  min-width: 0;
}
.sp-add-input:focus { outline: none; border-color: var(--accent); }

.sp-add-btn {
  background: rgba(212,160,23,0.12);
  border: 1px solid rgba(212,160,23,0.3);
  color: var(--accent);
  border-radius: 7px;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 1rem;
  flex-shrink: 0;
}
.sp-add-btn:hover { background: rgba(212,160,23,0.22); }

.sp-progress-wrap { margin-top: 0.5rem; }
.sp-progress-label { font-size: 0.8rem; color: var(--text2); margin-bottom: 0.4rem; }
.sp-progress-bar {
  height: 6px;
  background: rgba(212,160,23,0.1);
  border-radius: 99px;
  overflow: hidden;
}
.sp-progress-fill {
  height: 100%;
  background: var(--accent);
  border-radius: 99px;
  transition: width 0.4s ease;
}

@media (max-width: 900px) {
  .sp-grid { grid-template-columns: repeat(4, 1fr); }
}
@media (max-width: 600px) {
  .sp-grid { grid-template-columns: repeat(2, 1fr); }
}

/* ─── Exam Cities ───────────────────────────────────────────────────── */
.ec-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 1rem;
  margin-bottom: 1rem;
}

.ec-card { padding: 1.1rem 1.25rem; }

.ec-state {
  font-family: Cinzel, serif;
  font-weight: 700;
  font-size: 0.82rem;
  color: var(--accent);
  margin-bottom: 0.6rem;
  padding-bottom: 0.4rem;
  border-bottom: 1px solid rgba(212,160,23,0.15);
}

.ec-cities-list { display: flex; flex-wrap: wrap; gap: 0.35rem; }

.ec-city-tag {
  font-size: 0.72rem;
  background: rgba(212,160,23,0.06);
  border: 1px solid rgba(212,160,23,0.15);
  color: var(--text2);
  padding: 0.18rem 0.55rem;
  border-radius: 99px;
}

.ec-info-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
}

.ec-info-card {
  padding: 1.5rem;
  text-align: center;
}

@media (max-width: 700px) {
  .ec-info-row { grid-template-columns: 1fr; }
}

</style>
