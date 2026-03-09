import Testing
@testable import SVBilling

@Suite("SubscriptionTier Tests")
struct SubscriptionTierTests {
    @Test("Three tiers exist")
    func testTierCount() {
        #expect(SubscriptionTier.allCases.count == 3)
    }

    @Test("Free tier has correct raw value")
    func testFreeRawValue() {
        #expect(SubscriptionTier.free.rawValue == "free")
    }

    @Test("Display names are capitalized")
    func testDisplayNames() {
        #expect(SubscriptionTier.free.displayName == "Free")
        #expect(SubscriptionTier.basic.displayName == "Basic")
        #expect(SubscriptionTier.premium.displayName == "Premium")
    }
}
