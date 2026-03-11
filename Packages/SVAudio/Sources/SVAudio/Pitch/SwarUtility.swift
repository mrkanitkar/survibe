import Foundation

/// Shared utility for frequency-to-swar conversion.
/// Eliminates duplicated swar name arrays across pitch detectors.
/// Uses the canonical Swar enum from Note.swift.
public enum SwarUtility {
    // MARK: - Constants

    /// Western note names mapped by semitone index from C.
    private static let westernNames = [
        "C", "Db", "D", "Eb", "E", "F",
        "F#", "G", "Ab", "A", "Bb", "B"
    ]

    // MARK: - Public Methods

    /// Convert a frequency to the nearest Swar note name, octave, and cents offset.
    /// - Parameters:
    ///   - frequency: Detected frequency in Hz
    ///   - referencePitch: Reference pitch for A4 (default: 440 Hz)
    /// - Returns: Tuple of (note name, octave, cents offset from nearest note)
    public static func frequencyToNote(
        _ frequency: Double,
        referencePitch: Double = 440.0
    ) -> (String, Int, Double) { // swiftlint:disable:this large_tuple
        // Guard against invalid inputs that would produce NaN/Infinity from log2
        guard frequency > 0, referencePitch > 0,
              frequency.isFinite, referencePitch.isFinite
        else {
            return ("", 0, 0)
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
