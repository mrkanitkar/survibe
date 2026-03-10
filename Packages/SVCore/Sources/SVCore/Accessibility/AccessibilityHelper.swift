import Foundation
import SwiftUI

/// Accessibility helpers for VoiceOver labels and announcements.
public enum AccessibilityHelper {
    /// Generate VoiceOver label for a swar note.
    /// Provides the full note name for screen reader pronunciation.
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
            return String(localized: "In tune", bundle: .module)
        } else if centsOffset > 0 {
            return String(localized: "Sharp by \(Int(absOffset)) cents", bundle: .module)
        } else {
            return String(localized: "Flat by \(Int(absOffset)) cents", bundle: .module)
        }
    }

    /// Post a VoiceOver announcement. Must be called on the main thread.
    @MainActor
    public static func announce(_ message: String) {
        #if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: message)
        #endif
    }
}
