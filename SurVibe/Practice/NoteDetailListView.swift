import SwiftUI
import SVLearning

/// Displays per-note grade details from a completed practice session.
///
/// Each note attempt is shown as an expandable row with grade icon, expected
/// and detected note names, and accuracy percentage. Tapping a row reveals
/// detailed deviation metrics (pitch, timing, duration). A filter toggle
/// allows showing only mistakes (grades of `.fair` or `.miss`).
struct NoteDetailListView: View {
    /// The note scores to display, one per note attempt.
    let noteScores: [NoteScore]

    /// When true, only notes graded `.fair` or `.miss` are shown.
    @State private var showMistakesOnly: Bool = false

    /// Tracks which disclosure groups are expanded, keyed by note score ID.
    @State private var expandedNoteIDs: Set<UUID> = []

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            if noteScores.isEmpty {
                emptyState
            } else {
                filterToggle
                noteList
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Filtered Scores

    /// Scores filtered by the current mistake-only toggle state.
    ///
    /// When `showMistakesOnly` is true, returns only scores with grade
    /// `.miss` or `.fair`. Otherwise returns all scores.
    private var filteredScores: [NoteScore] {
        if showMistakesOnly {
            return noteScores.filter { $0.grade == .miss || $0.grade == .fair }
        }
        return noteScores
    }

    // MARK: - Empty State

    /// Placeholder shown when no note scores exist.
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("No notes scored yet")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No notes scored yet")
    }

    // MARK: - Filter Toggle

    /// Toggle to filter the list to only mistake notes.
    private var filterToggle: some View {
        Toggle(isOn: $showMistakesOnly) {
            Label("Show mistakes only", systemImage: "line.3.horizontal.decrease.circle")
        }
        .padding(.vertical, 4)
        .accessibilityLabel("Filter notes")
        .accessibilityHint("Show only notes graded fair or miss")
    }

    // MARK: - Note List

    /// The scrollable list of note score rows, or an all-correct message.
    private var noteList: some View {
        Group {
            if filteredScores.isEmpty && showMistakesOnly {
                allCorrectMessage
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(filteredScores.enumerated()), id: \.element.id) { index, score in
                        noteRow(
                            score: score,
                            displayIndex: displayIndex(for: score)
                        )
                    }
                }
            }
        }
    }

    // MARK: - All Correct Message

    /// Message shown when the filter is active but no mistakes exist.
    private var allCorrectMessage: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            Text("All notes scored correctly!")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("All notes scored correctly")
    }

    // MARK: - Note Row

    /// A single expandable note score row.
    ///
    /// Shows the note index, grade icon, expected/detected notes, and accuracy.
    /// Expanding the row reveals pitch deviation, timing deviation, and
    /// duration deviation details.
    ///
    /// - Parameters:
    ///   - score: The note score to display.
    ///   - displayIndex: The 1-based index of this note in the full list.
    /// - Returns: A disclosure group view for the note score.
    private func noteRow(score: NoteScore, displayIndex: Int) -> some View {
        let isExpanded = Binding<Bool>(
            get: { expandedNoteIDs.contains(score.id) },
            set: { newValue in
                if newValue {
                    expandedNoteIDs.insert(score.id)
                } else {
                    expandedNoteIDs.remove(score.id)
                }
            }
        )

        return DisclosureGroup(isExpanded: isExpanded) {
            noteDetailContent(score: score)
        } label: {
            noteRowLabel(score: score, displayIndex: displayIndex)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.quaternary.opacity(0.5))
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "Note \(displayIndex), \(score.expectedNote), "
                + "grade \(score.grade.rawValue), "
                + "accuracy \(Int(score.accuracy * 100)) percent"
        )
        .accessibilityHint("Tap to expand deviation details")
    }

    // MARK: - Note Row Label

    /// The summary label for a note row showing index, grade, notes, and accuracy.
    ///
    /// - Parameters:
    ///   - score: The note score to display.
    ///   - displayIndex: The 1-based display index.
    /// - Returns: The label view for the disclosure group.
    private func noteRowLabel(score: NoteScore, displayIndex: Int) -> some View {
        HStack(spacing: 10) {
            Text("\(displayIndex)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Image(systemName: score.grade.sfSymbol)
                .foregroundStyle(score.grade.color)
                .imageScale(.medium)
                .accessibilityHidden(true)

            Text(score.expectedNote)
                .font(.body.bold())

            Text(score.detectedNote ?? "\u{2014}")
                .font(.body)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(Int(score.accuracy * 100))%")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(score.grade.color)
        }
    }

    // MARK: - Note Detail Content

    /// The expanded detail section showing deviation metrics.
    ///
    /// Displays pitch deviation in cents, timing deviation in seconds,
    /// and duration deviation as a percentage.
    ///
    /// - Parameter score: The note score whose details to display.
    /// - Returns: A view with the three deviation metrics.
    private func noteDetailContent(score: NoteScore) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            deviationRow(
                label: "Pitch deviation",
                value: String(format: "%.1f cents", score.pitchDeviationCents)
            )
            deviationRow(
                label: "Timing deviation",
                value: String(format: "%.3f s", score.timingDeviationSeconds)
            )
            deviationRow(
                label: "Duration deviation",
                value: String(format: "%.1f%%", score.durationDeviation * 100)
            )
        }
        .padding(.top, 6)
        .font(.caption)
    }

    // MARK: - Deviation Row

    /// A single row within the expanded detail section.
    ///
    /// - Parameters:
    ///   - label: The metric name (e.g., "Pitch deviation").
    ///   - value: The formatted metric value (e.g., "12.5 cents").
    /// - Returns: A horizontal stack with the label and value.
    private func deviationRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Helpers

    /// Compute the 1-based display index for a score within the full note list.
    ///
    /// When filtering is active, the display index still reflects the note's
    /// original position in the unfiltered list so users can correlate with
    /// the song's notation.
    ///
    /// - Parameter score: The note score to look up.
    /// - Returns: The 1-based index in the original `noteScores` array.
    private func displayIndex(for score: NoteScore) -> Int {
        guard let index = noteScores.firstIndex(where: { $0.id == score.id }) else {
            return 0
        }
        return index + 1
    }
}
