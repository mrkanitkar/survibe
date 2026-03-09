import Testing
@testable import SVCore

@Suite("AnalyticsEvent Tests")
struct AnalyticsEventTests {
    @Test("Event raw values use snake_case format")
    func testRawValueFormat() {
        for event in [AnalyticsEvent.appScaffoldingLoaded, .audioPocPitchDetected, .cloudKitSyncCompleted, .tabSelected, .sessionStarted, .sessionEnded] {
            // Verify snake_case: only lowercase letters, digits, and underscores
            let isSnakeCase = event.rawValue.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "_" }
            #expect(isSnakeCase, "Event '\(event.rawValue)' should be snake_case")
        }
    }

    @Test("Sprint 0 verification events exist")
    func testSprint0Events() {
        #expect(AnalyticsEvent.appScaffoldingLoaded.rawValue == "app_scaffolding_loaded")
        #expect(AnalyticsEvent.audioPocPitchDetected.rawValue == "audio_poc_pitch_detected")
        #expect(AnalyticsEvent.cloudKitSyncCompleted.rawValue == "cloudkit_sync_completed")
    }
}
