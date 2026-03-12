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

    // Day 6 — Onboarding events
    case onboardingScreenViewed = "onboarding_screen_viewed"
    case onboardingSkipped = "onboarding_skipped"
    case onboardingCompleted = "onboarding_completed"

    // Day 7 — Auth events
    case signInStarted = "sign_in_started"
    case signInCompleted = "sign_in_completed"
    case signInFailed = "sign_in_failed"
    case signInCancelled = "sign_in_cancelled"
    case signOutCompleted = "sign_out_completed"
    case credentialRevoked = "credential_revoked"

    // Day 8 — Song Library events
    case songFavoriteToggled = "song_favorite_toggled"
    case songFilterApplied = "song_filter_applied"
    case songSearchPerformed = "song_search_performed"
    case songLibraryViewed = "song_library_viewed"

    // Day 9 — Practice Mode events
    case practiceSessionStarted = "practice_session_started"
    case practiceSessionCompleted = "practice_session_completed"
    case practiceSessionRestarted = "practice_session_restarted"

    // Day 10 — Wait Mode events
    case waitModeToggled = "wait_mode_toggled"
    case waitModeNoteAttempted = "wait_mode_note_attempted"
    case waitModeCompleted = "wait_mode_completed"
}
