import SwiftUI

struct LoginView: View {
    @Bindable var auth: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isUsernameFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 0)

                    VStack(spacing: 8) {
                        Text("Aralıklı Oruç")
                            .font(.system(size: 32, weight: .bold))
                            .multilineTextAlignment(.center)
                        Text("Yeme saatlerini tek dokunuşla kaydet")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textMuted(for: colorScheme))
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 20) {
                        TextField("kullanıcı adın", text: $auth.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.center)
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .padding(.vertical, 16)
                            .padding(.horizontal, 12)
                            .glassInput(cornerRadius: 14)
                            .focused($isUsernameFocused)
                            .submitLabel(.next)

                        PinCodeField(pin: $auth.pin) {
                            attemptSubmit()
                        }

                        if auth.isLoading {
                            Text("Bekleyin...")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textMuted(for: colorScheme))
                                .frame(maxWidth: .infinity)
                        }

                        if let error = auth.errorMessage {
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }

                        if auth.isRegister {
                            Button {
                                Task { await auth.submit() }
                            } label: {
                                Text(auth.isLoading ? "Bekleyin..." : "Kayıt Ol")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(GlassPrimaryButtonStyle(isDisabled: auth.isLoading))
                            .disabled(auth.isLoading)
                        }
                    }
                    .padding(20)
                    .glassPanel(cornerRadius: 24)

                    Button {
                        auth.isRegister.toggle()
                        auth.errorMessage = nil
                        auth.pin = ""
                    } label: {
                        Text(auth.isRegister ? "Zaten hesabın var mı? Giriş yap" : "Yeni hesap oluştur")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textMuted(for: colorScheme))
                            .multilineTextAlignment(.center)
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: 400)
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height)
                .padding(.horizontal, 20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func attemptSubmit() {
        isUsernameFocused = false

        let trimmedUsername = auth.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty else {
            auth.errorMessage = "Önce kullanıcı adını gir"
            auth.pin = ""
            isUsernameFocused = true
            return
        }

        guard !auth.isLoading else { return }

        Task { await auth.submit() }
    }
}

#Preview {
    LoginView(auth: AuthViewModel())
}
