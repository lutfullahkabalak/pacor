import Foundation

enum PlanTarget {
    static func normalize(hours: Int, minutes: Int) -> (fastingHours: Int, fastingMinutes: Int) {
        (
            fastingHours: max(0, hours),
            fastingMinutes: min(59, max(0, minutes))
        )
    }

    static func totalTargetMinutes(hours: Int, minutes: Int) -> Int {
        hours * 60 + minutes
    }

    static func isValid(hours: Int, minutes: Int) -> Bool {
        hours >= 0 && minutes >= 0 && minutes <= 59 && totalTargetMinutes(hours: hours, minutes: minutes) >= 1
    }

    static func formatTargetDuration(hours: Int, minutes: Int) -> String {
        if hours == 0 { return "\(minutes)dk" }
        if minutes == 0 { return "\(hours)s" }
        return "\(hours)s \(minutes)dk"
    }

    static func completion(fromDurationHours durationHours: Double, targetHours: Int, targetMinutes: Int) -> CompletionInfo {
        let targetTotal = totalTargetMinutes(hours: targetHours, minutes: targetMinutes)
        let elapsedMinutes = durationHours * 60
        let percent = targetTotal > 0 ? Int(round((elapsedMinutes / Double(targetTotal)) * 100)) : 0
        let fillRatio = targetTotal > 0 ? min(elapsedMinutes / Double(targetTotal), 1) : 0
        return CompletionInfo(percent: percent, fillRatio: fillRatio)
    }

    static func prepareForSave(_ plan: PlanSettings) -> PlanSettings {
        let normalized = normalize(hours: plan.fastingHours, minutes: plan.fastingMinutes)
        let eatingHours = max(1, 24 - normalized.fastingHours)
        return PlanSettings(
            planType: "custom",
            eatingHours: eatingHours,
            fastingHours: normalized.fastingHours,
            fastingMinutes: normalized.fastingMinutes
        )
    }
}
