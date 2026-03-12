import SwiftUI

/// Empty state view for the song library.
///
/// Displays two distinct modes:
/// - **No songs at all**: Shows a general "no songs" message.
/// - **No matching filters**: Shows a "no results" message with a "Clear Filters" button.
struct SongLibraryEmptyState: View {
    // MARK: - Properties

    /// Whether filters are currently active (determines which message to show).
    let hasActiveFilters: Bool

    /// Action to clear all active filters.
    var clearFiltersAction: (() -> Void)?

    // MARK: - Body

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(description)
        } actions: {
            if hasActiveFilters, let clearFiltersAction {
                Button("Clear Filters") {
                    clearFiltersAction()
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(Text("Clear Filters"))
                .accessibilityHint(Text("Double tap to remove all filters and show all songs"))
            }
        }
    }

    // MARK: - Private Methods

    /// Title for the empty state.
    private var title: String {
        hasActiveFilters ? "No Matching Songs" : "No Songs Yet"
    }

    /// SF Symbol for the empty state.
    private var icon: String {
        hasActiveFilters ? "magnifyingglass" : "music.note"
    }

    /// Description for the empty state.
    private var description: String {
        if hasActiveFilters {
            "Try adjusting your filters or search terms to find more songs."
        } else {
            "Songs will appear here once content is loaded."
        }
    }
}

// MARK: - Preview

#Preview("No Songs") {
    SongLibraryEmptyState(hasActiveFilters: false)
}

#Preview("No Matches") {
    SongLibraryEmptyState(hasActiveFilters: true, clearFiltersAction: {})
}
