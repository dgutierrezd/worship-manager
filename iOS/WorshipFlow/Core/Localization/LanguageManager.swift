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

    private init() {
        let saved = UserDefaults.standard.string(forKey: "app_language")
            ?? Locale.current.language.languageCode?.identifier
            ?? "en"
        self.currentLanguage = saved
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
