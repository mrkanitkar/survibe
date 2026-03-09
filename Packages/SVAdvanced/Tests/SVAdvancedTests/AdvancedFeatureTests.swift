import Testing
@testable import SVAdvanced

@Suite("SVAdvanced Feature Tests")
struct AdvancedFeatureTests {
    @Test("Advanced features not available in Sprint 0")
    func testNotAvailable() {
        #expect(SVAdvancedFeatures.isAvailable == false)
    }

    @Test("Four feature flags defined")
    func testFeatureCount() {
        #expect(SVAdvancedFeatures.Feature.allCases.count == 4)
    }
}
