import SwiftUI

struct HomeView: View {
    @Bindable var home: HomeViewModel
    @Bindable var auth: AuthViewModel
    @State private var statsViewModel = StatsViewModel()
    @State private var settingsViewModel = SettingsViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer()

                Text(home.displayText)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.elapsedText(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .animation(.easeInOut(duration: 0.3), value: home.displayText)

                Spacer()

                MealButtonView(
                    backgroundColor: home.buttonColor,
                    progress: home.progressRatio,
                    isLoading: home.isLogging
                ) {
                    Task { await home.logMeal() }
                }

                if let error = home.errorMessage, !home.showStats, !home.showSettings {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                Spacer()
            }

            StatsFab {
                home.showStats = true
            }
            .padding(.trailing, 16)
            .padding(.bottom, 16)
        }
        .task {
            home.onUnauthorized = {
                home.reset()
                await auth.handleUnauthorized()
            }
            await home.onAppear()
        }
        .onDisappear {
            home.onDisappear()
        }
        .sheet(isPresented: $home.showStats) {
            StatsSheet(viewModel: statsViewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $home.showSettings) {
            SettingsSheet(
                viewModel: settingsViewModel,
                onLogout: {
                    home.showSettings = false
                    Task { await auth.logout() }
                },
                onPlanSaved: {
                    Task { await home.refreshAll() }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: home.showStats) { _, isOpen in
            if isOpen {
                Task { await statsViewModel.load() }
            }
        }
        .onChange(of: home.showSettings) { _, isOpen in
            if isOpen {
                settingsViewModel.resetDraft()
                Task { await settingsViewModel.load() }
            }
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                PacManIcon(headOnly: true, showPellets: false)
                    .frame(width: 36, height: 36)
                Text("Pacor")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassPanel(cornerRadius: 18)

            Spacer()

            Button {
                home.showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(GlassIconButtonStyle())
            .glassCircle()
            .accessibilityLabel("Ayarlar")
        }
    }
}

#Preview {
    HomeView(home: HomeViewModel(), auth: AuthViewModel())
}
