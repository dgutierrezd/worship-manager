import SwiftUI

struct LanguageView: View {
    @ObservedObject private var langManager = LanguageManager.shared

    private let languages = [
        ("en", "English"),
        ("es", "Español")
    ]

    var body: some View {
        List {
            ForEach(languages, id: \.0) { code, name in
                Button {
                    langManager.currentLanguage = code
                } label: {
                    HStack {
                        Text(name)
                            .foregroundColor(.appPrimary)
                        Spacer()
                        if langManager.currentLanguage == code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.appAccent)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle("language".localized)
    }
}
