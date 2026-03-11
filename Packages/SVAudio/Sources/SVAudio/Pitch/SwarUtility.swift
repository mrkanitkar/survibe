import Foundation

/// Errors thrown by audio input validation.
///
/// Used by `SwarUtility`, `ChromagramDSP`, and `MetronomePlayer` to reject
/// invalid parameters with clear diagnostics instead of returning silent defaults.
public enum AudioValidationError: Error, Sendable, CustomStringConvertible {
    /// Frequency value is non-positive, NaN, or infinite.
    case invalidFrequency(Double)
    /// Reference pitch value is non-positive, NaN, or infinite.
    case invalidReferencePitch(Double)
    /// BPM value is outside the valid range (1–300).
    case invalidBPM(Double)
    /// Sample rate is non-positive.
    case invalidSampleRate(Double)
    /// Buffer size is not a power of two or is too small.
    case invalidBufferSize(Int)

    public var description: String {
        switch self {
        case .invalidFrequency(let value):
            "Invalid frequency: \(value) Hz (must be positive and finite)"
        case .invalidReferencePitch(let value):
            "Invalid reference pitch: \(value) Hz (must be positive and finite)"
        case .invalidBPM(let value):
            "Invalid BPM: \(value) (must be between 1 and 300)"
        case .invalidSampleRate(let value):
            "Invalid sample rate: \(value) Hz (must be positive)"
        case .invalidBufferSize(let value):
            "Invalid buffer size: \(value) (must be a positive power of two)"
        }
    }
}

/// Shared utility for frequency-to-swar conversion.
/// Eliminates duplicated swar name arrays across pitch detectors.
/// Uses the canonical Swar enum from Note.swift.
public enum SwarUtility {
    // MARK: - Constants

    /// Western note names mapped by semitone index from C.
    private static let westernNames = [
        "C", "Db", "D", "Eb", "E", "F",
        "F#", "G", "Ab", "A", "Bb", "B",
    ]

    // MARK: - Public Methods

    /// Convert a frequency to the nearest Swar note name, octave, and cents offset.
    ///
    /// Validates that both frequency and reference pitch are positive finite values
    /// before computing the conversion. Returns an empty result for invalid inputs.
    ///
    /// - Parameters:
    ///   - frequency: Detected frequency in Hz (must be positive and finite).
    ///   - referencePitch: Reference pitch for A4 (default: 440 Hz).
    /// - Returns: Tuple of (note name, octave, cents offset from nearest note).
    /// - Throws: `AudioValidationError.invalidFrequency` or
    ///           `AudioValidationError.invalidReferencePitch` if inputs are invalid.
    public static func frequencyToNote(
        _ frequency: Double,
        referencePitch: Double = 440.0
    ) throws -> (String, Int, Double) { // swiftlint:disable:this large_tuple
        guard frequency > 0, frequency.isFinite else {
            throw AudioValidationError.invalidFrequency(frequency)
        }
        guard referencePitch > 0, referencePitch.isFinite else {
            throw AudioValidationError.invalidReferencePitch(referencePitch)
        }

        let midiNote = 69.0 + 12.0 * log2(frequency / referencePitch)
        let roundedMidi = Int(round(midiNote))
        let centsOffset = (midiNote - Double(roundedMidi)) * 100.0

        let swarIndex = ((roundedMidi - 60) % 12 + 12) % 12
        // Use floor division so MIDI 59 → octave 3, not 4
        let octave = Int(floor(Double(roundedMidi - 60) / 12.0)) + 4

        // Use Swar enum for canonical note names
        let swar = Swar.allCases[swarIndex]
        return (swar.rawValue, octave, centsOffset)
    }

    /// Get the Western note name (C, D, E, etc.) for a given Swar note name.
    /// - Parameter swarName: Indian classical note name (e.g., "Sa", "Re", "Ga")
    /// - Returns: Western note name (e.g., "C", "D", "E"), or the input if not found
    public static func westernName(for swarName: String) -> String {
        guard let swar = Swar.allCases.first(where: { $0.rawValue == swarName }) else {
            return swarName
        }
        return westernNames[swar.midiOffset]
    }
}
