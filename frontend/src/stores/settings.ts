import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api } from '../api/client'
import { DEFAULT_PLAN, type PlanSettings } from '../types'
import { normalizePlanTarget } from '../utils/planTarget'

export const useSettingsStore = defineStore('settings', () => {
  const plan = ref<PlanSettings>({ ...DEFAULT_PLAN })
  const loading = ref(false)
  const error = ref<string | null>(null)
  const settingsModalOpen = ref(false)

  async function fetchPlan() {
    loading.value = true
    error.value = null
    try {
      const fetched = await api.getPlan()
      plan.value = {
        ...DEFAULT_PLAN,
        ...fetched,
        fasting_minutes: fetched.fasting_minutes ?? 0,
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Plan alınamadı'
    } finally {
      loading.value = false
    }
  }

  async function savePlan(next: PlanSettings) {
    loading.value = true
    error.value = null
    try {
      const { fasting_hours, fasting_minutes } = normalizePlanTarget(
        next.fasting_hours,
        next.fasting_minutes,
      )
      const payload: PlanSettings = {
        plan_type: 'custom',
        fasting_hours,
        fasting_minutes,
        eating_hours: Math.max(1, 24 - fasting_hours),
      }
      const saved = await api.updatePlan(payload)
      plan.value = {
        ...DEFAULT_PLAN,
        ...saved,
        fasting_hours,
        fasting_minutes,
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Plan kaydedilemedi'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function changePin(currentPin: string, newPin: string) {
    error.value = null
    await api.changePin(currentPin, newPin)
  }

  async function openSettingsModal() {
    settingsModalOpen.value = true
    await fetchPlan()
  }

  function closeSettingsModal() {
    settingsModalOpen.value = false
  }

  return {
    plan,
    loading,
    error,
    settingsModalOpen,
    fetchPlan,
    savePlan,
    changePin,
    openSettingsModal,
    closeSettingsModal,
  }
})
