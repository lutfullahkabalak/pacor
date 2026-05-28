import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    var lastMealAt: Date?
    var plan = PlanSettings.default
    var displayText = "Henüz başlamadı"
    var progressRatio: Double = 0
    var buttonColor = FastingColor.color(fromRatio: 0)
    var isLogging = false
    var errorMessage: String?
    var showStats = false
    var showSettings = false
    var onUnauthorized: (() async -> Void)?

    private var tickTimer: Timer?
    private var pollTimer: Timer?

    var targetTotalMinutes: Int {
        let total = PlanTarget.totalTargetMinutes(hours: plan.fastingHours, minutes: plan.fastingMinutes)
        return total > 0 ? total : 60
    }

    func onAppear() async {
        await refreshAll()
        startTimers()
    }

    func onDisappear() {
        tickTimer?.invalidate()
        pollTimer?.invalidate()
        tickTimer = nil
        pollTimer = nil
    }

    func refreshAll() async {
        do {
            let state = try await APIClient.shared.getCurrentState()
            let fetchedPlan = try await APIClient.shared.getPlan()
            plan = fetchedPlan
            if let lastMealString = state.lastMealAt {
                lastMealAt = FastingHistory.parseDate(lastMealString)
            } else {
                lastMealAt = nil
            }
            updateDisplay()
            errorMessage = nil
        } catch let error as APIError {
            if case .unauthorized = error {
                await onUnauthorized?()
            } else {
                errorMessage = error.errorDescription
            }
        } catch {
            errorMessage = "Bir hata oluştu"
        }
    }

    func logMeal() async {
        guard !isLogging else { return }
        isLogging = true
        errorMessage = nil
        defer { isLogging = false }

        do {
            let meal = try await APIClient.shared.logMeal()
            if let loggedAt = FastingHistory.parseDate(meal.loggedAt) {
                lastMealAt = loggedAt
                updateDisplay()
            }
            await refreshAll()
        } catch let error as APIError {
            if case .unauthorized = error {
                await onUnauthorized?()
            } else {
                errorMessage = error.errorDescription
            }
        } catch {
            errorMessage = "Kayıt başarısız"
        }
    }

    func reset() {
        onDisappear()
        onUnauthorized = nil
        lastMealAt = nil
        plan = PlanSettings.default
        displayText = "Henüz başlamadı"
        progressRatio = 0
        buttonColor = FastingColor.color(fromRatio: 0)
        isLogging = false
        errorMessage = nil
        showStats = false
        showSettings = false
    }

    private func startTimers() {
        tickTimer?.invalidate()
        pollTimer?.invalidate()

        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateDisplay()
            }
        }

        pollTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.statePollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshAll()
            }
        }
    }

    private func updateDisplay() {
        displayText = FormatElapsed.display(lastMealAt: lastMealAt)

        guard let lastMealAt else {
            progressRatio = 0
            buttonColor = FastingColor.color(fromRatio: 0)
            return
        }

        let elapsedMinutes = max(0, Date().timeIntervalSince(lastMealAt) / 60)
        progressRatio = min(elapsedMinutes / Double(targetTotalMinutes), 1)
        buttonColor = FastingColor.color(fromRatio: progressRatio)
    }
}
