import Foundation

/// Evaluates recent practice performance and suggests difficulty adjustments.
///
/// Analyzes the trend of recent accuracy scores to determine whether the
/// student should try easier or harder content, or keep practicing at
/// the current level.
public enum PracticeDifficultyAdvisor {
    // MARK: - Thresholds

    /// Accuracy threshold above which the student should try harder.
    private static let proficiencyThreshold: Double = 0.90

    /// Accuracy threshold below which the student should try easier.
    private static let struggleThreshold: Double = 0.40

    /// Minimum number of sessions needed before giving difficulty advice.
    private static let minimumSessions: Int = 2

    // MARK: - Public Methods

    /// Generate practice advice based on recent accuracy scores.
    ///
    /// Analyzes the trend of the most recent scores to produce
    /// actionable advice for the student.
    ///
    /// - Parameters:
    ///   - recentAccuracies: Array of recent session accuracies (0.0-1.0),
    ///     ordered oldest to newest.
    ///   - currentDifficulty: The song's difficulty level (1-5).
    ///   - waitModeEnabled: Whether Wait Mode is currently enabled.
    /// - Returns: A `PracticeAdvice` with a message and suggested action.
    public static func advise(
        recentAccuracies: [Double],
        currentDifficulty: Int,
        waitModeEnabled: Bool
    ) -> PracticeAdvice {
        guard recentAccuracies.count >= minimumSessions else {
            return PracticeAdvice(
                message: "Keep practicing to build your skills!",
                suggestedAction: .keepPracticing
            )
        }

        let average = recentAccuracies.reduce(0.0, +) / Double(recentAccuracies.count)
        let latest = recentAccuracies.last ?? 0.0
        let isImproving = checkImproving(recentAccuracies)

        if let advice = adviseForHighAccuracy(average: average, difficulty: currentDifficulty) {
            return advice
        }

        if let advice = adviseForStruggling(
            average: average, difficulty: currentDifficulty, waitModeEnabled: waitModeEnabled
        ) {
            return advice
        }

        return adviseForPlateau(isImproving: isImproving, latest: latest)
    }

    // MARK: - Private Helpers

    /// Check if the student's accuracy is improving based on the last two sessions.
    private static func checkImproving(_ accuracies: [Double]) -> Bool {
        accuracies.count >= 2
            && accuracies[accuracies.count - 1] > accuracies[accuracies.count - 2]
    }

    /// Advise when the student has reached proficiency.
    private static func adviseForHighAccuracy(average: Double, difficulty: Int) -> PracticeAdvice? {
        guard average >= proficiencyThreshold, difficulty < 5 else { return nil }
        return PracticeAdvice(
            message: "Excellent work! You've reached proficiency. Try a harder song!",
            suggestedAction: .tryHarder
        )
    }

    /// Advise when the student is struggling.
    private static func adviseForStruggling(
        average: Double,
        difficulty: Int,
        waitModeEnabled: Bool
    ) -> PracticeAdvice? {
        guard average < struggleThreshold else { return nil }
        if !waitModeEnabled {
            return PracticeAdvice(
                message: "Try enabling Wait Mode to practice each note carefully.",
                suggestedAction: .enableWaitMode
            )
        }
        if difficulty > 1 {
            return PracticeAdvice(
                message: "This song might be too challenging right now. Try an easier one.",
                suggestedAction: .tryEasier
            )
        }
        return PracticeAdvice(
            message: "Keep practicing — you'll improve with repetition!",
            suggestedAction: .repeatSong
        )
    }

    /// Advise when accuracy is moderate — either improving or plateauing.
    private static func adviseForPlateau(isImproving: Bool, latest: Double) -> PracticeAdvice {
        if isImproving {
            return PracticeAdvice(
                message: "Great progress! Your accuracy is improving. Keep it up!",
                suggestedAction: .keepPracticing
            )
        }
        if latest < proficiencyThreshold {
            return PracticeAdvice(
                message: "You're doing well! Try the song again to improve your score.",
                suggestedAction: .repeatSong
            )
        }
        return PracticeAdvice(
            message: "Great job! Keep practicing to maintain your skills.",
            suggestedAction: .keepPracticing
        )
    }
}
