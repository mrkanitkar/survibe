import SwiftUI
import SVCore

/// View for browsing the song library.
/// Full implementation in Sprint 2.
public struct SongLibraryView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Song Library")
                .font(.title2)
            Text("Browse and learn songs coming in Sprint 2")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .scaledPadding()
    }
}
