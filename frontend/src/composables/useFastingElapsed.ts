import { computed, onMounted, onUnmounted, ref, type Ref } from 'vue'
import { fastingColorFromRatio } from '../utils/fastingColor'
import { formatElapsed } from '../utils/formatElapsed'

export function useFastingElapsed(
  lastMealAt: Ref<string | null>,
  targetHours: Ref<number>,
  targetMinutes: Ref<number>,
) {
  const now = ref(Date.now())
  let timer: ReturnType<typeof setInterval> | null = null

  onMounted(() => {
    timer = setInterval(() => {
      now.value = Date.now()
    }, 1000)
  })

  onUnmounted(() => {
    if (timer) clearInterval(timer)
  })

  const elapsedSeconds = computed(() => {
    if (!lastMealAt.value) return 0
    const last = new Date(lastMealAt.value).getTime()
    return Math.max(0, Math.floor((now.value - last) / 1000))
  })

  const targetTotalMinutes = computed(() => {
    const hours = Number.isFinite(Number(targetHours.value))
      ? Math.max(0, Number(targetHours.value))
      : 0
    const minutes = Number.isFinite(Number(targetMinutes.value))
      ? Math.max(0, Number(targetMinutes.value))
      : 0
    const total = hours * 60 + minutes
    return total > 0 ? total : 60
  })

  const display = computed(() => {
    if (!lastMealAt.value) return 'Henüz başlamadı'
    return formatElapsed(elapsedSeconds.value)
  })

  const ratio = computed(() => {
    const elapsedMinutes = elapsedSeconds.value / 60
    return Math.min(elapsedMinutes / targetTotalMinutes.value, 1)
  })

  const backgroundColor = computed(() => fastingColorFromRatio(ratio.value))

  return {
    display,
    elapsedSeconds,
    ratio,
    backgroundColor,
    targetTotalMinutes,
  }
}
