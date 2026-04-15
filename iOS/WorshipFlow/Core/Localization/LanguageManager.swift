import SwiftUI

@MainActor
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "app_language")
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            loadBundle()
        }
    }

    nonisolated(unsafe) var bundle: Bundle = .main

    /// App default language. Spanish is the primary language for this
    /// product; users can switch to English from Settings → Language.
    private static let defaultLanguage = "es"

    /// Supported locales. Anything outside this list falls back to
    /// `defaultLanguage` so we never load an `.lproj` bundle that
    /// doesn't exist.
    private static let supportedLanguages: Set<String> = ["es", "en"]

    private init() {
        // Honor the user's saved preference if they've explicitly picked one;
        // otherwise default new installs to Spanish regardless of device locale.
        if let saved = UserDefaults.standard.string(forKey: "app_language"),
           Self.supportedLanguages.contains(saved) {
            self.currentLanguage = saved
        } else {
            self.currentLanguage = Self.defaultLanguage
        }
        loadBundle()
    }

    private func loadBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            bundle = langBundle
        } else {
            bundle = .main
        }
    }

    nonisolated func localizedString(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
