import Foundation

/// Type-safe navigation destinations used by AppRouter.
///
/// Each case represents a screen that can be pushed onto a tab's
/// NavigationStack. Cases that carry model data use the model's
/// `id` for hashing and equality to avoid comparing full objects.
enum AppDestination: Hashable {
    case songLibrary
    case songDetail(Song)
    case lessonList
    case lessonDetail(Lesson)
    case practiceMode(Song)
    case playAlong(Song)
    case profile
    case settings

    // MARK: - Hashable

    /// Hashes the destination using its case name and, for model-carrying
    /// cases, the model's `id` property.
    func hash(into hasher: inout Hasher) {
        switch self {
        case .songLibrary:
            hasher.combine("songLibrary")
        case .songDetail(let song):
            hasher.combine("songDetail")
            hasher.combine(song.id)
        case .lessonList:
            hasher.combine("lessonList")
        case .lessonDetail(let lesson):
            hasher.combine("lessonDetail")
            hasher.combine(lesson.id)
        case .practiceMode(let song):
            hasher.combine("practiceMode")
            hasher.combine(song.id)
        case .playAlong(let song):
            hasher.combine("playAlong")
            hasher.combine(song.id)
        case .profile:
            hasher.combine("profile")
        case .settings:
            hasher.combine("settings")
        }
    }

    // MARK: - Equatable

    /// Compares two destinations by case and, for model-carrying cases,
    /// by the model's `id` rather than the full model object.
    static func == (lhs: AppDestination, rhs: AppDestination) -> Bool {
        switch (lhs, rhs) {
        case (.songLibrary, .songLibrary):
            true
        case (.songDetail(let lhsSong), .songDetail(let rhsSong)):
            lhsSong.id == rhsSong.id
        case (.lessonList, .lessonList):
            true
        case (.lessonDetail(let lhsLesson), .lessonDetail(let rhsLesson)):
            lhsLesson.id == rhsLesson.id
        case (.practiceMode(let lhsSong), .practiceMode(let rhsSong)):
            lhsSong.id == rhsSong.id
        case (.playAlong(let lhsSong), .playAlong(let rhsSong)):
            lhsSong.id == rhsSong.id
        case (.profile, .profile):
            true
        case (.settings, .settings):
            true
        default:
            false
        }
    }
}
