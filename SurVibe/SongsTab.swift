import SVCore
import SwiftData
import SwiftUI

/// Songs tab — browse and play the song library.
///
/// Wraps `SongLibraryView` in a NavigationStack and creates the
/// `SongLibraryViewModel` with the current model context.
/// Navigation to `SongDetailView` is handled via `.navigationDestination`.
struct SongsTab: View {
    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SongLibraryViewModel?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    SongLibraryView()
                        .environment(viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Songs")
            .navigationDestination(for: Song.self) { song in
                SongDetailView(song: song)
            }
        }
        .accessibilityLabel(AccessibilityHelper.tabLabel(for: "Songs"))
        .onAppear {
            if viewModel == nil {
                viewModel = SongLibraryViewModel(modelContext: modelContext)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SongsTab()
        .modelContainer(for: Song.self, inMemory: true)
}
