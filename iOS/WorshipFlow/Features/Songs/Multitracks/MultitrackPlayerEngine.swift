import AVFoundation
import Foundation
import SwiftUI

/// Plays multiple stems in sample-accurate sync with per-stem mute / solo / volume.
///
/// ## Strategy
/// Each `SongStem` URL is downloaded once into `caches/multitracks/<songId>/`
/// (small AAC/MP3 files — ~2–5 MB each). After all stems are downloaded, one
/// `AVAudioPlayerNode` + `AVAudioMixerNode` is attached per stem and all player
/// nodes are scheduled to play from the same render timestamp, giving sample-
/// accurate sync. Mute/solo just toggles each mixer's `outputVolume` on the
/// main thread — instant, no audible clicks.
///
/// Downloaded files live in `cachesDirectory` so iOS evicts them automatically
/// under storage pressure. Re-opening the same song reuses the cached files.
@MainActor
final class MultitrackPlayerEngine: ObservableObject {

    // MARK: - Published state

    @Published private(set) var isLoading = false
    @Published private(set) var loadingProgress: Double = 0
    @Published private(set) var loadError: String?

    @Published private(set) var isPlaying = false
    @Published private(set) var duration: TimeInterval = 0
    @Published var currentTime: TimeInterval = 0

    /// Currently loaded stems, in the same order passed to `load(stems:)`.
    @Published private(set) var stems: [SongStem] = []

    /// Per-stem state
    @Published private(set) var muted: Set<String> = []
    @Published private(set) var soloed: Set<String> = []
    @Published private var volumes: [String: Float] = [:]

    // MARK: - Private audio graph

    private let engine = AVAudioEngine()

    private struct Track {
        let stem: SongStem
        let file: AVAudioFile
        let player: AVAudioPlayerNode
        let mixer: AVAudioMixerNode
        let duration: TimeInterval
    }
    private var tracks: [String: Track] = [:]
    private var trackOrder: [String] = []

    private var engineConfigured = false
    private var playbackStartHostTime: UInt64 = 0
    private var playbackStartOffset: TimeInterval = 0
    private var clockTimer: Timer?

    // MARK: - Lifecycle

    deinit {
        // Nonisolated deinit — tear down audio nodes without touching main-actor state.
        clockTimer?.invalidate()
        engine.stop()
    }

    // MARK: - Loading

    /// Downloads (or reuses cached) stem files and preps the audio graph.
    /// Safe to call multiple times with different stem arrays; any previous
    /// graph is torn down first.
    func load(songId: String, stems: [SongStem]) async {
        await teardown()

        self.stems = stems
        self.loadError = nil
        self.loadingProgress = 0
        self.isLoading = !stems.isEmpty
        self.duration = 0
        self.currentTime = 0

        guard !stems.isEmpty else {
            self.isLoading = false
            return
        }

        do {
            // 1. Download (or reuse cached) files in parallel
            let total = stems.count
            var downloaded = 0
            var localURLs: [(SongStem, URL)] = []

            try await withThrowingTaskGroup(of: (SongStem, URL).self) { group in
                for stem in stems {
                    group.addTask {
                        let localURL = try await Self.downloadIfNeeded(
                            stem: stem,
                            songId: songId
                        )
                        return (stem, localURL)
                    }
                }
                for try await result in group {
                    localURLs.append(result)
                    downloaded += 1
                    self.loadingProgress = Double(downloaded) / Double(total)
                }
            }

            // Preserve original stem order (not download completion order)
            let ordered = stems.compactMap { s in
                localURLs.first(where: { $0.0.id == s.id })
            }

            // 2. Wire up the audio graph
            try configureSession()
            try buildGraph(from: ordered)

            // 3. Compute max duration (we play until the longest stem ends)
            let maxDuration = tracks.values.map(\.duration).max() ?? 0
            self.duration = maxDuration

            self.isLoading = false
        } catch {
            self.loadError = error.localizedDescription
            self.isLoading = false
        }
    }

    /// Downloads a stem's URL to `caches/multitracks/<songId>/<stemId>.<ext>`
    /// if not already cached. Returns the local file URL.
    private static func downloadIfNeeded(stem: SongStem, songId: String) async throws -> URL {
        let dir = try cacheDirectory(forSongId: songId)
        let ext = fileExtension(for: stem.url)
        let localURL = dir.appendingPathComponent("\(stem.id).\(ext)")

        if FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }

        guard let remoteURL = URL(string: stem.url) else {
            throw NSError(
                domain: "MultitrackPlayerEngine",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid stem URL: \(stem.url)"]
            )
        }

        let (tempURL, response) = try await URLSession.shared.download(from: remoteURL)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            try? FileManager.default.removeItem(at: tempURL)
            throw NSError(
                domain: "MultitrackPlayerEngine",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Download failed (\(http.statusCode)) for \(stem.label)"]
            )
        }

        // Move from temp into the cache
        if FileManager.default.fileExists(atPath: localURL.path) {
            try FileManager.default.removeItem(at: localURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: localURL)
        return localURL
    }

    private static func cacheDirectory(forSongId songId: String) throws -> URL {
        let caches = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = caches
            .appendingPathComponent("multitracks", isDirectory: true)
            .appendingPathComponent(songId, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private static func fileExtension(for urlString: String) -> String {
        // Strip query string, look at the path extension
        if let url = URL(string: urlString) {
            let ext = url.pathExtension.lowercased()
            if !ext.isEmpty, ext.count <= 5 { return ext }
        }
        return "m4a"
    }

    // MARK: - Audio graph

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
    }

    private func buildGraph(from ordered: [(SongStem, URL)]) throws {
        // Detach any old nodes so calling build() twice works
        for node in engine.attachedNodes where node !== engine.mainMixerNode && node !== engine.outputNode {
            engine.detach(node)
        }
        tracks.removeAll()
        trackOrder.removeAll()

        // Use the hardware-preferred format for each file (AVAudioPlayerNode
        // converts on its own when connecting to a compatible mixer).
        for (stem, localURL) in ordered {
            let file = try AVAudioFile(forReading: localURL)
            let player = AVAudioPlayerNode()
            let mixer = AVAudioMixerNode()

            engine.attach(player)
            engine.attach(mixer)
            engine.connect(player, to: mixer, format: file.processingFormat)
            engine.connect(mixer, to: engine.mainMixerNode, format: file.processingFormat)

            let dur = Double(file.length) / file.processingFormat.sampleRate
            let track = Track(
                stem: stem,
                file: file,
                player: player,
                mixer: mixer,
                duration: dur
            )
            tracks[stem.id] = track
            trackOrder.append(stem.id)

            // Initialize volume state
            if volumes[stem.id] == nil { volumes[stem.id] = 1.0 }
        }

        if !engine.isRunning {
            try engine.start()
            engineConfigured = true
        }

        applyMixerVolumes()
    }

    // MARK: - Transport

    func play() {
        guard !tracks.isEmpty else { return }
        if isPlaying { return }

        // Pick a common start time slightly in the future so every node
        // schedules from the exact same render timestamp → sample-accurate sync.
        let sampleRate = tracks.values.first!.file.processingFormat.sampleRate
        let startSample = AVAudioFramePosition(0)
        let framesToSkip = AVAudioFramePosition(playbackStartOffset * sampleRate)
        _ = startSample // silence warning if offset is 0
        _ = framesToSkip

        let now = AVAudioTime(hostTime: mach_absolute_time())
        // Schedule all players 100ms into the future
        let startTime = AVAudioTime(
            hostTime: now.hostTime + AVAudioTime.hostTime(forSeconds: 0.1)
        )

        for id in trackOrder {
            guard let track = tracks[id] else { continue }
            let file = track.file

            // Calculate how many frames to skip for resume/seek
            let skip = AVAudioFramePosition(min(playbackStartOffset, track.duration) * file.processingFormat.sampleRate)
            let remaining = max(0, file.length - skip)

            if remaining <= 0 {
                // This stem has already ended — just leave it silent
                continue
            }

            track.player.stop()
            track.player.scheduleSegment(
                file,
                startingFrame: skip,
                frameCount: AVAudioFrameCount(remaining),
                at: startTime,
                completionCallbackType: .dataPlayedBack,
                completionHandler: nil
            )
            track.player.play(at: startTime)
        }

        playbackStartHostTime = startTime.hostTime
        isPlaying = true
        startClockTimer()
    }

    func pause() {
        guard isPlaying else { return }
        // Capture current time before pausing
        let now = currentTime
        for id in trackOrder {
            tracks[id]?.player.pause()
        }
        stopClockTimer()
        isPlaying = false
        playbackStartOffset = now
        currentTime = now
    }

    func stop() {
        for id in trackOrder {
            tracks[id]?.player.stop()
        }
        stopClockTimer()
        isPlaying = false
        playbackStartOffset = 0
        currentTime = 0
    }

    func seek(to time: TimeInterval) {
        let clamped = max(0, min(time, duration))
        let wasPlaying = isPlaying
        // Stop all players
        for id in trackOrder {
            tracks[id]?.player.stop()
        }
        stopClockTimer()
        isPlaying = false
        playbackStartOffset = clamped
        currentTime = clamped
        if wasPlaying {
            play()
        }
    }

    // MARK: - Mute / Solo / Volume

    func toggleMute(stemId: String) {
        if muted.contains(stemId) {
            muted.remove(stemId)
        } else {
            muted.insert(stemId)
        }
        applyMixerVolumes()
    }

    func toggleSolo(stemId: String) {
        if soloed.contains(stemId) {
            soloed.remove(stemId)
        } else {
            soloed.insert(stemId)
        }
        applyMixerVolumes()
    }

    func setVolume(stemId: String, volume: Float) {
        volumes[stemId] = max(0, min(1, volume))
        applyMixerVolumes()
    }

    func volume(stemId: String) -> Float {
        volumes[stemId] ?? 1.0
    }

    func isMuted(stemId: String) -> Bool { muted.contains(stemId) }
    func isSoloed(stemId: String) -> Bool { soloed.contains(stemId) }

    private func applyMixerVolumes() {
        let hasSolo = !soloed.isEmpty
        for (id, track) in tracks {
            let userVolume = volumes[id] ?? 1.0
            let isMuted = muted.contains(id)
            let isSoloed = soloed.contains(id)

            let effective: Float
            if hasSolo {
                effective = isSoloed ? userVolume : 0
            } else {
                effective = isMuted ? 0 : userVolume
            }
            track.mixer.outputVolume = effective
        }
    }

    // MARK: - Clock

    private func startClockTimer() {
        stopClockTimer()
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickClock()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        clockTimer = timer
    }

    private func stopClockTimer() {
        clockTimer?.invalidate()
        clockTimer = nil
    }

    private func tickClock() {
        // Prefer the player node's lastRenderTime for accuracy
        guard isPlaying, let track = tracks[trackOrder.first ?? ""] else { return }
        if let nodeTime = track.player.lastRenderTime,
           let playerTime = track.player.playerTime(forNodeTime: nodeTime)
        {
            let t = Double(playerTime.sampleTime) / playerTime.sampleRate
            currentTime = min(max(0, playbackStartOffset + t), duration)
            if currentTime >= duration - 0.01 {
                stop()
            }
        }
    }

    // MARK: - Teardown

    func teardown() async {
        stopClockTimer()
        for id in trackOrder {
            tracks[id]?.player.stop()
        }
        if engine.isRunning {
            engine.stop()
        }
        for node in engine.attachedNodes where node !== engine.mainMixerNode && node !== engine.outputNode {
            engine.detach(node)
        }
        tracks.removeAll()
        trackOrder.removeAll()
        isPlaying = false
        currentTime = 0
        playbackStartOffset = 0
        duration = 0
    }

    // MARK: - Cache management

    /// Deletes the cached file for a stem (used when a stem is deleted or its URL changes).
    static func purgeCache(songId: String, stemId: String) {
        guard let dir = try? cacheDirectory(forSongId: songId) else { return }
        let fm = FileManager.default
        if let items = try? fm.contentsOfDirectory(atPath: dir.path) {
            for item in items where item.hasPrefix("\(stemId).") {
                try? fm.removeItem(atPath: (dir as NSURL).appendingPathComponent(item)!.path)
            }
        }
    }
}
