import Foundation

/// Identifies the context that triggered a sign-in prompt.
///
/// Used to display context-specific messaging in `SignInPromptView`,
/// e.g., "Sign in to unlock premium songs" vs. "Sign in to sync your progress."
public enum SignInTrigger: String, Sendable, Identifiable {
    /// Unique identifier for `Identifiable` conformance (used by `.sheet(item:)`).
    public var id: String { rawValue }

    /// User tapped a premium (locked) song.
    case premiumSong
    /// User attempted to enable CloudKit sync.
    case cloudSync
    /// User tapped sign-in from the profile tab.
    case profile
    /// User tapped sign-in from settings.
    case settings

    /// The title shown in the sign-in prompt sheet.
    public var promptTitle: String {
        switch self {
        case .premiumSong:
            "Unlock Premium Songs"
        case .cloudSync:
            "Sync Your Progress"
        case .profile:
            "Sign In to SurVibe"
        case .settings:
            "Sign In to SurVibe"
        }
    }

    /// The descriptive message shown below the title.
    public var promptMessage: String {
        switch self {
        case .premiumSong:
            "Sign in with Apple to access the full song library and track your progress across devices."
        case .cloudSync:
            "Sign in with Apple to sync your practice data, achievements, and progress across all your devices."
        case .profile:
            "Sign in with Apple to save your progress, unlock premium content, and personalize your experience."
        case .settings:
            "Sign in with Apple to enable cloud sync and access premium features."
        }
    }
}
