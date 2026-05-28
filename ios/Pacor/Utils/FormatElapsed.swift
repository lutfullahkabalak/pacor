import Foundation

enum FormatElapsed {
    static func format(totalSeconds: Int) -> String {
        let seconds = max(0, totalSeconds)

        if seconds < 60 {
            return "\(seconds) saniye"
        }

        if seconds < 600 {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes) dk. \(remainingSeconds) saniye"
        }

        if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes) dakika"
        }

        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if minutes == 0 { return "\(hours)s" }
        return "\(hours)s \(minutes)dk"
    }

    static func display(lastMealAt: Date?) -> String {
        guard let lastMealAt else { return "Henüz başlamadı" }
        let elapsed = max(0, Int(Date().timeIntervalSince(lastMealAt)))
        return format(totalSeconds: elapsed)
    }
}
