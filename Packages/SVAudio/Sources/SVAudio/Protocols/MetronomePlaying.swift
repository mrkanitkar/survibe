import Foundation

/// Protocol abstracting metronome playback for testability.
///
/// The production implementation is `MetronomePlayer`, which uses
/// `AVAudioPlayerNode` with sample-accurate `AVAudioTime` scheduling.
/// Test doubles can track BPM and play/stop state without audio hardware.
@MainActor
public protocol MetronomePlaying: AnyObject {
    /// Current beats per minute.
    var bpm: Double { get }

    /// Whether the metronome is currently running.
    var isPlaying: Bool { get }

    /// Start the metronome at the current BPM.
    func start()

    /// Stop the metronome.
    func stop()

    /// Update the BPM. Restarts scheduling if currently playing.
    /// - Parameter newBPM: New beats per minute (1–300).
    func setBPM(_ newBPM: Double)
}
