<script setup lang="ts">
import { computed } from 'vue'
import { RouterView } from 'vue-router'
import SettingsModal from './components/SettingsModal.vue'
import StatsFab from './components/StatsFab.vue'
import StatsModal from './components/StatsModal.vue'
import { useAuthStore } from './stores/auth'

const auth = useAuthStore()
const showChrome = computed(() => auth.isAuthenticated)
</script>

<template>
  <div class="page-bg" aria-hidden="true" />
  <div class="relative z-[1] min-h-dvh">
    <RouterView />
    <StatsModal />
    <SettingsModal />
    <StatsFab v-if="showChrome" />
  </div>
</template>
