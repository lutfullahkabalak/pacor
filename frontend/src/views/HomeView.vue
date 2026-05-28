<script setup lang="ts">
import { computed, onMounted, onUnmounted } from 'vue'
import MealButton from '../components/MealButton.vue'
import PacManIcon from '../components/PacManIcon.vue'
import { useFastingElapsed } from '../composables/useFastingElapsed'
import { useMealsStore } from '../stores/meals'
import { useSettingsStore } from '../stores/settings'

const meals = useMealsStore()
const settings = useSettingsStore()

const lastMealAt = computed(() => meals.state?.last_meal_at ?? null)
const targetHours = computed(() => settings.plan.fasting_hours ?? 16)
const targetMinutes = computed(() => settings.plan.fasting_minutes ?? 0)

const { display, backgroundColor, ratio } = useFastingElapsed(
  lastMealAt,
  targetHours,
  targetMinutes,
)

let pollTimer: ReturnType<typeof setInterval> | null = null

onMounted(async () => {
  await Promise.all([meals.refreshState(), settings.fetchPlan()])
  pollTimer = setInterval(() => meals.refreshState(), 60000)
})

onUnmounted(() => {
  if (pollTimer) clearInterval(pollTimer)
})

async function handleMeal() {
  try {
    await meals.logMeal()
  } catch {
    // error shown via store
  }
}
</script>

<template>
  <div class="min-h-dvh pb-[calc(5rem+var(--safe-bottom))] pt-[var(--safe-top)]">
    <div class="max-w-lg mx-auto px-4 flex flex-col min-h-[calc(100dvh-var(--safe-top)-5rem-var(--safe-bottom))]">
      <header class="pt-4 flex items-center justify-between shrink-0">
        <div class="flex items-center gap-2.5">
          <div class="w-9 h-9 shrink-0" aria-hidden="true">
            <PacManIcon head-only />
          </div>
          <h1 class="app-title text-xl tracking-tight">Pacor</h1>
        </div>
        <button
          type="button"
          class="icon-btn w-10 h-10 rounded-full flex items-center justify-center transition-colors"
          aria-label="Ayarlar"
          @click="settings.openSettingsModal()"
        >
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="w-5 h-5">
            <path d="M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z" />
            <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09a1.65 1.65 0 0 0 1.51-1 1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9c.26.604.852.997 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1Z" />
          </svg>
        </button>
      </header>

      <div class="flex-1 flex flex-col items-center justify-center gap-8 w-full">
        <section class="w-full py-2">
          <p class="fasting-elapsed">{{ display }}</p>
        </section>

        <MealButton
          :loading="meals.logging"
          :background-color="backgroundColor"
          :progress="ratio"
          @click="handleMeal"
        />

        <p v-if="meals.error && !meals.statsModalOpen && !settings.settingsModalOpen" class="text-rose-400 text-sm text-center">
          {{ meals.error }}
        </p>
      </div>
    </div>
  </div>
</template>
