import Foundation
import SwiftData

/// Achievement record. Append-only: achievements are earned and never removed.
/// Type stored as String rawValue for CloudKit compatibility.
@Model
final class Achievement {
    var id: UUID = UUID()
    var achievementType: String = ""
    var title: String = ""
    var achievementDescription: String = ""
    var earnedAt: Date = Date()
    var xpReward: Int = 0

    init(
        achievementType: String = "",
        title: String = "",
        achievementDescription: String = "",
        xpReward: Int = 0
    ) {
        self.id = UUID()
        self.achievementType = achievementType
        self.title = title
        self.achievementDescription = achievementDescription
        self.earnedAt = Date()
        self.xpReward = xpReward
    }
}
