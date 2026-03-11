import Foundation

/// Analytics events for SurVibe pipeline and feature tracking.
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

    // Day 4 events
    case doorTapped = "door_tapped"
    case songPlaybackStarted = "song_playback_started"
    case songPlaybackPaused = "song_playback_paused"
    case songPlaybackCompleted = "song_playback_completed"
}
