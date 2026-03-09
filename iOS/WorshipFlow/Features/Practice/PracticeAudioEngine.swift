import AVFoundation
import Foundation

/// Generates metronome clicks and key pad drones using AVAudioEngine.
/// Fully on-device — no audio files needed.
class PracticeAudioEngine {
    private let engine = AVAudioEngine()
    private let clickPlayer = AVAudioPlayerNode()
    private let padPlayer = AVAudioPlayerNode()
    private let clickMixer = AVAudioMixerNode()
    private let padMixer = AVAudioMixerNode()

    private var clickBuffer: AVAudioPCMBuffer?
    private var accentBuffer: AVAudioPCMBuffer?

    private var clickTimer: DispatchSourceTimer?
    private var beatCount = 0
    private var beatsPerMeasure = 4

    private(set) var isRunning = false
    private var engineStarted = false

    var onBeat: ((Int) -> Void)?

    init() {
        setupEngine()
    }

    // MARK: - Engine Setup

    private func setupEngine() {
        engine.attach(clickPlayer)
        engine.attach(padPlayer)
        engine.attach(clickMixer)
        engine.attach(padMixer)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

        engine.connect(clickPlayer, to: clickMixer, format: format)
        engine.connect(clickMixer, to: engine.mainMixerNode, format: format)
        engine.connect(padPlayer, to: padMixer, format: format)
        engine.connect(padMixer, to: engine.mainMixerNode, format: format)

        clickMixer.outputVolume = 0.8
        padMixer.outputVolume = 0.3
    }

    // MARK: - Sound Generation

    private func generateClickBuffer(frequency: Double, duration: Double = 0.02, amplitude: Float = 0.7) -> AVAudioPCMBuffer? {
        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }

        buffer.frameLength = frameCount
        guard let floatData = buffer.floatChannelData?[0] else { return nil }

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = Float(1.0 - t / duration)
            floatData[i] = amplitude * envelope * sin(Float(2.0 * .pi * frequency * t))
        }

        return buffer
    }

    /// Creates a seamless pad drone buffer (no fade — designed for .loops playback)
    private func generatePadBuffer(rootFrequency: Double) -> AVAudioPCMBuffer? {
        let sampleRate: Double = 44100
        // Use a duration that creates a clean loop point (full wave cycles)
        // Calculate frames for exact whole cycles of the root frequency
        let cyclesPerBuffer: Double = 100
        let framesPerCycle = sampleRate / rootFrequency
        let frameCount = AVAudioFrameCount(framesPerCycle * cyclesPerBuffer)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }

        buffer.frameLength = frameCount
        guard let floatData = buffer.floatChannelData?[0] else { return nil }

        let fifth = rootFrequency * 1.4983
        let octave = rootFrequency * 2.0
        let amplitude: Float = 0.15

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let sample = sin(Float(2.0 * .pi * rootFrequency * t))
                       + 0.6 * sin(Float(2.0 * .pi * fifth * t))
                       + 0.4 * sin(Float(2.0 * .pi * octave * t))
            floatData[i] = amplitude * sample
        }

        return buffer
    }

    // MARK: - Key to Frequency

    static func frequency(forKey key: String) -> Double {
        let noteFrequencies: [String: Double] = [
            "C": 130.81, "C#": 138.59, "Db": 138.59,
            "D": 146.83, "D#": 155.56, "Eb": 155.56,
            "E": 164.81, "Fb": 164.81,
            "F": 174.61, "F#": 185.00, "Gb": 185.00,
            "G": 196.00, "G#": 207.65, "Ab": 207.65,
            "A": 220.00, "A#": 233.08, "Bb": 233.08,
            "B": 246.94, "Cb": 246.94,
        ]

        let cleaned = key
            .replacingOccurrences(of: "m", with: "")
            .replacingOccurrences(of: "min", with: "")
            .trimmingCharacters(in: .whitespaces)

        return noteFrequencies[cleaned] ?? 196.00
    }

    // MARK: - Time Signature

    static func beatsPerMeasure(forTimeSignature ts: String) -> Int {
        // Parse "4/4" -> 4, "6/8" -> 6, "3/4" -> 3, etc.
        let parts = ts.split(separator: "/")
        guard let numerator = parts.first, let beats = Int(numerator) else { return 4 }
        return beats
    }

    // MARK: - Playback Control

    func start(bpm: Int, key: String?, timeSignature: String = "4/4") {
        stop()

        self.beatsPerMeasure = PracticeAudioEngine.beatsPerMeasure(forTimeSignature: timeSignature)
        beatCount = 0

        // Generate click buffers
        clickBuffer = generateClickBuffer(frequency: 1000, duration: 0.015, amplitude: 0.8)
        accentBuffer = generateClickBuffer(frequency: 1500, duration: 0.02, amplitude: 1.0)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)

            if !engine.isRunning {
                try engine.start()
            }
            engineStarted = true

            // Start pad — loops forever, no gaps
            if let key, !key.isEmpty {
                let freq = PracticeAudioEngine.frequency(forKey: key)
                if let padBuffer = generatePadBuffer(rootFrequency: freq) {
                    padPlayer.play()
                    padPlayer.scheduleBuffer(padBuffer, at: nil, options: .loops, completionHandler: nil)
                }
            }

            // Start metronome
            clickPlayer.play()
            startClickTimer(bpm: bpm)

            isRunning = true
        } catch {
            print("PracticeAudioEngine start error: \(error)")
        }
    }

    func stop() {
        isRunning = false

        clickTimer?.cancel()
        clickTimer = nil

        if engineStarted {
            clickPlayer.stop()
            padPlayer.stop()
            engine.stop()
            engineStarted = false
        }

        beatCount = 0
    }

    // MARK: - Volume (safe to call while playing — no restart needed)

    func setPadVolume(_ volume: Float) {
        padMixer.outputVolume = volume
    }

    func setClickVolume(_ volume: Float) {
        clickMixer.outputVolume = volume
    }

    // MARK: - Metronome Timer

    private func startClickTimer(bpm: Int) {
        let interval = 60.0 / Double(bpm)

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInteractive))
        timer.schedule(deadline: .now(), repeating: interval)

        timer.setEventHandler { [weak self] in
            guard let self, self.isRunning else { return }
            let isAccent = self.beatCount % self.beatsPerMeasure == 0
            let buffer = isAccent ? self.accentBuffer : self.clickBuffer
            if let buffer {
                self.clickPlayer.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            }
            let currentBeat = (self.beatCount % self.beatsPerMeasure) + 1
            self.onBeat?(currentBeat)
            self.beatCount += 1
        }

        timer.resume()
        clickTimer = timer
    }

    deinit {
        stop()
    }
}
