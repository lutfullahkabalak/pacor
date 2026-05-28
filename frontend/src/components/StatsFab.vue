<script setup lang="ts">
import { useMealsStore } from '../stores/meals'

const meals = useMealsStore()
</script>

<template>
  <button
    type="button"
    class="icon-btn fixed bottom-[calc(1rem+var(--safe-bottom))] right-4 z-40 w-14 h-14 rounded-full bg-fab backdrop-blur shadow-lg transition-colors flex items-center justify-center"
    aria-label="İstatistikler"
    @click="meals.openStatsModal()"
  >
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="w-6 h-6">
      <path d="M18 20V10M12 20V4M6 20v-6" />
    </svg>
  </button>
</template>
