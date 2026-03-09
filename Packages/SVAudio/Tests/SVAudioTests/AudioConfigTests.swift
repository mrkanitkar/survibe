import Testing
@testable import SVAudio

@Suite("AudioConfig Tests")
struct AudioConfigTests {
    @Test("Default config uses 44100 Hz sample rate")
    func testDefaultSampleRate() {
        let config = AudioConfig()
        #expect(config.sampleRate == 44100)
    }

    @Test("Default buffer size is 2048")
    func testDefaultBufferSize() {
        let config = AudioConfig()
        #expect(config.bufferSize == 2048)
    }

    @Test("Default latency is approximately 46ms")
    func testDefaultLatency() {
        let config = AudioConfig()
        // 2048 / 44100 * 1000 ≈ 46.44 ms
        #expect(config.latencyMs > 46.0 && config.latencyMs < 47.0)
    }

    @Test("Pitch detection config matches defaults")
    func testPitchDetectionConfig() {
        let config = AudioConfig.pitchDetection
        #expect(config.bufferSize == 2048)
        #expect(config.sampleRate == 44100)
        #expect(config.channelCount == 1)
    }
}
