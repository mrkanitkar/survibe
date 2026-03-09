import SwiftUI

/// Practice tab — placeholder for riyaz/practice sessions.
struct PracticeTab: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "music.note")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("Practice")
                    .font(.title)
                Text("Riyaz practice coming in Sprint 1")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Practice")
        }
        .accessibilityLabel("Practice tab")
    }
}

#Preview {
    PracticeTab()
}
