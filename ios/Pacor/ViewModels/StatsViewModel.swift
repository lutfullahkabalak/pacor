import Foundation
import Observation

@MainActor
@Observable
final class StatsViewModel {
    var fastingHistory: [FastingRecord] = []
    var summary = FastingSummary(count: 0, longestHours: 0, shortestHours: 0)
    var plan = PlanSettings.default
    var isLoading = false
    var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            plan = try await APIClient.shared.getPlan()

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let fromDate = calendar.date(byAdding: .day, value: -365, to: today) ?? today
            let toDate = calendar.date(byAdding: .day, value: 1, to: today) ?? today

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone.current

            let meals = try await APIClient.shared.getMeals(
                from: formatter.string(from: fromDate),
                to: formatter.string(from: toDate)
            )

            let result = FastingHistory.compute(from: meals)
            fastingHistory = result.fasts
            summary = result.summary
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Bir hata oluştu"
        }
    }

    func completion(for record: FastingRecord) -> CompletionInfo {
        PlanTarget.completion(
            fromDurationHours: record.durationHours,
            targetHours: plan.fastingHours,
            targetMinutes: plan.fastingMinutes
        )
    }

    var targetLabel: String {
        PlanTarget.formatTargetDuration(hours: plan.fastingHours, minutes: plan.fastingMinutes)
    }
}
