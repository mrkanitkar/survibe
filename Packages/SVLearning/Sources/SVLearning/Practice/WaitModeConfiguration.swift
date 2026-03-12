import Foundation

/// Criteria for advancing to the next note in Wait Mode.
///
/// Determines what the student must achieve before the engine
/// advances to the next note in the sequence.
public enum WaitCriteria: String, Sendable, CaseIterable {
    /// Student must match the correct pitch (note name + octave).
    case correctPitch
    /// Student must match pitch within a tolerance band.
    case withinTolerance
    /// Student must match pitch and hold for a minimum duration.
    case pitchAndDuration
}

/// Configuration for Wait Mode behavior.
///
/// Controls how the wait-at-each-note state machine operates,
/// including tolerance thresholds, patience timeout, and criteria.
public struct WaitModeConfiguration: Sendable, Equatable {
    /// Whether Wait Mode is enabled.
    public var isEnabled: Bool

    /// Criteria for advancing to the next note.
    public var waitCriteria: WaitCriteria

    /// Maximum seconds to wait for the student before auto-skipping.
    /// Set to 0 for unlimited patience (no auto-skip).
    public var patienceSeconds: Double

    /// Pitch tolerance in cents for the `withinTolerance` criteria.
    public var pitchToleranceCents: Double

    /// Default configuration with reasonable starting values.
    public init(
        isEnabled: Bool = false,
        waitCriteria: WaitCriteria = .correctPitch,
        patienceSeconds: Double = 10.0,
        pitchToleranceCents: Double = 25.0
    ) {
        self.isEnabled = isEnabled
        self.waitCriteria = waitCriteria
        self.patienceSeconds = patienceSeconds
        self.pitchToleranceCents = pitchToleranceCents
    }
}
