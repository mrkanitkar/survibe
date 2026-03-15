import Foundation
import Testing
@testable import SVLearning

struct WesternNotationParserTests {

    let parser = WesternNotationParser()

    @Test func parsesSimpleCMajorScale() throws {
        let input = NotationInput(text: "C4 D4 E4 F4 G4 A4 B4 C5", declaredFormat: .western)
        let result = try parser.parse(input)
        #expect(result.notes.count == 8)
        #expect(result.notes[0].name == "C")
        #expect(result.notes[0].octave == 4)
        #expect(result.notes[7].name == "C")
        #expect(result.notes[7].octave == 5)
    }

    @Test func parsesSharpAccidental() throws {
        let input = NotationInput(text: "C#4 D#4", declaredFormat: .western)
        let result = try parser.parse(input)
        #expect(result.notes[0].name == "C#")
        #expect(result.notes[0].modifier == "sharp")
    }

    @Test func parsesFlatAccidental() throws {
        let input = NotationInput(text: "Db4 Eb4", declaredFormat: .western)
        let result = try parser.parse(input)
        #expect(result.notes[0].name == "Db")
        #expect(result.notes[0].modifier == "flat")
    }

    @Test func parsesDurationSuffix() throws {
        let input = NotationInput(text: "C4q D4h E4w F4e G4s", declaredFormat: .western)
        let result = try parser.parse(input)
        #expect(result.notes[0].durationBeats == 1.0)
        #expect(result.notes[1].durationBeats == 2.0)
        #expect(result.notes[2].durationBeats == 4.0)
        #expect(result.notes[3].durationBeats == 0.5)
        #expect(result.notes[4].durationBeats == 0.25)
    }

    @Test func parsesNoteWithoutOctave() throws {
        let input = NotationInput(text: "C D E", declaredFormat: .western)
        let result = try parser.parse(input)
        #expect(result.notes.count == 3)
        #expect(result.notes[0].octave == nil)
    }

    @Test func extractsKeySignatureFromHeader() throws {
        let input = NotationInput(text: "Key: G major\nG4 A4 B4", declaredFormat: .western)
        let result = try parser.parse(input)
        #expect(result.keySignature == "G major")
        #expect(result.notes.count == 3)
    }

    @Test func throwsOnEmptyInput() {
        let input = NotationInput(text: "   ", declaredFormat: .western)
        #expect(throws: ImportError.self) {
            try parser.parse(input)
        }
    }

    @Test func throwsWhenNoNotesFound() {
        let input = NotationInput(text: "hello world xyz", declaredFormat: .western)
        #expect(throws: ImportError.self) {
            try parser.parse(input)
        }
    }

    @Test func assignsCorrectIndexes() throws {
        let input = NotationInput(text: "C4 D4 E4", declaredFormat: .western)
        let result = try parser.parse(input)
        #expect(result.notes[0].index == 0)
        #expect(result.notes[1].index == 1)
        #expect(result.notes[2].index == 2)
    }

    @Test func formatIsWestern() throws {
        let input = NotationInput(text: "C4 D4 E4", declaredFormat: .western)
        let result = try parser.parse(input)
        #expect(result.format == .western)
    }
}
