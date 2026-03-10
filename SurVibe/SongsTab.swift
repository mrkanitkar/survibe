import SVCore
import SwiftUI

/// Songs tab — placeholder for song library.
struct SongsTab: View {
    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "music.note.list")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text("Songs")
                    .font(.title)
                Text("Song library coming in Sprint 2")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Songs")
        }
        .accessibilityLabel(AccessibilityHelper.tabLabel(for: "Songs"))
    }
}

#Preview {
    SongsTab()
}
