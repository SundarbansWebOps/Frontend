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
              </div>
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
            Handy <span class="tg">tools</span> for studying
          </h2>
        </div>
        <div class="grid-3" style="margin-bottom: 1.5rem">
          <div class="card-base rc" style="--card-delay: 0.1s">
            <div style="font-size: 1.5rem; margin-bottom: 0.5rem">⏱️</div>
            <h4 style="font-family: Cinzel, serif; font-weight: 700">
              Pomodoro Timer
            </h4>
            <p class="desc" style="font-size: 0.82rem">
              Study in focused 25-minute blocks
            </p>
            <a
              href="#"
              style="
                color: var(--accent);
                font-size: 0.82rem;
                font-weight: 600;
                text-decoration: none;
              "
              >Use Tool -&gt;</a
            >
          </div>
          <div class="card-base rc" style="--card-delay: 0.2s">
            <div style="font-size: 1.5rem; margin-bottom: 0.5rem">📝</div>
            <h4 style="font-family: Cinzel, serif; font-weight: 700">
              Doubt Board
            </h4>
            <p class="desc" style="font-size: 0.82rem">
              Post your doubts, get peer answers
            </p>
            <a
              href="#doubtBoard"
              style="
                color: var(--accent);
                font-size: 0.82rem;
                font-weight: 600;
                text-decoration: none;
              "
              >Open Board -&gt;</a
            >
          </div>
          <div class="card-base rc" style="--card-delay: 0.3s">
            <div style="font-size: 1.5rem; margin-bottom: 0.5rem">📅</div>
            <h4 style="font-family: Cinzel, serif; font-weight: 700">
              Study Planner
            </h4>
            <p class="desc" style="font-size: 0.82rem">
              Plan your week, track your progress
            </p>
            <a
              href="#"
              style="
                color: var(--accent);
                font-size: 0.82rem;
                font-weight: 600;
                text-decoration: none;
              "
              >Plan Now -&gt;</a
            >
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

        <div
          style="
            display: flex;
            flex-direction: column;
            gap: 1rem;
            max-width: 820px;
            margin: 0 auto 3rem;
          ">
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
  gap: 0.65rem;
}

.sc-sidebar-card {
  background: var(--surface);
  border: 1px solid rgba(212, 160, 23, 0.15);
  border-radius: 14px;
  padding: 1.1rem 1.25rem;
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
  margin-bottom: 0.75rem;
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
  gap: 0;
  min-height: 520px;
}

.sc-panel-search {
  margin-bottom: 1.25rem;
}

.sc-panel-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  flex: 1;
  min-height: 400px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 16px;
  text-align: center;
  padding: 3rem;
  color: var(--text3);
}

.sc-resource-panel {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 0 0 16px 16px;
  padding: 2rem;
  min-height: 360px;
  border-top: none;
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

.sc-subject-strip {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 16px 16px 0 0;
  padding: 1.25rem 1.5rem;
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
</style>
