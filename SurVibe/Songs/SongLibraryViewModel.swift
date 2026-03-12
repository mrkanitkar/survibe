import Foundation
import SVCore
import SwiftData
import SwiftUI

/// View model for the song library grid view.
///
/// Manages song fetching, filtering (language, difficulty, raga, favorites),
/// searching (with debounce), and sorting. All state changes are observed
/// by `SongLibraryView` via the `@Observable` macro.
///
/// Requires a `ModelContext` for SwiftData queries.
@MainActor
@Observable
final class SongLibraryViewModel {
    // MARK: - Properties

    /// All songs fetched from SwiftData.
    private(set) var allSongs: [Song] = []

    /// Songs after applying all active filters, search, and sort.
    private(set) var filteredSongs: [Song] = []

    /// Current search text entered by the user.
    var searchText: String = "" {
        didSet {
            scheduleSearchDebounce()
        }
    }

    /// Active language filter (nil = no language filter).
    var activeLanguageFilter: String?

    /// Active difficulty filter (nil = no difficulty filter).
    var activeDifficultyFilter: Int?

    /// Active raga name filters (empty = no raga filter).
    var activeRaagFilters: Set<String> = []

    /// Whether to show only favorites.
    var showFavoritesOnly: Bool = false

    /// Current sort option.
    var sortOption: SongSortOption = .difficultyAscending

    /// Whether the initial load is in progress.
    private(set) var isLoading: Bool = false

    /// The model context for SwiftData queries.
    private let modelContext: ModelContext

    /// Task handle for search debounce.
    private var searchDebounceTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// All unique language codes from the loaded songs.
    var availableLanguages: [String] {
        Array(Set(allSongs.map(\.language))).sorted()
    }

    /// All unique difficulty levels from the loaded songs.
    var availableDifficulties: [Int] {
        Array(Set(allSongs.map(\.difficulty))).sorted()
    }

    /// All unique raga names from the loaded songs (excluding empty).
    var availableRaagas: [String] {
        Array(Set(allSongs.compactMap { $0.ragaName.isEmpty ? nil : $0.ragaName })).sorted()
    }

    /// Whether any filter is currently active.
    var hasActiveFilters: Bool {
        activeLanguageFilter != nil
            || activeDifficultyFilter != nil
            || !activeRaagFilters.isEmpty
            || showFavoritesOnly
    }

    // MARK: - Initialization

    /// Creates the view model with a SwiftData model context.
    ///
    /// - Parameter modelContext: The context used for song queries.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// Fetches all songs from SwiftData and applies current filters.
    func loadSongs() async {
        isLoading = true
        do {
            let descriptor = FetchDescriptor<Song>(
                sortBy: [SortDescriptor(\Song.sortOrder)]
            )
            allSongs = try modelContext.fetch(descriptor)
        } catch {
            allSongs = []
        }
        applyFilters()
        isLoading = false

        AnalyticsManager.shared.track(
            .songLibraryViewed,
            properties: ["song_count": allSongs.count]
        )
    }

    /// Applies all active filters, search text, and sort option.
    func applyFilters() {
        var result = allSongs

        // Language filter
        if let lang = activeLanguageFilter {
            result = result.filter { $0.language == lang }
        }

        // Difficulty filter
        if let diff = activeDifficultyFilter {
            result = result.filter { $0.difficulty == diff }
        }

        // Raga filters
        if !activeRaagFilters.isEmpty {
            result = result.filter { activeRaagFilters.contains($0.ragaName) }
        }

        // Favorites only
        if showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }

        // Search text
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            result = result.filter { song in
                song.title.localizedCaseInsensitiveContains(trimmed)
                    || song.artist.localizedCaseInsensitiveContains(trimmed)
                    || song.ragaName.localizedCaseInsensitiveContains(trimmed)
            }
        }

        // Sort
        filteredSongs = sortOption.sorted(result)
    }

    /// Toggles the language filter on/off.
    ///
    /// - Parameter language: The language code to toggle.
    func toggleLanguageFilter(_ language: String) {
        if activeLanguageFilter == language {
            activeLanguageFilter = nil
        } else {
            activeLanguageFilter = language
        }
        applyFilters()
        AnalyticsManager.shared.track(
            .songFilterApplied,
            properties: ["filter_type": "language", "value": language]
        )
    }

    /// Toggles the difficulty filter on/off.
    ///
    /// - Parameter difficulty: The difficulty level to toggle.
    func toggleDifficultyFilter(_ difficulty: Int) {
        if activeDifficultyFilter == difficulty {
            activeDifficultyFilter = nil
        } else {
            activeDifficultyFilter = difficulty
        }
        applyFilters()
        AnalyticsManager.shared.track(
            .songFilterApplied,
            properties: ["filter_type": "difficulty", "value": difficulty]
        )
    }

    /// Toggles a raga filter on/off.
    ///
    /// - Parameter raag: The raga name to toggle.
    func toggleRaagFilter(_ raag: String) {
        if activeRaagFilters.contains(raag) {
            activeRaagFilters.remove(raag)
        } else {
            activeRaagFilters.insert(raag)
        }
        applyFilters()
        AnalyticsManager.shared.track(
            .songFilterApplied,
            properties: ["filter_type": "raag", "value": raag]
        )
    }

    /// Toggles the favorites-only filter.
    func toggleFavorites() {
        showFavoritesOnly.toggle()
        applyFilters()
        AnalyticsManager.shared.track(
            .songFilterApplied,
            properties: ["filter_type": "favorites", "value": showFavoritesOnly]
        )
    }

    /// Clears all active filters and reapplies sort.
    func clearAllFilters() {
        activeLanguageFilter = nil
        activeDifficultyFilter = nil
        activeRaagFilters.removeAll()
        showFavoritesOnly = false
        searchText = ""
        applyFilters()
    }

    /// Updates the sort option and reapplies filters.
    ///
    /// - Parameter option: The new sort option.
    func updateSort(_ option: SongSortOption) {
        sortOption = option
        applyFilters()
    }

    /// Toggles the favorite state for a song.
    ///
    /// - Parameter song: The song to toggle.
    func toggleFavorite(_ song: Song) {
        song.isFavorite.toggle()
        applyFilters()
        AnalyticsManager.shared.track(
            .songFavoriteToggled,
            properties: [
                "song_slug": song.slugId,
                "is_favorite": song.isFavorite,
            ]
        )
    }

    /// Whether a song is premium-locked (not free and user is not authenticated).
    ///
    /// - Parameter song: The song to check.
    /// - Returns: `true` if the song requires authentication to play.
    func isPremiumLocked(_ song: Song) -> Bool {
        !song.isFree && !AuthManager.shared.isAuthenticated
    }

    // MARK: - Private Methods

    /// Debounces search text changes by 300ms.
    private func scheduleSearchDebounce() {
        searchDebounceTask?.cancel()
        searchDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            applyFilters()

            let trimmed = searchText.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                AnalyticsManager.shared.track(
                    .songSearchPerformed,
                    properties: ["query_length": trimmed.count]
                )
            }
        }
    }
}
