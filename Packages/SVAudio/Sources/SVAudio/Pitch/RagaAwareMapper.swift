import Foundation

/// Maps detected frequencies to notes using just-intonation scale degrees from a raga.
///
/// Given a `RagaContext`, this mapper:
/// 1. Converts the detected frequency to cents-from-Sa (using `1200 * log2(f / saFreq)`)
/// 2. Octave-reduces to [0, 1200) cents
/// 3. Finds the nearest scale degree by minimum circular distance
/// 4. Reports whether the note is in-raga and the signed cents deviation from the JI target
///
/// Falls back to `EqualTemperamentMapper` for the note name and octave determination,
/// then enriches the result with raga-aware metadata.
public struct RagaAwareMapper: FrequencyToNoteMapper {
    /// The raga tuning context (immutable, Sendable).
    public let ragaContext: RagaContext

    /// Precomputed cents values for each scale degree, sorted ascending.
    private let sortedDegrees: [RagaScaleDegree]

    /// Create a raga-aware mapper.
    ///
    /// - Parameter ragaContext: The raga's JI scale context.
    public init(ragaContext: RagaContext) {
        self.ragaContext = ragaContext
        self.sortedDegrees = ragaContext.scaleDegrees.sorted { $0.cents < $1.cents }
    }

    /// Map a frequency to the nearest note, enriched with raga-aware JI data.
    ///
    /// The algorithm:
    /// 1. Use 12ET to determine the base note name and octave (since Swar mapping is
    ///    identical — Sa=C, Re=D, etc.).
    /// 2. Compute the frequency's position in cents relative to Sa in the same octave.
    /// 3. Find the nearest JI scale degree and compute the signed cents deviation.
    /// 4. Determine if the 12ET-detected note is in the raga's allowed set.
    ///
    /// - Parameters:
    ///   - frequency: Detected frequency in Hz.
    ///   - referencePitch: Reference pitch for A4 (default: 440 Hz).
    /// - Returns: A `NoteMapping` with JI cents deviation and in-raga flag.
    /// - Throws: `AudioValidationError` if inputs are invalid.
    public func mapFrequency(
        _ frequency: Double,
        referencePitch: Double = 440.0
    ) throws -> NoteMapping {
        // Step 1: Get 12ET mapping for base note name and octave
        let (noteName, octave, etCents) = try SwarUtility.frequencyToNote(
            frequency, referencePitch: referencePitch
        )

        // Step 2: Calculate Sa frequency for this octave
        // Sa = C, which is MIDI 60 for octave 4
        let saMidi = 60 + (octave - 4) * 12
        let saFreq = referencePitch * pow(2.0, Double(saMidi - 69) / 12.0)

        // Step 3: Convert detected frequency to cents relative to Sa
        let centsFromSa = 1200.0 * log2(frequency / saFreq)

        // Step 4: Octave-reduce to [0, 1200)
        var reducedCents = centsFromSa.truncatingRemainder(dividingBy: 1200.0)
        if reducedCents < 0 { reducedCents += 1200.0 }

        // Step 5: Find nearest JI scale degree
        let (nearestDegree, jiDeviation) = findNearestDegree(reducedCents)

        // Step 6: Determine if the detected note is in the raga
        let inRaga = ragaContext.allowedSwarNames.contains(noteName)

        return NoteMapping(
            noteName: noteName,
            octave: octave,
            centsOffset: nearestDegree != nil ? jiDeviation : etCents,
            isInRaga: inRaga,
            ragaCentsOffset: nearestDegree != nil ? jiDeviation : nil
        )
    }

    /// Check whether a Swar name is in the raga's scale.
    ///
    /// - Parameter noteName: Swar name (e.g., "Sa", "Tivra Ma").
    /// - Returns: `true` if the note is in the raga's allowed set.
    public func isNoteAllowed(_ noteName: String) -> Bool {
        ragaContext.allowedSwarNames.contains(noteName)
    }

    // MARK: - Private

    /// Find the nearest scale degree to a given cents value (octave-reduced).
    ///
    /// Uses circular distance to handle wrap-around at 1200¢ (Sa at both 0 and 1200).
    ///
    /// - Parameter cents: Octave-reduced cents value in [0, 1200).
    /// - Returns: Tuple of (nearest degree or nil, signed cents deviation).
    private func findNearestDegree(_ cents: Double) -> (RagaScaleDegree?, Double) {
        guard !sortedDegrees.isEmpty else { return (nil, 0) }

        var bestDegree: RagaScaleDegree?
        var bestDistance = Double.infinity
        var bestSigned = 0.0

        for degree in sortedDegrees {
            let diff = cents - degree.cents
            // Circular distance (wrap around 1200¢)
            let wrapped = diff - 1200.0 * round(diff / 1200.0)
            let distance = abs(wrapped)

            if distance < bestDistance {
                bestDistance = distance
                bestDegree = degree
                bestSigned = wrapped
            }
        }

        return (bestDegree, bestSigned)
    }
}
