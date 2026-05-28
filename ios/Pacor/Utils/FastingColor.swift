import SwiftUI

enum FastingColor {
    private struct RGB {
        var r: Double
        var g: Double
        var b: Double
    }

    private struct ColorStop {
        let at: Double
        let color: RGB
    }

    private static let stops: [ColorStop] = [
        ColorStop(at: 0.0, color: RGB(r: 145, g: 148, b: 158)),
        ColorStop(at: 0.4, color: RGB(r: 220, g: 52, b: 52)),
        ColorStop(at: 0.8, color: RGB(r: 220, g: 52, b: 52)),
        ColorStop(at: 0.87, color: RGB(r: 255, g: 140, b: 150)),
        ColorStop(at: 0.94, color: RGB(r: 140, g: 220, b: 160)),
        ColorStop(at: 1.0, color: RGB(r: 60, g: 190, b: 100)),
    ]

    static func color(fromRatio ratio: Double) -> Color {
        let rgb = multiStopLerp(ratio: ratio)
        return Color(
            red: rgb.r / 255,
            green: rgb.g / 255,
            blue: rgb.b / 255
        )
    }

    static func gradientStops() -> [Gradient.Stop] {
        stops.map { stop in
            let rgb = stop.color
            return Gradient.Stop(
                color: Color(red: rgb.r / 255, green: rgb.g / 255, blue: rgb.b / 255),
                location: stop.at
            )
        }
    }

    private static func multiStopLerp(ratio: Double) -> RGB {
        let r = min(max(ratio, 0), 1)

        if r <= stops[0].at { return stops[0].color }
        if r >= stops[stops.count - 1].at { return stops[stops.count - 1].color }

        for index in 0..<(stops.count - 1) {
            let current = stops[index]
            let next = stops[index + 1]
            if r >= current.at && r <= next.at {
                let t = (r - current.at) / (next.at - current.at)
                return lerpRgb(a: current.color, b: next.color, t: t)
            }
        }

        return stops[stops.count - 1].color
    }

    private static func lerpRgb(a: RGB, b: RGB, t: Double) -> RGB {
        RGB(
            r: a.r + (b.r - a.r) * t,
            g: a.g + (b.g - a.g) * t,
            b: a.b + (b.b - a.b) * t
        )
    }
}
