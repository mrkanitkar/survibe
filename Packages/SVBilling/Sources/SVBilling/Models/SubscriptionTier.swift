import Foundation

/// Subscription tier levels for SurVibe.
public enum SubscriptionTier: String, CaseIterable, Sendable {
    /// Free tier with limited features.
    case free

    /// Basic paid tier.
    case basic

    /// Premium tier with all features.
    case premium

    /// Display name for the tier.
    public var displayName: String {
        switch self {
        case .free: "Free"
        case .basic: "Basic"
        case .premium: "Premium"
        }
    }
}
