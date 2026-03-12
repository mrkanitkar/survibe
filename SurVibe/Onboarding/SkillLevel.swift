import Foundation

/// Skill level selected during onboarding.
///
/// Maps user's self-reported piano experience to a difficulty level
/// used for content recommendation (songs, lessons).
enum SkillLevel: String, CaseIterable, Codable, Sendable {
    case beginner
    case intermediate
    case advanced

    /// Display label for UI presentation.
    var label: String {
        switch self {
        case .beginner: "Beginner"
        case .intermediate: "Intermediate"
        case .advanced: "Advanced"
        }
    }

    /// Descriptive text shown below the label during onboarding.
    var description: String {
        switch self {
        case .beginner: "I'm just starting my musical journey"
        case .intermediate: "I know some basics and can play simple tunes"
        case .advanced: "I play regularly and know music theory"
        }
    }

    /// SF Symbol icon name for the skill card.
    var icon: String {
        switch self {
        case .beginner: "sparkles"
        case .intermediate: "music.note"
        case .advanced: "music.quarternote.3"
        }
    }

    /// Maps to Song.difficulty range for content filtering.
    ///
    /// - beginner: 1 (easiest songs/lessons)
    /// - intermediate: 2-3
    /// - advanced: 4-5
    var difficulty: Int {
        switch self {
        case .beginner: 1
        case .intermediate: 2
        case .advanced: 4
        }
    }
}
