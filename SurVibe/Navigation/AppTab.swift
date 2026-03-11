import SwiftUI

/// Represents the five main tabs in SurVibe's tab bar.
///
/// Each tab case provides its display label and SF Symbol for consistent
/// rendering across the tab bar and any tab-related UI.
enum AppTab: String, CaseIterable, Hashable {
    case home
    case learn
    case practice
    case songs
    case profile

    /// Localized display label for the tab.
    var label: String {
        switch self {
        case .home: "Home"
        case .learn: "Learn"
        case .practice: "Practice"
        case .songs: "Songs"
        case .profile: "Profile"
        }
    }

    /// SF Symbol name used for the tab icon.
    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .learn: "book.fill"
        case .practice: "music.note"
        case .songs: "music.note.list"
        case .profile: "person.circle.fill"
        }
    }
}
