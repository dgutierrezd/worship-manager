import SwiftUI

// MARK: - Shared Practice Manager (persists across navigation)

@MainActor
class PracticeManager: ObservableObject {
    static let shared = PracticeManager()

    @Published var isActive = false
    @Published var currentIndex = 0
    @Published var isPlaying = false
    @Published var currentBeat = 0
    @Published var clickVolume: Float = 0.8
    @Published var padVolume: Float = 0.3
    @Published var padEnabled = true
    @Published var clickEnabled = true
    @Published var countingIn = false
    @Published var countInBeat = 0
    @Published var showFullPlayer = false
    @Published var timeSignature: String = "4/4"

    static let timeSignatures = ["4/4", "3/4", "6/8", "2/4", "5/4", "7/8", "12/8"]

    private(set) var songs: [SetlistSong] = []
    let audioEngine = PracticeAudioEngine()

    private var countInTimer: DispatchSourceTimer?

    var beatsPerMeasure: Int {
        PracticeAudioEngine.beatsPerMeasure(forTimeSignature: timeSignature)
    }

    private init() {
        audioEngine.onBeat = { [weak self] beat in
            Task { @MainActor in
                self?.currentBeat = beat
            }
        }
    }

    // MARK: - Session lifecycle

    func startSession(songs: [SetlistSong]) {
        stopSession()
        self.songs = songs
        self.currentIndex = 0
        self.isActive = true
        self.showFullPlayer = true
    }

    func stopSession() {
        pause()
        songs = []
        currentIndex = 0
        isActive = false
        showFullPlayer = false
    }

    // MARK: - Computed

    var currentSong: SetlistSong? {
        guard currentIndex < songs.count else { return nil }
        return songs[currentIndex]
    }

    var currentTitle: String { currentSong?.songs?.title ?? "Unknown" }
    var currentArtist: String? { currentSong?.songs?.artist }
    var currentKey: String? { currentSong?.displayKey }
    var currentBPM: Int { currentSong?.songs?.tempoBpm ?? 120 }
    var totalSongs: Int { songs.count }
    var isSingleSong: Bool { songs.count == 1 }
    var hasNext: Bool { currentIndex < songs.count - 1 }
    var hasPrevious: Bool { currentIndex > 0 }

    // MARK: - Playback

    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            startCountIn()
        }
    }

    func startCountIn() {
        countingIn = true
        countInBeat = 0

        let interval = 60.0 / Double(currentBPM)
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .userInteractive))
        timer.schedule(deadline: .now(), repeating: interval)

        var count = 0
        timer.setEventHandler { [weak self] in
            count += 1
            Task { @MainActor in
                self?.countInBeat = count
            }
            if count >= 4 {
                timer.cancel()
                Task { @MainActor in
                    self?.countingIn = false
                    self?.play()
                }
            }
        }
        timer.resume()
        countInTimer = timer
    }

    func play() {
        audioEngine.setClickVolume(clickEnabled ? clickVolume : 0)
        audioEngine.setPadVolume(padEnabled ? padVolume : 0)
        audioEngine.start(bpm: currentBPM, key: currentKey, timeSignature: timeSignature)
        isPlaying = true
    }

    func pause() {
        countInTimer?.cancel()
        countInTimer = nil
        countingIn = false
        audioEngine.stop()
        isPlaying = false
        currentBeat = 0
    }

    func nextSong() {
        guard hasNext else { return }
        let wasPlaying = isPlaying
        pause()
        currentIndex += 1
        if wasPlaying { startCountIn() }
    }

    func previousSong() {
        guard hasPrevious else { return }
        let wasPlaying = isPlaying
        pause()
        currentIndex -= 1
        if wasPlaying { startCountIn() }
    }

    func goToSong(at index: Int) {
        guard index >= 0 && index < songs.count else { return }
        let wasPlaying = isPlaying
        pause()
        currentIndex = index
        if wasPlaying { startCountIn() }
    }

    func updateClickVolume(_ volume: Float) {
        clickVolume = volume
        audioEngine.setClickVolume(clickEnabled ? volume : 0)
    }

    func updatePadVolume(_ volume: Float) {
        padVolume = volume
        audioEngine.setPadVolume(padEnabled ? volume : 0)
    }

    func togglePad() {
        padEnabled.toggle()
        audioEngine.setPadVolume(padEnabled ? padVolume : 0)
    }

    func toggleClick() {
        clickEnabled.toggle()
        audioEngine.setClickVolume(clickEnabled ? clickVolume : 0)
    }

    func setTimeSignature(_ ts: String) {
        timeSignature = ts
        if isPlaying {
            let wasPlaying = true
            pause()
            if wasPlaying { startCountIn() }
        }
    }
}

// MARK: - Mini Player (floating bar above tab bar)

struct PracticeMiniPlayerView: View {
    @ObservedObject var practice = PracticeManager.shared

    var body: some View {
        if practice.isActive {
            HStack(spacing: 12) {
                // Beat dots
                HStack(spacing: 4) {
                    ForEach(1...practice.beatsPerMeasure, id: \.self) { beat in
                        Circle()
                            .fill(practice.currentBeat == beat ? Color.appAccent : Color.appDivider)
                            .frame(width: practice.currentBeat == beat ? 8 : 6,
                                   height: practice.currentBeat == beat ? 8 : 6)
                            .animation(.easeOut(duration: 0.08), value: practice.currentBeat)
                    }
                }

                // Song info
                VStack(alignment: .leading, spacing: 1) {
                    Text(practice.currentTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if let key = practice.currentKey {
                            Text(key)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        Text("\(practice.currentBPM) BPM")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.appSecondary)
                }

                Spacer()

                // Play/Pause
                Button {
                    practice.togglePlayback()
                } label: {
                    Image(systemName: practice.isPlaying || practice.countingIn ? "pause.fill" : "play.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.appPrimary)
                        .frame(width: 36, height: 36)
                }

                // Stop
                Button {
                    practice.stopSession()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.appSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
            .padding(.horizontal, 8)
            .onTapGesture {
                practice.showFullPlayer = true
            }
        }
    }
}

// MARK: - Full Practice Session View

struct PracticeSessionView: View {
    @ObservedObject var practice = PracticeManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Song list (top) — hidden for single song
                    if !practice.isSingleSong {
                        songListSection
                        Divider()
                    }

                    // Now playing (center)
                    nowPlayingSection

                    // Controls (bottom)
                    controlsSection
                }
            }
            .navigationTitle("practice_session".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        // Minimize — audio keeps playing
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundColor(.appAccent)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        practice.stopSession()
                        dismiss()
                    } label: {
                        Text("practice_stop".localized)
                            .font(.appCaption)
                            .foregroundColor(.statusNo)
                    }
                }
            }
        }
    }

    // MARK: - Song List

    private var songListSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(practice.songs.enumerated()), id: \.element.id) { index, item in
                        Button {
                            practice.goToSong(at: index)
                        } label: {
                            HStack(spacing: 12) {
                                Text("\(item.position)")
                                    .font(.appCaption)
                                    .foregroundColor(index == practice.currentIndex ? .appAccent : .appSecondary)
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.songs?.title ?? "Unknown")
                                        .font(index == practice.currentIndex ? .appHeadline : .appBody)
                                        .foregroundColor(index == practice.currentIndex ? .appPrimary : .appSecondary)

                                    HStack(spacing: 6) {
                                        if let key = item.displayKey {
                                            Text(key)
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 1)
                                                .background(index == practice.currentIndex ? Color.appAccent : Color.appSecondary.opacity(0.5))
                                                .clipShape(Capsule())
                                        }
                                        if let bpm = item.songs?.tempoBpm {
                                            Text("\(bpm) BPM")
                                                .font(.system(size: 11))
                                                .foregroundColor(.appSecondary)
                                        }
                                    }
                                }

                                Spacer()

                                if index == practice.currentIndex && practice.isPlaying {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.appAccent)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(index == practice.currentIndex ? Color.appAccent.opacity(0.08) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .id(index)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 220)
            .onChange(of: practice.currentIndex) { _, newValue in
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    // MARK: - Now Playing

    private var nowPlayingSection: some View {
        VStack(spacing: 16) {
            Spacer()

            if practice.countingIn {
                Text("\(practice.countInBeat)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.appAccent)
                    .transition(.scale)
            } else {
                Text(practice.currentTitle)
                    .font(.appLargeTitle)
                    .foregroundColor(.appPrimary)
                    .multilineTextAlignment(.center)

                if let artist = practice.currentArtist {
                    Text(artist)
                        .font(.appBody)
                        .foregroundColor(.appSecondary)
                }

                HStack(spacing: 20) {
                    if let key = practice.currentKey {
                        VStack(spacing: 4) {
                            Text("key".localized)
                                .font(.appCaption)
                                .foregroundColor(.appSecondary)
                            Text(key)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.appPrimary)
                        }
                    }

                    VStack(spacing: 4) {
                        Text("tempo".localized)
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                        Text("\(practice.currentBPM)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.appPrimary)
                    }

                    VStack(spacing: 4) {
                        Text("time_signature".localized)
                            .font(.appCaption)
                            .foregroundColor(.appSecondary)
                        Text(practice.timeSignature)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.appPrimary)
                    }
                }
                .padding(.top, 8)

                // Time signature picker
                timeSignaturePicker
                    .padding(.top, 8)

                if practice.isPlaying {
                    beatIndicator
                        .padding(.top, 12)
                }
            }

            Spacer()

            if !practice.isSingleSong {
                Text("\(practice.currentIndex + 1) / \(practice.totalSongs)")
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
            }
        }
        .padding(.horizontal, 24)
    }

    private var beatIndicator: some View {
        HStack(spacing: practice.beatsPerMeasure > 5 ? 6 : 12) {
            ForEach(1...practice.beatsPerMeasure, id: \.self) { beat in
                Circle()
                    .fill(practice.currentBeat == beat ? Color.appAccent : Color.appDivider)
                    .frame(width: practice.currentBeat == beat ? 18 : 12,
                           height: practice.currentBeat == beat ? 18 : 12)
                    .animation(.easeOut(duration: 0.1), value: practice.currentBeat)
            }
        }
    }

    private var timeSignaturePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(PracticeManager.timeSignatures, id: \.self) { ts in
                    Button {
                        practice.setTimeSignature(ts)
                    } label: {
                        Text(ts)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(practice.timeSignature == ts ? .white : .appPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(practice.timeSignature == ts ? Color.appPrimary : Color.appSurface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.appDivider, lineWidth: practice.timeSignature == ts ? 0 : 1)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Controls

    private var controlsSection: some View {
        VStack(spacing: 16) {
            // Volume controls
            volumeControls

            // Main transport
            HStack(spacing: 32) {
                // Click toggle
                Button {
                    practice.toggleClick()
                } label: {
                    Image(systemName: practice.clickEnabled ? "metronome.fill" : "metronome")
                        .font(.title3)
                        .foregroundColor(practice.clickEnabled ? .appAccent : .appSecondary)
                }

                // Previous
                if !practice.isSingleSong {
                    Button {
                        practice.previousSong()
                    } label: {
                        Image(systemName: "backward.end.fill")
                            .font(.title2)
                            .foregroundColor(practice.hasPrevious ? .appPrimary : .appDivider)
                    }
                    .disabled(!practice.hasPrevious)
                }

                // Play / Pause
                Button {
                    practice.togglePlayback()
                } label: {
                    Image(systemName: practice.isPlaying || practice.countingIn ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.appPrimary)
                }

                // Next
                if !practice.isSingleSong {
                    Button {
                        practice.nextSong()
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.title2)
                            .foregroundColor(practice.hasNext ? .appPrimary : .appDivider)
                    }
                    .disabled(!practice.hasNext)
                }

                // Pad toggle
                Button {
                    practice.togglePad()
                } label: {
                    Image(systemName: practice.padEnabled ? "waveform" : "waveform.slash")
                        .font(.title3)
                        .foregroundColor(practice.padEnabled ? .appAccent : .appSecondary)
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(Color.appSurface)
    }

    private var volumeControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "metronome")
                    .font(.system(size: 14))
                    .foregroundColor(.appSecondary)
                    .frame(width: 20)

                Text("practice_click".localized)
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
                    .frame(width: 40, alignment: .leading)

                Slider(
                    value: Binding(
                        get: { practice.clickVolume },
                        set: { practice.updateClickVolume($0) }
                    ),
                    in: 0...1
                )
                .tint(.appAccent)
                .disabled(!practice.clickEnabled)
                .opacity(practice.clickEnabled ? 1 : 0.4)
            }

            HStack(spacing: 10) {
                Image(systemName: "waveform")
                    .font(.system(size: 14))
                    .foregroundColor(.appSecondary)
                    .frame(width: 20)

                Text("practice_pad".localized)
                    .font(.appCaption)
                    .foregroundColor(.appSecondary)
                    .frame(width: 40, alignment: .leading)

                Slider(
                    value: Binding(
                        get: { practice.padVolume },
                        set: { practice.updatePadVolume($0) }
                    ),
                    in: 0...1
                )
                .tint(.appAccent)
                .disabled(!practice.padEnabled)
                .opacity(practice.padEnabled ? 1 : 0.4)
            }
        }
        .padding(.horizontal, 24)
    }
}
