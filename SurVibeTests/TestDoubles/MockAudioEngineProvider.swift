import AVFoundation
import SVAudio

/// Test double for `AudioEngineProviding` that simulates engine state
/// without requiring audio hardware or permissions.
@MainActor
final class MockAudioEngineProvider: AudioEngineProviding {
    var isRunning: Bool = false

    /// Number of times `start()` was called.
    private(set) var startCallCount: Int = 0

    /// Number of times `startForPlayback()` was called.
    private(set) var startForPlaybackCallCount: Int = 0

    /// Number of times `stop()` was called.
    private(set) var stopCallCount: Int = 0

    /// Whether a mic tap is currently installed.
    private(set) var hasMicTap: Bool = false

    /// Number of times `installMicTap` was called.
    private(set) var installMicTapCallCount: Int = 0

    /// If true, `start()` and `startForPlayback()` will throw.
    var shouldThrowOnStart: Bool = false

    func start() throws {
        startCallCount += 1
        if shouldThrowOnStart {
            throw NSError(domain: "MockAudioEngine", code: -1, userInfo: nil)
        }
        isRunning = true
    }

    func startForPlayback() throws {
        startForPlaybackCallCount += 1
        if shouldThrowOnStart {
            throw NSError(domain: "MockAudioEngine", code: -1, userInfo: nil)
        }
        isRunning = true
    }

    func stop() {
        stopCallCount += 1
        isRunning = false
        hasMicTap = false
    }

    @discardableResult
    func installMicTap(
        bufferSize: AVAudioFrameCount?,
        handler: @escaping @Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void
    ) -> Bool {
        installMicTapCallCount += 1
        hasMicTap = true
        return true
    }

    func removeMicTap() {
        hasMicTap = false
    }

    /// Reset all recorded state.
    func reset() {
        isRunning = false
        startCallCount = 0
        startForPlaybackCallCount = 0
        stopCallCount = 0
        hasMicTap = false
        installMicTapCallCount = 0
        shouldThrowOnStart = false
    }
}
