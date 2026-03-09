import SwiftUI

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.appCaption)
                .foregroundColor(.appSecondary)
                .tracking(1.2)

            Spacer()

            if let trailing, let action {
                Button(action: action) {
                    Text(trailing)
                        .font(.appCaption)
                        .foregroundColor(.appAccent)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }
}
