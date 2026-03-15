import Foundation
import Synchronization
import SVAudio

/// Test double for `ClockProviding` that enables deterministic time advancement
/// without actual delays.
///
/// ## Design — following Point-Free swift-clocks / Apple Clock protocol pattern
///
/// **Why NOT @MainActor:**
/// The playback loop in `PlayAlongViewModel` runs in an inherited-actor `Task`
/// on `@MainActor` and calls `clock.sleep()`. If `TestClock` were also
/// `@MainActor`, calling `continuation.resume()` from `advance(by:)` would try
/// to re-enter `@MainActor` while the actor is already held by the test — a
/// classic re-entrancy deadlock. Making `TestClock` nonisolated and using
/// `Mutex` for state avoids this entirely: `advance(by:)` resumes continuations
/// from outside any actor, so the `@MainActor` playback task can be
/// rescheduled immediately after the resume.
///
/// **Why Mutex:**
/// `Mutex` from `Synchronization` is `Sendable` and has no actor restrictions,
/// matching Swift's own `Clock` protocol requirement (conforming types must be
/// `Sendable` and callable from any isolation context).
///
/// **Cancellation handling:**
/// `withTaskCancellationHandler` ensures that when the calling task is
/// cancelled (e.g. during `vm.cleanup()`), the pending continuation is
/// immediately removed from `pendingSleeps` and resumed with
/// `CancellationError`. Without this, the Swift runtime crashes with a
/// "continuation leak" when the continuation is never resumed.
///
/// ## Usage
/// ```swift
/// let clock = TestClock()
/// // ... start something that calls clock.sleep(for:) ...
/// await clock.advance(by: .milliseconds(200))
/// // Resumed tasks execute before advance returns
/// ```
final class TestClock: ClockProviding, @unchecked Sendable {

    private struct SleepEntry {
        let id: ObjectIdentifier
        let deadline: ContinuousClock.Instant
        let continuation: CheckedContinuation<Void, any Error>
    }

    private struct State {
        var now: ContinuousClock.Instant
        var pendingSleeps: [SleepEntry]

        init() {
            now = ContinuousClock.now
            pendingSleeps = []
        }
    }

    private let state = Mutex(State())

    var now: ContinuousClock.Instant {
        state.withLock { $0.now }
    }

    init() {}

    /// Park the calling task until the clock is advanced past this deadline.
    ///
    /// Captures the current `now` and deadline atomically under the lock,
    /// then suspends. If the calling task is cancelled while parked, the
    /// continuation is removed from `pendingSleeps` and resumed with
    /// `CancellationError`, preventing a continuation leak crash.
    func sleep(for duration: Duration) async throws {
        // A heap-allocated token provides a stable `ObjectIdentifier` so the
        // cancellation handler can locate and remove this specific entry.
        final class Token: Sendable {}
        let token = Token()
        let id = ObjectIdentifier(token)

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                state.withLock { s in
                    let deadline = s.now.advanced(by: duration)
                    s.pendingSleeps.append(SleepEntry(id: id, deadline: deadline, continuation: continuation))
                }
            }
        } onCancel: {
            // Called synchronously when the task is cancelled.
            // Remove and resume the continuation with CancellationError so
            // the Swift runtime does not detect a leaked continuation and crash.
            let continuation: (CheckedContinuation<Void, any Error>)? = state.withLock { s in
                if let idx = s.pendingSleeps.firstIndex(where: { $0.id == id }) {
                    let entry = s.pendingSleeps.remove(at: idx)
                    return entry.continuation
                }
                return nil
            }
            continuation?.resume(throwing: CancellationError())
        }
    }

    /// Advance the clock by `duration`, resuming all parked sleeps whose
    /// deadlines have been reached.
    ///
    /// Yields once at the start so any just-enqueued `Task {}` blocks (e.g.
    /// the playback loop created by `startPlayback()`) have a chance to
    /// register their first `clock.sleep()` before the advance runs.
    ///
    /// Continuations are resumed **outside** the mutex lock so they can run
    /// immediately on their target actor (e.g. `@MainActor`) without
    /// re-entrancy issues. `Task.yield()` is called after each resume so the
    /// cooperative thread pool can schedule the resumed task before `advance`
    /// continues.
    func advance(by duration: Duration) async {
        // Give any just-started Task{} a chance to call clock.sleep() first.
        await Task.yield()

        let ready: [SleepEntry] = state.withLock { s in
            s.now = s.now.advanced(by: duration)
            let due = s.pendingSleeps.filter { $0.deadline <= s.now }
            s.pendingSleeps.removeAll { $0.deadline <= s.now }
            return due
        }
        for item in ready {
            item.continuation.resume()
            await Task.yield()
        }
    }

    /// Advance by `step` increments up to `totalDuration`.
    ///
    /// Use this for tests that contain polling loops which call
    /// `clock.sleep(for:)` repeatedly (e.g. wait mode, display link).
    func advanceToCompletion(totalDuration: Duration, step: Duration = .milliseconds(50)) async {
        var elapsed: Duration = .zero
        while elapsed < totalDuration {
            await advance(by: step)
            elapsed += step
        }
    }
}
