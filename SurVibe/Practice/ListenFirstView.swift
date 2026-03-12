import SVAudio
import SwiftUI

/// Listen-first phase view where the song plays back for the user to hear.
///
/// Shows the song title, scrollable sargam notation, a progress indicator,
/// and controls to play/pause or skip to practice. The user listens to the
/// complete melody before attempting to play along.
struct ListenFirstView: View {
    let viewModel: PracticeSessionViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 4) {
                Text("Listen First")
                    .font(.title2.bold())
                Text("Listen to the song before practicing")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            // Notation scroll area
            notationScrollView
                .frame(maxHeight: .infinity)

            // Progress bar
            progressBar

            // Controls
            controlButtons
                .padding(.bottom)
        }
    }

    // MARK: - Notation

    /// Scrollable list of sargam notes with the currently playing note highlighted.
    private var notationScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(
                    Array(viewModel.sargamNotes.enumerated()),
                    id: \.offset
                ) { index, note in
                    HStack {
                        Text(noteDisplayName(note))
                            .font(.title3.monospaced())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background {
                                if isCurrentListenNote(index) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.accentColor.opacity(0.2))
                                }
                            }

                        Text("Oct \(note.octave)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(String(format: "%.1f", note.duration))
                            .font(.caption.monospaced())
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "\(noteDisplayName(note)), octave \(note.octave), "
                            + "duration \(String(format: "%.1f", note.duration)) beats"
                    )
                }
            }
        }
    }

    // MARK: - Progress

    /// Playback progress bar showing current position relative to total duration.
    @ViewBuilder
    private var progressBar: some View {
        if viewModel.playbackEngine.duration > 0 {
            ProgressView(
                value: viewModel.playbackEngine.currentPosition,
                total: viewModel.playbackEngine.duration
            )
            .padding(.horizontal)
            .accessibilityLabel("Playback progress")
            .accessibilityValue(
                "\(Int(viewModel.playbackEngine.currentPosition)) of \(Int(viewModel.playbackEngine.duration)) seconds"
            )
        }
    }

    // MARK: - Controls

    /// Play/pause and skip-to-practice buttons.
    private var controlButtons: some View {
        HStack(spacing: 24) {
            Button {
                handlePlayPauseTap()
            } label: {
                Image(
                    systemName: viewModel.isListenPlaying
                        ? "pause.circle.fill" : "play.circle.fill"
                )
                .font(.system(size: 48))
            }
            .accessibilityLabel(viewModel.isListenPlaying ? "Pause" : "Play")
            .accessibilityHint(
                viewModel.isListenPlaying
                    ? "Pause the song playback"
                    : "Play the song to listen"
            )

            Button {
                viewModel.skipListenPhase()
            } label: {
                Label("Start Practice", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Start practice")
            .accessibilityHint("Skip listening and start playing along")
        }
    }

    // MARK: - Private Helpers

    /// Handle play/pause button tap based on current playback state.
    private func handlePlayPauseTap() {
        if viewModel.isListenPlaying {
            viewModel.pauseListenPhase()
        } else if viewModel.playbackEngine.playbackState == .paused {
            viewModel.resumeListenPhase()
        } else {
            viewModel.startListenPhase()
        }
    }

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

    /// Check if the given index is the currently playing note in listen mode.
    ///
    /// - Parameter index: Note index to check.
    /// - Returns: `true` if this is the active note during listen playback.
    private func isCurrentListenNote(_ index: Int) -> Bool {
        viewModel.playbackEngine.currentNoteIndex == index
    }
}
