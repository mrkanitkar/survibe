import Foundation
import SVAudio

/// Test double for `MetronomePlaying` that tracks BPM and play state
/// without audio hardware.
@MainActor
final class MockMetronomePlayer: MetronomePlaying {
    private(set) var bpm: Double = 60.0
    private(set) var isPlaying: Bool = false

    /// Number of times `start()` was called.
    private(set) var startCallCount: Int = 0

    /// Number of times `stop()` was called.
    private(set) var stopCallCount: Int = 0

    func start() {
        startCallCount += 1
        isPlaying = true
    }

    func stop() {
        stopCallCount += 1
        isPlaying = false
    }

    func setBPM(_ newBPM: Double) {
        bpm = newBPM
    }

    /// Reset all recorded state.
    func reset() {
        bpm = 60.0
        isPlaying = false
        startCallCount = 0
        stopCallCount = 0
    }
}
