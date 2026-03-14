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
    /// Highlights the cell when the detected pitch matches this note's swar name
    /// and octave. Shows a colored border (green/orange/red) based on tuning
    /// accuracy and a compact cents badge overlay.
    ///
    /// - Parameters:
    ///   - index: Position in the sargam notes array.
    ///   - note: The sargam note to display.
    /// - Returns: A styled VStack for this note.
    private func noteCell(index: Int, note: SargamNote) -> some View {
        let isDetected = isNoteDetected(note)
        let detectedCentsValue = isDetected ? (viewModel.currentPitch?.centsOffset ?? 0) : 0

        return VStack(spacing: 4) {
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
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isDetected ? detectionAccuracyColor(detectedCentsValue) : .clear,
                    lineWidth: isDetected ? 3 : 0
                )
        )
        .overlay(alignment: .topTrailing) {
            if isDetected {
                detectionCentsBadge(cents: detectedCentsValue)
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
                        HStack(spacing: 6) {
                            Text(pitch.noteName)
                                .font(.title2.bold())

                            // Show "Outside Raga" badge when note is not in raga
                            if pitch.isInRaga == false {
                                Text("Outside Raga")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(.orange))
                                    .accessibilityLabel("Note is outside the raga")
                            }
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Cents")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        // Show JI cents when available, otherwise 12ET cents
                        let displayCents = pitch.ragaCentsOffset ?? pitch.centsOffset
                        Text(String(format: "%+.0f", displayCents))
                            .font(.title3.monospaced())
                            .foregroundStyle(centsColor(displayCents))
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
                .accessibilityLabel(pitchFeedbackAccessibilityLabel(pitch))
            } else {
                Text("Sing or play a note...")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .accessibilityLabel("Waiting for audio input")
            }
        }
    }

    /// Build an accessibility label for the pitch feedback section.
    ///
    /// Includes note name, cents offset, confidence, and out-of-raga status.
    ///
    /// - Parameter pitch: The current pitch result.
    /// - Returns: Descriptive label for VoiceOver.
    private func pitchFeedbackAccessibilityLabel(_ pitch: PitchResult) -> String {
        let displayCents = pitch.ragaCentsOffset ?? pitch.centsOffset
        var label = "Detected note \(pitch.noteName), "
            + "\(Int(displayCents)) cents offset, "
            + "\(Int(pitch.confidence * 100)) percent confidence"
        if pitch.isInRaga == false {
            label += ", outside the raga"
        }
        return label
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

    /// Whether the given sargam note matches the currently detected pitch.
    ///
    /// Compares the note's swar name and octave against the live detection.
    ///
    /// - Parameter note: The sargam note to check.
    /// - Returns: `true` if the detected pitch matches this note.
    private func isNoteDetected(_ note: SargamNote) -> Bool {
        guard let pitch = viewModel.currentPitch,
              pitch.amplitude >= 0.02,
              pitch.confidence >= 0.5 else { return false }
        return pitch.noteName == note.note && pitch.octave == note.octave
    }

    /// Color indicating pitch accuracy based on cents deviation.
    ///
    /// - Parameter cents: Pitch deviation in cents.
    /// - Returns: Green (<10¢), orange (<25¢), or red (>=25¢).
    private func detectionAccuracyColor(_ cents: Double) -> Color {
        let absCents = abs(cents)
        if absCents < 10 { return .green }
        if absCents < 25 { return .orange }
        return .red
    }

    /// Compact cents badge overlaid on detected note cells.
    ///
    /// - Parameter cents: Pitch deviation in cents.
    /// - Returns: A capsule view with the formatted cents value.
    private func detectionCentsBadge(cents: Double) -> some View {
        let rounded = Int(cents)
        let label = abs(rounded) < 5 ? "✓" : "\(rounded > 0 ? "+" : "")\(rounded)¢"

        return Text(label)
            .font(.system(size: 9, weight: .bold).monospacedDigit())
            .foregroundStyle(.white)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .background(Capsule().fill(detectionAccuracyColor(cents)))
            .offset(x: 4, y: -4)
            .accessibilityHidden(true)
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
        if isNoteDetected(note) {
            let absCents = abs(Int(viewModel.currentPitch?.centsOffset ?? 0))
            if absCents < 10 {
                label += ", detected, in tune"
            } else {
                let direction = (viewModel.currentPitch?.centsOffset ?? 0) > 0 ? "sharp" : "flat"
                label += ", detected, \(absCents) cents \(direction)"
            }
        }
        if index < viewModel.noteScores.count {
            label += ", \(viewModel.noteScores[index].grade.rawValue)"
        }
        return label
    }
}
