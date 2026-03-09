import Testing
@testable import SVAudio

@Suite("Swar/Note Tests")
struct NoteTests {
    @Test("Swar count is 12")
    func testSwarCount() {
        #expect(Swar.allCases.count == 12)
    }

    @Test("Sa has midiOffset 0")
    func testSaMidiOffset() {
        #expect(Swar.sa.midiOffset == 0)
    }

    @Test("Pa has midiOffset 7")
    func testPaMidiOffset() {
        #expect(Swar.pa.midiOffset == 7)
    }

    @Test("Sa at octave 4 is MIDI 60")
    func testSaMidiNote() {
        #expect(Swar.sa.midiNote(octave: 4) == 60)
    }

    @Test("Pa at octave 4 is MIDI 67")
    func testPaMidiNote() {
        #expect(Swar.pa.midiNote(octave: 4) == 67)
    }

    @Test("Sa frequency at octave 4 is approximately 261.63 Hz")
    func testSaFrequency() {
        let freq = Swar.sa.frequency(octave: 4, referencePitch: 440.0)
        // C4 = 261.626 Hz in equal temperament with A4 = 440 Hz
        #expect(abs(freq - 261.626) < 0.01)
    }

    @Test("All swars have unique midi offsets")
    func testUniqueMidiOffsets() {
        let offsets = Swar.allCases.map(\.midiOffset)
        #expect(Set(offsets).count == offsets.count)
    }

    @Test("Swar raw values are readable names")
    func testRawValues() {
        #expect(Swar.sa.rawValue == "Sa")
        #expect(Swar.komalRe.rawValue == "Komal Re")
        #expect(Swar.tivraMa.rawValue == "Tivra Ma")
    }
}
