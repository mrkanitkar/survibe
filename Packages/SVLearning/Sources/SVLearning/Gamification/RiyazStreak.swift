import Foundation

/// Tracks daily practice (riyaz) streaks for gamification.
/// Full implementation in Sprint 1.
public struct RiyazStreak: Sendable {
    /// Current streak length in days.
    public var currentStreak: Int

    /// Longest streak ever achieved.
    public var longestStreak: Int

    /// Date of the last practice session.
    public var lastPracticeDate: Date?

    public init(currentStreak: Int = 0, longestStreak: Int = 0, lastPracticeDate: Date? = nil) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastPracticeDate = lastPracticeDate
    }

    /// Record a practice session for today. Updates streak accordingly.
    public mutating func recordPractice(on date: Date = Date()) {
        // Sprint 1: Check if consecutive day, increment or reset streak
        currentStreak += 1
        longestStreak = max(longestStreak, currentStreak)
        lastPracticeDate = date
    }
}
