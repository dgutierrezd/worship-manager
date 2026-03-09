import SwiftUI

struct BandAvatarView: View {
    let band: Band
    var size: CGFloat = 48

    var body: some View {
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

    private var emojiAvatar: some View {
        ZStack {
            Circle()
                .fill(Color(hex: band.avatarColor).opacity(0.15))
                .frame(width: size, height: size)
            Text(band.avatarEmoji)
                .font(.system(size: size * 0.5))
        }
    }
}
