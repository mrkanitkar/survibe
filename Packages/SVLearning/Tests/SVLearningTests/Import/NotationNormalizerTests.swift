import Foundation
import Testing
@testable import SVLearning

struct NotationNormalizerTests {

    let normalizer = NotationNormalizer()

    // Helpers
    func makeNote(name: String, octave: Int? = nil, duration: Double? = nil, index: Int = 0) -> ParsedNotation.Note {
        ParsedNotation.Note(name: name, octave: octave, durationBeats: duration, modifier: nil, index: index)
    }

    func makeNotation(notes: [ParsedNotation.Note], tempo: Int = 120) -> ParsedNotation {
        ParsedNotation(format: .sargam, notes: notes, tempo: tempo)
    }

    @Test func fillsMissingOctaveWithDefault() throws {
        let notes = [makeNote(name: "Sa"), makeNote(name: "Re", index: 1)]
        let notation = makeNotation(notes: notes)
        let result = try normalizer.normalise(notation)
        #expect(result.notes[0].octave == 4)
        #expect(result.notes[1].octave == 4)
    }

    @Test func fillsMissingDurationWithDefault() throws {
        let notes = [makeNote(name: "Sa"), makeNote(name: "Re", index: 1)]
        let notation = makeNotation(notes: notes)
        let result = try normalizer.normalise(notation)
        #expect(result.notes[0].durationBeats == 1.0)
        #expect(result.notes[1].durationBeats == 1.0)
    }

    @Test func preservesExplicitOctave() throws {
        let notes = [makeNote(name: "Sa", octave: 5)]
        let notation = makeNotation(notes: notes)
        let result = try normalizer.normalise(notation)
        #expect(result.notes[0].octave == 5)
    }

    @Test func preservesExplicitDuration() throws {
        let notes = [makeNote(name: "Sa", octave: 4, duration: 2.0)]
        let notation = makeNotation(notes: notes)
        let result = try normalizer.normalise(notation)
        #expect(result.notes[0].durationBeats == 2.0)
    }

    @Test func throwsOnEmptyNoteArray() {
        let notation = makeNotation(notes: [])
        #expect(throws: ImportError.self) {
            try normalizer.normalise(notation)
        }
    }

    @Test func estimatesDurationSeconds() throws {
        // 4 notes × 1 beat each at 120 BPM = 2 seconds
        let notes = (0..<4).map { makeNote(name: "Sa", octave: 4, duration: 1.0, index: $0) }
        let notation = makeNotation(notes: notes, tempo: 120)
        let seconds = normalizer.estimateDurationSeconds(notation, tempo: 120)
        #expect(seconds == 2)
    }

    @Test func estimatesDurationSecondsWithHalfNotes() throws {
        // 4 notes × 2 beats each at 120 BPM = 4 seconds
        let notes = (0..<4).map { makeNote(name: "Sa", octave: 4, duration: 2.0, index: $0) }
        let notation = makeNotation(notes: notes, tempo: 120)
        let seconds = normalizer.estimateDurationSeconds(notation, tempo: 120)
        #expect(seconds == 4)
    }

    @Test func estimatesMinimumOneDurationSecond() {
        let notation = makeNotation(notes: [])
        let seconds = normalizer.estimateDurationSeconds(notation, tempo: 120)
        #expect(seconds >= 1)
    }
}
