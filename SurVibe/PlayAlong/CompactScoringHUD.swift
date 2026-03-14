import SwiftUI

/// Compact floating heads-up display showing real-time scoring during play-along.
///
/// Displays accuracy percentage, current streak with a flame icon, and
/// note progress (hit / total) in a semi-transparent capsule overlay.
/// The HUD animates in and out based on ``isVisible``, respecting the
/// user's Reduce Motion accessibility setting.
///
/// ## Usage
/// ```swift
/// CompactScoringHUD(
///     accuracy: 0.856,
///     streak: 12,
///     notesHit: 34,
///     totalNotes: 50,
///     isVisible: engine.playbackState == .playing
/// )
/// ```
struct CompactScoringHUD: View {
    // MARK: - Properties

    /// Current accuracy as a fraction (0.0 to 1.0).
    let accuracy: Double

    /// Current consecutive correct-note streak.
    let streak: Int

    /// Number of notes the player has hit correctly so far.
    let notesHit: Int

    /// Total number of notes in the song.
    let totalNotes: Int

    /// Whether the HUD should be visible on screen.
    let isVisible: Bool

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Body

    var body: some View {
        if isVisible {
            HStack(spacing: 16) {
                accuracyLabel
                streakLabel
                progressLabel
            }
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(combinedAccessibilityLabel)
        }
    }

    // MARK: - Private Views

    /// Displays accuracy as a percentage (e.g., "85%").
    private var accuracyLabel: some View {
        Text(CompactScoringHUD.formatAccuracy(accuracy))
            .foregroundStyle(.primary)
            .accessibilityLabel("Accuracy \(CompactScoringHUD.formatAccuracy(accuracy))")
    }

    /// Displays the current streak with a flame icon.
    private var streakLabel: some View {
        HStack(spacing: 2) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text("\(streak)")
                .foregroundStyle(.primary)
        }
        .accessibilityLabel("Streak \(streak)")
    }

    /// Displays the notes-hit progress fraction.
    private var progressLabel: some View {
        Text("\(notesHit)/\(totalNotes)")
            .foregroundStyle(.secondary)
            .accessibilityLabel("\(notesHit) of \(totalNotes) notes hit")
    }

    // MARK: - Accessibility

    /// Combined VoiceOver label for the entire HUD.
    private var combinedAccessibilityLabel: String {
        let accuracyText = CompactScoringHUD.formatAccuracy(accuracy)
        return "Score: \(accuracyText) accuracy, streak \(streak), \(notesHit) of \(totalNotes) notes"
    }

    // MARK: - Static Helpers

    /// Format an accuracy value (0.0...1.0) as a percentage string.
    ///
    /// Rounds to the nearest whole percentage. Values are clamped to the
    /// valid range before formatting.
    ///
    /// - Parameter accuracy: Accuracy fraction (0.0 = 0%, 1.0 = 100%).
    /// - Returns: Formatted percentage string (e.g., "85%", "100%", "0%").
    static func formatAccuracy(_ accuracy: Double) -> String {
        let clamped = min(1.0, max(0.0, accuracy))
        let percent = Int((clamped * 100).rounded())
        return "\(percent)%"
    }

    /// Compute the progress fraction (notesHit / totalNotes).
    ///
    /// Returns 0.0 when totalNotes is zero to avoid division by zero.
    ///
    /// - Parameters:
    ///   - notesHit: Number of correctly hit notes.
    ///   - totalNotes: Total notes in the song.
    /// - Returns: Fraction from 0.0 to 1.0.
    static func progressFraction(notesHit: Int, totalNotes: Int) -> Double {
        guard totalNotes > 0 else { return 0.0 }
        return Double(notesHit) / Double(totalNotes)
    }
}

// MARK: - Preview

#Preview("HUD — Visible") {
    CompactScoringHUD(
        accuracy: 0.856,
        streak: 12,
        notesHit: 34,
        totalNotes: 50,
        isVisible: true
    )
    .padding()
}

#Preview("HUD — Hidden") {
    CompactScoringHUD(
        accuracy: 0.0,
        streak: 0,
        notesHit: 0,
        totalNotes: 50,
        isVisible: false
    )
    .padding()
}
