import Foundation

/// Protocol for earned achievements / badges.
///
/// Achievements are **append-only** — once earned, they are never revoked or deleted.
/// The `isUnlocked` flag on the concrete model is a one-way `false → true` flag
/// that never reverts, ensuring CloudKit sync cannot un-earn an achievement.
///
/// The concrete `Achievement` SwiftData model in the main app target conforms to this.
public protocol AchievementProtocol: Sendable {
    /// Stable identifier (CloudKit record ID).
    var id: UUID { get }

    /// Achievement type key (e.g., "first_riyaz", "100_xp"). Stored as `String` for CloudKit.
    var type: String { get }

    /// Date when the achievement was earned.
    var earnedAt: Date { get }
}
