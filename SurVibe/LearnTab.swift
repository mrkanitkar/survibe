import SwiftUI

/// Learn tab — placeholder for lesson content.
struct LearnTab: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "book.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("Learn")
                    .font(.title)
                Text("Lessons and courses coming in Sprint 1")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Learn")
        }
        .accessibilityLabel("Learn tab")
    }
}

#Preview {
    LearnTab()
}
