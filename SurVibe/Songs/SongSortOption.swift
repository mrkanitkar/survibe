import Foundation

/// Sort options for the song library grid.
///
/// Each case provides a human-readable label and a sort implementation.
/// Used by `SongLibraryViewModel` and the sort menu in `SongLibraryView`.
enum SongSortOption: String, CaseIterable, Identifiable {
    /// Difficulty ascending (easiest first).
    case difficultyAscending
    /// Difficulty descending (hardest first).
    case difficultyDescending
    /// Title A→Z.
    case titleAscending
    /// Title Z→A.
    case titleDescending
    /// Most recently added first.
    case recentlyAdded
    /// Grouped by language code.
    case language

    /// Unique identifier for `ForEach` / `Picker`.
    var id: String { rawValue }

    /// Human-readable label for the sort menu.
    var label: String {
        switch self {
        case .difficultyAscending: "Easiest First"
        case .difficultyDescending: "Hardest First"
        case .titleAscending: "Title A–Z"
        case .titleDescending: "Title Z–A"
        case .recentlyAdded: "Recently Added"
        case .language: "Language"
        }
    }

    /// SF Symbol icon for the sort menu.
    var icon: String {
        switch self {
        case .difficultyAscending: "arrow.up.circle"
        case .difficultyDescending: "arrow.down.circle"
        case .titleAscending: "textformat.abc"
        case .titleDescending: "textformat.abc"
        case .recentlyAdded: "clock"
        case .language: "globe"
        }
    }

    /// Sorts an array of songs according to this option.
    ///
    /// - Parameter songs: The unsorted song array.
    /// - Returns: A new array sorted per this option.
    func sorted(_ songs: [Song]) -> [Song] {
        switch self {
        case .difficultyAscending:
            songs.sorted { $0.difficulty < $1.difficulty }
        case .difficultyDescending:
            songs.sorted { $0.difficulty > $1.difficulty }
        case .titleAscending:
            songs.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleDescending:
            songs.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .recentlyAdded:
            songs.sorted { $0.createdAt > $1.createdAt }
        case .language:
            songs.sorted { $0.language < $1.language }
        }
    }
}
