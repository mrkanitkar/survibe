import Foundation

/// Visual shape of a notehead based on the note's duration.
///
/// Maps musical durations to their standard notation appearance:
/// whether the notehead is filled, has a stem, or requires flags/beams.
public enum NoteheadType: String, Sendable, CaseIterable {
    /// Whole note (semibreve) — 4 beats in 4/4 time.
    case whole

    /// Half note (minim) — 2 beats in 4/4 time.
    case half

    /// Quarter note (crotchet) — 1 beat in 4/4 time.
    case quarter

    /// Eighth note (quaver) — 0.5 beats in 4/4 time.
    case eighth

    /// Sixteenth note (semiquaver) — 0.25 beats in 4/4 time.
    case sixteenth

    /// Whether the notehead is filled (solid black).
    ///
    /// Whole and half notes have open noteheads; quarter and shorter are filled.
    public var isFilled: Bool {
        switch self {
        case .whole, .half:
            return false
        case .quarter, .eighth, .sixteenth:
            return true
        }
    }

    /// Whether the note has a stem.
    ///
    /// All notes except whole notes have stems.
    public var hasStem: Bool {
        self != .whole
    }

    /// Number of flags attached to the stem (for unbeamed notes).
    ///
    /// Quarter notes and longer have no flags. Eighth notes have 1,
    /// sixteenth notes have 2.
    public var flagCount: Int {
        switch self {
        case .whole, .half, .quarter:
            return 0
        case .eighth:
            return 1
        case .sixteenth:
            return 2
        }
    }

    /// Number of beams when notes are grouped (same as `flagCount`).
    ///
    /// Beams replace flags when multiple short notes are adjacent
    /// within the same beat group.
    public var beamCount: Int {
        flagCount
    }

    /// Create a notehead type from a beat duration value.
    ///
    /// Uses the base duration (before any dotting) to determine the
    /// notehead shape. Durations are in beats relative to a quarter note
    /// (quarter = 1.0).
    ///
    /// - Parameter duration: Duration in beats (quarter note = 1.0).
    public init(duration: Double) {
        let base = DurationHelper.baseDuration(from: duration)
        switch base {
        case 4.0...:
            self = .whole
        case 2.0..<4.0:
            self = .half
        case 1.0..<2.0:
            self = .quarter
        case 0.5..<1.0:
            self = .eighth
        default:
            self = .sixteenth
        }
    }
}

/// Utilities for analyzing note durations in beat-based notation.
///
/// Handles dotted note detection and base duration extraction
/// for mapping to visual notehead types.
public enum DurationHelper {
    /// Standard beat durations in descending order.
    private static let standardDurations: [Double] = [4.0, 2.0, 1.0, 0.5, 0.25]

    /// Check whether a duration represents a dotted note.
    ///
    /// A dotted note lasts 1.5x its base duration. This method checks
    /// if the given duration is approximately 1.5x any standard duration.
    ///
    /// - Parameter duration: Duration in beats.
    /// - Returns: `true` if the duration is dotted.
    public static func isDotted(duration: Double) -> Bool {
        for base in standardDurations {
            let dotted = base * 1.5
            if abs(duration - dotted) < 0.01 {
                return true
            }
        }
        return false
    }

    /// Extract the base (undotted) duration from a potentially dotted duration.
    ///
    /// If the duration is dotted, returns the base value (duration / 1.5).
    /// Otherwise returns the duration unchanged.
    ///
    /// - Parameter duration: Duration in beats.
    /// - Returns: Base duration without dot extension.
    public static func baseDuration(from duration: Double) -> Double {
        if isDotted(duration: duration) {
            return duration / 1.5
        }
        return duration
    }
}
