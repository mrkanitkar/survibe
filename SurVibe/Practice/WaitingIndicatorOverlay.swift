import SwiftUI
import SVLearning

/// Overlay displayed during Wait Mode when waiting for the student to play a note.
///
/// Shows a pulsing glow around the expected note, a patience countdown,
/// and a skip button. Respects the user's reduce motion preference.
struct WaitingIndicatorOverlay: View {
    /// The expected note name to display.
    let expectedNote: String

    /// The expected octave.
    let expectedOctave: Int

    /// Remaining patience time in seconds (0 = unlimited).
    let remainingPatience: Double

    /// Whether the patience timer is active (non-zero patience).
    let hasPatienceTimer: Bool

    /// Called when the skip button is tapped.
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 16) {
            // Expected note with pulsing glow
            Text(expectedNote)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .shadow(
                    color: .accentColor.opacity(isPulsing ? 0.6 : 0.2),
                    radius: isPulsing ? 20 : 8
                )
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
                .accessibilityLabel("Play \(expectedNote)")

            Text("Octave \(expectedOctave)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Patience countdown
            if hasPatienceTimer {
                Text("Time remaining: \(Int(remainingPatience))s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Time remaining: \(Int(remainingPatience)) seconds")
            } else {
                Text("Take your time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Skip button
            Button {
                onSkip()
            } label: {
                Label("Skip Note", systemImage: "forward.fill")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Skip note")
            .accessibilityHint("Skip this note and move to the next one")
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
