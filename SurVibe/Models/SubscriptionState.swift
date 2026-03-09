import Foundation
import SwiftData

/// Local cache of StoreKit 2 subscription state for CloudKit sync.
@Model
final class SubscriptionState {
    var id: UUID = UUID()
    var tier: String = "free"
    var isActive: Bool = false
    var expiresAt: Date?
    var originalPurchaseDate: Date?
    var lastVerifiedAt: Date = Date()

    init(tier: String = "free") {
        self.id = UUID()
        self.tier = tier
        self.isActive = tier != "free"
        self.lastVerifiedAt = Date()
    }
}
