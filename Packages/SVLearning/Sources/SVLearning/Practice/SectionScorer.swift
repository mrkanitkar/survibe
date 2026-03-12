import Foundation

/// Divides a practice session's note scores into sections and computes per-section metrics.
///
/// Sections are fixed-size groups of notes (default 4 notes per section).
/// Each section receives an average accuracy and grade based on the
/// constituent note scores.
public enum SectionScorer {
    /// Default number of notes per section.
    public static let defaultSectionSize = 4

    /// Divide note scores into sections and compute per-section metrics.
    ///
    /// - Parameters:
    ///   - scores: Array of note scores in order.
    ///   - sectionSize: Number of notes per section (default: 4).
    /// - Returns: Array of `SectionScore` values, one per section.
    public static func scoreSections(
        scores: [NoteScore],
        sectionSize: Int = defaultSectionSize
    ) -> [SectionScore] {
        guard !scores.isEmpty, sectionSize > 0 else { return [] }

        var sections: [SectionScore] = []
        var sectionIndex = 0
        var startIndex = 0

        while startIndex < scores.count {
            let endIndex = min(startIndex + sectionSize, scores.count)
            let sectionScores = Array(scores[startIndex..<endIndex])
            let avgAccuracy = PracticeScoring.averageAccuracy(scores: sectionScores)
            let grade = NoteGrade.from(accuracy: avgAccuracy)

            sections.append(SectionScore(
                sectionIndex: sectionIndex,
                noteRange: startIndex..<endIndex,
                accuracy: avgAccuracy,
                grade: grade,
                noteScores: sectionScores
            ))

            sectionIndex += 1
            startIndex = endIndex
        }

        return sections
    }

    /// Return sections sorted by accuracy (weakest first).
    ///
    /// Useful for highlighting areas that need the most improvement.
    ///
    /// - Parameter sections: Array of section scores.
    /// - Returns: Sections sorted by accuracy ascending (weakest first).
    public static func weakestFirst(sections: [SectionScore]) -> [SectionScore] {
        sections.sorted { $0.accuracy < $1.accuracy }
    }
}
