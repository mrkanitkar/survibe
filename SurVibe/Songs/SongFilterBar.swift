import SwiftUI

/// Horizontal scrolling filter bar for the song library.
///
/// Displays `FilterChip` instances for favorites, language, difficulty,
/// and raga filters. When any filter is active, shows a "Clear" button
/// at the end of the scroll view.
///
/// Uses `@Environment(SongLibraryViewModel.self)` for state.
struct SongFilterBar: View {
    // MARK: - Properties

    @Environment(SongLibraryViewModel.self) private var viewModel

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Favorites chip
                FilterChip(
                    label: "Favorites",
                    icon: "heart.fill",
                    isActive: viewModel.showFavoritesOnly
                ) {
                    viewModel.toggleFavorites()
                }

                // Language chips
                ForEach(viewModel.availableLanguages, id: \.self) { lang in
                    FilterChip(
                        label: languageLabel(for: lang),
                        isActive: viewModel.activeLanguageFilter == lang
                    ) {
                        viewModel.toggleLanguageFilter(lang)
                    }
                }

                // Difficulty chips
                ForEach(viewModel.availableDifficulties, id: \.self) { diff in
                    FilterChip(
                        label: difficultyLabel(for: diff),
                        isActive: viewModel.activeDifficultyFilter == diff
                    ) {
                        viewModel.toggleDifficultyFilter(diff)
                    }
                }

                // Raga chips (if any ragas available)
                ForEach(viewModel.availableRaagas, id: \.self) { raag in
                    FilterChip(
                        label: raag,
                        isActive: viewModel.activeRaagFilters.contains(raag)
                    ) {
                        viewModel.toggleRaagFilter(raag)
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

    /// Display name for a language code.
    ///
    /// - Parameter code: ISO 639-1 language code.
    /// - Returns: Human-readable language name.
    private func languageLabel(for code: String) -> String {
        switch code {
        case "hi": "Hindi"
        case "mr": "Marathi"
        case "en": "English"
        default: code.uppercased()
        }
    }

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
