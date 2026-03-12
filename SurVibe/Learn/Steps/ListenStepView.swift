import SwiftUI

/// Displays a listening step with audio playback controls.
///
/// The learner reads instructional content and listens to audio.
/// A "Mark as Listened" button appears after a brief delay,
/// allowing the user to signal completion and unlock the next step.
///
/// Audio integration with `SongPlaybackEngine` is planned for a future sprint.
/// Currently provides a placeholder with manual completion.
struct ListenStepView: View {
    // MARK: - Properties

    /// The lesson step to display.
    let step: LessonStep

    /// Callback when the listening activity is complete.
    let onComplete: () -> Void

    @State private var hasListened = false
    @State private var showCompleteButton = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepBadge

            Text(verbatim: step.content)
                .font(.body)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let seconds = step.durationSeconds {
                durationIndicator(seconds)
            }

            // Audio placeholder
            audioPlaceholder

            // Completion button
            if showCompleteButton, !hasListened {
                Button {
                    hasListened = true
                    onComplete()
                } label: {
                    Label("Mark as Listened", systemImage: "checkmark.circle")
                        .font(.body)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .accessibilityLabel(Text("Mark as listened"))
                .accessibilityHint(Text("Double tap to confirm you have listened to the audio"))
            }

            if hasListened {
                Label("Listened", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .accessibilityLabel(Text("Audio listening completed"))
            }
        }
        .task {
            // Show the complete button after a short delay
            try? await Task.sleep(for: .seconds(3))
            showCompleteButton = true
        }
    }

    // MARK: - Subviews

    /// Badge identifying this step as a listening exercise.
    private var stepBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "headphones")
            Text("Listen")
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .foregroundStyle(.purple)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(.purple.opacity(0.15)))
        .accessibilityLabel(Text("Step type: Listen"))
    }

    /// Placeholder card for the audio playback area.
    ///
    /// Will be replaced with actual audio controls in a future sprint.
    private var audioPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 48))
                .foregroundStyle(.purple.opacity(0.5))
                .accessibilityHidden(true)

            Text("Audio Playback")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Full audio integration coming soon")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Audio playback area — full integration coming soon"))
    }

    /// Shows the estimated duration for this step.
    ///
    /// - Parameter seconds: Duration in seconds.
    /// - Returns: A label with a timer icon and formatted duration.
    private func durationIndicator(_ seconds: Int) -> some View {
        Label(formatDuration(seconds), systemImage: "timer")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    // MARK: - Private Methods

    /// Formats seconds into a human-readable duration string.
    ///
    /// - Parameter seconds: Duration in seconds.
    /// - Returns: A formatted string like "30s", "2 min", or "1m 30s".
    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        let remaining = seconds % 60
        return remaining == 0 ? "\(minutes) min" : "\(minutes)m \(remaining)s"
    }
}
