import SwiftUI

/// Accessibility helpers for VoiceOver labels and announcements.
public enum AccessibilityHelper {
    /// Generate VoiceOver label for a swar note.
    public static func swarLabel(for noteName: String) -> String {
        noteName
    }

    /// Generate VoiceOver label for a tab.
    public static func tabLabel(for tabName: String) -> String {
        tabName
    }
}
