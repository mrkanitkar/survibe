import Testing
@testable import SVAudio

@Suite("SoundFontManager Tests")
struct SoundFontManagerTests {
    @Test("Singleton exists")
    func testSingleton() {
        let manager = SoundFontManager.shared
        #expect(manager != nil)
    }

    @Test("Not loaded initially")
    func testInitialState() {
        #expect(SoundFontManager.shared.isLoaded == false)
    }
}
