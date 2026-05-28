<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const router = useRouter()

const username = ref('')
const pin = ref('')
const isRegister = ref(false)
const loading = ref(false)
const error = ref<string | null>(null)

async function submit() {
  if (!username.value || pin.value.length < 4) {
    error.value = 'Kullanıcı adı ve en az 4 haneli PIN gerekli'
    return
  }

  loading.value = true
  error.value = null
  try {
    if (isRegister.value) {
      await auth.register(username.value.trim(), pin.value)
    } else {
      await auth.login(username.value.trim(), pin.value)
    }
    router.push('/')
  } catch (e) {
    error.value = e instanceof Error ? e.message : 'Giriş başarısız'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-dvh flex items-center justify-center px-4 pt-[var(--safe-top)] pb-[var(--safe-bottom)]">
    <div class="w-full max-w-sm space-y-6">
      <div class="text-center">
        <h1 class="text-3xl font-bold">Aralıklı Oruç</h1>
        <p class="text-muted mt-2">Yeme saatlerini tek dokunuşla kaydet</p>
      </div>

      <form class="space-y-4" @submit.prevent="submit">
        <label class="block">
          <span class="text-sm text-muted">Kullanıcı adı</span>
          <input
            v-model="username"
            autocomplete="username"
            class="mt-1 w-full rounded-xl border border-app bg-app-input px-4 py-4 text-lg"
            placeholder="ör. lutfi"
          />
        </label>

        <label class="block">
          <span class="text-sm text-muted">PIN</span>
          <input
            v-model="pin"
            type="password"
            inputmode="numeric"
            autocomplete="current-password"
            maxlength="8"
            class="mt-1 w-full rounded-xl border border-app bg-app-input px-4 py-4 text-2xl tracking-[0.3em] text-center"
            placeholder="••••"
          />
        </label>

        <p v-if="error" class="text-rose-400 text-sm">{{ error }}</p>

        <button
          type="submit"
          class="w-full rounded-xl btn-accent py-4 font-semibold disabled:opacity-60"
          :disabled="loading"
        >
          {{ loading ? 'Bekleyin...' : isRegister ? 'Kayıt Ol' : 'Giriş Yap' }}
        </button>
      </form>

      <button
        type="button"
        class="w-full text-sm text-muted"
        @click="isRegister = !isRegister"
      >
        {{ isRegister ? 'Zaten hesabın var mı? Giriş yap' : 'Yeni hesap oluştur' }}
      </button>
    </div>
  </div>
</template>
