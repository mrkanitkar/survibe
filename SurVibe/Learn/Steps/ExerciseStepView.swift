import SwiftUI

/// Displays an exercise step with drill controls.
///
/// The learner practices specific musical exercises. A "Mark as Complete"
/// button allows manual completion after a brief delay to encourage
/// the learner to read the instructions first.
///
/// Full drill integration via `WaitModeEngine` is planned for a future sprint.
/// Currently provides manual completion.
struct ExerciseStepView: View {
    // MARK: - Properties

    /// The lesson step to display.
    let step: LessonStep

    /// Callback when the exercise is complete.
    let onComplete: () -> Void

    @State private var hasCompleted = false
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

            // Exercise placeholder
            exercisePlaceholder

            if showCompleteButton, !hasCompleted {
                Button {
                    hasCompleted = true
                    onComplete()
                } label: {
                    Label("Mark as Complete", systemImage: "checkmark.circle")
                        .font(.body)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .accessibilityLabel(Text("Mark exercise as complete"))
                .accessibilityHint(Text("Double tap to confirm you have completed the exercise"))
            }

            if hasCompleted {
                Label("Exercise Complete", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .accessibilityLabel(Text("Exercise completed"))
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(5))
            showCompleteButton = true
        }
    }

    // MARK: - Subviews

    /// Badge identifying this step as an exercise.
    private var stepBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.tap")
            Text("Exercise")
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .foregroundStyle(.green)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(.green.opacity(0.15)))
        .accessibilityLabel(Text("Step type: Exercise"))
    }

    /// Placeholder card for the exercise drill area.
    ///
    /// Will be replaced with actual drill controls in a future sprint.
    private var exercisePlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green.opacity(0.5))
                .accessibilityHidden(true)

            Text("Interactive Exercise")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Drill mode integration coming soon")
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
        .accessibilityLabel(Text("Exercise area — drill mode coming soon"))
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
