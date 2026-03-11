import Foundation
import Testing

@testable import SVAudio

@Suite("SoundFontManager Tests")
struct SoundFontManagerTests {
    @Test("Not loaded initially")
    @MainActor
    func initialState() {
        #expect(SoundFontManager.shared.isLoaded == false)
    }

    @Test("stopAllNotes on empty state does not crash")
    @MainActor
    func stopAllNotesEmpty() {
        SoundFontManager.shared.stopAllNotes()
        // No crash = success
    }

    @Test("stopNote on unplayed note does not crash")
    @MainActor
    func stopUnplayedNote() {
        SoundFontManager.shared.stopNote(midiNote: 60)
        // No crash = success
    }

    @Test("loadSoundFont with invalid URL throws")
    @MainActor
    func loadInvalidURLThrows() {
        let badURL = URL(filePath: "/nonexistent/fake.sf2")
        #expect(throws: (any Error).self) {
            try SoundFontManager.shared.loadSoundFont(at: badURL)
        }
    }
}
