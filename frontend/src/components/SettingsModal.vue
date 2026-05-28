<script setup lang="ts">
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { storeToRefs } from 'pinia'
import PlanPicker from './PlanPicker.vue'
import { useAuthStore } from '../stores/auth'
import { useMealsStore } from '../stores/meals'
import { useSettingsStore } from '../stores/settings'
import { DEFAULT_PLAN, type PlanSettings } from '../types'
import { isValidPlanTarget, normalizePlanTarget } from '../utils/planTarget'
import { useEscapeKey } from '../composables/useEscapeKey'

const settings = useSettingsStore()
const auth = useAuthStore()
const meals = useMealsStore()
const router = useRouter()

const { settingsModalOpen, plan, loading, error } = storeToRefs(settings)

const draft = ref<PlanSettings>({ ...DEFAULT_PLAN })
const savingPlan = ref(false)
const planMessage = ref<string | null>(null)

const currentPin = ref('')
const newPin = ref('')
const confirmPin = ref('')
const changingPin = ref(false)
const pinMessage = ref<string | null>(null)
const pinError = ref<string | null>(null)

watch(settingsModalOpen, (open) => {
  if (!open) return
  draft.value = { ...plan.value }
  planMessage.value = null
  currentPin.value = ''
  newPin.value = ''
  confirmPin.value = ''
  pinMessage.value = null
  pinError.value = null
})

function close() {
  settings.closeSettingsModal()
}

useEscapeKey(close, () => settingsModalOpen.value)

function onBackdropClick(e: MouseEvent) {
  if (e.target === e.currentTarget) close()
}

async function savePlan() {
  savingPlan.value = true
  planMessage.value = null
  try {
    const { fasting_hours, fasting_minutes } = normalizePlanTarget(
      draft.value.fasting_hours,
      draft.value.fasting_minutes,
    )

    if (!isValidPlanTarget(fasting_hours, fasting_minutes)) {
      planMessage.value = 'Hedef en az 1 dakika olmalı'
      return
    }

    await settings.savePlan({
      ...draft.value,
      fasting_hours,
      fasting_minutes,
    })
    draft.value = { ...draft.value, fasting_hours, fasting_minutes }
    planMessage.value = 'Hedef kaydedildi'
    await meals.refreshState()
  } catch (e) {
    planMessage.value = e instanceof Error ? e.message : 'Kaydedilemedi'
  } finally {
    savingPlan.value = false
  }
}

async function changePin() {
  pinMessage.value = null
  pinError.value = null

  if (newPin.value.length < 4) {
    pinError.value = 'Yeni şifre en az 4 hane olmalı'
    return
  }
  if (newPin.value !== confirmPin.value) {
    pinError.value = 'Yeni şifreler eşleşmiyor'
    return
  }

  changingPin.value = true
  try {
    await settings.changePin(currentPin.value, newPin.value)
    pinMessage.value = 'Şifre değiştirildi'
    currentPin.value = ''
    newPin.value = ''
    confirmPin.value = ''
  } catch (e) {
    pinError.value = e instanceof Error ? e.message : 'Şifre değiştirilemedi'
  } finally {
    changingPin.value = false
  }
}

function logout() {
  close()
  auth.logout()
  router.push('/login')
}
</script>

<template>
  <Teleport to="body">
    <Transition name="modal">
      <div
        v-if="settingsModalOpen"
        class="fixed inset-0 z-50 flex items-end sm:items-center justify-center overlay-backdrop backdrop-blur-sm"
        @click="onBackdropClick"
      >
        <div
          class="modal-panel w-full max-w-lg max-h-[85dvh] sm:max-h-[80dvh] rounded-t-3xl sm:rounded-3xl flex flex-col shadow-2xl"
          @click.stop
        >
          <header class="flex items-center justify-between px-5 pt-5 pb-3 border-b border-app shrink-0">
            <div>
              <h2 class="text-xl font-bold">Ayarlar</h2>
              <p class="text-sm text-muted">{{ auth.username }}</p>
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

          <div class="overflow-y-auto flex-1 px-5 py-4 space-y-6">
            <section class="card rounded-2xl p-4 space-y-4">
              <div>
                <h3 class="font-semibold">Hedef oruç süresi</h3>
                <p class="text-sm text-muted mt-1">Buton rengi bu süreye göre değişir</p>
              </div>
              <PlanPicker :model-value="draft" />
              <button
                type="button"
                class="w-full rounded-xl btn-accent py-3 font-semibold disabled:opacity-60"
                :disabled="savingPlan || loading"
                @click="savePlan"
              >
                {{ savingPlan ? 'Kaydediliyor...' : 'Hedefi Kaydet' }}
              </button>
              <p v-if="planMessage" class="text-sm text-[var(--accent)]">{{ planMessage }}</p>
            </section>

            <section class="card rounded-2xl p-4 space-y-4">
              <h3 class="font-semibold">Şifre değiştir</h3>
              <label class="block text-sm">
                <span class="text-muted">Mevcut şifre</span>
                <input
                  v-model="currentPin"
                  type="password"
                  inputmode="numeric"
                  autocomplete="current-password"
                  class="mt-1 w-full rounded-xl border border-app bg-app-input px-3 py-3"
                />
              </label>
              <label class="block text-sm">
                <span class="text-muted">Yeni şifre</span>
                <input
                  v-model="newPin"
                  type="password"
                  inputmode="numeric"
                  autocomplete="new-password"
                  class="mt-1 w-full rounded-xl border border-app bg-app-input px-3 py-3"
                />
              </label>
              <label class="block text-sm">
                <span class="text-muted">Yeni şifre tekrar</span>
                <input
                  v-model="confirmPin"
                  type="password"
                  inputmode="numeric"
                  autocomplete="new-password"
                  class="mt-1 w-full rounded-xl border border-app bg-app-input px-3 py-3"
                />
              </label>
              <button
                type="button"
                class="w-full rounded-xl border border-app py-3 font-semibold disabled:opacity-60"
                :disabled="changingPin"
                @click="changePin"
              >
                {{ changingPin ? 'Değiştiriliyor...' : 'Şifreyi Değiştir' }}
              </button>
              <p v-if="pinMessage" class="text-sm text-[var(--accent)]">{{ pinMessage }}</p>
              <p v-if="pinError" class="text-sm text-rose-400">{{ pinError }}</p>
            </section>

            <p v-if="error" class="text-rose-400 text-sm text-center">{{ error }}</p>

            <button
              type="button"
              class="w-full py-2 text-sm text-muted hover:opacity-80 transition-opacity"
              @click="logout"
            >
              Çıkış Yap
            </button>
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
