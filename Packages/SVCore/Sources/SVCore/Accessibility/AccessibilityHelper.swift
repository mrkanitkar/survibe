import SwiftUI

/// Accessibility helpers for VoiceOver labels and announcements.
public enum AccessibilityHelper {
    /// Generate VoiceOver label for a swar note.
    /// Provides the full note name for screen reader pronunciation.
    public static func swarLabel(for noteName: String) -> String {
        // Map abbreviated note names to full VoiceOver-friendly pronunciations
        let voiceOverNames: [String: String] = [
            "Sa": "Sa, the tonic note",
            "Komal Re": "Komal Re, flat second",
            "Re": "Re, the second note",
            "Komal Ga": "Komal Ga, flat third",
            "Ga": "Ga, the third note",
            "Ma": "Ma, the fourth note",
            "Tivra Ma": "Tivra Ma, sharp fourth",
            "Pa": "Pa, the fifth note",
            "Komal Dha": "Komal Dha, flat sixth",
            "Dha": "Dha, the sixth note",
            "Komal Ni": "Komal Ni, flat seventh",
            "Ni": "Ni, the seventh note"
        ]
        return voiceOverNames[noteName] ?? noteName
    }

    /// Generate VoiceOver label for a tab.
    public static func tabLabel(for tabName: String) -> String {
        "\(tabName) tab"
    }

    /// Generate VoiceOver label for a rang level.
    public static func rangLabel(for level: RangLevel) -> String {
        "\(level.displayName) level, \(level.proficiencyLabel)"
    }

    /// Generate VoiceOver label for pitch accuracy.
    public static func pitchAccuracyLabel(centsOffset: Double) -> String {
        let absOffset = abs(centsOffset)
        if absOffset < 5 {
            return "In tune"
        } else if centsOffset > 0 {
            return "Sharp by \(Int(absOffset)) cents"
        } else {
            return "Flat by \(Int(absOffset)) cents"
        }
    }

    /// Post a VoiceOver announcement.
    public static func announce(_ message: String) {
        #if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: message)
        #endif
    }
}
