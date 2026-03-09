import SwiftUI

struct KeyBadge: View {
    let key: String

    var body: some View {
        Text(key)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundColor(.appSurface)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.appPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
