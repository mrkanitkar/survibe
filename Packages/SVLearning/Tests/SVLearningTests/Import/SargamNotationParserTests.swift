import Foundation
import Testing
@testable import SVLearning

struct SargamNotationParserTests {

    let parser = SargamNotationParser()

    @Test func parsesSimpleSargamScale() throws {
        let input = NotationInput(text: "Sa Re Ga Ma Pa Dha Ni Sa", declaredFormat: .sargam)
        let result = try parser.parse(input)
        #expect(result.notes.count == 8)
        #expect(result.notes[0].name == "Sa")
        #expect(result.notes[4].name == "Pa")
    }

    @Test func parsesKomalModifier() throws {
        let input = NotationInput(text: "Sa Komal.Re Ga Ma", declaredFormat: .sargam)
        let result = try parser.parse(input)
        #expect(result.notes[1].modifier == "komal")
        #expect(result.notes[1].name == "Re")
    }

    @Test func parsesTivraModifier() throws {
        let input = NotationInput(text: "Sa Re Ga Tivra.Ma Pa", declaredFormat: .sargam)
        let result = try parser.parse(input)
        #expect(result.notes[3].modifier == "tivra")
        #expect(result.notes[3].name == "Ma")
    }

    @Test func parsesUpperOctaveApostrophe() throws {
        let input = NotationInput(text: "Sa' Re' Ga'", declaredFormat: .sargam)
        let result = try parser.parse(input)
        #expect(result.notes[0].octave == 5)
        #expect(result.notes[0].name == "Sa")
    }

    @Test func parsesLowerOctaveDot() throws {
        let input = NotationInput(text: "Ni.", declaredFormat: .sargam)
        let result = try parser.parse(input)
        #expect(result.notes[0].octave == 3)
        #expect(result.notes[0].name == "Ni")
    }

    @Test func parsesDevanagariText() throws {
        let input = NotationInput(text: "सा रे ग म प ध नि", declaredFormat: .sargam)
        let result = try parser.parse(input)
        #expect(result.notes.count == 7)
        #expect(result.notes[0].name == "Sa")
    }

    @Test func throwsOnEmptyInput() {
        let input = NotationInput(text: "   ", declaredFormat: .sargam)
        #expect(throws: ImportError.self) {
            try parser.parse(input)
        }
    }

    @Test func throwsWhenNoNotesFound() {
        let input = NotationInput(text: "hello world 12345", declaredFormat: .sargam)
        #expect(throws: ImportError.self) {
            try parser.parse(input)
        }
    }

    @Test func assignsCorrectIndexes() throws {
        let input = NotationInput(text: "Sa Re Ga", declaredFormat: .sargam)
        let result = try parser.parse(input)
        #expect(result.notes[0].index == 0)
        #expect(result.notes[1].index == 1)
        #expect(result.notes[2].index == 2)
    }

    @Test func formatIsSargam() throws {
        let input = NotationInput(text: "Sa Re Ga", declaredFormat: .sargam)
        let result = try parser.parse(input)
        #expect(result.format == .sargam)
    }
}
