import Foundation

/// Protocol for analytics event tracking.
///
/// Decouples SVCore (and all downstream packages) from any specific analytics
/// SDK. Concrete implementations live in the app target or an adapter layer.
/// Only SVCore's `AnalyticsManager` should conform to this in production.
///
/// The protocol is `@MainActor`-isolated, matching `AnalyticsManager`.
/// Callers that hold an `any AnalyticsProviding` reference must be on the
/// main actor or use `await` to cross the boundary.
@MainActor
public protocol AnalyticsProviding {

    /// Tracks a named analytics event with optional properties.
    ///
    /// - Parameters:
    ///   - event: The event to record.
    ///   - properties: Sendable key-value metadata. Values must be `Sendable`
    ///     to cross isolation boundaries without data races. Pass `nil` for
    ///     events with no metadata.
    func track(_ event: AnalyticsEvent, properties: [String: any Sendable]?)

    /// Associates future events with a user identity.
    ///
    /// - Parameter userId: An opaque, non-PII user identifier (e.g. UUID string).
    ///   Must not contain email addresses, phone numbers, or other personally
    ///   identifiable information.
    func identify(userId: String)
}
