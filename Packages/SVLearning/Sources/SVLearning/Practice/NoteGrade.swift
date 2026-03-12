import SwiftUI

/// Grade assigned to a single note attempt during practice.
///
/// Grades are ordered from best (perfect) to worst (miss), with each
/// grade defining a minimum accuracy percentage threshold, display color,
/// and SF Symbol icon for consistent visual feedback across practice views.
public enum NoteGrade: String, CaseIterable, Sendable, Comparable {
    case perfect
    case good
    case fair
    case miss

    /// Minimum accuracy percentage required for this grade (0.0–1.0).
    public var minimumPercentage: Double {
        switch self {
        case .perfect: 0.90
        case .good: 0.70
        case .fair: 0.50
        case .miss: 0.0
        }
    }

    /// Display color for this grade in practice UI.
    public var color: Color {
        switch self {
        case .perfect: .green
        case .good: .blue
        case .fair: .orange
        case .miss: .red
        }
    }

    /// SF Symbol icon for this grade.
    public var sfSymbol: String {
        switch self {
        case .perfect: "checkmark.circle.fill"
        case .good: "checkmark.circle"
        case .fair: "exclamationmark.circle"
        case .miss: "xmark.circle.fill"
        }
    }

    /// Determine the grade for a given accuracy percentage (0.0–1.0).
    ///
    /// Iterates through all grades from best to worst, returning the first
    /// grade whose minimum percentage threshold is met or exceeded.
    ///
    /// - Parameter accuracy: Accuracy value between 0.0 and 1.0.
    /// - Returns: The highest grade matching the accuracy.
    public static func from(accuracy: Double) -> NoteGrade {
        let clamped = max(0.0, min(1.0, accuracy))
        for grade in NoteGrade.allCases {
            if clamped >= grade.minimumPercentage {
                return grade
            }
        }
        return .miss
    }

    /// Comparable conformance — grades are ordered by quality (perfect > good > fair > miss).
    public static func < (lhs: NoteGrade, rhs: NoteGrade) -> Bool {
        lhs.minimumPercentage > rhs.minimumPercentage
    }
}
