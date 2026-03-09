import AVFoundation

/// Tanpura drone player using AVAudioPlayerNode with looped playback.
/// Uses AudioEngineManager's tanpura node.
public final class TanpuraPlayer: @unchecked Sendable {
    public static let shared = TanpuraPlayer()

    /// Reference to the engine's tanpura player node.
    private var playerNode: AVAudioPlayerNode {
        AudioEngineManager.shared.tanpuraNode
    }

    /// Whether the tanpura is currently playing.
    public private(set) var isPlaying: Bool = false

    /// Current audio file for the drone.
    private var audioFile: AVAudioFile?

    private init() {}

    /// Load a tanpura audio file for drone playback.
    /// - Parameter url: URL to the tanpura audio file (.wav, .aif, .m4a)
    public func loadAudio(at url: URL) throws {
        audioFile = try AVAudioFile(forReading: url)
    }

    /// Start the tanpura drone with looped playback.
    public func start() {
        guard let audioFile, !isPlaying else { return }

        playerNode.scheduleFile(audioFile, at: nil) { [weak self] in
            // Re-schedule for looping
            DispatchQueue.main.async {
                if self?.isPlaying == true {
                    self?.start()
                }
            }
        }
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
