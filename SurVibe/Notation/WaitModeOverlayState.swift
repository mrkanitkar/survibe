import Foundation

/// State model for the wait-mode overlay on staff notation.
///
/// Tracks which note the student is currently waiting on,
/// whether the latest attempt was correct/incorrect, and
/// whether the note was auto-skipped. The renderer uses this
/// to draw visual feedback (green flash for correct, red shake
/// for incorrect, grey for skipped).
///
/// This is a simple value type — it does not depend on
/// `WaitModeEngine` directly. The practice session coordinator
/// maps `WaitModeState` transitions into this overlay state.
struct WaitModeOverlayState: Sendable, Equatable {

    /// Index of the note the student is currently waiting to play.
    /// `nil` when wait mode is not active.
    var waitingNoteIndex: Int?

    /// Whether the most recent attempt matched the expected note.
    var isCorrectAttempt: Bool = false

    /// Whether the most recent attempt was incorrect.
    var isIncorrectAttempt: Bool = false

    /// Whether the current note was auto-skipped (patience timeout).
    var isSkipped: Bool = false

    /// Reset all attempt feedback flags.
    ///
    /// Call this after the feedback animation completes,
    /// before advancing to the next note.
    mutating func resetFeedback() {
        isCorrectAttempt = false
        isIncorrectAttempt = false
        isSkipped = false
    }

    /// Mark the current note as correctly played.
    mutating func markCorrect() {
        isCorrectAttempt = true
        isIncorrectAttempt = false
        isSkipped = false
    }

    /// Mark the current note as incorrectly played.
    mutating func markIncorrect() {
        isCorrectAttempt = false
        isIncorrectAttempt = true
        isSkipped = false
    }

    /// Mark the current note as skipped.
    mutating func markSkipped() {
        isCorrectAttempt = false
        isIncorrectAttempt = false
        isSkipped = true
    }
}
