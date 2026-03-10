import Foundation
import PostHog

/// Thin PostHog analytics wrapper with privacy-first configuration.
/// No IP tracking, no fingerprinting, no IDFA collection.
public final class AnalyticsManager: @unchecked Sendable {
    public static let shared = AnalyticsManager()

    /// Whether analytics tracking is enabled. Defaults to true.
    /// Set to false to disable all tracking (user privacy toggle).
    public private(set) var isTrackingEnabled: Bool = true

    private init() {}

    /// Configure PostHog analytics with privacy mode. Call once at app launch.
    /// - Parameter apiKey: PostHog project API key
    /// - Parameter host: PostHog host URL (defaults to PostHog cloud)
    public func configure(apiKey: String, host: String = "https://app.posthog.com") {
        let config = PostHogConfig(apiKey: apiKey, host: host)

        // Privacy-first configuration: no IP, no fingerprinting
        config.captureApplicationLifecycleEvents = false
        config.captureScreenViews = false
        config.sendFeatureFlagEvent = false

        PostHogSDK.shared.setup(config)
    }

    /// Track an analytics event with optional properties.
    /// No-op if tracking is disabled via privacy toggle.
    public func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        guard isTrackingEnabled else { return }
        PostHogSDK.shared.capture(event.rawValue, properties: properties)
    }

    /// Identify a user for analytics.
    /// No-op if tracking is disabled via privacy toggle.
    public func identify(userId: String) {
        guard isTrackingEnabled else { return }
        PostHogSDK.shared.identify(userId)
    }

    /// Enable or disable all analytics tracking.
    public func setTrackingEnabled(_ enabled: Bool) {
        isTrackingEnabled = enabled
        if !enabled {
            PostHogSDK.shared.optOut()
        } else {
            PostHogSDK.shared.optIn()
        }
    }

    /// Reset analytics identity (e.g., on logout).
    public func reset() {
        PostHogSDK.shared.reset()
    }
}
