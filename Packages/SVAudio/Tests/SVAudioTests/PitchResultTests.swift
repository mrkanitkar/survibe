import Foundation
import Testing

@testable import SVAudio

@Suite("PitchResult Tests")
struct PitchResultTests {
    @Test("PitchResult initializes with correct values")
    func testInit() {
        let result = PitchResult(
            frequency: 261.63,
            amplitude: 0.8,
            noteName: "Sa",
            octave: 4,
            centsOffset: -2.5,
            confidence: 0.95
        )

        #expect(result.frequency == 261.63)
        #expect(result.amplitude == 0.8)
        #expect(result.noteName == "Sa")
        #expect(result.octave == 4)
        #expect(result.centsOffset == -2.5)
        #expect(result.confidence == 0.95)
    }

    @Test("PitchResult equality")
    func testEquality() {
        let date = Date()
        let a = PitchResult(
            frequency: 440.0, amplitude: 0.5, noteName: "Pa",
            octave: 4, centsOffset: 0, timestamp: date, confidence: 1.0
        )
        let b = PitchResult(
            frequency: 440.0, amplitude: 0.5, noteName: "Pa",
            octave: 4, centsOffset: 0, timestamp: date, confidence: 1.0
        )
        #expect(a == b)
    }
}
