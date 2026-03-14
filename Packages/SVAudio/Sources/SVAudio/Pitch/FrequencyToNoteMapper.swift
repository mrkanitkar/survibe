import Foundation

/// Result of mapping a detected frequency to a musical note.
///
/// Contains the note name (Swar), octave, cents deviation, and
/// optional raga-awareness metadata when a `RagaContext` is active.
public struct NoteMapping: Sendable, Equatable {
    /// Swar name of the detected note (e.g., "Sa", "Re", "Tivra Ma").
    public let noteName: String

    /// Octave number of the detected note.
    public let octave: Int

    /// Cents offset from the target pitch (-50 to +50 in 12ET, variable in JI).
    public let centsOffset: Double

    /// Whether the detected note belongs to the active raga's scale.
    /// `nil` when no raga context is active (equal temperament mode).
    public let isInRaga: Bool?

    /// Cents deviation from the just-intonation target for this raga scale degree.
    /// `nil` when no raga context is active.
    public let ragaCentsOffset: Double?

    /// Memberwise initializer.
    ///
    /// - Parameters:
    ///   - noteName: Swar name of the detected note.
    ///   - octave: Octave number.
    ///   - centsOffset: Cents offset from the nearest note (12ET or JI).
    ///   - isInRaga: Whether the note is in the active raga. `nil` for 12ET mode.
    ///   - ragaCentsOffset: Cents deviation from the JI target. `nil` for 12ET mode.
    public init(
        noteName: String,
        octave: Int,
        centsOffset: Double,
        isInRaga: Bool? = nil,
        ragaCentsOffset: Double? = nil
    ) {
        self.noteName = noteName
        self.octave = octave
        self.centsOffset = centsOffset
        self.isInRaga = isInRaga
        self.ragaCentsOffset = ragaCentsOffset
    }
}

/// Protocol for mapping a detected audio frequency to a musical note.
///
/// Two implementations exist:
/// - `EqualTemperamentMapper`: Standard 12-tone equal temperament (default).
/// - `RagaAwareMapper`: Just-intonation mapping using raga scale degrees.
public protocol FrequencyToNoteMapper: Sendable {
    /// Map a detected frequency to the nearest musical note.
    ///
    /// - Parameters:
    ///   - frequency: Detected frequency in Hz.
    ///   - referencePitch: Reference pitch for A4 (default: 440 Hz).
    /// - Returns: A `NoteMapping` with note name, octave, and cents deviation.
    /// - Throws: `AudioValidationError` if inputs are invalid.
    func mapFrequency(
        _ frequency: Double,
        referencePitch: Double
    ) throws -> NoteMapping

    /// Check whether a given Swar name is allowed in the current context.
    ///
    /// Returns `true` for all notes in equal temperament mode.
    /// In raga mode, returns `true` only for notes in the raga's scale.
    ///
    /// - Parameter noteName: Swar name (e.g., "Sa", "Tivra Ma").
    /// - Returns: Whether the note is allowed.
    func isNoteAllowed(_ noteName: String) -> Bool
}
