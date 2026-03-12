import Foundation

/// Resolves which accidental symbols to display for notes within a measure.
///
/// In standard music notation, accidentals are contextual per measure:
/// - A sharp or flat from the key signature is implicit (not drawn per note).
/// - When a note deviates from the key signature, an accidental is shown.
/// - That accidental persists for the rest of the measure (same octave).
/// - A natural sign cancels a key-signature accidental for the measure.
/// - At the start of each new measure, accidentals reset to the key signature.
///
/// ## Usage
/// ```swift
/// var resolver = AccidentalResolver(keySignature: .gMajor)
/// let accidental = resolver.resolve(midiNumber: 66)  // F#4 — implicit in G major → nil
/// let accidental2 = resolver.resolve(midiNumber: 65) // F4 — needs natural → .natural
/// resolver.resetMeasure()  // At barline
/// ```
public struct AccidentalResolver: Sendable {

    /// The key signature governing default accidentals.
    public let keySignature: KeySignature

    /// Tracks accidentals already displayed in the current measure.
    ///
    /// Key: diatonic step (from `StaffPositionCalculator.midiToDiatonic`).
    /// Value: the semitone offset that was last displayed at that position.
    private var measureAccidentals: [Int: Int] = [:]

    /// Diatonic note letter names indexed by diatonic position mod 7.
    private static let diatonicNames: [String] = ["C", "D", "E", "F", "G", "A", "B"]

    /// Create an accidental resolver for the given key signature.
    ///
    /// - Parameter keySignature: The key signature for accidental resolution.
    public init(keySignature: KeySignature) {
        self.keySignature = keySignature
    }

    /// Resolve the accidental to display for a given MIDI note number.
    ///
    /// Returns `nil` if no accidental needs to be drawn (the note matches
    /// the key signature and no prior accidental in this measure changes it).
    ///
    /// - Parameter midiNumber: MIDI note number (0–127).
    /// - Returns: The accidental to display, or `nil` if none needed.
    public mutating func resolve(midiNumber: Int) -> StaffNoteInfo.Accidental? {
        let diatonicStep = StaffPositionCalculator.midiToDiatonic(midiNumber)
        let semitone = midiNumber % 12
        let diatonicIndex = diatonicStep % 7
        let noteLetter = Self.diatonicNames[diatonicIndex]

        // Determine what the key signature expects for this note letter
        let keyState = keySignature.accidentalFor(diatonicNote: noteLetter)

        // Calculate the expected semitone for the natural diatonic note
        let naturalSemitones = naturalSemitone(for: diatonicIndex)
        let expectedSemitone: Int
        switch keyState {
        case .sharp:
            expectedSemitone = (naturalSemitones + 1) % 12
        case .flat:
            expectedSemitone = (naturalSemitones + 11) % 12
        case .natural:
            expectedSemitone = naturalSemitones
        }

        // Check if we've already displayed an accidental at this diatonic position
        if let previousSemitone = measureAccidentals[diatonicStep] {
            if semitone == previousSemitone {
                // Same as what's already been shown — no new accidental needed
                return nil
            }
        } else {
            // No prior accidental in this measure — check against key signature
            if semitone == expectedSemitone {
                // Matches key signature — no accidental needed
                return nil
            }
        }

        // We need to display an accidental — record it
        measureAccidentals[diatonicStep] = semitone

        // Determine which accidental to show
        let offset = semitone - naturalSemitones
        let normalizedOffset = ((offset % 12) + 12) % 12

        switch normalizedOffset {
        case 1:
            return .sharp
        case 11:
            return .flat
        case 0:
            return .natural
        default:
            // Edge case: enharmonic spellings
            return semitone > naturalSemitones ? .sharp : .flat
        }
    }

    /// Reset accidental tracking at the start of a new measure.
    ///
    /// Call this at each barline so that accidentals from the previous
    /// measure no longer carry over.
    public mutating func resetMeasure() {
        measureAccidentals.removeAll()
    }

    // MARK: - Private Helpers

    /// Get the natural (unaltered) semitone value for a diatonic note index.
    ///
    /// - Parameter diatonicIndex: Index 0–6 where 0=C, 1=D, ..., 6=B.
    /// - Returns: Semitone within an octave (0–11).
    private func naturalSemitone(for diatonicIndex: Int) -> Int {
        // C=0, D=2, E=4, F=5, G=7, A=9, B=11
        let semitones = [0, 2, 4, 5, 7, 9, 11]
        return semitones[diatonicIndex]
    }
}
