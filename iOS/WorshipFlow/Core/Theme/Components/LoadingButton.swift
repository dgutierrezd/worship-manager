import SwiftUI

// MARK: - Loading Button

/// Primary action button with built-in loading state and press-scale feedback.
/// Pass `style: .accent` for the gold gradient variant.
struct LoadingButton: View {
    enum ButtonStyle {
        case primary, accent, secondary
    }

    let title: String
    let isLoading: Bool
    var style: ButtonStyle = .primary
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            AppHaptics.medium()
            action()
        } label: {
            Group {
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.85)
                        Text(title)
                            .opacity(0.7)
                    }
                } else {
                    Text(title)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .font(.appSubtitle)
            .foregroundColor(style == .secondary ? .appPrimary : .white)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .opacity(isLoading ? 0.85 : 1)
    }

    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
        case .primary:   Color.appPrimary
        case .accent:    AppGradients.gold
        case .secondary: Color.appSurface
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.appDivider, lineWidth: 1.5))
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary:   Color.appPrimary.opacity(0.22)
        case .accent:    Color.appAccent.opacity(0.35)
        case .secondary: .clear
        }
    }
}
