import Foundation
import Testing

@testable import SVAudio

// MARK: - MIDIParser Tests

@Suite("MIDI Parser Tests")
struct MIDIParserTests {

    // MARK: - Invalid Input Tests

    @Test("Parse nil data returns invalidHeader error")
    func parseNilData() {
        let result = MIDIParser.parse(data: nil)
        guard case .failure(let error) = result else {
            Issue.record("Expected failure for nil data, got success")
            return
        }
        #expect(error == .invalidHeader)
    }

    @Test("Parse empty data returns invalidHeader error")
    func parseEmptyData() {
        let result = MIDIParser.parse(data: Data())
        guard case .failure(let error) = result else {
            Issue.record("Expected failure for empty data, got success")
            return
        }
        #expect(error == .invalidHeader)
    }

    @Test("Parse data shorter than 14 bytes returns invalidHeader")
    func parseTooShortData() {
        // Just the MThd magic + partial header (10 bytes, need 14)
        let data = Data([0x4D, 0x54, 0x68, 0x64, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00])
        let result = MIDIParser.parse(data: data)
        guard case .failure(let error) = result else {
            Issue.record("Expected failure for short data, got success")
            return
        }
        #expect(error == .invalidHeader)
    }

    @Test("Parse data with wrong magic bytes returns invalidHeader")
    func parseInvalidMagic() {
        var data = Data(count: 14)
        data[0] = 0x00  // Not 'M'
        data[1] = 0x00  // Not 'T'
        data[2] = 0x00  // Not 'h'
        data[3] = 0x00  // Not 'd'
        let result = MIDIParser.parse(data: data)
        guard case .failure(let error) = result else {
            Issue.record("Expected failure for invalid magic, got success")
            return
        }
        #expect(error == .invalidHeader)
    }

    @Test("Parse format 2 MIDI returns unsupportedFormat")
    func parseFormat2() {
        var data = Data()
        // MThd header
        data.append(contentsOf: [0x4D, 0x54, 0x68, 0x64])
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x06])
        data.append(contentsOf: [0x00, 0x02])  // Format 2
        data.append(contentsOf: [0x00, 0x01])  // 1 track
        data.append(contentsOf: [0x01, 0xE0])  // 480 ticks/quarter
        let result = MIDIParser.parse(data: data)
        guard case .failure(let error) = result else {
            Issue.record("Expected failure for format 2, got success")
            return
        }
        #expect(error == .unsupportedFormat)
    }

    // MARK: - MIDIEvent Tests

    @Test("MIDIEvent stores all properties correctly")
    func midiEventProperties() {
        let event = MIDIEvent(noteNumber: 72, velocity: 80, timestamp: 2.0, duration: 1.0)
        #expect(event.noteNumber == 72)
        #expect(event.velocity == 80)
        #expect(event.timestamp == 2.0)
        #expect(event.duration == 1.0)
    }

    @Test("MIDIEvent equality for identical values")
    func midiEventEquality() {
        let event1 = MIDIEvent(noteNumber: 60, velocity: 100, timestamp: 0.0, duration: 0.5)
        let event2 = MIDIEvent(noteNumber: 60, velocity: 100, timestamp: 0.0, duration: 0.5)
        #expect(event1 == event2)
    }

    @Test("MIDIEvent inequality for different timestamps")
    func midiEventDifferentTimestamps() {
        let event1 = MIDIEvent(noteNumber: 60, velocity: 100, timestamp: 0.0, duration: 0.5)
        let event2 = MIDIEvent(noteNumber: 60, velocity: 100, timestamp: 1.0, duration: 0.5)
        #expect(event1 != event2)
    }

    @Test("MIDIEvent conforms to Sendable")
    func midiEventSendable() {
        let event = MIDIEvent(noteNumber: 60, velocity: 100, timestamp: 0.0, duration: 0.5)
        let _: any Sendable = event
        #expect(true)
    }

    @Test("MIDIEvent Codable round-trip preserves all fields")
    func midiEventCodable() throws {
        let original = MIDIEvent(noteNumber: 64, velocity: 90, timestamp: 1.25, duration: 0.75)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MIDIEvent.self, from: data)
        #expect(decoded == original)
    }

    @Test("MIDIEvent Hashable produces consistent hash")
    func midiEventHashable() {
        let event1 = MIDIEvent(noteNumber: 60, velocity: 100, timestamp: 1.0, duration: 0.5)
        let event2 = MIDIEvent(noteNumber: 60, velocity: 100, timestamp: 1.0, duration: 0.5)
        #expect(event1.hashValue == event2.hashValue)
    }

    // MARK: - MIDIParseError Tests

    @Test("MIDIParseError all cases have non-nil localized descriptions")
    func parseErrorDescriptions() {
        #expect(MIDIParseError.invalidHeader.errorDescription != nil)
        #expect(MIDIParseError.corruptedData.errorDescription != nil)
        #expect(MIDIParseError.noNotesFound.errorDescription != nil)
        #expect(MIDIParseError.unsupportedFormat.errorDescription != nil)
    }

    @Test("MIDIParseError descriptions are non-empty strings")
    func parseErrorDescriptionsNonEmpty() {
        let allErrors: [MIDIParseError] = [
            .invalidHeader, .corruptedData, .noNotesFound, .unsupportedFormat,
        ]
        for error in allErrors {
            let description = error.errorDescription ?? ""
            #expect(!description.isEmpty, "Error \(error) has empty description")
        }
    }

    @Test("MIDIParseError equality for same cases")
    func parseErrorEquality() {
        #expect(MIDIParseError.invalidHeader == MIDIParseError.invalidHeader)
        #expect(MIDIParseError.corruptedData == MIDIParseError.corruptedData)
    }

    @Test("MIDIParseError inequality for different cases")
    func parseErrorInequality() {
        #expect(MIDIParseError.invalidHeader != MIDIParseError.corruptedData)
        #expect(MIDIParseError.noNotesFound != MIDIParseError.unsupportedFormat)
    }

    // MARK: - Valid MIDI Parsing Tests

    @Test("Parse valid minimal MIDI file returns at least one event")
    func parseMinimalMIDI() {
        let data = buildMinimalMIDI(noteNumber: 60, velocity: 100, durationTicks: 480)
        let result = MIDIParser.parse(data: data)
        guard case .success(let events) = result else {
            Issue.record("Expected success, got failure: \(result)")
            return
        }
        #expect(!events.isEmpty)
        #expect(events[0].noteNumber == 60)
        #expect(events[0].velocity == 100)
    }

    @Test("Parsed note has positive duration")
    func parsedNoteHasPositiveDuration() {
        let data = buildMinimalMIDI(noteNumber: 64, velocity: 80, durationTicks: 480)
        let result = MIDIParser.parse(data: data)
        guard case .success(let events) = result else {
            Issue.record("Expected success")
            return
        }
        #expect(!events.isEmpty)
        #expect(events[0].duration > 0)
    }

    @Test("Parsed note timestamp starts at zero")
    func parsedNoteStartsAtZero() {
        let data = buildMinimalMIDI(noteNumber: 60, velocity: 100, durationTicks: 480)
        let result = MIDIParser.parse(data: data)
        guard case .success(let events) = result else {
            Issue.record("Expected success")
            return
        }
        #expect(events[0].timestamp == 0.0)
    }

    @Test("Parse two-note MIDI file returns events sorted by timestamp")
    func parsedEventsSortedByTimestamp() {
        let data = buildTwoNoteMIDI()
        let result = MIDIParser.parse(data: data)
        guard case .success(let events) = result else {
            Issue.record("Expected success, got failure: \(result)")
            return
        }
        #expect(events.count >= 2)
        if events.count >= 2 {
            #expect(events[0].timestamp <= events[1].timestamp)
        }
    }

    @Test("Parse two-note MIDI file contains correct note numbers")
    func parsedTwoNoteContainsCorrectPitches() {
        let data = buildTwoNoteMIDI()
        let result = MIDIParser.parse(data: data)
        guard case .success(let events) = result else {
            Issue.record("Expected success")
            return
        }
        let noteNumbers = Set(events.map(\.noteNumber))
        #expect(noteNumbers.contains(60))  // C4
        #expect(noteNumbers.contains(64))  // E4
    }

    @Test("Parse MIDI with default tempo uses 120 BPM timing")
    func defaultTempoTiming() {
        // At 120 BPM, one quarter note = 0.5 seconds.
        // With 480 ticks/quarter, 480 ticks = 0.5s.
        let data = buildMinimalMIDI(noteNumber: 60, velocity: 100, durationTicks: 480)
        let result = MIDIParser.parse(data: data)
        guard case .success(let events) = result else {
            Issue.record("Expected success")
            return
        }
        #expect(!events.isEmpty)
        // Duration should be approximately 0.5 seconds for one quarter note at 120 BPM
        let duration = events[0].duration
        #expect(duration > 0.4)
        #expect(duration < 0.6)
    }

    @Test("Parse MIDI header with zero division returns corruptedData")
    func zeroDivisionReturnsError() {
        var data = Data()
        // MThd header
        data.append(contentsOf: [0x4D, 0x54, 0x68, 0x64])
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x06])
        data.append(contentsOf: [0x00, 0x00])  // Format 0
        data.append(contentsOf: [0x00, 0x01])  // 1 track
        data.append(contentsOf: [0x00, 0x00])  // 0 ticks/quarter — invalid
        let result = MIDIParser.parse(data: data)
        guard case .failure = result else {
            Issue.record("Expected failure for zero division, got success")
            return
        }
    }

    // MARK: - Helpers

    /// Build a minimal SMF format 0 MIDI file with a single note.
    private func buildMinimalMIDI(
        noteNumber: UInt8,
        velocity: UInt8,
        durationTicks: UInt16
    ) -> Data {
        var data = Data()

        // MThd header
        data.append(contentsOf: [0x4D, 0x54, 0x68, 0x64])  // "MThd"
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x06])  // Header length: 6
        data.append(contentsOf: [0x00, 0x00])  // Format 0
        data.append(contentsOf: [0x00, 0x01])  // 1 track
        data.append(contentsOf: [0x01, 0xE0])  // 480 ticks/quarter

        // MTrk track
        var track = Data()

        // Note On at delta 0
        track.append(0x00)  // delta = 0
        track.append(0x90)  // Note On, channel 0
        track.append(noteNumber)
        track.append(velocity)

        // Note Off at delta = durationTicks (VLQ encoded)
        // 480 = 0x1E0 → VLQ = [0x83, 0x60]
        let highByte = UInt8((durationTicks >> 7) & 0x7F) | 0x80
        let lowByte = UInt8(durationTicks & 0x7F)
        track.append(highByte)
        track.append(lowByte)
        track.append(0x80)  // Note Off, channel 0
        track.append(noteNumber)
        track.append(0x00)  // velocity 0

        // End of Track meta event
        track.append(0x00)  // delta = 0
        track.append(0xFF)  // meta event
        track.append(0x2F)  // End of Track
        track.append(0x00)  // length 0

        // Write track chunk header
        data.append(contentsOf: [0x4D, 0x54, 0x72, 0x6B])  // "MTrk"
        let trackLen = UInt32(track.count)
        data.append(UInt8((trackLen >> 24) & 0xFF))
        data.append(UInt8((trackLen >> 16) & 0xFF))
        data.append(UInt8((trackLen >> 8) & 0xFF))
        data.append(UInt8(trackLen & 0xFF))
        data.append(track)

        return data
    }

    /// Build a MIDI file with two sequential notes for sort testing.
    private func buildTwoNoteMIDI() -> Data {
        var data = Data()

        // MThd header
        data.append(contentsOf: [0x4D, 0x54, 0x68, 0x64])
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x06])
        data.append(contentsOf: [0x00, 0x00])  // Format 0
        data.append(contentsOf: [0x00, 0x01])  // 1 track
        data.append(contentsOf: [0x01, 0xE0])  // 480 ticks/quarter

        var track = Data()

        // Note 1: C4 (60) on at delta 0
        track.append(contentsOf: [0x00, 0x90, 60, 100])
        // Note 1: C4 off at delta 480 — VLQ [0x83, 0x60]
        track.append(contentsOf: [0x83, 0x60, 0x80, 60, 0x00])
        // Note 2: E4 (64) on at delta 0 (absolute tick 480)
        track.append(contentsOf: [0x00, 0x90, 64, 100])
        // Note 2: E4 off at delta 480 — VLQ [0x83, 0x60]
        track.append(contentsOf: [0x83, 0x60, 0x80, 64, 0x00])
        // End of Track
        track.append(contentsOf: [0x00, 0xFF, 0x2F, 0x00])

        // Write track chunk header
        data.append(contentsOf: [0x4D, 0x54, 0x72, 0x6B])  // "MTrk"
        let trackLen = UInt32(track.count)
        data.append(UInt8((trackLen >> 24) & 0xFF))
        data.append(UInt8((trackLen >> 16) & 0xFF))
        data.append(UInt8((trackLen >> 8) & 0xFF))
        data.append(UInt8(trackLen & 0xFF))
        data.append(track)

        return data
    }
}
