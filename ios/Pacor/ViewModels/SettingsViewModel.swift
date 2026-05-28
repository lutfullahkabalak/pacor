import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var plan = PlanSettings.default
    var draftPlan = PlanSettings.default
    var isLoading = false
    var isSavingPlan = false
    var isChangingPin = false
    var planMessage: String?
    var pinMessage: String?
    var pinError: String?
    var errorMessage: String?

    var currentPin = ""
    var newPin = ""
    var confirmPin = ""

    var username: String {
        KeychainService.username ?? ""
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            plan = try await APIClient.shared.getPlan()
            draftPlan = plan
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Bir hata oluştu"
        }
    }

    func resetDraft() {
        draftPlan = plan
        planMessage = nil
        currentPin = ""
        newPin = ""
        confirmPin = ""
        pinMessage = nil
        pinError = nil
    }

    func normalizeDraft() {
        let normalized = PlanTarget.normalize(
            hours: draftPlan.fastingHours,
            minutes: draftPlan.fastingMinutes
        )
        draftPlan.fastingHours = normalized.fastingHours
        draftPlan.fastingMinutes = normalized.fastingMinutes
    }

    func savePlan() async -> Bool {
        normalizeDraft()

        guard PlanTarget.isValid(hours: draftPlan.fastingHours, minutes: draftPlan.fastingMinutes) else {
            planMessage = "Hedef en az 1 dakika olmalı"
            return false
        }

        isSavingPlan = true
        planMessage = nil
        defer { isSavingPlan = false }

        do {
            let prepared = PlanTarget.prepareForSave(draftPlan)
            plan = try await APIClient.shared.updatePlan(prepared)
            draftPlan = plan
            planMessage = "Hedef kaydedildi"
            return true
        } catch let error as APIError {
            planMessage = error.errorDescription
        } catch {
            planMessage = "Kaydedilemedi"
        }
        return false
    }

    func changePin() async {
        pinMessage = nil
        pinError = nil

        guard newPin.count >= 4 else {
            pinError = "Yeni şifre en az 4 hane olmalı"
            return
        }

        guard newPin == confirmPin else {
            pinError = "Yeni şifreler eşleşmiyor"
            return
        }

        isChangingPin = true
        defer { isChangingPin = false }

        do {
            try await APIClient.shared.changePinVoid(currentPin: currentPin, newPin: newPin)
            pinMessage = "Şifre değiştirildi"
            currentPin = ""
            newPin = ""
            confirmPin = ""
        } catch let error as APIError {
            pinError = error.errorDescription
        } catch {
            pinError = "Şifre değiştirilemedi"
        }
    }
}
