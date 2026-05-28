import { defineStore } from 'pinia'
import { ref } from 'vue'

function getSystemTheme(): 'light' | 'dark' {
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
}

export const useThemeStore = defineStore('theme', () => {
  const resolvedTheme = ref<'light' | 'dark'>(getSystemTheme())

  function applyTheme() {
    document.documentElement.dataset.theme = resolvedTheme.value
  }

  function init() {
    resolvedTheme.value = getSystemTheme()
    applyTheme()
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
      resolvedTheme.value = e.matches ? 'dark' : 'light'
      applyTheme()
    })
  }

  return { resolvedTheme, init }
})
