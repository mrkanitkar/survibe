import Foundation
import Testing

@testable import SVSocial

@Suite("ReelGenerator Tests")
struct ReelGeneratorTests {
    @Test("ReelGenerator is Sendable")
    func generatorIsSendable() {
        func requireSendable<T: Sendable>(_: T) {}
        requireSendable(ReelGenerator())
    }

    @Test("generate stub returns input URL unchanged")
    func generateReturnsInputURL() async throws {
        let generator = ReelGenerator()
        let inputURL = URL(filePath: "/tmp/test-session.m4a")
        let outputURL = try await generator.generate(from: inputURL)
        #expect(outputURL == inputURL)
    }

    @Test("generate handles different URL schemes")
    func generateAcceptsVariousURLs() async throws {
        let generator = ReelGenerator()
        let fileURL = URL(filePath: "/Users/test/recording.wav")
        let result = try await generator.generate(from: fileURL)
        #expect(result.path().contains("recording.wav"))
    }
}
