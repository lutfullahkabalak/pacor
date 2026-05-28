function lerp(a: number, b: number, t: number) {
  return a + (b - a) * t
}

function clamp01(value: number) {
  return Math.min(Math.max(value, 0), 1)
}

type Rgb = { r: number; g: number; b: number }

interface ColorStop {
  at: number
  color: Rgb
}

const STOPS: ColorStop[] = [
  { at: 0.0, color: { r: 145, g: 148, b: 158 } },
  { at: 0.4, color: { r: 220, g: 52, b: 52 } },
  { at: 0.8, color: { r: 220, g: 52, b: 52 } },
  { at: 0.87, color: { r: 255, g: 140, b: 150 } },
  { at: 0.94, color: { r: 140, g: 220, b: 160 } },
  { at: 1.0, color: { r: 60, g: 190, b: 100 } },
]

function lerpRgb(a: Rgb, b: Rgb, t: number): Rgb {
  return {
    r: lerp(a.r, b.r, t),
    g: lerp(a.g, b.g, t),
    b: lerp(a.b, b.b, t),
  }
}

function rgbToCss({ r, g, b }: Rgb): string {
  return `rgb(${Math.round(r)}, ${Math.round(g)}, ${Math.round(b)})`
}

function multiStopLerp(ratio: number): Rgb {
  const r = clamp01(ratio)

  if (r <= STOPS[0].at) return STOPS[0].color
  if (r >= STOPS[STOPS.length - 1].at) return STOPS[STOPS.length - 1].color

  for (let i = 0; i < STOPS.length - 1; i++) {
    const curr = STOPS[i]
    const next = STOPS[i + 1]
    if (r >= curr.at && r <= next.at) {
      const t = (r - curr.at) / (next.at - curr.at)
      return lerpRgb(curr.color, next.color, t)
    }
  }

  return STOPS[STOPS.length - 1].color
}

export function fastingColorFromRatio(ratio: number): string {
  return rgbToCss(multiStopLerp(ratio))
}

export function fastingGradientCss(): string {
  const stops = STOPS.map((stop) => `${rgbToCss(stop.color)} ${stop.at * 100}%`).join(', ')
  return `linear-gradient(to right, ${stops})`
}

export function fastingColor(elapsedMinutes: number, targetHours: number): string {
  const targetMinutes = Math.max(targetHours, 1) * 60
  return fastingColorFromRatio(elapsedMinutes / targetMinutes)
}
