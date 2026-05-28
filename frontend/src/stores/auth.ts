import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { api, setToken } from '../api/client'

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string | null>(localStorage.getItem('token'))
  const username = ref<string | null>(localStorage.getItem('username'))
  const userId = ref<number | null>(
    localStorage.getItem('user_id') ? Number(localStorage.getItem('user_id')) : null,
  )

  const isAuthenticated = computed(() => !!token.value)

  function persist(session: { token: string; username: string; user_id: number }) {
    token.value = session.token
    username.value = session.username
    userId.value = session.user_id
    setToken(session.token)
    localStorage.setItem('username', session.username)
    localStorage.setItem('user_id', String(session.user_id))
  }

  async function login(user: string, pin: string) {
    const res = await api.login(user, pin)
    persist(res)
  }

  async function register(user: string, pin: string) {
    const res = await api.register(user, pin)
    persist(res)
  }

  function logout() {
    token.value = null
    username.value = null
    userId.value = null
    setToken(null)
    localStorage.removeItem('username')
    localStorage.removeItem('user_id')
  }

  return { token, username, userId, isAuthenticated, login, register, logout }
})
