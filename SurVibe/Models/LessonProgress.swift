import Foundation
import SwiftData

/// Tracks lesson completion progress. One-way flag: once completed, stays completed.
@Model
final class LessonProgress {
    var id: UUID = UUID()
    var lessonId: String = ""
    var lessonTitle: String = ""
    var isCompleted: Bool = false
    var completedAt: Date?
    var progressPercent: Double = 0.0
    var lastAccessedAt: Date = Date()

    init(
        lessonId: String = "",
        lessonTitle: String = ""
    ) {
        self.id = UUID()
        self.lessonId = lessonId
        self.lessonTitle = lessonTitle
        self.isCompleted = false
        self.progressPercent = 0.0
        self.lastAccessedAt = Date()
    }

    /// Mark lesson as completed (one-way flag — cannot be uncompleted).
    func markCompleted() {
        guard !isCompleted else { return }
        isCompleted = true
        completedAt = Date()
        progressPercent = 1.0
    }
}
