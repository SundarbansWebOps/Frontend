<!--
  The admin lounge, opened from the Lounge's profile menu by Regional Coordinators, community
  Heads/Co-Heads and Super Admins (the router keeps everyone else out; the database checks every
  call again). RC: students and roster of their region, own-region events/forms/notices, requests.
  Head/Co-Head: own community events and forms. Super Admin: house-wide plus every region and
  community, the approval queue, positions and the audit log. Admin-initiated student changes
  still need a different Super Admin. Student region corrections are reviewed by the current-region
  RC or a Super Admin.
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

    <section
      v-if="lookups && current"
      class="sec rise"
      style="--i: 2"
      :aria-labelledby="`${tab}-h`"
    >
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
import AdminForms from '../components/admin/AdminForms.vue';
import AdminNotices from '../components/admin/AdminNotices.vue';
import AdminRequests from '../components/admin/AdminRequests.vue';
import AdminPositions from '../components/admin/AdminPositions.vue';
import AdminAudit from '../components/admin/AdminAudit.vue';
import '../components/admin/admin.css';
import { auth, errorText, isRc, isSuperAdmin, signOut } from '../lib/auth.js';
import { loadCounts, loadLookups } from '../lib/admin.js';

const route = useRoute();
const router = useRouter();

const position = computed(() => auth.dashboard?.position);
const isHead = computed(() => position.value === 'head' || position.value === 'co_head');
const membersTabs = computed(() => isSuperAdmin.value || isRc.value);

const ALL_TABS = [
  {
    id: 'students',
    label: 'Students',
    component: AdminStudents,
    members: true,
    sub: 'Find a student, see their details and ask for a change. A Super Admin approves every admin-initiated change.',
  },
  {
    id: 'roster',
    label: 'Roster',
    component: AdminRoster,
    members: true,
    sub: 'Add students before their first sign-in. Only emails on the roster can sign in with Google. Name and region may be left empty.',
  },
  {
    id: 'events',
    label: 'Events',
    component: AdminEvents,
    sub: 'Draft, publish and unpublish events in your scope. Attendance and certificates live on each event.',
  },
  {
    id: 'forms',
    label: 'Forms',
    component: AdminForms,
    sub: 'House-themed forms, group applications and event registration. Invite links appear to students only after they submit.',
  },
  {
    id: 'notices',
    label: 'Notices',
    component: AdminNotices,
    sub: 'House, region or community notices, with optional cohort targeting. Group applications live on Forms, with the WhatsApp invite shown after submit.',
  },
  {
    id: 'requests',
    label: 'Requests',
    component: AdminRequests,
    members: true,
    sub: '',
  },
  {
    id: 'positions',
    label: 'Positions',
    component: AdminPositions,
    superAdmin: true,
    sub: 'Up to two Regional Coordinators per region, and a Head and Co-Head per community. Super Admin accounts are fixed.',
  },
  {
    id: 'audit',
    label: 'Audit log',
    component: AdminAudit,
    superAdmin: true,
    sub: 'Every change, who made it and when. Nothing here can be edited.',
  },
];

const tabs = computed(() =>
  ALL_TABS.filter((t) => {
    if (t.superAdmin) return isSuperAdmin.value;
    if (t.members) return membersTabs.value;
    return true;
  }).map((t) =>
    t.id === 'requests'
      ? {
          ...t,
          sub: isSuperAdmin.value
            ? 'Student region corrections, certificate-name corrections, and admin changes waiting for a different Super Admin.'
            : 'Student region corrections for your region, and the admin changes you asked for.',
        }
      : t
  )
);
const tab = computed(() =>
  tabs.value.some((t) => t.id === route.query.tab) ? route.query.tab : tabs.value[0]?.id
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
const communityName = computed(
  () => lookups.value?.communities.find((c) => c.id === auth.dashboard?.community_id)?.name ?? ''
);
const roleLabel = computed(() => {
  if (isSuperAdmin.value) return 'Super Admin';
  if (isHead.value)
    return `${position.value === 'co_head' ? 'Co-Head' : 'Head'}${communityName.value ? ` · ${communityName.value}` : ''}`;
  return `Regional Coordinator${regionName.value ? ` · ${regionName.value}` : ''}`;
});
const scopeNote = computed(() => {
  if (isSuperAdmin.value) return 'You see every region and community.';
  if (isHead.value)
    return `You manage events, forms and notices for ${communityName.value || 'your community'}. You cannot open the student list.`;
  return `You see students in ${regionName.value || 'your region'}, and events, forms and notices for that region.`;
});

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
