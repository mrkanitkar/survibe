import SwiftUI

/// Displays a sing-along step with practice controls.
///
/// The learner practices singing along with the lesson content.
/// A "Skip to Next" button appears after 10 seconds as a fallback.
/// The "Done Singing" button signals completion with a placeholder accuracy.
///
/// Full pitch detection integration via `PracticeSessionViewModel` is planned
/// for a future sprint. Currently provides manual completion.
struct SingStepView: View {
    // MARK: - Properties

    /// The lesson step to display.
    let step: LessonStep

    /// Callback when singing is complete, with accuracy (0.0-1.0).
    let onComplete: (Double) -> Void

    /// Callback when user manually skips past the singing exercise.
    let onManualAdvance: () -> Void

    @State private var showSkipButton = false
    @State private var hasCompleted = false

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

            // Practice placeholder
            practicePlaceholder

            if !hasCompleted {
                HStack(spacing: 12) {
                    if showSkipButton {
                        Button {
                            hasCompleted = true
                            onManualAdvance()
                        } label: {
                            Text("Skip")
                                .font(.body)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel(Text("Skip singing exercise"))
                        .accessibilityHint(Text("Double tap to skip to the next step"))
                    }

                    Button {
                        hasCompleted = true
                        onComplete(1.0) // Placeholder accuracy
                    } label: {
                        Label("Done Singing", systemImage: "checkmark.circle")
                            .font(.body)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                    .accessibilityLabel(Text("Done singing"))
                    .accessibilityHint(Text("Double tap to mark the singing exercise as complete"))
                }
            }

            if hasCompleted {
                Label("Singing Complete", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .accessibilityLabel(Text("Singing exercise completed"))
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(10))
            showSkipButton = true
        }
    }

    // MARK: - Subviews

    /// Badge identifying this step as a sing-along exercise.
    private var stepBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "waveform")
            Text("Sing Along")
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .foregroundStyle(.pink)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(.pink.opacity(0.15)))
        .accessibilityLabel(Text("Step type: Sing Along"))
    }

    /// Placeholder card for the singing practice area.
    ///
    /// Will be replaced with actual pitch detection controls in a future sprint.
    private var practicePlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.mic")
                .font(.system(size: 48))
                .foregroundStyle(.pink.opacity(0.5))
                .accessibilityHidden(true)

            Text("Sing Along Mode")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Pitch detection integration coming soon")
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
        .accessibilityLabel(Text("Sing along area — pitch detection coming soon"))
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
