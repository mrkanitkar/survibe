import Foundation

/// Protocol for achievements (append-only, never deleted).
public protocol AchievementProtocol {
    var id: UUID { get }
    var type: String { get }
    var earnedAt: Date { get }
}
