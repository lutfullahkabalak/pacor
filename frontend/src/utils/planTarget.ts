export function normalizePlanTarget(hours: unknown, minutes: unknown) {
  const parsedHours = Number(hours)
  const parsedMinutes = Number(minutes)

  return {
    fasting_hours: Number.isFinite(parsedHours)
      ? Math.max(0, Math.floor(parsedHours))
      : 0,
    fasting_minutes: Number.isFinite(parsedMinutes)
      ? Math.min(59, Math.max(0, Math.floor(parsedMinutes)))
      : 0,
  }
}

export function totalTargetMinutes(hours: number, minutes: number): number {
  return hours * 60 + minutes
}

export function isValidPlanTarget(hours: number, minutes: number): boolean {
  return (
    hours >= 0 &&
    minutes >= 0 &&
    minutes <= 59 &&
    totalTargetMinutes(hours, minutes) >= 1
  )
}

export function formatTargetDuration(hours: number, minutes: number): string {
  if (hours === 0) return `${minutes}dk`
  if (minutes === 0) return `${hours}s`
  return `${hours}s ${minutes}dk`
}

export function completionFromDuration(
  durationHours: number,
  targetHours: number,
  targetMinutes: number,
) {
  const targetTotal = totalTargetMinutes(targetHours, targetMinutes)
  const elapsedMinutes = durationHours * 60
  const percent =
    targetTotal > 0 ? Math.round((elapsedMinutes / targetTotal) * 100) : 0

  return {
    percent,
    fillRatio: targetTotal > 0 ? Math.min(elapsedMinutes / targetTotal, 1) : 0,
  }
}
