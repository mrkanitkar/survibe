import Foundation
import Testing
@testable import SVLearning

struct FormatDetectorTests {

    let detector = FormatDetector()

    @Test func detectsMusicXMLByXMLTags() {
        let input = NotationInput(text: "<?xml version=\"1.0\"?><score-partwise><part-list><measure><note><pitch>")
        #expect(detector.detect(input) == .musicXML)
    }

    @Test func detectsMusicXMLByFilenameXML() {
        let input = NotationInput(text: "any text", filenameHint: "mysong.xml")
        #expect(detector.detect(input) == .musicXML)
    }

    @Test func detectsMusicXMLByFilenameMXL() {
        let input = NotationInput(text: "any text", filenameHint: "mysong.mxl")
        #expect(detector.detect(input) == .musicXML)
    }

    @Test func detectsSargamByNoteNames() {
        let input = NotationInput(text: "Sa Re Ga Ma Pa Dha Ni Sa")
        #expect(detector.detect(input) == .sargam)
    }

    @Test func detectsSargamByKomalModifier() {
        let input = NotationInput(text: "Sa Komal Re Ga Ma Pa")
        #expect(detector.detect(input) == .sargam)
    }

    @Test func detectsSargamByDevanagari() {
        let input = NotationInput(text: "सा रे ग म प ध नि")
        #expect(detector.detect(input) == .sargam)
    }

    @Test func detectsWesternByNoteOctavePattern() {
        let input = NotationInput(text: "C4 D4 E4 F4 G4 A4 B4 C5")
        #expect(detector.detect(input) == .western)
    }

    @Test func detectsWesternWithAccidentals() {
        let input = NotationInput(text: "C4 D#4 Eb4 F4 G#4")
        #expect(detector.detect(input) == .western)
    }

    @Test func returnsDeclaredFormatWithoutDetection() {
        let input = NotationInput(text: "anything", declaredFormat: .sargam)
        #expect(detector.detect(input) == .sargam)
    }

    @Test func returnsUnknownForEmptyInput() {
        let input = NotationInput(text: "")
        #expect(detector.detect(input) == .unknown)
    }

    @Test func returnsUnknownForNonsenseInput() {
        let input = NotationInput(text: "hello world 12345 xyz")
        #expect(detector.detect(input) == .unknown)
    }
}
