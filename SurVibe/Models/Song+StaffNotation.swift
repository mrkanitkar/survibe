import Foundation
import SVLearning

/// Extension adding staff notation support to the Song model.
///
/// Provides typed computed properties for key signature and time signature
/// that map from the raw string fields stored in SwiftData/CloudKit.
extension Song {

    /// Returns the song's key signature as a typed enum.
    ///
    /// Maps `keySignatureRaw` (e.g., "G", "Bb") to `KeySignature`.
    /// Returns `.cMajor` when the raw value is empty or unrecognized.
    var keySignatureEnum: KeySignature {
        KeySignature.from(rawString: keySignatureRaw)
    }

    /// Returns the song's time signature as a typed enum.
    ///
    /// Maps `timeSignatureRaw` (e.g., "3/4", "6/8") to `TimeSignature`.
    /// Returns `.fourFour` when the raw value is empty or unrecognized.
    var timeSignatureEnum: TimeSignature {
        TimeSignature.from(rawString: timeSignatureRaw)
    }
}
