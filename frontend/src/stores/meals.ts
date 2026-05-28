import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api } from '../api/client'
import type { CurrentState, MealLog } from '../types'
import {
  computeFastingHistory,
  type FastingRecord,
  type FastingSummary,
} from '../utils/fastingHistory'

export const useMealsStore = defineStore('meals', () => {
  const state = ref<CurrentState | null>(null)
  const meals = ref<MealLog[]>([])
  const loading = ref(false)
  const logging = ref(false)
  const error = ref<string | null>(null)

  const statsModalOpen = ref(false)
  const fastingHistory = ref<FastingRecord[]>([])
  const fastingSummary = ref<FastingSummary>({
    count: 0,
    longest_hours: 0,
    shortest_hours: 0,
  })
  const historyLoading = ref(false)

  async function refreshState() {
    loading.value = true
    error.value = null
    try {
      state.value = await api.getCurrentState()
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Durum alınamadı'
    } finally {
      loading.value = false
    }
  }

  async function logMeal() {
    logging.value = true
    error.value = null
    try {
      await api.logMeal()
      await Promise.all([refreshState(), fetchRecentMeals()])
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Kayıt başarısız'
      throw e
    } finally {
      logging.value = false
    }
  }

  async function fetchRecentMeals() {
    try {
      meals.value = await api.getMeals()
      meals.value.sort((a, b) => new Date(b.logged_at).getTime() - new Date(a.logged_at).getTime())
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Kayıtlar alınamadı'
    }
  }

  async function deleteMeal(id: number) {
    await api.deleteMeal(id)
    await Promise.all([refreshState(), fetchRecentMeals()])
  }

  function historyDateRange() {
    const to = new Date()
    const from = new Date()
    from.setDate(from.getDate() - 365)
    const fmt = (d: Date) => d.toISOString().slice(0, 10)
    return { from: fmt(from), to: fmt(to) }
  }

  async function fetchFastingHistory() {
    historyLoading.value = true
    error.value = null
    try {
      const { from, to } = historyDateRange()
      const logs = await api.getMeals(from, to)
      const { fasts, summary } = computeFastingHistory(logs)
      fastingHistory.value = fasts
      fastingSummary.value = summary
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Geçmiş alınamadı'
    } finally {
      historyLoading.value = false
    }
  }

  async function openStatsModal() {
    statsModalOpen.value = true
    await fetchFastingHistory()
  }

  function closeStatsModal() {
    statsModalOpen.value = false
  }

  return {
    state,
    meals,
    loading,
    logging,
    error,
    statsModalOpen,
    fastingHistory,
    fastingSummary,
    historyLoading,
    refreshState,
    logMeal,
    fetchRecentMeals,
    deleteMeal,
    openStatsModal,
    closeStatsModal,
    fetchFastingHistory,
  }
})
