import Foundation

/// Errors that can occur during Standard MIDI File parsing.
///
/// Each case provides a user-readable description via `LocalizedError`
/// conformance, suitable for display in error UI or logging.
public enum MIDIParseError: LocalizedError, Sendable {
    /// The data does not begin with the "MThd" header magic bytes.
    case invalidHeader

    /// The MIDI data is structurally corrupt (unexpected EOF, invalid chunks).
    case corruptedData

    /// The file parsed successfully but contains no note events.
    case noNotesFound

    /// The MIDI file uses format 2 (independent patterns), which is not supported.
    case unsupportedFormat

    public var errorDescription: String? {
        switch self {
        case .invalidHeader:
            "Invalid MIDI file header — expected MThd magic bytes"
        case .corruptedData:
            "Corrupted MIDI data — unexpected end of file or invalid chunk"
        case .noNotesFound:
            "No note events found in the MIDI file"
        case .unsupportedFormat:
            "MIDI format 2 (independent patterns) is not supported"
        }
    }
}
