import SwiftUI

@main
struct Hackaton_2026_reto_BIMBOApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isLoggedIn {
                    ContentView()
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                } else {
                    LoginView()
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .animation(.spring(response: 0.5), value: appState.isLoggedIn)
            .environmentObject(appState)
        }
    }
}
