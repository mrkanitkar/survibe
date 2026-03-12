import SVAudio
import SVLearning
import SwiftUI

/// Practice-along phase view with notation, pitch feedback, and controls.
///
/// Highlights the current note to play, shows real-time pitch detection
/// feedback, and provides controls for metronome and session management.
/// The horizontal notation strip auto-scrolls to keep the active note
/// centered using `ScrollViewReader`.
struct PracticeAlongView: View {
    let viewModel: PracticeSessionViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // HUD overlay
            PracticeHUD(viewModel: viewModel)
                .padding(.horizontal)
                .padding(.top, 4)

            // Current note display
            currentNoteSection
                .padding()

            // Notation scroll
            notationScrollView
                .frame(maxHeight: .infinity)

            // Detected pitch feedback
            pitchFeedbackSection
                .padding()

            // Controls
            controlsSection
                .padding(.horizontal)
                .padding(.bottom)
        }
    }

    // MARK: - Sections

    /// The currently expected note, displayed prominently.
    private var currentNoteSection: some View {
        VStack(spacing: 8) {
            if viewModel.currentPracticeNoteIndex < viewModel.sargamNotes.count {
                let note = viewModel.sargamNotes[viewModel.currentPracticeNoteIndex]
                Text(noteDisplayName(note))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Play \(noteDisplayName(note))")

                Text("Octave \(note.octave)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Done!")
                    .font(.title)
                    .foregroundStyle(.green)
                    .accessibilityLabel("All notes completed")
            }
        }
    }

    /// Scrollable sargam notation with the current note highlighted.
    private var notationScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(
                        Array(viewModel.sargamNotes.enumerated()),
                        id: \.offset
                    ) { index, note in
                        noteCell(index: index, note: note)
                            .id(index)
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: viewModel.currentPracticeNoteIndex) { _, newIndex in
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    /// A single note cell in the horizontal notation strip.
    ///
    /// - Parameters:
    ///   - index: Position in the sargam notes array.
    ///   - note: The sargam note to display.
    /// - Returns: A styled VStack for this note.
    private func noteCell(index: Int, note: SargamNote) -> some View {
        VStack(spacing: 4) {
            Text(noteDisplayName(note))
                .font(.body.monospaced())
                .fontWeight(
                    index == viewModel.currentPracticeNoteIndex ? .bold : .regular
                )

            // Show grade badge if scored
            if index < viewModel.noteScores.count {
                Image(systemName: viewModel.noteScores[index].grade.sfSymbol)
                    .font(.caption)
                    .foregroundStyle(viewModel.noteScores[index].grade.color)
                    .accessibilityLabel(
                        "\(viewModel.noteScores[index].grade.rawValue) grade"
                    )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            if index == viewModel.currentPracticeNoteIndex {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.3))
            } else if index < viewModel.noteScores.count {
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.noteScores[index].grade.color.opacity(0.1))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(noteCellAccessibilityLabel(index: index, note: note))
    }

    /// Real-time pitch detection feedback.
    private var pitchFeedbackSection: some View {
        VStack(spacing: 8) {
            if let pitch = viewModel.currentPitch {
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Detected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(pitch.noteName)
                            .font(.title2.bold())
                    }

                    VStack(alignment: .leading) {
                        Text("Cents")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%+.0f", pitch.centsOffset))
                            .font(.title3.monospaced())
                            .foregroundStyle(centsColor(pitch.centsOffset))
                    }

                    VStack(alignment: .leading) {
                        Text("Confidence")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(pitch.confidence * 100))%")
                            .font(.title3)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "Detected note \(pitch.noteName), "
                        + "\(Int(pitch.centsOffset)) cents offset, "
                        + "\(Int(pitch.confidence * 100)) percent confidence"
                )
            } else {
                Text("Sing or play a note...")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .accessibilityLabel("Waiting for audio input")
            }
        }
    }

    /// Practice session controls.
    private var controlsSection: some View {
        HStack(spacing: 20) {
            // Metronome toggle
            Button {
                viewModel.isMetronomeEnabled.toggle()
            } label: {
                Image(
                    systemName: viewModel.isMetronomeEnabled
                        ? "metronome.fill" : "metronome"
                )
                .font(.title2)
            }
            .accessibilityLabel(
                viewModel.isMetronomeEnabled ? "Metronome on" : "Metronome off"
            )
            .accessibilityHint("Toggle the metronome")

            Spacer()

            // Complete practice button
            Button {
                viewModel.completePractice()
            } label: {
                Label("Finish", systemImage: "stop.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .accessibilityLabel("Finish practice")
            .accessibilityHint("End the practice session and see your results")
        }
    }

    // MARK: - Helpers

    /// Format a sargam note's display name including modifier.
    ///
    /// - Parameter note: The sargam note to format.
    /// - Returns: Display string such as "Komal Re" or "Sa".
    private func noteDisplayName(_ note: SargamNote) -> String {
        if let modifier = note.modifier {
            return "\(modifier.capitalized) \(note.note)"
        }
        return note.note
    }

    /// Map cents offset to a feedback color.
    ///
    /// Green for within 10 cents, blue for 25, orange for 50, red beyond.
    ///
    /// - Parameter cents: Pitch deviation in cents.
    /// - Returns: Color indicating tuning accuracy.
    private func centsColor(_ cents: Double) -> Color {
        let absCents = abs(cents)
        if absCents <= 10 { return .green }
        if absCents <= 25 { return .blue }
        if absCents <= 50 { return .orange }
        return .red
    }

    /// Build an accessibility label for a note cell.
    ///
    /// - Parameters:
    ///   - index: Position in the notation.
    ///   - note: The sargam note.
    /// - Returns: Descriptive label for VoiceOver.
    private func noteCellAccessibilityLabel(index: Int, note: SargamNote) -> String {
        var label = noteDisplayName(note)
        if index == viewModel.currentPracticeNoteIndex {
            label += ", current note"
        }
        if index < viewModel.noteScores.count {
            label += ", \(viewModel.noteScores[index].grade.rawValue)"
        }
        return label
    }
}
