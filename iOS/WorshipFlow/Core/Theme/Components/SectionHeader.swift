import SwiftUI

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center) {
            Text(title.uppercased())
                .font(.appSmall)
                .foregroundColor(.appSecondary)
                .tracking(1.4)
                .fontWeight(.semibold)

            Spacer()

            if let trailing, let action {
                Button(action: action) {
                    HStack(spacing: 3) {
                        Text(trailing)
                            .font(.appSmall)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.appAccent)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 10)
    }
}
