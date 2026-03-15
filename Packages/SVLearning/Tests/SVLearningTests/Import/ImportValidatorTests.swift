import Foundation
import Testing
@testable import SVLearning

struct ImportValidatorTests {

    let validator = ImportValidator()

    // MARK: - Helpers

    func makeNote(name: String, octave: Int = 4, duration: Double = 1.0, index: Int = 0) -> ParsedNotation.Note {
        ParsedNotation.Note(name: name, octave: octave, durationBeats: duration, modifier: nil, index: index)
    }

    func makeScale(count: Int = 7) -> ParsedNotation {
        let names = ["Sa", "Re", "Ga", "Ma", "Pa", "Dha", "Ni"]
        let notes = (0..<count).map { i in
            makeNote(name: names[i % names.count], index: i)
        }
        return ParsedNotation(format: .sargam, notes: notes, tempo: 120, keySignature: "C major")
    }

    // MARK: - Note Count

    @Test func noWarningForValidNoteCount() {
        let notation = makeScale(count: 7)
        let warnings = validator.validate(notation)
        let errors = warnings.filter { $0.severity == .error }
        #expect(errors.isEmpty)
    }

    @Test func errorForTooFewNotes() {
        let notes = [makeNote(name: "Sa")]
        let notation = ParsedNotation(format: .sargam, notes: notes, tempo: 120)
        let warnings = validator.validate(notation)
        let errors = warnings.filter { $0.severity == .error }
        #expect(!errors.isEmpty)
    }

    @Test func infoForTooManyNotes() {
        let notes = (0..<501).map { makeNote(name: "Sa", index: $0) }
        let notation = ParsedNotation(format: .sargam, notes: notes, tempo: 120)
        let warnings = validator.validate(notation)
        let infos = warnings.filter { $0.severity == .info }
        #expect(!infos.isEmpty)
    }

    // MARK: - Tempo

    @Test func noWarningForNormalTempo() {
        let notation = makeScale()
        let warnings = validator.validate(notation)
        let tempoWarnings = warnings.filter { $0.message.contains("BPM") }
        #expect(tempoWarnings.isEmpty)
    }

    @Test func warningForSlowTempo() {
        let notes = (0..<5).map { makeNote(name: "Sa", index: $0) }
        let notation = ParsedNotation(format: .sargam, notes: notes, tempo: 10, keySignature: "C major")
        let warnings = validator.validate(notation)
        let tempoWarnings = warnings.filter { $0.message.contains("BPM") && $0.severity == .warning }
        #expect(!tempoWarnings.isEmpty)
    }

    @Test func warningForFastTempo() {
        let notes = (0..<5).map { makeNote(name: "Sa", index: $0) }
        let notation = ParsedNotation(format: .sargam, notes: notes, tempo: 400, keySignature: "C major")
        let warnings = validator.validate(notation)
        let tempoWarnings = warnings.filter { $0.message.contains("BPM") && $0.severity == .warning }
        #expect(!tempoWarnings.isEmpty)
    }

    // MARK: - Octave Range

    @Test func warningForOctaveOutOfRange() {
        let notes = [makeNote(name: "Sa", octave: 9, index: 0),
                     makeNote(name: "Re", index: 1),
                     makeNote(name: "Ga", index: 2)]
        let notation = ParsedNotation(format: .sargam, notes: notes, tempo: 120, keySignature: "C major")
        let warnings = validator.validate(notation)
        let octaveWarnings = warnings.filter { $0.noteIndex == 0 }
        #expect(!octaveWarnings.isEmpty)
    }

    @Test func noWarningForValidOctave() {
        let notation = makeScale()
        let warnings = validator.validate(notation)
        let octaveWarnings = warnings.filter { $0.message.contains("octave") }
        #expect(octaveWarnings.isEmpty)
    }

    // MARK: - Key Signature

    @Test func infoForMissingKeySignature() {
        let notes = (0..<5).map { makeNote(name: "Sa", index: $0) }
        let notation = ParsedNotation(format: .sargam, notes: notes, tempo: 120, keySignature: "")
        let warnings = validator.validate(notation)
        let keyWarnings = warnings.filter { $0.message.contains("key signature") }
        #expect(!keyWarnings.isEmpty)
        #expect(keyWarnings[0].severity == .info)
    }

    @Test func noWarningWhenKeySignaturePresent() {
        let notation = makeScale()
        let warnings = validator.validate(notation)
        let keyWarnings = warnings.filter { $0.message.contains("key signature") }
        #expect(keyWarnings.isEmpty)
    }

    // MARK: - Durations

    @Test func infoForVeryShortDuration() {
        let notes = [makeNote(name: "Sa", octave: 4, duration: 0.0625, index: 0),
                     makeNote(name: "Re", index: 1),
                     makeNote(name: "Ga", index: 2)]
        let notation = ParsedNotation(format: .sargam, notes: notes, tempo: 120, keySignature: "C major")
        let warnings = validator.validate(notation)
        let durationWarnings = warnings.filter { $0.noteIndex == 0 }
        #expect(!durationWarnings.isEmpty)
    }
}
