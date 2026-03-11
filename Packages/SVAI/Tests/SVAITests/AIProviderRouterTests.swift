import Testing

@testable import SVAI

@Suite("AIProviderRouter Tests")
struct AIProviderRouterTests {
    @Test("Router returns empty string stub")
    func routeReturnsStub() async throws {
        let result = try await AIProviderRouter.shared.route(prompt: "Test")
        #expect(result.isEmpty)
    }

    @Test("Router is Sendable")
    func routerIsSendable() {
        func requireSendable<T: Sendable>(_: T) {}
        requireSendable(AIProviderRouter.shared)
    }
}
