import Foundation

/// A single scale degree within a raga, holding its Swar identity and JI tuning.
///
/// Each degree stores the just-intonation frequency ratio (relative to Sa = 1/1)
/// and the equivalent cents value for fast lookup during pitch detection.
public struct RagaScaleDegree: Sendable, Equatable {
    /// Swar name (e.g., "Sa", "Tivra Ma", "Komal Re").
    public let swar: Swar

    /// Just-intonation frequency ratio relative to Sa (e.g., 45/32 for Tivra Ma in Yaman).
    public let ratio: Double

    /// Cents value of this ratio (1200 * log2(ratio)), pre-computed for speed.
    public let cents: Double

    /// Create a raga scale degree.
    ///
    /// - Parameters:
    ///   - swar: The Swar enum case.
    ///   - ratio: JI frequency ratio relative to Sa (octave-reduced, in [1.0, 2.0)).
    public init(swar: Swar, ratio: Double) {
        self.swar = swar
        self.ratio = ratio
        self.cents = 1200.0 * log2(ratio)
    }
}

/// Immutable, Sendable snapshot of a raga's tuning context.
///
/// Built by `RagaTuningProvider` from the Microtonality `TuningTable` presets.
/// Once created, this struct is safe to pass across actor boundaries and use
/// in nonisolated DSP code.
///
/// Contains:
/// - The raga name
/// - Ordered scale degrees with JI ratios and cents
/// - A set of allowed Swar names for fast membership checks
public struct RagaContext: Sendable, Equatable {
    /// Raga name (e.g., "Yaman", "Bhairav").
    public let ragaName: String

    /// Ordered scale degrees (ascending by cents value).
    /// Typically 7 for a sampurna (complete) raga, but may be 5-6 for audav/shadav ragas.
    public let scaleDegrees: [RagaScaleDegree]

    /// Set of allowed Swar raw values for O(1) membership checks.
    public let allowedSwarNames: Set<String>

    /// Create a raga context.
    ///
    /// - Parameters:
    ///   - ragaName: Name of the raga.
    ///   - scaleDegrees: Ordered array of scale degrees with JI ratios.
    public init(ragaName: String, scaleDegrees: [RagaScaleDegree]) {
        self.ragaName = ragaName
        self.scaleDegrees = scaleDegrees
        self.allowedSwarNames = Set(scaleDegrees.map(\.swar.rawValue))
    }
}
