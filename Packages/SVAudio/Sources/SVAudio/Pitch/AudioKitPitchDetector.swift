import Foundation

/// Primary pitch detection using SoundpipeAudioKit PitchTap.
/// Buffer size: 2048 samples (~46ms at 44100 Hz).
/// Full implementation in Batch 6.
public final class AudioKitPitchDetector: PitchDetectorProtocol, @unchecked Sendable {

    public init() {}

    public func start() -> AsyncStream<PitchResult> {
        // Batch 6: Create PitchTap, bridge to AsyncStream
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    public func stop() {
        // Batch 6: Stop PitchTap
    }
}
