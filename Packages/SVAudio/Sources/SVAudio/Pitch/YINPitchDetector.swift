import Foundation

/// Fallback YIN autocorrelation pitch detector using Accelerate/vDSP.
/// Uses direct AVAudioEngine installTap for buffer access.
/// Full implementation in Batch 6.
public final class YINPitchDetector: PitchDetectorProtocol, @unchecked Sendable {

    public init() {}

    public func start() -> AsyncStream<PitchResult> {
        // Batch 6: Install tap, run YIN autocorrelation via vDSP
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    public func stop() {
        // Batch 6: Remove tap
    }
}
