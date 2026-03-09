import Foundation
import AVFoundation
import Observation

/// Microphone permission status.
public enum MicrophonePermissionStatus: Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

/// Manages microphone and other permission requests.
/// Full implementation in Batch 5.
@MainActor
@Observable
public final class PermissionManager {
    public static let shared = PermissionManager()

    public var microphoneStatus: MicrophonePermissionStatus = .notDetermined

    private init() {}

    /// Request microphone access. Call in context (first practice), NOT at launch.
    public func requestMicrophoneAccess() async -> Bool {
        // Batch 5: AVAudioApplication.requestRecordPermission()
        false
    }
}
