import SwiftUI
import UIKit

// MARK: - App Palette (Modern Deep-Blue)
//
// A refined, premium palette built around a deep navy `appPrimary` and
// a vibrant electric-blue `appAccent`. Inspired by modern product apps
// (Linear, Notion, Revolut, Rise). All tokens are light/dark adaptive.

extension Color {
    /// Cool off-white in light mode, deep midnight in dark mode.
    static let appBackground = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 1)   // #0A0C17
            : UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1)   // #F5F7FB
    })

    /// Raised card / surface color.
    static let appSurface = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.10, blue: 0.16, alpha: 1)   // #141929
            : UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1)   // #FFFFFF
    })

    /// Primary text — deep navy-near-black in light, near-white in dark.
    static let appPrimary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.94, green: 0.95, blue: 0.98, alpha: 1)   // #F0F2FA
            : UIColor(red: 0.04, green: 0.08, blue: 0.20, alpha: 1)   // #0B1533
    })

    /// Secondary text — slate gray.
    static let appSecondary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.60, green: 0.65, blue: 0.75, alpha: 1)   // #9AA5BF
            : UIColor(red: 0.39, green: 0.45, blue: 0.55, alpha: 1)   // #64748B
    })

    /// Hairline divider — cool neutral.
    static let appDivider = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.16, green: 0.19, blue: 0.26, alpha: 1)   // #283042
            : UIColor(red: 0.89, green: 0.91, blue: 0.95, alpha: 1)   // #E4E8F1
    })

    // MARK: Brand colors

    /// Vibrant electric blue — primary brand accent (CTAs, highlights).
    static let appAccent     = Color(hex: "#3B5BFF")
    /// Deep navy — used for gradient ends and emphasized surfaces.
    static let appAccentDeep = Color(hex: "#1B2E6B")
    /// Very subtle translucent brand tint for chips/backgrounds.
    static let appAccentSoft = Color(hex: "#3B5BFF").opacity(0.12)

    /// Soft navy-tinted shadow for modern depth.
    static let appShadow = Color(hex: "#0B1533").opacity(0.08)

    // MARK: Status colors (emerald / amber / coral-red)

    static let statusGoing = Color(hex: "#10B981")
    static let statusMaybe = Color(hex: "#F59E0B")
    static let statusNo    = Color(hex: "#EF4444")

    // MARK: Music key pill

    static let keyMajor = Color(hex: "#0B1533")
    static let keyMinor = Color(hex: "#64748B")

    // MARK: Feature accent palette (Quick Access cards)

    static let featureServices = Color(hex: "#3B5BFF")  // brand blue
    static let featureSongs    = Color(hex: "#8B5CF6")  // violet
    static let featureSchedule = Color(hex: "#10B981")  // emerald
    static let featureTeam     = Color(hex: "#F59E0B")  // amber

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
//
// NOTE: The `gold` and `hero` names are kept for binary/source compatibility
// with existing call sites across the app. Their visual identity has been
// re-mapped to the new electric-blue brand palette.

struct AppGradients {
    /// Brand gradient — electric blue → deep navy.
    /// (Historically named `gold`; kept for source compatibility.)
    static let gold = LinearGradient(
        colors: [Color(hex: "#4F74FF"), Color(hex: "#1B2E6B")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    /// Alias for new callers — same as `.gold`.
    static let brand = gold

    /// Soft blue aurora used behind hero / header sections.
    static let hero = LinearGradient(
        colors: [
            Color(hex: "#3B5BFF").opacity(0.22),
            Color(hex: "#8B5CF6").opacity(0.14),
            Color.appBackground.opacity(0)
        ],
        startPoint: .top, endPoint: .bottom
    )

    /// Surface lift for layered / elevated cards.
    static let surfaceLift = LinearGradient(
        colors: [Color.appSurface, Color.appSurface.opacity(0.94)],
        startPoint: .top, endPoint: .bottom
    )

    /// Subtle radial glow for hero avatars / accent focal points.
    static let brandGlow = RadialGradient(
        colors: [Color.appAccent.opacity(0.25), Color.appAccent.opacity(0)],
        center: .center, startRadius: 4, endRadius: 120
    )
}

// MARK: - Typography

extension Font {
    /// Large screen titles — rounded geometric for a friendly modern feel.
    static let appLargeTitle = Font.system(size: 32, weight: .bold,     design: .rounded)
    /// Section / navigation titles.
    static let appTitle      = Font.system(size: 22, weight: .bold,     design: .rounded)
    /// Subtitles and prominent labels.
    static let appSubtitle   = Font.system(size: 16, weight: .semibold)
    /// Row titles, prominent list items.
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
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.appShadow, radius: 14, x: 0, y: 6)
            .shadow(color: Color.appShadow.opacity(0.5), radius: 2, x: 0, y: 1)
    }
}

struct ElevatedCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.appShadow.opacity(1.6), radius: 22, x: 0, y: 10)
            .shadow(color: Color.appShadow, radius: 4, x: 0, y: 2)
    }
}

/// Featured card with a subtle brand accent border + tinted glow.
struct FeaturedCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.appAccent.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: Color.appAccent.opacity(0.14), radius: 14, x: 0, y: 6)
            .shadow(color: Color.appShadow, radius: 4, x: 0, y: 1)
    }
}

// MARK: - Button Styles

/// Solid deep-navy primary CTA — confident, modern.
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
                        Color.appAccent
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: (isDestructive ? Color.statusNo : Color.appAccent).opacity(0.35),
                    radius: 12, x: 0, y: 6)
    }
}

/// Gradient hero CTA (brand blue → deep navy).
struct AccentButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appSubtitle)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppGradients.brand)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.appAccent.opacity(0.40), radius: 14, x: 0, y: 8)
    }
}

/// Neutral secondary button — white with hairline border.
struct SecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appSubtitle)
            .foregroundColor(.appPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.appDivider, lineWidth: 1.2)
            )
    }
}

struct AppTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appBody)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.appDivider, lineWidth: 1.2)
            )
    }
}

// MARK: - Interactive Press Effect

struct PressableModifier: ViewModifier {
    @GestureState private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isPressed)
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
    static func light()     { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium()    { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func success()   { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}
