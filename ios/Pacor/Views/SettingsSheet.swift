import SwiftUI

struct SettingsSheet: View {
    @Bindable var viewModel: SettingsViewModel
    var onLogout: () -> Void
    var onPlanSaved: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                AdaptiveGlassContainer {
                    VStack(spacing: 20) {
                        planSection
                        pinSection

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }

                        Button("Çıkış Yap") {
                            dismiss()
                            onLogout()
                        }
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textMuted(for: colorScheme))
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .glassNavigationBar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
        .glassSheetBackground()
    }

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hedef oruç süresi")
                    .font(.headline)
                Text("Buton rengi bu süreye göre değişir")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textMuted(for: colorScheme))
            }

            HStack(alignment: .bottom, spacing: 8) {
                planField(title: "Saat", value: $viewModel.draftPlan.fastingHours)
                Text(":")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(AppTheme.textMuted(for: colorScheme))
                    .padding(.bottom, 12)
                planField(title: "Dakika", value: $viewModel.draftPlan.fastingMinutes)
            }

            Button {
                Task {
                    let saved = await viewModel.savePlan()
                    if saved { onPlanSaved() }
                }
            } label: {
                Text(viewModel.isSavingPlan ? "Kaydediliyor..." : "Hedefi Kaydet")
            }
            .buttonStyle(GlassPrimaryButtonStyle(isDisabled: viewModel.isSavingPlan || viewModel.isLoading))
            .disabled(viewModel.isSavingPlan || viewModel.isLoading)

            if let message = viewModel.planMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.accent(for: colorScheme))
            }
        }
        .padding(16)
        .glassPanel(cornerRadius: 18)
    }

    private var pinSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Şifre değiştir")
                .font(.headline)

            pinField(title: "Mevcut şifre", text: $viewModel.currentPin)
            pinField(title: "Yeni şifre", text: $viewModel.newPin)
            pinField(title: "Yeni şifre tekrar", text: $viewModel.confirmPin)

            Button {
                Task { await viewModel.changePin() }
            } label: {
                Text(viewModel.isChangingPin ? "Değiştiriliyor..." : "Şifreyi Değiştir")
            }
            .buttonStyle(GlassSecondaryButtonStyle())
            .disabled(viewModel.isChangingPin)

            if let message = viewModel.pinMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.accent(for: colorScheme))
            }

            if let error = viewModel.pinError {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
        }
        .padding(16)
        .glassPanel(cornerRadius: 18)
    }

    private func planField(title: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textMuted(for: colorScheme))
            TextField("0", value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .padding(.vertical, 12)
                .glassInput(cornerRadius: 12)
                .onChange(of: value.wrappedValue) { _, _ in
                    viewModel.normalizeDraft()
                }
        }
        .frame(maxWidth: .infinity)
    }

    private func pinField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textMuted(for: colorScheme))
            SecureField("", text: text)
                .keyboardType(.numberPad)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .glassInput(cornerRadius: 12)
        }
    }
}

#Preview {
    SettingsSheet(viewModel: SettingsViewModel(), onLogout: {}, onPlanSaved: {})
}
