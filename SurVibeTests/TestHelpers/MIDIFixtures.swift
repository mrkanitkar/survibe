import Foundation
import SVAudio

/// Pre-built MIDI event fixtures for play-along tests.
///
/// Provides commonly needed MIDI event sequences to avoid
/// duplicating test setup code across test files.
enum MIDIFixtures {
    /// A simple 4-note C major scale: C4, D4, E4, F4.
    /// Each note is 0.5s duration, spaced 0.5s apart (no gaps).
    static let cMajorScale: [MIDIEvent] = [
        MIDIEvent(noteNumber: 60, velocity: 100, timestamp: 0.0, duration: 0.5),
        MIDIEvent(noteNumber: 62, velocity: 100, timestamp: 0.5, duration: 0.5),
        MIDIEvent(noteNumber: 64, velocity: 100, timestamp: 1.0, duration: 0.5),
        MIDIEvent(noteNumber: 65, velocity: 100, timestamp: 1.5, duration: 0.5),
    ]

    /// A single note for minimal test scenarios.
    static let singleNote: [MIDIEvent] = [
        MIDIEvent(noteNumber: 60, velocity: 80, timestamp: 0.0, duration: 1.0),
    ]

    /// Notes with komal/tivra pitches: Komal Re (Db4=61), Tivra Ma (F#4=66).
    static let komalTivraSequence: [MIDIEvent] = [
        MIDIEvent(noteNumber: 60, velocity: 100, timestamp: 0.0, duration: 0.5),   // Sa
        MIDIEvent(noteNumber: 61, velocity: 100, timestamp: 0.5, duration: 0.5),   // Komal Re
        MIDIEvent(noteNumber: 66, velocity: 100, timestamp: 1.0, duration: 0.5),   // Tivra Ma
        MIDIEvent(noteNumber: 67, velocity: 100, timestamp: 1.5, duration: 0.5),   // Pa
    ]

    /// An empty event array.
    static let empty: [MIDIEvent] = []
}
