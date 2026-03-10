import AVFoundation

/// Manages AVAudioSession configuration for simultaneous input/output.
/// Uses @MainActor isolation for thread-safe callback management.
///
/// Category: .playAndRecord, Mode: .measurement
/// Options: [.defaultToSpeaker, .allowBluetoothHFP, .mixWithOthers]
@MainActor
public final class AudioSessionManager {
    public static let shared = AudioSessionManager()

    private let session = AVAudioSession.sharedInstance()

    private init() {
        setupInterruptionObserver()
        setupRouteChangeObserver()
    }

    /// Configure audio session for simultaneous playback and recording.
    /// Sets preferred sample rate to 44100 Hz and IO buffer duration for 2048 frames.
    public func configure() throws {
        try session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.defaultToSpeaker, .allowBluetoothHFP, .mixWithOthers]
        )
        // Request 44100 Hz sample rate per spec
        try session.setPreferredSampleRate(44100)
        // Request buffer duration matching 2048 frames at 44100 Hz (~46ms)
        try session.setPreferredIOBufferDuration(2048.0 / 44100.0)
        try session.setActive(true)
    }

    /// Deactivate the audio session.
    public func deactivate() {
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Whether other audio is currently playing.
    public var isOtherAudioPlaying: Bool {
        session.isOtherAudioPlaying
    }

    /// Current sample rate of the audio session.
    public var sampleRate: Double {
        session.sampleRate
    }

    // MARK: - Interruption Handling

    /// Callback invoked when audio is interrupted (phone call, etc.)
    public var onInterruptionBegan: (@Sendable () -> Void)?

    /// Callback invoked when audio interruption ends.
    public var onInterruptionEnded: (@Sendable (Bool) -> Void)?

    /// Callback invoked when the audio route changes (e.g., Bluetooth connect/disconnect).
    public var onRouteChange: (@Sendable () -> Void)?

    private func setupInterruptionObserver() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: .main
        ) { [weak self] notification in
            // Extract Sendable values before crossing isolation boundary
            // (Notification is not Sendable — cannot be passed into Task)
            let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            Task { @MainActor in
                self?.handleInterruption(typeValue: typeValue, optionsValue: optionsValue)
            }
        }
    }

    private func setupRouteChangeObserver() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: session,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.onRouteChange?()
            }
        }
    }

    private func handleInterruption(typeValue: UInt?, optionsValue: UInt?) {
        guard let typeValue,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            onInterruptionBegan?()
        case .ended:
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue ?? 0)
            let shouldResume = options.contains(.shouldResume)
            onInterruptionEnded?(shouldResume)
        @unknown default:
            break
        }
    }
}
