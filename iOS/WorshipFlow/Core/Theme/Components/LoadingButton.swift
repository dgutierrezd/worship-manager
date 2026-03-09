import SwiftUI

struct LoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.appSurface)
                } else {
                    Text(title)
                }
            }
            .primaryButton()
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.8 : 1)
    }
}
