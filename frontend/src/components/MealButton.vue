<script setup lang="ts">
import { computed } from 'vue'
import PacManIcon from './PacManIcon.vue'

const props = defineProps<{
  loading?: boolean
  backgroundColor: string
  progress: number
}>()

const emit = defineEmits<{ click: [] }>()

const RING_RADIUS = 47
const RING_CIRCUMFERENCE = 2 * Math.PI * RING_RADIUS

const clampedProgress = computed(() => Math.min(Math.max(props.progress, 0), 1))

const ringOffset = computed(
  () => RING_CIRCUMFERENCE * (1 - clampedProgress.value),
)

const ringOpacity = computed(() => {
  if (clampedProgress.value <= 0) return 0
  return 0.25 + clampedProgress.value * 0.75
})
</script>

<template>
  <div class="flex justify-center">
    <div class="relative grid place-items-center w-[15rem] h-[15rem] sm:w-[16rem] sm:h-[16rem]">
      <svg
        class="col-start-1 row-start-1 z-10 w-full h-full -rotate-90 pointer-events-none"
        viewBox="0 0 100 100"
        aria-hidden="true"
      >
        <circle
          cx="50"
          cy="50"
          :r="RING_RADIUS"
          fill="none"
          :stroke="backgroundColor"
          stroke-width="5"
          stroke-linecap="round"
          :stroke-dasharray="RING_CIRCUMFERENCE"
          :stroke-dashoffset="ringOffset"
          :opacity="ringOpacity"
          class="transition-[stroke-dashoffset,opacity,stroke] duration-700"
        />
      </svg>

      <button
        type="button"
        class="col-start-1 row-start-1 w-52 h-52 sm:w-56 sm:h-56 rounded-full flex items-center justify-center active:scale-[0.97] transition-[transform,background-color] duration-700 disabled:pointer-events-none"
        :class="loading ? 'opacity-70 animate-pulse' : ''"
        :style="{ backgroundColor }"
        :disabled="loading"
        aria-label="Yedim"
        @click="emit('click')"
      >
        <PacManIcon />
      </button>
    </div>
  </div>
</template>
