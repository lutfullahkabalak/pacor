import Foundation
import Observation

@MainActor
@Observable
final class AuthViewModel {
    var username = ""
    var pin = ""
    var isRegister = false
    var isLoading = false
    var errorMessage: String?
    var isAuthenticated = false

    func restoreSession() async {
        guard !isAuthenticated else { return }

        await APIClient.shared.restoreSession()
        guard await APIClient.shared.hasSession() else {
            isAuthenticated = false
            return
        }

        do {
            _ = try await APIClient.shared.getCurrentState()
            isAuthenticated = true
        } catch let error as APIError {
            if case .unauthorized = error {
                await APIClient.shared.clearSession()
            }
            isAuthenticated = false
        } catch {
            isAuthenticated = false
        }
    }

    func submit() async {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUsername.isEmpty, pin.count == 4 else {
            errorMessage = "Kullanıcı adı ve 4 haneli PIN gerekli"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response: AuthResponse
            if isRegister {
                response = try await APIClient.shared.register(username: trimmedUsername, pin: pin)
            } else {
                response = try await APIClient.shared.login(username: trimmedUsername, pin: pin)
            }

            await APIClient.shared.setSession(response)

            _ = try await APIClient.shared.getCurrentState()
            isAuthenticated = true
            pin = ""
        } catch let error as APIError {
            await APIClient.shared.clearSession()
            isAuthenticated = false
            errorMessage = error.errorDescription
            pin = ""
        } catch let error as URLError {
            await APIClient.shared.clearSession()
            isAuthenticated = false
            errorMessage = "Sunucuya bağlanılamadı"
            pin = ""
        } catch {
            await APIClient.shared.clearSession()
            isAuthenticated = false
            errorMessage = "Giriş başarısız"
            pin = ""
        }
    }

    func logout() async {
        await APIClient.shared.clearSession()
        isAuthenticated = false
        username = ""
        pin = ""
        errorMessage = nil
    }

    func handleUnauthorized() async {
        guard isAuthenticated else { return }
        await APIClient.shared.clearSession()
        isAuthenticated = false
        pin = ""
        errorMessage = nil
    }
}
