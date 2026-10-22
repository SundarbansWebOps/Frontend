<!-- Audit log (Super Admin): every admin action, newest first. Filters live in the route query, so a
     filtered view (or one member's timeline, ?tab=audit&member=<uuid>) can be linked and restored. -->
<template>
  <div class="audit">
    <div class="bar">
      <label class="search">
        <span class="visually-hidden">Search activity</span>
        <LineIcon name="search" />
        <input
          v-model="qText"
          class="adm-input"
          type="search"
          placeholder="Search name, code or id"
          autocomplete="off"
          maxlength="100"
          @input="typed"
        />
      </label>
      <button
        type="button"
        class="adm-btn ghost filters-toggle"
        :aria-expanded="filtersOpen"
        aria-controls="audit-filters"
        @click="filtersOpen = !filtersOpen"
      >
        {{ activeCount ? `Filters (${activeCount})` : 'Filters' }}
      </button>
    </div>

    <div id="audit-filters" class="filters" :class="{ open: filtersOpen }">
      <div class="frow">
        <span id="audit-when" class="flabel">When</span>
        <div class="fctl">
          <div class="adm-chips scroll" role="group" aria-labelledby="audit-when">
            <button
              v-for="r in RANGES"
              :key="r.id"
              type="button"
              class="adm-chip"
              :class="{ on: f.range === r.id }"
              :aria-pressed="f.range === r.id"
              @click="set({ range: r.id, from: '', to: '' })"
            >
              {{ r.label }}
            </button>
          </div>
          <div v-if="f.range === 'custom'" class="dates">
            <label class="adm-field"
              ><span>From</span
              ><input
                class="adm-input"
                type="date"
                :value="f.from"
                :max="f.to || undefined"
                @change="set({ from: $event.target.value })"
            /></label>
            <label class="adm-field"
              ><span>To</span
              ><input
                class="adm-input"
                type="date"
                :value="f.to"
                :min="f.from || undefined"
                @change="set({ to: $event.target.value })"
            /></label>
          </div>
        </div>
      </div>

      <div class="frow">
        <span id="audit-cat" class="flabel">Area</span>
        <div class="fctl">
          <div class="adm-chips scroll" role="group" aria-labelledby="audit-cat">
            <button
              type="button"
              class="adm-chip"
              :class="{ on: !f.cat }"
              :aria-pressed="!f.cat"
              @click="set({ cat: '', act: [] })"
            >
              Everything
            </button>
            <button
              v-for="c in CATEGORIES"
              :key="c.id"
              type="button"
              class="adm-chip"
              :class="{ on: f.cat === c.id }"
              :aria-pressed="f.cat === c.id"
              @click="set({ cat: c.id, act: [] })"
            >
              {{ c.label }}
            </button>
          </div>
          <details v-if="f.cat" ref="actionsBox" class="pick" @keydown.esc="closeActions">
            <summary class="adm-chip" :class="{ on: f.act.length }">
              {{ f.act.length ? `Actions (${f.act.length})` : 'All actions' }}
            </summary>
            <fieldset class="pop">
              <legend class="visually-hidden">Actions in {{ categoryLabel }}</legend>
              <label v-for="a in actionsIn(f.cat)" :key="a.id" class="adm-check">
                <input
                  type="checkbox"
                  :checked="f.act.includes(a.id)"
                  @change="toggleAction(a.id, $event.target.checked)"
                />
                <span
                  >{{ a.label }}<small class="mono">{{ a.id }}</small></span
                >
              </label>
            </fieldset>
          </details>
        </div>
      </div>

      <div class="frow">
        <span id="audit-role" class="flabel">Done by</span>
        <div class="fctl">
          <div class="adm-chips scroll" role="group" aria-labelledby="audit-role">
            <button
              type="button"
              class="adm-chip"
              :class="{ on: !f.role }"
              :aria-pressed="!f.role"
              @click="set({ role: '' })"
            >
              Everyone
            </button>
            <button
              v-for="r in ROLES"
              :key="r.id"
              type="button"
              class="adm-chip"
              :class="{ on: f.role === r.id }"
              :aria-pressed="f.role === r.id"
              @click="set({ role: r.id })"
            >
              {{ r.label }}
            </button>
          </div>
          <div class="actor">
            <span v-if="f.actor" class="adm-chip on picked">
              {{ nameOf(f.actor) }}
              <button type="button" class="x" @click="set({ actor: '' })">
                <LineIcon name="close" /><span class="visually-hidden"
                  >Stop filtering by {{ nameOf(f.actor) }}</span
                >
              </button>
            </span>
            <template v-else>
              <label class="visually-hidden" for="audit-actor">One admin</label>
              <input
                id="audit-actor"
                v-model="actorText"
                class="adm-input actor-input"
                type="search"
                placeholder="One admin…"
                autocomplete="off"
                maxlength="100"
                @input="findActor"
                @keydown.esc="actorHits = []"
              />
              <ul v-if="actorHits.length" class="hits" aria-label="Matching members">
                <li v-for="m in actorHits" :key="m.id">
                  <button type="button" @click="pickActor(m)">
                    <b>{{ m.preferred_name || m.full_name }}</b
                    ><small class="mono">{{ m.member_code }}</small>
                  </button>
                </li>
              </ul>
            </template>
          </div>
          <button
            v-if="activeCount"
            type="button"
            class="adm-btn ghost small clear"
            @click="clearAll"
          >
            Clear ({{ activeCount }})
          </button>
        </div>
      </div>
    </div>

    <div v-if="f.member" class="timeline">
      <p class="tl-label">
        Everything involving <b>{{ nameOf(f.member) }}</b>
      </p>
      <button type="button" class="adm-btn ghost small" @click="set({ member: '' })">
        <LineIcon name="close" />Show everyone
      </button>
    </div>

    <p v-if="error" class="adm-msg err" role="alert">
      {{ error }}
      <button type="button" class="retry" @click="load(lastMore)">Try again</button>
    </p>

    <div class="feed" :class="{ busy: loading && rows.length }" :aria-busy="loading">
      <section v-for="day in days" :key="day.key" :aria-labelledby="`day-${day.key}`">
        <h3 :id="`day-${day.key}`" class="day">{{ day.label }}</h3>
        <ul class="entries">
          <li
            v-for="e in day.entries"
            :key="e.head.id"
            class="entry"
            :class="{ open: openIds.has(e.head.id), fail: e.failed }"
          >
            <span class="avatar" aria-hidden="true">{{ initial(e.say.parts[0]) }}</span>
            <div class="body">
              <p class="say">
                <template v-for="(p, i) in e.say.parts" :key="i"
                  ><template v-if="typeof p === 'string'">{{ p }}</template
                  ><button
                    v-else-if="p.person"
                    type="button"
                    class="who"
                    :title="`Everything involving ${p.text}`"
                    @click="timeline(p.person, p.text)"
                  >
                    {{ p.text }}</button
                  ><button
                    v-else-if="p.record && i === e.recordIndex && e.link"
                    type="button"
                    class="rec"
                    @click="emit('navigate', e.link[0], e.link[1])"
                  >
                    {{ p.text }}</button
                  ><b v-else>{{ p.text }}</b
                  ><template v-if="p.suffix">{{ p.suffix }}</template></template
                ><span v-if="e.say.note" class="note"> · {{ clip(e.say.note) }}</span>
              </p>
              <div class="meta">
                <span>{{ e.category }}</span>
                <span v-if="e.role" class="adm-badge">{{ e.role }}</span>
                <time :datetime="e.head.created_at" :title="exact(e.head.created_at)">{{
                  ago(e.head.created_at)
                }}</time>
                <span v-if="e.failed" class="adm-badge verm">Failed</span>
                <button
                  v-if="e.head.request_id"
                  type="button"
                  class="lnk"
                  @click="emit('navigate', 'requests', e.head.request_id)"
                >
                  Request <LineIcon name="next" />
                </button>
                <span v-if="e.also.length">+{{ e.also.length }} linked</span>
              </div>
            </div>
            <button
              type="button"
              class="chev"
              :aria-expanded="openIds.has(e.head.id)"
              :aria-controls="`audit-d-${e.head.id}`"
              @click="toggle(e.head.id)"
            >
              <LineIcon name="next" /><span class="visually-hidden">Details of {{ e.label }}</span>
            </button>
            <div v-if="openIds.has(e.head.id)" :id="`audit-d-${e.head.id}`" class="detail">
              <div v-for="(r, ri) in [e.head, ...e.also]" :key="r.id" class="part">
                <p v-if="ri === 1" class="also-h">Recorded in the same change</p>
                <p v-if="ri > 0" class="also">
                  <span class="mono">{{ r.action }}</span> {{ plain(r) }}
                </p>
                <div v-if="diffOf(r).length" class="adm-table-wrap">
                  <table class="adm-table stack diff">
                    <thead>
                      <tr>
                        <th scope="col">Field</th>
                        <th scope="col">Before</th>
                        <th scope="col">After</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="d in diffOf(r)" :key="d.key" :class="{ changed: d.changed }">
                        <th scope="row" class="mono k">{{ d.key }}</th>
                        <td data-label="Before" :class="{ none: d.before === '—' }">
                          {{ d.before }}
                        </td>
                        <td data-label="After" :class="{ none: d.after === '—' }">
                          {{ d.after }}
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
                <p v-else class="adm-note quiet">No values were recorded with this action.</p>
                <dl class="facts">
                  <div>
                    <dt>Action</dt>
                    <dd class="mono">{{ r.action }}</dd>
                  </div>
                  <div v-if="r.target_table">
                    <dt>Record</dt>
                    <dd class="mono">{{ r.target_table }} · {{ r.target_id ?? '—' }}</dd>
                  </div>
                  <div v-if="r.actor_code">
                    <dt>By</dt>
                    <dd class="mono">{{ r.actor_code }}</dd>
                  </div>
                  <div v-if="r.subject_code">
                    <dt>About</dt>
                    <dd class="mono">{{ r.subject_code }}</dd>
                  </div>
                  <div>
                    <dt>When</dt>
                    <dd class="mono">{{ exact(r.created_at) }}</dd>
                  </div>
                  <div>
                    <dt>Entry</dt>
                    <dd class="mono">#{{ r.id }}</dd>
                  </div>
                </dl>
              </div>
              <div class="links">
                <button
                  v-if="e.head.subject_id && e.head.subject_name"
                  type="button"
                  class="adm-btn ghost small"
                  @click="emit('navigate', 'students', e.head.subject_id)"
                >
                  Open student
                </button>
                <button
                  v-if="e.link"
                  type="button"
                  class="adm-btn ghost small"
                  @click="emit('navigate', e.link[0], e.link[1])"
                >
                  Open in {{ TAB_LABEL[e.link[0]] }}
                </button>
                <details class="raw">
                  <summary>Raw JSON</summary>
                  <pre class="mono">{{ JSON.stringify([e.head, ...e.also], null, 2) }}</pre>
                </details>
              </div>
            </div>
          </li>
        </ul>
      </section>

      <p v-if="!rows.length && loading" class="adm-note" role="status">Loading activity…</p>
      <div v-else-if="!rows.length && loaded && !error" class="adm-empty">
        <template v-if="activeCount">
          <p>No activity matches these filters.</p>
          <button type="button" class="adm-btn ghost small" @click="clearAll">Clear filters</button>
        </template>
        <p v-else>No activity yet.</p>
      </div>
    </div>

    <div v-if="next && rows.length" class="more">
      <button type="button" class="adm-btn ghost" :disabled="loading" @click="load(true)">
        Older
      </button>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { errorText } from '../../lib/auth.js';
import { listAuditFeed, searchMembers } from '../../lib/admin.js';
import {
  CATEGORIES,
  RANGES,
  ROLES,
  actionLabel,
  actionsIn,
  activeFilters,
  categoryOf,
  feedArgs,
  filtersQuery,
  isRowTrigger,
  readFilters,
  recordLink,
  roleLabel,
  sentence,
} from '../../lib/audit-actions.js';
import LineIcon from '../site/LineIcon.vue';

const props = defineProps({
  lookups: { type: Object, default: () => ({ regions: [], communities: [] }) },
});
const emit = defineEmits(['navigate']);
const route = useRoute();
const router = useRouter();

const TAB_LABEL = {
  events: 'Events',
  forms: 'Forms',
  notices: 'Notices',
  requests: 'Requests',
  positions: 'Positions',
};

// ── Filters (the route query is the one source of truth) ───────────────────
const f = computed(() => readFilters(route.query));
const activeCount = computed(() => activeFilters(f.value));
const categoryLabel = computed(() => CATEGORIES.find((c) => c.id === f.value.cat)?.label);
const filtersOpen = ref(false);

function set(patch) {
  const { tab } = route.query;
  router.replace({ query: { tab, ...filtersQuery({ ...f.value, ...patch }) } });
}
function clearAll() {
  clearTimeout(qTimer);
  qText.value = '';
  set({ cat: '', act: [], role: '', actor: '', member: '', range: '', from: '', to: '', q: '' });
}
function toggleAction(id, on) {
  set({ act: on ? [...f.value.act, id] : f.value.act.filter((a) => a !== id) });
}
const actionsBox = ref(null);
function closeActions() {
  if (actionsBox.value) actionsBox.value.open = false;
}
// The picker floats over the filters below it, so a click anywhere else closes it.
function outside(event) {
  if (actionsBox.value?.open && !actionsBox.value.contains(event.target)) closeActions();
}
onMounted(() => document.addEventListener('pointerdown', outside));

// Search: typed text settles for 300 ms before it becomes a filter.
const qText = ref(f.value.q);
let qTimer;
function typed() {
  clearTimeout(qTimer);
  qTimer = setTimeout(() => set({ q: qText.value.trim() }), 300);
}
watch(
  () => f.value.q,
  (q) => {
    if (q !== qText.value.trim()) qText.value = q;
  }
);

// Names for ids in the filters: remembered from picked members and loaded rows.
const names = reactive(new Map());
const nameOf = (id) => names.get(id) || 'Selected member';
function timeline(id, text) {
  if (text) names.set(id, text);
  set({ member: id });
  window.scrollTo({ top: 0 });
}

// One admin, picked through the student search.
const actorText = ref('');
const actorHits = ref([]);
let actorTimer;
let actorSeq = 0;
function findActor() {
  clearTimeout(actorTimer);
  const token = ++actorSeq;
  const query = actorText.value.trim();
  if (query.length < 3) {
    actorHits.value = [];
    return;
  }
  actorTimer = setTimeout(async () => {
    try {
      const found = await searchMembers(query.slice(0, 100));
      if (token === actorSeq) actorHits.value = (found ?? []).slice(0, 6);
    } catch (e) {
      if (token === actorSeq) error.value = errorText(e);
    }
  }, 250);
}
function pickActor(m) {
  names.set(m.id, m.preferred_name || m.full_name);
  actorText.value = '';
  actorHits.value = [];
  set({ actor: m.id });
}

// ── Feed ────────────────────────────────────────────────────────────────────
const rows = ref([]);
const next = ref(null);
const loading = ref(false);
const loaded = ref(false);
const error = ref('');
const lastMore = ref(false);
const openIds = ref(new Set());
let seq = 0;

// A newer request (a filter changed again) wins; older answers are dropped.
async function load(more = false) {
  const token = ++seq;
  lastMore.value = more;
  loading.value = true;
  error.value = '';
  try {
    const page = await listAuditFeed(feedArgs(f.value), more ? next.value : null);
    if (token !== seq) return;
    for (const r of page.rows) {
      if (r.actor_id && r.actor_name) names.set(r.actor_id, r.actor_name);
      if (r.subject_id && r.subject_name) names.set(r.subject_id, r.subject_name);
    }
    rows.value = more ? rows.value.concat(page.rows) : page.rows;
    next.value = page.next;
    if (!more) openIds.value = new Set();
    loaded.value = true;
  } catch (e) {
    if (token === seq) error.value = errorText(e);
  } finally {
    if (token === seq) loading.value = false;
  }
}
// Every filter change starts again from the newest entry.
watch(
  () => JSON.stringify(f.value),
  () => load(false),
  { immediate: true }
);
onBeforeUnmount(() => {
  document.removeEventListener('pointerdown', outside);
  clearTimeout(qTimer);
  clearTimeout(actorTimer);
  seq++;
  actorSeq++;
});

const nameIn = (list, id) =>
  id == null ? null : list?.find((x) => x.id === Number(id))?.name || `#${id}`;
const ctx = {
  region: (id) => nameIn(props.lookups?.regions, id),
  community: (id) => nameIn(props.lookups?.communities, id),
};

// Rows from one transaction become one entry, led by the business action (not a table trigger).
const entries = computed(() => {
  const out = [];
  const byXact = new Map();
  for (const r of rows.value) {
    const group = r.xact_id ? byXact.get(r.xact_id) : null;
    if (group) group.push(r);
    else {
      const g = [r];
      if (r.xact_id) byXact.set(r.xact_id, g);
      out.push(g);
    }
  }
  return out.map((g) => {
    const head = g.find((r) => !isRowTrigger(r.action)) ?? g[0];
    const say = sentence(head, ctx);
    return {
      head,
      also: g.filter((r) => r !== head),
      say,
      link: recordLink(head),
      // Only the record the action is about links out; other bold words stay plain.
      recordIndex: say.parts.findIndex((p) => p?.record),
      label: actionLabel(head.action),
      category: categoryOf(head.action).label,
      role: roleLabel(head.actor_role),
      failed: g.some((r) => r.result === 'failure'),
    };
  });
});

const dayKey = (d) => `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
const days = computed(() => {
  const today = new Date();
  const yesterday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1);
  const out = [];
  for (const e of entries.value) {
    const at = new Date(e.head.created_at);
    const key = dayKey(at);
    let day = out.at(-1);
    if (day?.key !== key) {
      day = {
        key,
        label:
          key === dayKey(today)
            ? 'Today'
            : key === dayKey(yesterday)
              ? 'Yesterday'
              : at.toLocaleDateString('en-IN', {
                  weekday: 'short',
                  day: 'numeric',
                  month: 'short',
                  year: at.getFullYear() === today.getFullYear() ? undefined : 'numeric',
                }),
        entries: [],
      };
      out.push(day);
    }
    day.entries.push(e);
  }
  return out;
});

function toggle(id) {
  const s = new Set(openIds.value);
  if (!s.delete(id)) s.add(id);
  openIds.value = s;
}

// ── Display helpers ─────────────────────────────────────────────────────────
const initial = (part) => (part?.text || 'S').trim().charAt(0).toUpperCase();
const clip = (s) => (s.length > 140 ? `${s.slice(0, 139)}…` : s);
function plain(r) {
  const { parts, note } = sentence(r, ctx);
  const text = parts.map((p) => (typeof p === 'string' ? p : p.text + (p.suffix || ''))).join('');
  return note ? `${text} · ${note}` : text;
}
const exact = (iso) =>
  new Date(iso).toLocaleString('en-IN', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    second: '2-digit',
  });
function ago(iso) {
  const mins = Math.max(0, Math.floor((Date.now() - new Date(iso)) / 6e4));
  if (mins < 1) return 'Just now';
  if (mins < 60) return `${mins} min ago`;
  if (mins < 24 * 60) return `${Math.floor(mins / 60)} h ago`;
  return new Date(iso).toLocaleTimeString('en-IN', { hour: 'numeric', minute: '2-digit' });
}

const REGION_KEYS = new Set([
  'region_id',
  'from_region_id',
  'to_region_id',
  'old_region_id',
  'new_region_id',
]);
function show(key, value) {
  if (value === undefined || value === null || value === '') return '—';
  if (REGION_KEYS.has(key)) return `${ctx.region(value)} (${value})`;
  if (key === 'community_id') return `${ctx.community(value)} (${value})`;
  return typeof value === 'object' ? JSON.stringify(value) : String(value);
}
// Before / after per key. A key counts as changed only when both sides recorded it and the
// values differ (old_values often holds just the keys that were about to change).
function diffOf(r) {
  const before = r.old_values && typeof r.old_values === 'object' ? r.old_values : null;
  const after = r.new_values && typeof r.new_values === 'object' ? r.new_values : null;
  const keys = [...new Set([...Object.keys(before ?? {}), ...Object.keys(after ?? {})])];
  return keys.map((key) => ({
    key,
    before: show(key, before?.[key]),
    after: show(key, after?.[key]),
    changed:
      !!before &&
      !!after &&
      key in before &&
      key in after &&
      JSON.stringify(before[key]) !== JSON.stringify(after[key]),
  }));
}
</script>

<style scoped>
.audit {
  display: grid;
  gap: 14px;
  min-width: 0;
}

/* Filter bar */
.bar {
  display: flex;
  gap: 10px;
}
.search {
  position: relative;
  flex: 1;
  min-width: 0;
  max-width: 560px;
}
.search .ic {
  position: absolute;
  top: 50%;
  left: 12px;
  width: 17px;
  height: 17px;
  transform: translateY(-50%);
  fill: none;
  stroke: var(--ink-3);
  stroke-width: 1.8;
  pointer-events: none;
}
.search .adm-input {
  padding-left: 38px;
}
.filters-toggle {
  display: none;
}
.filters {
  display: grid;
  gap: 10px;
  padding: 12px 14px;
  border: 1px solid var(--line);
  border-radius: 12px;
  background: var(--sunk);
}
.frow {
  display: grid;
  grid-template-columns: 76px minmax(0, 1fr);
  align-items: start;
  gap: 10px;
}
.flabel {
  padding-top: 10px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--ink-3);
}
.fctl {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px 10px;
  min-width: 0;
}
.fctl > .adm-chips {
  min-width: 0;
}
.adm-chip {
  white-space: nowrap;
}
.dates {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
.dates .adm-field {
  grid-template-columns: auto auto;
  align-items: center;
  gap: 8px;
}
.dates .adm-field > span {
  font-size: 12.5px;
  color: var(--ink-2);
}
.dates .adm-input {
  width: auto;
  height: 34px;
}

/* Action picker: a native disclosure that floats over the feed on wide screens. */
.pick {
  position: relative;
}
.pick summary {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  list-style: none;
}
.pick summary::-webkit-details-marker {
  display: none;
}
.pick summary::after {
  content: '';
  width: 6px;
  height: 6px;
  border: solid currentColor;
  border-width: 0 1.5px 1.5px 0;
  transform: translateY(-2px) rotate(45deg);
}
.pick[open] summary::after {
  transform: translateY(1px) rotate(-135deg);
}
.pop {
  position: absolute;
  top: calc(100% + 6px);
  left: 0;
  z-index: 5;
  display: grid;
  gap: 10px;
  min-width: 260px;
  max-height: 320px;
  overflow: auto;
  margin: 0;
  padding: 14px;
  border: 1px solid var(--line-strong);
  border-radius: 12px;
  background: var(--card);
  box-shadow: var(--shadow);
}
.pop .adm-check {
  font-size: 14px;
}
.pop small {
  display: block;
  font-size: 11.5px;
  color: var(--ink-3);
}

/* One admin */
.actor {
  position: relative;
}
.actor-input {
  width: 200px;
  height: 34px;
}
.picked {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding-right: 4px;
  cursor: default;
}
.x {
  display: grid;
  place-items: center;
  width: 26px;
  height: 26px;
  padding: 0;
  border: 0;
  border-radius: 50%;
  background: transparent;
  color: inherit;
  cursor: pointer;
}
.x .ic,
.timeline .ic {
  width: 14px;
  height: 14px;
  fill: none;
  stroke: currentColor;
  stroke-width: 2;
}
.x:hover {
  background: color-mix(in srgb, var(--on-mari) 18%, transparent);
}
.hits {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  z-index: 5;
  min-width: 240px;
  margin: 0;
  padding: 4px;
  list-style: none;
  border: 1px solid var(--line-strong);
  border-radius: 10px;
  background: var(--card);
  box-shadow: var(--shadow);
}
.hits button {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  width: 100%;
  padding: 8px 10px;
  border: 0;
  border-radius: 7px;
  background: transparent;
  color: var(--ink);
  font: inherit;
  font-size: 14px;
  text-align: left;
  cursor: pointer;
}
.hits button:hover,
.hits button:focus-visible {
  background: var(--mari-soft);
}
.hits small {
  font-size: 12px;
  color: var(--ink-3);
}
.clear {
  margin-left: auto;
}

/* One member's timeline */
.timeline {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px 10px;
  padding: 10px 12px 10px 16px;
  border: 1px solid color-mix(in srgb, var(--mari-ink) 45%, transparent);
  border-left: 4px solid var(--mari);
  border-radius: 12px;
  background: var(--mari-soft);
  font-size: 15px;
}
.tl-label {
  margin: 0;
  color: var(--ink-2);
}
.timeline b {
  color: var(--ink);
  font-weight: 700;
}
.timeline .adm-btn {
  margin-left: auto;
}

.retry {
  border: 0;
  background: transparent;
  color: inherit;
  font: inherit;
  text-decoration: underline;
  cursor: pointer;
}

/* Feed */
.feed {
  display: grid;
  gap: 18px;
  min-width: 0;
  transition: opacity 0.2s;
}
.feed.busy {
  opacity: 0.55;
}
.day {
  margin: 0 0 8px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--ink-3);
}
.entries {
  display: grid;
  margin: 0;
  padding: 0;
  list-style: none;
  border: 1px solid var(--line);
  border-radius: 12px;
  background: var(--card);
  overflow: hidden;
}
.entry {
  display: grid;
  grid-template-columns: 30px minmax(0, 1fr) 32px;
  align-items: start;
  gap: 4px 12px;
  padding: 12px 12px 12px 14px;
  transition: background 0.2s;
}
.entry + .entry {
  border-top: 1px solid var(--line);
}
.entry.open {
  background: color-mix(in srgb, var(--mari-soft) 30%, var(--card));
}
.entry.fail {
  box-shadow: inset 3px 0 0 var(--verm);
}
.avatar {
  display: grid;
  place-items: center;
  width: 30px;
  height: 30px;
  border-radius: 50%;
  background: var(--mari-soft);
  color: var(--mari-ink);
  font-size: 13px;
  font-weight: 650;
}
.body {
  min-width: 0;
}
.say {
  margin: 0;
  font-size: 14.5px;
  line-height: 1.45;
  color: var(--ink);
  overflow-wrap: anywhere;
}
.say b {
  font-weight: 650;
}
.who,
.rec {
  display: inline;
  padding: 0;
  border: 0;
  background: none;
  color: var(--ink);
  font: inherit;
  font-weight: 700;
  text-align: left;
  text-decoration: underline;
  text-decoration-color: var(--line-strong);
  text-underline-offset: 3px;
  cursor: pointer;
  transition: text-decoration-color 0.2s;
}
.rec {
  font-weight: 650;
}
.who:hover,
.rec:hover {
  text-decoration-color: var(--mari);
}
.note {
  color: var(--ink-2);
}
.meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 4px 10px;
  margin-top: 4px;
  font-size: 12.5px;
  color: var(--ink-3);
}
.meta .adm-badge {
  font-size: 11px;
  padding: 1px 8px;
}
.meta time {
  font-variant-numeric: tabular-nums;
}
.lnk {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  padding: 0;
  border: 0;
  background: none;
  color: var(--mari-ink);
  font: inherit;
  font-weight: 650;
  cursor: pointer;
}
.lnk .ic {
  width: 13px;
  height: 13px;
  fill: none;
  stroke: currentColor;
  stroke-width: 2;
}
.chev {
  display: grid;
  place-items: center;
  width: 32px;
  height: 32px;
  padding: 0;
  border: 1px solid transparent;
  border-radius: 8px;
  background: transparent;
  color: var(--ink-2);
  cursor: pointer;
  transition:
    background 0.2s,
    border-color 0.2s;
}
.chev:hover {
  border-color: var(--line-strong);
  background: var(--card);
}
.chev .ic {
  width: 16px;
  height: 16px;
  fill: none;
  stroke: currentColor;
  stroke-width: 2;
  transform: rotate(90deg);
  transition: transform 0.2s var(--ease-out);
}
.chev[aria-expanded='true'] .ic {
  transform: rotate(-90deg);
}

/* Detail */
.detail {
  grid-column: 2 / -1;
  display: grid;
  gap: 14px;
  margin-top: 8px;
  padding: 12px 0 2px;
  border-top: 1px dashed var(--line-strong);
  min-width: 0;
}
.part {
  display: grid;
  gap: 10px;
  min-width: 0;
}
.part + .part {
  padding-left: 12px;
  border-left: 2px solid var(--line);
}
.also-h {
  margin: 4px 0 0;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--ink-3);
}
.also {
  margin: 0;
  font-size: 13.5px;
  color: var(--ink-2);
}
.also .mono {
  margin-right: 6px;
  color: var(--ink);
}
.diff {
  font-size: 13px;
}
.diff .k {
  width: 28%;
  font-size: 12.5px;
  font-weight: 600;
  letter-spacing: 0;
  text-transform: none;
  color: var(--ink-2);
}
.diff td {
  overflow-wrap: anywhere;
}
.diff td.none {
  color: var(--ink-3);
}
.diff tr.changed .k {
  box-shadow: inset 3px 0 0 var(--mari);
  color: var(--ink);
}
.diff tr.changed td:last-child {
  background: var(--mari-soft);
  color: var(--ink);
  font-weight: 600;
}
.quiet {
  font-size: 13px;
}
.facts {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 22px;
  margin: 0;
}
.facts dt {
  font-size: 10.5px;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--ink-3);
}
.facts dd {
  margin: 2px 0 0;
  font-size: 12.5px;
  color: var(--ink-2);
  overflow-wrap: anywhere;
}
.links {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
}
.raw {
  margin-left: auto;
  font-size: 12.5px;
  color: var(--ink-2);
}
.raw summary {
  cursor: pointer;
}
.raw[open] {
  flex-basis: 100%;
  margin-left: 0;
}
.raw pre {
  max-height: 320px;
  margin: 8px 0 0;
  padding: 12px;
  overflow: auto;
  border-radius: 10px;
  background: var(--sunk);
  font-size: 12px;
  color: var(--ink);
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}

.adm-empty p {
  margin: 0;
}
.adm-empty .adm-btn {
  margin-top: 12px;
}
.more {
  display: flex;
  justify-content: center;
}

@media (max-width: 760px) {
  .filters-toggle {
    display: inline-flex;
  }
  .search {
    max-width: none;
  }
  .filters {
    display: none;
  }
  .filters.open {
    display: grid;
  }
  .frow {
    grid-template-columns: minmax(0, 1fr);
    gap: 6px;
  }
  .flabel {
    padding-top: 0;
  }
  /* Chips scroll sideways instead of wrapping into a tall block. */
  .adm-chips.scroll {
    flex-wrap: nowrap;
    width: 100%;
    overflow-x: auto;
    scrollbar-width: none;
    padding-bottom: 2px;
  }
  .pop {
    position: static;
    margin-top: 8px;
    box-shadow: none;
  }
  .actor,
  .actor-input {
    width: 100%;
  }
  .dates .adm-field {
    grid-template-columns: 40px minmax(0, 200px);
  }
  .dates .adm-input {
    width: 100%;
    height: 44px;
  }
  .clear {
    margin-left: 0;
  }
}
/* Before / after: the key on its own line, the two values side by side. */
@media (max-width: 640px) {
  .adm-table.diff tr {
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
    gap: 6px 12px;
    padding: 10px 12px;
  }
  .adm-table.diff .k {
    grid-column: 1 / -1;
    width: auto;
    padding: 0;
    border: 0;
  }
  .adm-table.diff tr.changed .k {
    box-shadow: none;
    padding-left: 9px;
    border-left: 3px solid var(--mari);
  }
  .adm-table.diff tr td:last-child {
    grid-column: auto;
  }
  .adm-table.diff tr.changed td:last-child {
    margin: -4px -6px;
    padding: 4px 6px;
    border-radius: 6px;
  }
}
@media (max-width: 560px) {
  .entry {
    grid-template-columns: minmax(0, 1fr) 32px;
    padding: 12px;
  }
  .avatar {
    display: none;
  }
  .detail {
    grid-column: 1 / -1;
  }
  .say {
    font-size: 14px;
  }
  .meta {
    font-size: 12px;
  }
  .timeline .adm-btn {
    margin-left: 0;
  }
}
</style>
