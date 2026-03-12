import Foundation

/// Calculates individual note scores during practice mode.
///
/// Uses a weighted scoring formula: 50% pitch accuracy + 30% timing accuracy
/// + 20% duration accuracy. Each component is computed from the deviation
/// between the player's input and the expected note values, mapped to a
/// 0.0–1.0 accuracy range using the thresholds in `PracticeConstants`.
public enum NoteScoreCalculator {
    /// Calculate the score for a single note attempt.
    ///
    /// Takes raw deviation measurements and produces a `NoteScore` with
    /// composite accuracy and grade. All deviations are absolute values.
    ///
    /// - Parameters:
    ///   - expectedNote: The target swar note name (e.g., "Sa", "Re").
    ///   - detectedNote: The note name detected by pitch detection, if any.
    ///   - pitchDeviationCents: Absolute cents deviation from the target pitch.
    ///   - timingDeviationSeconds: Absolute timing deviation from expected onset.
    ///   - durationDeviation: Duration deviation as fraction of expected duration.
    /// - Returns: A `NoteScore` with computed accuracy and grade.
    public static func score(
        expectedNote: String,
        detectedNote: String?,
        pitchDeviationCents: Double,
        timingDeviationSeconds: Double,
        durationDeviation: Double
    ) -> NoteScore {
        let pitchAccuracy = pitchAccuracyScore(cents: abs(pitchDeviationCents))
        let timingAccuracy = timingAccuracyScore(seconds: abs(timingDeviationSeconds))
        let durationAccuracy = durationAccuracyScore(fraction: abs(durationDeviation))

        let composite = pitchAccuracy * PracticeConstants.pitchWeight
            + timingAccuracy * PracticeConstants.timingWeight
            + durationAccuracy * PracticeConstants.durationWeight

        let grade = NoteGrade.from(accuracy: composite)

        return NoteScore(
            grade: grade,
            accuracy: composite,
            pitchDeviationCents: pitchDeviationCents,
            timingDeviationSeconds: timingDeviationSeconds,
            durationDeviation: durationDeviation,
            expectedNote: expectedNote,
            detectedNote: detectedNote
        )
    }

    /// Calculate a score when no pitch was detected (silence or below threshold).
    ///
    /// Returns a miss with zero accuracy.
    ///
    /// - Parameter expectedNote: The target swar note name.
    /// - Returns: A `NoteScore` graded as a miss.
    public static func missedNote(expectedNote: String) -> NoteScore {
        NoteScore(
            grade: .miss,
            accuracy: 0.0,
            pitchDeviationCents: 0.0,
            timingDeviationSeconds: 0.0,
            durationDeviation: 0.0,
            expectedNote: expectedNote,
            detectedNote: nil
        )
    }

    // MARK: - Private Methods

    /// Convert cents deviation to a 0.0–1.0 pitch accuracy score.
    ///
    /// Uses linear interpolation between the tolerance thresholds defined
    /// in `PracticeConstants`. Values at or below `perfectPitchCents` score 1.0,
    /// values at or above `fairPitchCents` score 0.0.
    private static func pitchAccuracyScore(cents: Double) -> Double {
        if cents <= PracticeConstants.perfectPitchCents {
            return 1.0
        } else if cents <= PracticeConstants.goodPitchCents {
            return linearInterpolate(
                value: cents,
                low: PracticeConstants.perfectPitchCents,
                high: PracticeConstants.goodPitchCents,
                outputLow: 0.9,
                outputHigh: 0.7
            )
        } else if cents <= PracticeConstants.fairPitchCents {
            return linearInterpolate(
                value: cents,
                low: PracticeConstants.goodPitchCents,
                high: PracticeConstants.fairPitchCents,
                outputLow: 0.7,
                outputHigh: 0.5
            )
        }
        return max(0.0, 0.5 - (cents - PracticeConstants.fairPitchCents) / 100.0)
    }

    /// Convert timing deviation (seconds) to a 0.0–1.0 timing accuracy score.
    private static func timingAccuracyScore(seconds: Double) -> Double {
        if seconds <= PracticeConstants.perfectTimingSeconds {
            return 1.0
        } else if seconds <= PracticeConstants.goodTimingSeconds {
            return linearInterpolate(
                value: seconds,
                low: PracticeConstants.perfectTimingSeconds,
                high: PracticeConstants.goodTimingSeconds,
                outputLow: 0.9,
                outputHigh: 0.7
            )
        } else if seconds <= PracticeConstants.fairTimingSeconds {
            return linearInterpolate(
                value: seconds,
                low: PracticeConstants.goodTimingSeconds,
                high: PracticeConstants.fairTimingSeconds,
                outputLow: 0.7,
                outputHigh: 0.5
            )
        }
        return max(0.0, 0.5 - (seconds - PracticeConstants.fairTimingSeconds) / 1.0)
    }

    /// Convert duration deviation fraction to a 0.0–1.0 duration accuracy score.
    private static func durationAccuracyScore(fraction: Double) -> Double {
        if fraction <= PracticeConstants.perfectDurationFraction {
            return 1.0
        } else if fraction <= PracticeConstants.goodDurationFraction {
            return linearInterpolate(
                value: fraction,
                low: PracticeConstants.perfectDurationFraction,
                high: PracticeConstants.goodDurationFraction,
                outputLow: 0.9,
                outputHigh: 0.7
            )
        } else if fraction <= PracticeConstants.fairDurationFraction {
            return linearInterpolate(
                value: fraction,
                low: PracticeConstants.goodDurationFraction,
                high: PracticeConstants.fairDurationFraction,
                outputLow: 0.7,
                outputHigh: 0.5
            )
        }
        return max(0.0, 0.5 - (fraction - PracticeConstants.fairDurationFraction) / 1.0)
    }

    /// Linear interpolation between two ranges.
    private static func linearInterpolate(
        value: Double,
        low: Double,
        high: Double,
        outputLow: Double,
        outputHigh: Double
    ) -> Double {
        let ratio = (value - low) / (high - low)
        return outputLow + ratio * (outputHigh - outputLow)
    }
}
