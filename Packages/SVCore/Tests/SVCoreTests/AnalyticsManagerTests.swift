import Testing

@testable import SVCore

@Suite("AnalyticsManager Tests")
struct AnalyticsManagerTests {
    @Test("Tracking is enabled by default")
    @MainActor
    func trackingEnabledByDefault() {
        let manager = AnalyticsManager.shared
        #expect(manager.isTrackingEnabled == true)
    }

    @Test("SDK is not configured by default")
    @MainActor
    func notConfiguredByDefault() {
        let manager = AnalyticsManager.shared
        #expect(manager.isConfigured == false)
    }

    @Test("Track is a no-op when not configured")
    @MainActor
    func trackNoOpWhenNotConfigured() {
        let manager = AnalyticsManager.shared
        // Should not crash or throw — just silently no-op
        manager.track(.appScaffoldingLoaded)
        manager.track(.tabSelected, properties: ["tab": "practice"])
        #expect(manager.isConfigured == false)
    }

    @Test("Configure rejects empty API key")
    @MainActor
    func configureRejectsEmptyKey() {
        let manager = AnalyticsManager.shared
        manager.configure(apiKey: "")
        #expect(manager.isConfigured == false)
    }

    @Test("setTrackingEnabled toggles the flag")
    @MainActor
    func setTrackingEnabledToggles() {
        let manager = AnalyticsManager.shared
        let original = manager.isTrackingEnabled

        manager.setTrackingEnabled(false)
        #expect(manager.isTrackingEnabled == false)

        // Restore original state
        manager.setTrackingEnabled(original)
        #expect(manager.isTrackingEnabled == original)
    }

    @Test("Reset is a no-op when not configured")
    @MainActor
    func resetNoOpWhenNotConfigured() {
        let manager = AnalyticsManager.shared
        // Should not crash — just silently no-op
        manager.reset()
        #expect(manager.isConfigured == false)
    }
}
