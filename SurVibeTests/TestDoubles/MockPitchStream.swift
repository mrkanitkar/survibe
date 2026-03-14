import Foundation
import SVAudio

/// Test double that produces a controllable stream of pitch detection results.
///
/// Tests push `PitchResult` values via `emit(_:)` and consumers
/// iterate via the `stream` property.
@MainActor
final class MockPitchStream {
    private var continuation: AsyncStream<PitchResult>.Continuation?

    /// The async stream of pitch results for consumers to iterate.
    let stream: AsyncStream<PitchResult>

    init() {
        var captured: AsyncStream<PitchResult>.Continuation?
        stream = AsyncStream { continuation in
            captured = continuation
        }
        continuation = captured
    }

    /// Emit a pitch result into the stream.
    /// - Parameter result: The pitch result to emit.
    func emit(_ result: PitchResult) {
        continuation?.yield(result)
    }

    /// Finish the stream (no more values will be emitted).
    func finish() {
        continuation?.finish()
    }
}
