import Foundation

/// Protocol abstracting time measurement for testable playback scheduling.
///
/// Production code uses `RealClock`, which delegates to `ContinuousClock`.
/// Test code uses `TestClock`, which provides deterministic time advancement
/// without actual delays — enabling fast, reliable tempo and scheduling tests.
public protocol ClockProviding: Sendable {
    /// The current time as a `ContinuousClock.Instant`.
    var now: ContinuousClock.Instant { get }

    /// Sleep for the specified duration.
    /// - Parameter duration: The duration to sleep.
    /// - Throws: `CancellationError` if the task is cancelled during sleep.
    func sleep(for duration: Duration) async throws
}

/// Production clock backed by `ContinuousClock`.
///
/// Provides real wall-clock timing via the system's continuous clock,
/// which is not affected by system sleep or date changes.
public struct RealClock: ClockProviding {
    private let clock = ContinuousClock()

    public init() {}

    public var now: ContinuousClock.Instant {
        clock.now
    }

    public func sleep(for duration: Duration) async throws {
        try await clock.sleep(for: duration)
    }
}
