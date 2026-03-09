import SwiftUI
import PhotosUI

struct BandSettingsView: View {
    @EnvironmentObject var bandVM: BandViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var church: String = ""
    @State private var selectedEmoji: String = "🎸"
    @State private var selectedColor: String = "#1C1C1E"
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImage: UIImage?
    @State private var showDeleteAlert = false
    @State private var isSaving = false

    private let emojis = ["🎸", "🥁", "🎹", "🎺", "🎻", "🎤", "🎵", "🎼"]
    private let colors = ["#1C1C1E", "#3D8B5C", "#C9A84C", "#B05040", "#4A6FA5", "#7B5EA7"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Band Image
                bandImageSection

                // Emoji picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("band_icon".localized)
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(emojis, id: \.self) { emoji in
                                Button {
                                    selectedEmoji = emoji
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 32))
                                        .padding(8)
                                        .background(
                                            selectedEmoji == emoji
                                                ? Color.appAccent.opacity(0.2)
                                                : Color.clear
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                }

                // Color picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("band_color".localized)
                        .font(.appCaption)
                        .foregroundColor(.appSecondary)

                    HStack(spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.appAccent, lineWidth: selectedColor == color ? 3 : 0)
                                            .padding(-3)
                                    )
                            }
                        }
                    }
                }

                // Text fields
                VStack(spacing: 16) {
                    TextField("band_name".localized, text: $name)
                        .appTextField()

                    TextField("church_org".localized, text: $church)
                        .appTextField()
                }

                // Save button
                LoadingButton(
                    title: "save_changes".localized,
                    isLoading: isSaving
                ) {
                    Task { await saveChanges() }
                }
                .disabled(name.isEmpty)

                // Invite Code Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("invite_code".localized)
                        .font(.appHeadline)
                        .foregroundColor(.appPrimary)

                    HStack {
                        Text(bandVM.currentBand?.inviteCode ?? "")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(.appPrimary)

                        Spacer()

                        Button {
                            UIPasteboard.general.string = bandVM.currentBand?.inviteCode
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.appAccent)
                        }
                    }
                    .padding(16)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appDivider, lineWidth: 1))

                    Button {
                        Task { await bandVM.regenerateCode() }
                    } label: {
                        Text("regenerate_code".localized)
                            .font(.appBody)
                            .foregroundColor(.appAccent)
                    }
                }

                // Delete band
                if bandVM.currentBand?.isLeader == true {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Text("delete_band".localized)
                            .font(.appBody)
                            .foregroundColor(.statusNo)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.statusNo.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 8)
                }
            }
            .padding(24)
        }
        .background(Color.appBackground)
        .navigationTitle("band_settings".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadCurrentValues() }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                    selectedImage = UIImage(data: data)
                }
            }
        }
        .alert("delete_band_confirm".localized, isPresented: $showDeleteAlert) {
            Button("delete".localized, role: .destructive) {
                Task {
                    try? await BandService.deleteBand(id: bandVM.currentBand!.id)
                    bandVM.currentBand = nil
                    await bandVM.loadMyBands()
                    dismiss()
                }
            }
            Button("cancel".localized, role: .cancel) {}
        } message: {
            Text("delete_band_warning".localized)
        }
    }

    private var bandImageSection: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.appDivider, lineWidth: 2))
                } else if let urlStr = bandVM.currentBand?.avatarUrl,
                          let url = URL(string: urlStr) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.appDivider, lineWidth: 2))
                    } placeholder: {
                        bandEmojiAvatar
                    }
                } else {
                    bandEmojiAvatar
                }
            }

            Text("change_photo".localized)
                .font(.appCaption)
                .foregroundColor(.appAccent)
        }
    }

    private var bandEmojiAvatar: some View {
        ZStack {
            Circle()
                .fill(Color(hex: selectedColor).opacity(0.15))
                .frame(width: 100, height: 100)
            Text(selectedEmoji)
                .font(.system(size: 40))
            Image(systemName: "camera.fill")
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(6)
                .background(Color.appAccent)
                .clipShape(Circle())
                .offset(x: 35, y: 35)
        }
    }

    private func loadCurrentValues() {
        guard let band = bandVM.currentBand else { return }
        name = band.name
        church = band.church ?? ""
        selectedEmoji = band.avatarEmoji
        selectedColor = band.avatarColor
    }

    private func saveChanges() async {
        guard let bandId = bandVM.currentBand?.id else { return }
        isSaving = true

        // Upload image if changed
        if let imageData = selectedImageData {
            _ = try? await BandService.uploadAvatar(bandId: bandId, imageData: imageData)
        }

        // Update band info
        let _ = try? await BandService.updateBand(
            id: bandId,
            name: name.isEmpty ? nil : name,
            church: church,
            emoji: selectedEmoji,
            color: selectedColor
        )

        await bandVM.refreshCurrentBand()
        isSaving = false
    }
}
