import Foundation
import Testing
@testable import SVLearning

struct MusicXMLParserTests {

    let parser = MusicXMLParser()

    // Minimal valid MusicXML with one C4 quarter note
    let singleNoteXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <score-partwise>
      <part id="P1">
        <measure number="1">
          <note>
            <pitch><step>C</step><octave>4</octave></pitch>
            <type>quarter</type>
          </note>
        </measure>
      </part>
    </score-partwise>
    """

    let cMajorScaleXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <score-partwise>
      <part id="P1">
        <measure number="1">
          <attributes>
            <key><fifths>0</fifths><mode>major</mode></key>
            <time><beats>4</beats><beat-type>4</beat-type></time>
          </attributes>
          <note><pitch><step>C</step><octave>4</octave></pitch><type>quarter</type></note>
          <note><pitch><step>D</step><octave>4</octave></pitch><type>quarter</type></note>
          <note><pitch><step>E</step><octave>4</octave></pitch><type>quarter</type></note>
          <note><pitch><step>F</step><octave>4</octave></pitch><type>quarter</type></note>
        </measure>
      </part>
    </score-partwise>
    """

    let sharpNoteXML = """
    <?xml version="1.0" encoding="UTF-8"?>
    <score-partwise>
      <part id="P1">
        <measure number="1">
          <note>
            <pitch><step>F</step><alter>1</alter><octave>4</octave></pitch>
            <type>quarter</type>
          </note>
        </measure>
      </part>
    </score-partwise>
    """

    @Test func parsesSingleNote() throws {
        let input = NotationInput(text: singleNoteXML, declaredFormat: .musicXML)
        let result = try parser.parse(input)
        #expect(result.notes.count == 1)
        #expect(result.notes[0].name == "C")
        #expect(result.notes[0].octave == 4)
        #expect(result.notes[0].durationBeats == 1.0)
    }

    @Test func parsesCMajorScale() throws {
        let input = NotationInput(text: cMajorScaleXML, declaredFormat: .musicXML)
        let result = try parser.parse(input)
        #expect(result.notes.count == 4)
        #expect(result.notes[0].name == "C")
        #expect(result.notes[1].name == "D")
        #expect(result.notes[2].name == "E")
        #expect(result.notes[3].name == "F")
    }

    @Test func parsesKeySignature() throws {
        let input = NotationInput(text: cMajorScaleXML, declaredFormat: .musicXML)
        let result = try parser.parse(input)
        #expect(result.keySignature == "C major")
    }

    @Test func parsesTimeSignature() throws {
        let input = NotationInput(text: cMajorScaleXML, declaredFormat: .musicXML)
        let result = try parser.parse(input)
        #expect(result.timeSignature == "4/4")
    }

    @Test func parsesSharpAccidental() throws {
        let input = NotationInput(text: sharpNoteXML, declaredFormat: .musicXML)
        let result = try parser.parse(input)
        #expect(result.notes[0].name == "F#")
        #expect(result.notes[0].modifier == "sharp")
    }

    @Test func throwsOnEmptyInput() {
        let input = NotationInput(text: "", declaredFormat: .musicXML)
        #expect(throws: ImportError.self) {
            try parser.parse(input)
        }
    }

    @Test func throwsOnMalformedXML() {
        let input = NotationInput(text: "<broken><xml>", declaredFormat: .musicXML)
        #expect(throws: ImportError.self) {
            try parser.parse(input)
        }
    }

    @Test func skipsRestElements() throws {
        let restXML = """
        <?xml version="1.0"?>
        <score-partwise><part id="P1"><measure number="1">
          <note><rest/><type>quarter</type></note>
          <note><pitch><step>C</step><octave>4</octave></pitch><type>quarter</type></note>
        </measure></part></score-partwise>
        """
        let input = NotationInput(text: restXML, declaredFormat: .musicXML)
        let result = try parser.parse(input)
        #expect(result.notes.count == 1)
        #expect(result.notes[0].name == "C")
    }

    @Test func formatIsMusicXML() throws {
        let input = NotationInput(text: singleNoteXML, declaredFormat: .musicXML)
        let result = try parser.parse(input)
        #expect(result.format == .musicXML)
    }
}
