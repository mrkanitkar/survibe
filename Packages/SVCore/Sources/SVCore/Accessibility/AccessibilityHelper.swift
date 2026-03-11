import Foundation
import SwiftUI

/// VoiceOver label generators and accessibility announcements for SurVibe.
///
/// Provides consistent, localized screen reader text for swar notes,
/// navigation tabs, rang levels, and pitch accuracy feedback.
/// All labels follow Apple HIG for voice-friendly descriptions.
public enum AccessibilityHelper {
    /// Generate a VoiceOver label for a swar note.
    ///
    /// Returns a localized string with the full note name and its interval
    /// description (e.g., "Sa, the tonic note") for clear screen reader pronunciation.
    ///
    /// - Parameter noteName: The swar name (e.g., "Sa", "Komal Re").
    /// - Returns: Localized VoiceOver-friendly description of the note.
    public static func swarLabel(for noteName: String) -> String {
        switch noteName {
        case "Sa": String(localized: "Sa, the tonic note", bundle: .module)
        case "Komal Re": String(localized: "Komal Re, flat second", bundle: .module)
        case "Re": String(localized: "Re, the second note", bundle: .module)
        case "Komal Ga": String(localized: "Komal Ga, flat third", bundle: .module)
        case "Ga": String(localized: "Ga, the third note", bundle: .module)
        case "Ma": String(localized: "Ma, the fourth note", bundle: .module)
        case "Tivra Ma": String(localized: "Tivra Ma, sharp fourth", bundle: .module)
        case "Pa": String(localized: "Pa, the fifth note", bundle: .module)
        case "Komal Dha": String(localized: "Komal Dha, flat sixth", bundle: .module)
        case "Dha": String(localized: "Dha, the sixth note", bundle: .module)
        case "Komal Ni": String(localized: "Komal Ni, flat seventh", bundle: .module)
        case "Ni": String(localized: "Ni, the seventh note", bundle: .module)
        default: noteName
        }
    }

    /// Generate a VoiceOver label for a navigation tab.
    ///
    /// - Parameter tabName: Display name of the tab (e.g., "Practice", "Learn").
    /// - Returns: Label with " tab" suffix for VoiceOver context.
    public static func tabLabel(for tabName: String) -> String {
        "\(tabName) tab"
    }

    /// Generate a VoiceOver label for a rang (gamification level).
    ///
    /// - Parameter level: The user's current rang level.
    /// - Returns: Label combining the level display name and proficiency (e.g., "Neel level, Beginner").
    public static func rangLabel(for level: RangLevel) -> String {
        "\(level.displayName) level, \(level.proficiencyLabel)"
    }

    /// Generate a VoiceOver label describing pitch accuracy relative to the target note.
    ///
    /// - Parameter centsOffset: Deviation in cents from the target pitch. Positive = sharp, negative = flat.
    /// - Returns: Localized label: "In tune" (±5 cents), "Sharp by N cents", or "Flat by N cents".
    public static func pitchAccuracyLabel(centsOffset: Double) -> String {
        let absOffset = abs(centsOffset)
        if absOffset < 5 {
            return String(localized: "In tune", bundle: .module)
        } else if centsOffset > 0 {
            return String(localized: "Sharp by \(Int(absOffset)) cents", bundle: .module)
        } else {
            return String(localized: "Flat by \(Int(absOffset)) cents", bundle: .module)
        }
    }

    /// Post a VoiceOver announcement to the accessibility system.
    ///
    /// - Parameter message: The text to announce. Should be concise and action-oriented.
    @MainActor
    public static func announce(_ message: String) {
        #if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: message)
        #endif
    }
}
