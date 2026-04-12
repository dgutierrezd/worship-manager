import SwiftUI

/// Tracks tab content inside `SongDetailView`. Shows a transport bar and a
/// list of stems with mute/solo/volume per stem.
struct MultitracksView: View {
    @StateObject private var vm: MultitracksViewModel
    @ObservedObject private var engine: MultitrackPlayerEngine

    @State private var showAddSheet = false
    @State private var editingStem: SongStem?
    @State private var stemPendingDelete: SongStem?

    init(songId: String) {
        let viewModel = MultitracksViewModel(songId: songId)
        _vm = StateObject(wrappedValue: viewModel)
        self.engine = viewModel.player
    }

    var body: some View {
        content
            .padding(.vertical, 16)
            .task { await vm.loadStems() }
            .sheet(isPresented: $showAddSheet) {
                AddStemSheet { kind, label, url in
                    await vm.addStem(kind: kind, label: label, url: url)
                }
            }
            .sheet(item: $editingStem) { stem in
                AddStemSheet(existing: stem) { kind, label, url in
                    await vm.updateStem(
                        stem,
                        label: label == stem.label ? nil : label,
                        kind: kind == stem.kind ? nil : kind,
                        url: url == stem.url ? nil : url
                    )
                }
            }
            .alert(
                "Delete Track?",
                isPresented: deleteAlertBinding,
                presenting: stemPendingDelete,
                actions: { stem in
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        Task { await vm.deleteStem(stem) }
                    }
                },
                message: { stem in
                    Text("Remove '\(stem.label)' from this song?")
                }
            )
    }

    // MARK: - Content sections

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 16) {
            if !vm.stems.isEmpty {
                transportBar.padding(.horizontal, 16)
            }
            stemList
            addTrackButton
            errorBanner
        }
    }

    @ViewBuilder
    private var stemList: some View {
        if vm.isLoadingList && vm.stems.isEmpty {
            loadingSkeleton
        } else if vm.stems.isEmpty {
            emptyState.padding(.top, 40)
        } else {
            VStack(spacing: 10) {
                ForEach(vm.stems) { stem in
                    StemRowView(
                        stem: stem,
                        engine: engine,
                        onEdit: { editingStem = stem },
                        onDelete: { stemPendingDelete = stem }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var addTrackButton: some View {
        Button {
            showAddSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Add Track")
            }
            .frame(maxWidth: .infinity)
        }
        .secondaryButton()
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let err = vm.error ?? engine.loadError {
            Text(err)
                .font(.appCaption)
                .foregroundColor(.statusNo)
                .padding(.horizontal, 16)
                .multilineTextAlignment(.center)
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { stemPendingDelete != nil },
            set: { newValue in
                if !newValue { stemPendingDelete = nil }
            }
        )
    }

    // MARK: - Transport bar

    private var transportBar: some View {
        VStack(spacing: 10) {
            if engine.isLoading {
                VStack(spacing: 6) {
                    ProgressView(value: engine.loadingProgress)
                        .tint(.appAccent)
                    Text("Loading tracks…")
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                }
                .padding(.vertical, 4)
            } else {
                // Scrubber
                VStack(spacing: 4) {
                    Slider(
                        value: Binding(
                            get: { engine.currentTime },
                            set: { engine.seek(to: $0) }
                        ),
                        in: 0...max(engine.duration, 0.01)
                    )
                    .tint(.appAccent)
                    .disabled(engine.duration <= 0)

                    HStack {
                        Text(formatTime(engine.currentTime))
                        Spacer()
                        Text(formatTime(engine.duration))
                    }
                    .font(.appMono)
                    .foregroundColor(.appSecondary)
                }

                // Transport buttons
                HStack(spacing: 28) {
                    Button {
                        engine.seek(to: 0)
                    } label: {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 22))
                    }
                    .foregroundColor(.appPrimary)

                    Button {
                        if engine.isPlaying {
                            engine.pause()
                        } else {
                            engine.play()
                        }
                    } label: {
                        Image(systemName: engine.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.appAccent)
                    }

                    Button {
                        engine.stop()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 22))
                    }
                    .foregroundColor(.appPrimary)
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appDivider, lineWidth: 1)
        )
    }

    // MARK: - Empty / loading

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.system(size: 44))
                .foregroundColor(.appAccent.opacity(0.6))
            Text("No tracks yet")
                .font(.appHeadline)
                .foregroundColor(.appPrimary)
            Text("Add a streaming link to any stem so your band can play along.")
                .font(.appCaption)
                .foregroundColor(.appSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var loadingSkeleton: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.appSurface)
                    .frame(height: 80)
                    .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Helpers

    private func formatTime(_ t: TimeInterval) -> String {
        guard t.isFinite, t >= 0 else { return "0:00" }
        let total = Int(t)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
