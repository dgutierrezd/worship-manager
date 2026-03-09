import SwiftUI

extension String {
    var localized: String {
        LanguageManager.shared.localizedString(self)
    }
}
