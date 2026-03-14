import AVFoundation

/// Protocol abstracting the audio engine for testability.
///
/// The production implementation is `AudioEngineManager`, which manages
/// a single `AVAudioEngine` instance. Test doubles can simulate engine
/// state without requiring audio hardware.
@MainActor
public protocol AudioEngineProviding: AnyObject {
    /// Whether the audio engine is currently running.
    var isRunning: Bool { get }

    /// Whether a microphone tap is currently installed.
    var hasMicTap: Bool { get }

    /// Start the engine with microphone input (playAndRecord mode).
    /// - Throws: If the audio session or engine fails to start.
    func start() throws

    /// Start the engine for playback only (no mic permission prompt).
    /// - Throws: If the audio session or engine fails to start.
    func startForPlayback() throws

    /// Stop the engine and remove any installed taps.
    func stop()

    /// Install a tap on the mic input node for pitch detection.
    /// - Parameters:
    ///   - bufferSize: Number of frames per buffer (default: engine's buffer size).
    ///   - handler: Callback with audio buffer and time on the real-time audio thread.
    /// - Returns: `true` if the tap was installed successfully.
    @discardableResult
    func installMicTap(
        bufferSize: AVAudioFrameCount?,
        handler: @escaping @Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void
    ) -> Bool

    /// Remove the mic input tap.
    func removeMicTap()
}
