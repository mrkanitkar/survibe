import SwiftUI

/// Empty state view shown when no lessons match the current filters or search.
///
/// Uses `ContentUnavailableView` for a consistent Apple-standard presentation.
struct LessonLibraryEmptyState: View {
    // MARK: - Properties

    /// Whether there are active filters or search text.
    let hasActiveFilters: Bool

    /// Callback to clear all filters.
    let clearFilters: () -> Void

    // MARK: - Body

    var body: some View {
        ContentUnavailableView {
            Label(
                hasActiveFilters ? "No Lessons Found" : "No Lessons Yet",
                systemImage: hasActiveFilters ? "magnifyingglass" : "book.closed"
            )
        } description: {
            if hasActiveFilters {
                Text("Try adjusting your filters or search to find lessons.")
            } else {
                Text("Lessons will appear here once content is available.")
            }
        } actions: {
            if hasActiveFilters {
                Button("Clear Filters") {
                    clearFilters()
                }
                .accessibilityHint(Text("Double tap to clear all active filters"))
            }
        }
    }
}
