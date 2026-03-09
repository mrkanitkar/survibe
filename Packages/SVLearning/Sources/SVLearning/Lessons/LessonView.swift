import SwiftUI
import SVCore

/// View for displaying a single lesson.
/// Full implementation in Sprint 1.
public struct LessonView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "music.note.tv")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Lesson Content")
                .font(.title2)
            Text("Coming in Sprint 1")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .scaledPadding()
    }
}
