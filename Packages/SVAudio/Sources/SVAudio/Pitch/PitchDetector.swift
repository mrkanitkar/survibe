import Foundation

/// Protocol for pitch detection implementations.
/// Provides an AsyncStream of PitchResult values from mic input.
/// Full implementation in Batch 6.
public protocol PitchDetectorProtocol: Sendable {
    /// Start pitch detection and return an async stream of results.
    func start() -> AsyncStream<PitchResult>

    /// Stop pitch detection.
    func stop()
}
