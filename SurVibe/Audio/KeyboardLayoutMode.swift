import Foundation

/// Layout mode for the interactive keyboard in PracticeTab.
///
/// - `.piano`: Traditional piano layout with black and white keys (C2–C7).
/// - `.isomorphic`: Equal-sized rectangular keys in chromatic order, colored by swar.
enum KeyboardLayoutMode: String, CaseIterable, Sendable {
    case piano
    case isomorphic

    /// Display name for UI pickers.
    var displayName: String {
        switch self {
        case .piano: "Piano"
        case .isomorphic: "Sargam"
        }
    }

    /// SF Symbol for mode toggle button.
    var systemImage: String {
        switch self {
        case .piano: "pianokeys"
        case .isomorphic: "rectangle.grid.1x2"
        }
    }
}
