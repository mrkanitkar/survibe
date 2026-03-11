import SVCore
import SwiftData
import SwiftUI

/// Songs tab — browse and play the song library.
///
/// Displays all songs from the SwiftData store sorted by display order.
/// When the library is empty, shows a `ContentUnavailableView` placeholder.
/// Tapping a song row navigates to `SongDetailView` for metadata
/// inspection and playback.
struct SongsTab: View {
    // MARK: - Properties

    /// All songs from SwiftData, sorted by display order.
    @Query(sort: \Song.sortOrder)
    private var songs: [Song]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if songs.isEmpty {
                    ContentUnavailableView(
                        "No Songs Yet",
                        systemImage: "music.note.list",
                        description: Text("Songs will appear here once content is loaded.")
                    )
                } else {
                    List(songs) { song in
                        NavigationLink(value: song) {
                            SongListRow(song: song)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Songs")
            .navigationDestination(for: Song.self) { song in
                SongDetailView(song: song)
            }
        }
        .accessibilityLabel(AccessibilityHelper.tabLabel(for: "Songs"))
    }
}

// MARK: - Preview

#Preview {
    SongsTab()
        .modelContainer(for: Song.self, inMemory: true)
}
