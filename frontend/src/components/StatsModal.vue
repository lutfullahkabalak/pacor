<script setup lang="ts">
import { computed, watch } from 'vue'
import { storeToRefs } from 'pinia'
import { useMealsStore } from '../stores/meals'
import { useSettingsStore } from '../stores/settings'
import { formatDuration, formatTimeRange } from '../utils/fastingHistory'
import {
  completionFromDuration,
  formatTargetDuration,
} from '../utils/planTarget'
import { fastingColorFromRatio, fastingGradientCss } from '../utils/fastingColor'
import { useEscapeKey } from '../composables/useEscapeKey'

const meals = useMealsStore()
const settings = useSettingsStore()
const { statsModalOpen, fastingHistory, fastingSummary, historyLoading, error } =
  storeToRefs(meals)
const { plan } = storeToRefs(settings)

const targetLabel = computed(() =>
  formatTargetDuration(plan.value.fasting_hours, plan.value.fasting_minutes),
)

const fastingHistoryWithCompletion = computed(() =>
  fastingHistory.value.map((fast) => {
    const completion = completionFromDuration(
      fast.duration_hours,
      plan.value.fasting_hours,
      plan.value.fasting_minutes,
    )
    return {
      ...fast,
      completion,
      barColor: fastingColorFromRatio(completion.fillRatio),
    }
  }),
)

const progressGradient = fastingGradientCss()

watch(statsModalOpen, (open) => {
  if (open) settings.fetchPlan()
})

function close() {
  meals.closeStatsModal()
}

useEscapeKey(close, () => statsModalOpen.value)

function onBackdropClick(e: MouseEvent) {
  if (e.target === e.currentTarget) close()
}
</script>

<template>
  <Teleport to="body">
    <Transition name="modal">
      <div
        v-if="statsModalOpen"
        class="fixed inset-0 z-50 flex items-end sm:items-center justify-center overlay-backdrop backdrop-blur-sm"
        @click="onBackdropClick"
      >
        <div
          class="modal-panel w-full max-w-lg max-h-[85dvh] sm:max-h-[80dvh] rounded-t-3xl sm:rounded-3xl flex flex-col shadow-2xl"
          @click.stop
        >
          <header class="flex items-center justify-between px-5 pt-5 pb-3 border-b border-app shrink-0">
            <div>
              <h2 class="text-xl font-bold">İstatistikler</h2>
              <p class="text-sm text-muted">Tamamlanan oruç geçmişi</p>
            </div>
            <button
              type="button"
              class="w-9 h-9 rounded-full bg-surface-elevated text-muted hover:opacity-80 transition-opacity"
              aria-label="Kapat"
              @click="close"
            >
              ✕
            </button>
          </header>

          <div class="overflow-y-auto flex-1 px-5 py-4 space-y-4">
            <div v-if="historyLoading" class="text-center text-muted py-8">
              Yükleniyor...
            </div>

            <template v-else>
              <div v-if="fastingSummary.count > 0" class="grid grid-cols-3 gap-2">
                <div class="card rounded-xl p-3 text-center">
                  <p class="text-xs text-muted mb-1">Toplam</p>
                  <p class="text-xl font-bold">{{ fastingSummary.count }}</p>
                </div>
                <div class="card rounded-xl p-3 text-center">
                  <p class="text-xs text-muted mb-1">En uzun</p>
                  <p class="text-lg font-bold text-[var(--accent)]">
                    {{ formatDuration(fastingSummary.longest_hours) }}
                  </p>
                </div>
                <div class="card rounded-xl p-3 text-center">
                  <p class="text-xs text-muted mb-1">En kısa</p>
                  <p class="text-lg font-bold text-amber-500">
                    {{ formatDuration(fastingSummary.shortest_hours) }}
                  </p>
                </div>
              </div>

              <div v-if="fastingHistory.length === 0" class="text-center text-muted py-8">
                Henüz tamamlanan oruç yok
              </div>

              <ul v-else class="space-y-2">
                <li
                  v-for="(fast, index) in fastingHistoryWithCompletion"
                  :key="`${fast.start}-${fast.end}-${index}`"
                  class="card rounded-xl px-4 py-3"
                >
                  <div class="flex items-start justify-between gap-3">
                    <p class="text-lg font-bold tabular-nums">
                      {{ formatDuration(fast.duration_hours) }}
                    </p>
                    <p
                      class="text-sm font-semibold tabular-nums shrink-0"
                      :style="{ color: fast.barColor }"
                    >
                      %{{ fast.completion.percent }}
                    </p>
                  </div>
                  <p class="text-sm text-muted mt-0.5">
                    {{ formatTimeRange(fast.start, fast.end) }}
                  </p>
                  <div class="mt-3">
                    <div class="flex items-center justify-between text-xs text-muted mb-1.5">
                      <span>Hedef: {{ targetLabel }}</span>
                      <span>%{{ fast.completion.percent }} tamamlandı</span>
                    </div>
                    <div
                      class="relative h-2 rounded-full overflow-hidden bg-surface-elevated"
                      role="progressbar"
                      :aria-valuenow="fast.completion.percent"
                      aria-valuemin="0"
                      aria-valuemax="100"
                      :aria-label="`Hedefin yüzde ${fast.completion.percent} tamamlandı`"
                    >
                      <div
                        class="absolute inset-0"
                        :style="{ background: progressGradient }"
                      />
                      <div
                        class="absolute inset-y-0 bg-surface-elevated"
                        :style="{ left: `${Math.min(fast.completion.fillRatio, 1) * 100}%`, right: 0 }"
                      />
                    </div>
                  </div>
                </li>
              </ul>
            </template>

            <p v-if="error" class="text-rose-400 text-sm text-center">{{ error }}</p>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.2s ease;
}

.modal-enter-active > div,
.modal-leave-active > div {
  transition: transform 0.25s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-from > div,
.modal-leave-to > div {
  transform: translateY(100%);
}

@media (min-width: 640px) {
  .modal-enter-from > div,
  .modal-leave-to > div {
    transform: translateY(1rem) scale(0.98);
  }
}
</style>
