import AVFoundation
import SVCore
import os.log

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
    // MARK: - Properties

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

    private var isConfigured = false
    private var hasMicTap = false

    private static let logger = Logger(
        subsystem: "com.survibe",
        category: "AudioEngine"
    )

    // MARK: - Initialization

    private init() {
        // Attach nodes only — defer connections to start() after session is configured
        engine.attach(sampler)
        engine.attach(tanpuraNode)
        engine.attach(metronomeNode)
    }

    // MARK: - Private Methods

    /// Connect all nodes to main mixer using the current audio session format.
    /// Must be called after audio session is configured.
    private func connectNodes() {
        let mainMixer = engine.mainMixerNode
        let format = mainMixer.outputFormat(forBus: 0)

        engine.connect(sampler, to: mainMixer, format: format)
        engine.connect(tanpuraNode, to: mainMixer, format: format)
        engine.connect(metronomeNode, to: mainMixer, format: format)
        isConfigured = true
    }

    // MARK: - Public Methods

    /// Start the audio engine. Configures audio session first, then connects nodes.
    ///
    /// Important: Accesses `engine.inputNode` before `engine.start()` to ensure
    /// iOS configures the audio route for microphone input. Without this, the
    /// input node may report 0 channels when `installMicTap` is called later.
    public func start() throws {
        Self.logger.info("start() called")
        try AudioSessionManager.shared.configure()
        Self.logger.info("Audio session configured")

        // Connect nodes after session is configured so format is valid
        if !isConfigured {
            connectNodes()
            Self.logger.info("Nodes connected")
        }

        // CRITICAL: Access inputNode BEFORE engine.start() so iOS knows
        // we need mic input and configures the audio route accordingly.
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        Self.logger.info(
            "Input node format: rate=\(inputFormat.sampleRate) ch=\(inputFormat.channelCount)"
        )

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
        Self.logger.info("Engine started, isRunning=\(self.engine.isRunning)")
    }

    /// Stop the audio engine and remove any installed taps.
    public func stop() {
        if hasMicTap {
            engine.inputNode.removeTap(onBus: 0)
            hasMicTap = false
        }
        if engine.isRunning {
            tanpuraNode.stop()
            metronomeNode.stop()
            engine.stop()
        }
        isConfigured = false
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
    /// - Returns: `true` if the tap was installed successfully, `false` otherwise.
    @discardableResult
    public func installMicTap(
        bufferSize: AVAudioFrameCount? = nil,
        handler: @escaping @Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void
    ) -> Bool {
        guard engine.isRunning else {
            Self.logger.error("installMicTap: engine not running")
            return false
        }

        let inputNode = engine.inputNode
        let tapBufferSize = bufferSize ?? self.bufferSize
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Guard against 0-channel format (mic not available or session misconfigured)
        guard inputFormat.channelCount > 0 else {
            Self.logger.error(
                "installMicTap: 0 channels — mic not available. sampleRate=\(inputFormat.sampleRate)"
            )
            return false
        }

        guard inputFormat.sampleRate > 0 else {
            Self.logger.error("installMicTap: sampleRate is 0")
            return false
        }

        Self.logger.info(
            "installMicTap: format=\(inputFormat.sampleRate)Hz ch=\(inputFormat.channelCount) buf=\(tapBufferSize)"
        )

        // Remove existing tap if any
        if hasMicTap {
            inputNode.removeTap(onBus: 0)
            hasMicTap = false
        }

        inputNode.installTap(
            onBus: 0,
            bufferSize: tapBufferSize,
            format: inputFormat,
            block: handler
        )
        hasMicTap = true
        Self.logger.info("Mic tap installed successfully")
        return true
    }

    /// Remove the mic input tap.
    public func removeMicTap() {
        guard hasMicTap else { return }
        engine.inputNode.removeTap(onBus: 0)
        hasMicTap = false
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
