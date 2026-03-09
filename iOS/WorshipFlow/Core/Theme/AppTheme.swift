import SwiftUI

// MARK: - Colors

extension Color {
    // Core palette
    static let appBackground  = Color(hex: "#FAFAF8")
    static let appSurface     = Color(hex: "#FFFFFF")
    static let appPrimary     = Color(hex: "#1C1C1E")
    static let appSecondary   = Color(hex: "#6B6B6B")
    static let appAccent      = Color(hex: "#C9A84C")
    static let appDivider     = Color(hex: "#E8E8E4")

    // Status colors
    static let statusGoing    = Color(hex: "#3D8B5C")
    static let statusMaybe    = Color(hex: "#C9A84C")
    static let statusNo       = Color(hex: "#B05040")

    // Music key colors
    static let keyMajor       = Color(hex: "#1C1C1E")
    static let keyMinor       = Color(hex: "#6B6B6B")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography

extension Font {
    static let appLargeTitle = Font.system(size: 32, weight: .bold, design: .serif)
    static let appTitle      = Font.system(size: 22, weight: .semibold, design: .default)
    static let appHeadline   = Font.system(size: 17, weight: .semibold)
    static let appBody       = Font.system(size: 16, weight: .regular)
    static let appCaption    = Font.system(size: 13, weight: .regular)
    static let appMono       = Font.system(size: 14, weight: .regular, design: .monospaced)
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appHeadline)
            .foregroundColor(.appSurface)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.appPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct SecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appHeadline)
            .foregroundColor(.appPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.appDivider, lineWidth: 1)
            )
    }
}

struct AppTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appBody)
            .padding(16)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appDivider, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
    func primaryButton() -> some View { modifier(PrimaryButtonStyle()) }
    func secondaryButton() -> some View { modifier(SecondaryButtonStyle()) }
    func appTextField() -> some View { modifier(AppTextFieldStyle()) }
}
