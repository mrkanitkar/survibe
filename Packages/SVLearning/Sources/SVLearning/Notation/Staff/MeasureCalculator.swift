import Foundation

/// Result of measure assignment for a sequence of notes.
///
/// Contains the notes grouped by measure and the x-positions
/// of barlines for the renderer to draw.
public struct MeasureLayout: Sendable, Equatable {
    /// Notes with their `measureNumber` field populated.
    public let notes: [StaffNoteInfo]

    /// X-positions where barlines should be drawn.
    public let barlinePositions: [Double]

    /// Total number of measures.
    public let measureCount: Int
}

/// Assigns notes to measures and calculates barline positions.
///
/// Divides a sequence of notes into measures based on the time signature's
/// beats-per-measure capacity. Each note's `measureNumber` is set, and
/// barline x-positions are computed for the renderer.
///
/// ## Algorithm
/// Iterates through notes, accumulating beat durations. When the
/// accumulated duration fills a measure, the measure counter increments
/// and a barline position is recorded at the next note's x-position.
public enum MeasureCalculator {

    /// Assign measure numbers to a sequence of notes based on the time signature.
    ///
    /// Notes that straddle a measure boundary are placed in the measure
    /// where they start. The returned array has the same count as the input
    /// with `measureNumber` and potentially adjusted values.
    ///
    /// - Parameters:
    ///   - notes: Notes with x-positions already assigned.
    ///   - timeSignature: The time signature governing measure capacity.
    /// - Returns: A `MeasureLayout` with measure assignments and barline positions.
    public static func assignMeasures(
        notes: [StaffNoteInfo],
        timeSignature: TimeSignature
    ) -> MeasureLayout {
        guard !notes.isEmpty else {
            return MeasureLayout(notes: [], barlinePositions: [], measureCount: 0)
        }

        let beatsPerMeasure = timeSignature.beatsPerMeasure
        var result = notes
        var barlinePositions: [Double] = []
        var currentMeasure = 0
        var accumulatedBeats = 0.0

        for index in result.indices {
            result[index].measureNumber = currentMeasure

            accumulatedBeats += result[index].duration

            // Check if we've filled the current measure
            while accumulatedBeats >= beatsPerMeasure - 0.001 {
                accumulatedBeats -= beatsPerMeasure
                currentMeasure += 1

                // Record barline position at the next note's x position
                if index + 1 < result.count {
                    let barlineX = result[index + 1].xPosition - 5.0
                    barlinePositions.append(barlineX)
                }
            }
        }

        return MeasureLayout(
            notes: result,
            barlinePositions: barlinePositions,
            measureCount: currentMeasure + 1
        )
    }

    /// Calculate barline positions from a pre-measured note sequence.
    ///
    /// Extracts barline positions by detecting measure number transitions.
    /// Useful when notes already have measure numbers assigned.
    ///
    /// - Parameter notes: Notes with `measureNumber` already set.
    /// - Returns: X-positions for barlines.
    public static func barlinePositions(from notes: [StaffNoteInfo]) -> [Double] {
        guard notes.count > 1 else { return [] }

        var positions: [Double] = []
        for index in 1..<notes.count
        where notes[index].measureNumber != notes[index - 1].measureNumber {
            let barlineX = notes[index].xPosition - 5.0
            positions.append(barlineX)
        }
        return positions
    }
}
