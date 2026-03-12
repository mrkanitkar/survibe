import SwiftUI

/// Horizontal scrolling filter bar for the lesson library.
///
/// Displays `FilterChip` instances for difficulty levels. When any
/// filter is active, shows a "Clear" button at the end of the scroll view.
///
/// Uses `@Environment(LessonLibraryViewModel.self)` for state.
struct LessonFilterBar: View {
    // MARK: - Properties

    @Environment(LessonLibraryViewModel.self)
    private var viewModel

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Difficulty chips
                ForEach(viewModel.availableDifficulties, id: \.self) { diff in
                    FilterChip(
                        label: difficultyLabel(for: diff),
                        isActive: viewModel.activeDifficultyFilter == diff
                    ) {
                        viewModel.toggleDifficultyFilter(diff)
                    }
                }

                // Clear button
                if viewModel.hasActiveFilters {
                    Button {
                        viewModel.clearAllFilters()
                    } label: {
                        Label("Clear", systemImage: "xmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(Text("Clear all filters"))
                    .accessibilityHint(Text("Double tap to remove all active filters"))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Private Methods

    /// Display name for a difficulty level.
    ///
    /// - Parameter difficulty: Integer difficulty (1–5).
    /// - Returns: Human-readable difficulty label.
    private func difficultyLabel(for difficulty: Int) -> String {
        switch difficulty {
        case 1: "Beginner"
        case 2: "Easy"
        case 3: "Medium"
        case 4: "Hard"
        case 5: "Expert"
        default: "Level \(difficulty)"
        }
    }
}
