import SwiftUI

@main
struct WorshipFlowApp: App {
    @StateObject private var authVM = AuthViewModel()
    @ObservedObject private var langManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
                .id(langManager.currentLanguage)
                .preferredColorScheme(.light)
        }
    }
}
