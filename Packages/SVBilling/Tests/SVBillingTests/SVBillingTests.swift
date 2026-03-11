import Testing

@testable import SVBilling

@Suite("StoreKit2Manager Tests")
struct StoreKit2ManagerTests {
    @Test("Default tier is free")
    @MainActor
    func defaultTierIsFree() {
        #expect(StoreKit2Manager.shared.currentTier == .free)
    }

    @Test("SubscriptionTier has exactly three tiers")
    func tierCount() {
        #expect(SubscriptionTier.allCases.count == 3)
    }

    @Test("SubscriptionTier raw values are lowercase strings")
    func tierRawValuesAreLowercase() {
        for tier in SubscriptionTier.allCases {
            #expect(tier.rawValue == tier.rawValue.lowercased())
        }
    }

    @Test("Display names are non-empty and capitalized")
    func displayNamesCapitalized() {
        for tier in SubscriptionTier.allCases {
            #expect(!tier.displayName.isEmpty)
            let first = tier.displayName.first!
            #expect(first.isUppercase, "\(tier.rawValue) displayName not capitalized")
        }
    }

    @Test("Free tier raw value matches spec")
    func freeTierRawValue() {
        #expect(SubscriptionTier.free.rawValue == "free")
        #expect(SubscriptionTier.free.displayName == "Free")
    }
}
