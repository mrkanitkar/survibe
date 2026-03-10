import Foundation

/// Sprint 0 analytics events for pipeline verification.
public enum AnalyticsEvent: String, Sendable {
    // Sprint 0 verification events
    case appScaffoldingLoaded = "app_scaffolding_loaded"
    case audioPocPitchDetected = "audio_poc_pitch_detected"
    case cloudKitSyncCompleted = "cloudkit_sync_completed"

    // Navigation events
    case tabSelected = "tab_selected"
    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"

    // Settings events
    case languageChanged = "language_changed"
}
