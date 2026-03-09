import Foundation
import SwiftData

/// User profile model for CloudKit sync.
/// All fields have defaults or are optional per CloudKit requirements.
/// Additive-only: XP and rang only increase (max-wins).
@Model
final class UserProfile {
    var id: UUID = UUID()
    var displayName: String = ""
    var currentRang: Int = 1
    var totalXP: Int = 0
    var preferredLanguage: String = "en"
    var createdAt: Date = Date()
    var lastActiveAt: Date = Date()

    /// Profile image data (stored as Transformable blob in CloudKit).
    @Attribute(.externalStorage) var profileImageData: Data?

    init(
        displayName: String = "",
        preferredLanguage: String = "en"
    ) {
        self.id = UUID()
        self.displayName = displayName
        self.currentRang = 1
        self.totalXP = 0
        self.preferredLanguage = preferredLanguage
        self.createdAt = Date()
        self.lastActiveAt = Date()
    }

    /// Add XP using max-wins merge strategy (only increases).
    func addXP(_ amount: Int) {
        totalXP = max(totalXP, totalXP + amount)
        lastActiveAt = Date()
    }
}
