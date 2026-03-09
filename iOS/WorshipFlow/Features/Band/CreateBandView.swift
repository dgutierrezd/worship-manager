import SwiftUI
import PhotosUI

struct CreateBandView: View {
    @EnvironmentObject var bandVM: BandViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var church = ""
    @State private var selectedEmoji = "🎸"
    @State private var selectedColor = "#1C1C1E"
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImage: UIImage?

    private let emojis = ["🎸", "🥁", "🎹", "🎺", "🎻", "🎤", "🎵", "🎼"]
    private let colors = ["#1C1C1E", "#3D8B5C", "#C9A84C", "#B05040", "#4A6FA5", "#7B5EA7"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("create_band".localized)
                        .font(.appLargeTitle)
                        .foregroundColor(.appPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Band Image
                VStack(spacing: 12) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.appDivider, lineWidth: 2))
                        } else {
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
                    }

                    if selectedImage != nil {
                        Button("Remove Photo") {
                            selectedImage = nil
                            selectedImageData = nil
                            selectedPhoto = nil
                        }
                        .font(.appCaption)
                        .foregroundColor(.statusNo)
                    }
                }

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

                VStack(spacing: 16) {
                    TextField("band_name".localized, text: $name)
                        .appTextField()

                    TextField("church_org".localized, text: $church)
                        .appTextField()
                }

                LoadingButton(
                    title: "create_band".localized,
                    isLoading: bandVM.isLoading
                ) {
                    Task {
                        let success = await bandVM.createBand(
                            name: name,
                            church: church.isEmpty ? nil : church,
                            emoji: selectedEmoji,
                            color: selectedColor
                        )
                        if success, let imageData = selectedImageData,
                           let bandId = bandVM.currentBand?.id {
                            _ = try? await BandService.uploadAvatar(bandId: bandId, imageData: imageData)
                            await bandVM.refreshCurrentBand()
                        }
                    }
                }
                .disabled(name.isEmpty)
            }
            .padding(24)
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { bandVM.error = nil }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                    selectedImage = UIImage(data: data)
                }
            }
        }
        .alert("Error", isPresented: Binding<Bool>(
            get: { bandVM.error != nil },
            set: { if !$0 { bandVM.error = nil } }
        )) {
            Button("OK") { bandVM.error = nil }
        } message: {
            Text(bandVM.error ?? "")
        }
    }
}
