import Foundation

/// Protocol for per-lesson completion tracking.
///
/// **CloudKit sync:** `isCompleted` is a one-way flag (`false → true`, never reverts).
/// `bestScore` uses highwater-mark conflict resolution (higher value wins).
///
/// The concrete `LessonProgress` SwiftData model in the main app target conforms to this.
public protocol LessonProgressProtocol: Sendable {
    /// Stable identifier (CloudKit record ID).
    var id: UUID { get }

    /// Unique lesson identifier matching the lesson catalog.
    var lessonId: String { get }

    /// Whether this lesson has been completed. One-way flag: once `true`, never reverts.
    var isCompleted: Bool { get }

    /// Highest score achieved on this lesson (0–100). Uses highwater-mark sync.
    var bestScore: Int { get }
}
