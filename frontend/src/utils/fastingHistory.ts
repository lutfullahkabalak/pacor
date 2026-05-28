import type { MealLog } from '../types'

export interface FastingRecord {
  start: string
  end: string
  duration_hours: number
}

export interface FastingSummary {
  count: number
  longest_hours: number
  shortest_hours: number
}

export function computeFastingHistory(meals: MealLog[]): {
  fasts: FastingRecord[]
  summary: FastingSummary
} {
  if (meals.length < 2) {
    return {
      fasts: [],
      summary: { count: 0, longest_hours: 0, shortest_hours: 0 },
    }
  }

  const sorted = [...meals].sort(
    (a, b) => new Date(a.logged_at).getTime() - new Date(b.logged_at).getTime(),
  )

  const fasts: FastingRecord[] = []
  for (let i = 1; i < sorted.length; i++) {
    const start = sorted[i - 1].logged_at
    const end = sorted[i].logged_at
    const duration_hours =
      (new Date(end).getTime() - new Date(start).getTime()) / 3600000
    fasts.push({
      start,
      end,
      duration_hours: Math.round(duration_hours * 100) / 100,
    })
  }

  fasts.reverse()

  const durations = fasts.map((f) => f.duration_hours)
  return {
    fasts,
    summary: {
      count: fasts.length,
      longest_hours: Math.max(...durations),
      shortest_hours: Math.min(...durations),
    },
  }
}

export function formatDuration(hours: number): string {
  const totalMinutes = Math.round(hours * 60)
  const h = Math.floor(totalMinutes / 60)
  const m = totalMinutes % 60
  if (h === 0) return `${m}dk`
  if (m === 0) return `${h}s`
  return `${h}s ${m}dk`
}

export function formatTimeRange(start: string, end: string): string {
  const opts: Intl.DateTimeFormatOptions = { hour: '2-digit', minute: '2-digit' }
  const startDate = new Date(start)
  const endDate = new Date(end)
  const sameDay =
    startDate.toDateString() === endDate.toDateString()

  const timeRange = `${startDate.toLocaleTimeString('tr-TR', opts)} – ${endDate.toLocaleTimeString('tr-TR', opts)}`

  if (sameDay) {
    return `${startDate.toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' })} · ${timeRange}`
  }

  const dateStart = startDate.toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' })
  const dateEnd = endDate.toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' })
  return `${dateStart} ${startDate.toLocaleTimeString('tr-TR', opts)} – ${dateEnd} ${endDate.toLocaleTimeString('tr-TR', opts)}`
}
