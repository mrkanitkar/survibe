import Foundation

/// Sort options for the lesson library list.
///
/// Each case provides a human-readable label and a sort implementation.
/// Used by `LessonLibraryViewModel` and the sort menu in `LessonLibraryView`.
enum LessonSortOption: String, CaseIterable, Identifiable {
    /// Curriculum order (ascending `orderIndex`).
    case orderIndex
    /// Difficulty ascending (easiest first).
    case difficultyAscending
    /// Difficulty descending (hardest first).
    case difficultyDescending
    /// Title A→Z.
    case titleAscending

    /// Unique identifier for `ForEach` / `Picker`.
    var id: String { rawValue }

    /// Human-readable label for the sort menu.
    var label: String {
        switch self {
        case .orderIndex: "Curriculum Order"
        case .difficultyAscending: "Easiest First"
        case .difficultyDescending: "Hardest First"
        case .titleAscending: "Title A–Z"
        }
    }

    /// SF Symbol icon for the sort menu.
    var icon: String {
        switch self {
        case .orderIndex: "list.number"
        case .difficultyAscending: "arrow.up.circle"
        case .difficultyDescending: "arrow.down.circle"
        case .titleAscending: "textformat.abc"
        }
    }

    /// Sorts an array of `LessonWithProgress` according to this option.
    ///
    /// - Parameter lessons: The unsorted lesson array.
    /// - Returns: A new array sorted per this option.
    func sorted(_ lessons: [LessonWithProgress]) -> [LessonWithProgress] {
        switch self {
        case .orderIndex:
            lessons.sorted { $0.lesson.orderIndex < $1.lesson.orderIndex }
        case .difficultyAscending:
            lessons.sorted { $0.lesson.difficulty < $1.lesson.difficulty }
        case .difficultyDescending:
            lessons.sorted { $0.lesson.difficulty > $1.lesson.difficulty }
        case .titleAscending:
            lessons.sorted {
                $0.lesson.title.localizedCaseInsensitiveCompare($1.lesson.title) == .orderedAscending
            }
        }
    }
}
