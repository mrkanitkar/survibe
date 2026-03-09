import SwiftUI
import SVCore

/// Practice tab — placeholder for riyaz/practice sessions.
/// Will integrate PitchDetector and real-time feedback in Sprint 1.
struct PracticeTab: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.md) {
                Image(systemName: "music.note")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("Practice")
                    .font(.title)
                Text("Riyaz practice coming in Sprint 1")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Pitch detection pipeline ready")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .navigationTitle("Practice")
        }
        .accessibilityLabel(AccessibilityHelper.tabLabel(for: "Practice"))
    }
}

#Preview {
    PracticeTab()
}
