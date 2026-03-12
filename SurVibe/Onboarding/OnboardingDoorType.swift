import Foundation

/// Represents a "Door" (feature area) that users can select during onboarding.
///
/// Users pick 1-3 doors to personalize their home screen experience.
/// Named `OnboardingDoorType` to avoid conflicts with HomeTab's DoorCard.
enum OnboardingDoorType: String, CaseIterable, Codable, Sendable, Hashable {
    case songs
    case learn
    case moods
    case community
    case practice

    /// Display label for the door selection card.
    var label: String {
        switch self {
        case .songs: "Songs"
        case .learn: "Learn"
        case .moods: "Moods"
        case .community: "Community"
        case .practice: "Practice"
        }
    }

    /// SF Symbol icon for the door selection card.
    var icon: String {
        switch self {
        case .songs: "music.note.list"
        case .learn: "book.circle"
        case .moods: "heart.fill"
        case .community: "person.2.circle"
        case .practice: "waveform.circle"
        }
    }

    /// Subtitle description shown in the door selection card.
    var subtitle: String {
        switch self {
        case .songs: "Browse and play songs"
        case .learn: "Guided lessons and tutorials"
        case .moods: "Music for your mood"
        case .community: "Connect with other learners"
        case .practice: "Free practice with feedback"
        }
    }
}
