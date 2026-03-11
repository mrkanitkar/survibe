import Foundation
import PostHog

/// Thin PostHog analytics wrapper with privacy-first configuration.
/// Uses @MainActor isolation for thread-safe state access.
///
/// Privacy settings applied:
/// - `captureApplicationLifecycleEvents`: disabled
/// - `captureScreenViews`: disabled
/// - `sendFeatureFlagEvent`: disabled
/// - `personProfiles`: `.identifiedOnly`
/// - IP anonymization: requires server-side PostHog project setting
/// - No IDFA collection (no ATTrackingManager usage)
@MainActor
public final class AnalyticsManager {
    public static let shared = AnalyticsManager()

    /// Whether analytics tracking is enabled. Defaults to true.
    /// Set to false to disable all tracking (user privacy toggle).
    public private(set) var isTrackingEnabled: Bool = true

    /// Whether the SDK has been configured via `configure(apiKey:host:)`.
    public private(set) var isConfigured: Bool = false

    private init() {}

    /// Configure PostHog analytics with privacy mode. Call once at app launch.
    ///
    /// - Parameters:
    ///   - apiKey: PostHog project API key (write-only key, safe in binary). Must not be empty.
    ///   - host: PostHog host URL (defaults to PostHog cloud).
    public func configure(apiKey: String, host: String = "https://app.posthog.com") {
        guard !apiKey.isEmpty else { return }
        let config = PostHogConfig(apiKey: apiKey, host: host)

        // Privacy-first configuration
        config.captureApplicationLifecycleEvents = false
        config.captureScreenViews = false
        config.sendFeatureFlagEvent = false
        config.personProfiles = .identifiedOnly

        PostHogSDK.shared.setup(config)
        isConfigured = true
    }

    /// Track an analytics event with optional properties.
    ///
    /// No-op if tracking is disabled or the SDK is not configured.
    ///
    /// - Parameters:
    ///   - event: The event to track, from the `AnalyticsEvent` enum.
    ///   - properties: Optional dictionary of event properties (e.g., `["tab": "practice"]`).
    ///     Keys should be `snake_case`. Values must be PostHog-serializable types.
    public func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        guard isTrackingEnabled, isConfigured else { return }
        PostHogSDK.shared.capture(event.rawValue, properties: properties)
    }

    /// Identify a user for analytics.
    ///
    /// - Parameter userId: Anonymous user identifier (e.g., CloudKit record ID or app-generated UUID).
    ///   Must not contain PII (email, name, phone). Validated in debug builds.
    public func identify(userId: String) {
        guard isTrackingEnabled, isConfigured else { return }

        // PII guard: reject strings that look like emails, phone numbers, or are too long
        #if DEBUG
        if userId.contains("@") || userId.hasPrefix("+") || userId.count > 128 {
            assertionFailure(
                "identify() userId appears to contain PII or exceeds 128 chars: \(userId.prefix(20))..."
            )
            return
        }
        #endif

        PostHogSDK.shared.identify(userId)
    }

    /// Enable or disable all analytics tracking.
    ///
    /// When disabled, calls PostHog `optOut()`. When re-enabled, calls `optIn()`.
    /// This persists across the session but does not persist across app launches
    /// — the default is always `true`.
    ///
    /// - Parameter enabled: `true` to enable tracking, `false` to disable.
    public func setTrackingEnabled(_ enabled: Bool) {
        isTrackingEnabled = enabled
        if isConfigured {
            if !enabled {
                PostHogSDK.shared.optOut()
            } else {
                PostHogSDK.shared.optIn()
            }
        }
    }

    /// Reset analytics identity and clear all cached state.
    ///
    /// Call on user logout to ensure the next user gets a fresh analytics session.
    /// No-op if the SDK is not configured.
    public func reset() {
        guard isConfigured else { return }
        PostHogSDK.shared.reset()
    }
}
