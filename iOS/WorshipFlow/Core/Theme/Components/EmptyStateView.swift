import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 48))

            Text(title)
                .font(.appHeadline)
                .foregroundColor(.appPrimary)

            Text(subtitle)
                .font(.appBody)
                .foregroundColor(.appSecondary)
                .multilineTextAlignment(.center)

            if let buttonTitle, let action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.appHeadline)
                        .foregroundColor(.appAccent)
                }
                .padding(.top, 8)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
