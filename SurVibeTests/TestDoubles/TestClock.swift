import Foundation
import SVAudio

/// Test double for `ClockProviding` that enables deterministic time advancement
/// without actual delays.
///
/// Tests call `advance(by:)` to move time forward instantly, which resumes
/// any pending `sleep(for:)` calls whose duration has elapsed.
final class TestClock: ClockProviding, @unchecked Sendable {
    // Note: @unchecked Sendable is acceptable here because TestClock is only
    // used in single-threaded test contexts where mutations are serialized.

    private var _now: ContinuousClock.Instant
    private var pendingSleeps: [(deadline: ContinuousClock.Instant, continuation: CheckedContinuation<Void, any Error>)] = []

    var now: ContinuousClock.Instant { _now }

    init() {
        _now = ContinuousClock.now
    }

    func sleep(for duration: Duration) async throws {
        let deadline = _now.advanced(by: duration)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            pendingSleeps.append((deadline, continuation))
        }
    }

    /// Advance the clock by the specified duration, resuming any pending sleeps
    /// whose deadlines have been reached.
    func advance(by duration: Duration) {
        _now = _now.advanced(by: duration)
        let ready = pendingSleeps.filter { $0.deadline <= _now }
        pendingSleeps.removeAll { $0.deadline <= _now }
        for item in ready {
            item.continuation.resume()
        }
    }
}
