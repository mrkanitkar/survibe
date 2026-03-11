import Testing

@testable import SVAI

@Suite("OnDeviceAIProvider Tests")
struct OnDeviceAIProviderTests {
    @Test("Provider name is On-Device")
    func providerName() {
        let provider = OnDeviceAIProvider()
        #expect(provider.name == "On-Device")
    }

    @Test("Provider is not available in Sprint 0")
    func notAvailableYet() {
        let provider = OnDeviceAIProvider()
        #expect(provider.isAvailable == false)
    }

    @Test("generate returns empty string stub")
    func generateReturnsStub() async throws {
        let provider = OnDeviceAIProvider()
        let result = try await provider.generate(prompt: "Test prompt")
        #expect(result.isEmpty)
    }

    @Test("Provider conforms to AIProvider protocol")
    func conformsToProtocol() {
        let provider: any AIProvider = OnDeviceAIProvider()
        #expect(provider.name == "On-Device")
    }
}
