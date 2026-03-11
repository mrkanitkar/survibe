import Foundation

/// Protocol for daily practice (riyaz) entries.
///
/// Entries are **append-only** — once created, they are never deleted or modified.
/// This ensures CloudKit sync never causes data loss from conflicting deletes.
///
/// The concrete `RiyazEntry` SwiftData model in the main app target conforms to this.
public protocol RiyazEntryProtocol: Sendable {
    /// Stable identifier (CloudKit record ID).
    var id: UUID { get }

    /// Date of the practice session.
    var date: Date { get }

    /// Duration of the practice session in minutes.
    var minutesPracticed: Int { get }

    /// Pitch accuracy score (0.0–1.0) for the session.
    var accuracy: Double { get }
}
