<!-- Audit log (Super Admin): newest first, read-only. -->
<template>
  <div>
    <p v-if="error" class="adm-msg err" role="alert">{{ error }}</p>
    <ul v-if="rows.length" class="adm-list">
      <li v-for="r in rows" :key="r.id" class="adm-row">
        <div>
          <b>{{ label(r.action) }}</b>
          <div class="adm-meta">
            <span>{{ r.actor ?? (r.actor_id ? 'Former member' : 'System') }}</span>
            <span v-if="r.target_table" class="mono">{{ r.target_table }}</span>
            <span v-if="r.result !== 'success'" class="adm-badge verm">{{ r.result }}</span>
          </div>
        </div>
        <span class="mono when">{{ when(r.created_at) }}</span>
      </li>
    </ul>
    <p v-else-if="!loading" class="adm-empty">No activity yet.</p>
    <div v-if="hasMore" class="more">
      <button type="button" class="adm-btn ghost" :disabled="loading" @click="load(page + 1)">
        Older
      </button>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue';
import { errorText } from '../../lib/auth.js';
import { PAGE, listAudit } from '../../lib/admin.js';

const rows = ref([]);
const page = ref(0);
const hasMore = ref(false);
const loading = ref(false);
const error = ref('');

// "request.approve" → "Request approve"; readable without a lookup table.
const label = (a) => {
  const s = a.replace(/[._]/g, ' ');
  return s.charAt(0).toUpperCase() + s.slice(1);
};
const when = (iso) =>
  new Date(iso).toLocaleString('en-IN', {
    day: 'numeric',
    month: 'short',
    hour: 'numeric',
    minute: '2-digit',
  });

async function load(p = 0) {
  loading.value = true;
  error.value = '';
  try {
    const next = await listAudit(p);
    rows.value = p === 0 ? next : rows.value.concat(next);
    page.value = p;
    hasMore.value = next.length === PAGE;
  } catch (e) {
    error.value = errorText(e);
  } finally {
    loading.value = false;
  }
}
onMounted(() => load(0));
</script>

<style scoped>
.when {
  font-size: 12.5px;
  color: var(--ink-3);
  white-space: nowrap;
}
.more {
  display: flex;
  justify-content: center;
  margin-top: 14px;
}
</style>
