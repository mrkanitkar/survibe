import AVFoundation

/// Manages AVAudioSession configuration for simultaneous input/output.
/// Category: .playAndRecord, Mode: .measurement
/// Options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers]
public final class AudioSessionManager: @unchecked Sendable {
    public static let shared = AudioSessionManager()

    private let session = AVAudioSession.sharedInstance()

    private init() {
        setupInterruptionObserver()
    }

    /// Configure audio session for simultaneous playback and recording.
    public func configure() throws {
        try session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers]
        )
        try session.setActive(true)
    }

    /// Deactivate the audio session.
    public func deactivate() {
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Whether the audio session is currently active.
    public var isOtherAudioPlaying: Bool {
        session.isOtherAudioPlaying
    }

    /// Current sample rate of the audio session.
    public var sampleRate: Double {
        session.sampleRate
    }

    // MARK: - Interruption Handling

    /// Callback invoked when audio is interrupted (phone call, etc.)
    public var onInterruptionBegan: (() -> Void)?

    /// Callback invoked when audio interruption ends.
    public var onInterruptionEnded: ((Bool) -> Void)?

    private func setupInterruptionObserver() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            onInterruptionBegan?()
        case .ended:
            let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            let shouldResume = options.contains(.shouldResume)
            onInterruptionEnded?(shouldResume)
        @unknown default:
            break
        }
    }
}
