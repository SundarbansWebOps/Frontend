<!-- Renders the question asked by askConfirm() (lib/admin-confirm.js). Closing it any way other
     than the confirm button answers "no". -->
<template>
  <AdminDialog v-if="pendingConfirm" ref="dlg" :title="pendingConfirm.title" @close="answer(false)">
    <p class="adm-note confirm-text">{{ pendingConfirm.message }}</p>
    <template #footer>
      <button type="button" class="adm-btn ghost" @click="dlg?.close()">Cancel</button>
      <button
        type="button"
        class="adm-btn"
        :class="pendingConfirm.danger ? 'danger' : 'mari'"
        @click="answer(true)"
      >
        {{ pendingConfirm.confirmLabel }}
      </button>
    </template>
  </AdminDialog>
</template>

<script setup>
import { ref } from 'vue';
import AdminDialog from './AdminDialog.vue';
import { pendingConfirm } from '../../lib/admin-confirm.js';

const dlg = ref(null);

function answer(yes) {
  pendingConfirm.value?.resolve(yes);
}
</script>

<style scoped>
.confirm-text {
  max-width: none;
  font-size: 15px;
  white-space: pre-line;
}
</style>
