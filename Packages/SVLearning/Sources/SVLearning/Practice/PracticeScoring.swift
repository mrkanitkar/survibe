import Foundation

/// Session-level scoring utilities for practice mode.
///
/// Computes aggregate metrics from a collection of `NoteScore` values:
/// star ratings, XP earned, and streak analysis. Used by the practice
/// session summary to display performance results.
public enum PracticeScoring {
    /// Calculate a 1–5 star rating from overall accuracy.
    ///
    /// Maps accuracy percentage to stars using fixed thresholds:
    /// - 5 stars: >= 90%
    /// - 4 stars: >= 75%
    /// - 3 stars: >= 60%
    /// - 2 stars: >= 40%
    /// - 1 star: < 40%
    ///
    /// - Parameter accuracy: Session accuracy between 0.0 and 1.0.
    /// - Returns: Star count from 1 to 5.
    public static func starRating(accuracy: Double) -> Int {
        let clamped = max(0.0, min(1.0, accuracy))
        switch clamped {
        case 0.90...: return 5
        case 0.75..<0.90: return 4
        case 0.60..<0.75: return 3
        case 0.40..<0.60: return 2
        default: return 1
        }
    }

    /// Calculate XP earned from accuracy and song difficulty.
    ///
    /// Formula: `baseXP * accuracyMultiplier * difficultyMultiplier`
    /// where accuracyMultiplier scales from 1.0 to `maxXPMultiplier` (3.0)
    /// and difficultyMultiplier adds a bonus per difficulty level.
    ///
    /// - Parameters:
    ///   - accuracy: Session accuracy between 0.0 and 1.0.
    ///   - difficulty: Song difficulty level (1–5).
    /// - Returns: XP amount to award.
    public static func xpEarned(accuracy: Double, difficulty: Int) -> Int {
        let clamped = max(0.0, min(1.0, accuracy))
        let clampedDifficulty = max(1, min(5, difficulty))

        let accuracyMultiplier = 1.0 + clamped * (PracticeConstants.maxXPMultiplier - 1.0)
        let difficultyMultiplier = 1.0 + Double(clampedDifficulty - 1) * PracticeConstants.difficultyXPMultiplier

        return Int(Double(PracticeConstants.baseXP) * accuracyMultiplier * difficultyMultiplier)
    }

    /// Find the longest streak of consecutive non-miss grades.
    ///
    /// A streak counts consecutive notes graded as perfect, good, or fair
    /// (anything above miss). The longest such streak in the array is returned.
    ///
    /// - Parameter grades: Array of grades in note order.
    /// - Returns: Length of the longest non-miss streak.
    public static func longestStreak(grades: [NoteGrade]) -> Int {
        var maxStreak = 0
        var currentStreak = 0

        for grade in grades {
            if grade != .miss {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }

        return maxStreak
    }

    /// Calculate the average accuracy from a collection of note scores.
    ///
    /// Returns 0.0 if the array is empty to avoid division by zero.
    ///
    /// - Parameter scores: Array of note scores.
    /// - Returns: Mean accuracy between 0.0 and 1.0.
    public static func averageAccuracy(scores: [NoteScore]) -> Double {
        guard !scores.isEmpty else { return 0.0 }
        let total = scores.reduce(0.0) { $0 + $1.accuracy }
        return total / Double(scores.count)
    }

    /// Count notes by grade from a collection of note scores.
    ///
    /// - Parameter scores: Array of note scores.
    /// - Returns: Dictionary mapping each `NoteGrade` to its count.
    public static func gradeCounts(scores: [NoteScore]) -> [NoteGrade: Int] {
        var counts: [NoteGrade: Int] = [:]
        for grade in NoteGrade.allCases {
            counts[grade] = 0
        }
        for score in scores {
            counts[score.grade, default: 0] += 1
        }
        return counts
    }
}
