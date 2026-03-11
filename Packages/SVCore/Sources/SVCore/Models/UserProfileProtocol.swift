import Foundation

/// Protocol defining the shape of a user profile for cross-package use.
///
/// The concrete `UserProfile` SwiftData model in the main app target conforms
/// to this protocol. Packages reference this protocol to avoid depending on
/// SwiftData or the main target.
///
/// **CloudKit sync:** `totalXP` and `currentRang` use highwater-mark conflict
/// resolution (higher value wins). `displayName` uses last-writer-wins.
public protocol UserProfileProtocol: Sendable {
    /// Stable identifier (CloudKit record ID).
    var id: UUID { get }

    /// User-chosen display name. Defaults to `""`.
    var displayName: String { get }

    /// Current gamification level (1–5). Uses highwater-mark sync.
    var currentRang: Int { get }

    /// Cumulative experience points. Uses highwater-mark sync.
    var totalXP: Int { get }

    /// ISO 639-1 language code (e.g., "hi", "en"). Defaults to system language.
    var preferredLanguage: String { get }
}
