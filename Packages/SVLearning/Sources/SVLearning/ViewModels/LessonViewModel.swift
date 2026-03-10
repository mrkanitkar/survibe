import Foundation
import Observation
import SVCore

/// View model for lesson playback and progress tracking.
/// Uses @Observable per project convention (Observation framework only).
/// Full implementation in Sprint 1.
@MainActor
@Observable
public final class LessonViewModel {
    /// Current lesson title.
    public var lessonTitle: String = ""

    /// Whether the lesson is currently playing.
    public var isPlaying: Bool = false

    /// Lesson completion percentage (0.0 to 1.0).
    public var progress: Double = 0.0

    public init() {}

    /// Start lesson playback.
    public func play() {
        // Sprint 1: Start audio playback, update progress
        isPlaying = true
    }

    /// Pause lesson playback.
    public func pause() {
        // Sprint 1: Pause audio playback
        isPlaying = false
    }
}
