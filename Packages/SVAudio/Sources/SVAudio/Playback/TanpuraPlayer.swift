import AVFoundation

/// Tanpura drone player using AVAudioPlayerNode with looped buffer playback.
/// Uses AudioEngineManager's tanpura node.
@MainActor
public final class TanpuraPlayer {
    public static let shared = TanpuraPlayer()

    /// Reference to the engine's tanpura player node.
    private var playerNode: AVAudioPlayerNode {
        AudioEngineManager.shared.tanpuraNode
    }

    /// Whether the tanpura is currently playing.
    public private(set) var isPlaying: Bool = false

    /// Pre-loaded audio buffer for gapless looping.
    private var loopBuffer: AVAudioPCMBuffer?

    private init() {}

    /// Load a tanpura audio file for drone playback.
    /// Pre-loads into an AVAudioPCMBuffer for gapless looping.
    /// - Parameter url: URL to the tanpura audio file (.wav, .aif, .m4a)
    public func loadAudio(at url: URL) throws {
        let audioFile = try AVAudioFile(forReading: url)
        let frameCount = AVAudioFrameCount(audioFile.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: frameCount) else {
            throw NSError(domain: "TanpuraPlayer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PCM buffer"])
        }
        try audioFile.read(into: buffer)
        loopBuffer = buffer
    }

    /// Start the tanpura drone with gapless looped playback.
    public func start() {
        guard let loopBuffer, !isPlaying else { return }

        // Schedule buffer with .loops for gapless playback at engine level
        playerNode.scheduleBuffer(loopBuffer, at: nil, options: .loops)
        playerNode.play()
        isPlaying = true
    }

    /// Stop the tanpura drone.
    public func stop() {
        playerNode.stop()
        isPlaying = false
    }

    /// Set the volume of the tanpura (0.0 to 1.0).
    public func setVolume(_ volume: Float) {
        AudioEngineManager.shared.setTanpuraVolume(volume)
    }
}
