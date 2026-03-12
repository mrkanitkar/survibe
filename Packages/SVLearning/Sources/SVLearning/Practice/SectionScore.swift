import Foundation

/// Score for a section (group of consecutive notes) in a practice session.
///
/// Used by `SectionScorer` to break a session into logical sections
/// and compute per-section metrics for the section breakdown view.
public struct SectionScore: Sendable, Equatable, Identifiable {
    /// Unique identifier for this section.
    public let id: UUID

    /// Zero-based section index.
    public let sectionIndex: Int

    /// Range of note indices in this section (inclusive start, exclusive end).
    public let noteRange: Range<Int>

    /// Average accuracy for notes in this section (0.0–1.0).
    public let accuracy: Double

    /// Overall grade for this section.
    public let grade: NoteGrade

    /// Individual note scores in this section.
    public let noteScores: [NoteScore]

    public init(
        id: UUID = UUID(),
        sectionIndex: Int,
        noteRange: Range<Int>,
        accuracy: Double,
        grade: NoteGrade,
        noteScores: [NoteScore]
    ) {
        self.id = id
        self.sectionIndex = sectionIndex
        self.noteRange = noteRange
        self.accuracy = accuracy
        self.grade = grade
        self.noteScores = noteScores
    }
}
