import Foundation

/// Types of quiz questions in the lesson system.
///
/// Each type tests a different musical knowledge area,
/// allowing lessons to assess comprehension progressively.
enum QuestionType: String, Codable, Sendable {
    /// Identify a note by ear or visual representation.
    case noteIdentification

    /// Recognize the interval between two notes.
    case intervalRecognition

    /// Match a Sargam note name to its Western equivalent.
    case sargamMatching
}

/// A single quiz question within a lesson step.
///
/// Quiz questions are embedded as JSON in the `content` field of
/// a lesson step with `stepType == "quiz"`. The `QuizStepView`
/// decodes the JSON array into `[QuizQuestion]` for the quiz engine.
///
/// ## JSON Format
/// ```json
/// {
///   "id": "L1-Q1",
///   "questionText": "Which Sargam note corresponds to C?",
///   "options": ["Sa", "Re", "Ga", "Ma"],
///   "correctAnswerIndex": 0,
///   "questionType": "sargamMatching"
/// }
/// ```
struct QuizQuestion: Codable, Identifiable, Sendable, Equatable {
    /// Unique identifier (e.g., "L1-Q1").
    let id: String

    /// The question text displayed to the learner.
    let questionText: String

    /// Four answer options (A, B, C, D).
    let options: [String]

    /// Index of the correct answer in `options` (0–3).
    let correctAnswerIndex: Int

    /// Optional audio clip reference for ear training questions.
    let audioClip: String?

    /// The type of musical knowledge being tested.
    let questionType: QuestionType
}

/// The result of a completed quiz.
///
/// Computed from the user's answers after all questions are answered.
/// The score uses a 0.0–1.0 scale for consistency with `LessonProgress.bestQuizScore`.
struct QuizResult: Sendable, Equatable {
    /// Total number of questions in the quiz.
    let totalQuestions: Int

    /// Number of correctly answered questions.
    let correctCount: Int

    /// Score as a fraction (0.0–1.0).
    var score: Double {
        guard totalQuestions > 0 else { return 0.0 }
        return Double(correctCount) / Double(totalQuestions)
    }

    /// Score as a percentage (0–100).
    var percentage: Int {
        Int(score * 100)
    }

    /// Encouraging feedback message based on performance.
    var message: String {
        switch percentage {
        case 100:
            "Perfect! You've mastered this!"
        case 60..<100:
            "Great job! Keep practicing."
        default:
            "Good try! Review the lesson and try again."
        }
    }
}
