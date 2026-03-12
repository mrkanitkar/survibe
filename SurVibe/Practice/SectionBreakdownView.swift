import SVLearning
import SwiftUI

/// Section-by-section scoring breakdown displayed after a practice session.
///
/// Computes section scores from an array of `NoteScore` values using
/// `SectionScorer`, then displays them sorted weakest-first so the
/// player can focus on areas needing the most improvement. Each section
/// card shows the grade badge, accuracy bar, percentage, and note range.
struct SectionBreakdownView: View {
    /// Individual note scores from the completed practice session.
    let noteScores: [NoteScore]

    /// Number of notes per section (default: 4).
    var sectionSize: Int = SectionScorer.defaultSectionSize

    // MARK: - Computed Properties

    /// Section scores computed from note scores and sorted weakest-first.
    private var sortedSections: [SectionScore] {
        let sections = SectionScorer.scoreSections(
            scores: noteScores,
            sectionSize: sectionSize
        )
        return SectionScorer.weakestFirst(sections: sections)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView

            if noteScores.isEmpty {
                emptyStateView
            } else {
                sectionListView
            }
        }
    }

    // MARK: - Header

    /// Section header with title and subtitle.
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Section Breakdown")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)

            if !noteScores.isEmpty {
                Text("Weakest sections shown first")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Empty State

    /// Placeholder displayed when no note scores are available.
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)

            Text("No notes scored yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No notes scored yet")
    }

    // MARK: - Section List

    /// Lazy vertical stack of section cards.
    private var sectionListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(sortedSections) { section in
                sectionCard(for: section)
            }
        }
    }

    // MARK: - Section Card

    /// Card displaying a single section's score, grade, and accuracy.
    ///
    /// Shows the section label, grade badge icon, an accuracy progress bar,
    /// the percentage value, and the note range covered by this section.
    ///
    /// - Parameter section: The section score to render.
    /// - Returns: A styled card view for the section.
    private func sectionCard(for section: SectionScore) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: section label + grade badge
            HStack {
                Text("Section \(section.sectionIndex + 1)")
                    .font(.headline)

                Spacer()

                gradeBadge(for: section.grade)
            }

            // Accuracy bar
            accuracyBar(accuracy: section.accuracy, grade: section.grade)

            // Bottom row: percentage + note range
            HStack {
                Text(formattedPercentage(section.accuracy))
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(section.grade.color)

                Spacer()

                Text(noteRangeLabel(for: section.noteRange))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(sectionAccessibilityLabel(for: section))
    }

    // MARK: - Grade Badge

    /// Circular badge displaying the grade's SF Symbol and color.
    ///
    /// - Parameter grade: The note grade to represent.
    /// - Returns: An icon view colored by the grade.
    private func gradeBadge(for grade: NoteGrade) -> some View {
        Image(systemName: grade.sfSymbol)
            .font(.title3)
            .foregroundStyle(grade.color)
            .accessibilityHidden(true)
    }

    // MARK: - Accuracy Bar

    /// Horizontal progress bar showing the section's accuracy.
    ///
    /// Uses a `ProgressView` styled with the grade's color to provide
    /// a visual representation of how well the section was performed.
    ///
    /// - Parameters:
    ///   - accuracy: Accuracy value between 0.0 and 1.0.
    ///   - grade: The grade used to determine the bar's tint color.
    /// - Returns: A tinted progress bar view.
    private func accuracyBar(accuracy: Double, grade: NoteGrade) -> some View {
        ProgressView(value: max(0, min(1, accuracy)))
            .tint(grade.color)
            .accessibilityHidden(true)
    }

    // MARK: - Helpers

    /// Format an accuracy value as a percentage string.
    ///
    /// - Parameter accuracy: Accuracy between 0.0 and 1.0.
    /// - Returns: Formatted string such as "85%".
    private func formattedPercentage(_ accuracy: Double) -> String {
        "\(Int(accuracy * 100))%"
    }

    /// Build a human-readable note range label.
    ///
    /// Converts a `Range<Int>` into a display string like "Notes 1-4".
    /// Uses 1-based indexing for user-facing display.
    ///
    /// - Parameter range: Zero-based note range from `SectionScore`.
    /// - Returns: Formatted label such as "Notes 1-4".
    private func noteRangeLabel(for range: Range<Int>) -> String {
        let start = range.lowerBound + 1
        let end = range.upperBound
        return "Notes \(start)-\(end)"
    }

    /// Build a VoiceOver accessibility label for a section card.
    ///
    /// Combines the section number, grade, accuracy, and note range
    /// into a single descriptive string for screen reader users.
    ///
    /// - Parameter section: The section score.
    /// - Returns: Accessibility label string.
    private func sectionAccessibilityLabel(for section: SectionScore) -> String {
        let sectionNumber = section.sectionIndex + 1
        let percentage = Int(section.accuracy * 100)
        let noteRange = noteRangeLabel(for: section.noteRange)
        return "Section \(sectionNumber), \(section.grade.rawValue), \(percentage) percent accuracy, \(noteRange)"
    }
}

// MARK: - Previews

#Preview("With Scores") {
    ScrollView {
        SectionBreakdownView(
            noteScores: previewNoteScores()
        )
        .padding()
    }
}

#Preview("Empty State") {
    SectionBreakdownView(noteScores: [])
        .padding()
}

/// Generate sample note scores for Xcode previews.
///
/// Creates a sequence of notes with varying accuracy levels
/// to demonstrate the section breakdown layout.
///
/// - Returns: Array of sample `NoteScore` values.
private func previewNoteScores() -> [NoteScore] {
    let accuracies: [Double] = [
        0.95, 0.88, 0.92, 0.75,
        0.60, 0.55, 0.45, 0.70,
        0.80, 0.85, 0.90, 0.95,
    ]
    return accuracies.enumerated().map { index, accuracy in
        NoteScore(
            grade: NoteGrade.from(accuracy: accuracy),
            accuracy: accuracy,
            pitchDeviationCents: (1.0 - accuracy) * 50,
            timingDeviationSeconds: (1.0 - accuracy) * 0.2,
            durationDeviation: (1.0 - accuracy) * 0.3,
            expectedNote: ["Sa", "Re", "Ga", "Ma", "Pa", "Dha"][index % 6]
        )
    }
}
