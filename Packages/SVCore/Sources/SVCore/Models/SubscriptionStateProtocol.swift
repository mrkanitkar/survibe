import Foundation

/// Protocol for in-app subscription state.
///
/// This is a **local cache** of StoreKit 2 subscription status. StoreKit 2
/// is the source of truth — this model is updated after each `Transaction.updates`
/// check and stored in SwiftData for offline access.
///
/// The concrete `SubscriptionState` SwiftData model in the main app target conforms to this.
public protocol SubscriptionStateProtocol: Sendable {
    /// Stable identifier (CloudKit record ID).
    var id: UUID { get }

    /// Subscription tier key (e.g., "free", "premium"). Stored as `String` for CloudKit.
    var tier: String { get }

    /// Whether the subscription is currently active (not expired or revoked).
    var isActive: Bool { get }
}
