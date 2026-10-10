<!-- Year / term / All students selector. Options come from get_available_cohorts (India dates).
     Empty selection means All students. The immediately next cohort carries a Future badge. -->
<template>
  <div class="box">
    <div class="adm-chips" role="group" :aria-label="label">
      <button type="button" class="adm-chip" :class="{ on: allStudents }" @click="setAll">
        All students
      </button>
    </div>
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
            @click="toggle(code(t))"
          >
            {{ t }}
            <span v-if="code(t) === cohorts.next" class="adm-badge mari">Future</span>
          </button>
          <button type="button" class="adm-chip" :disabled="!terms.length" @click="addYear">
            All terms
          </button>
        </div>
      </div>
    </div>
    <div v-if="!allStudents && selected.length" class="adm-chips picked">
      <span v-for="c in selected" :key="c" class="adm-badge">
        {{ c }}
        <span v-if="c === cohorts.next">Future</span>
        <button type="button" class="x" @click="toggle(c)">
          <span class="visually-hidden">Remove {{ c }}</span>
          ×
        </button>
      </span>
    </div>
    <small>
      Upcoming and live listings reach only the selected cohorts. All students removes the cohort
      limit. Past published listings are public.
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
function toggle(c) {
  const next = selected.value.includes(c)
    ? selected.value.filter((x) => x !== c)
    : [...selected.value, c];
  emit('update:modelValue', next);
}
function addYear() {
  const extra = terms.value.map(code).filter((c) => !selected.value.includes(c));
  emit('update:modelValue', [...selected.value, ...extra]);
}
</script>

<style scoped>
.box {
  display: grid;
  gap: 10px;
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
.picked {
  align-items: center;
}
.x {
  margin-left: 4px;
  border: 0;
  background: transparent;
  color: inherit;
  font: inherit;
  cursor: pointer;
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
