import Foundation

/// Direction a note stem should be drawn.
///
/// Stems point up for notes below the middle staff line (B4, MIDI 71)
/// and down for notes on or above the middle line.
public enum StemDirection: Sendable {
    case up
    case down
}

/// Information about ledger lines needed for a note.
///
/// Notes above or below the staff require short horizontal lines
/// to extend the staff visually. This type captures how many are
/// needed and whether they sit above or below.
public struct LedgerLineInfo: Sendable, Equatable {
    /// Number of ledger lines needed (0 if note is on the staff).
    public let count: Int

    /// Whether the ledger lines are above the staff (`true`) or below (`false`).
    public let isAbove: Bool

    /// No ledger lines needed.
    public static let none = LedgerLineInfo(count: 0, isAbove: false)
}

/// Maps MIDI note numbers to staff positions for treble clef rendering.
///
/// The treble clef staff spans from E4 (MIDI 64, bottom line) to F5
/// (MIDI 77, top line). Notes outside this range require ledger lines.
/// All calculations use diatonic (white-key) steps relative to E4 so
/// that accidentals don't shift vertical position.
///
/// ## Coordinate System
/// Staff position 0 corresponds to the bottom line (E4). Each diatonic
/// step increments the position by 1 (one half-space on the staff).
/// A standard staff has positions 0 through 8 for the five lines.
public enum StaffPositionCalculator {

    // MARK: - Constants

    /// MIDI number for E4 — the bottom line of the treble clef staff.
    private static let bottomLineMIDI: Int = 64

    /// MIDI number for B4 — the middle line of the treble clef staff.
    private static let middleLineMIDI: Int = 71

    /// Staff position of the middle line (B4).
    private static let middleLinePosition: Int = 4

    /// Diatonic note names in chromatic order (C = 0).
    ///
    /// Sharps/flats map to the same diatonic position as their natural
    /// neighbor; accidental resolution is handled separately.
    private static let chromaticToDiatonic: [Int] = [
        0,  // C
        1,  // C#/Db → between C and D, maps to D position handled by accidentals
        1,  // D
        2,  // D#/Eb → maps to E-flat position
        2,  // E
        3,  // F
        3,  // F#/Gb
        4,  // G
        4,  // G#/Ab → maps to A-flat position
        5,  // A
        5,  // A#/Bb → maps to B-flat position
        6   // B
    ]

    // MARK: - Public Methods

    /// Convert a MIDI number to a diatonic step value.
    ///
    /// Diatonic steps count white-key positions from C0. This is used
    /// internally for staff position math and by `AccidentalResolver`.
    ///
    /// - Parameter midi: MIDI note number (0–127).
    /// - Returns: Diatonic step count from C0.
    static func midiToDiatonic(_ midi: Int) -> Int {
        let octave = midi / 12
        let semitone = midi % 12
        return octave * 7 + chromaticToDiatonic[semitone]
    }

    /// Calculate the staff Y-position for a given MIDI note number.
    ///
    /// Position 0 is the bottom staff line (E4). Each increment moves
    /// up one half-space. The five staff lines sit at positions 0, 2,
    /// 4, 6, 8.
    ///
    /// - Parameter midi: MIDI note number (0–127).
    /// - Returns: Staff position as an integer (may be negative for low notes).
    public static func staffPosition(midi: Int) -> Int {
        let noteDiatonic = midiToDiatonic(midi)
        let referenceDiatonic = midiToDiatonic(bottomLineMIDI)
        return noteDiatonic - referenceDiatonic
    }

    /// Calculate the Y offset in points for rendering on a canvas.
    ///
    /// Converts a MIDI number to a vertical pixel offset where higher
    /// notes have lower Y values (standard screen coordinates with
    /// origin at top-left).
    ///
    /// - Parameters:
    ///   - midi: MIDI note number (0–127).
    ///   - staffSpacing: Distance between adjacent staff lines in points. Default 10.
    /// - Returns: Y offset in points from the top staff line.
    public static func yOffset(midi: Int, staffSpacing: Double = 10.0) -> Double {
        let position = staffPosition(midi: midi)
        let halfSpace = staffSpacing / 2.0
        // Position 8 = top line (F5), Y = 0. Position decreases → Y increases.
        let topLinePosition = 8
        return Double(topLinePosition - position) * halfSpace
    }

    /// Determine the stem direction for a note based on its staff position.
    ///
    /// Notes below the middle line (B4, position 4) get stems pointing up.
    /// Notes on or above the middle line get stems pointing down.
    ///
    /// - Parameter midi: MIDI note number (0–127).
    /// - Returns: The stem direction.
    public static func stemDirection(midi: Int) -> StemDirection {
        let position = staffPosition(midi: midi)
        return position < middleLinePosition ? .up : .down
    }

    /// Calculate ledger line requirements for a note.
    ///
    /// Notes with staff positions below 0 or above 8 need ledger lines.
    /// Each line corresponds to an even position outside the staff range.
    ///
    /// - Parameter midi: MIDI note number (0–127).
    /// - Returns: Ledger line information (count and direction).
    public static func ledgerLines(midi: Int) -> LedgerLineInfo {
        let position = staffPosition(midi: midi)

        if position < 0 {
            // Below staff: ledger lines at positions -2, -4, -6, etc.
            // Also count position 0's line if the note is at -1
            let linesBelow = ((-position) + 1) / 2
            return LedgerLineInfo(count: linesBelow, isAbove: false)
        } else if position > 8 {
            // Above staff: ledger lines at positions 10, 12, 14, etc.
            let linesAbove = ((position - 8) + 1) / 2
            return LedgerLineInfo(count: linesAbove, isAbove: true)
        }

        return .none
    }

    /// Check whether a MIDI note sits exactly on a staff line.
    ///
    /// Staff lines are at even positions: 0, 2, 4, 6, 8.
    /// This helps renderers decide whether to draw a line through the notehead.
    ///
    /// - Parameter midi: MIDI note number (0–127).
    /// - Returns: `true` if the note sits on a line, `false` if in a space.
    public static func isOnLine(midi: Int) -> Bool {
        let position = staffPosition(midi: midi)
        return position % 2 == 0
    }
}
