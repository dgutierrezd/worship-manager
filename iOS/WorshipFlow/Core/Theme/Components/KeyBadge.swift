import SwiftUI

// MARK: - Key Badge

struct KeyBadge: View {
    let key: String

    /// Minor keys get a softer muted style; major keys use the gold accent
    private var isMajor: Bool {
        !key.hasSuffix("m") && !key.lowercased().contains("min")
    }

    var body: some View {
        Text(key)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(isMajor ? .white : .appSecondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Group {
                    if isMajor {
                        AnyView(AppGradients.gold)
                    } else {
                        AnyView(Color.appDivider)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .shadow(color: isMajor ? Color.appAccent.opacity(0.25) : .clear, radius: 3, x: 0, y: 1)
    }
}
