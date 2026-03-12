import Foundation

/// Time signatures supported for staff notation rendering.
///
/// Defines the metric structure of each measure, including the number
/// of beats, the note value that gets one beat, and the total beats
/// per measure. Used by `MeasureCalculator` to divide notes into
/// measures and by the renderer to draw time signature numerals.
public enum TimeSignature: String, Sendable, CaseIterable {
    /// 4/4 time — four quarter-note beats per measure.
    case fourFour = "4/4"

    /// 3/4 time — three quarter-note beats per measure.
    case threeFour = "3/4"

    /// 6/8 time — six eighth-note beats per measure (compound duple).
    case sixEight = "6/8"

    /// 2/4 time — two quarter-note beats per measure.
    case twoFour = "2/4"

    /// Top number of the time signature (number of beats).
    public var numerator: Int {
        switch self {
        case .fourFour: return 4
        case .threeFour: return 3
        case .sixEight: return 6
        case .twoFour: return 2
        }
    }

    /// Bottom number of the time signature (beat unit note value).
    ///
    /// 4 means the quarter note gets one beat; 8 means the eighth note.
    public var denominator: Int {
        switch self {
        case .fourFour: return 4
        case .threeFour: return 4
        case .sixEight: return 8
        case .twoFour: return 4
        }
    }

    /// Total beats per measure in quarter-note equivalents.
    ///
    /// This normalizes to quarter notes so that `MeasureCalculator`
    /// can uniformly compare note durations against measure capacity.
    /// - 4/4: 4 beats
    /// - 3/4: 3 beats
    /// - 6/8: 3 beats (6 eighth notes = 3 quarter notes)
    /// - 2/4: 2 beats
    public var beatsPerMeasure: Double {
        switch self {
        case .fourFour: return 4.0
        case .threeFour: return 3.0
        case .sixEight: return 3.0
        case .twoFour: return 2.0
        }
    }

    /// Create a time signature from a raw string value.
    ///
    /// Falls back to 4/4 if the string doesn't match any known time signature.
    ///
    /// - Parameter rawString: Time signature string (e.g., "3/4", "6/8", "").
    /// - Returns: Matching time signature, or `.fourFour` as default.
    public static func from(rawString: String) -> TimeSignature {
        TimeSignature(rawValue: rawString) ?? .fourFour
    }
}
