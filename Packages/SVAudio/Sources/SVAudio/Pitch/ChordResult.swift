import Foundation

// MARK: - Detected Pitch

/// A single detected note within a polyphonic chord analysis.
///
/// Contains the exact frequency, MIDI note, pitch class, and intonation data
/// for one constituent note of a detected chord. Used by `ChromagramDSP`
/// to represent individual notes found via FFT peak analysis.
public struct DetectedPitch: Sendable, Equatable {
    /// Detected frequency in Hz.
    public let frequency: Double

    /// Signal amplitude contribution (0.0 to 1.0).
    public let amplitude: Double

    /// MIDI note number (e.g., 60 = C4/Sa4).
    public let midiNote: Int

    /// Pitch class (0–11, where 0 = C/Sa).
    public let pitchClass: Int

    /// Swar note name (e.g., "Sa", "Re").
    public let noteName: String

    /// Octave number.
    public let octave: Int

    /// Cents offset from the nearest note (-50 to +50).
    public let centsOffset: Double

    /// Detection confidence (0.0 to 1.0).
    public let confidence: Double

    public init(
        frequency: Double,
        amplitude: Double,
        midiNote: Int,
        pitchClass: Int,
        noteName: String,
        octave: Int,
        centsOffset: Double,
        confidence: Double
    ) {
        self.frequency = frequency
        self.amplitude = amplitude
        self.midiNote = midiNote
        self.pitchClass = pitchClass
        self.noteName = noteName
        self.octave = octave
        self.centsOffset = centsOffset
        self.confidence = confidence
    }
}

// MARK: - Chord Quality

/// Chord quality classification.
///
/// Defines the interval pattern that distinguishes chord types.
/// Each case has a set of semitone intervals from the root.
public enum ChordQuality: String, Sendable, CaseIterable {
    case major = "Major"
    case minor = "Minor"
    case diminished = "Dim"
    case augmented = "Aug"
    case major7 = "Maj7"
    case minor7 = "Min7"
    case dominant7 = "Dom7"
    case sus2 = "Sus2"
    case sus4 = "Sus4"

    /// Semitone intervals from root that define this chord quality.
    public var intervals: Set<Int> {
        switch self {
        case .major: [0, 4, 7]
        case .minor: [0, 3, 7]
        case .diminished: [0, 3, 6]
        case .augmented: [0, 4, 8]
        case .major7: [0, 4, 7, 11]
        case .minor7: [0, 3, 7, 10]
        case .dominant7: [0, 4, 7, 10]
        case .sus2: [0, 2, 7]
        case .sus4: [0, 5, 7]
        }
    }
}

// MARK: - Chord Name

/// Identifies a chord by root note and quality.
///
/// Produced by template matching in `ChromagramDSP.matchChord`.
/// Contains both Western and Sargam display names for the UI.
public struct ChordName: Sendable, Equatable {
    /// Root pitch class (0–11, where 0 = C/Sa).
    public let rootPitchClass: Int

    /// Chord quality (e.g., .major, .minor, .diminished).
    public let quality: ChordQuality

    /// Western display name (e.g., "C Major", "Am", "F#dim").
    public let displayName: String

    /// Sargam display name (e.g., "Sa Major", "Dha Minor").
    public let sargamDisplayName: String

    /// How well the detected notes match the chord template (0.0 to 1.0).
    public let matchConfidence: Double

    public init(
        rootPitchClass: Int,
        quality: ChordQuality,
        displayName: String,
        sargamDisplayName: String,
        matchConfidence: Double
    ) {
        self.rootPitchClass = rootPitchClass
        self.quality = quality
        self.displayName = displayName
        self.sargamDisplayName = sargamDisplayName
        self.matchConfidence = matchConfidence
    }
}

// MARK: - Chord Result

/// Complete result from the polyphonic chord detection pipeline.
///
/// Contains all individually detected notes, the best-match chord name,
/// the overall RMS amplitude, and a timestamp. Produced by
/// `ChromagramDSP.analyzeChord`.
public struct ChordResult: Sendable, Equatable {
    /// All detected notes, sorted by frequency ascending.
    public let detectedPitches: [DetectedPitch]

    /// Best-match chord name, nil if fewer than 3 notes detected.
    public let chordName: ChordName?

    /// Overall RMS amplitude of the input signal.
    public let amplitude: Double

    /// Timestamp of the detection.
    public let timestamp: Date

    /// Set of MIDI note numbers for keyboard highlighting.
    public var activeMidiNotes: Set<Int> {
        Set(detectedPitches.map(\.midiNote))
    }

    public init(
        detectedPitches: [DetectedPitch],
        chordName: ChordName?,
        amplitude: Double,
        timestamp: Date = Date()
    ) {
        self.detectedPitches = detectedPitches
        self.chordName = chordName
        self.amplitude = amplitude
        self.timestamp = timestamp
    }
}
