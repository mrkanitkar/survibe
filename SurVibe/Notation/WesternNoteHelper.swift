import Foundation

/// Utility for converting MIDI note numbers to Western note names and octaves.
///
/// Uses standard MIDI numbering where middle C (C4) = 60.
/// Note names include sharps (e.g., "C#") but not flats.
enum WesternNoteHelper {
    // MARK: - Properties

    /// The 12 chromatic note names in order from C.
    private static let noteNames = [
        "C", "C#", "D", "D#", "E", "F",
        "F#", "G", "G#", "A", "A#", "B",
    ]

    // MARK: - Public Methods

    /// Returns the note name (without octave) for a MIDI number.
    ///
    /// Maps the MIDI number modulo 12 to the chromatic scale starting at C.
    /// For example, MIDI 60 returns "C", MIDI 61 returns "C#".
    ///
    /// - Parameter midiNumber: MIDI note number (0–127).
    /// - Returns: Note name string like "C", "C#", "D", etc.
    ///   Returns "?" if the computed index is out of range.
    static func noteName(from midiNumber: Int) -> String {
        let index = midiNumber % 12
        guard index >= 0, index < noteNames.count else { return "?" }
        return noteNames[index]
    }

    /// Returns the octave number for a MIDI number.
    ///
    /// Uses the standard MIDI convention where MIDI 60 = C4.
    /// Octave is calculated as `(midiNumber / 12) - 1`.
    ///
    /// - Parameter midiNumber: MIDI note number (0–127).
    /// - Returns: Octave number (MIDI 60 = octave 4).
    static func octave(from midiNumber: Int) -> Int {
        (midiNumber / 12) - 1
    }

    /// Returns the full display name (note + octave) for a MIDI number.
    ///
    /// Combines `noteName(from:)` and `octave(from:)` into a single
    /// human-readable string suitable for UI display.
    ///
    /// - Parameter midiNumber: MIDI note number (0–127).
    /// - Returns: Display string like "C4", "A#3", "G5".
    static func displayName(from midiNumber: Int) -> String {
        "\(noteName(from: midiNumber))\(octave(from: midiNumber))"
    }
}
