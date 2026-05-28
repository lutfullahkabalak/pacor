<script setup lang="ts">
import type { PlanSettings } from '../types'
import { normalizePlanTarget } from '../utils/planTarget'

defineProps<{
  modelValue: PlanSettings
}>()

function normalizeField(modelValue: PlanSettings, field: 'fasting_hours' | 'fasting_minutes') {
  const normalized = normalizePlanTarget(modelValue.fasting_hours, modelValue.fasting_minutes)
  modelValue[field] = normalized[field]
}
</script>

<template>
  <div class="flex items-end gap-2">
    <label class="block text-sm flex-1 min-w-0">
      <span class="text-muted">Saat</span>
      <input
        v-model.number="modelValue.fasting_hours"
        type="text"
        inputmode="numeric"
        pattern="[0-9]*"
        autocomplete="off"
        class="input-numeric mt-1 w-full rounded-xl border border-app bg-app-input px-3 py-3 text-center"
        @blur="normalizeField(modelValue, 'fasting_hours')"
      />
    </label>
    <span class="pb-3 text-muted font-medium select-none" aria-hidden="true">:</span>
    <label class="block text-sm flex-1 min-w-0">
      <span class="text-muted">Dakika</span>
      <input
        v-model.number="modelValue.fasting_minutes"
        type="text"
        inputmode="numeric"
        pattern="[0-9]*"
        autocomplete="off"
        class="input-numeric mt-1 w-full rounded-xl border border-app bg-app-input px-3 py-3 text-center"
        @blur="normalizeField(modelValue, 'fasting_minutes')"
      />
    </label>
  </div>
</template>
