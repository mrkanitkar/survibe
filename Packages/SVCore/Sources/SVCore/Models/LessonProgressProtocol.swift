import Foundation

/// Protocol for lesson progress (isCompleted is one-way flag).
public protocol LessonProgressProtocol: Sendable {
    var id: UUID { get }
    var lessonId: String { get }
    var isCompleted: Bool { get }
    var bestScore: Int { get }
}
