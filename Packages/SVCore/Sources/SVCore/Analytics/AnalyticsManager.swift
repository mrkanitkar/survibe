import Foundation

/// Thin analytics wrapper. Full PostHog integration in Batch 5.
public final class AnalyticsManager: Sendable {
    public static let shared = AnalyticsManager()

    private init() {}

    /// Configure analytics with API key. Call once at app launch.
    public func configure(apiKey: String) {
        // Batch 5: PostHog initialization
    }

    /// Track an analytics event with optional properties.
    public func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        // Batch 5: PostHog event tracking
    }

    /// Identify a user for analytics.
    public func identify(userId: String) {
        // Batch 5: PostHog user identification
    }
}
