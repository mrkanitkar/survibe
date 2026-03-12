import Foundation

/// Display mode for notation rendering.
///
/// Persisted via @AppStorage as a String rawValue.
/// Controls whether the notation view shows Sargam notation,
/// Western notation, staff (sheet music), or combinations.
///
/// ## Raw Value Stability
/// Existing cases (`.sargam`, `.western`, `.dual`) keep their raw values
/// to avoid breaking OnboardingManager and AppStorage persistence.
enum NotationDisplayMode: String, CaseIterable, Sendable {
    /// Indian classical Sargam notation only.
    case sargam
    /// Western note labels only.
    case western
    /// Both Sargam and Western stacked vertically.
    case dual
    /// Standard 5-line staff (sheet music) notation.
    case sheetMusic
    /// Sargam notation stacked above staff notation.
    case sargamPlusSheet

    /// Human-readable label for UI display.
    var label: String {
        switch self {
        case .sargam: "Sargam"
        case .western: "Western"
        case .dual: "Both"
        case .sheetMusic: "Sheet Music"
        case .sargamPlusSheet: "Sargam + Sheet"
        }
    }

    /// SF Symbol name for each mode (used in pickers and onboarding).
    var iconName: String {
        switch self {
        case .sargam: "character.textbox"
        case .western: "music.note"
        case .dual: "rectangle.split.1x2"
        case .sheetMusic: "music.note.list"
        case .sargamPlusSheet: "rectangle.split.1x2.fill"
        }
    }
}
