import SwiftUI

// MARK: - Band Avatar View

struct BandAvatarView: View {
    let band: Band
    var size: CGFloat = 48
    /// When true, renders a gold gradient ring around the avatar
    var showLeaderRing: Bool = false

    var body: some View {
        ZStack {
            if showLeaderRing {
                // Gold gradient outer ring
                Circle()
                    .fill(AppGradients.gold)
                    .frame(width: size + 6, height: size + 6)
                Circle()
                    .fill(Color.appBackground)
                    .frame(width: size + 2, height: size + 2)
            }

            if let urlStr = band.avatarUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    default:
                        emojiAvatar
                    }
                }
            } else {
                emojiAvatar
            }
        }
    }

    private var emojiAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: band.avatarColor).opacity(0.22),
                            Color(hex: band.avatarColor).opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .strokeBorder(Color(hex: band.avatarColor).opacity(0.20), lineWidth: 1.5)
                )
            Text(band.avatarEmoji)
                .font(.system(size: size * 0.45))
        }
    }
}
