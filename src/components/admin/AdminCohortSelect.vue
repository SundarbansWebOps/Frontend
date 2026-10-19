<!-- Who can see a form or event. Empty selection means every student. Picking a term narrows it;
     clearing the last term goes back to every student. The sentence under the switch always says
     who can see it now, so each click has a visible result. -->
<template>
  <div class="cohorts">
    <div class="mode" role="group" :aria-label="label">
      <button
        type="button"
        class="mode-btn"
        :class="{ on: allStudents }"
        :aria-pressed="allStudents"
        @click="setAll"
      >
        <span class="dot" aria-hidden="true" />
        All students
      </button>
      <button
        type="button"
        class="mode-btn"
        :class="{ on: !allStudents }"
        :aria-pressed="!allStudents"
        :disabled="!cohorts.current"
        @click="pickCurrent"
      >
        <span class="dot" aria-hidden="true" />
        Selected cohorts
      </button>
    </div>
    <p class="status" aria-live="polite">{{ summary }}</p>

    <div class="picker" :class="{ idle: allStudents }">
      <div class="row">
        <label class="adm-field">
          <span>Year</span>
          <select v-model.number="year" class="adm-input">
            <option v-for="y in years" :key="y" :value="y">{{ y }}</option>
          </select>
        </label>
        <div class="adm-field grow">
          <span>Term</span>
          <div class="adm-chips">
            <button
              v-for="t in terms"
              :key="t"
              type="button"
              class="adm-chip"
              :class="{ on: selected.includes(code(t)) }"
              :aria-pressed="selected.includes(code(t))"
              @click="toggle(code(t))"
            >
              {{ t }}
              <span v-if="code(t) === cohorts.next" class="adm-badge mari">Future</span>
            </button>
            <button
              type="button"
              class="adm-chip"
              :class="{ on: allTermsOn }"
              :aria-pressed="allTermsOn"
              :disabled="!terms.length"
              @click="toggleYear"
            >
              All terms
            </button>
          </div>
        </div>
      </div>
    </div>
    <small>
      Upcoming and live listings reach only the selected cohorts. Past published listings are
      public.
    </small>
  </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue';
import { termsForYear, yearFromCohort } from '../../lib/admin.js';

const props = defineProps({
  modelValue: { type: Array, default: () => [] },
  cohorts: { type: Object, required: true },
  label: { type: String, default: 'Who can see this' },
});
const emit = defineEmits(['update:modelValue']);

const selected = computed(() => props.modelValue ?? []);
const allStudents = computed(() => selected.value.length === 0);
const years = computed(() => {
  const set = new Set(props.cohorts.options.map(yearFromCohort).filter(Boolean));
  return [...set].sort((a, b) => b - a);
});
const year = ref(yearFromCohort(props.cohorts.current) || years.value[0]);
const terms = computed(() => termsForYear(year.value, props.cohorts));
const allTermsOn = computed(
  () => terms.value.length > 0 && terms.value.every((t) => selected.value.includes(code(t)))
);
const summary = computed(() =>
  allStudents.value
    ? 'Every student can see this. Pick a term to narrow it.'
    : `Only ${selected.value.join(', ')} can see this.`
);

watch(
  () => props.cohorts.current,
  (c) => {
    const y = yearFromCohort(c);
    if (y) year.value = y;
  }
);

function code(term) {
  return `${String(year.value).slice(-2)}${term}`;
}
function setAll() {
  emit('update:modelValue', []);
}
function pickCurrent() {
  if (!allStudents.value || !props.cohorts.current) return;
  emit('update:modelValue', [props.cohorts.current]);
}
function toggle(c) {
  const next = selected.value.includes(c)
    ? selected.value.filter((x) => x !== c)
    : [...selected.value, c];
  emit('update:modelValue', next);
}
function toggleYear() {
  const codes = terms.value.map(code);
  if (allTermsOn.value) {
    emit(
      'update:modelValue',
      selected.value.filter((c) => !codes.includes(c))
    );
    return;
  }
  const extra = codes.filter((c) => !selected.value.includes(c));
  emit('update:modelValue', [...selected.value, ...extra]);
}
</script>

<style scoped>
.cohorts {
  display: grid;
  gap: 12px;
}
.mode {
  display: inline-flex;
  flex-wrap: wrap;
  gap: 4px;
  justify-self: start;
  padding: 4px;
  border: 1px solid var(--line-strong);
  border-radius: 99px;
  background: var(--sunk);
}
.mode-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 7px 14px;
  border: 0;
  border-radius: 99px;
  background: transparent;
  color: var(--ink-2);
  font: inherit;
  font-size: 14px;
  font-weight: 650;
  cursor: pointer;
  transition:
    background 0.2s,
    color 0.2s;
}
.mode-btn:hover:not(:disabled):not(.on) {
  color: var(--ink);
}
.mode-btn:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
.mode-btn.on {
  background: var(--ink);
  color: var(--paper);
}
.dot {
  width: 8px;
  height: 8px;
  border: 1.5px solid currentColor;
  border-radius: 50%;
}
.mode-btn.on .dot {
  background: currentColor;
}
.status {
  margin: 0;
  font-size: 14px;
  color: var(--ink);
}
.picker {
  display: grid;
  transition: opacity 0.2s;
}
.picker.idle {
  opacity: 0.6;
}
.row {
  display: grid;
  grid-template-columns: 120px minmax(0, 1fr);
  gap: 12px;
  align-items: end;
}
.grow {
  min-width: 0;
}
small {
  font-size: 12.5px;
  color: var(--ink-3);
}
@media (max-width: 640px) {
  .row {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
