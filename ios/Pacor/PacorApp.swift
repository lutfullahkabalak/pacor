import SwiftUI

@main
struct PacorApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @State private var auth = AuthViewModel()
    @State private var home = HomeViewModel()

    var body: some View {
        Group {
            if auth.isAuthenticated {
                HomeView(home: home, auth: auth)
            } else {
                LoginView(auth: auth)
            }
        }
        .background {
            AppPageBackground()
        }
        .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
            if !isAuthenticated {
                home.reset()
            }
        }
        .task {
            await auth.restoreSession()
        }
    }
}
