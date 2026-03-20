import SVLearning
import SwiftUI

/// Heads-up display overlay showing live practice stats.
///
/// Displays accuracy percentage, current streak count, note progress,
/// and elapsed time during the practice-along phase. Rendered as a
/// compact horizontal bar with an ultra-thin material background.
struct PracticeHUD: View {
    let viewModel: PracticeSessionViewModel

    var body: some View {
        HStack {
            // Accuracy
            VStack(alignment: .leading, spacing: 2) {
                Text("Accuracy")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(accuracyText)
                    .font(.headline.monospacedDigit())
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Accuracy \(accuracyText)")

            Spacer()

            // Streak
            VStack(spacing: 2) {
                Text("Streak")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(currentStreak)")
                    .font(.headline.monospacedDigit())
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Current streak \(currentStreak)")

            Spacer()

            // Progress
            VStack(spacing: 2) {
                Text("Progress")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(progressText)
                    .font(.headline.monospacedDigit())
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Progress \(progressText)")

            Spacer()

            // Elapsed time
            VStack(alignment: .trailing, spacing: 2) {
                Text("Time")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(formattedTime)
                    .font(.headline.monospacedDigit())
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Elapsed time \(formattedTime)")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Computed Properties

    /// Formatted accuracy percentage or a dash when no scores exist.
    ///
    /// AUD-017: Reads `liveAccuracySum` (maintained incrementally in ViewModel)
    /// instead of calling `PracticeScoring.averageAccuracy` (O(n) reduce) per render.
    private var accuracyText: String {
        let count = viewModel.noteScores.count
        guard count > 0 else { return "\u{2014}" }
        let avg = viewModel.liveAccuracySum / Double(count)
        return "\(Int(avg * 100))%"
    }

    /// Current consecutive non-miss streak.
    ///
    /// AUD-017: Reads `liveStreak` (maintained incrementally in ViewModel)
    /// instead of calling `PracticeScoring.longestStreak` (O(n) walk) per render.
    private var currentStreak: Int {
        viewModel.liveStreak
    }

    /// Current note index out of total notes (e.g., "3/12").
    private var progressText: String {
        let total = viewModel.sargamNotes.count
        guard total > 0 else { return "0/0" }
        return "\(viewModel.currentPracticeNoteIndex)/\(total)"
    }

    /// Elapsed practice time formatted as M:SS.
    private var formattedTime: String {
        let totalSeconds = Int(viewModel.elapsedPracticeTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
