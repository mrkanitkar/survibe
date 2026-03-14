import Foundation

/// Maps detected frequencies to notes using 12-tone equal temperament.
///
/// Wraps `SwarUtility.frequencyToNote()` behind the `FrequencyToNoteMapper`
/// protocol. All notes are considered "allowed" (no raga filtering).
/// This is the default mapper used when no raga context is active.
public struct EqualTemperamentMapper: FrequencyToNoteMapper {
    /// Create an equal temperament mapper.
    public init() {}

    /// Map a frequency to the nearest 12ET note.
    ///
    /// Delegates to `SwarUtility.frequencyToNote()` for the actual conversion
    /// and wraps the result in a `NoteMapping` with `nil` raga metadata.
    ///
    /// - Parameters:
    ///   - frequency: Detected frequency in Hz.
    ///   - referencePitch: Reference pitch for A4 (default: 440 Hz).
    /// - Returns: A `NoteMapping` with 12ET note name, octave, and cents offset.
    /// - Throws: `AudioValidationError` if inputs are invalid.
    public func mapFrequency(
        _ frequency: Double,
        referencePitch: Double = 440.0
    ) throws -> NoteMapping {
        let (noteName, octave, cents) = try SwarUtility.frequencyToNote(
            frequency, referencePitch: referencePitch
        )
        return NoteMapping(
            noteName: noteName,
            octave: octave,
            centsOffset: cents
        )
    }

    /// All notes are allowed in equal temperament mode.
    ///
    /// - Parameter noteName: Swar name (ignored).
    /// - Returns: Always `true`.
    public func isNoteAllowed(_ noteName: String) -> Bool {
        true
    }
}
