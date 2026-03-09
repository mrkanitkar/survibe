import AVFoundation

/// Metronome player using AVAudioPlayerNode with BPM control.
/// Full implementation in Batch 7.
public final class MetronomePlayer: @unchecked Sendable {
    public static let shared = MetronomePlayer()

    /// Beats per minute (default: 60).
    public var bpm: Double = 60.0

    private init() {}

    /// Start the metronome at the current BPM.
    public func start() {
        // Batch 7: Schedule repeating beats at BPM interval
    }

    /// Stop the metronome.
    public func stop() {
        // Batch 7: Stop player node, cancel timer
    }
}
