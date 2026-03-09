import SwiftUI
import SVCore

/// Root content view with 4-tab navigation.
/// Tracks tab selection events via AnalyticsManager.
struct ContentView: View {
    @State private var selectedTab = "Learn"

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Learn", systemImage: "book.fill", value: "Learn") {
                LearnTab()
            }

            Tab("Practice", systemImage: "music.note", value: "Practice") {
                PracticeTab()
            }

            Tab("Songs", systemImage: "music.note.list", value: "Songs") {
                SongsTab()
            }

            Tab("Profile", systemImage: "person.fill", value: "Profile") {
                ProfileTab()
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            AnalyticsManager.shared.track(.tabSelected, properties: ["tab": newTab])
        }
    }
}

#Preview {
    ContentView()
}
