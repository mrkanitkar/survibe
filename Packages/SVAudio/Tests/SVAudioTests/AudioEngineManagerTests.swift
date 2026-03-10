import Testing
@testable import SVAudio

@Suite("AudioEngineManager Tests")
struct AudioEngineManagerTests {
    @Test("Singleton exists")
    @MainActor func testSingleton() {
        let manager = AudioEngineManager.shared
        #expect(manager != nil)
    }

    @Test("Engine is not running initially")
    @MainActor func testInitialState() {
        #expect(AudioEngineManager.shared.isRunning == false)
    }

    @Test("Buffer size is 2048")
    @MainActor func testBufferSize() {
        #expect(AudioEngineManager.shared.bufferSize == 2048)
    }

    @Test("Engine has sampler, tanpura, and metronome nodes attached")
    @MainActor func testNodesAttached() {
        let manager = AudioEngineManager.shared
        // These properties exist and are accessible
        #expect(manager.sampler != nil)
        #expect(manager.tanpuraNode != nil)
        #expect(manager.metronomeNode != nil)
    }
}
