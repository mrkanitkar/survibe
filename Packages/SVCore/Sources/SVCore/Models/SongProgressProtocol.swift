import Foundation

/// Protocol for per-song progress tracking.
///
/// **CloudKit sync:** `bestScore` and `timesPlayed` use highwater-mark conflict
/// resolution (higher value wins). This ensures a sync conflict never lowers
/// a player's best score or erases play count.
///
/// The concrete `SongProgress` SwiftData model in the main app target conforms to this.
public protocol SongProgressProtocol: Sendable {
    /// Stable identifier (CloudKit record ID).
    var id: UUID { get }

    /// Unique song identifier matching the song catalog.
    var songId: String { get }

    /// Highest score achieved on this song (0–100). Uses highwater-mark sync.
    var bestScore: Int { get }

    /// Total number of times this song has been played. Uses highwater-mark sync.
    var timesPlayed: Int { get }
}
