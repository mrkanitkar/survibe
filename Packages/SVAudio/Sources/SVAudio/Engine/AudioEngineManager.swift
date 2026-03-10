import AVFoundation
import SVCore

/// Central audio engine manager using a single AVAudioEngine instance.
/// Uses @MainActor isolation for thread-safe state access.
///
/// Node graph (per WWDC 2014/2019 best practice — single engine):
/// - AVAudioInputNode (mic, 2048 buffer tap at 44100 Hz)
/// - AVAudioUnitSampler (SoundFont piano)
/// - AVAudioPlayerNode x2 (tanpura, metronome)
/// - Main mixer with per-node volume
@MainActor
public final class AudioEngineManager {
    public static let shared = AudioEngineManager()

    /// The single AVAudioEngine instance.
    public let engine = AVAudioEngine()

    /// Sampler node for SoundFont instrument playback.
    public let sampler = AVAudioUnitSampler()

    /// Player node for tanpura drone.
    public let tanpuraNode = AVAudioPlayerNode()

    /// Player node for metronome clicks.
    public let metronomeNode = AVAudioPlayerNode()

    /// Default buffer size for mic tap: 2048 frames (~46ms at 44100 Hz).
    public let bufferSize: AVAudioFrameCount = 2048

    private init() {
        // Attach all nodes to the engine
        engine.attach(sampler)
        engine.attach(tanpuraNode)
        engine.attach(metronomeNode)

        // Connect nodes to main mixer
        let mainMixer = engine.mainMixerNode
        let format = mainMixer.outputFormat(forBus: 0)

        engine.connect(sampler, to: mainMixer, format: format)
        engine.connect(tanpuraNode, to: mainMixer, format: format)
        engine.connect(metronomeNode, to: mainMixer, format: format)
    }

    /// Start the audio engine. Configures audio session first.
    public func start() throws {
        try AudioSessionManager.shared.configure()

        // Set up interruption handling
        AudioSessionManager.shared.onInterruptionBegan = { [weak self] in
            Task { @MainActor in
                self?.engine.pause()
            }
        }
        AudioSessionManager.shared.onInterruptionEnded = { [weak self] shouldResume in
            Task { @MainActor in
                if shouldResume {
                    try? self?.engine.start()
                }
            }
        }

        engine.prepare()
        try engine.start()
    }

    /// Stop the audio engine and remove any installed taps.
    public func stop() {
        let inputNode = engine.inputNode
        inputNode.removeTap(onBus: 0)

        tanpuraNode.stop()
        metronomeNode.stop()
        engine.stop()
        AudioSessionManager.shared.deactivate()
    }

    /// Whether the audio engine is currently running.
    public var isRunning: Bool {
        engine.isRunning
    }

    /// Install a tap on the mic input node for pitch detection.
    /// - Parameters:
    ///   - bufferSize: Number of frames per buffer (default: 2048)
    ///   - handler: Callback with audio buffer and time. Executes on real-time audio thread.
    public func installMicTap(
        bufferSize: AVAudioFrameCount? = nil,
        handler: @escaping @Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void
    ) {
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        let tapBufferSize = bufferSize ?? self.bufferSize

        inputNode.installTap(
            onBus: 0,
            bufferSize: tapBufferSize,
            format: recordingFormat,
            block: handler
        )
    }

    /// Remove the mic input tap.
    public func removeMicTap() {
        engine.inputNode.removeTap(onBus: 0)
    }

    /// Set volume for the sampler node (0.0 to 1.0).
    public func setSamplerVolume(_ volume: Float) {
        sampler.volume = volume
    }

    /// Set volume for the tanpura node (0.0 to 1.0).
    public func setTanpuraVolume(_ volume: Float) {
        tanpuraNode.volume = volume
    }

    /// Set volume for the metronome node (0.0 to 1.0).
    public func setMetronomeVolume(_ volume: Float) {
        metronomeNode.volume = volume
    }
}
