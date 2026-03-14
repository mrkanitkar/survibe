import Foundation

/// Computes pitch detection confidence from autocorrelation data.
///
/// Replaces the naive `min(1.0, amplitude * 2.0)` heuristic with a
/// peak-to-sidelobe ratio metric. This provides:
/// - High confidence for quiet but clear notes (important for soft playing)
/// - Low confidence for noisy/ambiguous signals regardless of amplitude
/// - Amplitude-independent quality measurement
///
/// Algorithm: `confidence = clamp((peakValue / avgSidelobes - 1.0) / 4.0, 0, 1)`
public enum SpectralConfidence {
    /// Compute confidence from normalized autocorrelation data.
    ///
    /// Measures how prominent the best lag's peak is compared to surrounding
    /// sidelobe values. A pure sinusoid produces peak >> sidelobes (confidence ~1.0),
    /// while white noise produces peak ≈ sidelobes (confidence ~0.0).
    ///
    /// - Parameters:
    ///   - autocorrelation: Normalized autocorrelation array (peak at index 0 = 1.0).
    ///   - bestLag: Index of the detected pitch peak.
    ///   - minLag: Minimum lag considered (based on max detectable frequency).
    /// - Returns: Confidence value in [0, 1].
    nonisolated public static func compute(
        autocorrelation: [Float],
        bestLag: Int,
        minLag: Int
    ) -> Double {
        guard bestLag > minLag,
              bestLag < autocorrelation.count,
              autocorrelation.count > minLag else {
            return 0
        }

        let peakValue = Double(autocorrelation[bestLag])
        guard peakValue > 0 else { return 0 }

        // Compute average of sidelobe values between minLag and the search range,
        // excluding ±3 samples around the peak to avoid contamination.
        let exclusionRadius = 3
        var sidelobeSum = 0.0
        var sidelobeCount = 0

        let searchEnd = min(autocorrelation.count, bestLag + bestLag / 2)
        for lag in minLag..<searchEnd {
            if abs(lag - bestLag) <= exclusionRadius { continue }
            sidelobeSum += Double(abs(autocorrelation[lag]))
            sidelobeCount += 1
        }

        guard sidelobeCount > 0, sidelobeSum > 0 else {
            // No sidelobes found — peak is isolated, high confidence
            return min(1.0, peakValue)
        }

        let avgSidelobes = sidelobeSum / Double(sidelobeCount)
        let ratio = peakValue / avgSidelobes

        // Map ratio to [0, 1]: ratio of 1 → 0 confidence, ratio of 5+ → 1.0
        let confidence = min(1.0, max(0.0, (ratio - 1.0) / 4.0))
        return confidence
    }

    /// Compute confidence from YIN's cumulative mean normalized difference function.
    ///
    /// YIN naturally provides a clarity metric: `1.0 - cmndf[bestTau]`.
    /// A perfect periodic signal has cmndf ≈ 0 at the true period, giving confidence ≈ 1.0.
    /// Noise produces cmndf values near 1.0, giving confidence ≈ 0.0.
    ///
    /// - Parameter cmndfAtBestTau: The CMNDF value at the detected period.
    /// - Returns: Confidence value in [0, 1].
    nonisolated public static func fromYIN(cmndfAtBestTau: Float) -> Double {
        min(1.0, max(0.0, 1.0 - Double(cmndfAtBestTau)))
    }
}
