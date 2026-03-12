import Foundation

/// Key signatures supported for staff notation rendering.
///
/// Each key defines which notes are sharped or flatted by default,
/// the staff positions where those accidentals are drawn, and a
/// lookup method for determining the accidental state of any
/// diatonic note within the key.
///
/// Currently supports 6 common major keys covering most Indian
/// classical music when mapped to Western notation.
public enum KeySignature: String, Sendable, CaseIterable {
    /// C Major — no sharps or flats.
    case cMajor = "C"

    /// G Major — 1 sharp (F#).
    case gMajor = "G"

    /// D Major — 2 sharps (F#, C#).
    case dMajor = "D"

    /// A Major — 3 sharps (F#, C#, G#).
    case aMajor = "A"

    /// F Major — 1 flat (Bb).
    case fMajor = "F"

    /// Bb Major — 2 flats (Bb, Eb).
    case bbMajor = "Bb"

    // MARK: - Accidental State

    /// The accidental state of a note within a key signature.
    public enum AccidentalState: Sendable, Equatable {
        /// Note is sharped by the key signature.
        case sharp

        /// Note is flatted by the key signature.
        case flat

        /// Note is natural (unaltered) in this key.
        case natural
    }

    // MARK: - Sharp/Flat Counts

    /// Note names that are sharped in this key (in order of sharps).
    ///
    /// Follows the circle of fifths order: F, C, G, D, A, E, B.
    public var sharps: [String] {
        switch self {
        case .cMajor: return []
        case .gMajor: return ["F"]
        case .dMajor: return ["F", "C"]
        case .aMajor: return ["F", "C", "G"]
        case .fMajor: return []
        case .bbMajor: return []
        }
    }

    /// Note names that are flatted in this key (in order of flats).
    ///
    /// Follows the circle of fourths order: B, E, A, D, G, C, F.
    public var flats: [String] {
        switch self {
        case .cMajor: return []
        case .gMajor: return []
        case .dMajor: return []
        case .aMajor: return []
        case .fMajor: return ["B"]
        case .bbMajor: return ["B", "E"]
        }
    }

    // MARK: - Staff Positions for Key Signature Drawing

    /// Staff positions (from bottom line = 0) where sharp symbols are drawn.
    ///
    /// Positions follow standard treble clef key signature placement.
    /// For example, F# is drawn at position 8 (top line, F5).
    public var sharpStaffPositions: [Int] {
        switch self {
        case .cMajor: return []
        case .gMajor: return [8]           // F# on top line
        case .dMajor: return [8, 5]        // F#, C#
        case .aMajor: return [8, 5, 9]     // F#, C#, G#
        case .fMajor: return []
        case .bbMajor: return []
        }
    }

    /// Staff positions (from bottom line = 0) where flat symbols are drawn.
    ///
    /// Positions follow standard treble clef key signature placement.
    /// For example, Bb is drawn at position 4 (middle line, B4).
    public var flatStaffPositions: [Int] {
        switch self {
        case .cMajor: return []
        case .gMajor: return []
        case .dMajor: return []
        case .aMajor: return []
        case .fMajor: return [4]           // Bb on middle line
        case .bbMajor: return [4, 7]       // Bb, Eb
        }
    }

    // MARK: - Accidental Lookup

    /// Determine the accidental state of a diatonic note name in this key.
    ///
    /// Returns whether the note is sharped, flatted, or natural according
    /// to the key signature. This does not account for measure-level
    /// accidentals — use `AccidentalResolver` for that.
    ///
    /// - Parameter diatonicNote: A note letter name ("C", "D", "E", etc.).
    /// - Returns: The accidental state in this key.
    public func accidentalFor(diatonicNote: String) -> AccidentalState {
        if sharps.contains(diatonicNote) {
            return .sharp
        } else if flats.contains(diatonicNote) {
            return .flat
        }
        return .natural
    }

    /// Create a key signature from a raw string value.
    ///
    /// Falls back to C Major if the string doesn't match any known key.
    ///
    /// - Parameter rawString: Key signature string (e.g., "G", "Bb", "").
    /// - Returns: Matching key signature, or `.cMajor` as default.
    public static func from(rawString: String) -> KeySignature {
        KeySignature(rawValue: rawString) ?? .cMajor
    }
}
