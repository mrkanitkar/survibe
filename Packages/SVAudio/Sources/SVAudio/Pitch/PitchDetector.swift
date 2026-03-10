import Foundation

/// Protocol for pitch detection implementations.
/// Conforming types use AsyncStream to deliver pitch results.
///
/// Two implementations:
/// - `AudioKitPitchDetector`: Autocorrelation-based (primary)
/// - `YINPitchDetector`: YIN algorithm (fallback)
public protocol PitchDetectorProtocol: AnyObject {
    /// Start pitch detection and return an AsyncStream of results.
    @MainActor func start() -> AsyncStream<PitchResult>

    /// Stop pitch detection and clean up resources.
    @MainActor func stop()
}
