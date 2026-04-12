import SwiftUI

/// Sheet for adding or editing a stem. Three fields: kind, label, URL.
/// Zero file upload — the audio lives in the user's own cloud.
struct AddStemSheet: View {
    @Environment(\.dismiss) private var dismiss

    let existing: SongStem?
    let onSave: (_ kind: String, _ label: String, _ url: String) async -> Bool

    @State private var kind: String = "drums"
    @State private var label: String = ""
    @State private var urlText: String = ""
    @State private var isSaving = false
    @State private var showHelp = false

    init(
        existing: SongStem? = nil,
        onSave: @escaping (_ kind: String, _ label: String, _ url: String) async -> Bool
    ) {
        self.existing = existing
        self.onSave = onSave
        _kind = State(initialValue: existing?.kind ?? "drums")
        _label = State(initialValue: existing?.label ?? "")
        _urlText = State(initialValue: existing?.url ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Track") {
                    Picker("Instrument", selection: $kind) {
                        ForEach(SongStem.kinds, id: \.self) { k in
                            Label(SongStem.displayName(forKind: k),
                                  systemImage: SongStem.icon(forKind: k))
                                .tag(k)
                        }
                    }

                    TextField("Label (e.g. Electric Gtr L)", text: $label)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    HStack(spacing: 8) {
                        TextField("https://...", text: $urlText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .font(.appMono)

                        Button {
                            if let clip = UIPasteboard.general.string {
                                urlText = clip
                            }
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                                .foregroundColor(.appAccent)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Streaming URL")
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Paste a direct audio link. Dropbox, Google Drive, OneDrive and any direct web link are supported.")
                        Button {
                            showHelp = true
                        } label: {
                            Label("How to get a direct link", systemImage: "questionmark.circle")
                                .font(.appCaption)
                                .foregroundColor(.appAccent)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(existing == nil ? "Add Track" : "Edit Track")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save").fontWeight(.semibold)
                        }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .sheet(isPresented: $showHelp) {
                StreamingURLHelpSheet()
            }
        }
    }

    private var canSave: Bool {
        !label.trimmingCharacters(in: .whitespaces).isEmpty &&
        !urlText.trimmingCharacters(in: .whitespaces).isEmpty &&
        URL(string: urlText.trimmingCharacters(in: .whitespaces)) != nil
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let ok = await onSave(
            kind,
            label.trimmingCharacters(in: .whitespaces),
            urlText.trimmingCharacters(in: .whitespaces)
        )
        if ok { dismiss() }
    }
}

// MARK: - Help Sheet

private struct StreamingURLHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How to get a direct streaming link")
                        .font(.appTitle)
                        .foregroundColor(.appPrimary)

                    Text("Worship Manager doesn't host your audio. Upload your stems to any cloud you already use, then paste a direct link here.")
                        .font(.appBody)
                        .foregroundColor(.appSecondary)

                    helpBlock(
                        icon: "icloud.fill",
                        title: "Dropbox",
                        steps: [
                            "Right-click the file → Copy link",
                            "Paste here — we'll automatically convert ?dl=0 to ?raw=1 so it streams directly.",
                        ]
                    )

                    helpBlock(
                        icon: "doc.circle.fill",
                        title: "Google Drive",
                        steps: [
                            "Share the file: Anyone with the link",
                            "Copy the file ID from the share URL",
                            "Paste this format: https://drive.google.com/uc?export=download&id=FILE_ID",
                        ]
                    )

                    helpBlock(
                        icon: "icloud.circle.fill",
                        title: "OneDrive",
                        steps: [
                            "Right-click → Share → Copy link",
                            "Paste here — we append ?download=1 automatically.",
                        ]
                    )

                    helpBlock(
                        icon: "globe",
                        title: "Any direct web host",
                        steps: [
                            "Cloudinary, Bunny CDN, S3, your own server…",
                            "If the URL ends in .mp3, .m4a, .wav or .aac, just paste it.",
                        ]
                    )

                    Text("Note: iCloud public links return a webpage, not the file, so they don't work. Use Dropbox or Drive instead.")
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                        .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Streaming Links")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func helpBlock(icon: String, title: String, steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.appHeadline)
                .foregroundColor(.appPrimary)
            ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(idx + 1).")
                        .font(.appCaption)
                        .foregroundColor(.appAccent)
                    Text(step)
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)
                }
            }
        }
        .padding(14)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
