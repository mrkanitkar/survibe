import Foundation

/// Protocol for subscription state (StoreKit 2 is source of truth).
public protocol SubscriptionStateProtocol: Sendable {
    var id: UUID { get }
    var tier: String { get }
    var isActive: Bool { get }
}
