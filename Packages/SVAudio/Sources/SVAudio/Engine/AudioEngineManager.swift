import AVFoundation
import SVCore

/// Central audio engine manager using a single AVAudioEngine instance.
/// Manages mic input, SoundFont playback, tanpura drone, and metronome nodes.
/// Full implementation in Batch 6.
public final class AudioEngineManager: Sendable {
    public static let shared = AudioEngineManager()

    private init() {}

    /// Start the audio engine. Configures audio session and starts the engine.
    public func start() throws {
        // Batch 6: Configure AVAudioEngine, install tap, start engine
    }

    /// Stop the audio engine and remove taps.
    public func stop() {
        // Batch 6: Stop engine, remove taps
    }

    /// Whether the audio engine is currently running.
    public var isRunning: Bool {
        // Batch 6: Return engine.isRunning
        false
    }
}
