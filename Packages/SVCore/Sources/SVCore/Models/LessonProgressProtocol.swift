import Foundation

/// Protocol for lesson progress (completed is one-way flag).
public protocol LessonProgressProtocol {
    var id: UUID { get }
    var lessonId: String { get }
    var completed: Bool { get }
    var bestScore: Int { get }
}
