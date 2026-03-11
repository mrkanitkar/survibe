import Foundation

/// Display mode for notation rendering.
///
/// Persisted via @AppStorage as a String rawValue.
/// Controls whether the notation view shows Sargam notation,
/// Western notation, or both side-by-side.
enum NotationDisplayMode: String, CaseIterable, Sendable {
    /// Indian classical Sargam notation only.
    case sargam
    /// Western staff/note notation only.
    case western
    /// Both Sargam and Western stacked vertically.
    case dual

    /// Human-readable label for UI display.
    var label: String {
        switch self {
        case .sargam: "Sargam"
        case .western: "Western"
        case .dual: "Both"
        }
    }
}
