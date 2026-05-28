export function formatElapsed(totalSeconds: number): string {
  const seconds = Math.max(0, Math.floor(totalSeconds))

  if (seconds < 60) {
    return `${seconds} saniye`
  }

  if (seconds < 600) {
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = seconds % 60
    return `${minutes} dk. ${remainingSeconds} saniye`
  }

  if (seconds < 3600) {
    const minutes = Math.floor(seconds / 60)
    return `${minutes} dakika`
  }

  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  if (minutes === 0) return `${hours}s`
  return `${hours}s ${minutes}dk`
}
