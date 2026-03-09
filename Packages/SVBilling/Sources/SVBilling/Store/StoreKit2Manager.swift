import Foundation
import StoreKit
import SVCore

/// StoreKit 2 subscription management.
/// Handles product fetching, purchasing, and entitlement verification.
/// Full implementation in Phase 2.
@MainActor
@Observable
public final class StoreKit2Manager {
    public static let shared = StoreKit2Manager()

    /// Current subscription tier.
    public var currentTier: SubscriptionTier = .free

    private init() {}

    /// Fetch available products from the App Store.
    public func fetchProducts() async throws {
        // Phase 2: Product.products(for:)
    }

    /// Purchase a subscription product.
    public func purchase(_ tier: SubscriptionTier) async throws {
        // Phase 2: product.purchase()
    }

    /// Restore purchases.
    public func restorePurchases() async throws {
        // Phase 2: Transaction.currentEntitlements
    }
}
