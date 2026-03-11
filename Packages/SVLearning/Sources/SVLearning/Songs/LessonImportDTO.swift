import Foundation

/// Data Transfer Object for importing lessons from JSON files.
///
/// Maps directly to the JSON lesson schema. The import pipeline reads
/// JSON → `LessonImportDTO` → validates → `Lesson` @Model (in app target).
///
/// All fields use Codable types; no SwiftData dependencies.
/// This DTO lives in SVLearning so it can be tested independently
/// without a ModelContainer.
public struct LessonImportDTO: Codable, Equatable, Sendable {
    // MARK: - Required Fields

    /// Unique lesson identifier (kebab-case, e.g., "lesson-meet-swaras-v1").
    public let lessonId: String

    /// Display title.
    public let title: String

    /// Detailed description of learning objectives.
    public let lessonDescription: String

    /// Difficulty level (1–5).
    public let difficulty: Int

    /// Ordering within curriculum (ascending).
    public let orderIndex: Int

    /// Lesson steps (intro, listen, exercise, practice, quiz).
    public let steps: [LessonStepDTO]

    // MARK: - Optional Fields

    /// Lesson IDs that must be completed before this one.
    public let prerequisiteLessonIds: [String]?

    /// Song IDs referenced in this lesson.
    public let associatedSongIds: [String]?

    /// Whether this lesson is available to free-tier users.
    public let isFree: Bool?

    // MARK: - Validation

    /// Validates the DTO against schema rules.
    ///
    /// - Throws: `LessonImportError` with details about the first validation failure.
    public func validate() throws {
        guard !lessonId.isEmpty else {
            throw LessonImportError.missingField("lessonId")
        }
        guard !title.isEmpty, title.count <= 200 else {
            throw LessonImportError.invalidField("title", reason: "must be 1–200 characters")
        }
        guard !lessonDescription.isEmpty, lessonDescription.count <= 1000 else {
            throw LessonImportError.invalidField(
                "lessonDescription", reason: "must be 1–1000 characters")
        }
        guard (1...5).contains(difficulty) else {
            throw LessonImportError.invalidField("difficulty", reason: "must be 1–5")
        }
        guard !steps.isEmpty else {
            throw LessonImportError.missingField("steps")
        }
    }
}

/// A single instructional step in a lesson import JSON.
public struct LessonStepDTO: Codable, Equatable, Sendable {
    /// Step type: "intro", "listen", "read", "exercise", "practice", "quiz".
    public let stepType: String

    /// Instructional content.
    public let content: String

    /// Optional reference to a song slug ID for audio playback.
    public let songId: String?

    /// Optional duration in seconds (used for timed steps).
    public let durationSeconds: Int?

    public init(
        stepType: String,
        content: String,
        songId: String? = nil,
        durationSeconds: Int? = nil
    ) {
        self.stepType = stepType
        self.content = content
        self.songId = songId
        self.durationSeconds = durationSeconds
    }
}

/// Errors thrown during lesson import validation.
public enum LessonImportError: Error, Sendable, CustomStringConvertible {
    /// A required field is missing or empty.
    case missingField(String)
    /// A field value is outside the allowed range or format.
    case invalidField(String, reason: String)
    /// The JSON data could not be decoded.
    case decodingFailed(String)

    public var description: String {
        switch self {
        case .missingField(let field):
            "Missing required field: \(field)"
        case .invalidField(let field, let reason):
            "Invalid field '\(field)': \(reason)"
        case .decodingFailed(let detail):
            "JSON decoding failed: \(detail)"
        }
    }
}
