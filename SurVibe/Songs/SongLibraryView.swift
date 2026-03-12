import SVCore
import SwiftUI

/// The main song library grid view with search, filters, and sort.
///
/// Displays songs in a 2-column adaptive grid with a search bar, filter bar,
/// sort menu, and song count badge. Premium-locked songs show a sign-in
/// prompt sheet when tapped.
///
/// Receives `SongLibraryViewModel` via the SwiftUI environment.
struct SongLibraryView: View {
    // MARK: - Properties

    @Environment(SongLibraryViewModel.self) private var viewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Controls the sign-in prompt sheet for premium songs.
    @State private var signInTrigger: SignInTrigger?

    /// Two-column adaptive grid.
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16),
    ]

    // MARK: - Body

    var body: some View {
        @Bindable var vm = viewModel

        VStack(spacing: 0) {
            // Filter bar
            SongFilterBar()

            // Content area
            if viewModel.isLoading {
                loadingState
            } else if viewModel.filteredSongs.isEmpty {
                SongLibraryEmptyState(
                    hasActiveFilters: viewModel.hasActiveFilters,
                    clearFiltersAction: { viewModel.clearAllFilters() }
                )
            } else {
                songGrid
            }
        }
        .searchable(text: $vm.searchText, prompt: Text("Search songs, artists, ragas..."))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                sortMenu
            }

            ToolbarItem(placement: .topBarTrailing) {
                songCountBadge
            }
        }
        .sheet(item: $signInTrigger) { trigger in
            SignInPromptView(trigger: trigger)
        }
        .task {
            await viewModel.loadSongs()
        }
    }

    // MARK: - Subviews

    /// Song grid with 2-column adaptive layout.
    private var songGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.filteredSongs) { song in
                    if viewModel.isPremiumLocked(song) {
                        SongCardView(song: song)
                            .onTapGesture {
                                signInTrigger = .premiumSong
                            }
                    } else {
                        NavigationLink(value: song) {
                            SongCardView(song: song)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
    }

    /// Loading state with shimmer placeholders.
    private var loadingState: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(0..<6, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 200)
                        .shimmer()
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    /// Sort menu in the toolbar.
    private var sortMenu: some View {
        Menu {
            ForEach(SongSortOption.allCases) { option in
                Button {
                    viewModel.updateSort(option)
                } label: {
                    Label(option.label, systemImage: option.icon)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .accessibilityLabel(Text("Sort songs"))
                .accessibilityHint(Text("Double tap to choose a sort order"))
        }
    }

    /// Song count badge in the toolbar.
    private var songCountBadge: some View {
        Text(verbatim: "\(viewModel.filteredSongs.count)")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(.tertiarySystemBackground))
            )
            .accessibilityLabel(Text("\(viewModel.filteredSongs.count) songs"))
    }
}
