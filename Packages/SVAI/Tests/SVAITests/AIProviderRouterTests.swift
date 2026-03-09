import Testing
@testable import SVAI

@Suite("AIProviderRouter Tests")
struct AIProviderRouterTests {
    @Test("Router singleton exists")
    func testSingleton() {
        let router = AIProviderRouter.shared
        #expect(router != nil)
    }
}
