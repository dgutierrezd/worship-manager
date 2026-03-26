import SwiftUI
import UIKit

// MARK: - Colors (Light/Dark adaptive)

extension Color {
    /// Warm off-white in light mode, deep charcoal in dark mode
    static let appBackground = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1)
            : UIColor(red: 0.97, green: 0.97, blue: 0.96, alpha: 1)
    })

    /// Pure white / raised dark surface
    static let appSurface = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
            : UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    })

    /// Near-black / near-white text
    static let appPrimary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
            : UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1)
    })

    /// Muted secondary text
    static let appSecondary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1)
            : UIColor(red: 0.44, green: 0.44, blue: 0.46, alpha: 1)
    })

    /// Subtle separator / divider
    static let appDivider = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1)
            : UIColor(red: 0.90, green: 0.90, blue: 0.88, alpha: 1)
    })

    /// Gold accent — consistent across modes
    static let appAccent    = Color(hex: "#C9A84C")
    static let appAccentDeep = Color(hex: "#A07830")     // deeper gold for gradients
    static let appAccentSoft = Color(hex: "#C9A84C").opacity(0.12)  // light gold tint

    // Status colors
    static let statusGoing = Color(hex: "#2D7D52")
    static let statusMaybe = Color(hex: "#C9A84C")
    static let statusNo    = Color(hex: "#B04040")

    // Music key colors
    static let keyMajor = Color(hex: "#1C1C1E")
    static let keyMinor = Color(hex: "#6B6B6B")

    // Feature accent palette (for Quick Access cards)
    static let featureServices  = Color(hex: "#C9A84C")                    // gold
    static let featureSongs     = Color(UIColor(red: 0.28, green: 0.52, blue: 0.96, alpha: 1)) // blue
    static let featureSchedule  = Color(UIColor(red: 0.22, green: 0.70, blue: 0.48, alpha: 1)) // green
    static let featureTeam      = Color(UIColor(red: 0.92, green: 0.52, blue: 0.24, alpha: 1)) // orange

    // MARK: - Hex initializer

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
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - App Gradients

struct AppGradients {
    /// Gold shimmer gradient for hero elements and CTA buttons
    static let gold = LinearGradient(
        colors: [Color.appAccent, Color.appAccentDeep],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    /// Soft gold tint used in the dashboard hero header
    static let hero = LinearGradient(
        colors: [
            Color.appAccent.opacity(0.18),
            Color.appAccent.opacity(0.06),
            Color.appBackground.opacity(0)
        ],
        startPoint: .top, endPoint: .bottom
    )

    /// Subtle surface lift for elevated cards
    static let surfaceLift = LinearGradient(
        colors: [Color.appSurface, Color.appSurface.opacity(0.92)],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - Typography

extension Font {
    static let appLargeTitle = Font.system(size: 30, weight: .bold,     design: .rounded)
    static let appTitle      = Font.system(size: 22, weight: .bold,     design: .rounded)
    static let appSubtitle   = Font.system(size: 16, weight: .semibold, design: .default)
    static let appHeadline   = Font.system(size: 15, weight: .semibold)
    static let appBody       = Font.system(size: 15, weight: .regular)
    static let appCaption    = Font.system(size: 13, weight: .regular)
    static let appSmall      = Font.system(size: 12, weight: .medium)
    static let appMono       = Font.system(size: 14, weight: .regular,  design: .monospaced)
}

// MARK: - Card Styles

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

struct ElevatedCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 6)
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
}

/// Featured card with a gold accent left-border stripe
struct FeaturedCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.appAccent.opacity(0.30), lineWidth: 1)
            )
            .shadow(color: Color.appAccent.opacity(0.12), radius: 12, x: 0, y: 4)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ViewModifier {
    var isDestructive: Bool = false
    func body(content: Content) -> some View {
        content
            .font(.appSubtitle)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if isDestructive {
                        Color.statusNo
                    } else {
                        Color.appPrimary
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: (isDestructive ? Color.statusNo : Color.appPrimary).opacity(0.25),
                    radius: 8, x: 0, y: 4)
    }
}

struct AccentButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appSubtitle)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppGradients.gold)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.appAccent.opacity(0.35), radius: 10, x: 0, y: 4)
    }
}

struct SecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appSubtitle)
            .foregroundColor(.appPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appDivider, lineWidth: 1.5)
            )
    }
}

struct AppTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appBody)
            .padding(16)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.appDivider, lineWidth: 1.5)
            )
    }
}

// MARK: - Interactive Press Effect

struct PressableModifier: ViewModifier {
    @GestureState private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in state = true }
            )
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle()          -> some View { modifier(CardStyle()) }
    func elevatedCardStyle()  -> some View { modifier(ElevatedCardStyle()) }
    func featuredCardStyle()  -> some View { modifier(FeaturedCardStyle()) }
    func primaryButton()      -> some View { modifier(PrimaryButtonStyle()) }
    func destructiveButton()  -> some View { modifier(PrimaryButtonStyle(isDestructive: true)) }
    func accentButton()       -> some View { modifier(AccentButtonStyle()) }
    func secondaryButton()    -> some View { modifier(SecondaryButtonStyle()) }
    func appTextField()       -> some View { modifier(AppTextFieldStyle()) }
    func pressable()          -> some View { modifier(PressableModifier()) }
}

// MARK: - Haptic Feedback

enum AppHaptics {
    static func light()    { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium()   { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func success()  { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}
