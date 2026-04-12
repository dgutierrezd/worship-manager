import SwiftUI

/// A single stem row: icon, label, mute toggle, solo toggle, and volume slider.
struct StemRowView: View {
    let stem: SongStem
    @ObservedObject var engine: MultitrackPlayerEngine

    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var localVolume: Float = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Kind icon
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: SongStem.icon(forKind: stem.kind))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(stem.label)
                        .font(.appHeadline)
                        .foregroundColor(.appPrimary)
                    Text(SongStem.displayName(forKind: stem.kind))
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                }

                Spacer()

                // Mute button
                Button {
                    engine.toggleMute(stemId: stem.id)
                } label: {
                    Text("M")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .frame(width: 34, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(engine.isMuted(stemId: stem.id)
                                      ? Color.statusNo.opacity(0.25)
                                      : Color.appBackground)
                        )
                        .foregroundColor(engine.isMuted(stemId: stem.id) ? .statusNo : .appPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.appDivider, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                // Solo button
                Button {
                    engine.toggleSolo(stemId: stem.id)
                } label: {
                    Text("S")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .frame(width: 34, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(engine.isSoloed(stemId: stem.id)
                                      ? Color.appAccent.opacity(0.25)
                                      : Color.appBackground)
                        )
                        .foregroundColor(engine.isSoloed(stemId: stem.id) ? .appAccent : .appPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.appDivider, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            // Volume slider
            HStack(spacing: 10) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.appSecondary)

                Slider(value: $localVolume, in: 0...1) { editing in
                    if !editing {
                        engine.setVolume(stemId: stem.id, volume: localVolume)
                    }
                }
                .onChange(of: localVolume) { _, newVal in
                    engine.setVolume(stemId: stem.id, volume: newVal)
                }
                .tint(.appAccent)

                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.appSecondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(engine.isSoloed(stemId: stem.id) ? Color.appAccent : Color.appDivider, lineWidth: 1)
        )
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .onAppear {
            localVolume = engine.volume(stemId: stem.id)
        }
    }
}
