import SwiftUI

// MARK: - Shimmer Modifier
// Apply .shimmer() to any shape/view to get the animated loading effect.

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .clear,                      location: 0),
                            .init(color: .white.opacity(0.28),        location: 0.4),
                            .init(color: .white.opacity(0.18),        location: 0.5),
                            .init(color: .clear,                      location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2.5)
                    .offset(x: phase * geo.size.width * 2.5)
                    .onAppear {
                        withAnimation(
                            .linear(duration: 1.4)
                            .repeatForever(autoreverses: false)
                        ) {
                            phase = 1
                        }
                    }
                }
                .clipped()
            )
            .allowsHitTesting(false)
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Base Skeleton Block

struct SkeletonBlock: View {
    var width: CGFloat? = nil
    var height: CGFloat = 14
    var cornerRadius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.appDivider)
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - Skeleton Avatar

struct SkeletonAvatar: View {
    var size: CGFloat = 44
    var rounded: Bool = false

    var body: some View {
        Group {
            if rounded {
                Circle()
                    .fill(Color.appDivider)
                    .frame(width: size, height: size)
            } else {
                RoundedRectangle(cornerRadius: size * 0.24)
                    .fill(Color.appDivider)
                    .frame(width: size, height: size)
            }
        }
        .shimmer()
    }
}

// MARK: - Skeleton: Song Row

struct SkeletonSongRow: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonAvatar(size: 44)

            VStack(alignment: .leading, spacing: 8) {
                SkeletonBlock(width: CGFloat.random(in: 120...200), height: 14)
                SkeletonBlock(width: CGFloat.random(in: 70...130), height: 10)
            }

            Spacer()

            SkeletonBlock(width: 36, height: 22, cornerRadius: 8)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Skeleton: Member Row

struct SkeletonMemberRow: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonAvatar(size: 46, rounded: true)

            VStack(alignment: .leading, spacing: 8) {
                SkeletonBlock(width: CGFloat.random(in: 100...180), height: 14)
                SkeletonBlock(width: CGFloat.random(in: 60...120), height: 10)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Skeleton: Service / Setlist Row

struct SkeletonServiceRow: View {
    var body: some View {
        HStack(spacing: 14) {
            // Date block
            VStack(spacing: 4) {
                SkeletonBlock(width: 28, height: 12, cornerRadius: 4)
                SkeletonBlock(width: 20, height: 18, cornerRadius: 4)
                SkeletonBlock(width: 28, height: 10, cornerRadius: 4)
            }
            .frame(width: 44)

            Rectangle()
                .fill(Color.appDivider)
                .frame(width: 1, height: 44)
                .shimmer()

            VStack(alignment: .leading, spacing: 8) {
                SkeletonBlock(width: CGFloat.random(in: 130...200), height: 14)
                HStack(spacing: 6) {
                    SkeletonBlock(width: 60, height: 18, cornerRadius: 9)
                    SkeletonBlock(width: 80, height: 10)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Skeleton: Rehearsal Row

struct SkeletonRehearsalRow: View {
    var body: some View {
        HStack(spacing: 14) {
            SkeletonBlock(width: 4, height: 52, cornerRadius: 2)

            VStack(alignment: .leading, spacing: 8) {
                SkeletonBlock(width: CGFloat.random(in: 120...190), height: 14)
                SkeletonBlock(width: CGFloat.random(in: 80...150), height: 10)
            }

            Spacer()

            SkeletonBlock(width: 50, height: 22, cornerRadius: 11)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Skeleton: Home Dashboard Card

struct SkeletonHomeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SkeletonBlock(width: 140, height: 16)
                Spacer()
                SkeletonBlock(width: 50, height: 12)
            }
            SkeletonBlock(height: 80, cornerRadius: 12)
            HStack(spacing: 8) {
                SkeletonBlock(height: 60, cornerRadius: 10)
                SkeletonBlock(height: 60, cornerRadius: 10)
                SkeletonBlock(height: 60, cornerRadius: 10)
            }
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Skeleton List (generic, for use inside List/ScrollView)

struct SkeletonList<Row: View>: View {
    let count: Int
    @ViewBuilder let row: () -> Row

    init(count: Int = 6, @ViewBuilder row: @escaping () -> Row) {
        self.count = count
        self.row = row
    }

    var body: some View {
        ForEach(0..<count, id: \.self) { _ in
            row()
                // Randomise widths slightly so it looks natural
                .id(UUID())
        }
    }
}
