import SwiftUI

// MARK: - RSVP Button

struct RSVPButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    @State private var bounced = false

    var body: some View {
        Button {
            AppHaptics.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                bounced = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                bounced = false
            }
            action()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.appSmall)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.10))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : color.opacity(0.25), lineWidth: 1)
            )
        }
        .scaleEffect(bounced ? 1.08 : (isSelected ? 1.03 : 1.0))
        .shadow(color: isSelected ? color.opacity(0.28) : .clear, radius: 6, x: 0, y: 3)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}
