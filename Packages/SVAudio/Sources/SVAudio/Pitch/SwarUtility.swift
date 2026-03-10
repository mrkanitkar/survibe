import Foundation

/// Shared utility for frequency-to-swar conversion.
/// Eliminates duplicated swar name arrays across pitch detectors.
/// Uses the canonical Swar enum from Note.swift.
public enum SwarUtility {
    /// Convert a frequency to the nearest Swar note name, octave, and cents offset.
    /// - Parameters:
    ///   - frequency: Detected frequency in Hz
    ///   - referencePitch: Reference pitch for A4 (default: 440 Hz)
    /// - Returns: Tuple of (note name, octave, cents offset from nearest note)
    public static func frequencyToNote(
        _ frequency: Double,
        referencePitch: Double = 440.0
    ) -> (String, Int, Double) { // swiftlint:disable:this large_tuple
        let midiNote = 69.0 + 12.0 * log2(frequency / referencePitch)
        let roundedMidi = Int(round(midiNote))
        let centsOffset = (midiNote - Double(roundedMidi)) * 100.0

        let swarIndex = ((roundedMidi - 60) % 12 + 12) % 12
        let octave = (roundedMidi - 60) / 12 + 4

        // Use Swar enum for canonical note names
        let swar = Swar.allCases[swarIndex]
        return (swar.rawValue, octave, centsOffset)
    }
}
