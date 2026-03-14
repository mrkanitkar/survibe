import Foundation

@testable import SurVibe

/// Convenience factory for creating NoteEvent instances in tests.
///
/// Provides shorthand methods to build NoteEvents without specifying
/// every parameter, using sensible defaults for test scenarios.
enum NoteEventFactory {
    /// Create a NoteEvent with minimal required parameters.
    /// - Parameters:
    ///   - swarName: Full Swar name (e.g., "Sa", "Komal Re").
    ///   - midiNote: MIDI note number (default: 60).
    ///   - octave: Octave number (default: 4).
    ///   - timestamp: Start time in seconds (default: 0).
    ///   - duration: Duration in seconds (default: 0.5).
    ///   - velocity: Key velocity (default: 100).
    /// - Returns: A configured NoteEvent.
    static func make(
        swarName: String = "Sa",
        westernName: String = "C4",
        midiNote: UInt8 = 60,
        octave: Int = 4,
        timestamp: TimeInterval = 0,
        duration: TimeInterval = 0.5,
        velocity: UInt8 = 100
    ) -> NoteEvent {
        NoteEvent(
            id: UUID(),
            midiNote: midiNote,
            swarName: swarName,
            westernName: westernName,
            octave: octave,
            timestamp: timestamp,
            duration: duration,
            velocity: velocity
        )
    }

    /// Create a sequence of NoteEvents from Swar names with equal spacing.
    /// - Parameters:
    ///   - swarNames: Array of full Swar names.
    ///   - duration: Duration of each note in seconds (default: 0.5).
    /// - Returns: Array of NoteEvents with cumulative timestamps.
    static func sequence(
        swarNames: [String],
        duration: TimeInterval = 0.5
    ) -> [NoteEvent] {
        swarNames.enumerated().map { index, name in
            make(
                swarName: name,
                timestamp: Double(index) * duration,
                duration: duration
            )
        }
    }
}
