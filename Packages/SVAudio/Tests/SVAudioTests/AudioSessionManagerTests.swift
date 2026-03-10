import Testing
@testable import SVAudio

@Suite("AudioSessionManager Tests")
struct AudioSessionManagerTests {
    @Test("Singleton exists")
    @MainActor func testSingleton() {
        let manager = AudioSessionManager.shared
        #expect(manager != nil)
    }

    @Test("Sample rate returns a positive value")
    @MainActor func testSampleRate() {
        #expect(AudioSessionManager.shared.sampleRate > 0)
    }
}
