import Foundation

/// Visual display mode for the play-along experience.
///
/// Controls which primary view is shown in `SongPlayAlongView`:
/// - Falling notes (rhythm game style, top-down approach)
/// - Scrolling sheet (traditional notation, auto-scrolling)
///
/// Persisted via `@AppStorage("playAlongViewMode")`.
enum PlayAlongViewMode: String, CaseIterable, Sendable {
    /// Falling notes visualization — notes descend toward the piano keyboard.
    case fallingNotes

    /// Scrolling notation sheet — traditional notation auto-scrolls with playback.
    case scrollingSheet

    /// Human-readable label for UI pickers.
    var label: String {
        switch self {
        case .fallingNotes: "Falling Notes"
        case .scrollingSheet: "Sheet View"
        }
    }

    /// SF Symbol icon name for each mode.
    var iconName: String {
        switch self {
        case .fallingNotes: "arrow.down.to.line"
        case .scrollingSheet: "music.note.list"
        }
    }
}
