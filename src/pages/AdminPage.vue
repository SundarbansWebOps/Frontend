<!--
  The admin lounge, opened from the Lounge's profile menu by Regional Coordinators and Super
  Admins (the router keeps everyone else out; the database checks every call again).
  RC: students and roster of their region, all events, their own requests.
  Super Admin: everything an RC can do in every region, plus the approval queue, positions and
  the audit log. Every change to a student is a request that a different Super Admin approves.
-->
<template>
  <main class="wrap">
    <header class="head rise" style="--i: 0">
      <div>
        <p class="adm-kicker">{{ roleLabel }}</p>
        <h1>Admin lounge</h1>
      </div>
      <dl class="stats">
        <div v-for="s in STATS" :key="s.key">
          <dt>{{ s.label }}</dt>
          <dd class="mono">{{ counts[s.key] ?? '–' }}</dd>
        </div>
      </dl>
      <div class="who">
        <p class="sub">
          Signed in as <b>{{ auth.profile?.preferred_name || auth.profile?.full_name }}</b
          >.
          {{ scopeNote }}
        </p>
        <div class="acts">
          <RouterLink class="adm-btn ghost small" to="/lounge">
            <LineIcon class="ic" name="back" /> Lounge
          </RouterLink>
          <button type="button" class="adm-btn ghost small" @click="leave">Sign out</button>
        </div>
      </div>
    </header>

    <nav class="tabs rise" style="--i: 1" aria-label="Admin sections">
      <div class="chips" role="tablist">
        <button
          v-for="t in tabs"
          :key="t.id"
          type="button"
          role="tab"
          class="chip"
          :class="{ on: tab === t.id }"
          :aria-selected="tab === t.id"
          @click="setTab(t.id)"
        >
          {{ t.label }}
          <b v-if="t.id === 'requests' && counts.pending" class="dot mono">{{ counts.pending }}</b>
        </button>
      </div>
    </nav>

    <p v-if="loadError" class="adm-msg err" role="alert">{{ loadError }}</p>

    <section v-if="lookups" class="sec rise" style="--i: 2" :aria-labelledby="`${tab}-h`">
      <h2 :id="`${tab}-h`" class="sec-h">
        <span class="mono">{{
          String(tabs.findIndex((t) => t.id === tab) + 1).padStart(2, '0')
        }}</span>
        {{ current.label }}
      </h2>
      <p class="sec-sub">{{ current.sub }}</p>
      <component :is="current.component" :lookups="lookups" @changed="refreshCounts" />
    </section>
  </main>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import LineIcon from '../components/site/LineIcon.vue';
import AdminStudents from '../components/admin/AdminStudents.vue';
import AdminRoster from '../components/admin/AdminRoster.vue';
import AdminEvents from '../components/admin/AdminEvents.vue';
import AdminRequests from '../components/admin/AdminRequests.vue';
import AdminPositions from '../components/admin/AdminPositions.vue';
import AdminAudit from '../components/admin/AdminAudit.vue';
import '../components/admin/admin.css';
import { auth, errorText, isSuperAdmin, signOut } from '../lib/auth.js';
import { loadCounts, loadLookups } from '../lib/admin.js';

const route = useRoute();
const router = useRouter();

const ALL_TABS = [
  {
    id: 'students',
    label: 'Students',
    component: AdminStudents,
    sub: 'Find a student, see their details and ask for a change. A Super Admin approves every change.',
  },
  {
    id: 'roster',
    label: 'Roster',
    component: AdminRoster,
    sub: 'Add students before their first sign-in. Only emails on the roster can sign in with Google.',
  },
  {
    id: 'events',
    label: 'Events',
    component: AdminEvents,
    sub: 'Create, edit, cancel or remove house and community events.',
  },
  {
    id: 'requests',
    label: 'Requests',
    component: AdminRequests,
    sub: '',
  },
  {
    id: 'positions',
    label: 'Positions',
    component: AdminPositions,
    sub: 'Who coordinates each region and leads each community. Changes need a second Super Admin.',
    superAdmin: true,
  },
  {
    id: 'audit',
    label: 'Audit log',
    component: AdminAudit,
    sub: 'Every change, who made it and when. Nothing here can be edited.',
    superAdmin: true,
  },
];

const tabs = computed(() =>
  ALL_TABS.filter((t) => !t.superAdmin || isSuperAdmin.value).map((t) =>
    t.id === 'requests'
      ? {
          ...t,
          sub: isSuperAdmin.value
            ? 'Changes waiting for a Super Admin. You can approve anyone’s request except your own.'
            : 'Your requests and what a Super Admin decided.',
        }
      : t
  )
);
const tab = computed(() =>
  tabs.value.some((t) => t.id === route.query.tab) ? route.query.tab : 'students'
);
const current = computed(() => tabs.value.find((t) => t.id === tab.value));
function setTab(id) {
  router.replace({ query: { tab: id } });
}

const STATS = [
  { key: 'members', label: 'students' },
  { key: 'roster', label: 'on roster' },
  { key: 'events', label: 'upcoming events' },
  { key: 'pending', label: 'pending requests' },
];
const counts = reactive({});
const lookups = ref(null);
const loadError = ref('');

const regionName = computed(
  () => lookups.value?.regions.find((r) => r.id === auth.dashboard?.region_id)?.name ?? ''
);
const roleLabel = computed(() =>
  isSuperAdmin.value
    ? 'Super Admin'
    : `Regional Coordinator${regionName.value ? ` · ${regionName.value}` : ''}`
);
const scopeNote = computed(() =>
  isSuperAdmin.value
    ? 'You see every region.'
    : `You see students in ${regionName.value || 'your region'} and every event.`
);

async function refreshCounts() {
  try {
    Object.assign(counts, await loadCounts());
  } catch (e) {
    loadError.value = errorText(e);
  }
}

onMounted(async () => {
  try {
    lookups.value = await loadLookups();
  } catch (e) {
    loadError.value = errorText(e);
  }
  refreshCounts();
});

async function leave() {
  await signOut().catch(() => {});
  router.push('/login');
}
</script>

<style scoped>
.wrap {
  max-width: 1240px;
  margin: 0 auto;
  padding: 18px 24px 80px;
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 18px;
}
.head {
  display: grid;
  grid-template-columns: auto 1fr;
  align-items: end;
  gap: 4px 28px;
}
h1 {
  margin: 0;
  font-size: clamp(34px, 4.4vw, 48px);
  font-weight: 750;
  letter-spacing: -0.04em;
  line-height: 0.95;
}
.stats {
  display: flex;
  justify-content: flex-end;
  gap: 26px;
  margin: 0;
}
.stats div {
  display: flex;
  flex-direction: column-reverse;
  align-items: flex-end;
}
.stats dt {
  font-size: 12px;
  color: var(--ink-2);
}
.stats dd {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
  letter-spacing: -0.04em;
  line-height: 1;
  font-variant-numeric: tabular-nums;
}
.who {
  grid-column: 1 / -1;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 10px 18px;
  margin-top: 6px;
}
.sub {
  margin: 0;
  max-width: 62ch;
  font-size: 15px;
  color: var(--ink-2);
}
.sub b {
  color: var(--ink);
  font-weight: 650;
}
.acts {
  display: flex;
  gap: 8px;
}
.tabs {
  position: sticky;
  top: calc(var(--nav-h) + 8px);
  z-index: 20;
  justify-self: start;
  max-width: 100%;
}
.chips {
  display: flex;
  gap: 4px;
  padding: 4px;
  border-radius: 99px;
  background: color-mix(in srgb, var(--sunk) 88%, transparent);
  backdrop-filter: blur(10px);
  box-shadow: var(--shadow);
  overflow-x: auto;
  scrollbar-width: none;
}
.chip {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 15px;
  border: 0;
  border-radius: 99px;
  background: transparent;
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  color: var(--ink-2);
  white-space: nowrap;
  cursor: pointer;
  transition:
    color 0.25s,
    background 0.35s var(--ease-out);
}
.chip:hover {
  color: var(--ink);
}
.chip.on {
  background: var(--ink);
  color: var(--paper);
}
.dot {
  min-width: 20px;
  padding: 1px 6px;
  border-radius: 99px;
  background: var(--mari);
  color: var(--on-mari);
  font-size: 11.5px;
  font-weight: 700;
}
.sec {
  padding-top: 18px;
}
.sec-h {
  margin: 0 0 22px;
  font-size: clamp(24px, 2.6vw, 30px);
  font-weight: 750;
  letter-spacing: -0.035em;
}
.sec-h span {
  margin-right: 8px;
  font-size: 13px;
  font-weight: 500;
  color: var(--mari-ink);
  vertical-align: 0.5em;
}
.sec-sub {
  margin: -12px 0 22px;
  max-width: 62ch;
  font-size: 15px;
  line-height: 1.5;
  color: var(--ink-2);
}
@media (max-width: 900px) {
  .head {
    grid-template-columns: 1fr;
  }
  .stats {
    justify-content: flex-start;
    flex-wrap: wrap;
  }
  .stats div {
    align-items: flex-start;
  }
}
@media (max-width: 560px) {
  .wrap {
    padding: 14px 16px 90px;
  }
  .chip {
    padding: 8px 12px;
    font-size: 13.5px;
  }
}
</style>
