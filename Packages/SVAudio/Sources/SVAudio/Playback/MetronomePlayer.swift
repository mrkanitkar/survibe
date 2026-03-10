import AVFoundation

/// Metronome player using AVAudioPlayerNode with BPM control.
/// Uses sample-accurate AVAudioTime scheduling for precise timing.
@MainActor
public final class MetronomePlayer {
    public static let shared = MetronomePlayer()

    /// Reference to the engine's metronome player node.
    private var playerNode: AVAudioPlayerNode {
        AudioEngineManager.shared.metronomeNode
    }

    /// Beats per minute (default: 60).
    public private(set) var bpm: Double = 60.0

    /// Whether the metronome is currently running.
    public private(set) var isPlaying: Bool = false

    /// Pre-loaded click buffer for efficient scheduling.
    private var clickBuffer: AVAudioPCMBuffer?

    /// Timer for scheduling beats.
    private var timer: DispatchSourceTimer?

    /// Queue for metronome timing.
    private let metronomeQueue = DispatchQueue(label: "com.survibe.metronome", qos: .userInteractive)

    private init() {}

    /// Load a click sound for the metronome. Pre-loads into buffer.
    /// - Parameter url: URL to the click audio file (.wav, .aif)
    public func loadClick(at url: URL) throws {
        let audioFile = try AVAudioFile(forReading: url)
        let frameCount = AVAudioFrameCount(audioFile.length)
        let format = audioFile.processingFormat
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw NSError(
                domain: "MetronomePlayer", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create PCM buffer"]
            )
        }
        try audioFile.read(into: buffer)
        clickBuffer = buffer
    }

    /// Start the metronome at the current BPM.
    public func start() {
        guard !isPlaying else { return }
        isPlaying = true

        // Start the player node once
        playerNode.play()

        let interval = 60.0 / bpm

        timer = DispatchSource.makeTimerSource(queue: metronomeQueue)
        timer?.schedule(deadline: .now(), repeating: interval)
        timer?.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.scheduleClick()
            }
        }
        timer?.resume()
    }

    /// Stop the metronome.
    public func stop() {
        timer?.cancel()
        timer = nil
        playerNode.stop()
        isPlaying = false
    }

    /// Update BPM. Adjusts timing without stopping playback if running.
    public func setBPM(_ newBPM: Double) {
        bpm = newBPM
        if isPlaying {
            // Cancel old timer and create new one with updated interval
            timer?.cancel()
            let interval = 60.0 / bpm
            timer = DispatchSource.makeTimerSource(queue: metronomeQueue)
            timer?.schedule(deadline: .now() + interval, repeating: interval)
            timer?.setEventHandler { [weak self] in
                Task { @MainActor in
                    self?.scheduleClick()
                }
            }
            timer?.resume()
        }
    }

    /// Set the volume of the metronome (0.0 to 1.0).
    public func setVolume(_ volume: Float) {
        AudioEngineManager.shared.setMetronomeVolume(volume)
    }

    /// Schedule a single click sound from the pre-loaded buffer.
    private func scheduleClick() {
        guard let clickBuffer else { return }
        playerNode.scheduleBuffer(clickBuffer, at: nil)
    }
}
