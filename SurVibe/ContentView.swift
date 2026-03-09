import SwiftUI

/// Root content view with 4-tab navigation.
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Learn", systemImage: "book.fill") {
                LearnTab()
            }

            Tab("Practice", systemImage: "music.note") {
                PracticeTab()
            }

            Tab("Songs", systemImage: "music.note.list") {
                SongsTab()
            }

            Tab("Profile", systemImage: "person.fill") {
                ProfileTab()
            }
        }
    }
}

#Preview {
    ContentView()
}
