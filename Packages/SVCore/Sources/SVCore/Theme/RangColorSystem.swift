import SwiftUI

/// Rang (color) system mapping musical achievement levels to colors.
/// Each level represents a stage of musical proficiency in Indian classical music.
///
/// Usage rules:
/// - Neel, Hara, Lal: Safe for any text size, backgrounds, and icons
/// - Peela, Sona: Use only for backgrounds, large text (18pt+), and icons
///   For body text with Peela/Sona, use the dark variants (peelaDark/sonaDark)
///   which meet WCAG AA contrast requirements
public enum RangLevel: Int, CaseIterable, Sendable {
    case neel = 1    // Beginner — Indigo Blue (#3F51B5)
    case hara = 2    // Developing — Forest Green (#388E3C)
    case peela = 3   // Intermediate — Marigold (#F9A825)
    case lal = 4     // Advanced — Vermillion (#D32F2F)
    case sona = 5    // Master — Gold (#FFB300)

    /// Display name for this rang level.
    public var displayName: String {
        switch self {
        case .neel: "Neel"
        case .hara: "Hara"
        case .peela: "Peela"
        case .lal: "Lal"
        case .sona: "Sona"
        }
    }

    /// English description of the proficiency level.
    public var proficiencyLabel: String {
        switch self {
        case .neel: "Beginner"
        case .hara: "Developing"
        case .peela: "Intermediate"
        case .lal: "Advanced"
        case .sona: "Master"
        }
    }

    /// Primary color for this rang level.
    public var color: Color {
        switch self {
        case .neel: .rangNeel
        case .hara: .rangHara
        case .peela: .rangPeela
        case .lal: .rangLal
        case .sona: .rangSona
        }
    }

    /// Safe color for body text — uses dark variants for Peela and Sona
    /// to meet WCAG AA contrast requirements on white backgrounds.
    public var bodyTextColor: Color {
        switch self {
        case .neel: .rangNeel
        case .hara: .rangHara
        case .peela: .rangPeelaDark
        case .lal: .rangLal
        case .sona: .rangSonaDark
        }
    }

    /// Minimum XP threshold to reach this rang level.
    public var xpThreshold: Int {
        switch self {
        case .neel: 0
        case .hara: 500
        case .peela: 2000
        case .lal: 5000
        case .sona: 10000
        }
    }

    /// Determine the rang level for a given XP value.
    public static func level(for xp: Int) -> RangLevel {
        for level in allCases.reversed() where xp >= level.xpThreshold {
            return level
        }
        return .neel
    }
}
