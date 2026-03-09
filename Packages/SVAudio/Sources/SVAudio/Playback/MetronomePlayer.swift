import AVFoundation

/// Metronome player using AVAudioPlayerNode with BPM control.
/// Uses AudioEngineManager's metronome node.
public final class MetronomePlayer: @unchecked Sendable {
    public static let shared = MetronomePlayer()

    /// Reference to the engine's metronome player node.
    private var playerNode: AVAudioPlayerNode {
        AudioEngineManager.shared.metronomeNode
    }

    /// Beats per minute (default: 60).
    public var bpm: Double = 60.0

    /// Whether the metronome is currently running.
    public private(set) var isPlaying: Bool = false

    /// Audio file for the click sound.
    private var clickFile: AVAudioFile?

    /// Timer for scheduling beats.
    private var timer: DispatchSourceTimer?

    /// Queue for metronome timing.
    private let metronomeQueue = DispatchQueue(label: "com.survibe.metronome", qos: .userInteractive)

    private init() {}

    /// Load a click sound for the metronome.
    /// - Parameter url: URL to the click audio file (.wav, .aif)
    public func loadClick(at url: URL) throws {
        clickFile = try AVAudioFile(forReading: url)
    }

    /// Start the metronome at the current BPM.
    public func start() {
        guard !isPlaying else { return }
        isPlaying = true

        let interval = 60.0 / bpm

        timer = DispatchSource.makeTimerSource(queue: metronomeQueue)
        timer?.schedule(deadline: .now(), repeating: interval)
        timer?.setEventHandler { [weak self] in
            self?.playClick()
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

    /// Update BPM while running.
    public func setBPM(_ newBPM: Double) {
        bpm = newBPM
        if isPlaying {
            stop()
            start()
        }
    }

    /// Set the volume of the metronome (0.0 to 1.0).
    public func setVolume(_ volume: Float) {
        AudioEngineManager.shared.setMetronomeVolume(volume)
    }

    /// Play a single click sound.
    private func playClick() {
        guard let clickFile else { return }
        playerNode.scheduleFile(clickFile, at: nil)
        playerNode.play()
    }
}
