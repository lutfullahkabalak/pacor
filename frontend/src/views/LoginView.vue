<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import PinCodeField from '../components/PinCodeField.vue'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const router = useRouter()

const username = ref('')
const pin = ref('')
const isRegister = ref(false)
const loading = ref(false)
const error = ref<string | null>(null)
const usernameInputRef = ref<HTMLInputElement | null>(null)

function attemptSubmit() {
  const trimmedUsername = username.value.trim()
  if (!trimmedUsername) {
    error.value = 'Önce kullanıcı adını gir'
    pin.value = ''
    usernameInputRef.value?.focus()
    return
  }

  if (loading.value) return
  void submit()
}

async function submit() {
  const trimmedUsername = username.value.trim()
  if (!trimmedUsername || pin.value.length !== 4) {
    error.value = 'Kullanıcı adı ve 4 haneli PIN gerekli'
    return
  }

  loading.value = true
  error.value = null
  try {
    if (isRegister.value) {
      await auth.register(trimmedUsername, pin.value)
    } else {
      await auth.login(trimmedUsername, pin.value)
    }
    router.push('/')
  } catch (e) {
    error.value = e instanceof Error ? e.message : 'Giriş başarısız'
    pin.value = ''
  } finally {
    loading.value = false
  }
}

function toggleMode() {
  isRegister.value = !isRegister.value
  error.value = null
  pin.value = ''
}
</script>

<template>
  <div
    class="min-h-dvh flex items-center justify-center px-4 py-[var(--safe-top)] pb-[var(--safe-bottom)]"
  >
    <div class="w-full max-w-sm space-y-6">
      <div class="text-center">
        <h1 class="text-3xl font-bold">Aralıklı Oruç</h1>
        <p class="text-muted mt-2">Yeme saatlerini tek dokunuşla kaydet</p>
      </div>

      <form class="card rounded-3xl p-5 space-y-5" @submit.prevent="attemptSubmit">
        <input
          ref="usernameInputRef"
          v-model="username"
          autocomplete="username"
          class="w-full rounded-xl border border-app bg-app-input px-4 py-4 text-xl text-center font-medium"
          placeholder="kullanıcı adın"
        />

        <PinCodeField v-model="pin" @complete="attemptSubmit" />

        <p v-if="loading" class="text-muted text-sm text-center">Bekleyin...</p>

        <p v-if="error" class="text-rose-400 text-sm text-center">{{ error }}</p>

        <button
          v-if="isRegister"
          type="submit"
          class="w-full rounded-xl btn-accent py-4 font-semibold disabled:opacity-60"
          :disabled="loading"
        >
          {{ loading ? 'Bekleyin...' : 'Kayıt Ol' }}
        </button>
      </form>

      <button type="button" class="w-full text-sm text-muted text-center" @click="toggleMode">
        {{ isRegister ? 'Zaten hesabın var mı? Giriş yap' : 'Yeni hesap oluştur' }}
      </button>
    </div>
  </div>
</template>
