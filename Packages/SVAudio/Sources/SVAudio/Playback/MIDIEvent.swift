import Foundation

/// A single MIDI note event extracted from a Standard MIDI File.
///
/// MIDIEvent represents a note-on event with its timing and duration,
/// ready for playback scheduling by SongPlaybackEngine.
/// All times are in seconds from the start of the song.
///
/// - Note: Duration is computed by pairing Note On and Note Off events
///   during MIDI parsing. If no matching Note Off is found, a default
///   duration of one quarter note is used.
public struct MIDIEvent: Hashable, Sendable, Codable {
    /// MIDI note number (0–127). Middle C = 60.
    public let noteNumber: UInt8

    /// Key velocity (1–127). 0 is treated as note-off by convention.
    public let velocity: UInt8

    /// Absolute time in seconds from the start of the song.
    public let timestamp: TimeInterval

    /// Duration of the note in seconds.
    public let duration: TimeInterval

    /// Creates a MIDI event with the specified parameters.
    /// - Parameters:
    ///   - noteNumber: MIDI note number (0–127).
    ///   - velocity: Key velocity (1–127).
    ///   - timestamp: Absolute time in seconds from song start.
    ///   - duration: Note duration in seconds.
    public init(noteNumber: UInt8, velocity: UInt8, timestamp: TimeInterval, duration: TimeInterval) {
        self.noteNumber = noteNumber
        self.velocity = velocity
        self.timestamp = timestamp
        self.duration = duration
    }
}
