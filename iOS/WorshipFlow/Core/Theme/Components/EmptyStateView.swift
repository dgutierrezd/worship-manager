import SwiftUI

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                // Icon container
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.10))
                        .frame(width: 80, height: 80)
                    Image(systemName: sfIcon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(AppGradients.gold)
                }

                VStack(spacing: 8) {
                    Text(title)
                        .font(.appTitle)
                        .foregroundColor(.appPrimary)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.appBody)
                        .foregroundColor(.appSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }

                if let buttonTitle, let action {
                    Button(action: {
                        AppHaptics.medium()
                        action()
                    }) {
                        Text(buttonTitle)
                            .accentButton()
                    }
                    .padding(.top, 4)
                    .pressable()
                }
            }
            .padding(40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Map legacy emoji icons → SF Symbols for consistency
    private var sfIcon: String {
        switch icon {
        case "🎵", "🎶": return "music.note"
        case "📅":       return "calendar"
        case "👥":       return "person.3.fill"
        case "🎸":       return "music.quarternote.3"
        case "📋":       return "list.bullet.clipboard"
        case "🔔":       return "bell.fill"
        default:         return "music.note.list"
        }
    }
}
