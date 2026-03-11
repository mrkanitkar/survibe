import Foundation
import Testing

@testable import SVAudio

@Suite("SwarUtility Tests")
struct SwarUtilityTests {
    // MARK: - frequencyToNote

    @Test("A4 at 440 Hz maps to Dha octave 4")
    func a4MapsCorrectly() throws {
        let (name, octave, cents) = try SwarUtility.frequencyToNote(440.0)
        #expect(name == "Dha")
        #expect(octave == 4)
        #expect(abs(cents) < 1.0)
    }

    @Test("Middle C (261.63 Hz) maps to Sa octave 4")
    func middleCMapsSa() throws {
        let (name, octave, cents) = try SwarUtility.frequencyToNote(261.626)
        #expect(name == "Sa")
        #expect(octave == 4)
        #expect(abs(cents) < 1.0)
    }

    @Test("C5 (523.25 Hz) maps to Sa octave 5")
    func c5MapsSaOctave5() throws {
        let (name, octave, _) = try SwarUtility.frequencyToNote(523.25)
        #expect(name == "Sa")
        #expect(octave == 5)
    }

    @Test("Low C2 (65.41 Hz) maps to Sa octave 2")
    func lowC2MapsSa() throws {
        let (name, octave, _) = try SwarUtility.frequencyToNote(65.41)
        #expect(name == "Sa")
        #expect(octave == 2)
    }

    @Test("Frequency sharp of A4 gives positive cents offset")
    func sharpFrequencyGivesPositiveCents() throws {
        // 445 Hz is slightly sharp of A4=440
        let (_, _, cents) = try SwarUtility.frequencyToNote(445.0)
        #expect(cents > 0)
    }

    @Test("Frequency flat of A4 gives negative cents offset")
    func flatFrequencyGivesNegativeCents() throws {
        // 435 Hz is slightly flat of A4=440
        let (_, _, cents) = try SwarUtility.frequencyToNote(435.0)
        #expect(cents < 0)
    }

    @Test("All 12 swar names are reachable via frequency")
    func allSwarsReachable() throws {
        // Generate one frequency per chromatic note in octave 4 (C4 to B4)
        let a4 = 440.0
        var noteNames: Set<String> = []
        for semitone in -9...2 {
            let freq = a4 * pow(2.0, Double(semitone) / 12.0)
            let (name, _, _) = try SwarUtility.frequencyToNote(freq)
            noteNames.insert(name)
        }
        #expect(noteNames.count == 12)
    }

    @Test("Custom reference pitch shifts note mapping")
    func customReferencePitch() throws {
        // With A4=432 Hz, 432 Hz should map to Dha
        let (name, _, cents) = try SwarUtility.frequencyToNote(432.0, referencePitch: 432.0)
        #expect(name == "Dha")
        #expect(abs(cents) < 1.0)
    }

    // MARK: - Input Validation

    @Test("Zero frequency throws invalidFrequency")
    func zeroFrequencyThrows() {
        #expect(throws: AudioValidationError.self) {
            _ = try SwarUtility.frequencyToNote(0.0)
        }
    }

    @Test("Negative frequency throws invalidFrequency")
    func negativeFrequencyThrows() {
        #expect(throws: AudioValidationError.self) {
            _ = try SwarUtility.frequencyToNote(-100.0)
        }
    }

    @Test("NaN frequency throws invalidFrequency")
    func nanFrequencyThrows() {
        #expect(throws: AudioValidationError.self) {
            _ = try SwarUtility.frequencyToNote(Double.nan)
        }
    }

    @Test("Infinite frequency throws invalidFrequency")
    func infiniteFrequencyThrows() {
        #expect(throws: AudioValidationError.self) {
            _ = try SwarUtility.frequencyToNote(Double.infinity)
        }
    }

    @Test("Zero reference pitch throws invalidReferencePitch")
    func zeroRefPitchThrows() {
        #expect(throws: AudioValidationError.self) {
            _ = try SwarUtility.frequencyToNote(440.0, referencePitch: 0.0)
        }
    }

    @Test("NaN reference pitch throws invalidReferencePitch")
    func nanRefPitchThrows() {
        #expect(throws: AudioValidationError.self) {
            _ = try SwarUtility.frequencyToNote(440.0, referencePitch: Double.nan)
        }
    }

    // MARK: - westernName

    @Test("Sa maps to C")
    func saToC() {
        #expect(SwarUtility.westernName(for: "Sa") == "C")
    }

    @Test("Pa maps to G")
    func paToG() {
        #expect(SwarUtility.westernName(for: "Pa") == "G")
    }

    @Test("Dha maps to A")
    func dhaToA() {
        #expect(SwarUtility.westernName(for: "Dha") == "A")
    }

    @Test("Tivra Ma maps to F#")
    func tivraMaToFSharp() {
        #expect(SwarUtility.westernName(for: "Tivra Ma") == "F#")
    }

    @Test("Unknown swar name returns input unchanged")
    func unknownSwarReturnsInput() {
        #expect(SwarUtility.westernName(for: "XYZ") == "XYZ")
    }

    @Test("All 12 swar names produce distinct western names")
    func allWesternNamesDistinct() {
        let swarNames = Swar.allCases.map { $0.rawValue }
        let westernNames = swarNames.map { SwarUtility.westernName(for: $0) }
        #expect(Set(westernNames).count == 12)
    }
}
