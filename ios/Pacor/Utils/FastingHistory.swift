import Foundation

enum FastingHistory {
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatterNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func parseDate(_ string: String) -> Date? {
        isoFormatter.date(from: string) ?? isoFormatterNoFraction.date(from: string)
    }

    static func compute(from meals: [MealLog]) -> (fasts: [FastingRecord], summary: FastingSummary) {
        guard meals.count >= 2 else {
            return ([], FastingSummary(count: 0, longestHours: 0, shortestHours: 0))
        }

        let sorted = meals
            .compactMap { meal -> (MealLog, Date)? in
                guard let date = parseDate(meal.loggedAt) else { return nil }
                return (meal, date)
            }
            .sorted { $0.1 < $1.1 }

        var fasts: [FastingRecord] = []
        for index in 1..<sorted.count {
            let start = sorted[index - 1].1
            let end = sorted[index].1
            let durationHours = (end.timeIntervalSince(start) / 3600 * 100).rounded() / 100
            fasts.append(FastingRecord(start: start, end: end, durationHours: durationHours))
        }

        fasts.reverse()

        guard !fasts.isEmpty else {
            return ([], FastingSummary(count: 0, longestHours: 0, shortestHours: 0))
        }

        let durations = fasts.map(\.durationHours)
        return (
            fasts,
            FastingSummary(
                count: fasts.count,
                longestHours: durations.max() ?? 0,
                shortestHours: durations.min() ?? 0
            )
        )
    }

    static func formatDuration(hours: Double) -> String {
        let totalMinutes = Int(round(hours * 60))
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h == 0 { return "\(m)dk" }
        if m == 0 { return "\(h)s" }
        return "\(h)s \(m)dk"
    }

    static func formatTimeRange(start: Date, end: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "tr_TR")
        timeFormatter.dateFormat = "HH:mm"

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "tr_TR")
        dateFormatter.dateFormat = "d MMM"

        let timeRange = "\(timeFormatter.string(from: start)) – \(timeFormatter.string(from: end))"

        if Calendar.current.isDate(start, inSameDayAs: end) {
            return "\(dateFormatter.string(from: start)) · \(timeRange)"
        }

        return "\(dateFormatter.string(from: start)) \(timeFormatter.string(from: start)) – \(dateFormatter.string(from: end)) \(timeFormatter.string(from: end))"
    }
}
