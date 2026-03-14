import Foundation
import SVAudio

/// Test double for `SoundFontPlaying` that records all note play/stop calls
/// without requiring audio hardware.
@MainActor
final class MockSoundFontPlayer: SoundFontPlaying {
    var isLoaded: Bool = true

    /// All notes that have been played, in order.
    private(set) var playedNotes: [(midiNote: UInt8, velocity: UInt8, channel: UInt8)] = []

    /// All notes that have been stopped, in order.
    private(set) var stoppedNotes: [(midiNote: UInt8, channel: UInt8)] = []

    /// Number of times `stopAllNotes()` was called.
    private(set) var stopAllNotesCallCount: Int = 0

    func playNote(midiNote: UInt8, velocity: UInt8, channel: UInt8) {
        playedNotes.append((midiNote, velocity, channel))
    }

    func stopNote(midiNote: UInt8, channel: UInt8) {
        stoppedNotes.append((midiNote, channel))
    }

    func stopAllNotes() {
        stopAllNotesCallCount += 1
    }

    /// Reset all recorded calls.
    func reset() {
        playedNotes.removeAll()
        stoppedNotes.removeAll()
        stopAllNotesCallCount = 0
    }
}
