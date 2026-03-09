import SwiftUI

/// Songs tab — placeholder for song library.
struct SongsTab: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "music.note.list")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("Songs")
                    .font(.title)
                Text("Song library coming in Sprint 2")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Songs")
        }
        .accessibilityLabel("Songs tab")
    }
}

#Preview {
    SongsTab()
}
