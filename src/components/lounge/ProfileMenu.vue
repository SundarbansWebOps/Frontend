<!--
  The profile menu from the avatar: a sheet of ghat paper with the band on top. Who you are
  (preferred name as the title, never the roll number; then roll, region and Regional
  Coordinator), then My certificates, Edit name, Retake the tour, the theme and Sign out.
  Hangs from the header on wide screens; a full-width panel from the top on phones.
-->
<template>
  <LoungeDialog ref="dlg" variant="drop" labelledby="pm-h" @close="emit('close')">
    <div class="pm">
      <div class="pm-who">
        <span class="pm-av" :class="{ crest: !initials }" aria-hidden="true">
          <span v-if="initials">{{ initials }}</span>
          <img v-else :src="CREST" alt="" />
        </span>
        <div class="pm-id">
          <p class="gp-kicker">Your profile</p>
          <h2 v-if="callName" id="pm-h">{{ callName }}</h2>
          <template v-else>
            <h2 id="pm-h" class="pm-noname">No name yet</h2>
            <button type="button" class="gp-chip pm-add" @click="go('edit')">Add your name</button>
          </template>
        </div>
      </div>

      <dl class="pm-facts">
        <div>
          <dt>Roll</dt>
          <dd class="tnum">{{ member.roll }}</dd>
        </div>
        <div>
          <dt>Region</dt>
          <dd>{{ member.region.name }}</dd>
        </div>
        <div>
          <dt>Regional Coordinator</dt>
          <dd>{{ member.coordinator.name }}</dd>
        </div>
      </dl>

      <ul class="pm-acts">
        <li>
          <button type="button" @click="go('certs')">
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <circle cx="12" cy="9" r="5.5" />
              <path d="m8.5 13.5-1.8 7 5.3-2.6 5.3 2.6-1.8-7" />
            </svg>
            <span>My certificates</span>
            <b class="pm-n tnum">{{ certCount }}</b>
          </button>
        </li>
        <li v-if="callName">
          <button type="button" @click="go('edit')">
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M4 20h4L19 9l-4-4L4 16v4Z" />
              <path d="m13.5 6.5 4 4" />
            </svg>
            <span>Edit name</span>
          </button>
        </li>
        <li>
          <button type="button" @click="go('tour')">
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M3 17c3 0 3-2 6-2s3 2 6 2 3-2 6-2" />
              <path d="M5 13.5 7.5 9h9l2.5 4.5" />
              <path d="M12 9V3.5" />
            </svg>
            <span>Retake the tour</span>
          </button>
        </li>
        <li>
          <button type="button" @click="go('theme')">
            <svg v-if="theme === 'dark'" viewBox="0 0 24 24" aria-hidden="true">
              <circle cx="12" cy="12" r="4.2" />
              <path
                d="M12 2.5v2.2M12 19.3v2.2M2.5 12h2.2M19.3 12h2.2M5.3 5.3l1.6 1.6M17.1 17.1l1.6 1.6M5.3 18.7l1.6-1.6M17.1 6.9l1.6-1.6"
              />
            </svg>
            <svg v-else viewBox="0 0 24 24" aria-hidden="true">
              <path d="M19.5 14.6A8 8 0 0 1 9.4 4.5a8 8 0 1 0 10.1 10.1Z" />
            </svg>
            <span>{{ theme === 'dark' ? 'Switch to day' : 'Switch to night' }}</span>
          </button>
        </li>
        <li>
          <button type="button" class="pm-out" @click="signedOutNote = true">
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M14 4h4a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-4" />
              <path d="M10 8 6 12l4 4M6 12h10" />
            </svg>
            <span>{{
              signedOutNote ? 'Sign out does nothing in this prototype' : 'Sign out'
            }}</span>
          </button>
        </li>
      </ul>
    </div>
  </LoungeDialog>
</template>

<script setup>
import { computed, ref } from 'vue';
import CREST from '../../assets/crest.webp';
import LoungeDialog from './LoungeDialog.vue';
import * as ev from './events.js';
import { member } from './fixtures.js';
import { callName, initialsOf, theme } from './state.js';

const emit = defineEmits(['close', 'edit', 'certs', 'tour', 'theme']);
const dlg = ref(null);
const signedOutNote = ref(false);

const initials = computed(() => initialsOf(callName.value));
const certCount = computed(() => ev.certificates?.length ?? 0);

/* Edit and My certificates replace this menu (same Back entry); tour and theme close it. */
async function go(what) {
  if (what === 'edit' || what === 'certs') {
    emit(what);
    dlg.value?.swap();
  } else {
    await dlg.value?.close();
    emit(what);
  }
}
</script>
